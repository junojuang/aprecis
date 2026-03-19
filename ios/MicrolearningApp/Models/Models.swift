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
        case paperId = "paper_id"
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

    enum CodingKeys: String, CodingKey {
        case paperId = "paper_id"
        case title
        case source
        case cards
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
        title: "New model learns to reason by simulating future outcomes",
        source: "arxiv",
        cards: [
            Card(type: .hook,     text: "New model learns to reason by simulating future outcomes", description: nil, visual: nil),
            Card(type: .coreIdea, text: "1. Plans ahead before answering\n2. Scores candidate paths\n3. Picks highest-value route", description: nil, visual: nil),
            Card(type: .eli5,     text: "Like a chess player who imagines five moves ahead before touching a piece, instead of grabbing the first one that looks good.", description: nil, visual: nil),
            Card(type: .analogy,  text: "It's a GPS that simulates three possible routes and picks the fastest before you even pull out of the driveway.", description: nil, visual: nil),
            Card(type: .visual,   text: nil, description: "How the model evaluates candidate reasoning paths",
                 visual: VisualSchema(
                    type: .flow,
                    nodes: [
                        VisualNode(id: "a", label: "Question"),
                        VisualNode(id: "b", label: "Draft paths"),
                        VisualNode(id: "c", label: "Score each"),
                        VisualNode(id: "d", label: "Best answer"),
                    ],
                    edges: [
                        VisualEdge(from: "a", to: "b"),
                        VisualEdge(from: "b", to: "c"),
                        VisualEdge(from: "c", to: "d"),
                    ]
                 )),
            Card(type: .takeaway, text: "Reasoning models that plan ahead cut errors by 40% on multi-step tasks — a step toward reliable AI agents.", description: nil, visual: nil),
        ]
    )
}
