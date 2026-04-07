import SwiftUI

// MARK: - DeckReaderView

struct DeckReaderView: View {
    @ObservedObject var viewModel: FeedViewModel
    let onDismiss: () -> Void

    // Local state owns the displayed position to avoid animation flash from
    // the viewModel's @Published indices.
    @State private var displayedCardIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    private var deck: CardDeck? { viewModel.currentDeck }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBg.ignoresSafeArea()

                if let deck = deck {
                    let cards = deck.cards

                    // Card layer
                    ZStack {
                        if displayedCardIndex < cards.count {
                            FullCardView(
                                card: cards[displayedCardIndex],
                                deck: deck,
                                geo: geo
                            )
                            .offset(y: dragOffset)
                            .gesture(
                                DragGesture(minimumDistance: 10)
                                    .onChanged { value in
                                        guard !isAnimating else { return }
                                        dragOffset = value.translation.height
                                    }
                                    .onEnded { value in
                                        guard !isAnimating else { return }
                                        handleSwipe(
                                            dy: value.translation.height,
                                            predictedDy: value.predictedEndTranslation.height,
                                            screenHeight: geo.size.height,
                                            cards: cards
                                        )
                                    }
                            )
                        }
                    }

                    // Fixed overlay — positioned in front, hit-testing only on close button
                    overlayLayer(deck: deck, cards: cards, geo: geo)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            displayedCardIndex = viewModel.currentCardIndex
        }
    }

    // MARK: - Swipe Handler

    private func handleSwipe(dy: CGFloat, predictedDy: CGFloat,
                             screenHeight: CGFloat, cards: [Card]) {
        let swipeUp   = dy < -80 || predictedDy < -200
        let swipeDown = dy >  80 || predictedDy >  200
        let isLast  = displayedCardIndex >= cards.count - 1
        let isFirst = displayedCardIndex <= 0

        if swipeUp {
            if isLast {
                // Last card → advance to next paper
                animateCardOff(direction: -1, screenHeight: screenHeight) {
                    viewModel.advancePaper()
                    viewModel.currentCardIndex = 0
                    displayedCardIndex = 0
                }
            } else {
                // Next card
                animateCardOff(direction: -1, screenHeight: screenHeight) {
                    displayedCardIndex += 1
                    viewModel.currentCardIndex = displayedCardIndex
                }
            }
        } else if swipeDown {
            if isFirst {
                // First card → dismiss reader
                animateCardOff(direction: 1, screenHeight: screenHeight) {
                    onDismiss()
                }
            } else {
                // Previous card
                animateCardOff(direction: 1, screenHeight: screenHeight) {
                    displayedCardIndex -= 1
                    viewModel.currentCardIndex = displayedCardIndex
                }
            }
        } else {
            // Not a committed swipe — spring back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                dragOffset = 0
            }
        }
    }

    /// Slides the card off-screen, runs `completion`, then resets offset.
    private func animateCardOff(direction: CGFloat, screenHeight: CGFloat,
                                completion: @escaping () -> Void) {
        isAnimating = true
        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = direction * screenHeight
        } completion: {
            completion()
            dragOffset = 0
            isAnimating = false
        }
    }

    // MARK: - Overlay Layer

    @ViewBuilder
    private func overlayLayer(deck: CardDeck, cards: [Card], geo: GeometryProxy) -> some View {
        ZStack {
            // Top bar
            VStack {
                HStack(alignment: .center) {
                    // Close button — only interactive element
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Progress dots
                    ProgressDotsView(total: cards.count, current: displayedCardIndex)

                    Spacer()

                    // Signal strength
                    SignalStrengthView(strength: deck.signalStrength)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, 20)
                .padding(.top, geo.safeAreaInsets.top + 12)

                Spacer()

                // Paper counter at bottom
                Text("\(viewModel.currentPaperIndex + 1) / \(viewModel.decks.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.bottom, geo.safeAreaInsets.bottom + 16)
            }
        }
        .allowsHitTesting(false)
        // Re-enable hit testing only for the close button via the Button above.
        // We punch through by applying allowsHitTesting(false) after the ZStack
        // except the Button which has its own hit area.
        .overlay(alignment: .topLeading) {
            // Invisible touch target for the close button (already above),
            // we need the ZStack to pass touches through for the drag gesture.
            Color.clear
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }
                .padding(.leading, 20)
                .padding(.top, geo.safeAreaInsets.top + 4)
        }
    }
}

// MARK: - Progress Dots

private struct ProgressDotsView: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.white : Color.white.opacity(0.25))
                    .frame(width: i == current ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - FullCardView

struct FullCardView: View {
    let card: Card
    let deck: CardDeck
    let geo: GeometryProxy

    var body: some View {
        ZStack(alignment: .topLeading) {
            background
            content
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .clipped()
    }

    // MARK: Background per card type

    @ViewBuilder
    private var background: some View {
        switch card.type {
        case .hook:
            LinearGradient(
                colors: [Color(hex: "0a1628"), accentBlue.opacity(0.5), pageBg],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

        case .coreIdea:
            LinearGradient(
                colors: [pageBg, Color(hex: "0d1a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

        case .eli5:
            LinearGradient(
                colors: [pageBg, Color(hex: "0a1f1a")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

        case .analogy:
            LinearGradient(
                colors: [pageBg, Color(hex: "151020")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

        case .visual:
            pageBg.ignoresSafeArea()

        case .takeaway:
            LinearGradient(
                colors: [pageBg, accentBlue.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: Content per card type

    @ViewBuilder
    private var content: some View {
        switch card.type {
        case .hook:       HookCardContent(card: card, deck: deck, geo: geo)
        case .coreIdea:   CoreIdeaCardContent(card: card, geo: geo)
        case .eli5:       ELI5CardContent(card: card, geo: geo)
        case .analogy:    AnalogyCardContent(card: card, geo: geo)
        case .visual:     VisualCardContent(card: card, geo: geo)
        case .takeaway:   TakeawayCardContent(card: card, geo: geo)
        }
    }
}

// MARK: - Hook Card

private struct HookCardContent: View {
    let card: Card
    let deck: CardDeck
    let geo: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Source badge
            if let src = deck.source {
                SourceBadge(source: src, color: accentBlue)
                    .padding(.top, geo.safeAreaInsets.top + 80)
                    .padding(.bottom, 24)
            } else {
                Spacer()
                    .frame(height: geo.safeAreaInsets.top + 80 + 24)
            }

            Spacer()

            // Main hook text
            if let text = card.text {
                Text(text)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Swipe hint
            HStack(spacing: 5) {
                Text("↑")
                    .font(.system(size: 13, weight: .semibold))
                Text("Swipe to explore")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.25))
            .padding(.bottom, geo.safeAreaInsets.bottom + 32)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Core Idea Card

private struct CoreIdeaCardContent: View {
    let card: Card
    let geo: GeometryProxy

    private var ideas: [String] {
        (card.text ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: geo.safeAreaInsets.top + 80)

            // Label
            CardTypeLabel(icon: "list.bullet", title: "CORE IDEAS", color: accentBlue)
                .padding(.bottom, 12)

            // Title
            Text("The 3 things to know")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 28)

            // Ideas list
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(ideas.enumerated()), id: \.offset) { i, idea in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(i + 1)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(accentBlue.opacity(0.35))
                            .frame(width: 30, alignment: .leading)
                        Text(idea)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ELI5 Card

private struct ELI5CardContent: View {
    let card: Card
    let geo: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: geo.safeAreaInsets.top + 80)

            // Label
            HStack(spacing: 8) {
                Text("🧠")
                    .font(.system(size: 20))
                CardTypeLabel(icon: nil, title: "ELI5", color: Color(hex: "5effa0"))
            }
            .padding(.bottom, 12)

            Text("In plain English")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)

            Text(card.text ?? card.description ?? "")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Analogy Card

private struct AnalogyCardContent: View {
    let card: Card
    let geo: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: geo.safeAreaInsets.top + 80)

            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "ffd06b"))
                CardTypeLabel(icon: nil, title: "ANALOGY", color: Color(hex: "ffd06b"))
            }
            .padding(.bottom, 12)

            Text("Think of it like…")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)

            // Quote mark
            Text("\u{201C}")
                .font(.system(size: 72, weight: .black, design: .serif))
                .foregroundStyle(accentBlue.opacity(0.3))
                .frame(height: 36)
                .padding(.bottom, 8)

            Text(card.text ?? card.description ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Visual Card

private struct VisualCardContent: View {
    let card: Card
    let geo: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: geo.safeAreaInsets.top + 80)

            HStack(spacing: 6) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentBlue)
                CardTypeLabel(icon: nil, title: "VISUAL", color: accentBlue)
            }
            .padding(.bottom, 12)

            Text("Visualized")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)

            if let visual = card.visual {
                VisualRendererView(schema: visual)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let desc = card.description {
                Text(desc)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Takeaway Card

private struct TakeawayCardContent: View {
    let card: Card
    let geo: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: geo.safeAreaInsets.top + 80)

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentBlue)
                CardTypeLabel(icon: nil, title: "TAKEAWAY", color: accentBlue)
            }
            .padding(.bottom, 12)

            Text("Why it matters")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 24)

            Text(card.text ?? card.description ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text("End of paper · Swipe for next ↓")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.22))
                .padding(.bottom, geo.safeAreaInsets.bottom + 32)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CardTypeLabel

private struct CardTypeLabel: View {
    let icon: String?
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .kerning(2)
        }
    }
}

// MARK: - Preview

#Preview {
    DeckReaderView(viewModel: {
        let vm = FeedViewModel()
        vm.decks = [.preview]
        vm.currentPaperIndex = 0
        vm.currentCardIndex  = 0
        return vm
    }()) {
        // dismiss
    }
}
