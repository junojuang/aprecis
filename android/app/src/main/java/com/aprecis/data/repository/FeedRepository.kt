package com.aprecis.data.repository

import com.aprecis.data.remote.AprecisApi
import com.aprecis.data.remote.InteractionBody
import com.aprecis.data.remote.dto.CardDeckDto
import com.aprecis.data.remote.dto.FeedPageDto
import com.aprecis.data.remote.dto.RelatedResponseDto
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for the Android shell. The lesson content itself stays portable:
 * native Compose discovers papers and routes, hosted web bundles teach them.
 */
@Singleton
class FeedRepository @Inject constructor(
    private val api: AprecisApi,
) {
    suspend fun loadFeed(page: Int, limit: Int = 80): Result<FeedPageDto> = runCatching {
        api.fetchFeed(page = page, limit = limit)
    }

    suspend fun loadDeck(paperId: String): Result<CardDeckDto> = runCatching {
        api.fetchDeck(paperId)
    }

    suspend fun loadWebLessons(): Result<Map<String, String>> = runCatching {
        api.fetchWebLessons()
    }

    suspend fun loadRelated(paperId: String): Result<RelatedResponseDto> = runCatching {
        api.fetchRelated(paperId)
    }

    suspend fun markInteraction(paperId: String, action: String): Result<Unit> = runCatching {
        api.markInteraction(InteractionBody(paperId = paperId, action = action))
    }
}
