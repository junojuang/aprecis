import Foundation

enum Config {
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_ANON_KEY"
    static let apiBase = "\(supabaseURL)/functions/v1"
}
