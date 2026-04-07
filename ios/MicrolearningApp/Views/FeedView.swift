import SwiftUI

// MARK: - FeedView

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var readerOpen = false
    @AppStorage("totalPapersRead") private var totalPapersRead = 0

    // Decks that qualify for the "Before It Matters" rail
    private var featuredDecks: [CardDeck] {
        let high = viewModel.decks.filter { $0.isHighSignal }
        let source = high.isEmpty ? viewModel.decks : high
        return Array(source.prefix(5))
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            if viewModel.isLoading && viewModel.decks.isEmpty {
                FeedLoadingView()
            } else if let msg = viewModel.error, viewModel.decks.isEmpty {
                FeedErrorView(message: msg) { Task { await viewModel.loadFeed() } }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {

                        // MARK: Slim Header
                        FeedHeaderView()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        // MARK: Before It Matters
                        if !featuredDecks.isEmpty {
                            BeforeItMattersSection(
                                decks: featuredDecks,
                                onTap: { deck in
                                    if let idx = viewModel.decks.firstIndex(where: { $0.id == deck.id }) {
                                        viewModel.currentPaperIndex = idx
                                        viewModel.currentCardIndex  = 0
                                        totalPapersRead = max(totalPapersRead, idx + 1)
                                        readerOpen = true
                                    }
                                }
                            )
                            .padding(.bottom, 32)
                        }

                        // MARK: All Papers
                        SectionHeader(title: "All Papers", subtitle: nil)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)

                        ForEach(Array(viewModel.decks.enumerated()), id: \.element.id) { i, deck in
                            DeckRowCard(deck: deck)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.currentPaperIndex = i
                                    viewModel.currentCardIndex  = 0
                                    totalPapersRead = max(totalPapersRead, i + 1)
                                    readerOpen = true
                                }
                                .onAppear {
                                    if i >= viewModel.decks.count - 3 {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(accentBlue)
                                .padding(.vertical, 24)
                        }

                        Color.clear.frame(height: 50)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $readerOpen) {
            DeckReaderView(viewModel: viewModel) {
                readerOpen = false
            }
        }
        .task { await viewModel.loadFeed() }
    }
}

// MARK: - FeedHeaderView

private struct FeedHeaderView: View {
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Aprecis")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(accentBlue)
                Text("AI Research Feed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            // Bolt icon echoes the tab
            Image(systemName: "bolt.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accentBlue.opacity(0.7))
        }
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            Spacer()
        }
    }
}

// MARK: - Before It Matters Section

private struct BeforeItMattersSection: View {
    let decks: [CardDeck]
    let onTap: (CardDeck) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Before it matters", subtitle: "Papers you should know first")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(decks) { deck in
                        FeaturedCard(deck: deck)
                            .onTapGesture { onTap(deck) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - FeaturedCard (horizontal rail item)

private struct FeaturedCard: View {
    let deck: CardDeck

    private var hookText: String {
        deck.cards.first(where: { $0.type == .hook })?.text ?? deck.title ?? "Untitled Paper"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background gradient
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "0a1628"),
                            accentBlue.opacity(0.45),
                            pageBg,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                // Top row: source badge + "⚡ NOW" badge
                HStack(spacing: 6) {
                    if let src = deck.source {
                        SourceBadge(source: src, color: accentBlue)
                    }
                    Spacer()
                    // ⚡ NOW urgency badge
                    HStack(spacing: 3) {
                        Text("⚡")
                            .font(.system(size: 9))
                        Text("NOW")
                            .font(.system(size: 9, weight: .black))
                            .kerning(0.8)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(urgentColor)
                    .clipShape(Capsule())
                }

                Spacer()

                // Hook text — 2 lines
                Text(hookText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)

                // Bottom row: signal + card count
                HStack(alignment: .center, spacing: 6) {
                    SignalStrengthView(strength: deck.signalStrength)
                    Text("\(deck.cards.count) cards")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(16)
        }
        .frame(width: 280, height: 170)
    }
}

// MARK: - DeckRowCard

struct DeckRowCard: View {
    let deck: CardDeck

    private var hookText: String {
        deck.cards.first(where: { $0.type == .hook })?.text ?? deck.title ?? "Untitled Paper"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardSurface)

            VStack(alignment: .leading, spacing: 8) {
                // Source + signal row
                HStack(alignment: .center) {
                    if let src = deck.source {
                        SourceBadge(source: src, color: accentBlue)
                    }
                    Spacer()
                    SignalStrengthView(strength: deck.signalStrength)
                }

                // Hook text
                Text(hookText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Footer
                HStack {
                    Text("\(deck.cards.count) cards")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                    HStack(spacing: 3) {
                        Text("Read")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 140)
    }
}

// MARK: - SourceBadge (shared)

struct SourceBadge: View {
    let source: String
    let color: Color

    var body: some View {
        Text(source.uppercased())
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .kerning(1.2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - SignalStrengthView (shared)

struct SignalStrengthView: View {
    /// 1–5 signal level
    let strength: Int

    private let barHeights: [CGFloat] = [8, 12, 16, 20]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { idx in
                let filled = (idx + 1) <= min(strength, 4)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(filled ? accentBlue : Color.white.opacity(0.15))
                    .frame(width: 4, height: barHeights[idx])
            }
        }
        .frame(width: 20, height: 24, alignment: .bottom)
    }
}

// MARK: - Loading

private struct FeedLoadingView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()
            VStack(spacing: 20) {
                Circle()
                    .fill(accentBlue.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(accentBlue)
                    )
                Text("Loading feed…")
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
            pageBg.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.4))
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 13)
                        .background(accentBlue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FeedView(viewModel: FeedViewModel())
}
