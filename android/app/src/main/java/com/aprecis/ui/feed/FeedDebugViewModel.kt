package com.aprecis.ui.feed

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aprecis.data.remote.dto.CardDeckDto
import com.aprecis.data.repository.FeedRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed interface FeedUiState {
    data object Loading : FeedUiState
    data class Loaded(val decks: List<CardDeckDto>, val hasMore: Boolean) : FeedUiState
    data class Error(val message: String) : FeedUiState
}

@HiltViewModel
class FeedDebugViewModel @Inject constructor(
    private val repository: FeedRepository,
) : ViewModel() {

    private val _state = MutableStateFlow<FeedUiState>(FeedUiState.Loading)
    val state: StateFlow<FeedUiState> = _state.asStateFlow()

    init { load() }

    fun load() {
        _state.update { FeedUiState.Loading }
        viewModelScope.launch {
            repository.loadFeed(page = 0)
                .onSuccess { page ->
                    _state.update { FeedUiState.Loaded(page.decks, page.hasMore) }
                }
                .onFailure { e ->
                    _state.update { FeedUiState.Error(e.message ?: "Unknown error") }
                }
        }
    }
}
