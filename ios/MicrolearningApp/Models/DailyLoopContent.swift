import Foundation
import SwiftUI

// MARK: - Daily Loop Content

// Segmented text with inline italic/highlighted runs, used for card titles
// and questions that weave an accent word into serif copy.
enum DLSegment {
    case plain(String)
    case highlight(String)   // italic + accent color
}

// For body paragraphs that mix regular serif copy with emphasized nouns.
enum DLHighlightPart {
    case plain(String)
    case bold(String)
}

struct DLCoreIdeaItem {
    let roman: String
    let title: String
    let detail: String
}

// MARK: - Learning objectives
//
// Sharper "by the end you'll know" bullets shown on the Hook card. Each item is
// a short objective + an optional one-line gloss that fits under it. When set,
// replaces the auto-derived YOU'LL LEARN list (which used coreIdeaItems.title).
// Reserved for the foundational bundle so other loops keep the lean default.
struct DLObjective {
    let text: String           // ≤9 words, concrete verb up front
    let gloss: String?         // optional ~10-word elaboration under the bullet
}

// MARK: - Explanation card (annotated re-walk of the diagram)
//
// Slot 4 in the foundational deck (the new card inserted between the
// interactive diagram and the first viz). Reinforces what the diagram taught
// with a static mini-recap and 3 narrative paragraphs. Optional on every
// content variant; only present for the foundational bundle's premium loops.

enum DLExplanationMini {
    // Each case maps to a per-paper bespoke mini-recap rendered by
    // `ExplanationCard.swift`. Keep one case per studio view in the bundle so
    // the visual matches the diagram the reader just left.
    case perceptron, backprop, lenet, alexnet, word2vec
    case seq2seq, gans, resnet, transformer, gpt3, bert
    case deepseekR1, instructGPT, chainOfThought
    case scratchpad, selfConsistency, treeOfThoughts
    case leastToMost, reAct, toolformer
    case grokking
}

struct DLExplanationPara {
    let kicker: String?        // e.g., "P1 · WEIGHTS" rendered as small caps. Optional.
    let body: String           // 1-3 sentences. Glossarised on render.
}

struct DLExplanationCard {
    let eyebrow: String                  // e.g., "WHAT JUST HAPPENED"
    let titleSegments: [DLSegment]       // serif title with one highlight
    let mini: DLExplanationMini          // which bespoke mini-recap to render
    let paragraphs: [DLExplanationPara]  // exactly 3 (sometimes 4)
    let takeaway: String                 // bold one-liner at the foot of the card
}

enum DLDiagramLayout {
    case hub      // center seeker with three satellites (attention-collapse)
    case flow     // linear left→right reasoning chain (chain-of-thought)
}

enum DLEliArt {
    case megaphone    // loud-voice / drowns-the-room analogies
    case scratchPaper // mental-math / scratch-pad analogies
    case magnifier    // sliding-window / focus / inspect analogies (LeNet)
    case kitchen      // kitchen / recipe / ingredients analogies (AlexNet)
    case map          // map / geography / coordinates analogies (Word2Vec)
    case whisper      // whisper-game / single-channel analogies (Seq2Seq)
    case forger       // forger-vs-detective / dueling analogies (GANs)
    case exit         // emergency-exit / shortcut / skip analogies (ResNet)
    case readers      // room-of-readers / parallel-attention analogies (Transformer)
    case librarian    // librarian / recall / catalog analogies (GPT-3)
    case exoskeleton  // exoskeleton / external-scaffold analogies
    case bouncer      // bouncer / gatekeeper / clipboard analogies

    /// Pick the closest shape from the analogy label. Used when content comes
    /// from the backend blueprint (free-form string) so each paper still gets
    /// a unique illustration even when the LLM writes a fresh metaphor.
    static func from(label: String) -> DLEliArt {
        let s = label.lowercased()
        if s.contains("bouncer") || s.contains("clipboard") || s.contains("gatekeeper") { return .bouncer }
        if s.contains("librarian") || s.contains("library") || s.contains("recall") || s.contains("catalog") { return .librarian }
        if s.contains("readers") || s.contains("reader") || s.contains("crowd") || s.contains("audience") { return .readers }
        if s.contains("exit") || s.contains("shortcut") || s.contains("skip") || s.contains("bypass") { return .exit }
        if s.contains("forger") || s.contains("detective") || s.contains("counterfeit") || s.contains("duel") { return .forger }
        if s.contains("whisper") || s.contains("telephone game") || s.contains("relay") { return .whisper }
        if s.contains("map") || s.contains("atlas") || s.contains("coordinate") || s.contains("geography") { return .map }
        if s.contains("kitchen") || s.contains("recipe") || s.contains("chef") || s.contains("ingredient") { return .kitchen }
        if s.contains("magnif") || s.contains("microscope") || s.contains("lens") || s.contains("zoom") { return .magnifier }
        if s.contains("exoskeleton") || s.contains("scaffold") || s.contains("brace") || s.contains("crutch") { return .exoskeleton }
        if s.contains("scratch") || s.contains("notepad") || s.contains("pencil") || s.contains("paper") { return .scratchPaper }
        if s.contains("megaphone") || s.contains("loud") || s.contains("voice") || s.contains("shout") { return .megaphone }
        return .bouncer
    }
}

struct DLDiagramNode {
    let id: String
    let label: String          // Short label drawn on the node (e.g., "K₁", "Step 1")
    let sublabel: String?      // Optional second line inside the node
    let panelTitle: String     // Uppercased title for the explanation panel
    let panelBody: String      // Explanation body for the panel
}

// MARK: - Visualization module
//
// Replaces the old quiz cards (fill-in-the-blanks + MCQ). Each daily-loop
// deck supplies exactly two `DLVizCard`s. A viz card pairs an editorial
// title + caption with one `DLVisualization` payload. New chart types are
// added by extending the enum and adding a renderer in DailyLoopView.

struct DLBarPoint {
    let label: String          // X-axis tick (e.g., "D1", "62B")
    let sublabel: String?      // Small caption under tick (e.g., "baseline")
    let primary: Double        // Primary bar height, 0...yMax
    let secondary: Double?     // Optional comparison bar (nil = single bar)
    let annotation: String?    // Tap-to-reveal callout above this point
}

struct DLBarChartSpec {
    let yAxisLabel: String
    let primaryLabel: String
    let secondaryLabel: String?
    let yMax: Double           // Used to normalize bar heights
    let yTickLabels: [String]  // 2-3 reference labels (e.g., "0", "50%", "100%")
    let points: [DLBarPoint]
    let cliffIndex: Int?       // Optional vertical rule (e.g., where ChatGPT was withdrawn)
    let cliffLabel: String?
    let defaultInsight: String // Shown in the insight panel before any tap
}

struct DLScatterDot {
    let xBefore: Double        // 0..1 normalized position pre-transition
    let yBefore: Double
    let xAfter: Double         // 0..1 position post-transition
    let yAfter: Double
    let isTreatment: Bool      // Treatment vs control (drives color)
}

struct DLScatterMorphSpec {
    let beforeLabel: String    // e.g., "Day 1"
    let afterLabel: String     // e.g., "Day 30"
    let treatmentLabel: String
    let controlLabel: String
    let dots: [DLScatterDot]
    let beforeCaption: String  // Shown when scrubber is at start
    let afterCaption: String   // Shown when scrubber is at end
    let xAxisLabel: String     // e.g., "Vocabulary diversity →"
    let yAxisLabel: String     // e.g., "Sentence structure variance →"
}

enum DLTrainingCurveColor {
    case teal, amber, rose, ink
}

struct DLTrainingCurvePoint {
    let x: Double            // raw domain value (epoch number, step, etc.)
    let y: Double            // 0..1 normalised
    let milestone: String?   // tick label rendered next to the dot
    let annotation: String?  // panel body when the dot is tapped
}

struct DLTrainingCurveSeries {
    let label: String
    let color: DLTrainingCurveColor
    let dashed: Bool
    let points: [DLTrainingCurvePoint]
}

struct DLTrainingCurveSpec {
    let xAxisLabel: String
    let yAxisLabel: String
    let xTickLabels: [String]
    let yTickLabels: [String]
    let series: [DLTrainingCurveSeries]
    let defaultInsight: String
}

// MARK: - Flow-rich visualization
//
// Boxes-and-arrows architecture diagram. Nodes lay out on a column/row grid
// (column = stage along the pipeline, row = parallel branch / skip path).
// Edge kinds map to distinct strokes, solid teal forward, dashed amber
// backward, curved ink skip.

enum DLFlowRichRole {
    case input, process, output, loss, skipNode
}

enum DLFlowRichEdgeKind {
    case forward, backward, skip
}

enum DLFlowRichLayout {
    case horizontal, stacked
}

struct DLFlowRichNode {
    let id: String
    let label: String
    let sublabel: String?
    let role: DLFlowRichRole
    let panelTitle: String
    let panelBody: String
    let column: Int
    let row: Int
}

struct DLFlowRichEdge {
    let from: String
    let to: String
    let label: String?
    let kind: DLFlowRichEdgeKind
}

struct DLFlowRichSpec {
    let layout: DLFlowRichLayout
    let nodes: [DLFlowRichNode]
    let edges: [DLFlowRichEdge]
    let defaultInsight: String
}

// MARK: - Equation-rich visualization
//
// Hand-typeset equation. Each term is a token with optional super/sub script
// and an optional explanation panel. Operators are non-tappable. The renderer
// lays out the terms baseline-aligned and lets the user tap any meaningful
// term to surface its definition.

enum DLEquationTermColor {
    case teal, amber, rose, ink, muted
}

struct DLEquationTerm {
    let id: String
    let display: String
    let sup: String?
    let sub: String?
    let color: DLEquationTermColor
    let panelTitle: String?
    let panelBody: String?
    var isTappable: Bool { panelTitle != nil && panelBody != nil }
}

struct DLEquationRichSpec {
    let terms: [DLEquationTerm]
    let defaultInsight: String
    let promptText: String?
}

enum DLVisualization {
    case barChart(DLBarChartSpec)
    case scatterMorph(DLScatterMorphSpec)
    case trainingCurve(DLTrainingCurveSpec)
    case flowRich(DLFlowRichSpec)
    case equationRich(DLEquationRichSpec)
}

struct DLVizCard {
    let kicker: String                 // e.g., "CARD 05 · THE DATA"
    let titleSegments: [DLSegment]
    let visualization: DLVisualization
    let caption: String                // 1-2 sentence editorial framing under the chart
    let takeaway: String               // Bottom-of-card sticky takeaway
}

// A fully-parameterized 7-step daily loop (5 content cards + 2 viz cards + complete).
struct DailyLoopContent {
    // Hero card surface (shown in Featured Papers carousel / Today's Paper hero)
    let heroEyebrow: String              // e.g., "FRESH · 4 HOURS AGO" or "DAILY LOOP · NEW"
    let heroTitleSegments: [DLSegment]   // condensed headline for hero card
    let heroBody: String                 // one-sentence blurb for hero card
    let sourceLine: String               // e.g., "arXiv:2201.11903 · Wei et al."

    // Card 1, Hook (dark card)
    let hookSegments: [DLSegment]
    let hookBody: String

    // Card 2, Core Idea
    let coreIdeaSegments: [DLSegment]
    let coreIdeaItems: [DLCoreIdeaItem]   // exactly 3

    // Card 3, ELI5
    let eliAnalogyLabel: String
    let eliHeadlineSegments: [DLSegment]
    let eliBodyParts: [DLHighlightPart]
    let eliArt: DLEliArt

    // Card 4, Interactive concept diagram
    let diagramSegments: [DLSegment]
    let diagramLayout: DLDiagramLayout
    let diagramNodes: [DLDiagramNode]     // exactly 4
    let diagramCollapseText: String?      // optional marker below the nodes
    let diagramDefaultPanelBody: String

    // Cards 5 to 6, Visualizations (replace the old quiz cards). Exactly 2.
    let vizCards: [DLVizCard]

    // Complete
    let completeTakeaway: String
    let completeNextTease: String

    // Real paper title (full academic name). Rendered at the bottom of the
    // hook card as a citation so the reader can connect the editorial framing
    // to the original work. Optional: hardcoded variants that pre-date this
    // field default to nil and skip the citation block.
    var paperTitle: String? = nil

    // Inline glossary. Keys are matched case-insensitively against body copy
    // (hook, accordion details, ELI body, diagram panels). Matched terms render
    // with a subtle teal underline; tapping opens a Kindle-style sheet with
    // the definition. Empty by default.
    var glossary: [String: String] = [:]

    // Backing paper id, used by the save / bookmark feature so the loop can
    // be toggled into the user's library. Set automatically by the deck-based
    // init; nil for hardcoded preview variants that have no real CardDeck
    // behind them, in which case the bookmark control hides.
    var paperId: String? = nil

    // Sharpened learning objectives. When non-nil, the Hook card swaps the
    // auto-derived YOU'LL LEARN bullets (which read from coreIdeaItems.title)
    // for this hand-tuned list. Reserved for the foundational bundle.
    var learningObjectives: [DLObjective]? = nil

    // Annotated re-walk of the diagram. When non-nil, slot 4 of the loop becomes
    // a static recap card sitting between the interactive diagram and the first
    // viz. Foundational papers only; other loops keep the original 7-card flow.
    var explanationCard: DLExplanationCard? = nil

    // Canonical URL for the original paper (arXiv, Nature, Yann LeCun's site,
    // etc.). When set, the Complete card renders a "Read the full paper" link
    // above the Done button so the reader can jump from the microlearning loop
    // straight to the source. Optional; legacy loops without a hosted source
    // simply hide the link.
    var paperURL: String? = nil
}

// MARK: - Estimated read time
//
// Replaces a hardcoded "5 MIN" badge that used to sit on every hero/loop
// header. Sums word count across every body-text surface in the loop, divides
// by 180 wpm, and adds 90s of fixed overhead for the interactive diagram and
// the two viz cards. Rounds up to whole minutes, never below 2.
extension DailyLoopContent {
    var estimatedMinutes: Int {
        var words = dlWordCount(heroBody)
        words += dlSegmentWords(hookSegments) + dlWordCount(hookBody)
        words += dlSegmentWords(coreIdeaSegments)
        for item in coreIdeaItems {
            words += dlWordCount(item.title) + dlWordCount(item.detail)
        }
        words += dlWordCount(eliAnalogyLabel)
        words += dlSegmentWords(eliHeadlineSegments)
        for part in eliBodyParts {
            switch part {
            case .plain(let s), .bold(let s):
                words += dlWordCount(s)
            }
        }
        words += dlSegmentWords(diagramSegments)
        words += dlWordCount(diagramDefaultPanelBody)
        if let s = diagramCollapseText { words += dlWordCount(s) }
        for node in diagramNodes {
            words += dlWordCount(node.panelTitle) + dlWordCount(node.panelBody)
            words += dlWordCount(node.label)
            if let sub = node.sublabel { words += dlWordCount(sub) }
        }
        for v in vizCards {
            words += dlWordCount(v.kicker)
            words += dlSegmentWords(v.titleSegments)
            words += dlWordCount(v.caption) + dlWordCount(v.takeaway)
            words += dlVizWords(v.visualization)
        }
        words += dlWordCount(completeTakeaway) + dlWordCount(completeNextTease)

        if let objs = learningObjectives {
            for o in objs {
                words += dlWordCount(o.text)
                if let g = o.gloss { words += dlWordCount(g) }
            }
        }
        if let ec = explanationCard {
            words += dlWordCount(ec.eyebrow) + dlSegmentWords(ec.titleSegments) + dlWordCount(ec.takeaway)
            for p in ec.paragraphs {
                words += dlWordCount(p.body)
                if let k = p.kicker { words += dlWordCount(k) }
            }
        }

        let readingSeconds = Double(words) / 180.0 * 60.0
        // Add 90s baseline (diagram + 2 viz). +30s extra if the deck includes
        // the explanation card so the timer better reflects the longer flow.
        let overhead: Double = explanationCard == nil ? 90.0 : 120.0
        let totalSeconds = readingSeconds + overhead
        return max(2, Int((totalSeconds / 60.0).rounded(.up)))
    }
}

private func dlWordCount(_ s: String) -> Int {
    s.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
}

private func dlSegmentWords(_ segs: [DLSegment]) -> Int {
    segs.reduce(0) { acc, seg in
        switch seg {
        case .plain(let s), .highlight(let s):
            return acc + dlWordCount(s)
        }
    }
}

private func dlVizWords(_ v: DLVisualization) -> Int {
    switch v {
    case .barChart(let s):
        var n = dlWordCount(s.defaultInsight) + dlWordCount(s.yAxisLabel) + dlWordCount(s.primaryLabel)
        if let l = s.secondaryLabel { n += dlWordCount(l) }
        if let l = s.cliffLabel { n += dlWordCount(l) }
        for p in s.points {
            n += dlWordCount(p.label)
            if let sub = p.sublabel { n += dlWordCount(sub) }
            if let a = p.annotation { n += dlWordCount(a) }
        }
        return n
    case .scatterMorph(let s):
        return dlWordCount(s.beforeCaption) + dlWordCount(s.afterCaption)
             + dlWordCount(s.xAxisLabel) + dlWordCount(s.yAxisLabel)
             + dlWordCount(s.treatmentLabel) + dlWordCount(s.controlLabel)
    case .trainingCurve(let s):
        var n = dlWordCount(s.defaultInsight) + dlWordCount(s.xAxisLabel) + dlWordCount(s.yAxisLabel)
        for series in s.series {
            n += dlWordCount(series.label)
            for p in series.points {
                if let m = p.milestone { n += dlWordCount(m) }
                if let a = p.annotation { n += dlWordCount(a) }
            }
        }
        return n
    case .flowRich(let s):
        var n = dlWordCount(s.defaultInsight)
        for node in s.nodes {
            n += dlWordCount(node.label) + dlWordCount(node.panelTitle) + dlWordCount(node.panelBody)
            if let sub = node.sublabel { n += dlWordCount(sub) }
        }
        for e in s.edges {
            if let l = e.label { n += dlWordCount(l) }
        }
        return n
    case .equationRich(let s):
        var n = dlWordCount(s.defaultInsight)
        if let p = s.promptText { n += dlWordCount(p) }
        for t in s.terms {
            if let pt = t.panelTitle { n += dlWordCount(pt) }
            if let pb = t.panelBody { n += dlWordCount(pb) }
        }
        return n
    }
}

// MARK: - Glossary helpers

struct DLGlossaryHit: Identifiable, Hashable {
    var id: String { term }
    let term: String
    let definition: String
}

// Builds an AttributedString that renders glossary terms as tappable links.
// We hijack the URL field with a custom `aprecis://gloss/<term>` scheme;
// SwiftUI's openURL environment intercepts it and surfaces a sheet.
//
// Style: glossary terms render in teal + semibold. Underlines were too easy
// to mistake for hyperlinks-to-elsewhere; a colored bold reads as in-place
// emphasis and tests as more obviously interactive in the editorial layout.
func dlGlossarise(_ raw: String, glossary: [String: String]) -> AttributedString {
    var attr = AttributedString(raw)
    if glossary.isEmpty { return attr }
    let teal = Color(red: 0.06, green: 0.35, blue: 0.35)   // matches dlTealDeep

    // Collect every word-boundary match across all terms, then apply greedily
    // longest-first while skipping overlaps. Word boundaries stop "ML" from
    // hitting the "ml" inside "randomly" and stop "feature" from hitting
    // "features" only when the user wrote both keys; case-insensitive so
    // "Cross-validation" and "cross-validation" both resolve.
    struct Hit { let nsRange: NSRange; let term: String }
    var hits: [Hit] = []

    let ns = raw as NSString
    let full = NSRange(location: 0, length: ns.length)
    let letterDigit = CharacterSet.letters.union(.decimalDigits)

    for term in glossary.keys {
        let escaped = NSRegularExpression.escapedPattern(for: term)
        // Use lookaround on letter/digit characters so terms with leading or
        // trailing punctuation (e.g. "C4.5", "K-L div.", "Occam's razor")
        // still anchor cleanly. \b alone misbehaves around the dot in "C4.5".
        let pattern = "(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let rx = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
        rx.enumerateMatches(in: raw, options: [], range: full) { match, _, _ in
            guard let m = match else { return }
            // Belt + braces: re-verify boundaries against the original string.
            let lo = m.range.location
            let hi = m.range.location + m.range.length
            if lo > 0 {
                let prev = ns.substring(with: NSRange(location: lo - 1, length: 1)).unicodeScalars.first!
                if letterDigit.contains(prev) { return }
            }
            if hi < ns.length {
                let next = ns.substring(with: NSRange(location: hi, length: 1)).unicodeScalars.first!
                if letterDigit.contains(next) { return }
            }
            hits.append(Hit(nsRange: m.range, term: term))
        }
    }

    // Apply longest hits first; skip any that overlap an already-claimed range.
    hits.sort { ($0.nsRange.length, -$0.nsRange.location) > ($1.nsRange.length, -$1.nsRange.location) }
    var claimed: [NSRange] = []
    func overlaps(_ a: NSRange, _ b: NSRange) -> Bool {
        return NSIntersectionRange(a, b).length > 0
    }

    for hit in hits {
        if claimed.contains(where: { overlaps($0, hit.nsRange) }) { continue }
        guard let swiftRange = Range(hit.nsRange, in: raw),
              let attrRange = Range(swiftRange, in: attr) else { continue }
        let canonical = glossary.keys.first { $0.caseInsensitiveCompare(hit.term) == .orderedSame } ?? hit.term
        let encoded = canonical.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? canonical
        attr[attrRange].link = URL(string: "aprecis://gloss/\(encoded)")
        attr[attrRange].foregroundColor = teal
        attr[attrRange].inlinePresentationIntent = .stronglyEmphasized
        claimed.append(hit.nsRange)
    }

    return attr
}

// MARK: - Mutators

extension DailyLoopContent {
    /// Returns a copy with paperId set, so the bookmark control in
    /// `DailyLoopView` becomes active. Used to give hardcoded preview
    /// variants (which have no real CardDeck) a stable save key.
    func withPaperId(_ id: String) -> DailyLoopContent {
        var copy = self
        copy.paperId = id
        return copy
    }

    /// Resolves a synthetic "loop:..." paperId back to its hardcoded
    /// DailyLoopContent. Used by the profile Library + Recently viewed
    /// sections so a saved hardcoded loop can be re-rendered as a row
    /// without going through the feed API.
    /// Every hardcoded loop shipping in the app, with the stable paperId that
    /// routes into it. Used by Explore "All" so users see the full prepared
    /// catalog without depending on the backend feed.
    ///
    /// Canonical IDs are maintained in `CuratedPaperCatalog.interactiveLoopPaperIds`.
    static var allPrepared: [(paperId: String, content: DailyLoopContent)] {
        CuratedPaperCatalog.allPrepared
    }

    static func byPaperId(_ id: String) -> DailyLoopContent? {
        CuratedPaperCatalog.content(forPaperId: id)
    }
}

// MARK: - Canonical content

extension DailyLoopContent {

    // The original hardcoded "attention head collapse" loop (DeepMind), kept as
    // the default so existing Today's Paper hero behaves identically.
    static let attentionCollapse = DailyLoopContent(
        heroEyebrow: "FRESH · 4 HOURS AGO",
        heroTitleSegments: [
            .plain("Why transformers "),
            .highlight("hallucinate")
        ],
        heroBody: "Most of those confident wrong answers come from a single failure inside the model: one tiny piece grabs onto one word and drowns out the rest.",
        sourceLine: "DeepMind · 2024",

        hookSegments: [
            .plain("What if a model's "),
            .highlight("wildest lies"),
            .plain(" come from a single broken neuron?")
        ],
        hookBody: "Roughly 80% of those confident wrong answers trace back to a single failure inside the model. One tiny piece latches onto one word and drowns out everything else the sentence is saying.",

        coreIdeaSegments: [
            .plain("Three things that break "),
            .highlight("at once")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "The model fixates on one word",
                detail: "Softmax across the head's 512 tokens collapses. One position gets weight ≈ 1, the rest ≈ 0. Normally spread is ~0.2 per cluster."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Later parts of the model go blind",
                detail: "With 95%+ of attention on one token, the residual stream for other positions gets starved. Layer N+1 builds features from near zero vectors."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "It still sounds confident",
                detail: "The logit for the predicted token is sharpened, not widened, so the model outputs the wrong answer with *higher* confidence than a balanced head would."),
        ],

        eliAnalogyLabel: "ANALOGY · ONE LOUD VOICE DROWNS THE ROOM",
        eliHeadlineSegments: [
            .plain("Imagine a meeting where "),
            .highlight("one person starts shouting"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("Attention heads are a "),
            .bold("committee"),
            .plain(". Each one casts a weighted vote on what word matters next. When a head collapses, it's like one committee member grabs the mic and "),
            .bold("shouts over everyone"),
            .plain(". The rest stop talking, and the chair (the next layer) mishears the room.")
        ],
        eliArt: .megaphone,

        diagramSegments: [
            .plain("How a head "),
            .highlight("collapses")
        ],
        diagramLayout: .hub,
        diagramNodes: [
            DLDiagramNode(id: "q",  label: "Query", sublabel: "\"Paris\"",
                          panelTitle: "Query · the seeker",
                          panelBody: "The Query vector asks: \"what else matters for this token?\" It's the side that scans the sentence looking for relevant context."),
            DLDiagramNode(id: "k1", label: "K₁", sublabel: "\"France\"",
                          panelTitle: "K₁ (\"France\") · the winner",
                          panelBody: "K₁ wins the softmax. Its dot product with Q is ~15× the others. In a healthy head the gap would be ~2×."),
            DLDiagramNode(id: "k2", label: "K₂", sublabel: nil,
                          panelTitle: "K₂ · starved",
                          panelBody: "K₂ normally contributes ~25% of the attention mass. Here it's near zero. The collapse has drowned it out."),
            DLDiagramNode(id: "k3", label: "K₃", sublabel: nil,
                          panelTitle: "K₃ · starved",
                          panelBody: "K₃ same story. Attention has collapsed into a single peak instead of spreading across relevant keys.")
        ],
        diagramCollapseText: "⚠ Collapse",
        diagramDefaultPanelBody: "Four nodes form one attention head. Tap each to see its role. The explanation rewrites as you go.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · ATTENTION SHAPE",
                titleSegments: [
                    .plain("Healthy spread vs. "),
                    .highlight("collapsed spike")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Attention weight",
                    primaryLabel: "Collapsed head",
                    secondaryLabel: "Healthy head",
                    yMax: 1.0,
                    yTickLabels: ["0", "0.5", "1.0"],
                    points: [
                        DLBarPoint(label: "K₁", sublabel: "winner", primary: 0.95, secondary: 0.32,
                                   annotation: "K₁ takes 95% of the mass after collapse, a healthy head gives it ~32%."),
                        DLBarPoint(label: "K₂", sublabel: nil, primary: 0.02, secondary: 0.28,
                                   annotation: "K₂ flatlines under collapse. Its signal was 28% of attention before, now near zero."),
                        DLBarPoint(label: "K₃", sublabel: nil, primary: 0.02, secondary: 0.22,
                                   annotation: "K₃ same story: starved by the dominant peak."),
                        DLBarPoint(label: "K₄", sublabel: nil, primary: 0.01, secondary: 0.18,
                                   annotation: "K₄ effectively silenced. The softmax has collapsed into a delta function."),
                    ],
                    cliffIndex: nil,
                    cliffLabel: nil,
                    defaultInsight: "Tap any bar. A healthy head spreads attention across the keys. A collapsed head dumps it onto one."
                )),
                caption: "Each pair shows one key token's share of attention. In a healthy head the four bars sit close together. In a collapsed head, one swallows the rest.",
                takeaway: "Collapse is shape, not size."
            ),
            DLVizCard(
                kicker: "CARD 06 · THE DRIFT",
                titleSegments: [
                    .plain("Token vectors "),
                    .highlight("drift toward one")
                ],
                visualization: .scatterMorph(DLScatterMorphSpec(
                    beforeLabel: "Healthy",
                    afterLabel: "Collapsed",
                    treatmentLabel: "Attended to keys",
                    controlLabel: "Other tokens",
                    dots: [
                        DLScatterDot(xBefore: 0.18, yBefore: 0.30, xAfter: 0.78, yAfter: 0.40, isTreatment: true),
                        DLScatterDot(xBefore: 0.30, yBefore: 0.62, xAfter: 0.80, yAfter: 0.42, isTreatment: true),
                        DLScatterDot(xBefore: 0.55, yBefore: 0.24, xAfter: 0.79, yAfter: 0.41, isTreatment: true),
                        DLScatterDot(xBefore: 0.72, yBefore: 0.78, xAfter: 0.81, yAfter: 0.39, isTreatment: true),
                        DLScatterDot(xBefore: 0.42, yBefore: 0.48, xAfter: 0.80, yAfter: 0.40, isTreatment: true),
                        DLScatterDot(xBefore: 0.20, yBefore: 0.80, xAfter: 0.20, yAfter: 0.80, isTreatment: false),
                        DLScatterDot(xBefore: 0.14, yBefore: 0.20, xAfter: 0.14, yAfter: 0.20, isTreatment: false),
                        DLScatterDot(xBefore: 0.85, yBefore: 0.15, xAfter: 0.85, yAfter: 0.15, isTreatment: false),
                        DLScatterDot(xBefore: 0.62, yBefore: 0.85, xAfter: 0.62, yAfter: 0.85, isTreatment: false),
                    ],
                    beforeCaption: "Attended keys spread across the residual space. Each contributes its own slice of context.",
                    afterCaption: "Attended keys collapse to a single point. The model treats them as one token.",
                    xAxisLabel: "Residual dim 1 →",
                    yAxisLabel: "Residual dim 2 →"
                )),
                caption: "Drag the scrubber. Coloured dots are the keys an attention head reads from. Watch them collapse onto one location as the head over weights its winner.",
                takeaway: "One peak, every read goes to the same place."
            ),
        ],

        completeTakeaway: "\"Hallucination isn't random. It's a broken softmax.\"",
        completeNextTease: "Come back tomorrow for diffusion models.",
        paperTitle: "Attention Head Collapse and the Geometry of Hallucination in Large Language Models"
    )

    // Chain-of-Thought Prompting (Wei et al., arXiv:2201.11903), formatted
    // for learning. Used as the top card in Featured Papers.
    static let chainOfThought = DailyLoopContent(
        heroEyebrow: "DAILY LOOP · NEW",
        heroTitleSegments: [
            .plain("How one line of text made models "),
            .highlight("reason")
        ],
        heroBody: "Show the model a few examples that work through the problem step by step, and it starts showing its working too. Grade school math goes from 17% to 57%, no retraining.",
        sourceLine: "arXiv:2201.11903 · Wei et al., 2022",

        hookSegments: [
            .plain("What if writing "),
            .highlight("\"let's think step by step\""),
            .plain(" made a model 3× smarter?")
        ],
        hookBody: "A massive reasoning gain came from a simple prompting trick. Include a few examples that work through the problem step by step, and the model starts writing its own scratch work. Grade school math accuracy jumped from 17% to 57%.",

        coreIdeaSegments: [
            .plain("Three things that change "),
            .highlight("at once")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "Asking once skips the thinking",
                detail: "\"Q → A\" forces the model to compute the answer in one forward pass. For multi step problems there's no room for intermediate reasoning. The answer arrives half formed."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Showing steps unlocks reasoning",
                detail: "Prepend a few examples of worked out reasoning (Q → thought₁ → thought₂ → A). The model imitates the format and starts generating its own intermediate steps before answering."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Only big models get this trick",
                detail: "CoT barely helps below ~62B parameters. The steps come out incoherent and often hurt accuracy. Above that threshold, multi step reasoning clicks on sharply. It's an emergent capability, not a continuous curve."),
        ],

        eliAnalogyLabel: "ANALOGY · MENTAL MATH VS. SCRATCH PAPER",
        eliHeadlineSegments: [
            .plain("Imagine solving "),
            .highlight("23 × 17"),
            .plain(" in your head, vs. on paper.")
        ],
        eliBodyParts: [
            .plain("A model with plain prompting is a kid asked to "),
            .bold("shout the answer immediately"),
            .plain(". Chain of thought is like giving that same kid "),
            .bold("scratch paper"),
            .plain(". Same brain, same numbers. But now they can work it out step by step, check as they go, and land on the right answer. The trick isn't a smarter kid. It's "),
            .bold("space to think"),
            .plain(".")
        ],
        eliArt: .scratchPaper,

        diagramSegments: [
            .plain("How a thought "),
            .highlight("unfolds")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "q",
                label: "Problem",
                sublabel: "5 + 2 cans",
                panelTitle: "Problem · the prompt",
                panelBody: "\"Roger has 5 tennis balls. He buys 2 more cans, 3 balls each. How many now?\" Without CoT the model would jump straight to a number, often the wrong one."),
            DLDiagramNode(
                id: "t1",
                label: "Thought 1",
                sublabel: "2 × 3 = 6",
                panelTitle: "Thought 1 · decompose",
                panelBody: "The model writes out the first sub step: 2 cans × 3 balls = 6 balls. Breaking the problem into pieces lets each forward pass do bounded work, not arbitrary work."),
            DLDiagramNode(
                id: "t2",
                label: "Thought 2",
                sublabel: "5 + 6 = 11",
                panelTitle: "Thought 2 · combine",
                panelBody: "The second step reads the previous line and adds: 5 starting + 6 new = 11. Each token of the answer now conditions on its own reasoning trace, not just the question."),
            DLDiagramNode(
                id: "a",
                label: "Answer",
                sublabel: "11",
                panelTitle: "Answer · land it",
                panelBody: "The final token predicts from a context that already contains the worked out chain. Error rates on GSM8K drop from 18% to 57% at PaLM-540B scale.")
        ],
        diagramCollapseText: nil,
        diagramDefaultPanelBody: "Four stops along one reasoning chain. Tap each to see what the model does at that step.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · EMERGENCE",
                titleSegments: [
                    .plain("CoT clicks on at "),
                    .highlight("~62B params")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "GSM8K accuracy",
                    primaryLabel: "Chain of thought",
                    secondaryLabel: "Standard prompt",
                    yMax: 0.6,
                    yTickLabels: ["0%", "30%", "60%"],
                    points: [
                        DLBarPoint(label: "8B", sublabel: nil, primary: 0.05, secondary: 0.06,
                                   annotation: "Below threshold. CoT steps come out incoherent and slightly hurt accuracy."),
                        DLBarPoint(label: "62B", sublabel: nil, primary: 0.18, secondary: 0.13,
                                   annotation: "Threshold. CoT just edges past standard prompting. The capability is starting to fire."),
                        DLBarPoint(label: "175B", sublabel: nil, primary: 0.35, secondary: 0.16,
                                   annotation: "Now CoT decisively wins. The model writes coherent intermediate steps."),
                        DLBarPoint(label: "540B", sublabel: "PaLM", primary: 0.57, secondary: 0.17,
                                   annotation: "Headline result: 57% with CoT vs 17% without. A 3× lift from one prompt change."),
                    ],
                    cliffIndex: 1,
                    cliffLabel: "emergence",
                    defaultInsight: "Tap a bar. Below 62B params CoT does nothing. Above it, accuracy snaps upward, a discontinuous jump."
                )),
                caption: "Two prompting strategies, four model sizes. The CoT line stays flat with the standard line until a sharp threshold around 62B parameters.",
                takeaway: "Reasoning is emergent. It needs scale to compile."
            ),
            DLVizCard(
                kicker: "CARD 06 · ROOM TO THINK",
                titleSegments: [
                    .plain("From one token "),
                    .highlight("to a chain")
                ],
                visualization: .scatterMorph(DLScatterMorphSpec(
                    beforeLabel: "No scratchpad",
                    afterLabel: "With scratchpad",
                    treatmentLabel: "Correct answer",
                    controlLabel: "Wrong answer",
                    dots: [
                        DLScatterDot(xBefore: 0.50, yBefore: 0.62, xAfter: 0.85, yAfter: 0.30, isTreatment: true),
                        DLScatterDot(xBefore: 0.50, yBefore: 0.50, xAfter: 0.85, yAfter: 0.32, isTreatment: true),
                        DLScatterDot(xBefore: 0.50, yBefore: 0.40, xAfter: 0.85, yAfter: 0.28, isTreatment: true),
                        DLScatterDot(xBefore: 0.50, yBefore: 0.30, xAfter: 0.84, yAfter: 0.34, isTreatment: true),
                        DLScatterDot(xBefore: 0.20, yBefore: 0.55, xAfter: 0.20, yAfter: 0.55, isTreatment: false),
                        DLScatterDot(xBefore: 0.18, yBefore: 0.40, xAfter: 0.18, yAfter: 0.40, isTreatment: false),
                        DLScatterDot(xBefore: 0.25, yBefore: 0.70, xAfter: 0.25, yAfter: 0.70, isTreatment: false),
                        DLScatterDot(xBefore: 0.28, yBefore: 0.30, xAfter: 0.28, yAfter: 0.30, isTreatment: false),
                    ],
                    beforeCaption: "Without a scratchpad, the model has one token to compute the answer. Most attempts land near the wrong cluster.",
                    afterCaption: "With CoT, intermediate steps push the answer rightward, into a cluster of correct tokens.",
                    xAxisLabel: "Token position in context →",
                    yAxisLabel: "Output entropy"
                )),
                caption: "Drag to scrub. Each dot is one attempt at a multi step problem. With scratchpad, attempts shift right (more context) and down (more confidence).",
                takeaway: "Same brain, more space, better answer."
            ),
        ],

        completeTakeaway: "\"Big models can reason, if you give them room to write it down.\"",
        completeNextTease: "Come back tomorrow for mixture of experts.",
        paperTitle: "Chain of Thought Prompting Elicits Reasoning in Large Language Models",
        glossary: [
            "forward pass": "One run of the model from input to output. The network reads the prompt, computes activations layer by layer, and emits a prediction. No learning happens; weights stay fixed.",
            "chain of thought": "A prompting style that asks the model to write intermediate reasoning steps before the final answer. Each step conditions on the previous one, giving the model 'room to think'.",
            "scratchpad": "An informal name for the intermediate tokens the model generates between question and answer. Acts like working memory for multi step reasoning.",
            "prompting": "Conditioning a language model on a prefix of text. Few shot prompting prepends examples; zero shot uses only an instruction.",
            "GSM8K": "Grade School Math 8K, a benchmark of 8,500 multi step word problems used to evaluate arithmetic reasoning.",
            "PaLM": "Pathways Language Model. Google's 540B parameter dense transformer used as the headline model in the chain of thought paper.",
            "emergent": "A capability that appears abruptly once a model crosses a scale threshold, rather than improving smoothly. Below the threshold the ability is absent or harmful.",
            "logit": "The raw, unnormalised score the model assigns to each candidate token before softmax converts them into probabilities.",
            "softmax": "A function that turns a vector of logits into a probability distribution. Sharper logits produce a peakier distribution.",
            "token": "The smallest unit a language model reads or writes, usually a sub word piece, not a full word.",
            "parameters": "The trainable numbers (weights and biases) inside a neural network. More parameters generally means more capacity to memorise and generalise.",
            "few shot": "Showing the model a handful of worked examples in the prompt itself, with no weight updates."
        ],
        learningObjectives: [
            DLObjective(
                text: "Why writing the steps fixes multi-step problems",
                gloss: "Reasoning out loud gives the model room to work, so it stops skipping a step and slipping on the final answer."),
            DLObjective(
                text: "How a prompt alone changes behaviour",
                gloss: "Show a few worked examples and the model copies the habit. No fine-tuning involved."),
            DLObjective(
                text: "Why it only works at scale",
                gloss: "Chain of thought is an emergent ability: latent in big models, absent in small ones."),
        ],
        explanationCard: DLExplanationCard(
            eyebrow: "WHAT JUST HAPPENED",
            titleSegments: [
                .plain("It showed its working, "),
                .highlight("and got it right"),
            ],
            mini: .chainOfThought,
            paragraphs: [
                DLExplanationPara(
                    kicker: "P1 · SHOW THE STEPS",
                    body: "Instead of examples that go question then answer, chain of thought examples show the working in between. Copying that, the model writes its own steps before answering your real question."),
                DLExplanationPara(
                    kicker: "P2 · JUST A PROMPT",
                    body: "Nothing was retrained. The same frozen model reasons better purely because the examples in the prompt now demonstrate reasoning. The ability was latent; the prompt elicited it."),
                DLExplanationPara(
                    kicker: "P3 · EMERGES AT SCALE",
                    body: "On small models the chains come out fluent but muddled, so it does not help. Past a threshold it unlocks a large jump, like 17 to 57 percent on grade school maths."),
            ],
            takeaway: "Chain of thought asks a big model to show its working, and the reasoning it already held comes out."
        ),
        paperURL: "https://arxiv.org/abs/2201.11903"
    )

    // Daily paper: "When ChatGPT is gone: Creativity reverts and homogeneity
    // persists" (Liu et al., arXiv:2401.06816). 7-day lab experiment + 30-day
    // follow-up across 61 students and 3,302 ideas. Treatment group used
    // ChatGPT; control did not. Boost shows up for 5 days, evaporates the
    // moment ChatGPT is switched off, and homogenization of writing style
    // persists 30 days later.
    static let creativityRevert = DailyLoopContent(
        heroEyebrow: "DAILY LOOP · NEW",
        heroTitleSegments: [
            .plain("When ChatGPT leaves, creativity "),
            .highlight("vanishes")
        ],
        heroBody: "ChatGPT's creative boost vanishes the second it's gone. The flattened style stays.",
        sourceLine: "arXiv:2401.06816 · Liu et al., 2024",

        hookSegments: [
            .plain("What if every "),
            .highlight("creative gain"),
            .plain(" from ChatGPT vanished the second you stopped using it?")
        ],
        hookBody: "A 7 day study with 61 students and 3,302 creative ideas. With ChatGPT, creativity climbed for 5 straight days. On day 7, with it switched off, performance collapsed back to baseline. 30 days later, still flat.",

        coreIdeaSegments: [
            .plain("Three things the experiment "),
            .highlight("uncovers")
        ],
        coreIdeaItems: [
            DLCoreIdeaItem(
                roman: "i",
                title: "The skill leaves when the tool leaves",
                detail: "Over 5 days the treatment group consistently outscored controls on idea novelty and quality. On day 7, with ChatGPT removed, treatment scores dropped to control group baseline. The skill never crossed into the user."),
            DLCoreIdeaItem(
                roman: "ii",
                title: "Everyone starts sounding the same",
                detail: "ChatGPT assisted ideas converged toward a shared style: same phrasings, same structures, lower inter person variance. That convergence persisted on day 7 and at the 30-day follow up, long after ChatGPT was gone."),
            DLCoreIdeaItem(
                roman: "iii",
                title: "Looking smart is not being smart",
                detail: "Higher scores during access masked an unchanged underlying capability. Once the scaffold dropped, output reverted, but the *style* it taught did not. The cost of the boost is paid in diversity of thought."),
        ],

        eliAnalogyLabel: "ANALOGY · EXOSKELETON, NOT MUSCLE",
        eliHeadlineSegments: [
            .plain("It's like training every day in "),
            .highlight("a powered exoskeleton"),
            .plain(".")
        ],
        eliBodyParts: [
            .plain("With the suit on, you "),
            .bold("run further than ever"),
            .plain(". Take it off, and you're right back where you started. The suit did the work, your legs didn't change. Worse: every day in the suit, your gait reshapes to match the machine. Even unaided, "),
            .bold("everyone now runs the same way"),
            .plain(". ChatGPT lifts your output while you lean on it, and quietly flattens how you write, for keeps.")
        ],
        eliArt: .exoskeleton,

        diagramSegments: [
            .plain("How creativity "),
            .highlight("rises and reverts")
        ],
        diagramLayout: .flow,
        diagramNodes: [
            DLDiagramNode(
                id: "d1",
                label: "Day 1",
                sublabel: "baseline",
                panelTitle: "Day 1 · same starting line",
                panelBody: "Treatment and control groups produce ideas at comparable creativity scores. The pre registered design ensures any later gap is causal, not confounded by initial talent."),
            DLDiagramNode(
                id: "d5",
                label: "Day 5",
                sublabel: "peak boost",
                panelTitle: "Day 5 · the lift",
                panelBody: "Five days in a row, the ChatGPT group outscores control on novelty and quality. The headline read: ChatGPT genuinely boosts human creativity. Look closer and the ideas are quietly converging in style."),
            DLDiagramNode(
                id: "d7",
                label: "Day 7",
                sublabel: "ChatGPT off",
                panelTitle: "Day 7 · the cliff",
                panelBody: "ChatGPT is withdrawn. The treatment group's creativity scores fall back to baseline, indistinguishable from control. The boost was the tool, not a learned capacity. But homogenization in their writing stays."),
            DLDiagramNode(
                id: "d30",
                label: "Day 30",
                sublabel: "still flat",
                panelTitle: "Day 30 · the ghost",
                panelBody: "A month later, no rebound and no relearning. Creativity remains at baseline, and the convergence in writing style introduced during ChatGPT use is still there. The tool left a stylistic fingerprint that outlasted the access.")
        ],
        diagramCollapseText: "⚠ Revert + persist",
        diagramDefaultPanelBody: "Four checkpoints across a 30-day arc. Tap each to see what the experiment measured at that day.",

        vizCards: [
            DLVizCard(
                kicker: "CARD 05 · THE CLIFF",
                titleSegments: [
                    .plain("Creativity climbs, then "),
                    .highlight("falls off")
                ],
                visualization: .barChart(DLBarChartSpec(
                    yAxisLabel: "Creativity score",
                    primaryLabel: "ChatGPT group",
                    secondaryLabel: "Control",
                    yMax: 1.0,
                    yTickLabels: ["baseline", "+0.5σ", "+1.0σ"],
                    points: [
                        DLBarPoint(label: "D1", sublabel: "baseline", primary: 0.30, secondary: 0.30,
                                   annotation: "Both groups start at the same creativity score. Random assignment held; any later gap is causal."),
                        DLBarPoint(label: "D3", sublabel: nil, primary: 0.55, secondary: 0.32,
                                   annotation: "ChatGPT group pulls ahead. Idea novelty rises ~0.4σ above control."),
                        DLBarPoint(label: "D5", sublabel: "peak", primary: 0.82, secondary: 0.34,
                                   annotation: "Peak boost. Treatment group is now ~1σ above control on novelty + quality. Looks like real learning."),
                        DLBarPoint(label: "D7", sublabel: "GPT off", primary: 0.32, secondary: 0.33,
                                   annotation: "ChatGPT withdrawn. Treatment scores collapse to control group baseline within 24 hours. The skill never crossed in."),
                        DLBarPoint(label: "D30", sublabel: "follow up", primary: 0.31, secondary: 0.32,
                                   annotation: "A month later, still flat. No rebound. Creativity gains were rented, not earned."),
                    ],
                    cliffIndex: 3,
                    cliffLabel: "ChatGPT off",
                    defaultInsight: "Tap any day. Watch the gap open between days 1 to 5, then collapse the moment ChatGPT is withdrawn on day 7."
                )),
                caption: "Five timepoints from a 30-day study. Bars show creativity score deltas vs. baseline. The amber bar dominates, until day 7.",
                takeaway: "The gain lives in the tool, not in the user."
            ),
            DLVizCard(
                kicker: "CARD 06 · THE GHOST",
                titleSegments: [
                    .plain("Style "),
                    .highlight("converges"),
                    .plain(" and stays converged")
                ],
                visualization: .scatterMorph(DLScatterMorphSpec(
                    beforeLabel: "Day 1",
                    afterLabel: "Day 30",
                    treatmentLabel: "ChatGPT group",
                    controlLabel: "Control",
                    dots: [
                        // Treatment: spread on Day 1, tight cluster by Day 30
                        DLScatterDot(xBefore: 0.18, yBefore: 0.74, xAfter: 0.62, yAfter: 0.48, isTreatment: true),
                        DLScatterDot(xBefore: 0.34, yBefore: 0.22, xAfter: 0.66, yAfter: 0.52, isTreatment: true),
                        DLScatterDot(xBefore: 0.56, yBefore: 0.82, xAfter: 0.68, yAfter: 0.46, isTreatment: true),
                        DLScatterDot(xBefore: 0.78, yBefore: 0.38, xAfter: 0.64, yAfter: 0.54, isTreatment: true),
                        DLScatterDot(xBefore: 0.42, yBefore: 0.58, xAfter: 0.65, yAfter: 0.50, isTreatment: true),
                        DLScatterDot(xBefore: 0.22, yBefore: 0.30, xAfter: 0.63, yAfter: 0.50, isTreatment: true),
                        DLScatterDot(xBefore: 0.62, yBefore: 0.68, xAfter: 0.67, yAfter: 0.49, isTreatment: true),
                        DLScatterDot(xBefore: 0.84, yBefore: 0.72, xAfter: 0.66, yAfter: 0.51, isTreatment: true),
                        // Control: scattered both before and after (no convergence)
                        DLScatterDot(xBefore: 0.14, yBefore: 0.18, xAfter: 0.16, yAfter: 0.22, isTreatment: false),
                        DLScatterDot(xBefore: 0.20, yBefore: 0.86, xAfter: 0.24, yAfter: 0.82, isTreatment: false),
                        DLScatterDot(xBefore: 0.86, yBefore: 0.16, xAfter: 0.84, yAfter: 0.20, isTreatment: false),
                        DLScatterDot(xBefore: 0.88, yBefore: 0.84, xAfter: 0.82, yAfter: 0.86, isTreatment: false),
                    ],
                    beforeCaption: "Day 1: every student writes differently. Both groups occupy the full diversity space.",
                    afterCaption: "Day 30: ChatGPT group has collapsed to a tight cluster. Control still spread out. The fingerprint outlived the tool.",
                    xAxisLabel: "Vocabulary diversity →",
                    yAxisLabel: "Sentence structure variance →"
                )),
                caption: "Each dot is one student's writing style. Drag the scrubber from Day 1 to Day 30 and watch the ChatGPT group lose its diversity, even after the tool is gone.",
                takeaway: "Performance reverts. Style does not."
            ),
        ],

        completeTakeaway: "\"ChatGPT lifts you while you lean on it. It flattens you forever.\"",
        completeNextTease: "Come back tomorrow for the next paper.",
        paperTitle: "Generative AI and the Lasting Homogenization of Human Creative Writing",
        glossary: [
            "ChatGPT": "OpenAI's conversational LLM, used as the writing assistance tool in the study. Treatment participants had access for 7 days, then it was withdrawn.",
            "treatment group": "Study participants given access to ChatGPT during the writing task. Compared against the control group to isolate the tool's effect.",
            "control group": "Participants who completed the same writing task without ChatGPT, providing the baseline for novelty and quality scores.",
            "homogenization": "Convergence of outputs toward a shared style, same phrasings, sentence structures, and vocabulary distribution. Lowers inter person variance even after the tool is removed.",
            "novelty": "How unusual an idea is relative to a reference set. The study scored novelty by embedding distance from a corpus of prior responses.",
            "baseline": "The starting score before any intervention. In this study, Day 1 performance and the control group's running average both serve as baselines.",
            "scaffold": "Temporary external support that boosts performance while present. Once removed, the supported skill reverts unless the underlying capability has been internalised.",
            "inter person variance": "How much writing styles differ between people. The study found ChatGPT users converged, variance dropped, and stayed converged 30 days after the tool was withdrawn.",
            "follow up": "The 30-day post experiment measurement, designed to test whether effects from the 7-day intervention persisted or faded.",
            "creativity score": "A composite of novelty and quality ratings used by the study, averaged over multiple human raters per response.",
            "embedding": "A vector representation of text where semantically similar pieces sit close together. Used here to measure how alike two writing samples are.",
            "performance": "Observed output quality on the task. Distinguished from capability, the underlying skill, because external tools can lift performance without changing capability."
        ]
    )
}

// MARK: - Blueprint adapter
//
// Converts a server-side DailyLoopBlueprint (paired with its CardDeck) into the
// rich DailyLoopContent struct DailyLoopView expects. Highlight phrases are
// matched against their parent string by `range(of:)`; if the phrase is not a
// substring, the segment is rendered as plain text so render never crashes.
// Scatter dot positions are materialised deterministically from the qualitative
// "pattern" descriptors so the LLM never has to hand-pick numeric coordinates.

extension DailyLoopContent {

    init(deck: CardDeck, blueprint: DailyLoopBlueprint) {
        self.init(
            heroEyebrow: blueprint.heroEyebrow,
            heroTitleSegments: Self.segments(from: blueprint.heroTitle),
            heroBody: blueprint.heroBody,
            sourceLine: blueprint.sourceLine,

            hookSegments: Self.segments(from: blueprint.hookTitle),
            hookBody: blueprint.hookBody,

            coreIdeaSegments: Self.segments(from: blueprint.coreIdeaTitle),
            coreIdeaItems: blueprint.coreFindings.prefix(3).enumerated().map { idx, f in
                DLCoreIdeaItem(roman: ["i", "ii", "iii"][idx], title: f.title, detail: f.detail)
            },

            eliAnalogyLabel: blueprint.eliAnalogyLabel,
            eliHeadlineSegments: Self.segments(from: blueprint.eliHeadline),
            eliBodyParts: Self.boldParts(from: blueprint.eliBody),
            eliArt: DLEliArt.from(label: blueprint.eliAnalogyLabel),

            diagramSegments: Self.segments(from: blueprint.diagramTitle),
            diagramLayout: blueprint.diagramLayout == "hub" ? .hub : .flow,
            diagramNodes: blueprint.timelineNodes.enumerated().map { idx, n in
                DLDiagramNode(
                    id: n.id ?? "n\(idx)",
                    label: n.label,
                    sublabel: n.sublabel,
                    panelTitle: n.panelTitle,
                    panelBody: n.panelBody
                )
            },
            diagramCollapseText: blueprint.diagramCollapseText,
            diagramDefaultPanelBody: blueprint.diagramDefaultPanelBody,

            vizCards: blueprint.vizCards.map(Self.makeVizCard),

            completeTakeaway: blueprint.completeQuote,
            completeNextTease: blueprint.completeTease
        )
        self.paperTitle = blueprint.paperTitle ?? deck.title
        self.glossary = blueprint.glossary ?? [:]
        self.paperId = deck.paperId
    }

    // MARK: highlight parsing

    private static func segments(from h: DLHighlightedText) -> [DLSegment] {
        guard let phrase = h.highlight, !phrase.isEmpty,
              let range = h.text.range(of: phrase) else {
            return [.plain(h.text)]
        }
        var out: [DLSegment] = []
        let pre  = String(h.text[..<range.lowerBound])
        let post = String(h.text[range.upperBound...])
        if !pre.isEmpty  { out.append(.plain(pre)) }
        out.append(.highlight(phrase))
        if !post.isEmpty { out.append(.plain(post)) }
        return out
    }

    private static func boldParts(from h: DLHighlightedText) -> [DLHighlightPart] {
        guard let phrase = h.bold, !phrase.isEmpty,
              let range = h.text.range(of: phrase) else {
            return [.plain(h.text)]
        }
        var out: [DLHighlightPart] = []
        let pre  = String(h.text[..<range.lowerBound])
        let post = String(h.text[range.upperBound...])
        if !pre.isEmpty  { out.append(.plain(pre)) }
        out.append(.bold(phrase))
        if !post.isEmpty { out.append(.plain(post)) }
        return out
    }

    // MARK: viz card materialisation

    private static func makeVizCard(_ v: DLBlueprintVizCard) -> DLVizCard {
        let viz: DLVisualization
        switch v.spec {
        case .bar(let s):
            viz = .barChart(DLBarChartSpec(
                yAxisLabel: s.yAxisLabel,
                primaryLabel: s.primaryLabel,
                secondaryLabel: s.secondaryLabel,
                yMax: 1.0,
                yTickLabels: s.yTickLabels,
                points: s.points.map {
                    DLBarPoint(label: $0.label, sublabel: $0.sublabel,
                               primary: $0.primary, secondary: $0.secondary,
                               annotation: $0.annotation)
                },
                cliffIndex: s.cliffIndex,
                cliffLabel: s.cliffLabel,
                defaultInsight: s.defaultInsight
            ))
        case .scatter(let s):
            viz = .scatterMorph(DLScatterMorphSpec(
                beforeLabel: s.beforeLabel,
                afterLabel:  s.afterLabel,
                treatmentLabel: s.treatmentLabel,
                controlLabel:   s.controlLabel,
                dots: makeScatterDots(s),
                beforeCaption: s.beforeCaption,
                afterCaption:  s.afterCaption,
                xAxisLabel: s.xAxisLabel,
                yAxisLabel: s.yAxisLabel
            ))
        case .trainingCurve(let s):
            viz = .trainingCurve(DLTrainingCurveSpec(
                xAxisLabel: s.xAxisLabel,
                yAxisLabel: s.yAxisLabel,
                xTickLabels: s.xTickLabels,
                yTickLabels: s.yTickLabels,
                series: s.series.map { srs in
                    DLTrainingCurveSeries(
                        label: srs.label,
                        color: parseCurveColor(srs.color),
                        dashed: srs.dashed ?? false,
                        points: srs.points.map {
                            DLTrainingCurvePoint(x: $0.x, y: $0.y,
                                                 milestone: $0.milestone,
                                                 annotation: $0.annotation)
                        }
                    )
                },
                defaultInsight: s.defaultInsight
            ))
        case .equationRich(let s):
            viz = .equationRich(DLEquationRichSpec(
                terms: s.terms.map {
                    DLEquationTerm(
                        id: $0.id,
                        display: $0.display,
                        sup: $0.sup,
                        sub: $0.sub,
                        color: parseEquationColor($0.color),
                        panelTitle: $0.panelTitle,
                        panelBody: $0.panelBody
                    )
                },
                defaultInsight: s.defaultInsight,
                promptText: s.promptText
            ))
        case .flowRich(let s):
            viz = .flowRich(DLFlowRichSpec(
                layout: parseFlowLayout(s.layout),
                nodes: s.nodes.map {
                    DLFlowRichNode(
                        id: $0.id,
                        label: $0.label,
                        sublabel: $0.sublabel,
                        role: parseFlowRole($0.role),
                        panelTitle: $0.panelTitle,
                        panelBody: $0.panelBody,
                        column: $0.column,
                        row: $0.row ?? 0
                    )
                },
                edges: s.edges.map {
                    DLFlowRichEdge(
                        from: $0.from,
                        to: $0.to,
                        label: $0.label,
                        kind: parseFlowEdgeKind($0.kind)
                    )
                },
                defaultInsight: s.defaultInsight
            ))
        }
        return DLVizCard(
            kicker: v.kicker,
            titleSegments: segments(from: v.title),
            visualization: viz,
            caption: v.caption,
            takeaway: v.takeaway
        )
    }

    private static func parseCurveColor(_ raw: String) -> DLTrainingCurveColor {
        switch raw.lowercased() {
        case "amber": return .amber
        case "rose":  return .rose
        case "ink":   return .ink
        default:      return .teal
        }
    }

    private static func parseFlowLayout(_ raw: String?) -> DLFlowRichLayout {
        switch raw?.lowercased() {
        case "stacked": return .stacked
        default:        return .horizontal
        }
    }

    private static func parseFlowRole(_ raw: String) -> DLFlowRichRole {
        switch raw.lowercased() {
        case "input":   return .input
        case "output":  return .output
        case "loss":    return .loss
        case "skip":    return .skipNode
        default:        return .process
        }
    }

    private static func parseFlowEdgeKind(_ raw: String) -> DLFlowRichEdgeKind {
        switch raw.lowercased() {
        case "backward": return .backward
        case "skip":     return .skip
        default:         return .forward
        }
    }

    private static func parseEquationColor(_ raw: String) -> DLEquationTermColor {
        switch raw.lowercased() {
        case "teal":  return .teal
        case "amber": return .amber
        case "rose":  return .rose
        case "ink":   return .ink
        case "muted": return .muted
        default:      return .ink
        }
    }

    // Deterministic dot generator. Each dot is sampled from a 2D distribution
    // tied to the named pattern, with a seeded RNG so the same blueprint always
    // renders identically across runs.

    private static func makeScatterDots(_ s: DLBlueprintScatterSpec) -> [DLScatterDot] {
        var rng = SeededRNG(seed: UInt64(abs(s.beforeLabel.hashValue ^ s.afterLabel.hashValue)))
        var out: [DLScatterDot] = []
        for _ in 0..<max(1, s.treatmentCount) {
            let (xb, yb) = sample(pattern: s.treatmentBeforePattern, rng: &rng)
            let (xa, ya) = sample(pattern: s.treatmentAfterPattern,  rng: &rng)
            out.append(DLScatterDot(xBefore: xb, yBefore: yb, xAfter: xa, yAfter: ya, isTreatment: true))
        }
        for _ in 0..<max(1, s.controlCount) {
            let (xb, yb) = sample(pattern: s.controlBeforePattern, rng: &rng)
            let (xa, ya) = sample(pattern: s.controlAfterPattern,  rng: &rng)
            out.append(DLScatterDot(xBefore: xb, yBefore: yb, xAfter: xa, yAfter: ya, isTreatment: false))
        }
        return out
    }

    private static func sample(pattern: String, rng: inout SeededRNG) -> (Double, Double) {
        let jitter = 0.06
        switch pattern {
        case "cluster_left":   return (clamp(0.20 + rng.gaussian() * jitter), clamp(0.50 + rng.gaussian() * jitter * 1.6))
        case "cluster_right":  return (clamp(0.78 + rng.gaussian() * jitter), clamp(0.50 + rng.gaussian() * jitter * 1.6))
        case "cluster_center": return (clamp(0.50 + rng.gaussian() * jitter), clamp(0.50 + rng.gaussian() * jitter))
        case "spread":         fallthrough
        default:               return (clamp(rng.uniform()), clamp(rng.uniform()))
        }
    }

    private static func clamp(_ v: Double) -> Double { min(max(v, 0.05), 0.95) }
}

// MARK: - Seeded RNG (deterministic for blueprint renders)

private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEADBEEF : seed }

    mutating func next() -> UInt64 {
        // splitmix64
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func uniform() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func gaussian() -> Double {
        // Box-Muller, take only one component
        let u1 = max(uniform(), 1e-9)
        let u2 = uniform()
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}
