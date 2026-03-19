import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var decks: [CardDeck] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var currentPaperIndex: Int = 0
    @Published var currentCardIndex: Int = 0

    private var currentPage: Int = 0
    private var hasMore: Bool = true
    private let api: APIService

    init(api: APIService = .shared) {
        self.api = api
    }

    // MARK: - Computed

    var currentDeck: CardDeck? {
        guard currentPaperIndex < decks.count else { return nil }
        return decks[currentPaperIndex]
    }

    var currentCard: Card? {
        guard let deck = currentDeck, currentCardIndex < deck.cards.count else { return nil }
        return deck.cards[currentCardIndex]
    }

    var previousCard: Card? {
        guard let deck = currentDeck, currentCardIndex > 0 else { return nil }
        return deck.cards[currentCardIndex - 1]
    }

    var nextCard: Card? {
        guard let deck = currentDeck, currentCardIndex < deck.cards.count - 1 else { return nil }
        return deck.cards[currentCardIndex + 1]
    }

    struct PaperCard { let card: Card; let deck: CardDeck }

    var nextPaperFirstCard: PaperCard? {
        guard currentPaperIndex + 1 < decks.count,
              let card = decks[currentPaperIndex + 1].cards.first else { return nil }
        return PaperCard(card: card, deck: decks[currentPaperIndex + 1])
    }

    var prevPaperFirstCard: PaperCard? {
        guard currentPaperIndex > 0,
              let card = decks[currentPaperIndex - 1].cards.first else { return nil }
        return PaperCard(card: card, deck: decks[currentPaperIndex - 1])
    }

    // MARK: - Navigation

    func advanceCard() {
        guard let deck = currentDeck else { return }
        if currentCardIndex < deck.cards.count - 1 {
            currentCardIndex += 1
        } else {
            advancePaper()
        }
    }

    func retreatCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
        }
    }

    func advancePaper() {
        guard currentPaperIndex < decks.count - 1 else { return }
        currentPaperIndex += 1
        currentCardIndex = 0
        if decks.count - currentPaperIndex <= 3 {
            Task { await loadMore() }
        }
    }

    func retreatPaper() {
        guard currentPaperIndex > 0 else { return }
        currentPaperIndex -= 1
        currentCardIndex = 0
    }

    // MARK: - Loading

    func loadFeed() async {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            decks = [.preview]
            return
        }
        #endif
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 0
        currentPaperIndex = 0
        currentCardIndex = 0
        do {
            decks = try await api.fetchFeed(page: 0)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        let next = currentPage + 1
        do {
            let fetched = try await api.fetchFeed(page: next)
            if fetched.isEmpty {
                hasMore = false
            } else {
                decks.append(contentsOf: fetched)
                currentPage = next
            }
        } catch {}
        isLoading = false
    }
}
