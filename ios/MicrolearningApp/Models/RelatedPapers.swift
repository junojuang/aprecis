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
        "perceptron": "perceptron",
        "backprop":   "backprop",
        "lenet":      "lenet",
        "alexnet":    "alexnet",
        "word2vec":   "arxiv:1301.3781",
        "seq2seq":    "arxiv:1409.3215",
        "gans":       "arxiv:1406.2661",
        "resnet":     "arxiv:1512.03385",
        "attention":  "arxiv:1706.03762",
        "gpt3":       "arxiv:2005.14165",
        "bert":       "arxiv:1810.04805",
        "instructgpt": "arxiv:2203.02155",
        "chain-of-thought": "arxiv:2201.11903",
        "scratchpad": "arxiv:2112.00114",
        "self-consistency": "arxiv:2203.11171",
        "tree-of-thoughts": "arxiv:2305.10601",
        "least-to-most": "arxiv:2205.10625",
        "react": "arxiv:2210.03629",
        "toolformer": "arxiv:2302.04761",
        "grokking": "arxiv:2201.02177",
        "deepseek-r1": "arxiv:2501.12948",
        "vit": "arxiv:2010.11929",
        "ddpm": "arxiv:2006.11239",
        "clip": "arxiv:2103.00020",
        "stable-diffusion": "arxiv:2112.10752",
        "controlnet": "arxiv:2302.05543",
        "sam": "arxiv:2304.02643",
        "t5": "arxiv:1910.10683",
        "chinchilla": "arxiv:2203.15556",
        "palm": "arxiv:2204.02311",
        "llama": "arxiv:2302.13971",
        "mixtral": "arxiv:2401.04088",
        "reflexion": "arxiv:2303.11366",
        "flashattention": "arxiv:2205.14135",
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
    /// deck and its backend deck (e.g. `attention` and
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

        let response: APIService.RelatedResponse?
        do {
            response = try await APIService.shared.fetchRelated(paperId: backendId(for: id))
        } catch {
            response = nil // backend unreachable / paper not in graph yet
        }

        // Hidden papers must not surface in any rail (Builds on, Led to,
        // Adjacent, Surprise) even though the backend graph still returns
        // their edges.
        let visible: (String) -> Bool = { !HiddenPapers.isHidden(paperId: $0, title: nil) }

        var bundle = Bundle.empty
        if let response {
            bundle = Bundle(
                buildsOn: Array(response.buildsOn.map { preferredId(for: $0) }.filter(visible).prefix(12)),
                ledTo:    Array(response.ledTo.map { preferredId(for: $0) }.filter(visible).prefix(12)),
                adjacent: Array(response.adjacent.map { preferredId(for: $0) }.filter(visible).prefix(3)),
                surprise: response.surprise.map { preferredId(for: $0) }.flatMap { visible($0) ? $0 : nil }
            )
        }

        // Graceful degradation: when the backend graph has nothing for this
        // paper (call failed, or the paper is not yet seeded into the corpus —
        // e.g. a freshly added curated lesson), fall back to the curated
        // client-side maps so the Explore hub still links to related papers.
        // Papers that ARE in the backend graph keep using its scoring; this
        // only fills the gap for ones it doesn't know about.
        if bundle.buildsOn.isEmpty, bundle.ledTo.isEmpty, bundle.adjacent.isEmpty {
            if let fallback = curatedFallback(for: id, visible: visible) {
                bundle = fallback
            } else if response == nil {
                return .empty // nothing to show and nothing to cache
            }
        }

        cache[id] = bundle
        return bundle
    }

    /// Rails derived from the hand-curated `PrerequisiteMap` (lineage) and
    /// `SimilarityGraph` (concept adjacency). Returns `nil` when the paper is
    /// not part of the curated canon, so non-curated papers don't get faked
    /// rails. Ids are already curated `loop:` ids.
    @MainActor
    private static func curatedFallback(for id: String, visible: (String) -> Bool) -> Bundle? {
        let loopId = preferredId(for: id)
        let inPrereq = PrerequisiteMap.nodes.contains(loopId)
        let inSimilarity = SimilarityGraph.metaById[loopId] != nil
        guard inPrereq || inSimilarity else { return nil }

        let buildsOn = PrerequisiteMap.parents(of: loopId).filter(visible)
        let ledTo = PrerequisiteMap.prereqs
            .filter { $0.value.contains(loopId) }
            .map(\.key)
            .filter(visible)
            .sorted()

        let exclude = Set(buildsOn + ledTo + [loopId])
        let adjacent = SimilarityGraph.neighbors(of: loopId, k: 8)
            .map(\.id)
            .filter { !exclude.contains($0) && visible($0) }

        guard !buildsOn.isEmpty || !ledTo.isEmpty || !adjacent.isEmpty else { return nil }
        return Bundle(buildsOn: buildsOn, ledTo: ledTo,
                      adjacent: Array(adjacent.prefix(3)), surprise: nil)
    }

    /// Recommended starter paper when the user opens Explore cold.
    static var starter: String { "gpt3" }

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
                return "perceptron"
            case .trending:
                return SimilarityGraph.papers
                    .max(by: { $0.trending < $1.trending })?.id
                    ?? RelatedPapers.starter
            case .frontier:
                return "gpt3"
            case .random:
                return SimilarityGraph.papers.randomElement()?.id
                    ?? RelatedPapers.starter
            }
        }
    }
}
