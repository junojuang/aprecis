import SwiftUI

// MARK: - SearchView

struct SearchView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var query: String = ""
    @State private var readerOpen: Bool = false
    @FocusState private var searchFieldFocused: Bool

    // Filtered results
    private var results: [CardDeck] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty {
            // Show recent: first 10 from feed
            return Array(viewModel.decks.prefix(10))
        }
        let lower = q.lowercased()
        return viewModel.decks.filter { deck in
            if deck.title?.lowercased().contains(lower) == true { return true }
            return deck.cards.contains { card in
                card.text?.lowercased().contains(lower) == true ||
                card.description?.lowercased().contains(lower) == true
            }
        }
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                    Text("Find papers by keyword")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Search field
                SearchField(text: $query, isFocused: $searchFieldFocused)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Section label
                HStack {
                    Text(query.trimmingCharacters(in: .whitespaces).isEmpty ? "Recent" : "Results")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(0.5)
                    Spacer()
                    if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("\(results.count) found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Content
                if viewModel.isLoading && viewModel.decks.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(accentBlue)
                    Spacer()
                } else if results.isEmpty && !query.trimmingCharacters(in: .whitespaces).isEmpty {
                    EmptySearchState(query: query)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { i, deck in
                                SearchResultRow(deck: deck)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        searchFieldFocused = false
                                        if let idx = viewModel.decks.firstIndex(where: { $0.id == deck.id }) {
                                            viewModel.currentPaperIndex = idx
                                            viewModel.currentCardIndex  = 0
                                        }
                                        readerOpen = true
                                    }

                                if i < results.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $readerOpen) {
            DeckReaderView(viewModel: viewModel) {
                readerOpen = false
            }
        }
    }
}

// MARK: - Search Field

private struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))

            TextField("Search papers…", text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .tint(accentBlue)
                .focused(isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let deck: CardDeck

    private var title: String {
        deck.cards.first(where: { $0.type == .hook })?.text ?? deck.title ?? "Untitled Paper"
    }

    private var smartSummary: String {
        guard let eli5 = deck.cards.first(where: { $0.type == .eli5 }) else {
            return deck.cards.first(where: { $0.type == .takeaway })?.text?.prefix(100).description ?? ""
        }
        let raw = eli5.text ?? eli5.description ?? ""
        return String(raw.prefix(100))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !smartSummary.isEmpty {
                    Text(smartSummary + (smartSummary.count == 100 ? "…" : ""))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                }

                if let src = deck.source {
                    SourceBadge(source: src, color: accentBlue)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            SignalStrengthView(strength: deck.signalStrength)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(pageBg)
    }
}

// MARK: - Empty State

private struct EmptySearchState: View {
    let query: String

    var body: some View {
        Spacer()
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.2))
            Text("No papers found")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text("Nothing matched \"\(query)\".\nTry a different keyword.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        Spacer()
    }
}

// MARK: - Preview

#Preview {
    SearchView(viewModel: {
        let vm = FeedViewModel()
        vm.decks = [.preview]
        return vm
    }())
}
