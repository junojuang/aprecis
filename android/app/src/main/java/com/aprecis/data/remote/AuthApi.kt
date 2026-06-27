package com.aprecis.data.remote

import com.aprecis.data.remote.dto.AuthSessionDto
import com.aprecis.data.remote.dto.EmailPasswordBody
import com.aprecis.data.remote.dto.RefreshTokenBody
import retrofit2.http.Body
import retrofit2.http.POST

/**
 * Supabase GoTrue endpoints under `${Config.AUTH_BASE}`. Mirrors the iOS
 * `AuthService`. The apikey header is attached by the network interceptor.
 *
 * Sign in with Apple is replaced on Android by Google Sign-In, which will post
 * to `token?grant_type=id_token` with `provider=google` (added in a later phase).
 */
interface AuthApi {

    @POST("signup")
    suspend fun signUp(@Body body: EmailPasswordBody): AuthSessionDto

    @POST("token?grant_type=password")
    suspend fun signIn(@Body body: EmailPasswordBody): AuthSessionDto

    @POST("token?grant_type=refresh_token")
    suspend fun refresh(@Body body: RefreshTokenBody): AuthSessionDto
}
