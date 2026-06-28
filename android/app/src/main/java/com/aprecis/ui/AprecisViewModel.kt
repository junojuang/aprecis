package com.aprecis.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aprecis.data.remote.dto.CardDeckDto
import com.aprecis.data.remote.dto.RelatedResponseDto
import com.aprecis.data.repository.RecentPaperEntry
import com.aprecis.data.repository.FeedRepository
import com.aprecis.data.repository.UserLibraryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class AppTab { Discover, Profile }

sealed interface Destination {
    data object Home : Destination
    data class Focus(val deck: CardDeckDto) : Destination
    data class Paper(val deck: CardDeckDto) : Destination
    data class WebLesson(val paperId: String, val title: String, val url: String) : Destination
}

data class AppUiState(
    val loading: Boolean = true,
    val decks: List<CardDeckDto> = emptyList(),
    val webLessons: Map<String, String> = emptyMap(),
    val related: RelatedResponseDto? = null,
    val focusTrailIds: List<String> = emptyList(),
    val selectedTab: AppTab = AppTab.Discover,
    val destination: Destination = Destination.Home,
    val query: String = "",
    val searchTopicFilter: Topic? = null,
    val savedIds: Set<String> = emptySet(),
    val completedIds: Set<String> = emptySet(),
    val recentIds: List<String> = emptyList(),
    val recentEntries: List<RecentPaperEntry> = emptyList(),
    val progressById: Map<String, Float> = emptyMap(),
    val todayCompletedCount: Int = 0,
    val currentStreak: Int = 0,
    val recentSearches: List<String> = emptyList(),
    val onboardingCompleted: Boolean = false,
    val displayName: String = "",
    val dailyGoal: Int = 3,
    val notificationsEnabled: Boolean = true,
    val error: String? = null,
) {
    val rankedSearchHits: List<SearchHit>
        get() {
            val q = query.trim().lowercase()
            if (q.isEmpty()) return emptyList()
            val tokens = q.split(Regex("[^a-z0-9]+")).filter { it.length >= 2 }
            return decks.mapNotNull { deck ->
                val topic = Topic.forDeck(deck)
                if (searchTopicFilter != null && searchTopicFilter != topic) return@mapNotNull null
                val score = deck.searchScore(q, tokens, topic)
                if (score <= 0) null else SearchHit(deck = deck, score = score, topic = topic)
            }
                .sortedByDescending { it.score }
        }

    val searchResults: List<CardDeckDto> get() = rankedSearchHits.take(12).map { it.deck }
    val searchResultCount: Int get() = rankedSearchHits.size
    val webLessonCount: Int get() = webLessons.keys.intersect(decks.map { it.paperId }.toSet()).size
    val savedDecks: List<CardDeckDto> get() = savedIds.mapNotNull { id -> decks.find { it.paperId == id } }
    val recentDecks: List<CardDeckDto> get() = recentIds.mapNotNull { id -> decks.find { it.paperId == id } }
    val recentDeckEntries: List<RecentDeckEntry>
        get() = recentEntries.mapNotNull { entry ->
            decks.find { it.paperId == entry.paperId }?.let { deck ->
                RecentDeckEntry(deck = deck, openedAtMillis = entry.openedAtMillis)
            }
        }
    val focusTrailDecks: List<CardDeckDto> get() = focusTrailIds.mapNotNull { id -> decks.find { it.paperId == id } }
    fun progressFor(paperId: String): Float = progressById[paperId] ?: if (paperId in completedIds) 1f else 0f
}

data class SearchHit(
    val deck: CardDeckDto,
    val score: Int,
    val topic: Topic,
)

data class RecentDeckEntry(
    val deck: CardDeckDto,
    val openedAtMillis: Long,
)

@HiltViewModel
class AprecisViewModel @Inject constructor(
    private val repository: FeedRepository,
    private val libraryRepository: UserLibraryRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(AppUiState())
    val state: StateFlow<AppUiState> = _state.asStateFlow()

    init {
        observeLibrary()
        refresh()
    }

    private fun observeLibrary() {
        viewModelScope.launch {
            libraryRepository.library.collect { library ->
                _state.update {
                    it.copy(
                        savedIds = library.savedIds,
                        completedIds = library.completedIds,
                        recentIds = library.recentIds,
                        recentEntries = library.recentEntries,
                        progressById = library.progressById,
                        todayCompletedCount = library.todayCompletedCount,
                        currentStreak = library.currentStreak,
                        recentSearches = library.recentSearches,
                        onboardingCompleted = library.onboardingCompleted,
                        displayName = library.displayName,
                        dailyGoal = library.dailyGoal,
                        notificationsEnabled = library.notificationsEnabled,
                    )
                }
            }
        }
    }

    fun refresh() {
        _state.update { it.copy(loading = true, error = null) }
        viewModelScope.launch {
            val feed = async { repository.loadFeed(page = 0) }
            val webLessons = async { repository.loadWebLessons() }
            val feedResult = feed.await()
            val lessonResult = webLessons.await()

            feedResult
                .onSuccess { page ->
                    val map = lessonResult.getOrDefault(emptyMap())
                    _state.update {
                        it.copy(
                            loading = false,
                            decks = page.decks.map { deck -> deck.withWebLesson(map[deck.paperId]) },
                            webLessons = map,
                            error = lessonResult.exceptionOrNull()?.message,
                        )
                    }
                }
                .onFailure { error ->
                    _state.update {
                        it.copy(
                            loading = false,
                            error = error.message ?: "Could not load Aprecis.",
                        )
                    }
                }
        }
    }

    fun selectTab(tab: AppTab) {
        _state.update { it.copy(selectedTab = tab, destination = Destination.Home, related = null, focusTrailIds = emptyList()) }
    }

    fun updateQuery(query: String) {
        _state.update {
            it.copy(
                query = query,
                searchTopicFilter = if (query.isBlank()) null else it.searchTopicFilter,
            )
        }
    }

    fun updateSearchTopicFilter(topic: Topic?) {
        _state.update { it.copy(searchTopicFilter = topic) }
    }

    fun clearRecentSearches() {
        viewModelScope.launch { libraryRepository.clearRecentSearches() }
    }

    fun openTopic(topic: Topic) {
        _state.update {
            it.copy(
                query = topic.query,
                searchTopicFilter = null,
                selectedTab = AppTab.Discover,
                destination = Destination.Home,
                focusTrailIds = emptyList(),
            )
        }
    }

    fun openRandomFocus() {
        val deck = _state.value.decks.randomOrNull() ?: return
        setFocus(deck, addToTrail = false, resetTrail = false)
    }

    fun openFocus(deck: CardDeckDto) {
        val query = _state.value.query.trim()
        if (query.length >= 2) {
            viewModelScope.launch { libraryRepository.recordSearch(query) }
        }
        setFocus(deck, addToTrail = false, resetTrail = true)
    }

    fun openRelatedFocus(deck: CardDeckDto) {
        setFocus(deck, addToTrail = true, resetTrail = false)
    }

    fun openTrailFocus(deck: CardDeckDto) {
        val trail = _state.value.focusTrailIds
        val index = trail.indexOf(deck.paperId)
        if (index >= 0) {
            _state.update { it.copy(focusTrailIds = trail.take(index)) }
        }
        setFocus(deck, addToTrail = false, resetTrail = false)
    }

    fun openDeck(deck: CardDeckDto) {
        val url = deck.webLessonUrl ?: _state.value.webLessons[deck.paperId]
        if (!url.isNullOrBlank()) {
            _state.update {
                it.copy(
                    destination = Destination.WebLesson(
                        paperId = deck.paperId,
                        title = deck.title ?: deck.paperId,
                        url = url,
                    ),
                    related = null,
                    focusTrailIds = emptyList(),
                )
            }
            mark(deck.paperId, "open_web_lesson")
            markOpened(deck.paperId)
        } else {
            _state.update { it.copy(destination = Destination.Paper(deck), related = null, focusTrailIds = emptyList()) }
            mark(deck.paperId, "open_deck")
            markOpened(deck.paperId)
            loadRelated(deck.paperId)
        }
    }

    fun closeDestination() {
        _state.update { it.copy(destination = Destination.Home, related = null, focusTrailIds = emptyList()) }
    }

    fun finishLesson(paperId: String) {
        mark(paperId, "complete")
        viewModelScope.launch { libraryRepository.markCompleted(paperId) }
        closeDestination()
    }

    fun markDone(paperId: String) {
        mark(paperId, "progress")
        viewModelScope.launch { libraryRepository.markCompleted(paperId) }
    }

    fun toggleSaved(paperId: String) {
        viewModelScope.launch { libraryRepository.toggleSaved(paperId) }
    }

    fun completeOnboarding() {
        viewModelScope.launch { libraryRepository.setOnboardingCompleted(true) }
    }

    fun replayOnboarding() {
        viewModelScope.launch { libraryRepository.setOnboardingCompleted(false) }
    }

    fun updateDisplayName(name: String) {
        viewModelScope.launch { libraryRepository.setDisplayName(name) }
    }

    fun updateDailyGoal(goal: Int) {
        viewModelScope.launch { libraryRepository.setDailyGoal(goal) }
    }

    fun updateNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch { libraryRepository.setNotificationsEnabled(enabled) }
    }

    fun resetLocalData() {
        viewModelScope.launch { libraryRepository.resetLocalData() }
    }

    fun mark(paperId: String, action: String) {
        if (action.startsWith("progress:")) {
            val progress = action.substringAfter("progress:").toFloatOrNull()
            if (progress != null) {
                viewModelScope.launch { libraryRepository.setProgress(paperId, progress) }
            }
        }
        viewModelScope.launch {
            repository.markInteraction(paperId, action)
        }
    }

    private fun loadRelated(paperId: String) {
        viewModelScope.launch {
            repository.loadRelated(paperId)
                .onSuccess { related -> _state.update { it.copy(related = related) } }
        }
    }

    private fun setFocus(deck: CardDeckDto, addToTrail: Boolean, resetTrail: Boolean) {
        val current = _state.value.destination as? Destination.Focus
        val nextTrail = when {
            resetTrail -> emptyList()
            addToTrail && current != null -> {
                val existing = _state.value.focusTrailIds
                val rewind = existing.indexOf(deck.paperId)
                when {
                    rewind >= 0 -> existing.take(rewind)
                    current.deck.paperId == deck.paperId -> existing
                    else -> (existing + current.deck.paperId).takeLast(8)
                }
            }
            else -> _state.value.focusTrailIds
        }
        _state.update {
            it.copy(
                selectedTab = AppTab.Discover,
                destination = Destination.Focus(deck),
                related = null,
                focusTrailIds = nextTrail,
            )
        }
        mark(deck.paperId, "open_focus")
        loadRelated(deck.paperId)
    }

    private fun markOpened(paperId: String) {
        viewModelScope.launch { libraryRepository.markOpened(paperId) }
    }
}

private fun CardDeckDto.withWebLesson(webUrl: String?): CardDeckDto =
    if (webUrl.isNullOrBlank() || webLessonUrl != null) this else copy(webLessonUrl = webUrl)

private fun CardDeckDto.searchScore(query: String, tokens: List<String>, topic: Topic): Int {
    val title = title.orEmpty().lowercase()
    val hook = hook.orEmpty().lowercase()
    val summary = summary.orEmpty().lowercase()
    val paper = paperId.lowercase()
    val sourceText = source.orEmpty().lowercase()
    val category = arxivCategory.orEmpty().lowercase()
    val concepts = concepts.joinToString(" ") { "${it.title} ${it.body}" }.lowercase()
    val topicBlob = "${topic.label} ${topic.query} ${topic.blurb}".lowercase()
    var score = 0
    if (title.contains(query)) score += 12
    if (title.startsWith(query)) score += 8
    if (concepts.contains(query)) score += 8
    if (hook.contains(query)) score += 6
    if (summary.contains(query)) score += 5
    if (paper.contains(query)) score += 5
    if (sourceText.contains(query) || category.contains(query)) score += 4
    if (topicBlob.contains(query)) score += 11
    tokens.forEach { token ->
        if (title.contains(token)) score += 5
        if (concepts.contains(token)) score += 3
        if (hook.contains(token)) score += 2
        if (summary.contains(token)) score += 2
        if (paper.contains(token)) score += 2
        if (topicBlob.contains(token)) score += 4
    }
    return score
}
