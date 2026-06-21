import SwiftUI

// MARK: - AddPaperView

struct AddPaperView: View {
    @ObservedObject var viewModel: FeedViewModel

    @State private var urlText = ""
    @State private var isProcessing = false
    @State private var processingStep = 0
    @State private var errorMessage: String? = nil
    @State private var showArxivSearch = false
    @State private var addedDeck: CardDeck? = nil
    @State private var navigateToDeck = false

    /// Paper IDs the user personally distilled, stored locally
    @AppStorage("userDistilledIds") private var distilledIdsRaw: String = ""

    private var distilledIds: [String] {
        distilledIdsRaw.split(separator: ",").map(String.init)
    }

    private var recentlyDistilled: [CardDeck] {
        let ids = Set(distilledIds)
        return viewModel.decks.filter { ids.contains($0.id) }
    }

    private let processingSteps = [
        "Fetching paper",
        "Extracting key concepts",
        "Generating diagrams",
        "Writing Aprecis summary",
        "Packaging concepts"
    ]

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
                .navigationDestination(isPresented: $navigateToDeck) {
                    if let deck = addedDeck {
                        DeckDestination(deck: deck)
                    }
                }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    SectionLabel("Paste arXiv URL or ID")
                    urlInputRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    if let err = errorMessage {
                        Text(err)
                            .scaledFont(size: 12)
                            .foregroundStyle(Color.red.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }

                    if isProcessing {
                        processingCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    }


                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Add Paper")
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundStyle(inkColor)
            }
        }
        .sheet(isPresented: $showArxivSearch) {
            ArxivSearchSheet { arxivId in
                showArxivSearch = false
                Task { await distil(arxivId: arxivId) }
            }
        }
    }

    // MARK: - URL Input Row

    private var urlInputRow: some View {
        HStack(spacing: 10) {
            Text("🔗")
                .scaledFont(size: 16)
            TextField("arxiv.org/abs/... or 2301.07041", text: $urlText)
                .font(.system(size: 12).monospaced())
                .foregroundStyle(inkColor)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { submitURL() }
            Button("Distil") { submitURL() }
                .scaledFont(size: 12, weight: .semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(urlText.trimmingCharacters(in: .whitespaces).isEmpty ? tealAccent.opacity(0.4) : tealAccent)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(tealAccent, lineWidth: 2)
                )
                .shadow(color: tealAccent.opacity(0.12), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Processing Card

    private var processingCard: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: tealAccent))
                .scaleEffect(1.3)
                .padding(.top, 8)

            Text("Distilling paper...")
                .scaledFont(size: 15, weight: .semibold)
                .foregroundStyle(inkColor)

            Text("AI is reading, understanding, and creating visual concepts for you.")
                .scaledFont(size: 12)
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(processingSteps.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Group {
                            if i < processingStep {
                                Image(systemName: "checkmark")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundStyle(tealAccent)
                            } else if i == processingStep {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: amberAccent))
                                    .scaleEffect(0.7)
                            } else {
                                Circle()
                                    .stroke(mutedText.opacity(0.3), lineWidth: 1)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .frame(width: 16, alignment: .center)
                        Text(processingSteps[i])
                            .scaledFont(size: 12)
                            .foregroundStyle(i < processingStep ? tealAccent : (i == processingStep ? inkColor : mutedText))
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func submitURL() {
        let trimmed = urlText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let arxivPattern = #"(\d{4}\.\d{4,5}(?:v\d+)?)"#
        if let match = trimmed.range(of: arxivPattern, options: .regularExpression) {
            let arxivId = String(trimmed[match]).replacingOccurrences(of: #"v\d+$"#, with: "",
                                                                       options: .regularExpression)
            Task { await distil(arxivId: arxivId) }
        } else {
            errorMessage = "Couldn't find an arXiv ID in that URL. Try pasting directly from arxiv.org/abs/…"
        }
    }

    @MainActor
    private func distil(arxivId: String) async {
        guard !isProcessing else { return }
        errorMessage = nil
        isProcessing = true
        processingStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
            if processingStep < processingSteps.count - 1 {
                processingStep += 1
            }
        }

        do {
            let deck = try await APIService.shared.addPaper(arxivId: arxivId)
            timer.invalidate()
            processingStep = processingSteps.count
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Prepend to feed; merge duplicate braces (same arXiv) instead of stacking two rows.
            if let dupIdx = viewModel.decks.firstIndex(where: {
                $0.canonicalBraceKey == deck.canonicalBraceKey || $0.paperId == deck.paperId
            }) {
                let merged = BraceIdentity.preferredDuplicate(viewModel.decks[dupIdx], deck)
                viewModel.decks.remove(at: dupIdx)
                viewModel.decks.insert(merged, at: 0)
            } else {
                viewModel.decks.insert(deck, at: 0)
            }
            distilledIdsRaw = (distilledIdsRaw.isEmpty ? "" : distilledIdsRaw + ",") + deck.id
            addedDeck = deck
            isProcessing = false
            urlText = ""
            navigateToDeck = true
        } catch {
            timer.invalidate()
            isProcessing = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ArxivSearchSheet

struct ArxivSearchSheet: View {
    let onSelect: (String) -> Void

    @State private var query = ""
    @State private var results: [APIService.ArxivPaper] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                paperBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(mutedText)
                            .scaledFont(size: 14)
                        TextField("Search arXiv by title or topic", text: $query)
                            .scaledFont(size: 14)
                            .foregroundStyle(inkColor)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onSubmit { Task { await search() } }
                        if isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: tealAccent))
                                .scaleEffect(0.8)
                        } else if !query.isEmpty {
                            Button(action: { query = ""; results = [] }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(mutedText)
                                    .scaledFont(size: 14)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(query.isEmpty ? borderColor : tealAccent, lineWidth: query.isEmpty ? 1 : 2)
                    )
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)

                    if let err = searchError {
                        Text(err)
                            .scaledFont(size: 12)
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }

                    if results.isEmpty && !isSearching {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(results) { paper in
                                    ArxivResultRow(paper: paper) {
                                        onSelect(paper.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(tealAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") { Task { await search() } }
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundStyle(query.isEmpty ? mutedText : tealAccent)
                        .disabled(query.isEmpty)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .scaledFont(size: 40)
                .foregroundStyle(tealLight)
            Text(query.isEmpty ? "Search arXiv" : "No results found")
                .scaledFont(size: 16, weight: .semibold, design: .serif)
                .foregroundStyle(inkColor)
            Text(query.isEmpty
                 ? "Type a paper title, author, or topic"
                 : "Try different keywords")
                .scaledFont(size: 13)
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    @MainActor
    private func search() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isSearching = true
        searchError = nil
        do {
            results = try await APIService.shared.searchArxiv(query: q)
        } catch {
            searchError = "Search failed: \(error.localizedDescription)"
        }
        isSearching = false
    }
}

// MARK: - ArxivResultRow

private struct ArxivResultRow: View {
    let paper: APIService.ArxivPaper
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(paper.title)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundStyle(inkColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !paper.authors.isEmpty {
                    Text(paper.authors.joined(separator: ", "))
                        .font(.system(size: 11).monospaced())
                        .foregroundStyle(mutedText)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text("arXiv")
                        .scaledFont(size: 10, weight: .semibold)
                        .foregroundStyle(tealAccent)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(tealLight)
                        .clipShape(Capsule())
                    Text(paper.id)
                        .font(.system(size: 10).monospaced())
                        .foregroundStyle(mutedText)
                    Spacer()
                    Text(dateLabel)
                        .scaledFont(size: 10)
                        .foregroundStyle(mutedText)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(cardBg)
            .overlay(alignment: .bottom) {
                Rectangle().fill(borderColor).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: paper.published)
    }
}
