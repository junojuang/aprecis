package com.aprecis.data.repository

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.ZoneId
import javax.inject.Inject
import javax.inject.Singleton

private val Context.userLibraryStore by preferencesDataStore(name = "user_library")

data class RecentPaperEntry(
    val paperId: String,
    val openedAtMillis: Long,
)

data class UserLibrary(
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
)

@Singleton
class UserLibraryRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val savedKey = stringSetPreferencesKey("saved_paper_ids")
    private val completedKey = stringSetPreferencesKey("completed_paper_ids")
    private val recentKey = stringSetPreferencesKey("recent_paper_ids")
    private val progressKey = stringSetPreferencesKey("reading_progress_v1")
    private val dailyCompletionsKey = stringSetPreferencesKey("daily_completions_v1")
    private val recentSearchesKey = stringSetPreferencesKey("recent_searches_v1")
    private val onboardingCompletedKey = booleanPreferencesKey("onboarding.completed")
    private val displayNameKey = stringPreferencesKey("profile.displayNameOverride")
    private val dailyGoalKey = intPreferencesKey("profile.dailyGoal")
    private val notificationsEnabledKey = booleanPreferencesKey("profile.notificationsEnabled")

    val library: Flow<UserLibrary> = context.userLibraryStore.data.map { prefs ->
        val recentEntries = prefs[recentKey].orEmpty().decodeRecentEntries()
        val dailyCompletions = prefs[dailyCompletionsKey].orEmpty().decodeDailyCompletions()
        UserLibrary(
            savedIds = prefs[savedKey].orEmpty(),
            completedIds = prefs[completedKey].orEmpty(),
            recentIds = recentEntries.map { it.paperId },
            recentEntries = recentEntries,
            progressById = prefs[progressKey].orEmpty().decodeProgressMap(),
            todayCompletedCount = dailyCompletions[todayKey()].orEmpty().size,
            currentStreak = dailyCompletions.currentStreak(),
            recentSearches = prefs[recentSearchesKey].orEmpty().decodeOrderedStrings(),
            onboardingCompleted = prefs[onboardingCompletedKey] ?: false,
            displayName = prefs[displayNameKey].orEmpty(),
            dailyGoal = (prefs[dailyGoalKey] ?: 3).coerceAtLeast(1),
            notificationsEnabled = prefs[notificationsEnabledKey] ?: true,
        )
    }

    suspend fun toggleSaved(paperId: String) {
        context.userLibraryStore.edit { prefs ->
            val next = prefs[savedKey].orEmpty().toMutableSet()
            if (!next.add(paperId)) next.remove(paperId)
            prefs[savedKey] = next
        }
    }

    suspend fun markCompleted(paperId: String) {
        context.userLibraryStore.edit { prefs ->
            prefs[completedKey] = prefs[completedKey].orEmpty() + paperId
            prefs[recentKey] = withRecentPrefix(paperId, prefs[recentKey].orEmpty())
            prefs[progressKey] = prefs[progressKey].orEmpty().withProgress(paperId, 1f)
            prefs[dailyCompletionsKey] = prefs[dailyCompletionsKey].orEmpty().withDailyCompletion(paperId)
        }
    }

    suspend fun setProgress(paperId: String, progress: Float) {
        context.userLibraryStore.edit { prefs ->
            val current = prefs[progressKey].orEmpty().decodeProgressMap()[paperId] ?: 0f
            val next = progress.coerceIn(0f, 1f)
            if (next > current) {
                prefs[progressKey] = prefs[progressKey].orEmpty().withProgress(paperId, next)
            }
            if (next >= 0.98f) {
                prefs[completedKey] = prefs[completedKey].orEmpty() + paperId
                prefs[dailyCompletionsKey] = prefs[dailyCompletionsKey].orEmpty().withDailyCompletion(paperId)
            }
            prefs[recentKey] = withRecentPrefix(paperId, prefs[recentKey].orEmpty())
        }
    }

    suspend fun markOpened(paperId: String) {
        context.userLibraryStore.edit { prefs ->
            prefs[recentKey] = withRecentPrefix(paperId, prefs[recentKey].orEmpty())
        }
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        context.userLibraryStore.edit { prefs ->
            prefs[onboardingCompletedKey] = completed
        }
    }

    suspend fun setDisplayName(name: String) {
        context.userLibraryStore.edit { prefs ->
            prefs[displayNameKey] = name.trim()
        }
    }

    suspend fun setDailyGoal(goal: Int) {
        context.userLibraryStore.edit { prefs ->
            prefs[dailyGoalKey] = goal.coerceIn(1, 20)
        }
    }

    suspend fun setNotificationsEnabled(enabled: Boolean) {
        context.userLibraryStore.edit { prefs ->
            prefs[notificationsEnabledKey] = enabled
        }
    }

    suspend fun recordSearch(raw: String) {
        val query = raw.trim()
        if (query.length < 2) return
        context.userLibraryStore.edit { prefs ->
            val existing = prefs[recentSearchesKey].orEmpty().decodeOrderedStrings()
            val next = (listOf(query) + existing.filterNot { it.equals(query, ignoreCase = true) })
                .take(8)
                .mapIndexed { index, value -> "${index.toString().padStart(2, '0')}:$value" }
                .toSet()
            prefs[recentSearchesKey] = next
        }
    }

    suspend fun clearRecentSearches() {
        context.userLibraryStore.edit { prefs ->
            prefs.remove(recentSearchesKey)
        }
    }

    suspend fun resetLocalData() {
        context.userLibraryStore.edit { prefs ->
            prefs.remove(savedKey)
            prefs.remove(completedKey)
            prefs.remove(recentKey)
            prefs.remove(progressKey)
            prefs.remove(dailyCompletionsKey)
            prefs.remove(recentSearchesKey)
        }
    }
}

private fun withRecentPrefix(paperId: String, existing: Set<String>): Set<String> {
    val now = System.currentTimeMillis()
    val rest = existing
        .decodeRecentEntries()
        .filter { it.paperId != paperId }
        .take(29)
    return (listOf(RecentPaperEntry(paperId, now)) + rest)
        .map { entry -> "${entry.openedAtMillis}:${entry.paperId}" }
        .toSet()
}

private fun Set<String>.decodeRecentEntries(): List<RecentPaperEntry> {
    val now = System.currentTimeMillis()
    return mapIndexedNotNull { index, encoded ->
        val separator = encoded.indexOf(':')
        if (separator <= 0 || separator >= encoded.lastIndex) {
            return@mapIndexedNotNull RecentPaperEntry(encoded, now - index)
        }
        val prefix = encoded.substring(0, separator)
        val paperId = encoded.substring(separator + 1)
        val rawNumber = prefix.toLongOrNull()
        val openedAtMillis = when {
            rawNumber == null -> now - index
            rawNumber < 100_000_000_000L -> now - rawNumber.coerceAtLeast(0L)
            else -> rawNumber
        }
        RecentPaperEntry(paperId, openedAtMillis)
    }
        .distinctBy { it.paperId }
        .sortedByDescending { it.openedAtMillis }
        .take(30)
}

private fun Set<String>.decodeOrderedStrings(): List<String> =
    sorted().map { encoded -> encoded.substringAfter(":", missingDelimiterValue = encoded) }

private fun Set<String>.decodeProgressMap(): Map<String, Float> =
    mapNotNull { encoded ->
        val separator = encoded.lastIndexOf(':')
        if (separator <= 0 || separator >= encoded.lastIndex) return@mapNotNull null
        val id = encoded.substring(0, separator)
        val progress = encoded.substring(separator + 1).toFloatOrNull()?.coerceIn(0f, 1f)
        progress?.let { id to it }
    }.toMap()

private fun Set<String>.withProgress(paperId: String, progress: Float): Set<String> {
    val prefix = "$paperId:"
    return filterNot { it.startsWith(prefix) }.toSet() + "$paperId:${progress.coerceIn(0f, 1f)}"
}

private fun Set<String>.withDailyCompletion(paperId: String): Set<String> {
    val today = todayKey()
    return this + "$today:$paperId"
}

private fun Set<String>.decodeDailyCompletions(): Map<String, Set<String>> =
    mapNotNull { encoded ->
        val separator = encoded.indexOf(':')
        if (separator <= 0 || separator >= encoded.lastIndex) return@mapNotNull null
        encoded.substring(0, separator) to encoded.substring(separator + 1)
    }
        .groupBy(keySelector = { it.first }, valueTransform = { it.second })
        .mapValues { (_, ids) -> ids.toSet() }

private fun Map<String, Set<String>>.currentStreak(): Int {
    var day = LocalDate.now(ZoneId.systemDefault())
    var streak = 0
    while (this[day.toString()].orEmpty().isNotEmpty()) {
        streak += 1
        day = day.minusDays(1)
    }
    return streak
}

private fun todayKey(): String = LocalDate.now(ZoneId.systemDefault()).toString()
