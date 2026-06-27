package com.aprecis.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Wire model for a card deck returned by `/serve-cards`. Field names mirror the
 * iOS `CardDeck` CodingKeys (snake_case). Unknown fields (e.g. `blueprint`,
 * `diagramSpec`) are tolerated by the Json config and can be modeled later.
 */
@Serializable
data class CardDeckDto(
    @SerialName("paper_id") val paperId: String,
    val title: String? = null,
    val url: String? = null,
    val source: String? = null,
    val hook: String? = null,
    val summary: String? = null,
    val concepts: List<ConceptDto> = emptyList(),
    val score: Double? = null,
    @SerialName("published_at") val publishedAt: String? = null,
    @SerialName("arxiv_category") val arxivCategory: String? = null,
    @SerialName("web_lesson_url") val webLessonUrl: String? = null,
)

/**
 * Wire model for a concept. The iOS `Concept` uses default (camelCase) coding
 * keys, so these match the JSON exactly. Diagram specs are intentionally not
 * modeled yet (Phase 1 fetch/log only); they are skipped via ignoreUnknownKeys.
 */
@Serializable
data class ConceptDto(
    val title: String,
    val body: String,
    val vizHtml: String? = null,
    val conceptImageUrl: String? = null,
)
