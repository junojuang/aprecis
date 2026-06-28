package com.aprecis.ui

import android.content.Context
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.Casino
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.FilterList
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.text.HtmlCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.aprecis.data.remote.dto.CardDeckDto
import com.aprecis.data.remote.dto.RelatedResponseDto
import com.aprecis.ui.lesson.WebLessonScreen
import com.aprecis.ui.theme.AmberAccent
import com.aprecis.ui.theme.CardBg
import com.aprecis.ui.theme.InkColor
import com.aprecis.ui.theme.MutedInk
import com.aprecis.ui.theme.PaperBg
import com.aprecis.ui.theme.ProgressGreen
import com.aprecis.ui.theme.TealAccent
import com.aprecis.ui.theme.TealLight
import kotlinx.coroutines.delay
import androidx.compose.runtime.setValue

@Composable
fun AprecisAppShell(viewModel: AprecisViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showLaunch by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        delay(1600)
        showLaunch = false
    }

    Box(Modifier.fillMaxSize()) {
        if (!state.onboardingCompleted) {
            OnboardingScreen(onFinish = viewModel::completeOnboarding)
        } else {
            when (val destination = state.destination) {
                Destination.Home -> RootScaffold(
                    state = state,
                    onTab = viewModel::selectTab,
                    onRefresh = viewModel::refresh,
                    onQuery = viewModel::updateQuery,
                    onTopicFilter = viewModel::updateSearchTopicFilter,
                    onTopic = viewModel::openTopic,
                    onRandom = viewModel::openRandomFocus,
                    onFocus = viewModel::openFocus,
                    onOpen = viewModel::openDeck,
                    onToggleSaved = viewModel::toggleSaved,
                    onUpdateDisplayName = viewModel::updateDisplayName,
                    onUpdateDailyGoal = viewModel::updateDailyGoal,
                    onUpdateNotifications = viewModel::updateNotificationsEnabled,
                    onReplayOnboarding = viewModel::replayOnboarding,
                    onResetLocalData = viewModel::resetLocalData,
                )

                is Destination.Focus -> FocusScreen(
                    deck = destination.deck,
                    related = state.related,
                    decks = state.decks,
                    trailDecks = state.focusTrailDecks,
                    isSaved = destination.deck.paperId in state.savedIds,
                    isCompleted = state.progressFor(destination.deck.paperId) >= 0.98f,
                    progressById = state.progressById,
                    onBack = viewModel::closeDestination,
                    onRandom = viewModel::openRandomFocus,
                    onFocus = viewModel::openRelatedFocus,
                    onTrail = viewModel::openTrailFocus,
                    onOpen = viewModel::openDeck,
                    onToggleSaved = { viewModel.toggleSaved(destination.deck.paperId) },
                )

                is Destination.Paper -> PaperDetailScreen(
                    deck = destination.deck,
                    related = state.related,
                    onBack = viewModel::closeDestination,
                    onOpen = viewModel::openDeck,
                    decks = state.decks,
                    isSaved = destination.deck.paperId in state.savedIds,
                    onToggleSaved = { viewModel.toggleSaved(destination.deck.paperId) },
                )

                is Destination.WebLesson -> WebLessonScreen(
                    paperId = destination.paperId,
                    title = destination.title,
                    url = destination.url,
                    isSaved = destination.paperId in state.savedIds,
                    onClose = viewModel::closeDestination,
                    onDone = { viewModel.finishLesson(destination.paperId) },
                    onMarkDone = { viewModel.markDone(destination.paperId) },
                    onToggleSaved = { viewModel.toggleSaved(destination.paperId) },
                    onInteraction = { action -> viewModel.mark(destination.paperId, action) },
                )
            }
        }

        if (showLaunch) {
            LaunchOverlay()
        }
    }
}

@Composable
private fun RootScaffold(
    state: AppUiState,
    onTab: (AppTab) -> Unit,
    onRefresh: () -> Unit,
    onQuery: (String) -> Unit,
    onTopicFilter: (Topic?) -> Unit,
    onTopic: (Topic) -> Unit,
    onRandom: () -> Unit,
    onFocus: (CardDeckDto) -> Unit,
    onOpen: (CardDeckDto) -> Unit,
    onToggleSaved: (String) -> Unit,
    onUpdateDisplayName: (String) -> Unit,
    onUpdateDailyGoal: (Int) -> Unit,
    onUpdateNotifications: (Boolean) -> Unit,
    onReplayOnboarding: () -> Unit,
    onResetLocalData: () -> Unit,
) {
    Scaffold(
        bottomBar = {
            NavigationBar(containerColor = CardBg, contentColor = InkColor) {
                NavigationBarItem(
                    selected = state.selectedTab == AppTab.Discover,
                    onClick = { onTab(AppTab.Discover) },
                    icon = { Icon(Icons.Outlined.Search, contentDescription = null) },
                    label = { Text("Discover") },
                )
                NavigationBarItem(
                    selected = state.selectedTab == AppTab.Profile,
                    onClick = { onTab(AppTab.Profile) },
                    icon = { Icon(Icons.Outlined.AccountCircle, contentDescription = null) },
                    label = { Text("Profile") },
                )
            }
        },
        containerColor = PaperBg,
    ) { padding ->
        when {
            state.loading && state.decks.isEmpty() -> Centered(padding) { CircularProgressIndicator(color = InkColor) }
            state.error != null && state.decks.isEmpty() -> ErrorState(padding, state.error, onRefresh)
            state.selectedTab == AppTab.Discover -> DiscoverScreen(
                padding = padding,
                state = state,
                onRefresh = onRefresh,
                onQuery = onQuery,
                onTopicFilter = onTopicFilter,
                onTopic = onTopic,
                onRandom = onRandom,
                onFocus = onFocus,
            )
            state.selectedTab == AppTab.Profile -> ProfileScreen(
                padding = padding,
                state = state,
                onOpen = onOpen,
                onToggleSaved = onToggleSaved,
                onUpdateDisplayName = onUpdateDisplayName,
                onUpdateDailyGoal = onUpdateDailyGoal,
                onUpdateNotifications = onUpdateNotifications,
                onReplayOnboarding = onReplayOnboarding,
                onResetLocalData = onResetLocalData,
            )
        }
    }
}

@Composable
private fun DiscoverScreen(
    padding: PaddingValues,
    state: AppUiState,
    onRefresh: () -> Unit,
    onQuery: (String) -> Unit,
    onTopicFilter: (Topic?) -> Unit,
    onTopic: (Topic) -> Unit,
    onRandom: () -> Unit,
    onFocus: (CardDeckDto) -> Unit,
) {
    var showTopics by remember { mutableStateOf(false) }
    Box(
        Modifier
            .fillMaxSize()
            .padding(padding)
            .background(discoverBackdrop()),
    ) {
        IconButton(
            onClick = onRefresh,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(top = 10.dp, end = 12.dp),
        ) {
            Icon(Icons.Outlined.Refresh, contentDescription = "Refresh", tint = MutedInk)
        }

        if (state.query.isBlank()) {
            Column(
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(horizontal = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Where should we begin?",
                        fontFamily = FontFamily.Serif,
                        fontSize = 28.sp,
                        color = InkColor,
                        textAlign = TextAlign.Center,
                    )
                    Text(
                        "A paper, a concept, or an idea.",
                        fontFamily = FontFamily.Serif,
                        fontSize = 14.sp,
                        color = MutedInk,
                        textAlign = TextAlign.Center,
                    )
                }
                DiscoverSearchBar(query = state.query, onQuery = onQuery)
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    DiscoverPill(Icons.Outlined.GridView, "Topics", onClick = { showTopics = true })
                    DiscoverPill(Icons.Outlined.Casino, "Random", onClick = onRandom)
                }
                TopicStrip(onTopic)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 20.dp)
                    .padding(top = 18.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    DiscoverSearchBar(query = state.query, onQuery = onQuery, modifier = Modifier.weight(1f))
                    TopicFilterButton(
                        activeTopic = state.searchTopicFilter,
                        onSelect = onTopicFilter,
                    )
                }
                SearchStatusRow(
                    resultCount = state.searchResultCount,
                    activeTopic = state.searchTopicFilter,
                    onClearFilter = { onTopicFilter(null) },
                )
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(bottom = 22.dp),
                ) {
                    if (state.searchResults.isEmpty()) {
                        item { EmptySearchState(state.query, state.searchTopicFilter) }
                    } else {
                        items(state.searchResults, key = { it.paperId }) { deck ->
                            SearchResultRow(deck = deck, onClick = { onFocus(deck) })
                        }
                    }
                }
            }
        }
    }
    if (showTopics) {
        TopicsDialog(
            decks = state.decks,
            onDismiss = { showTopics = false },
            onSelect = { topic ->
                showTopics = false
                onTopic(topic)
            },
        )
    }
}

@Composable
private fun DiscoverSearchBar(query: String, onQuery: (String) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(CardBg)
            .padding(horizontal = 14.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Outlined.Search, contentDescription = null, tint = if (query.isBlank()) MutedInk else TealAccent, modifier = Modifier.size(18.dp))
        BasicTextField(
            value = query,
            onValueChange = onQuery,
            singleLine = true,
            textStyle = TextStyle(color = InkColor, fontSize = 16.sp),
            modifier = Modifier.weight(1f),
            decorationBox = { inner ->
                if (query.isBlank()) Text("Search papers, topics, or tags", color = MutedInk, fontSize = 16.sp)
                inner()
            },
        )
        if (query.isNotBlank()) {
            TextButton(onClick = { onQuery("") }) { Text("Clear", color = MutedInk) }
        }
    }
}

@Composable
private fun SearchStatusRow(
    resultCount: Int,
    activeTopic: Topic?,
    onClearFilter: () -> Unit,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth().padding(start = 2.dp),
    ) {
        if (resultCount > 0) {
            Text(
                "$resultCount ${if (resultCount == 1) "result" else "results"} found",
                color = MutedInk,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
            )
        }
        if (activeTopic != null) {
            Text(
                activeTopic.label,
                color = activeTopic.color,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .clip(RoundedCornerShape(999.dp))
                    .background(CardBg)
                    .clickable(onClick = onClearFilter)
                    .padding(horizontal = 9.dp, vertical = 4.dp),
            )
        }
    }
}

@Composable
private fun TopicFilterButton(activeTopic: Topic?, onSelect: (Topic?) -> Unit) {
    var showFilter by remember { mutableStateOf(false) }
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(CardBg)
            .clickable { showFilter = true },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Outlined.FilterList,
            contentDescription = "Filter search by topic",
            tint = activeTopic?.color ?: MutedInk,
            modifier = Modifier.size(20.dp),
        )
    }
    if (showFilter) {
        TopicFilterDialog(
            activeTopic = activeTopic,
            onDismiss = { showFilter = false },
            onSelect = {
                onSelect(it)
                showFilter = false
            },
        )
    }
}

@Composable
private fun TopicFilterDialog(
    activeTopic: Topic?,
    onDismiss: () -> Unit,
    onSelect: (Topic?) -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                SectionKicker("FILTER RESULTS", TealAccent)
                Text("Search topics", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            }
        },
        text = {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.height(420.dp)) {
                item {
                    FilterTopicRow(
                        label = "All topics",
                        color = TealAccent,
                        selected = activeTopic == null,
                        onClick = { onSelect(null) },
                    )
                }
                items(Topic.all) { topic ->
                    FilterTopicRow(
                        label = topic.label,
                        color = topic.color,
                        selected = topic == activeTopic,
                        onClick = { onSelect(topic) },
                    )
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done", color = TealAccent) } },
    )
}

@Composable
private fun FilterTopicRow(label: String, color: Color, selected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (selected) color.copy(alpha = 0.10f) else CardBg)
            .clickable(onClick = onClick)
            .padding(horizontal = 13.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Box(Modifier.size(6.dp).clip(CircleShape).background(color))
        Text(label, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 14.sp, modifier = Modifier.weight(1f))
        if (selected) Icon(Icons.Outlined.Check, contentDescription = null, tint = color, modifier = Modifier.size(15.dp))
    }
}

@Composable
private fun DiscoverPill(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(22.dp))
            .background(CardBg)
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Icon(icon, contentDescription = null, tint = InkColor, modifier = Modifier.size(16.dp))
        Text(title, color = InkColor, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
    }
}

@Composable
private fun TopicStrip(onTopic: (Topic) -> Unit) {
    Row(
        modifier = Modifier
            .horizontalScroll(rememberScrollState())
            .padding(top = 2.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Topic.all.forEach { topic ->
            Text(
                topic.label,
                color = topic.color,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .clip(RoundedCornerShape(18.dp))
                    .background(CardBg)
                    .clickable { onTopic(topic) }
                    .padding(horizontal = 12.dp, vertical = 7.dp),
            )
        }
    }
}

@Composable
private fun TopicsDialog(
    decks: List<CardDeckDto>,
    onDismiss: () -> Unit,
    onSelect: (Topic) -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = {
            Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
                SectionKicker("RESEARCH, BY THEME", TealAccent)
                Text("Explore topics", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 30.sp, fontWeight = FontWeight.Bold)
            }
        },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.height(460.dp),
            ) {
                item {
                    FeaturedTopicCard(
                        topic = Topic.all.first(),
                        count = topicCount(decks, Topic.all.first()),
                        onClick = { onSelect(Topic.all.first()) },
                    )
                }
                items(Topic.all.drop(1).chunked(2)) { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                        row.forEach { topic ->
                            CompactTopicCard(
                                topic = topic,
                                count = topicCount(decks, topic),
                                onClick = { onSelect(topic) },
                                modifier = Modifier.weight(1f),
                            )
                        }
                        if (row.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done", color = TealAccent) } },
    )
}

@Composable
private fun FeaturedTopicCard(topic: Topic, count: Int, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(CardBg)
            .clickable(onClick = onClick)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        TopicGlyph(topic, modifier = Modifier.fillMaxWidth().height(110.dp))
        Text(topic.label, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 23.sp, fontWeight = FontWeight.Bold, lineHeight = 26.sp)
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(topic.blurb, color = MutedInk, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 13.sp, lineHeight = 18.sp, modifier = Modifier.weight(1f))
            if (count > 0) Text("$count", color = topic.color, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontWeight = FontWeight.SemiBold)
            Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = topic.color, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun CompactTopicCard(
    topic: Topic,
    count: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(118.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(CardBg),
            contentAlignment = Alignment.Center,
        ) {
            TopicGlyph(topic, compact = true, modifier = Modifier.fillMaxWidth().height(92.dp).padding(8.dp))
        }
        Text(topic.label, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, lineHeight = 18.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
        if (count > 0) Text("$count papers", color = MutedInk, fontSize = 10.sp)
    }
}

@Composable
private fun TopicGlyph(topic: Topic, compact: Boolean = false, modifier: Modifier = Modifier) {
    val size = if (compact) 54.dp else 72.dp
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Box(
            modifier = Modifier
                .width(if (compact) 120.dp else 170.dp)
                .height(if (compact) 58.dp else 78.dp)
                .clip(CircleShape)
                .background(topic.color.copy(alpha = 0.10f))
                .align(Alignment.BottomCenter),
        )
        listOf(-18.dp, 18.dp, 0.dp).forEachIndexed { index, x ->
            Box(
                modifier = Modifier
                    .size(size)
                    .offset(x = x, y = if (index == 2) 0.dp else 6.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (index == 2) CardBg else topic.color.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center,
            ) {
                if (index == 2) {
                    Text(topic.mark, color = topic.color, fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold, fontSize = if (compact) 22.sp else 28.sp)
                }
            }
        }
    }
}

@Composable
private fun SearchResultRow(deck: CardDeckDto, onClick: () -> Unit) {
    val topic = Topic.forDeck(deck)
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = CardBg),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                MetaLabel(topic)
                Text(
                    cleanDisplayText(deck.title ?: deck.paperId),
                    color = InkColor,
                    fontFamily = FontFamily.Serif,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                deck.bestSubtitle()?.let {
                    Text(
                        cleanDisplayText(it),
                        color = MutedInk,
                        fontFamily = FontFamily.Serif,
                        fontStyle = FontStyle.Italic,
                        fontSize = 12.sp,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = TealAccent, modifier = Modifier.size(17.dp))
        }
    }
}

@Composable
private fun FocusScreen(
    deck: CardDeckDto,
    related: RelatedResponseDto?,
    decks: List<CardDeckDto>,
    trailDecks: List<CardDeckDto>,
    isSaved: Boolean,
    isCompleted: Boolean,
    progressById: Map<String, Float>,
    onBack: () -> Unit,
    onRandom: () -> Unit,
    onFocus: (CardDeckDto) -> Unit,
    onTrail: (CardDeckDto) -> Unit,
    onOpen: (CardDeckDto) -> Unit,
    onToggleSaved: () -> Unit,
) {
    val topic = Topic.forDeck(deck)
    val byId = decks.associateBy { it.paperId }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(focusBackdrop(topic)),
    ) {
        LazyColumn(
            contentPadding = PaddingValues(start = 22.dp, end = 22.dp, top = 66.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (trailDecks.isNotEmpty()) {
                        TrailStrip(
                            trailDecks = trailDecks,
                            currentDeck = deck,
                            onTrail = onTrail,
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        MetaLabel(topic)
                        if (isCompleted) {
                            Text("READ", color = ProgressGreen, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                            Icon(Icons.Outlined.Check, contentDescription = null, tint = ProgressGreen, modifier = Modifier.size(12.dp))
                        }
                        Text("· ${estimatedReadMinutes(deck)} min read", color = MutedInk, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 10.sp)
                    }
                    Text(
                        cleanDisplayText(deck.title ?: deck.paperId),
                        color = InkColor,
                        fontFamily = FontFamily.Serif,
                        fontSize = 28.sp,
                        lineHeight = 32.sp,
                    )
                    deck.bestSubtitle()?.let {
                        Text(
                            cleanDisplayText(it),
                            color = MutedInk,
                            fontFamily = FontFamily.Serif,
                            fontStyle = FontStyle.Italic,
                            fontSize = 14.sp,
                            lineHeight = 20.sp,
                        )
                    }
                }
            }
            item {
                RelatedTabs(related = related, byId = byId, progressById = progressById, onFocus = onFocus)
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier
                            .weight(1f)
                            .height(46.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(TealAccent)
                            .clickable { onOpen(deck) },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        Text("Open paper", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                    }
                    Box(
                        modifier = Modifier
                            .size(46.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(CardBg)
                            .clickable(onClick = onToggleSaved),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(if (isSaved) Icons.Outlined.Bookmark else Icons.Outlined.BookmarkBorder, contentDescription = if (isSaved) "Unsave" else "Save", tint = if (isSaved) TealAccent else InkColor)
                    }
                }
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(CardBg),
            ) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Back", tint = InkColor, modifier = Modifier.size(18.dp))
            }
            DiscoverPill(Icons.Outlined.Casino, "Random", onClick = onRandom)
        }
    }
}

@Composable
private fun TrailStrip(
    trailDecks: List<CardDeckDto>,
    currentDeck: CardDeckDto,
    onTrail: (CardDeckDto) -> Unit,
) {
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        trailDecks.forEach { deck ->
            TrailChip(
                title = shortTitle(deck),
                active = false,
                onClick = { onTrail(deck) },
            )
            Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = MutedInk.copy(alpha = 0.55f), modifier = Modifier.size(10.dp))
        }
        TrailChip(title = shortTitle(currentDeck), active = true, onClick = {})
    }
}

@Composable
private fun TrailChip(title: String, active: Boolean, onClick: () -> Unit) {
    Text(
        title,
        color = if (active) InkColor else MutedInk,
        fontFamily = FontFamily.Serif,
        fontSize = 10.sp,
        fontWeight = if (active) FontWeight.Bold else FontWeight.SemiBold,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(if (active) Color.Transparent else Color.White)
            .then(if (active) Modifier else Modifier.clickable(onClick = onClick))
            .padding(horizontal = 9.dp, vertical = 4.dp),
    )
}

@Composable
private fun RelatedTabs(
    related: RelatedResponseDto?,
    byId: Map<String, CardDeckDto>,
    progressById: Map<String, Float>,
    onFocus: (CardDeckDto) -> Unit,
) {
    val rails = remember(related, byId) {
        RailKind.entries.map { kind ->
            kind to kind.ids(related).mapNotNull { byId[it] }
        }
    }
    val availableRails = rails.filter { it.second.isNotEmpty() }
    var activeRail by remember(related) { mutableStateOf(RailKind.BuildsOn) }
    LaunchedEffect(availableRails.map { it.first }) {
        if (availableRails.isNotEmpty() && availableRails.none { it.first == activeRail }) {
            activeRail = availableRails.first().first
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        when {
            related == null -> {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp, color = MutedInk)
                Text("Finding related papers", color = MutedInk, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 12.sp)
            }
            }
            availableRails.isEmpty() -> EmptyPanel("No related papers yet.")
            else -> {
                RailTabBar(
                    rails = availableRails,
                    active = activeRail,
                    onActive = { activeRail = it },
                )
                val activeDecks = availableRails.firstOrNull { it.first == activeRail }?.second.orEmpty()
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    activeDecks.forEach { deck ->
                        RelatedCard(
                            deck = deck,
                            progress = progressById[deck.paperId] ?: 0f,
                            accent = activeRail.color,
                            onClick = { onFocus(deck) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RailTabBar(
    rails: List<Pair<RailKind, List<CardDeckDto>>>,
    active: RailKind,
    onActive: (RailKind) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.Top, modifier = Modifier.fillMaxWidth()) {
            rails.forEachIndexed { index, (kind, decks) ->
                if (index > 0) {
                    Box(
                        Modifier
                            .padding(horizontal = 14.dp, vertical = 2.dp)
                            .width(1.dp)
                            .height(16.dp)
                            .background(InkColor.copy(alpha = 0.18f)),
                    )
                }
                RailTab(
                    kind = kind,
                    count = decks.size,
                    active = kind == active,
                    onClick = { onActive(kind) },
                    modifier = Modifier.weight(1f),
                )
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(InkColor.copy(alpha = 0.08f)))
    }
}

@Composable
private fun RailTab(
    kind: RailKind,
    count: Int,
    active: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Text(
            kind.label,
            color = if (active) InkColor else MutedInk.copy(alpha = 0.86f),
            fontFamily = FontFamily.Serif,
            fontSize = 15.sp,
            fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(2.dp)
                .background(if (active) kind.color else Color.Transparent),
        )
        Text(
            "$count",
            color = if (active) kind.color else MutedInk.copy(alpha = 0.55f),
            fontSize = 10.sp,
            fontWeight = FontWeight.Medium,
            letterSpacing = 0.4.sp,
        )
    }
}

@Composable
private fun RelatedCard(
    deck: CardDeckDto,
    progress: Float = 0f,
    accent: Color = TealAccent,
    onClick: () -> Unit,
) {
    val topic = Topic.forDeck(deck)
    val isRead = progress >= 0.98f
    Card(
        modifier = Modifier
            .width(180.dp)
            .height(140.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = CardBg),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            MetaLabel(topic)
            Text(
                cleanDisplayText(deck.title ?: deck.paperId),
                color = InkColor,
                fontFamily = FontFamily.Serif,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.weight(1f))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                if (isRead) ReadStamp()
                Spacer(Modifier.weight(1f))
                Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = accent, modifier = Modifier.size(15.dp))
            }
        }
    }
}

@Composable
private fun ReadStamp() {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Text("read", color = TealAccent, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 11.sp)
        Icon(Icons.Outlined.Check, contentDescription = null, tint = TealAccent.copy(alpha = 0.75f), modifier = Modifier.size(10.dp))
    }
}

@Composable
private fun ProfileScreen(
    padding: PaddingValues,
    state: AppUiState,
    onOpen: (CardDeckDto) -> Unit,
    onToggleSaved: (String) -> Unit,
    onUpdateDisplayName: (String) -> Unit,
    onUpdateDailyGoal: (Int) -> Unit,
    onUpdateNotifications: (Boolean) -> Unit,
    onReplayOnboarding: () -> Unit,
    onResetLocalData: () -> Unit,
) {
    var showNameDialog by remember { mutableStateOf(false) }
    var showGoalDialog by remember { mutableStateOf(false) }
    var showSettingsDialog by remember { mutableStateOf(false) }
    var showClearDataConfirm by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val appVersion = remember(context) { context.aprecisVersionName() }
    val displayName = state.displayName.ifBlank { "Reader" }
    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(padding).background(PaperBg),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 22.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        item {
            IdentityHeader(
                displayName = displayName,
                onEditName = { showNameDialog = true },
                onSettings = { showSettingsDialog = true },
            )
        }
        item {
            GoalCard(
                read = state.todayCompletedCount,
                goal = state.dailyGoal,
                streak = state.currentStreak,
                onClick = { showGoalDialog = true },
            )
        }
        item {
            LibraryHeader(count = state.savedDecks.size)
        }
        if (state.savedDecks.isEmpty()) {
            item { EmptyShelf() }
        } else {
            item {
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    state.savedDecks.forEach { deck ->
                        BookSpine(
                            deck = deck,
                            progress = state.progressFor(deck.paperId),
                            onClick = { onOpen(deck) },
                            onToggleSaved = { onToggleSaved(deck.paperId) },
                        )
                    }
                }
            }
        }
        if (state.recentDeckEntries.isNotEmpty()) {
            item { SectionKicker("RECENTLY OPENED", AmberAccent) }
            item {
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    state.recentDeckEntries.take(8).forEach { entry ->
                        RecentChip(
                            deck = entry.deck,
                            openedAtMillis = entry.openedAtMillis,
                            progress = state.progressFor(entry.deck.paperId),
                            onClick = { onOpen(entry.deck) },
                        )
                    }
                }
            }
        }
    }

    if (showNameDialog) {
        EditDisplayNameDialog(
            current = state.displayName,
            onDismiss = { showNameDialog = false },
            onSave = {
                onUpdateDisplayName(it)
                showNameDialog = false
            },
        )
    }
    if (showGoalDialog) {
        DailyGoalDialog(
            current = state.dailyGoal,
            onDismiss = { showGoalDialog = false },
            onSave = {
                onUpdateDailyGoal(it)
                showGoalDialog = false
            },
        )
    }
    if (showSettingsDialog) {
        SettingsDialog(
            displayName = displayName,
            dailyGoal = state.dailyGoal,
            notificationsEnabled = state.notificationsEnabled,
            appVersion = appVersion,
            onDismiss = { showSettingsDialog = false },
            onEditName = {
                showSettingsDialog = false
                showNameDialog = true
            },
            onEditGoal = {
                showSettingsDialog = false
                showGoalDialog = true
            },
            onUpdateNotifications = onUpdateNotifications,
            onReplayOnboarding = {
                onReplayOnboarding()
                showSettingsDialog = false
            },
            onResetLocalData = {
                showSettingsDialog = false
                showClearDataConfirm = true
            },
        )
    }
    if (showClearDataConfirm) {
        ClearLocalDataDialog(
            onDismiss = { showClearDataConfirm = false },
            onConfirm = {
                onResetLocalData()
                showClearDataConfirm = false
            },
        )
    }
}

@Composable
private fun IdentityHeader(
    displayName: String,
    onEditName: () -> Unit,
    onSettings: () -> Unit,
) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(TealLight)
                .clickable(onClick = onEditName),
            contentAlignment = Alignment.Center,
        ) {
            Text(displayName.take(1).uppercase(), color = TealAccent, fontFamily = FontFamily.Serif, fontSize = 22.sp, fontWeight = FontWeight.SemiBold)
        }
        Text(
            displayName,
            color = InkColor,
            fontFamily = FontFamily.Serif,
            fontSize = 24.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f).clickable(onClick = onEditName),
        )
        Box(modifier = Modifier.size(36.dp).clip(CircleShape).background(TealLight).clickable(onClick = onSettings), contentAlignment = Alignment.Center) {
            Icon(Icons.Outlined.Settings, contentDescription = "Settings", tint = TealAccent, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun GoalCard(read: Int, goal: Int, streak: Int, onClick: () -> Unit) {
    val progress = (read.toFloat() / goal.toFloat()).coerceIn(0f, 1f)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(CardBg)
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Box(Modifier.size(56.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(progress = { 1f }, color = InkColor.copy(alpha = 0.10f), strokeWidth = 4.dp)
            CircularProgressIndicator(progress = { progress }, color = if (read >= goal) ProgressGreen else TealAccent, strokeWidth = 4.dp)
            Text("$read/$goal", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        }
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("TODAY'S GOAL", color = MutedInk, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.4.sp)
            Text(goalHeadline(read = read, goal = goal), color = InkColor, fontFamily = FontFamily.Serif, fontSize = 15.sp)
            Text(goalSubcopy(streak), color = MutedInk, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 11.sp)
        }
    }
}

private fun goalHeadline(read: Int, goal: Int): String =
    when {
        read == 0 -> "Begin today's reading"
        read >= goal -> "Goal hit. Streak safe."
        goal - read == 1 -> "1 more to lock in today"
        else -> "${goal - read} more to lock in today"
    }

private fun goalSubcopy(streak: Int): String =
    when (streak) {
        0 -> "Tap to set your daily target"
        1 -> "1 day streak"
        else -> "$streak day streak"
    }

@Composable
private fun LibraryHeader(count: Int) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        SectionKicker("FROM YOUR SHELF", TealAccent)
        Row(verticalAlignment = Alignment.Bottom) {
            Text("Library", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 30.sp)
            Spacer(Modifier.weight(1f))
            if (count > 0) Text("$count", color = TealAccent, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontWeight = FontWeight.SemiBold)
        }
        Text(
            if (count == 0) "Nothing saved yet. Bookmark a paper to start your shelf." else "$count ${if (count == 1) "paper" else "papers"} saved · tap to revisit",
            color = MutedInk,
            fontFamily = FontFamily.Serif,
            fontStyle = FontStyle.Italic,
            fontSize = 13.sp,
        )
    }
}

@Composable
private fun BookSpine(deck: CardDeckDto, progress: Float, onClick: () -> Unit, onToggleSaved: () -> Unit) {
    Box(
        modifier = Modifier
            .width(48.dp)
            .height((112 + (stableHash(deck.paperId) % 52)).dp)
            .clip(RoundedCornerShape(topStart = 6.dp, topEnd = 6.dp))
            .background(spineColor(deck.paperId))
            .clickable(onClick = onClick)
            .padding(7.dp),
    ) {
        Text(
            cleanDisplayText(deck.title ?: deck.paperId),
            color = Color.White,
            fontFamily = FontFamily.Serif,
            fontSize = 11.sp,
            maxLines = 5,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.align(Alignment.TopCenter),
        )
        Icon(
            Icons.Outlined.Bookmark,
            contentDescription = "Unsave",
            tint = Color.White.copy(alpha = 0.86f),
            modifier = Modifier.align(Alignment.BottomCenter).size(15.dp).clickable(onClick = onToggleSaved),
        )
        if (progress > 0.001f) {
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .height(3.dp)
                    .background(Color.White.copy(alpha = 0.20f)),
            )
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth(progress.coerceIn(0f, 1f))
                    .height(3.dp)
                    .background(if (progress >= 0.98f) ProgressGreen else TealLight),
            )
        }
    }
}

@Composable
private fun RecentChip(deck: CardDeckDto, openedAtMillis: Long, progress: Float, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .width(164.dp)
            .height(80.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(CardBg)
            .clickable(onClick = onClick),
    ) {
        Column(
            Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(cleanDisplayText(deck.title ?: deck.paperId), color = InkColor, fontFamily = FontFamily.Serif, fontSize = 12.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(Icons.Outlined.Schedule, contentDescription = null, tint = MutedInk, modifier = Modifier.size(10.dp))
                Text(relativeVisit(openedAtMillis), color = MutedInk, fontSize = 10.sp, fontWeight = FontWeight.Medium)
            }
        }
        if (progress > 0.001f) {
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .height(3.dp)
                    .background(MutedInk.copy(alpha = 0.15f)),
            )
            Box(
                Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth(progress.coerceIn(0f, 1f))
                    .height(3.dp)
                    .background(if (progress >= 0.98f) ProgressGreen else TealAccent),
            )
        }
    }
}

private fun relativeVisit(openedAtMillis: Long): String {
    val elapsedSeconds = ((System.currentTimeMillis() - openedAtMillis).coerceAtLeast(0L)) / 1000L
    if (elapsedSeconds < 60L) return "Just now"
    val minutes = elapsedSeconds / 60L
    if (minutes < 60L) return if (minutes == 1L) "1 minute ago" else "$minutes minutes ago"
    val hours = elapsedSeconds / 3600L
    if (hours < 24L) return if (hours == 1L) "1 hour ago" else "$hours hours ago"
    val days = elapsedSeconds / 86400L
    if (days == 1L) return "Yesterday"
    if (days < 7L) return "$days days ago"
    val weeks = days / 7L
    return if (weeks == 1L) "1 week ago" else "$weeks weeks ago"
}

@Composable
private fun EmptyShelf() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier.size(72.dp).clip(CircleShape).background(CardBg),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.BookmarkBorder, contentDescription = null, tint = MutedInk)
        }
        Text("Your shelf is empty", color = InkColor, fontFamily = FontFamily.Serif, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
        Text("Tap the bookmark on any paper to keep it here.", color = MutedInk, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 12.sp, textAlign = TextAlign.Center)
    }
}

@Composable
private fun EditDisplayNameDialog(
    current: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
) {
    var draft by remember(current) { mutableStateOf(current) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = { Text("Display name", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 22.sp) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text("How you'll appear in Aprecis. Leave blank to stay Reader.", color = MutedInk, fontSize = 13.sp)
                BasicTextField(
                    value = draft,
                    onValueChange = { draft = it },
                    singleLine = true,
                    textStyle = TextStyle(color = InkColor, fontFamily = FontFamily.Serif, fontSize = 16.sp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(CardBg)
                        .padding(14.dp),
                    decorationBox = { inner ->
                        if (draft.isBlank()) Text("e.g. Justin", color = MutedInk, fontFamily = FontFamily.Serif, fontSize = 16.sp)
                        inner()
                    },
                )
            }
        },
        confirmButton = { TextButton(onClick = { onSave(draft) }) { Text("Save", color = TealAccent) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel", color = MutedInk) } },
    )
}

@Composable
private fun DailyGoalDialog(
    current: Int,
    onDismiss: () -> Unit,
    onSave: (Int) -> Unit,
) {
    var draft by remember(current) { mutableIntStateOf(current.coerceIn(1, 20)) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = { Text("Daily goal", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 22.sp) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Papers to read each day. Streak counts any day you hit at least one.", color = MutedInk, fontSize = 13.sp)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    StepperButton("−", enabled = draft > 1) { if (draft > 1) draft -= 1 }
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text("$draft", color = TealAccent, fontFamily = FontFamily.Serif, fontSize = 56.sp)
                        Text(if (draft == 1) "PAPER / DAY" else "PAPERS / DAY", color = MutedInk, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.4.sp)
                    }
                    StepperButton("+", enabled = draft < 20) { if (draft < 20) draft += 1 }
                }
            }
        },
        confirmButton = { TextButton(onClick = { onSave(draft) }) { Text("Save goal", color = TealAccent) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel", color = MutedInk) } },
    )
}

@Composable
private fun StepperButton(text: String, enabled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(46.dp)
            .clip(CircleShape)
            .background(CardBg)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, color = if (enabled) InkColor else MutedInk.copy(alpha = 0.5f), fontSize = 22.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun SettingsDialog(
    displayName: String,
    dailyGoal: Int,
    notificationsEnabled: Boolean,
    appVersion: String,
    onDismiss: () -> Unit,
    onEditName: () -> Unit,
    onEditGoal: () -> Unit,
    onUpdateNotifications: (Boolean) -> Unit,
    onReplayOnboarding: () -> Unit,
    onResetLocalData: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = { Text("Settings", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 22.sp) },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(18.dp),
                modifier = Modifier.height(520.dp),
            ) {
                item {
                    SettingsSection(title = "Preferences") {
                        SettingsRow("Daily goal", "$dailyGoal ${if (dailyGoal == 1) "paper" else "papers"}", onEditGoal)
                        SettingsDivider()
                        SettingsRow("Display name", displayName, onEditName)
                        SettingsDivider()
                        SettingsToggleRow("Notifications", notificationsEnabled, onUpdateNotifications)
                        SettingsDivider()
                        SettingsRow("Replay onboarding", "Show", onReplayOnboarding)
                    }
                }
                item {
                    SettingsSection(title = "Account") {
                        SettingsStaticRow("Version", appVersion)
                    }
                }
                item {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        TextButton(onClick = onResetLocalData) {
                            Text("Clear local data", color = MutedInk, fontSize = 12.sp, fontWeight = FontWeight.Medium)
                        }
                        Text(
                            "Clears your reading progress, streaks and saved papers from this device. This cannot be undone.",
                            color = MutedInk.copy(alpha = 0.85f),
                            fontFamily = FontFamily.Serif,
                            fontStyle = FontStyle.Italic,
                            fontSize = 10.sp,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done", color = TealAccent) } },
    )
}

@Composable
private fun SettingsSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 18.sp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CardBg),
            content = content,
        )
    }
}

@Composable
private fun SettingsDivider() {
    Box(Modifier.fillMaxWidth().padding(start = 16.dp).height(1.dp).background(InkColor.copy(alpha = 0.08f)))
}

@Composable
private fun SettingsRow(label: String, value: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label.uppercase(), color = MutedInk, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.6.sp)
        Spacer(Modifier.weight(1f))
        Text(value, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Spacer(Modifier.width(8.dp))
        Icon(Icons.AutoMirrored.Outlined.ArrowForward, contentDescription = null, tint = MutedInk.copy(alpha = 0.7f), modifier = Modifier.size(13.dp))
    }
}

@Composable
private fun SettingsStaticRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label.uppercase(), color = MutedInk, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.6.sp)
        Spacer(Modifier.weight(1f))
        Text(value, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun SettingsToggleRow(label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label.uppercase(), color = MutedInk, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.6.sp)
        Spacer(Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun ClearLocalDataDialog(onDismiss: () -> Unit, onConfirm: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = PaperBg,
        title = { Text("Clear local data?", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 22.sp) },
        text = {
            Text(
                "Removes reading progress, streaks and saved papers from this device. Cannot be undone.",
                color = MutedInk,
                fontFamily = FontFamily.Serif,
                fontStyle = FontStyle.Italic,
                fontSize = 13.sp,
            )
        },
        confirmButton = { TextButton(onClick = onConfirm) { Text("Clear", color = Color(0xFFB43A3A)) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel", color = MutedInk) } },
    )
}

@Composable
private fun OnboardingScreen(onFinish: () -> Unit) {
    var page by remember { mutableIntStateOf(0) }
    val pages = OnboardingPage.all
    Box(Modifier.fillMaxSize().background(PaperBg)) {
        TextButton(
            onClick = onFinish,
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 18.dp, end = 20.dp),
        ) { Text("Skip", color = MutedInk, fontWeight = FontWeight.SemiBold) }

        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            OnboardingIllustration(pages[page].kind)
            Spacer(Modifier.height(28.dp))
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(pages[page].eyebrow, color = TealAccent, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.8.sp)
                Text(pages[page].title, color = InkColor, fontFamily = FontFamily.Serif, fontSize = 30.sp, lineHeight = 34.sp)
                Text(pages[page].body, color = MutedInk, fontFamily = FontFamily.Serif, fontSize = 14.sp, lineHeight = 20.sp)
                pages[page].footnote?.let {
                    Text(it, color = MutedInk.copy(alpha = 0.85f), fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 12.sp, lineHeight = 17.sp)
                }
            }
            Spacer(Modifier.weight(1f))
            Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                pages.indices.forEach { idx ->
                    Box(
                        Modifier
                            .width(if (idx == page) 22.dp else 6.dp)
                            .height(6.dp)
                            .clip(RoundedCornerShape(6.dp))
                            .background(if (idx == page) TealAccent else MutedInk.copy(alpha = 0.25f)),
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(InkColor)
                    .clickable {
                        if (page < pages.lastIndex) page += 1 else onFinish()
                    },
                contentAlignment = Alignment.Center,
            ) {
                Text(if (page == pages.lastIndex) "Start reading" else "Continue", color = Color.White, fontWeight = FontWeight.Bold, letterSpacing = 0.6.sp)
            }
            TextButton(
                onClick = { if (page > 0) page -= 1 },
                enabled = page > 0,
            ) {
                Text("Back", color = if (page > 0) MutedInk else Color.Transparent, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun OnboardingIllustration(kind: OnboardingKind) {
    when (kind) {
        OnboardingKind.Welcome -> Box(Modifier.size(220.dp).clip(CircleShape).background(TealLight), contentAlignment = Alignment.Center) {
            Text("a", color = TealAccent, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 180.sp)
        }
        OnboardingKind.Daily -> Box(Modifier.width(230.dp).height(230.dp), contentAlignment = Alignment.Center) {
            repeat(3) { idx ->
                Box(
                    Modifier
                        .width(170.dp)
                        .height(220.dp)
                        .offset(x = (-10 * idx).dp, y = (-8 * idx).dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(CardBg),
                )
            }
            Column(
                Modifier
                    .width(156.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBg)
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text("TODAY · 7 MIN", color = TealAccent, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.4.sp)
                Box(Modifier.fillMaxWidth().height(9.dp).clip(RoundedCornerShape(2.dp)).background(InkColor.copy(alpha = 0.85f)))
                Box(Modifier.width(110.dp).height(9.dp).clip(RoundedCornerShape(2.dp)).background(InkColor.copy(alpha = 0.85f)))
                Box(Modifier.fillMaxWidth().height(5.dp).clip(RoundedCornerShape(2.dp)).background(MutedInk.copy(alpha = 0.4f)))
                Box(Modifier.width(100.dp).height(5.dp).clip(RoundedCornerShape(2.dp)).background(MutedInk.copy(alpha = 0.4f)))
            }
        }
        OnboardingKind.Library -> Column(Modifier.width(240.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            repeat(2) {
                Row(
                    Modifier.clip(RoundedCornerShape(12.dp)).background(CardBg).padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Box(Modifier.size(28.dp).clip(CircleShape).background(TealLight), contentAlignment = Alignment.Center) {
                        Icon(Icons.Outlined.Bookmark, contentDescription = null, tint = TealAccent, modifier = Modifier.size(15.dp))
                    }
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Box(Modifier.width(if (it == 0) 130.dp else 110.dp).height(8.dp).clip(RoundedCornerShape(2.dp)).background(InkColor.copy(alpha = 0.8f)))
                        Box(Modifier.width(if (it == 0) 90.dp else 70.dp).height(5.dp).clip(RoundedCornerShape(2.dp)).background(MutedInk.copy(alpha = 0.5f)))
                    }
                }
            }
        }
        OnboardingKind.Glossary -> Column(Modifier.width(280.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Text("Stack attention layers and depth becomes capacity.", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 15.sp, textAlign = TextAlign.Center)
            Column(Modifier.width(240.dp).clip(RoundedCornerShape(12.dp)).background(CardBg).padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("ATTENTION", color = TealAccent, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.4.sp)
                Text("A mechanism that lets each token weigh every other token by relevance.", color = InkColor, fontFamily = FontFamily.Serif, fontSize = 12.sp, lineHeight = 16.sp)
            }
        }
    }
}

@Composable
private fun LaunchOverlay() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(Color(0xFFF9F8F4), PaperBg, Color(0xFFF1EDE5)),
                ),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .size(280.dp)
                .background(Brush.radialGradient(listOf(TealAccent.copy(alpha = 0.18f), Color.Transparent))),
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(22.dp)) {
            Box(Modifier.size(76.dp).clip(RoundedCornerShape(20.dp)).background(TealAccent), contentAlignment = Alignment.Center) {
                Text("a", color = Color.White, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 54.sp)
            }
            Row {
                Text("aprecis", color = TealAccent, fontFamily = FontFamily.Serif, fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
                Text(".", color = InkColor, fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
            }
            LinearProgressIndicator(
                modifier = Modifier.width(132.dp).height(2.dp),
                color = TealAccent,
                trackColor = InkColor.copy(alpha = 0.08f),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PaperDetailScreen(
    deck: CardDeckDto,
    related: RelatedResponseDto?,
    onBack: () -> Unit,
    onOpen: (CardDeckDto) -> Unit,
    decks: List<CardDeckDto>,
    isSaved: Boolean,
    onToggleSaved: () -> Unit,
) {
    val byId = decks.associateBy { it.paperId }
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(cleanDisplayText(deck.title ?: deck.paperId), maxLines = 1, overflow = TextOverflow.Ellipsis) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onToggleSaved) {
                        Icon(
                            if (isSaved) Icons.Outlined.Bookmark else Icons.Outlined.BookmarkBorder,
                            contentDescription = if (isSaved) "Unsave" else "Save",
                        )
                    }
                },
            )
        },
        containerColor = PaperBg,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Text(cleanDisplayText(deck.title ?: deck.paperId), style = MaterialTheme.typography.headlineSmall, fontFamily = FontFamily.Serif)
                deck.summary?.let {
                    Text(
                        cleanDisplayText(it),
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(top = 10.dp),
                    )
                }
            }
            item {
                Text("Concepts", style = MaterialTheme.typography.titleMedium)
            }
            items(deck.concepts) { concept ->
                Card(colors = CardDefaults.cardColors(containerColor = CardBg)) {
                    Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(cleanDisplayText(concept.title), fontWeight = FontWeight.SemiBold)
                        Text(cleanDisplayText(concept.body), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            related?.let { rails ->
                item { Text("Connections", style = MaterialTheme.typography.titleMedium) }
                item {
                    RelatedRail("Builds on", rails.buildsOn, byId, onOpen)
                    RelatedRail("Led to", rails.ledTo, byId, onOpen)
                    RelatedRail("Adjacent", rails.adjacent, byId, onOpen)
                }
            }
        }
    }
}

@Composable
private fun RelatedRail(
    title: String,
    ids: List<String>,
    byId: Map<String, CardDeckDto>,
    onOpen: (CardDeckDto) -> Unit,
) {
    if (ids.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(bottom = 12.dp)) {
        Text(title, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
        ids.mapNotNull { byId[it] }.forEach { deck ->
            TextButton(onClick = { onOpen(deck) }) {
                Text(cleanDisplayText(deck.title ?: deck.paperId), maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

@Composable
private fun SectionKicker(text: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.size(4.dp).clip(CircleShape).background(color))
        Text(text, color = color, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.8.sp)
    }
}

@Composable
private fun MetaLabel(topic: Topic) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(Modifier.size(6.dp).clip(CircleShape).background(topic.color))
        Text(topic.label.uppercase(), color = topic.color, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.3.sp)
    }
}

@Composable
private fun EmptyPanel(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(CardBg)
            .padding(16.dp),
    ) {
        Text(text, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun EmptySearchState(query: String, activeTopic: Topic?) {
    val trimmed = query.trim()
    val headline = if (activeTopic == null) {
        "No matches for \"$trimmed\""
    } else {
        "No ${activeTopic.label} hits for \"$trimmed\""
    }
    val subcopy = if (activeTopic == null) {
        "Try a topic tag, a concept like attention, or a plain question."
    } else {
        "Try another topic filter or clear the filter to see all matches."
    }
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(if (activeTopic == null) Icons.Outlined.Search else Icons.Outlined.FilterList, contentDescription = null, tint = MutedInk.copy(alpha = 0.5f))
        Text(headline, color = InkColor, fontFamily = FontFamily.Serif, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, textAlign = TextAlign.Center)
        Text(subcopy, color = MutedInk, fontSize = 13.sp, textAlign = TextAlign.Center)
    }
}

@Composable
private fun ErrorState(padding: PaddingValues, message: String, onRefresh: () -> Unit) {
    Centered(padding) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Could not load Aprecis", style = MaterialTheme.typography.titleMedium)
            Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant)
            TextButton(onClick = onRefresh) { Text("Retry") }
        }
    }
}

@Composable
private fun Centered(
    padding: PaddingValues,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(padding),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        content()
    }
}

enum class Topic(
    val label: String,
    val query: String,
    val color: Color,
    val blurb: String,
    val mark: String,
) {
    LanguageModels(
        "Large Language Models",
        "language model",
        TealAccent,
        "How machines learned to read, write, and reason in words.",
        "LLM",
    ),
    Transformers(
        "Transformers & Attention",
        "attention",
        Color(0xFF2DB8B8),
        "The architecture under every modern model.",
        "T",
    ),
    Reasoning(
        "Reasoning",
        "reasoning",
        Color(0xFF8A5A18),
        "Teaching models to think step by step.",
        "R",
    ),
    Vision(
        "Computer Vision",
        "vision",
        Color(0xFF8A4EC2),
        "Making machines see and understand images.",
        "V",
    ),
    Generative(
        "Generative Models",
        "generative",
        Color(0xFFC25A8A),
        "AI that creates: images, audio, whole worlds.",
        "G",
    ),
    Reinforcement(
        "Reinforcement Learning",
        "reinforcement",
        Color(0xFFC07014),
        "Learning from reward instead of answer keys.",
        "RL",
    ),
    Foundations(
        "Foundations",
        "foundations",
        Color(0xFF2A6D7A),
        "The building blocks: one neuron to backprop.",
        "F",
    ),
    Embeddings(
        "Embeddings",
        "embedding",
        Color(0xFF3A7CA5),
        "Turning words and things into geometry.",
        "E",
    ),
    Training(
        "Optimization & Training",
        "optimization",
        Color(0xFF5A9FD8),
        "The tricks that make deep networks actually learn.",
        "∂",
    ),
    Scaling(
        "Scaling & Efficiency",
        "scaling",
        AmberAccent,
        "Bigger, faster, cheaper: more model for less.",
        "S",
    ),
    Alignment(
        "Alignment & Human Feedback",
        "feedback",
        Color(0xFF7A4040),
        "Steering models toward what people actually want.",
        "A",
    );

    companion object {
        val all = entries

        fun forDeck(deck: CardDeckDto): Topic {
            val blob = listOfNotNull(deck.title, deck.hook, deck.summary, deck.source, deck.arxivCategory)
                .joinToString(" ")
                .lowercase()
            return when {
                listOf("vision", "image", "clip", "controlnet").any { blob.contains(it) } -> Vision
                listOf("diffusion", "generative", "gan", "vae", "dreambooth").any { blob.contains(it) } -> Generative
                listOf("feedback", "alignment", "rlhf", "dpo", "instruct").any { blob.contains(it) } -> Alignment
                listOf("reinforcement", "reward", "policy").any { blob.contains(it) } -> Reinforcement
                listOf("embedding", "word2vec", "vector").any { blob.contains(it) } -> Embeddings
                listOf("optimization", "training", "gradient", "backprop").any { blob.contains(it) } -> Training
                listOf("scaling", "efficient", "flash", "memory").any { blob.contains(it) } -> Scaling
                listOf("attention", "transformer").any { blob.contains(it) } -> Transformers
                listOf("language", "llm", "bert", "gpt", "token", "llama").any { blob.contains(it) } -> LanguageModels
                listOf("reason", "chain", "agent", "tool", "thought", "planning").any { blob.contains(it) } -> Reasoning
                else -> Foundations
            }
        }
    }
}

private fun topicCount(decks: List<CardDeckDto>, topic: Topic): Int {
    val tokens = topic.query.lowercase().split(Regex("\\s+")).filter { it.isNotBlank() }
    return decks.count { deck ->
        val blob = listOfNotNull(deck.title, deck.hook, deck.summary, deck.source, deck.arxivCategory)
            .plus(deck.concepts.map { it.title })
            .joinToString(" ")
            .lowercase()
        tokens.any { blob.contains(it) }
    }
}

private enum class OnboardingKind { Welcome, Daily, Library, Glossary }

private enum class RailKind(val label: String, val color: Color) {
    BuildsOn("Builds on", AmberAccent),
    LedTo("Led to", TealAccent),
    Adjacent("Adjacent", Color(0xFF2DB8B8));

    fun ids(related: RelatedResponseDto?): List<String> = when (this) {
        BuildsOn -> related?.buildsOn.orEmpty()
        LedTo -> related?.ledTo.orEmpty()
        Adjacent -> related?.adjacent.orEmpty()
    }
}

private data class OnboardingPage(
    val kind: OnboardingKind,
    val eyebrow: String,
    val title: String,
    val body: String,
    val footnote: String? = null,
) {
    companion object {
        val all = listOf(
            OnboardingPage(
                kind = OnboardingKind.Welcome,
                eyebrow = "WELCOME",
                title = "Papers, distilled.",
                body = "Aprecis turns dense AI research into bite-size lessons you can finish on a coffee break.",
                footnote = "One small idea at a time. No rush.",
            ),
            OnboardingPage(
                kind = OnboardingKind.Daily,
                eyebrow = "DISCOVER",
                title = "Explore the research.",
                body = "Search any topic in Discover, then open a paper as interactive learning materials.",
                footnote = "Each paper shows how its ideas connect to the next.",
            ),
            OnboardingPage(
                kind = OnboardingKind.Library,
                eyebrow = "LIBRARY",
                title = "Keep what matters.",
                body = "Tap the bookmark on any paper to save it.",
            ),
            OnboardingPage(
                kind = OnboardingKind.Glossary,
                eyebrow = "GLOSSARY",
                title = "Tap the dotted words.",
                body = "Inside any paper, key terms carry a teal dotted underline. Tap one to surface a quick definition; tap again to dismiss.",
                footnote = "Plain teal words are just emphasis. The dotted underline marks a definition.",
            ),
        )
    }
}

private fun discoverBackdrop(): Brush =
    Brush.radialGradient(
        colors = listOf(TealAccent.copy(alpha = 0.14f), PaperBg),
        radius = 980f,
    )

private fun focusBackdrop(topic: Topic): Brush =
    Brush.verticalGradient(
        colors = listOf(topic.color.copy(alpha = 0.10f), PaperBg, PaperBg),
    )

private fun cleanDisplayText(value: String): String =
    HtmlCompat.fromHtml(value, HtmlCompat.FROM_HTML_MODE_COMPACT)
        .toString()
        .replace(Regex("\\s+"), " ")
        .trim()
        .ifBlank { value.replace(Regex("<[^>]+>"), " ").replace(Regex("\\s+"), " ").trim() }

private fun CardDeckDto.bestSubtitle(): String? =
    hook?.takeIf { it.isNotBlank() }
        ?: summary?.takeIf { it.isNotBlank() }
        ?: concepts.takeIf { it.isNotEmpty() }?.take(3)?.joinToString(" · ") { it.title }

private fun shortTitle(deck: CardDeckDto): String {
    val cleaned = cleanDisplayText(deck.title ?: deck.paperId)
    val beforeColon = cleaned.substringBefore(":").trim()
    val base = beforeColon.ifBlank { cleaned }
    return if (base.length <= 26) base else base.take(23).trimEnd() + "..."
}

private fun estimatedReadMinutes(deck: CardDeckDto): Int = (deck.concepts.size + 4).coerceIn(3, 9)

private fun stableHash(value: String): Int = value.fold(0) { acc, c -> (acc * 31 + c.code) and 0x7fffffff }

private fun spineColor(id: String): Color {
    val colors = listOf(
        Color(0xFF1A8A8A),
        Color(0xFF2D6F9F),
        Color(0xFF7A5C9E),
        Color(0xFF9B5E34),
        Color(0xFF2A7A4A),
        Color(0xFF3F5D7A),
    )
    return colors[stableHash(id) % colors.size]
}

private fun Context.aprecisVersionName(): String =
    runCatching {
        val info = packageManager.getPackageInfo(packageName, 0)
        val versionName = info.versionName ?: "0.1.0"
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        "$versionName ($versionCode)"
    }.getOrDefault("0.1.0")
