package com.aprecis.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val AprecisLightColors = lightColorScheme(
    primary = TealAccent,
    onPrimary = PaperBg,
    background = PaperBg,
    onBackground = InkColor,
    surface = PaperBg,
    onSurface = InkColor,
    onSurfaceVariant = MutedInk,
)

/**
 * The iOS app pins itself to light mode (`preferredColorScheme(.light)`), so we
 * match that for visual parity until a dark theme is designed for both platforms.
 */
@Composable
fun AprecisTheme(
    @Suppress("UNUSED_PARAMETER") darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = AprecisLightColors,
        typography = AprecisTypography,
        content = content,
    )
}
