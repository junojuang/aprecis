package com.aprecis

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.aprecis.ui.feed.FeedDebugScreen
import com.aprecis.ui.theme.AprecisTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            AprecisTheme {
                // Phase 1: a debug screen that exercises the networking layer by
                // fetching and displaying a real /serve-cards page. Replaced by
                // the Discover/Profile NavHost in a later phase.
                FeedDebugScreen()
            }
        }
    }
}
