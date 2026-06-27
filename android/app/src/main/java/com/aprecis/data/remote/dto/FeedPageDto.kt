package com.aprecis.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Response of `GET /serve-cards?page=<n>`. Mirrors iOS `APIService.FeedPage`. */
@Serializable
data class FeedPageDto(
    val decks: List<CardDeckDto> = emptyList(),
    @SerialName("has_more") val hasMore: Boolean = false,
)

/** Response of `GET /serve-cards/related?paperId=<id>`. Keys match the JSON. */
@Serializable
data class RelatedResponseDto(
    val buildsOn: List<String> = emptyList(),
    val ledTo: List<String> = emptyList(),
    val adjacent: List<String> = emptyList(),
    val surprise: String? = null,
)
