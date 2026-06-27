import Foundation
import SwiftUI

// MARK: - SubwayMap
//
// Curated "transit map" view of the catalog. Each line is a single
// intellectual lineage running left to right; stations are papers in
// reading order; transfers are cross-line arcs that capture the moments
// where one tradition reaches into another (e.g. backprop bleeding into
// generative work via GANs).
//
// The layout is fully static — no force sim, no overlaps, no
// surprises — which makes the map calm to read at a glance while still
// telling the "research is built on top of research" story.

enum SubwayMap {

    // MARK: lines

    struct Line: Identifiable {
        let id: String
        let label: String
        let blurb: String          // 1-line description of the lineage
        let color: Color
        /// Each station: paper id + x slot (0...N). Slots are integers
        /// so transfer arcs land cleanly between same-x stations on
        /// different lines.
        let stations: [Station]
    }

    struct Station: Identifiable {
        let id: String             // paper id
        let slot: Int
        let label: String          // short station label (≤ ~16 chars)
    }

    /// Stations and whole lines for hidden papers are dropped (see
    /// `CuratedPaperCatalog.hiddenPaperIds`); `allLines` keeps the full set.
    static var lines: [Line] {
        allLines.compactMap { line in
            let kept = line.stations.filter {
                !CuratedPaperCatalog.hiddenPaperIds.contains($0.id)
            }
            guard !kept.isEmpty else { return nil }
            return Line(id: line.id, label: line.label, blurb: line.blurb,
                        color: line.color, stations: kept)
        }
    }

    private static let allLines: [Line] = [
        Line(id: "foundations",
             label: "FOUNDATIONS",
             blurb: "The bedrock — one neuron to deep residuals",
             color: Color(hex: "2a6d7a"),
             stations: [
                Station(id: "perceptron", slot: 0, label: "Perceptron"),
                Station(id: "backprop",   slot: 1, label: "Backprop"),
                Station(id: "lenet",      slot: 2, label: "LeNet"),
                Station(id: "alexnet",    slot: 3, label: "AlexNet"),
                Station(id: "resnet",     slot: 4, label: "ResNet"),
             ]),

        Line(id: "language",
             label: "LANGUAGE",
             blurb: "Embeddings to large language models",
             color: tealAccent,
             stations: [
                Station(id: "word2vec",   slot: 1, label: "Word2Vec"),
                Station(id: "seq2seq",    slot: 2, label: "Seq2Seq"),
                Station(id: "attention",  slot: 3, label: "Attention"),
                Station(id: "gpt3",       slot: 4, label: "GPT-3"),
                Station(id: "instructgpt", slot: 5, label: "InstructGPT"),
             ]),

        Line(id: "generative",
             label: "GENERATIVE",
             blurb: "Models that produce instead of classify",
             color: Color(hex: "c25a8a"),
             stations: [
                Station(id: "gans",       slot: 2, label: "GANs"),
             ]),

        Line(id: "reasoning",
             label: "REASONING",
             blurb: "Where language models learned to think",
             color: Color(hex: "8a5a18"),
             stations: [
                Station(id: "scratchpad", slot: 4, label: "Scratchpad"),
                Station(id: "chain-of-thought", slot: 5, label: "Chain of Thought"),
                Station(id: "least-to-most", slot: 6, label: "Least-to-Most"),
                Station(id: "self-consistency", slot: 7, label: "Self-Consistency"),
                Station(id: "tree-of-thoughts", slot: 8, label: "Tree of Thoughts"),
                Station(id: "react", slot: 9, label: "ReAct"),
                Station(id: "toolformer", slot: 10, label: "Toolformer"),
                Station(id: "grokking", slot: 11, label: "Grokking"),
                Station(id: "deepseek-r1", slot: 12, label: "DeepSeek-R1"),
             ]),
    ]

    // MARK: transfers
    //
    // Cross-line arcs. Each arc is rendered as a thin curve from one
    // station to another, in the color of the destination line. Used
    // sparingly: only the influences that genuinely cross subfields.

    struct Transfer: Hashable {
        let from: String   // paper id
        let to: String     // paper id
    }

    /// Transfers touching a hidden paper are dropped.
    static var transfers: [Transfer] {
        allTransfers.filter {
            !CuratedPaperCatalog.hiddenPaperIds.contains($0.from)
                && !CuratedPaperCatalog.hiddenPaperIds.contains($0.to)
        }
    }

    private static let allTransfers: [Transfer] = [
        // Backprop seeded everything.
        Transfer(from: "backprop", to: "word2vec"),
        Transfer(from: "backprop", to: "gans"),
        // Language scaled into reasoning: scratchpads and prompting first,
        // then alignment feeding the trained reasoners.
        Transfer(from: "gpt3", to: "scratchpad"),
        Transfer(from: "gpt3", to: "chain-of-thought"),
        Transfer(from: "instructgpt", to: "deepseek-r1"),
    ]

    // MARK: helpers

    static var maxSlot: Int {
        lines.flatMap { $0.stations.map(\.slot) }.max() ?? 0
    }

    static func line(of stationId: String) -> Line? {
        lines.first { $0.stations.contains { $0.id == stationId } }
    }

    static func station(_ id: String) -> Station? {
        lines.flatMap(\.stations).first { $0.id == id }
    }

    static func allStations() -> [Station] {
        lines.flatMap(\.stations)
    }

    /// Neighbors of a station: previous + next on its own line, plus
    /// any station reached by a transfer involving this one.
    static func neighbors(of stationId: String) -> [String] {
        var out: [String] = []
        if let l = line(of: stationId),
           let idx = l.stations.firstIndex(where: { $0.id == stationId }) {
            if idx > 0 { out.append(l.stations[idx - 1].id) }
            if idx < l.stations.count - 1 { out.append(l.stations[idx + 1].id) }
        }
        for t in transfers {
            if t.from == stationId { out.append(t.to) }
            if t.to   == stationId { out.append(t.from) }
        }
        return out
    }
}
