import Foundation

// MARK: - HiddenPapers
//
// Papers kept fully in the codebase, loop content, lessons, graph entries
// all intact, but suppressed from every surface of the app. This is hiding,
// not deleting. Reversible: empty the collections below to bring a paper
// back.
//
// Two kinds of hidden paper:
//  - Curated `loop:` ids, filtered from the catalog, subway map, and
//    similarity graph (see `CuratedPaperCatalog.hiddenPaperIds`).
//  - Backend-ingested papers, matched by id or title substring and
//    filtered out of the feed (see `FeedViewModel`).

enum HiddenPapers {

    /// Curated `loop:` ids hidden everywhere they would otherwise appear.
    static let hiddenLoopIds: Set<String> = []

    /// Lowercased substrings that mark a backend-ingested paper as hidden.
    /// Matched against the deck's paper id and title. Include an arXiv id
    /// where known, so the paper is also filtered from graph rails (which
    /// carry ids only, no titles).
    static let hiddenPatterns: [String] = [
        "2201.11903",          // Chain-of-Thought Prompting (Wei et al.)
        "chain-of-thought",
        "chain of thought",
        "2401.06816",          // Generative AI and the Lasting Homogenization
        "homogenization of human creative writing",
        "1706.03762",          // Attention Is All You Need (backend dup; curated loop kept)
    ]

    static func isHidden(paperId: String, title: String?) -> Bool {
        if hiddenLoopIds.contains(paperId) { return true }
        let hay = "\(paperId) \(title ?? "")".lowercased()
        return hiddenPatterns.contains { hay.contains($0) }
    }

    static func isHidden(_ deck: CardDeck) -> Bool {
        isHidden(paperId: deck.paperId, title: deck.title)
    }
}
