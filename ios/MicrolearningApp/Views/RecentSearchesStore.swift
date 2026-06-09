import Foundation
import SwiftUI

/// UserDefaults-backed log of recent search queries. Drives the "Recent
/// searches" suggestions shown when the search field is empty.
@MainActor
final class RecentSearchesStore: ObservableObject {
    static let shared = RecentSearchesStore()

    @Published private(set) var queries: [String] = []

    private let key = "recentSearches.v1"
    private let maxEntries = 8

    private init() {
        queries = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
    }

    /// Add query to the front. Trims whitespace, dedupes case-insensitive,
    /// caps to `maxEntries`. No-op for queries shorter than 2 chars so we
    /// don't pollute the list with single keystrokes during typing.
    func record(_ raw: String) {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return }
        var next = queries.filter { $0.compare(q, options: .caseInsensitive) != .orderedSame }
        next.insert(q, at: 0)
        if next.count > maxEntries { next = Array(next.prefix(maxEntries)) }
        queries = next
        UserDefaults.standard.set(queries, forKey: key)
    }

    func remove(_ q: String) {
        queries.removeAll { $0 == q }
        UserDefaults.standard.set(queries, forKey: key)
    }

    func clear() {
        queries = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}
