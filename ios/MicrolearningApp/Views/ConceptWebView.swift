import SwiftUI
import WebKit

// MARK: - ConceptWebView
//
// Renders a concept's interactive visualization in a WKWebView.
// Priority: vizHtml (GPT-4o generated HTML) → ConceptViz.html template + VisualSchema JSON.
// The webview reports its rendered height back via JS → Swift message handler.

struct ConceptWebView: UIViewRepresentable {
    let concept: Concept
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(
            WeakScriptMessageProxy(coordinator: context.coordinator),
            name: "resize"
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        context.coordinator.load(concept: concept, into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the concept changed
        guard concept.title != context.coordinator.loadedTitle else { return }
        context.coordinator.load(concept: concept, into: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "resize")
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ConceptWebView
        var loadedTitle: String = ""
        /// Schema to inject after template finishes loading (legacy fallback path)
        var pendingSchema: VisualSchema?

        init(_ parent: ConceptWebView) { self.parent = parent }

        func load(concept: Concept, into webView: WKWebView) {
            loadedTitle = concept.title

            if let html = concept.vizHtml, !html.isEmpty {
                // ── Path A: rich Claude HTML, use bundle base URL so JS bridge works ──
                webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
            } else if let schema = concept.diagram,
                      let url = Bundle.main.url(forResource: "ConceptViz", withExtension: "html") {
                // ── Path B: legacy schema, inject into template ───────────────
                pendingSchema = schema
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                // ── Path C: nothing to show, tiny placeholder ────────────────
                webView.loadHTMLString(
                    "<html><body style='background:transparent'></body></html>",
                    baseURL: Bundle.main.bundleURL
                )
            }
        }

        // Called after template (Path B) finishes loading
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let schema = pendingSchema,
                  let json = try? JSONEncoder().encode(schema),
                  let jsonStr = String(data: json, encoding: .utf8) else { return }
            webView.evaluateJavaScript("renderConcept(\(jsonStr))", completionHandler: nil)
            pendingSchema = nil
        }

        func handleResize(_ value: Any) {
            let h: CGFloat
            if let d = value as? Double { h = CGFloat(d) }
            else if let i = value as? Int { h = CGFloat(i) }
            else { return }
            DispatchQueue.main.async { self.parent.height = max(h, 60) }
        }
    }
}

// MARK: - WeakScriptMessageProxy
// Breaks the WKUserContentController strong-reference cycle.

private final class WeakScriptMessageProxy: NSObject, WKScriptMessageHandler {
    weak var coordinator: ConceptWebView.Coordinator?
    init(coordinator: ConceptWebView.Coordinator) { self.coordinator = coordinator }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        coordinator?.handleResize(message.body)
    }
}
