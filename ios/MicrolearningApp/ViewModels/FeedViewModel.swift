import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var decks: [CardDeck] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private var currentPage: Int = 0
    private var hasMore: Bool = true
    private let api: APIService

    init(api: APIService = .shared) {
        self.api = api
    }

    // MARK: - Loading

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 0
        // Load the server-driven web-lesson map alongside the feed so any paper
        // (including curated loops) can resolve its bundle before it's opened.
        Task { await WebLessonRegistry.refreshFromServer() }
        do {
            let page = try await api.fetchFeed(page: 0)
            decks = page.decks.mergingCanonicalBraceDuplicates()
                .filter { !HiddenPapers.isHidden($0) }
            hasMore = page.has_more
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
            let page = try await api.fetchFeed(page: next)
            if page.decks.isEmpty {
                hasMore = false
            } else {
                decks.append(contentsOf: page.decks)
                decks = decks.mergingCanonicalBraceDuplicates()
                    .filter { !HiddenPapers.isHidden($0) }
                currentPage = next
                hasMore = page.has_more
            }
        } catch {
            self.error = error.localizedDescription
            hasMore = false
        }
        isLoading = false
    }

    private var didLoadAll = false
    private static let maxPagesForLoadAll = 20

    func loadAll() async {
        guard !didLoadAll else { return }
        if decks.isEmpty { await loadFeed() }
        var pages = 0
        while hasMore && pages < Self.maxPagesForLoadAll {
            let before = decks.count
            await loadMore()
            if decks.count == before { break }
            pages += 1
        }
        didLoadAll = true
    }
}
