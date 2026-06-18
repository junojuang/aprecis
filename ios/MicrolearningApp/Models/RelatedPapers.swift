import Foundation

// MARK: - RelatedPapers
//
// Unified neighbor lookup for the Explore focus view. Wraps the
// curated PrerequisiteMap (for lineage) and SimilarityGraph (for
// adjacency + surprise) behind one API so the UI never has to think
// about where a relationship came from. Designed so a future backend
// can swap in real embeddings without touching the view layer.

enum RelatedPapers {

    struct Bundle {
        let buildsOn: [String]   // strict prerequisites
        let ledTo: [String]      // papers that have this one as prereq
        let adjacent: [String]   // similar papers (same field)
        let surprise: String?    // high similarity, distant field

        static let empty = Bundle(buildsOn: [], ledTo: [], adjacent: [], surprise: nil)
    }

    // MARK: - Curated ↔ backend identity map
    //
    // The 11 curated canon papers ship client-side under `loop:` ids, but in
    // the backend graph corpus they live under their real paper_id (arXiv id,
    // or a stable pre-arXiv id). This explicit map bridges the two. It must
    // stay in sync with backend/scripts/seed-curated-papers.ts.

    private static let curatedLoopToBackend: [String: String] = [
        "loop:foundational:perceptron": "rosenblatt:1958",
        "loop:foundational:backprop":   "rumelhart:1986",
        "loop:foundational:lenet":      "lecun:1998",
        "loop:foundational:alexnet":    "krizhevsky:2012",
        "loop:foundational:word2vec":   "arxiv:1301.3781",
        "loop:foundational:seq2seq":    "arxiv:1409.3215",
        "loop:foundational:gans":       "arxiv:1406.2661",
        "loop:foundational:resnet":     "arxiv:1512.03385",
        "loop:foundational:attention":  "arxiv:1706.03762",
        "loop:foundational:gpt3":       "arxiv:2005.14165",
        "loop:foundational:bert":       "arxiv:1810.04805",
    ]

    private static let curatedBackendToLoop: [String: String] =
        Dictionary(uniqueKeysWithValues: curatedLoopToBackend.map { ($1, $0) })

    /// Backend `paper_id` to query the graph with. Curated `loop:` ids map to
    /// their corpus id; everything else is already a backend id.
    private static func backendId(for id: String) -> String {
        curatedLoopToBackend[id] ?? id
    }

    /// Canonical backend `paper_id` for a curated `loop:` id, or `nil` if `id`
    /// is not one of the 11 canon papers. `BraceIdentity` uses this so a loop
    /// deck and its backend deck (e.g. `loop:foundational:attention` and
    /// `arxiv:1706.03762`) collapse to a single brace instead of showing twice.
    static func canonicalBackendId(forLoopId id: String) -> String? {
        curatedLoopToBackend[id]
    }

    // MARK: - Canonical identity (one source of truth)
    //
    // A paper can arrive under several ids: a backend `paper_id` or a curated
    // `loop:` id. The Explore hub must key on ONE id per paper, or the same
    // paper shows different rails depending on the entry path. `preferredId`
    // collapses any alias to the curated `loop:` id when the paper is in the
    // curated canon (so its client-side hub content resolves); otherwise it
    // returns the id unchanged.

    static func preferredId(for id: String, deck: CardDeck? = nil) -> String {
        if let loop = curatedBackendToLoop[id] { return loop }
        let key = BraceIdentity.canonicalKey(paperId: id, url: deck?.url, title: deck?.title)
        return SimilarityGraph.loopIdByCanonicalBraceKey[key] ?? id
    }

    // MARK: - Backend-backed bundle (async)
    //
    // Every rail — Builds on, Led to, Adjacent — comes from the backend paper
    // graph: citation edges (Semantic Scholar) and pgvector embedding
    // neighbors. ONE scoring system for every paper, curated canon included.
    // No hand-written PrerequisiteMap / SimilarityGraph rails.

    /// Per-paper in-memory cache. MainActor-isolated; Explore loads on the main
    /// actor, so no extra synchronization is needed.
    @MainActor private static var cache: [String: Bundle] = [:]

    /// Backend rails for `id`. Returns `.empty` if the graph call fails (e.g.
    /// the paper has no embedding yet). Rail ids are normalized to canonical
    /// ids so curated papers in a rail resolve to their client-side hub.
    @MainActor
    static func bundle(for id: String, focusedDeck: CardDeck? = nil) async -> Bundle {
        if let hit = cache[id] { return hit }

        let response: APIService.RelatedResponse
        do {
            response = try await APIService.shared.fetchRelated(paperId: backendId(for: id))
        } catch {
            return .empty // do not cache a failure
        }

        // Hidden papers must not surface in any rail (Builds on, Led to,
        // Adjacent, Surprise) even though the backend graph still returns
        // their edges.
        let visible: (String) -> Bool = { !HiddenPapers.isHidden(paperId: $0, title: nil) }
        let bundle = Bundle(
            buildsOn: Array(response.buildsOn.map { preferredId(for: $0) }.filter(visible).prefix(12)),
            ledTo:    Array(response.ledTo.map { preferredId(for: $0) }.filter(visible).prefix(12)),
            adjacent: Array(response.adjacent.map { preferredId(for: $0) }.filter(visible).prefix(8)),
            surprise: response.surprise.map { preferredId(for: $0) }.flatMap { visible($0) ? $0 : nil }
        )
        cache[id] = bundle
        return bundle
    }

    /// Recommended starter paper when the user opens Explore cold.
    static var starter: String { "loop:foundational:gpt3" }

    /// Lightweight feed used by browse entry chips.
    enum Entry: String, CaseIterable, Identifiable {
        case foundational, trending, frontier, random
        var id: String { rawValue }
        var label: String {
            switch self {
            case .foundational: return "Start at the beginning"
            case .trending:     return "What everyone's reading"
            case .frontier:     return "Edge of research"
            case .random:       return "Surprise me"
            }
        }
        var blurb: String {
            switch self {
            case .foundational: return "The neuron that started it all"
            case .trending:     return "Highest read velocity this week"
            case .frontier:     return "Recent and weird"
            case .random:       return "Pick something at random"
            }
        }
        var icon: String {
            switch self {
            case .foundational: return "circle.dotted"
            case .trending:     return "flame"
            case .frontier:     return "sparkles"
            case .random:       return "die.face.5"
            }
        }
        func seedId() -> String {
            switch self {
            case .foundational:
                return "loop:foundational:perceptron"
            case .trending:
                return SimilarityGraph.papers
                    .max(by: { $0.trending < $1.trending })?.id
                    ?? RelatedPapers.starter
            case .frontier:
                return "loop:foundational:gpt3"
            case .random:
                return SimilarityGraph.papers.randomElement()?.id
                    ?? RelatedPapers.starter
            }
        }
    }
}
