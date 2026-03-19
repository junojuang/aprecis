import SwiftUI
import UIKit

// MARK: - FeedView

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea()

            if viewModel.isLoading && viewModel.decks.isEmpty {
                FeedLoadingView()
            } else if let msg = viewModel.error, viewModel.decks.isEmpty {
                FeedErrorView(message: msg) { Task { await viewModel.loadFeed() } }
            } else if !viewModel.decks.isEmpty {
                CardFeedView(viewModel: viewModel)
            }
        }
        .task { await viewModel.loadFeed() }
    }
}

// MARK: - CardFeedView

struct CardFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var dragAxis: DragAxis? = nil
    @State private var isAnimating = false

    enum DragAxis { case vertical, horizontal }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                cardLayers(w: w, h: h)
                hud(w: w, h: h)
            }
            .gesture(makeGesture(w: w, h: h))
        }
        .ignoresSafeArea()
    }

    // MARK: - Card Layers

    @ViewBuilder
    private func cardLayers(w: CGFloat, h: CGFloat) -> some View {
        let vy = dragAxis == .vertical ? dragOffset.height : 0
        let hx = dragAxis == .horizontal ? dragOffset.width : 0

        ZStack {
            // Prev card (above current)
            if let prev = viewModel.previousCard, let deck = viewModel.currentDeck {
                CardView(card: prev, deck: deck)
                    .frame(width: w, height: h)
                    .offset(y: -h + vy)
            }

            // Next card (below current)
            if let next = viewModel.nextCard, let deck = viewModel.currentDeck {
                CardView(card: next, deck: deck)
                    .frame(width: w, height: h)
                    .offset(y: h + vy)
            }

            // Prev paper (left) — only during horizontal drag right
            if let pp = viewModel.prevPaperFirstCard, hx > 0 {
                CardView(card: pp.card, deck: pp.deck)
                    .frame(width: w, height: h)
                    .offset(x: -w + hx)
            }

            // Next paper (right) — only during horizontal drag left
            if let np = viewModel.nextPaperFirstCard, hx < 0 {
                CardView(card: np.card, deck: np.deck)
                    .frame(width: w, height: h)
                    .offset(x: w + hx)
            }

            // Current card
            if let card = viewModel.currentCard, let deck = viewModel.currentDeck {
                CardView(card: card, deck: deck)
                    .frame(width: w, height: h)
                    .offset(x: hx, y: vy)
                    .scaleEffect(dragScale(w: w, h: h))
            }
        }
    }

    private func dragScale(w: CGFloat, h: CGFloat) -> CGFloat {
        guard dragAxis != nil else { return 1 }
        let drag = max(abs(dragOffset.width), abs(dragOffset.height))
        let ref = max(w, h)
        return max(0.94, 1 - (drag / ref) * 0.06)
    }

    // MARK: - HUD

    @ViewBuilder
    private func hud(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            bottomBar
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 44)
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("microlearn")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .kerning(2)
                    .textCase(.uppercase)
                if let src = viewModel.currentDeck?.source {
                    sourcePill(src)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.currentPaperIndex + 1) / \(viewModel.decks.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white.opacity(0.4))
                        .scaleEffect(0.6)
                }
            }
        }
    }

    private func sourcePill(_ source: String) -> some View {
        Text(source.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(sourceColor(source).opacity(0.9))
            .kerning(1.2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(sourceColor(source).opacity(0.15))
            .clipShape(Capsule())
    }

    private func sourceColor(_ source: String) -> Color {
        switch source {
        case "arxiv":       return .purple
        case "github":      return .green
        case "hackernews":  return .orange
        case "rss":         return .cyan
        default:            return .white
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            if let card = viewModel.currentCard {
                Text(card.type.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
                    .kerning(1.5)
            }
            Spacer()
            cardDots
        }
    }

    private var cardDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<(viewModel.currentDeck?.cards.count ?? 0), id: \.self) { i in
                let isCurrent = i == viewModel.currentCardIndex
                Capsule()
                    .fill(isCurrent ? Color.white : Color.white.opacity(0.2))
                    .frame(width: isCurrent ? 18 : 5, height: 5)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.currentCardIndex)
            }
        }
    }

    // MARK: - Gesture

    private func makeGesture(w: CGFloat, h: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isAnimating else { return }
                if dragAxis == nil {
                    let ax = abs(value.translation.width)
                    let ay = abs(value.translation.height)
                    dragAxis = ax > ay ? .horizontal : .vertical
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimating else { return }
                handleGestureEnd(value, w: w, h: h)
            }
    }

    private func handleGestureEnd(_ value: DragGesture.Value, w: CGFloat, h: CGFloat) {
        let axis = dragAxis
        let vThreshold = h * 0.18
        let hThreshold = w * 0.22
        let velocityThreshold: CGFloat = 550

        func snapBack() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
            dragAxis = nil
        }

        func commit(to target: CGSize, navigate: @escaping () -> Void) {
            isAnimating = true
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                dragOffset = target
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigate()
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    dragOffset = .zero
                    dragAxis = nil
                }
                isAnimating = false
            }
        }

        switch axis {
        case .vertical:
            let dy = value.translation.height
            let vy = value.predictedEndTranslation.height
            if dy < -vThreshold || vy < -velocityThreshold {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                commit(to: CGSize(width: 0, height: -h)) { viewModel.advanceCard() }
            } else if dy > vThreshold || vy > velocityThreshold {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                commit(to: CGSize(width: 0, height: h)) { viewModel.retreatCard() }
            } else {
                snapBack()
            }

        case .horizontal:
            let dx = value.translation.width
            let vx = value.predictedEndTranslation.width
            if dx < -hThreshold || vx < -velocityThreshold {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                commit(to: CGSize(width: -w, height: 0)) { viewModel.advancePaper() }
            } else if dx > hThreshold || vx > velocityThreshold {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                commit(to: CGSize(width: w, height: 0)) { viewModel.retreatPaper() }
            } else {
                snapBack()
            }

        case nil:
            snapBack()
        }
    }
}

// MARK: - Loading

private struct FeedLoadingView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea()
            VStack(spacing: 20) {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white.opacity(0.7))
                    )
                Text("Loading feed")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Error

private struct FeedErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.3))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 13)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    FeedView()
}
