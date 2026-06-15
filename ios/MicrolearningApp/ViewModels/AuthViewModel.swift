import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - AuthState

enum AuthState {
    case loggedOut
    case loggedIn(AuthSession)
    case confirmationRequired(email: String)
}

// MARK: - AuthViewModel

@MainActor
final class AuthViewModel: NSObject, ObservableObject {

    @Published var state: AuthState = .loggedOut {
        didSet { syncSavedStore() }
    }

    private func syncSavedStore() {
        if case .loggedIn(let s) = state {
            SavedPapersStore.shared.setUserId(s.user.id)
            ReadingProgressStore.shared.setAuth(accessToken: s.accessToken, userId: s.user.id)
        } else {
            SavedPapersStore.shared.setUserId(nil)
            ReadingProgressStore.shared.setAuth(accessToken: nil, userId: nil)
        }
    }
    @Published var isLoading = false
    @Published var error: String?
    @Published var needsProfileSetup: Bool = false

    var isLoggedIn: Bool {
        if case .loggedIn = state { return true }
        return false
    }

    var currentSession: AuthSession? {
        if case .loggedIn(let s) = state { return s }
        return nil
    }

    // Persisted tokens
    @AppStorage("auth_access_token")  private var storedAccessToken  = ""
    @AppStorage("auth_refresh_token") private var storedRefreshToken = ""

    // Apple Sign-In nonce (kept in memory during the auth flow)
    private var currentNonce: String = ""

    // MARK: - Init

    override init() {
        super.init()
        Task { await restoreSession() }
    }

    // MARK: - Session restore

    private func restoreSession() async {
        guard !storedRefreshToken.isEmpty else { return }
        do {
            let session = try await AuthService.shared.refresh(token: storedRefreshToken)
            persist(session: session)
            state = .loggedIn(session)
            await checkProfileSetup(session: session)
        } catch {
            storedAccessToken  = ""
            storedRefreshToken = ""
        }
    }

    private func checkProfileSetup(session: AuthSession) async {
        do {
            let profile = try await ProfileService.shared.fetchProfile(
                userId: session.user.id,
                accessToken: session.accessToken
            )
            let name = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            needsProfileSetup = name.isEmpty
        } catch {
            // Profile row missing or fetch failed. Surface the setup sheet so
            // the user can still fill it in; submit will upsert.
            needsProfileSetup = true
        }
    }

    func markProfileSetupComplete() {
        needsProfileSetup = false
    }

    // MARK: - Email Sign Up

    func signUp(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            let session = try await AuthService.shared.signUp(email: email, password: password)
            persist(session: session)
            state = .loggedIn(session)
            await checkProfileSetup(session: session)
        } catch AuthError.confirmationRequired {
            state = .confirmationRequired(email: email)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Email Sign In

    func signIn(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            let session = try await AuthService.shared.signIn(email: email, password: password)
            persist(session: session)
            state = .loggedIn(session)
            await checkProfileSetup(session: session)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - TEST, mock login bypass
    func mockSignIn() {
        let user = AuthUser(id: "test-user-001",
                            email: "test@aprecis.app",
                            createdAt: ISO8601DateFormatter().string(from: Date()))
        let session = AuthSession(accessToken: "mock-access",
                                  refreshToken: "mock-refresh",
                                  user: user)
        error = nil
        state = .loggedIn(session)
    }

    // MARK: - Sign In with Apple

    func startAppleSignIn() {
        currentNonce = generateNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256Nonce(currentNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Sign Out

    func signOut() async {
        if let token = currentSession?.accessToken {
            await AuthService.shared.signOut(accessToken: token)
        }
        storedAccessToken  = ""
        storedRefreshToken = ""
        state = .loggedOut
    }

    // MARK: - Delete Account

    /// Permanently deletes the user's account on the server, then clears the
    /// session and all on-device data. Returns true on success; on failure the
    /// session is left intact and `error` carries a message.
    @discardableResult
    func deleteAccount() async -> Bool {
        guard let session = currentSession else { return false }
        isLoading = true; error = nil
        do {
            try await AuthService.shared.deleteAccount(accessToken: session.accessToken)
            // Account is gone server-side. Wipe local traces too.
            SavedPapersStore.shared.reset()
            ReadingProgressStore.shared.reset()
            RecentlyViewedStore.shared.reset()
            storedAccessToken  = ""
            storedRefreshToken = ""
            state = .loggedOut
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Helpers

    private func persist(session: AuthSession) {
        storedAccessToken  = session.accessToken
        storedRefreshToken = session.refreshToken
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthViewModel: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData   = credential.identityToken,
              let idToken     = String(data: tokenData, encoding: .utf8) else {
            error = "We couldn't read your Apple sign in. Try once more."
            return
        }
        let nonce = currentNonce
        // Apple hands the stable user id every time, but the full name ONLY on
        // the first authorization. Capture both now — after this they are gone.
        let appleUserId = credential.user
        let appleName = appleDisplayName(from: credential.fullName)
        Task {
            isLoading = true; error = nil
            do {
                let session = try await AuthService.shared.signInWithApple(idToken: idToken, nonce: nonce)
                persist(session: session)
                state = .loggedIn(session)
                // Persist the Apple identity + name before checking setup, so a
                // first-time Apple sign-in skips the manual name sheet.
                await recordAppleIdentity(session: session,
                                          appleUserId: appleUserId,
                                          appleName: appleName)
                await checkProfileSetup(session: session)
            } catch {
                self.error = friendlyMessage(for: error)
            }
            isLoading = false
        }
    }

    /// Formats Apple's `PersonNameComponents` into a display name, or nil when
    /// Apple sent none (every sign-in after the first).
    private func appleDisplayName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        let name = formatter.string(from: components)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    /// Writes the Apple user id (and first-run name) to the user's profile row.
    /// Non-fatal: a failure just falls back to the manual profile-setup sheet.
    private func recordAppleIdentity(session: AuthSession,
                                     appleUserId: String,
                                     appleName: String?) async {
        do {
            try await ProfileService.shared.applyAppleIdentity(
                userId: session.user.id,
                accessToken: session.accessToken,
                displayName: appleName,
                appleUserId: appleUserId
            )
        } catch {
            // Profile row may not exist yet, or the network blipped. The
            // profile-setup sheet still covers the name; no user-facing error.
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        // User cancelled the sheet themselves. Don't show anything.
        let code = (error as? ASAuthorizationError)?.code
        if code == .canceled { return }
        self.error = friendlyMessage(for: error)
    }
}

// MARK: - Friendly error mapping

extension AuthViewModel {

    func clearError() { error = nil }

    func retryAppleSignIn() {
        error = nil
        startAppleSignIn()
    }

    fileprivate func friendlyMessage(for error: Error) -> String {
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                return ""
            case .failed:
                return "Apple couldn't finish signing you in. Give it another try."
            case .invalidResponse:
                return "Apple sent something we didn't expect. Try again in a moment."
            case .notHandled:
                return "Sign in isn't available right now. Try again shortly."
            case .notInteractive:
                return "We need you to tap through the Apple prompt. Try again."
            case .unknown:
                return "Sign in didn't complete. Make sure you're signed into iCloud on this device, then try again."
            default:
                return "Something went sideways. Try again."
            }
        }

        let raw = error.localizedDescription.lowercased()

        if raw.contains("unacceptable audience") || raw.contains("invalid_grant") || raw.contains("invalid id_token") {
            return "We hit a small wiring issue on our side. Email us if it keeps happening."
        }
        if raw.contains("network") || raw.contains("offline") || raw.contains("internet") || raw.contains("connection") {
            return "Looks like you're offline. Check your connection and try again."
        }
        if raw.contains("timed out") || raw.contains("timeout") {
            return "That took too long. Try again."
        }
        return "Sign in didn't complete. Try again."
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
