import Foundation

// MARK: - Enums

enum CardType: String, Codable, CaseIterable {
    case hook
    case eli5
    case analogy
    case visual
    case takeaway
    case coreIdea = "core_idea"
}

enum VisualType: String, Codable {
    case flow
    case diagram
    case comparison
}

// MARK: - Paper

struct Paper: Codable, Identifiable {
    var id: String { paperId }
    let paperId: String
    let title: String
    let authors: [String]
    let abstract: String
    let source: String
    let url: String
    let publishedAt: Date
    let score: Double

    enum CodingKeys: String, CodingKey {
        case paperId     = "paper_id"
        case title
        case authors
        case abstract
        case source
        case url
        case publishedAt = "published_at"
        case score
    }
}

// MARK: - Card

struct Card: Codable, Identifiable {
    var id: String { "\(type.rawValue)-\(text?.prefix(16) ?? description?.prefix(16) ?? "?")" }
    let type: CardType
    let text: String?
    let description: String?
    let visual: VisualSchema?

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case description
        case visual
    }
}

// MARK: - CardDeck

struct CardDeck: Codable, Identifiable {
    var id: String { paperId }
    let paperId: String
    let title: String?
    let source: String?
    let cards: [Card]
    let score: Double?
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case paperId     = "paper_id"
        case title
        case source
        case cards
        case score
        case publishedAt = "published_at"
    }

    // MARK: - Signal Strength (1–5)

    /// Maps the 0–1 paper score to a 1–5 bar count.
    var signalStrength: Int {
        guard let s = score else { return 3 }
        switch s {
        case ..<0.2: return 1
        case ..<0.4: return 2
        case ..<0.6: return 3
        case ..<0.8: return 4
        default:     return 5
        }
    }

    /// True when the paper is high-relevance OR published within the last 48 hours.
    var isHighSignal: Bool {
        let highScore = (score ?? 0) >= 0.65
        let recentCutoff = Date().addingTimeInterval(-48 * 60 * 60)
        let recentlyPublished = publishedAt.map { $0 >= recentCutoff } ?? false
        return highScore || recentlyPublished
    }
}

// MARK: - Visual DSL

struct VisualNode: Codable, Identifiable {
    let id: String
    let label: String
}

struct VisualEdge: Codable {
    let from: String
    let to: String
}

struct VisualSchema: Codable {
    let type: VisualType
    let nodes: [VisualNode]
    let edges: [VisualEdge]
}

// MARK: - Preview Data

extension CardDeck {
    static let preview = CardDeck(
        paperId: "preview-001",
        title: "Attention Is All You Need",
        source: "arxiv",
        cards: [
            Card(type: .hook,
                 text: "Every AI you use today — ChatGPT, Claude, Gemini — exists because of one paper written in 2017.",
                 description: nil, visual: nil),
            Card(type: .coreIdea,
                 text: "1. Old AI read one word at a time and forgot the start of long sentences\n2. The fix: let every word look at every other word simultaneously\n3. They called this mechanism Attention — and made it the only thing the model does",
                 description: nil, visual: nil),
            Card(type: .eli5,
                 text: "Before this, translation AI needed a complicated memory system plus an attention system bolted on. These researchers threw out the memory entirely. Just attention. It worked better.",
                 description: nil, visual: nil),
            Card(type: .analogy,
                 text: "Scanning the whole room at once instead of staring at one corner with a flashlight. That's what Attention lets a model do with language.",
                 description: nil, visual: nil),
            Card(type: .visual, text: nil,
                 description: "How Attention connects every word to every other word in a sentence",
                 visual: VisualSchema(
                    type: .flow,
                    nodes: [
                        VisualNode(id: "a", label: "Input"),
                        VisualNode(id: "b", label: "Attention"),
                        VisualNode(id: "c", label: "Encode"),
                        VisualNode(id: "d", label: "Output"),
                    ],
                    edges: [
                        VisualEdge(from: "a", to: "b"),
                        VisualEdge(from: "b", to: "c"),
                        VisualEdge(from: "c", to: "d"),
                    ]
                 )),
            Card(type: .takeaway,
                 text: "Beat every translation model on the planet. Trained in 3.5 days on 8 GPUs. The same architecture, essentially unchanged, now powers code generation, image recognition, drug discovery, and every chatbot you've ever used.",
                 description: nil, visual: nil),
        ],
        score: 0.87,
        publishedAt: Date().addingTimeInterval(-24 * 60 * 60)
    )
}
