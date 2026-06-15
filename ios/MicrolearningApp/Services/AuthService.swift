import Foundation
import CryptoKit

// MARK: - Auth Models

struct AuthUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyRegistered
    case confirmationRequired
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:       return "Incorrect email or password."
        case .emailAlreadyRegistered:   return "An account with this email already exists."
        case .confirmationRequired:     return "Please check your email and click the confirmation link."
        case .serverError(let msg):     return msg
        }
    }
}

// MARK: - AuthService

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let base = "\(Config.supabaseURL)/auth/v1"

    // MARK: Sign Up

    /// Returns a session if email confirmation is disabled, or throws .confirmationRequired if a link was sent.
    func signUp(email: String, password: String) async throws -> AuthSession {
        let resp = try await post(path: "/signup",
                                  body: ["email": email, "password": password])
        if let token = resp["access_token"] as? String,
           let refresh = resp["refresh_token"] as? String,
           let userDict = resp["user"] as? [String: Any],
           let id = userDict["id"] as? String {
            let user = AuthUser(id: id,
                                email: userDict["email"] as? String,
                                createdAt: userDict["created_at"] as? String)
            return AuthSession(accessToken: token, refreshToken: refresh, user: user)
        }
        // Supabase returns user object without tokens when confirmation is required
        throw AuthError.confirmationRequired
    }

    // MARK: Sign In (email + password)

    func signIn(email: String, password: String) async throws -> AuthSession {
        try decode(try await post(path: "/token?grant_type=password",
                                  body: ["email": email, "password": password]))
    }

    // MARK: Sign In with Apple

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        try decode(try await post(path: "/token?grant_type=id_token",
                                  body: ["provider": "apple",
                                         "id_token": idToken,
                                         "nonce": nonce]))
    }

    // MARK: Sign Out

    func signOut(accessToken: String) async {
        var req = URLRequest(url: URL(string: "\(base)/logout")!)
        req.httpMethod = "POST"
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
    }

    // MARK: Delete Account

    /// Permanently deletes the signed-in user's account via the `delete-account`
    /// edge function. The server identifies the user from the access token, so a
    /// caller can only ever delete themselves. Deleting the auth user cascades to
    /// the profile row. Required for App Store Guideline 5.1.1(v).
    func deleteAccount(accessToken: String) async throws {
        var req = URLRequest(url: URL(string: "\(Config.apiBase)/delete-account")!)
        req.httpMethod = "POST"
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey,  forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.serverError("No response")
        }
        if http.statusCode >= 400 {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let msg = json?["error"] as? String ?? "Couldn't delete your account."
            throw AuthError.serverError(msg)
        }
    }

    // MARK: Refresh

    func refresh(token: String) async throws -> AuthSession {
        try decode(try await post(path: "/token?grant_type=refresh_token",
                                  body: ["refresh_token": token]))
    }

    // MARK: - Helpers

    private func post(path: String, body: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: "\(base)\(path)")!)
        req.httpMethod = "POST"
        req.setValue("application/json",     forHTTPHeaderField: "Content-Type")
        req.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.serverError("No response")
        }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        if http.statusCode >= 400 {
            let msg = json["error_description"] as? String
                   ?? json["msg"] as? String
                   ?? json["message"] as? String
                   ?? "Error \(http.statusCode)"
            let lower = msg.lowercased()
            if lower.contains("already registered") || lower.contains("already exists") {
                throw AuthError.emailAlreadyRegistered
            }
            if lower.contains("invalid") || lower.contains("credentials") || lower.contains("password") {
                throw AuthError.invalidCredentials
            }
            throw AuthError.serverError(msg)
        }
        return json
    }

    private func decode(_ json: [String: Any]) throws -> AuthSession {
        guard let token   = json["access_token"]  as? String,
              let refresh = json["refresh_token"] as? String,
              let userDict = json["user"] as? [String: Any],
              let id      = userDict["id"] as? String else {
            throw AuthError.serverError("Unexpected response format")
        }
        let user = AuthUser(id: id,
                            email: userDict["email"] as? String,
                            createdAt: userDict["created_at"] as? String)
        return AuthSession(accessToken: token, refreshToken: refresh, user: user)
    }
}

// MARK: - Nonce helpers (for Sign in with Apple)

func generateNonce(length: Int = 32) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    let chars: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(bytes.map { chars[Int($0) % chars.count] })
}

func sha256Nonce(_ input: String) -> String {
    SHA256.hash(data: Data(input.utf8))
        .map { String(format: "%02x", $0) }
        .joined()
}
