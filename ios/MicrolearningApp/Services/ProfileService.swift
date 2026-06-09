import Foundation

struct UserProfile: Codable {
    let id: String
    var displayName: String?
    var papersRead: Int
    var appleUserId: String?
    var email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case papersRead  = "papers_read"
        case appleUserId = "apple_user_id"
        case email
    }
}

enum ProfileError: LocalizedError {
    case notFound
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:               return "Profile not found."
        case .serverError(let msg):   return msg
        }
    }
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private let base = "\(Config.supabaseURL)/rest/v1"

    func fetchProfile(userId: String, accessToken: String) async throws -> UserProfile {
        var comps = URLComponents(string: "\(base)/profiles")!
        comps.queryItems = [
            URLQueryItem(name: "id",     value: "eq.\(userId)"),
            URLQueryItem(name: "select", value: "id,display_name,papers_read,apple_user_id,email")
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw ProfileError.serverError("Failed to fetch profile.")
        }
        let rows = try JSONDecoder().decode([UserProfile].self, from: data)
        guard let first = rows.first else { throw ProfileError.notFound }
        return first
    }

    func updateProfile(userId: String,
                       accessToken: String,
                       displayName: String?) async throws -> UserProfile {
        var comps = URLComponents(string: "\(base)/profiles")!
        comps.queryItems = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")

        var body: [String: Any] = [:]
        if let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            body["display_name"] = name
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Update failed."
            throw ProfileError.serverError(msg)
        }
        let rows = try JSONDecoder().decode([UserProfile].self, from: data)
        guard let first = rows.first else { throw ProfileError.notFound }
        return first
    }

    /// Records the Apple Sign-In identity on the profile: the stable Apple user
    /// id, and the full name Apple provides (only on the first authorization).
    /// `displayName` is written only when non-nil, so a later sign-in (where
    /// Apple sends no name) never clobbers a name the user already has.
    /// Leaves `daily_goal` untouched.
    func applyAppleIdentity(userId: String,
                            accessToken: String,
                            displayName: String?,
                            appleUserId: String) async throws {
        var comps = URLComponents(string: "\(base)/profiles")!
        comps.queryItems = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "PATCH"
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal",        forHTTPHeaderField: "Prefer")

        var body: [String: Any] = ["apple_user_id": appleUserId]
        if let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            body["display_name"] = name
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Apple identity update failed."
            throw ProfileError.serverError(msg)
        }
    }

    /// Increments the signed-in user's lifetime papers-read counter via the
    /// `increment_papers_read` RPC and returns the new running total. The RPC
    /// does the +1 atomically server-side, scoped to auth.uid().
    @discardableResult
    func incrementPapersRead(accessToken: String) async throws -> Int {
        let url = URL(string: "\(base)/rpc/increment_papers_read")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Increment failed."
            throw ProfileError.serverError(msg)
        }
        return (try? JSONDecoder().decode(Int.self, from: data)) ?? 0
    }
}
