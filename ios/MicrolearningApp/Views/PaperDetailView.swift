import SwiftUI

// MARK: - PaperDetailView
//
// Deck-style paper reader. Every paper opens as a swipeable sequence of
// full-screen cards instead of one long scrolling page:
//   • Hook (dark teal), the "why you care" sentence
//   • One card per concept, kicker + serif title + prose body + optional diagram
//   • Takeaway, recap quote, source line, 2-stat row, restart + Done
//
// Navigation: bottom Continue / swipe / tap scrubber dots. Reading progress
// is (currentCard / totalCards).

struct PaperDetailView: View {
    let deck: CardDeck
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var progressStore = ReadingProgressStore.shared
    @ObservedObject private var savedStore = SavedPapersStore.shared
    @State private var cardIndex: Int = 0
    @State private var revealedConcepts: Set<Int> = [0]  // first concept auto-revealed

    // MARK: Card model

    private enum DeckCard: Equatable {
        case hook
        case concept(Int)
        case takeaway
    }

    private var cards: [DeckCard] {
        var out: [DeckCard] = []
        if deck.hook != nil || deck.title != nil { out.append(.hook) }
        for i in deck.concepts.indices { out.append(.concept(i)) }
        out.append(.takeaway)
        return out
    }

    private var currentCard: DeckCard {
        cards[min(cardIndex, cards.count - 1)]
    }

    // MARK: Body

    var body: some View {
        ZStack {
            backgroundFor(currentCard)
                .ignoresSafeArea()
                .motionAware(.easeInOut(duration: 0.35), value: cardIndex)

            VStack(spacing: 0) {
                topBar
                ZStack {
                    cardContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                bottomBar
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { v in
                    if v.translation.height < -60 && abs(v.translation.width) < 40 {
                        advance()
                    } else if v.translation.width < -70 {
                        advance()
                    } else if v.translation.width > 70 {
                        back()
                    }
                }
        )
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { restoreProgress() }
        .onChange(of: cardIndex) { _, _ in saveProgress() }
        .onDisappear { saveProgress() }
    }

    // MARK: Backgrounds

    @ViewBuilder
    private func backgroundFor(_ card: DeckCard) -> some View {
        switch card {
        case .hook:
            HookCoverBackground()
        case .takeaway:
            ZStack {
                paperBg
                RadialGradient(colors: [amberAccent.opacity(0.15), .clear],
                               center: .top, startRadius: 0, endRadius: 320)
                RadialGradient(colors: [tealAccent.opacity(0.13), .clear],
                               center: .bottom, startRadius: 0, endRadius: 280)
            }
        case .concept:
            paperBg
        }
    }

    // MARK: Top bar

    @ViewBuilder
    private var topBar: some View {
        let dark = currentCard == .hook
        HStack(spacing: 12) {
            Button {
                if cardIndex == 0 { dismiss() } else { back() }
            } label: {
                Image(systemName: cardIndex == 0 ? "xmark" : "chevron.left")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(dark ? Color.white : inkColor)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(dark ? Color.white.opacity(0.12) : Color(hex: "efeae1"))
                    )
            }
            .accessibilityLabel(cardIndex == 0 ? "Close" : "Previous card")

            DeckDots(index: cardIndex, count: cards.count, dark: dark)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Card \(cardIndex + 1) of \(cards.count)")

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(dark ? Color.white : inkColor)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(dark ? Color.white.opacity(0.12) : Color(hex: "efeae1"))
                    )
                    .opacity(cardIndex == 0 ? 0 : 1)
            }
            .accessibilityLabel("Close")
            .accessibilityHidden(cardIndex == 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Card content

    @ViewBuilder
    private var cardContent: some View {
        switch currentCard {
        case .hook:
            DeckHookCard(deck: deck)
        case .concept(let i):
            if deck.concepts.indices.contains(i) {
                DeckConceptCard(
                    concept: deck.concepts[i],
                    index: i,
                    total: deck.concepts.count,
                    isRevealed: revealedConcepts.contains(i),
                    onReveal: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            _ = revealedConcepts.insert(i)
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                )
            }
        case .takeaway:
            DeckTakeawayCard(deck: deck, cardIndex: cardIndex, total: cards.count, onRestart: restart, onDone: { dismiss() })
        }
    }

    // MARK: Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        if currentCard == .takeaway {
            Color.clear.frame(height: 8)
        } else {
            HStack(spacing: 10) {
                Button(action: advance) {
                    HStack(spacing: 8) {
                        Text(nextLabel)
                        Image(systemName: "arrow.right")
                            .accessibilityHidden(true)
                    }
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundStyle(currentCard == .hook ? inkColor : paperBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(currentCard == .hook ? Color(hex: "5fd4d4") : inkColor)
                    )
                }
                .buttonStyle(.plain)

                deckBookmarkIconButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
    }

    /// Icon-only bookmark at thumb height (matches Explore “Open paper” row).
    private var deckBookmarkIconButton: some View {
        let saved = savedStore.isSaved(deck.paperId)
        return Button {
            savedStore.toggleOrPromptSignIn(deck.paperId)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .scaledFont(size: 16, weight: .semibold)
                .foregroundStyle(saved ? tealAccent : inkColor)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(saved ? "Remove from library" : "Save to library")
    }

    private var nextLabel: String {
        switch currentCard {
        case .hook: return "Start reading"
        case .concept(let i):
            if i + 1 < deck.concepts.count { return "Next concept" }
            return "Wrap up"
        case .takeaway: return ""
        }
    }

    // MARK: Navigation

    private func advance() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            if cardIndex < cards.count - 1 { cardIndex += 1 }
        }
        if case .concept(let i) = cards[min(cardIndex, cards.count - 1)] {
            revealedConcepts.insert(i)
        }
        saveProgress()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func back() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            cardIndex = max(cardIndex - 1, 0)
        }
        saveProgress()
    }

    private func restart() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            cardIndex = 0
            revealedConcepts = [0]
        }
    }

    // MARK: Progress

    private func restoreProgress() {
        let restored: Int
        if let raw = progressStore.lastCardIndex(for: deck.paperId) {
            restored = raw
        } else {
            // Legacy decks only have the 0.0–1.0 fraction stored. Recover
            // an approximate card index from it so users who read before
            // the raw-index store existed still resume in the right place.
            let fraction = progressStore.progress(for: deck.paperId)
            restored = Int((fraction * Double(cards.count - 1)).rounded())
        }
        cardIndex = min(max(restored, 0), cards.count - 1)

        // Reveal every concept up to and including the resumed card so
        // earlier concepts don't read as "tap to reveal" placeholders
        // when the reader returns to a paper they already opened.
        for case .concept(let i) in cards.prefix(cardIndex + 1) {
            revealedConcepts.insert(i)
        }
    }

    private func saveProgress() {
        guard cards.count > 1 else { return }
        progressStore.setLastCardIndex(cardIndex, totalCards: cards.count, for: deck.paperId)
    }
}

// MARK: - Hook Cover Background
//
// Detail view cover (hook card) background. Echoes the home page hero card,
// which features a single oversized italic 'a' as a brand watermark. Here the
// 'a' is dissolved into its constituent geometry: a tilted bowl + counter
// upper-right, concentric rings radiating from that anchor, and three soft
// waves at the bottom suggesting the descending tail. All strokes sit at very
// low opacity so the center of the card stays clean for content.

private struct HookCoverBackground: View {
    private let surfaceTop = Color(hex: "0f3a3a")
    private let surfaceBtm = Color(hex: "0a2a2a")
    private let glow       = Color(hex: "5fd4d4")

    // Reference design viewBox. Scaled to fit any device size.
    private let designSize = CGSize(width: 800, height: 1200)
    private let aCenter    = CGPoint(x: 630, y: 240)

    var body: some View {
        GeometryReader { geo in
            let s = scale(for: geo.size)
            ZStack {
                LinearGradient(
                    colors: [surfaceTop, surfaceBtm],
                    startPoint: .top, endPoint: .bottom
                )

                RadialGradient(
                    colors: [glow.opacity(0.11), .clear],
                    center: UnitPoint(x: 0.78, y: 0.18),
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.62
                )

                RadialGradient(
                    colors: [glow.opacity(0.06), .clear],
                    center: UnitPoint(x: 0.5, y: 1),
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )

                Canvas { ctx, _ in
                    ctx.translateBy(x: offset(for: geo.size).x, y: offset(for: geo.size).y)
                    ctx.scaleBy(x: s, y: s)

                    drawGhostA(ctx)
                    drawConcentricRings(ctx)
                    drawTailWaves(ctx)
                }
            }
        }
        .ignoresSafeArea()
    }

    // Aspect-fill scale: cover the full screen, crop overflow.
    private func scale(for size: CGSize) -> CGFloat {
        max(size.width / designSize.width, size.height / designSize.height)
    }

    private func offset(for size: CGSize) -> CGPoint {
        let s = scale(for: size)
        return CGPoint(
            x: (size.width  - designSize.width  * s) / 2,
            y: (size.height - designSize.height * s) / 2
        )
    }

    private func drawGhostA(_ ctx: GraphicsContext) {
        let stroke = GraphicsContext.Shading.color(glow.opacity(0.08))
        let style  = StrokeStyle(lineWidth: 1.4, lineCap: .round)

        // Tilted outer bowl
        let bowl = Path(ellipseIn: CGRect(x: aCenter.x - 220, y: aCenter.y - 248, width: 440, height: 496))
            .applying(rotation(by: -12, around: aCenter))
        ctx.stroke(bowl, with: stroke, style: style)

        // Inner counter (the eye of the 'a')
        let counter = Path(ellipseIn: CGRect(x: 642 - 118, y: 230 - 138, width: 236, height: 276))
            .applying(rotation(by: -12, around: CGPoint(x: 642, y: 230)))
        ctx.stroke(counter, with: stroke, style: style)

        // Descending tail
        var tail = Path()
        tail.move(to: CGPoint(x: 820, y: 380))
        tail.addQuadCurve(to: CGPoint(x: 690, y: 620), control: CGPoint(x: 780, y: 540))
        tail.addQuadCurve(to: CGPoint(x: 520, y: 740), control: CGPoint(x: 610, y: 690))
        ctx.stroke(tail, with: stroke, style: style)

        // Stem entry
        var stem = Path()
        stem.move(to: CGPoint(x: 850, y: 60))
        stem.addQuadCurve(to: CGPoint(x: 820, y: 380), control: CGPoint(x: 884, y: 210))
        ctx.stroke(stem, with: stroke, style: style)
    }

    private func drawConcentricRings(_ ctx: GraphicsContext) {
        let stroke = GraphicsContext.Shading.color(glow.opacity(0.05))
        let style  = StrokeStyle(lineWidth: 1)
        for r in [340.0, 450.0, 580.0, 720.0, 880.0] {
            let ring = Path(ellipseIn: CGRect(
                x: aCenter.x - r, y: aCenter.y - r,
                width: r * 2, height: r * 2
            ))
            ctx.stroke(ring, with: stroke, style: style)
        }
    }

    private func drawTailWaves(_ ctx: GraphicsContext) {
        let stroke = GraphicsContext.Shading.color(glow.opacity(0.07))
        let style  = StrokeStyle(lineWidth: 1.1, lineCap: .round)
        let baselines: [CGFloat] = [980, 1040, 1100]
        let dips:      [CGFloat] = [916, 976, 1036]
        for (y, dip) in zip(baselines, dips) {
            var p = Path()
            p.move(to: CGPoint(x: -40, y: y))
            p.addQuadCurve(to: CGPoint(x: 400, y: y), control: CGPoint(x: 200, y: dip))
            // Reflected control point for smooth T-style continuation
            p.addQuadCurve(to: CGPoint(x: 840, y: y), control: CGPoint(x: 600, y: y - (y - dip)))
            ctx.stroke(p, with: stroke, style: style)
        }
    }

    private func rotation(by degrees: Double, around point: CGPoint) -> CGAffineTransform {
        CGAffineTransform.identity
            .translatedBy(x: point.x, y: point.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -point.x, y: -point.y)
    }
}

// MARK: - Dots

private struct DeckDots: View {
    let index: Int
    let count: Int
    let dark: Bool

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(count, 1), id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: i))
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for i: Int) -> Color {
        if i < index { return dark ? Color(hex: "5fd4d4") : tealAccent }
        if i == index { return dark ? Color.white : inkColor }
        return dark ? Color.white.opacity(0.2) : Color(hex: "e6e1d6")
    }
}

// MARK: - Hook Card

private struct DeckHookCard: View {
    let deck: CardDeck

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(sourceKicker.uppercased())
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.8)
                    .foregroundStyle(Color(hex: "5fd4d4"))
                    .padding(.bottom, 14)

                Text(hookHeadline)
                    .scaledFont(size: 28, weight: .semibold, design: .serif)
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18)

                if let title = deck.title, deck.hook != nil {
                    Text(title)
                        .scaledFont(size: 12)
                        .foregroundStyle(Color(hex: "b0b4bc"))
                        .lineSpacing(2)
                        .padding(.bottom, 14)
                }

                if let sub = subText, !sub.isEmpty {
                    Text(sub)
                        .scaledFont(size: 14)
                        .foregroundStyle(Color(hex: "d1d4dc"))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(metaLine)
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.top, 24)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }

    private var hookHeadline: String {
        deck.hook ?? deck.title ?? "Untitled paper"
    }

    private var subText: String? {
        if deck.hook != nil, let s = deck.summary, !s.isEmpty { return s }
        if deck.hook == nil, let first = deck.concepts.first { return first.body }
        return deck.summary
    }

    private var sourceKicker: String {
        switch deck.source {
        case "arxiv":  return "arXiv · new paper"
        case "github": return "GitHub · open source"
        case "hn":     return "Hacker News · tech"
        default:       return "Research"
        }
    }

    private var metaLine: String {
        let tag = deck.topicTagUppercased
        if let date = deck.publishedAt {
            let f = DateFormatter(); f.dateStyle = .medium
            return "\(tag) · \(f.string(from: date))"
        }
        return tag
    }
}

// MARK: - Concept Card

private struct DeckConceptCard: View {
    let concept: Concept
    let index: Int
    let total: Int
    let isRevealed: Bool
    let onReveal: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Optional cover image strip
                if concept.conceptImageUrl != nil {
                    ConceptCoverImage(imageUrl: concept.conceptImageUrl, colorIndex: index)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)
                }

                Text("CONCEPT \(String(format: "%02d", index + 1)) · \(index + 1) OF \(total)")
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                Text(concept.title)
                    .scaledFont(size: 26, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                if isRevealed {
                    Text(concept.body)
                        .scaledFont(size: 16, design: .serif)
                        .foregroundStyle(Color(hex: "2a2d36"))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    if let spec = concept.diagramSpec {
                        DiagramView(spec: spec)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color(hex: "e6e1d6"), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                } else {
                    Button(action: onReveal) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap")
                                .scaledFont(size: 13, weight: .semibold)
                                .accessibilityHidden(true)
                            Text("Tap to reveal")
                                .scaledFont(size: 13, weight: .semibold)
                                .tracking(0.3)
                        }
                        .foregroundStyle(tealAccent)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(tealLight)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 16)
            }
            .padding(.top, 6)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Takeaway / Complete

private struct DeckTakeawayCard: View {
    let deck: CardDeck
    let cardIndex: Int
    let total: Int
    let onRestart: () -> Void
    let onDone: () -> Void

    @ObservedObject private var savedStore = SavedPapersStore.shared
    @ObservedObject private var progressStore = ReadingProgressStore.shared
    @State private var dailyCount: Int = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // Editorial seal: an italic serif numeral perched on a thin
                // teal arc. No heavy gradient ring, no redundant minutes block.
                EndingSeal(ordinal: dailyCount)
                    .frame(width: 132, height: 132)
                    .padding(.top, 20)
                    .padding(.bottom, 26)
                    .accessibilityHidden(true)

                // Headline: dynamic, paper-count framing
                Text("You've read your \(ordinalPhrase(dailyCount)) paper of the day.")
                    .scaledFont(size: 24, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)

                // Paper title, small, uppercase tracking
                if let title = deck.title, !title.isEmpty {
                    Text(title)
                        .scaledFont(size: 11, weight: .medium, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 36)
                        .padding(.top, 10)
                }

                // Italic quote, kept as feature, breathing more space
                if let take = takeaway {
                    QuoteBlock(text: take)
                        .padding(.horizontal, 28)
                        .padding(.top, 26)
                }

                Spacer(minLength: 32)

                HStack(spacing: 10) {
                    Button(action: onRestart) {
                        Image(systemName: "arrow.counterclockwise")
                            .scaledFont(size: 14, weight: .semibold)
                            .foregroundStyle(inkColor)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "efeae1"))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Restart paper")

                    Button(action: onDone) {
                        Text("Done")
                            .scaledFont(size: 15, weight: .semibold, design: .serif)
                            .foregroundStyle(paperBg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(inkColor))
                    }
                    .buttonStyle(.plain)

                    Button {
                        savedStore.toggleOrPromptSignIn(deck.paperId)
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: savedStore.isSaved(deck.paperId) ? "bookmark.fill" : "bookmark")
                            .scaledFont(size: 16, weight: .semibold)
                            .foregroundStyle(savedStore.isSaved(deck.paperId) ? tealAccent : inkColor)
                            .frame(width: 46, height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(savedStore.isSaved(deck.paperId) ? "Remove from library" : "Save to library")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            dailyCount = progressStore.markCompletedToday(paperId: deck.paperId)
        }
    }

    private var takeaway: String? {
        if let hook = deck.hook, !hook.isEmpty { return hook }
        if let s = deck.summary, !s.isEmpty { return s }
        return deck.concepts.first?.body
    }

    private func ordinalPhrase(_ n: Int) -> String {
        let n = max(1, n)
        let suffix: String
        switch n % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}

// Italic serif quote in a centered block. Open/close glyphs sit as oversized
// teal flourishes either side of the text, anchoring it as a pull-quote.
// Shared across all ending screens (paper detail, daily loop complete).
struct QuoteBlock: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{201C}")
                .scaledFont(size: 38, weight: .regular, design: .serif)
                .foregroundStyle(tealAccent.opacity(0.55))
                .baselineOffset(-12)

            Text(text)
                .scaledFont(size: 15, design: .serif)
                .italic()
                .foregroundStyle(inkColor.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("\u{201D}")
                .scaledFont(size: 38, weight: .regular, design: .serif)
                .foregroundStyle(tealAccent.opacity(0.55))
                .baselineOffset(-12)
        }
    }
}

// Editorial seal, italic serif ordinal numeral on a thin teal arc.
// Replaces the heavy gradient ring; reads as a stamp, not a meter.
// Shared across all ending screens.
struct EndingSeal: View {
    let ordinal: Int

    var body: some View {
        ZStack {
            // Thin open arc ~ three-quarters circle, leaving a gap at the top
            Circle()
                .trim(from: 0.07, to: 0.93)
                .stroke(
                    LinearGradient(
                        colors: [tealAccent, amberAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Inner soft cream disc
            Circle()
                .fill(paperBg)
                .padding(10)
                .shadow(color: inkColor.opacity(0.04), radius: 6, y: 2)

            // Italic serif numeral
            Text("\(max(1, ordinal))")
                .scaledFont(size: 56, weight: .regular, design: .serif)
                .italic()
                .foregroundStyle(inkColor)

            // Tiny teal eyebrow above numeral
            VStack {
                Text("PAPER")
                    .scaledFont(size: 7, weight: .bold)
                    .tracking(2.4)
                    .foregroundStyle(tealAccent)
                    .padding(.top, 22)
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaperDetailView(deck: .preview)
    }
}
