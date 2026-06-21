import SwiftUI

// MARK: - OnboardingView
//
// First-launch tour. Four paged cards introducing the app's core mental
// model: exploring papers in Discover, the saved library, and the inline
// glossary. Last card lands the user in the app.
//
// Persists completion via @AppStorage("onboarding.completed") so the
// tour only fires once per install. Settings can re-set this flag if
// we want to replay it for an existing user.

struct OnboardingView: View {
    @AppStorage("onboarding.completed") private var completed: Bool = false
    @State private var page: Int = 0

    private var pages: [OnboardingPage] { OnboardingPage.all }

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        pageView(p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .motionAware(.easeInOut, value: page)

                pageDots
                ctaBlock
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .scaledFont(size: 13, weight: .semibold)
                .foregroundStyle(mutedText)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            illustration(for: p)
                .padding(.bottom, 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                Text(p.eyebrow)
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
                Text(p.title)
                    .scaledFont(size: 30, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(p.body)
                    .scaledFont(size: 14, design: .serif)
                    .foregroundStyle(mutedText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                if let footnote = p.footnote {
                    Text(footnote)
                        .scaledFont(size: 12, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText.opacity(0.8))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func illustration(for p: OnboardingPage) -> some View {
        switch p.kind {
        case .welcome:    welcomeIllustration
        case .daily:      dailyIllustration
        case .path:       pathIllustration
        case .library:    libraryIllustration
        case .glossary:   glossaryIllustration
        }
    }

    // Welcome — big italic 'a' watermark on a soft circular wash
    private var welcomeIllustration: some View {
        ZStack {
            Circle().fill(tealLight).frame(width: 220, height: 220)
            Text("a")
                .scaledFont(size: 180, weight: .regular, design: .serif)
                .italic()
                .foregroundStyle(tealAccent.opacity(0.85))
                .offset(y: -8)
        }
    }

    // Daily — single editorial card stack with deck pages peeking out
    private var dailyIllustration: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .frame(width: 170, height: 220)
                    .offset(x: CGFloat(i) * -10, y: CGFloat(i) * -8)
                    .shadow(color: inkColor.opacity(0.05), radius: 6, y: 2)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY · 7 MIN")
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                Rectangle().fill(inkColor.opacity(0.85)).frame(height: 9).cornerRadius(2)
                Rectangle().fill(inkColor.opacity(0.85)).frame(width: 110, height: 9).cornerRadius(2)
                Spacer().frame(height: 4)
                Rectangle().fill(mutedText.opacity(0.5)).frame(height: 5).cornerRadius(2)
                Rectangle().fill(mutedText.opacity(0.5)).frame(width: 130, height: 5).cornerRadius(2)
                Rectangle().fill(mutedText.opacity(0.5)).frame(width: 100, height: 5).cornerRadius(2)
            }
            .frame(width: 140, alignment: .leading)
            .padding(14)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: inkColor.opacity(0.10), radius: 12, y: 6)
        }
        .frame(height: 220)
    }

    // Path — three mini nodes connected by dots, mirrors BundlesView path
    private var pathIllustration: some View {
        VStack(spacing: 10) {
            pathNodeMini(filled: true,  glyph: "checkmark", color: tealAccent, offset: -50)
            connectorMini(filled: true)
            pathNodeMini(filled: true,  glyph: "play.fill", color: amberAccent, offset: 0)
            connectorMini(filled: false)
            pathNodeMini(filled: false, glyph: "lock.fill", color: mutedText.opacity(0.4), offset: 50)
        }
        .padding(.vertical, 8)
    }

    private func pathNodeMini(filled: Bool, glyph: String, color: Color, offset: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(filled ? color : cardBg)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle().stroke(color.opacity(filled ? 0 : 0.6), lineWidth: 1.5)
                )
                .shadow(color: inkColor.opacity(0.05), radius: 3, y: 1)
            Image(systemName: glyph)
                .scaledFont(size: 13, weight: .bold)
                .foregroundStyle(filled ? .white : color)
        }
        .offset(x: offset)
    }

    private func connectorMini(filled: Bool) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(filled ? tealAccent.opacity(0.5) : mutedText.opacity(0.25))
                    .frame(width: 4, height: 4)
            }
        }
    }

    // Library — bookmark icon + faux saved row stack
    private var libraryIllustration: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(tealAccent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tealLight))
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle().fill(inkColor.opacity(0.8)).frame(width: 130, height: 8).cornerRadius(2)
                    Rectangle().fill(mutedText.opacity(0.5)).frame(width: 90, height: 5).cornerRadius(2)
                }
                Spacer()
            }
            .padding(12)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(borderColor, lineWidth: 1))

            HStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(tealAccent)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tealLight))
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle().fill(inkColor.opacity(0.8)).frame(width: 110, height: 8).cornerRadius(2)
                    Rectangle().fill(mutedText.opacity(0.5)).frame(width: 70, height: 5).cornerRadius(2)
                }
                Spacer()
            }
            .padding(12)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(borderColor, lineWidth: 1))
        }
        .frame(width: 240)
    }

    // Glossary — sample sentence with one term carrying the real teal
    // dotted-underline treatment, plus the definition popup it surfaces.
    private var glossaryTermAttributed: AttributedString {
        var a = AttributedString("attention")
        a.font = .system(size: 15, weight: .semibold, design: .serif)
        a.foregroundColor = tealAccent
        a.underlineStyle = Text.LineStyle(pattern: .dot, color: tealAccent.opacity(0.5))
        return a
    }

    private var glossaryIllustration: some View {
        VStack(spacing: 18) {
            // Faux body text with a glossary-styled term
            (Text("Stack ")
                + Text(glossaryTermAttributed)
                + Text(" layers and depth becomes capacity."))
                .scaledFont(size: 15, design: .serif)
                .foregroundStyle(inkColor)
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            // Popup card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("ATTENTION")
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.6)
                        .foregroundStyle(tealAccent)
                    Spacer()
                    Image(systemName: "xmark")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(mutedText)
                }
                Text("A mechanism that lets each token weigh every other token by relevance.")
                    .scaledFont(size: 12, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(tealAccent.opacity(0.4), lineWidth: 1))
            .shadow(color: tealAccent.opacity(0.18), radius: 12, y: 4)
            .frame(width: 240)
        }
        .frame(width: 280)
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? tealAccent : mutedText.opacity(0.25))
                    .frame(width: i == page ? 22 : 6, height: 6)
                    .motionAware(.spring(response: 0.32, dampingFraction: 0.85), value: page)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
    }

    private var ctaBlock: some View {
        VStack(spacing: 10) {
            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page == pages.count - 1 ? "Start reading" : "Continue")
                    .scaledFont(size: 14, weight: .bold)
                    .tracking(0.6)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(inkColor)
                    )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { page -= 1 }
            } label: {
                Text("Back")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundStyle(mutedText)
            }
            .opacity(page > 0 ? 1 : 0)
            .disabled(page == 0)
            .accessibilityHidden(page == 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private func finish() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeInOut(duration: 0.35)) { completed = true }
    }
}

// MARK: - OnboardingPage model

struct OnboardingPage {
    enum Kind { case welcome, daily, path, library, glossary }
    let kind: Kind
    let eyebrow: String
    let title: String
    let body: String
    let footnote: String?

    static let all: [OnboardingPage] = [
        OnboardingPage(
            kind: .welcome,
            eyebrow: "WELCOME",
            title: "Papers, distilled.",
            body: "Aprecis turns dense AI research into bite-size lessons you can finish on a coffee break.",
            footnote: "One small idea at a time. No rush."
        ),
        OnboardingPage(
            kind: .daily,
            eyebrow: "DISCOVER",
            title: "Explore the research.",
            body: "Search any topic in Discover, then open a paper as interactive learning materials.",
            footnote: "Each paper shows how its ideas connect to the next."
        ),
        OnboardingPage(
            kind: .library,
            eyebrow: "LIBRARY",
            title: "Keep what matters.",
            body: "Tap the bookmark on any paper to save it. Or swipe a row left from the Explore list to save without opening.",
            footnote: nil
        ),
        OnboardingPage(
            kind: .glossary,
            eyebrow: "GLOSSARY",
            title: "Tap the dotted words.",
            body: "Inside any paper, key terms carry a teal dotted underline. Tap one to surface a quick definition; tap again to dismiss.",
            footnote: "Plain teal words are just emphasis. The dotted underline marks a definition."
        ),
    ]
}
