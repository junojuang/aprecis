package com.aprecis.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AuthUserDto(
    val id: String,
    val email: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
)

/** GoTrue session payload (signup / token / refresh). Mirrors iOS `AuthSession`. */
@Serializable
data class AuthSessionDto(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String,
    val user: AuthUserDto,
)

@Serializable
data class EmailPasswordBody(
    val email: String,
    val password: String,
)

@Serializable
data class RefreshTokenBody(
    @SerialName("refresh_token") val refreshToken: String,
)
