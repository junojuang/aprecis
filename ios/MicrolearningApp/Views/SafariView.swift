import SwiftUI
import SafariServices

// MARK: - In-app browser
//
// Wraps SFSafariViewController so external links (e.g. the "Read the original"
// arXiv link at the end of a paper) open inside Aprecis as a browser sheet
// rather than bouncing the user out to Safari. Keeps the reading session
// uninterrupted, with a Done button to slide back to the lesson.

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(tealAccent)
        vc.dismissButtonStyle = .done
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Small Identifiable wrapper so a tapped URL can drive `.sheet(item:)`.
struct BrowserLink: Identifiable {
    let id = UUID()
    let url: URL
}
