package com.aprecis.data.remote

import com.aprecis.data.remote.dto.CardDeckDto
import com.aprecis.data.remote.dto.FeedPageDto
import com.aprecis.data.remote.dto.RelatedResponseDto
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

/**
 * Edge-function endpoints under `${Config.API_BASE}`. Mirrors the iOS
 * `APIService`. The Supabase apikey + bearer headers are attached by an OkHttp
 * interceptor (see NetworkModule), so they are not declared per-method here.
 */
interface AprecisApi {

    /** GET /serve-cards?page=<page> */
    @GET("serve-cards")
    suspend fun fetchFeed(@Query("page") page: Int): FeedPageDto

    /** GET /serve-cards?paper_id=<id> */
    @GET("serve-cards")
    suspend fun fetchDeck(@Query("paper_id") paperId: String): CardDeckDto

    /** GET /serve-cards/web-lessons -> { paper_id: web_lesson_url } */
    @GET("serve-cards/web-lessons")
    suspend fun fetchWebLessons(): Map<String, String>

    /** GET /serve-cards/related?paperId=<id> */
    @GET("serve-cards/related")
    suspend fun fetchRelated(@Query("paperId") paperId: String): RelatedResponseDto

    /** POST /serve-cards/interaction */
    @POST("serve-cards/interaction")
    suspend fun markInteraction(@Body body: InteractionBody)

    /** POST /add-paper */
    @POST("add-paper")
    suspend fun addPaper(@Body body: AddPaperBody): CardDeckDto
}

@kotlinx.serialization.Serializable
data class InteractionBody(
    @kotlinx.serialization.SerialName("paper_id") val paperId: String,
    val action: String,
)

@kotlinx.serialization.Serializable
data class AddPaperBody(
    @kotlinx.serialization.SerialName("arxiv_id") val arxivId: String,
)
