import SwiftUI
import WebKit

// MARK: - Web lesson channel
//
// Renders a paper's lesson from a self-contained web bundle (HTML/CSS/JS) in a
// full-screen WKWebView, instead of a native SwiftUI reader. This is the
// no-app-update authoring path: write a bespoke lesson locally, upload the
// bundle to Storage, point `cards.web_lesson_url` at it, and it renders here.
//
// The bundle talks to the app through the `Aprecis` JS bridge (see
// prototypes/web-lesson/kit/aprecis-sdk.js). Supported messages:
//   haptic({style})  · markDone · finish · close · openOriginal({url})
//
// Both remote URLs and bundled file URLs are supported. Remote bundles load
// with a cache-first policy so a lesson opened once keeps working offline.

// MARK: Registry

/// Resolves which web bundle (if any) should render a given paper.
///
/// Priority: a bundled local override (for offline testing) → the server-driven
/// catalog map loaded from `/serve-cards/web-lessons` (curated loops, no app
/// update) → an ingested deck's own `web_lesson_url`. When nothing resolves, the
/// caller falls back to the native reader, so papers degrade gracefully offline.
enum WebLessonRegistry {
    /// Local paperId → bundled-resource overrides. Empty by default; add an
    /// entry only to bake a flagship lesson in for offline use. The normal path
    /// is the server map below, which needs no app update.
    static let localOverrides: [String: URL] = [:]

    /// paperId → bundle URL, loaded once from the server catalog at launch.
    /// Read on the main thread (from SwiftUI view bodies); set after the fetch.
    static var serverOverrides: [String: String] = [:]

    /// Loads the server-driven web-lesson map. Failures are silent: papers just
    /// fall back to their native reader until the next successful load.
    static func refreshFromServer() async {
        if let map = try? await APIService.shared.fetchWebLessons() {
            serverOverrides = map
        }
    }

    static func url(forPaperId id: String) -> URL? {
        let preferred = RelatedPapers.preferredId(for: id)
        if let local = localOverrides[id] ?? localOverrides[preferred] { return local }
        if let s = serverOverrides[id] ?? serverOverrides[preferred], let u = URL(string: s) {
            return u
        }
        return nil
    }

    /// Full resolution for a deck: overrides/catalog first, then the deck's own field.
    static func url(for deck: CardDeck) -> URL? {
        if let resolved = url(forPaperId: deck.paperId) { return resolved }
        if let s = deck.webLessonURL, let u = URL(string: s) { return u }
        return nil
    }
}

// MARK: View

struct WebLessonView: View {
    let url: URL
    var paperId: String? = nil
    var onClose: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var browser: BrowserLink?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Lesson-toned backdrop so the gap before the bundle paints reads as
            // the app loading, not a blank white web view.
            paperBg.ignoresSafeArea()

            WebLessonRepresentable(
                url: url,
                paperId: paperId,
                onClose: onClose,
                onOpenOriginal: { browser = BrowserLink(url: $0) },
                onLoadingChange: { loading in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                        isLoading = loading
                    }
                }
            )
            .ignoresSafeArea()
            // Hold the web view hidden until it has actually painted, so a
            // half-rendered first frame never flashes through.
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(inkColor)
                    .transition(.opacity)
                    .accessibilityLabel("Loading lesson")
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $browser) { link in
            SafariView(url: link.url).ignoresSafeArea()
        }
    }
}

// MARK: Representable

private struct WebLessonRepresentable: UIViewRepresentable {
    let url: URL
    let paperId: String?
    let onClose: () -> Void
    let onOpenOriginal: (URL) -> Void
    let onLoadingChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let ucc = config.userContentController
        for name in ["haptic", "markDone", "finish", "close", "openOriginal"] {
            ucc.add(WeakLessonMessageProxy(coordinator: context.coordinator), name: name)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false

        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // Object storage (e.g. Supabase) serves uploaded HTML as text/plain
            // with nosniff to prevent XSS on its domain, so a plain load(URLRequest)
            // would render the bundle as raw text. Fetch the bytes ourselves and
            // load them with a forced text/html type. URLCache gives offline reuse.
            context.coordinator.loadRemote(url, into: webView)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        let ucc = webView.configuration.userContentController
        for name in ["haptic", "markDone", "finish", "close", "openOriginal"] {
            ucc.removeScriptMessageHandler(forName: name)
        }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebLessonRepresentable
        private var didComplete = false
        init(_ parent: WebLessonRepresentable) { self.parent = parent }

        // Reveal the bundle only once it has painted; never hang the spinner.
        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            MainActor.assumeIsolated { parent.onLoadingChange(false) }
        }
        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!,
                                 withError error: Error) {
            MainActor.assumeIsolated { parent.onLoadingChange(false) }
        }
        nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                                 withError error: Error) {
            MainActor.assumeIsolated { parent.onLoadingChange(false) }
        }

        /// Fetches the bundle and loads it with a forced text/html MIME type so
        /// it renders as HTML even when the host serves it as text/plain.
        func loadRemote(_ url: URL, into webView: WKWebView) {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 30)
            Task { @MainActor [weak webView] in
                guard let (data, _) = try? await URLSession.shared.data(for: request) else {
                    // Couldn't even fetch the bytes (offline, etc.): stop the
                    // spinner so the user isn't stranded on a loading screen.
                    parent.onLoadingChange(false)
                    return
                }
                webView?.load(data, mimeType: "text/html",
                              characterEncodingName: "utf-8", baseURL: url)
            }
        }

        func handle(_ name: String, _ body: Any) {
            switch name {
            case "haptic":
                fireHaptic(style: (body as? [String: Any])?["style"] as? String ?? "soft")
            case "markDone":
                markComplete()
            case "finish":
                markComplete()
                parent.onClose()
            case "close":
                parent.onClose()
            case "openOriginal":
                if let s = (body as? [String: Any])?["url"] as? String, let u = URL(string: s) {
                    parent.onOpenOriginal(u)
                }
            default:
                break
            }
        }

        private func markComplete() {
            guard !didComplete, let id = parent.paperId else { return }
            didComplete = true
            let store = ReadingProgressStore.shared
            store.markCompletedToday(paperId: id)
            store.markComplete(paperId: id)
        }

        private func fireHaptic(style: String) {
            switch style {
            case "select":
                UISelectionFeedbackGenerator().selectionChanged()
            case "success":
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case "warning":
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case "error":
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case "light":
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case "medium":
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case "heavy":
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case "rigid":
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            default:
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }
}

// Breaks the WKUserContentController → coordinator strong-reference cycle.
private final class WeakLessonMessageProxy: NSObject, WKScriptMessageHandler {
    weak var coordinator: WebLessonRepresentable.Coordinator?
    init(coordinator: WebLessonRepresentable.Coordinator) { self.coordinator = coordinator }

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        // WebKit delivers script messages on the main thread, so it is safe to
        // assume MainActor isolation here for the @MainActor coordinator.
        let name = message.name, body = message.body
        MainActor.assumeIsolated { coordinator?.handle(name, body) }
    }
}
