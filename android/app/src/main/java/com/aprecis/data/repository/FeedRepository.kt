package com.aprecis.data.repository

import com.aprecis.data.remote.AprecisApi
import com.aprecis.data.remote.dto.FeedPageDto
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin wrapper over the feed endpoints. Kept deliberately small for Phase 1;
 * caching, dedupe (the iOS `mergingCanonicalBraceDuplicates`), and the
 * web-lesson registry land in later phases.
 */
@Singleton
class FeedRepository @Inject constructor(
    private val api: AprecisApi,
) {
    suspend fun loadFeed(page: Int): Result<FeedPageDto> = runCatching {
        api.fetchFeed(page)
    }
}
