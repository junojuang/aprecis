package com.aprecis.config

/**
 * Backend configuration. Mirrors the iOS `Config` enum so both apps talk to the
 * same Supabase project and edge functions.
 *
 * For v1 these match the values already shipped in the iOS binary (the anon key
 * is a public, RLS-gated key by design). When secrets are moved to build config,
 * inject them here via BuildConfig instead of hardcoding.
 */
object Config {
    const val SUPABASE_URL = "https://kurqbmbayqecfbbcjojj.supabase.co"
    const val SUPABASE_ANON_KEY =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1cnFibWJheXFlY2ZiYmNqb2pqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3OTQ5MDAsImV4cCI6MjA4OTM3MDkwMH0.gmwpVByjPKSe6vRCGKgWtVFUfgsfG6NR4bxQzW-V7b4"

    /** Edge functions base, e.g. `${SUPABASE_URL}/functions/v1`. */
    const val API_BASE = "$SUPABASE_URL/functions/v1"

    /** GoTrue auth base, e.g. `${SUPABASE_URL}/auth/v1`. */
    const val AUTH_BASE = "$SUPABASE_URL/auth/v1"
}
