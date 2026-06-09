import Foundation

// Editorial blueprint produced by the backend pipeline. Mirrors the shape in
// `backend/src/types.ts`. iOS decodes it from the cards.blueprint JSONB column
// served by /serve-cards. Rendered by DailyLoopView via
// DailyLoopContent.init(deck:blueprint:) which lives in DailyLoopContent.swift.

struct DLHighlightedText: Codable, Hashable {
    let text: String
    let highlight: String?
    let bold: String?
}

struct DLBlueprintCoreFinding: Codable, Hashable {
    let title: String
    let detail: String
}

struct DLBlueprintTimelineNode: Codable, Hashable {
    let id: String?
    let label: String
    let sublabel: String?
    let panelTitle: String
    let panelBody: String
}

struct DLBlueprintBarPoint: Codable, Hashable {
    let label: String
    let sublabel: String?
    let primary: Double
    let secondary: Double
    let annotation: String
}

struct DLBlueprintBarSpec: Codable, Hashable {
    let kind: String          // "bar"
    let yAxisLabel: String
    let primaryLabel: String
    let secondaryLabel: String
    let yTickLabels: [String]
    let cliffIndex: Int?
    let cliffLabel: String?
    let defaultInsight: String
    let points: [DLBlueprintBarPoint]
}

struct DLBlueprintScatterSpec: Codable, Hashable {
    let kind: String          // "scatter"
    let beforeLabel: String
    let afterLabel: String
    let treatmentLabel: String
    let controlLabel: String
    let treatmentBeforePattern: String
    let treatmentAfterPattern: String
    let controlBeforePattern: String
    let controlAfterPattern: String
    let treatmentCount: Int
    let controlCount: Int
    let beforeCaption: String
    let afterCaption: String
    let xAxisLabel: String
    let yAxisLabel: String
}

struct DLBlueprintTrainingCurvePoint: Codable, Hashable {
    let x: Double
    let y: Double
    let milestone: String?
    let annotation: String?
}

struct DLBlueprintTrainingCurveSeries: Codable, Hashable {
    let label: String
    let color: String                       // "teal" | "amber" | "rose" | "ink"
    let points: [DLBlueprintTrainingCurvePoint]
    let dashed: Bool?
}

struct DLBlueprintTrainingCurveSpec: Codable, Hashable {
    let kind: String                        // "training_curve"
    let xAxisLabel: String
    let yAxisLabel: String
    let xTickLabels: [String]
    let yTickLabels: [String]
    let series: [DLBlueprintTrainingCurveSeries]
    let defaultInsight: String
}

struct DLBlueprintFlowRichNode: Codable, Hashable {
    let id: String
    let label: String
    let sublabel: String?
    let role: String                 // "input" | "process" | "output" | "loss" | "skip"
    let panelTitle: String
    let panelBody: String
    let column: Int
    let row: Int?
}

struct DLBlueprintFlowRichEdge: Codable, Hashable {
    let from: String
    let to: String
    let label: String?
    let kind: String                 // "forward" | "backward" | "skip"
}

struct DLBlueprintFlowRichSpec: Codable, Hashable {
    let kind: String                 // "flow_rich"
    let layout: String?              // "horizontal" | "stacked"
    let nodes: [DLBlueprintFlowRichNode]
    let edges: [DLBlueprintFlowRichEdge]
    let defaultInsight: String
}

struct DLBlueprintEquationTerm: Codable, Hashable {
    let id: String
    let display: String
    let sup: String?
    let sub: String?
    let color: String                // "teal" | "amber" | "rose" | "ink" | "muted"
    let panelTitle: String?
    let panelBody: String?
}

struct DLBlueprintEquationRichSpec: Codable, Hashable {
    let kind: String                 // "equation_rich"
    let terms: [DLBlueprintEquationTerm]
    let defaultInsight: String
    let promptText: String?
}

// Discriminated union: the JSON has a `kind` field. Decode any variant.
enum DLBlueprintVizSpec: Codable, Hashable {
    case bar(DLBlueprintBarSpec)
    case scatter(DLBlueprintScatterSpec)
    case trainingCurve(DLBlueprintTrainingCurveSpec)
    case flowRich(DLBlueprintFlowRichSpec)
    case equationRich(DLBlueprintEquationRichSpec)

    private enum KindKey: String, CodingKey { case kind }

    init(from decoder: Decoder) throws {
        let kind = try decoder.container(keyedBy: KindKey.self).decode(String.self, forKey: .kind)
        let single = try decoder.singleValueContainer()
        switch kind {
        case "bar":             self = .bar(try single.decode(DLBlueprintBarSpec.self))
        case "scatter":         self = .scatter(try single.decode(DLBlueprintScatterSpec.self))
        case "training_curve":  self = .trainingCurve(try single.decode(DLBlueprintTrainingCurveSpec.self))
        case "flow_rich":       self = .flowRich(try single.decode(DLBlueprintFlowRichSpec.self))
        case "equation_rich":   self = .equationRich(try single.decode(DLBlueprintEquationRichSpec.self))
        default:                throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                                                                       debugDescription: "Unknown viz kind: \(kind)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .bar(let s):           try c.encode(s)
        case .scatter(let s):       try c.encode(s)
        case .trainingCurve(let s): try c.encode(s)
        case .flowRich(let s):      try c.encode(s)
        case .equationRich(let s):  try c.encode(s)
        }
    }
}

struct DLBlueprintVizCard: Codable, Hashable {
    let kicker: String
    let title: DLHighlightedText
    let spec: DLBlueprintVizSpec
    let caption: String
    let takeaway: String
}

struct DailyLoopBlueprint: Codable, Hashable {
    let heroEyebrow: String
    let heroTitle: DLHighlightedText
    let heroBody: String
    let sourceLine: String

    let hookTitle: DLHighlightedText
    let hookBody: String

    let coreIdeaTitle: DLHighlightedText
    let coreFindings: [DLBlueprintCoreFinding]

    let eliAnalogyLabel: String
    let eliHeadline: DLHighlightedText
    let eliBody: DLHighlightedText

    let diagramTitle: DLHighlightedText
    let timelineNodes: [DLBlueprintTimelineNode]
    let diagramCollapseText: String
    let diagramDefaultPanelBody: String

    let vizCards: [DLBlueprintVizCard]

    let completeQuote: String
    let completeTease: String

    // Curated extensions (optional; nil on LLM-generated blueprints).
    let paperTitle: String?
    let glossary: [String: String]?
    let eliArt: String?         // "megaphone" | "scratchPaper"
    let diagramLayout: String?  // "hub" | "flow"
}
