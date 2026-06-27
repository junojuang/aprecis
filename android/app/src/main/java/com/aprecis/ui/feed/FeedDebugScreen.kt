package com.aprecis.ui.feed

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.aprecis.data.remote.dto.CardDeckDto

/**
 * Phase 1 smoke screen. Confirms the whole networking stack (Hilt -> Retrofit ->
 * Supabase edge function -> kotlinx.serialization) works end to end by listing a
 * real `/serve-cards` page. This is replaced by the Discover feed in a later phase.
 */
@Composable
fun FeedDebugScreen(viewModel: FeedDebugViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Scaffold { padding ->
        when (val s = state) {
            is FeedUiState.Loading -> Centered(padding) { CircularProgressIndicator() }

            is FeedUiState.Error -> Centered(padding) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("Couldn't load the feed", style = MaterialTheme.typography.titleMedium)
                    Text(s.message, style = MaterialTheme.typography.bodySmall)
                    Button(onClick = viewModel::load, modifier = Modifier.padding(top = 12.dp)) {
                        Text("Retry")
                    }
                }
            }

            is FeedUiState.Loaded -> LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                item {
                    Text(
                        "serve-cards page 0 · ${s.decks.size} decks · hasMore=${s.hasMore}",
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier.padding(vertical = 12.dp),
                    )
                }
                items(s.decks, key = { it.paperId }) { deck ->
                    DeckRow(deck)
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
private fun DeckRow(deck: CardDeckDto) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp)) {
        Text(
            deck.title ?: deck.paperId,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
        )
        deck.hook?.let {
            Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        val tags = buildList {
            deck.source?.let { add(it) }
            add("${deck.concepts.size} concepts")
            if (deck.webLessonUrl != null) add("web lesson")
        }
        Text(
            tags.joinToString(" · "),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun Centered(
    padding: androidx.compose.foundation.layout.PaddingValues,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(padding),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) { content() }
}
