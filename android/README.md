# Aprecis · Android

Native Android client for Aprecis (Google Play). Shares the Supabase backend,
edge functions, and web-lesson bundles with the iOS app. The native shell is
rebuilt in Kotlin + Jetpack Compose; lesson content renders from the same web
bundles via a re-implemented `Aprecis` JS bridge (added in a later phase).

## Status: Phase 1 (scaffold + networking)

This phase stands up the project and the networking layer end to end. The app
launches into a debug screen that fetches and lists a real `/serve-cards` page,
proving the Hilt → Retrofit → Supabase → kotlinx.serialization stack works.

Implemented:
- Gradle project (AGP 8.7, Kotlin 2.0, Compose, Hilt, Retrofit, kotlinx.serialization).
- `config/Config.kt` — same Supabase URL + anon key as iOS.
- `data/remote` — `AprecisApi` (serve-cards / related / interaction / add-paper),
  `AuthApi` (GoTrue signup / token / refresh), DTOs, and the Hilt `NetworkModule`
  that attaches the Supabase apikey + bearer headers.
- `ui/feed/FeedDebugScreen` — Phase 1 smoke screen.

Not yet built (later phases): WebView lesson host + bridge, Discover/Search,
Explore graph/Focus, Profile/auth/onboarding, paywall, billing.

## Build & run

Requires Android Studio (Ladybug or newer) — it bundles a JDK and the Android SDK.
There is no system JDK/SDK assumed on the build host.

1. Open the `android/` folder in Android Studio and let it sync.
2. Create a `local.properties` with your SDK path if Studio does not (it usually does):
   ```
   sdk.dir=/Users/<you>/Library/Android/sdk
   ```
3. Run the `app` configuration on an emulator or device (min SDK 26 / Android 8).

### CLI (optional)
With a JDK 17+ on PATH and the Android SDK installed:
```bash
cd android
./gradlew :app:assembleDebug
```

## Conventions
- Package root: `com.aprecis`.
- Architecture: MVVM (`ViewModel` + `StateFlow`), repositories over Retrofit.
- Theme pinned to light, teal accent, to match the iOS app.
- Card-content style rule travels from the iOS app: no em dashes (literal `—`
  or escaped) in any user-facing string.
