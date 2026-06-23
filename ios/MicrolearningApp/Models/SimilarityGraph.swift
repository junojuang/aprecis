import Foundation
import SwiftUI

// MARK: - SimilarityGraph
//
// Curated concept-overlap graph for P0 of the Explore "Neighborhoods"
// lens. Each curated paper gets a concept tag set; edges are derived
// from Jaccard similarity over those sets, with a small bonus when two
// papers share the same cluster. No backend required.
//
// The system intentionally produces relatively dense bridges between
// adjacent subfields so users encounter the "wait, this is connected?"
// moments described in the design brief.

enum SimilarityGraph {

    /// Stable cluster labels. Drives node color and the cluster-gravity
    /// term in the force simulation.
    enum Cluster: String, CaseIterable {
        case foundations, language, reasoning, vision, generative, opinion

        /// Extra tokens matched in Discover search (beyond `label` and `rawValue`).
        var searchSynonyms: [String] {
            switch self {
            case .foundations:
                return ["fundamentals", "history", "classic", "core", "basics"]
            case .language:
                return ["nlp", "llm", "transformers", "transformer", "gpt", "bert", "token", "embedding", "text"]
            case .reasoning:
                return ["thinking", "cot", "chain-of-thought", "chain of thought", "math", "logic", "agents", "planning"]
            case .vision:
                return ["cv", "cnn", "convnet", "images", "imagenet", "segmentation", "object detection"]
            case .generative:
                return ["diffusion", "gan", "vae", "synthetic", "image generation"]
            case .opinion:
                return ["essay", "perspective", "editorial", "critique", "commentary"]
            }
        }

        /// Lowercased haystack for substring search / scoring.
        var searchableBlob: String {
            let tokens = [label, rawValue.replacingOccurrences(of: "_", with: " ")] + searchSynonyms
            return tokens.joined(separator: " ").lowercased()
        }

        var color: Color {
            switch self {
            case .foundations: return Color(hex: "2a6d7a")
            case .language:    return tealAccent
            case .reasoning:   return Color(hex: "8a5a18")
            case .vision:      return Color(hex: "8a4ec2")
            case .generative:  return Color(hex: "c25a8a")
            case .opinion:     return Color(hex: "7a4040")
            }
        }

        var label: String {
            switch self {
            case .foundations: return "Foundations"
            case .language:    return "Language"
            case .reasoning:   return "Reasoning"
            case .vision:      return "Vision"
            case .generative:  return "Generative"
            case .opinion:     return "Opinion"
            }
        }

        /// Maps an arXiv primary category to a display cluster. Returns nil for
        /// categories with no clean mapping, so the caller can fall back to
        /// text inference. arXiv has no "reasoning"/"generative"/"opinion"
        /// category, so those clusters still come from inference.
        static func fromArxivCategory(_ raw: String) -> Cluster? {
            switch raw.lowercased() {
            case "cs.cl":
                return .language
            case "cs.cv", "eess.iv":
                return .vision
            case "cs.lg", "stat.ml", "cs.ne":
                return .foundations
            case "cs.ai":
                return .reasoning
            default:
                return nil
            }
        }
    }

    /// Curated paper metadata. Concept tags are deliberately overlapping
    /// across subfield boundaries so the resulting graph has bridges.
    struct PaperMeta {
        let id: String
        let cluster: Cluster
        let concepts: Set<String>
        let influence: Double   // log-scaled, drives node size
        let trending: Double    // 0..1, drives glow intensity
    }

    /// Hidden papers (see `CuratedPaperCatalog.hiddenPaperIds`) are removed
    /// so they cannot surface as graph nodes or related-paper picks.
    static var papers: [PaperMeta] {
        allPapers.filter { !CuratedPaperCatalog.hiddenPaperIds.contains($0.id) }
    }

    private static let allPapers: [PaperMeta] = [
        PaperMeta(id: "loop:foundational:perceptron",
                  cluster: .foundations,
                  concepts: ["neural network", "linear classifier", "threshold",
                             "supervised learning", "history"],
                  influence: 1.00, trending: 0.10),
        PaperMeta(id: "loop:foundational:backprop",
                  cluster: .foundations,
                  concepts: ["neural network", "gradient descent", "chain rule",
                             "supervised learning", "optimization"],
                  influence: 1.00, trending: 0.15),
        PaperMeta(id: "loop:foundational:lenet",
                  cluster: .vision,
                  concepts: ["convolutional", "neural network", "image",
                             "supervised learning", "feature hierarchy"],
                  influence: 0.85, trending: 0.10),
        PaperMeta(id: "loop:foundational:alexnet",
                  cluster: .vision,
                  concepts: ["convolutional", "image", "imagenet",
                             "feature hierarchy", "gpu", "depth"],
                  influence: 0.95, trending: 0.20),
        PaperMeta(id: "loop:foundational:resnet",
                  cluster: .vision,
                  concepts: ["convolutional", "image", "depth",
                             "residual", "skip connection", "optimization"],
                  influence: 0.95, trending: 0.30),
        PaperMeta(id: "loop:foundational:gans",
                  cluster: .generative,
                  concepts: ["generative", "adversarial", "image",
                             "neural network", "optimization", "minimax"],
                  influence: 0.90, trending: 0.40),
        PaperMeta(id: "loop:foundational:word2vec",
                  cluster: .language,
                  concepts: ["embedding", "language", "representation",
                             "neural network", "similarity"],
                  influence: 0.90, trending: 0.30),
        PaperMeta(id: "loop:foundational:seq2seq",
                  cluster: .language,
                  concepts: ["sequence", "encoder decoder", "language",
                             "translation", "embedding", "rnn"],
                  influence: 0.85, trending: 0.30),
        PaperMeta(id: "loop:foundational:attention",
                  cluster: .language,
                  concepts: ["attention", "transformer", "sequence",
                             "language", "encoder decoder", "scaling"],
                  influence: 1.00, trending: 0.85),
        PaperMeta(id: "loop:foundational:gpt3",
                  cluster: .language,
                  concepts: ["attention", "transformer", "language model",
                             "scaling", "few shot", "emergence"],
                  influence: 1.00, trending: 0.95),
        PaperMeta(id: "loop:foundational:bert",
                  cluster: .language,
                  concepts: ["attention", "transformer", "language model",
                             "masked language modelling", "encoder", "pretraining",
                             "fine tuning", "bidirectional"],
                  influence: 1.00, trending: 0.90),
        PaperMeta(id: "loop:foundational:instructgpt",
                  cluster: .language,
                  concepts: ["language model", "alignment", "reinforcement learning",
                             "human feedback", "reward model", "instruction following",
                             "fine tuning"],
                  influence: 1.00, trending: 0.92),
        PaperMeta(id: "loop:foundational:chain-of-thought",
                  cluster: .reasoning,
                  concepts: ["reasoning", "chain of thought", "prompting",
                             "few shot", "language model", "emergence", "in context learning"],
                  influence: 1.00, trending: 0.94),
        PaperMeta(id: "loop:foundational:scratchpad",
                  cluster: .reasoning,
                  concepts: ["reasoning", "scratchpad", "intermediate computation",
                             "algorithmic", "length generalisation", "code execution",
                             "language model"],
                  influence: 0.82, trending: 0.80),
        PaperMeta(id: "loop:foundational:self-consistency",
                  cluster: .reasoning,
                  concepts: ["reasoning", "chain of thought", "self consistency",
                             "sampling", "majority vote", "marginalisation",
                             "language model"],
                  influence: 0.92, trending: 0.88),
        PaperMeta(id: "loop:foundational:tot",
                  cluster: .reasoning,
                  concepts: ["reasoning", "tree of thoughts", "search", "planning",
                             "backtracking", "deliberation", "language model"],
                  influence: 0.94, trending: 0.90),
        PaperMeta(id: "loop:foundational:least-to-most",
                  cluster: .reasoning,
                  concepts: ["reasoning", "least to most", "decomposition",
                             "compositional generalisation", "prompting", "subproblems",
                             "language model"],
                  influence: 0.88, trending: 0.84),
        PaperMeta(id: "loop:foundational:react",
                  cluster: .reasoning,
                  concepts: ["reasoning", "react", "acting", "tool use",
                             "observation", "grounding", "agent", "language model"],
                  influence: 0.96, trending: 0.94),
        PaperMeta(id: "loop:foundational:toolformer",
                  cluster: .reasoning,
                  concepts: ["tool use", "toolformer", "api call", "self supervised",
                             "function calling", "fine tuning", "agent", "language model"],
                  influence: 0.94, trending: 0.92),
        PaperMeta(id: "loop:foundational:grokking",
                  cluster: .reasoning,
                  concepts: ["grokking", "generalisation", "overfitting", "memorisation",
                             "weight decay", "regularisation", "training dynamics", "interpretability"],
                  influence: 0.90, trending: 0.93),
        PaperMeta(id: "loop:foundational:deepseek-r1",
                  cluster: .reasoning,
                  concepts: ["reasoning", "chain of thought", "reinforcement learning",
                             "language model", "reward", "distillation", "emergence"],
                  influence: 1.00, trending: 1.00),
        PaperMeta(id: "loop:systems:flashattention",
                  cluster: .language,
                  concepts: ["attention", "transformer", "sequence", "scaling",
                             "gpu", "memory", "kernel", "softmax", "long context",
                             "systems"],
                  influence: 0.96, trending: 0.95),
    ]

    static let metaById: [String: PaperMeta] = Dictionary(uniqueKeysWithValues:
        papers.map { ($0.id, $0) })

    /// Maps `CardDeck.canonicalBraceKey` (e.g. `arxiv:2201.11903`) to the cluster
    /// of the curated loop that cites the same work, so merged API decks keep tags.
    private static let clusterByCanonicalBraceKey: [String: Cluster] = {
        var map: [String: Cluster] = [:]
        for entry in CuratedPaperCatalog.allPrepared {
            guard let meta = metaById[entry.paperId] else { continue }
            let stamped = entry.content.withPaperId(entry.paperId)
            let deck = CardDeck.fromLoop(paperId: entry.paperId, content: stamped)
            map[deck.canonicalBraceKey] = meta.cluster
        }
        return map
    }()

    /// Maps a canonical brace key to the curated loop id distilling the same
    /// work. Lets any backend `paper_id` for a curated paper resolve back to
    /// its loop id, so the Explore hub has one identity (and one set of rails)
    /// per paper regardless of which entry path opened it.
    static let loopIdByCanonicalBraceKey: [String: String] = {
        var map: [String: String] = [:]
        for entry in CuratedPaperCatalog.allPrepared {
            let stamped = entry.content.withPaperId(entry.paperId)
            let deck = CardDeck.fromLoop(paperId: entry.paperId, content: stamped)
            map[deck.canonicalBraceKey] = entry.paperId
        }
        return map
    }()

    /// Primary topic chip for **any** deck: curated ids, canonical URL matches, then text inference.
    static func cluster(for deck: CardDeck) -> Cluster {
        if let m = metaById[deck.paperId] { return m.cluster }
        let key = deck.canonicalBraceKey
        if let c = clusterByCanonicalBraceKey[key] { return c }
        // Backend arXiv category is authoritative for ingested papers; text
        // inference is only the fallback for categories with no clean mapping.
        if let cat = deck.arxivCategory, let c = Cluster.fromArxivCategory(cat) { return c }
        return inferredCluster(for: deck)
    }

    /// When only a paper id is known (rail cards, stubs), resolve deck from caches if possible.
    static func displayCluster(forPaperId id: String, deckHint: CardDeck?) -> Cluster {
        if let d = deckHint { return cluster(for: d) }
        if let m = metaById[id] { return m.cluster }
        if let loop = CuratedPaperCatalog.content(forPaperId: id) {
            return cluster(for: CardDeck.fromLoop(paperId: id, content: loop))
        }
        return .opinion
    }

    private static func inferredCluster(for deck: CardDeck) -> Cluster {
        let parts = [
            deck.title ?? "",
            deck.hook ?? "",
            deck.summary ?? "",
            deck.concepts.map(\.title).joined(separator: " "),
            deck.concepts.map(\.body).joined(separator: " "),
        ]
        let blob = parts.joined(separator: "\n").lowercased()

        let rules: [(Cluster, [String])] = [
            (.vision, [
                " vision", "computer vision", "cnn", "convnet", "convolutional",
                "imagenet", "segmentation", "object detection", "yolo",
                "resnet", " vit", "vit:", "pixels", "image ", "images ", "spatial",
                "depth estimation",
            ]),
            (.generative, [
                "gan", "generative adversarial", " diffusion", "diffusion ",
                "vae", " latent", "stable diffusion", "flow matching",
                "synthetic image",
            ]),
            (.language, [
                "language model", " transformers", " tokenizer", "llm",
                " bert ", " bert,", "gpt-", "gpt ", "nlp ", " natural language",
                "encoder-decoder", "seq2seq", "translation", " summarization",
                "attention mechanism", " self-attention", "positional encoding",
            ]),
            (.reasoning, [
                "chain-of-thought", "chain of thought", " reasoning", " scratchpad",
                "gsm8k", "multi-step", " arithmetic", " tool use", " planning",
                "agent", "emergent",
            ]),
            (.foundations, [
                "perceptron", "backprop", "back propagation", "gradient descent",
                " adam ", " sgd ", "optimizer", "lenet",
                "neural network", "loss ", "epochs",
            ]),
            (.opinion, [
                " homogenization", "creativity", " editorial", " essay",
                "perspective ", "critique ", "philosoph", " societal",
                "side effect",
            ]),
        ]

        var best: Cluster = .opinion
        var bestHits = 0
        for (cluster, terms) in rules {
            let hits = terms.reduce(0) { partial, phrase in partial + (blob.contains(phrase) ? 1 : 0) }
            if hits > bestHits {
                bestHits = hits
                best = cluster
            }
        }
        return best
    }

    static func cluster(of id: String) -> Cluster {
        metaById[id]?.cluster ?? .opinion
    }

    static func concepts(of id: String) -> Set<String> {
        metaById[id]?.concepts ?? []
    }

    // MARK: edges

    struct Edge: Hashable {
        let a: String
        let b: String
        let weight: Double
    }

    /// All edges above the visibility threshold, deduped (a < b).
    static let edges: [Edge] = {
        var out: [Edge] = []
        let ids = papers.map(\.id).sorted()
        for i in 0..<ids.count {
            for j in (i+1)..<ids.count {
                let w = weight(ids[i], ids[j])
                if w >= 0.18 {
                    out.append(Edge(a: ids[i], b: ids[j], weight: w))
                }
            }
        }
        return out
    }()

    /// Concept-Jaccard with a small same-cluster boost. Range ≈ 0...1.
    static func weight(_ a: String, _ b: String) -> Double {
        guard a != b,
              let ma = metaById[a], let mb = metaById[b] else { return 0 }
        let inter = ma.concepts.intersection(mb.concepts).count
        let union = ma.concepts.union(mb.concepts).count
        guard union > 0 else { return 0 }
        let jaccard = Double(inter) / Double(union)
        let clusterBoost = (ma.cluster == mb.cluster) ? 0.08 : 0
        return min(1.0, jaccard + clusterBoost)
    }

    /// Top-k neighbors of a node by edge weight, descending.
    static func neighbors(of id: String, k: Int = 5) -> [(id: String, weight: Double)] {
        papers.compactMap { other -> (String, Double)? in
            guard other.id != id else { return nil }
            let w = weight(id, other.id)
            return w > 0 ? (other.id, w) : nil
        }
        .sorted { $0.1 > $1.1 }
        .prefix(k)
        .map { ($0.0, $0.1) }
    }

    /// Recommendation slate used by the focus card:
    ///   2 most-similar  + 1 surprise (high w, distant cluster)
    ///   + 1 foundational (high influence + foundational cluster)
    ///   + 1 emerging (high trending, not already chosen)
    /// All distinct, never includes the seed.
    static func slate(for seed: String) -> [(id: String, kind: SlateKind)] {
        let seedMeta = metaById[seed]
        var chosen: Set<String> = [seed]
        var out: [(String, SlateKind)] = []

        // 2 most similar
        for (id, _) in neighbors(of: seed, k: 8) where chosen.count < 3 {
            if !chosen.contains(id) {
                out.append((id, .similar))
                chosen.insert(id)
            }
        }

        // 1 surprise: high weight AND distant cluster
        let surprise = papers
            .filter { !chosen.contains($0.id)
                      && $0.cluster != seedMeta?.cluster }
            .map { ($0.id, weight(seed, $0.id)) }
            .sorted { $0.1 > $1.1 }
            .first
        if let surprise, surprise.1 > 0.10 {
            out.append((surprise.0, .surprise))
            chosen.insert(surprise.0)
        }

        // 1 foundational
        let foundational = papers
            .filter { !chosen.contains($0.id) && $0.cluster == .foundations }
            .sorted { $0.influence > $1.influence }
            .first
        if let foundational {
            out.append((foundational.id, .foundational))
            chosen.insert(foundational.id)
        }

        // 1 emerging
        let emerging = papers
            .filter { !chosen.contains($0.id) }
            .sorted { $0.trending > $1.trending }
            .first
        if let emerging {
            out.append((emerging.id, .emerging))
            chosen.insert(emerging.id)
        }

        return out
    }

    // MARK: curated paths
    //
    // Hand-picked learning trails surfaced on the browse landing. Each
    // path is a short ordered sequence of paper ids that tells a story.

    struct Path: Identifiable {
        let id: String
        let title: String
        let blurb: String
        let stops: [String]
    }

    static let paths: [Path] = [
        Path(id: "road-to-gpt3",
             title: "The road to GPT-3",
             blurb: "Six papers from one neuron to a 175B-parameter generalist",
             stops: [
                "loop:foundational:perceptron",
                "loop:foundational:backprop",
                "loop:foundational:word2vec",
                "loop:foundational:seq2seq",
                "loop:foundational:attention",
                "loop:foundational:gpt3",
             ]),
        Path(id: "vision-arc",
             title: "How machines learned to see",
             blurb: "From handwritten digits to ImageNet to deep residuals",
             stops: [
                "loop:foundational:perceptron",
                "loop:foundational:lenet",
                "loop:foundational:alexnet",
                "loop:foundational:resnet",
             ]),
        Path(id: "transformers-to-llms",
             title: "Transformers to few-shot giants",
             blurb: "Self-attention and the first 175B-parameter few-shot learner",
             stops: [
                "loop:foundational:attention",
                "loop:foundational:gpt3",
             ]),
    ]

    enum SlateKind {
        case similar, surprise, foundational, emerging
        var label: String {
            switch self {
            case .similar:      return "RELATED"
            case .surprise:     return "SURPRISE"
            case .foundational: return "ROOT"
            case .emerging:     return "EMERGING"
            }
        }
        var color: Color {
            switch self {
            case .similar:      return tealAccent
            case .surprise:     return Color(hex: "8a4ec2")
            case .foundational: return amberAccent
            case .emerging:     return Color(hex: "c25a8a")
            }
        }
    }
}

extension CardDeck {
    /// Same topic taxonomy as Discover search (foundations … opinion).
    var topicCluster: SimilarityGraph.Cluster {
        SimilarityGraph.cluster(for: self)
    }

    var topicTagUppercased: String {
        topicCluster.label.uppercased()
    }
}
