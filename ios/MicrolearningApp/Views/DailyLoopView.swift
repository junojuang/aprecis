import SwiftUI

// MARK: - Colors local to the Daily Loop

private let dlTealBright = Color(hex: "5fd4d4")
private let dlTealDeep   = Color(hex: "0f5a5a")
private let dlAmberLight = Color(hex: "fbf1dc")
private let dlAmberDeep  = Color(hex: "7a5310")
private let dlRose       = Color(hex: "d46a6a")
private let dlRoseLight  = Color(hex: "fbe8e8")
private let dlGreen      = Color(hex: "4a9c4a")
private let dlGreenLight = Color(hex: "ecf7ec")
private let dlPaper2     = Color(hex: "efeae1")
private let dlPaper3     = Color(hex: "e6e1d6")
private let dlLine       = Color(hex: "e6e1d6")
private let dlInk2       = Color(hex: "2a2d36")
private let dlInk3       = Color(hex: "4a4e58")

// MARK: - Inline glossary

// Renders body text with glossary terms underlined and tappable. Tapping a
// term surfaces a Kindle-style bottom sheet with its definition.
struct GlossText: View {
    let raw: String
    let glossary: [String: String]
    var font: Font = .system(size: 14, design: .serif)
    var color: Color = dlInk3
    var lineSpacing: CGFloat = 4

    @State private var hit: DLGlossaryHit?

    var body: some View {
        Text(dlGlossarise(raw, glossary: glossary))
            .font(font)
            .foregroundStyle(color)
            .tint(dlTealDeep)
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "aprecis", url.host == "gloss" else { return .systemAction }
                let raw = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
                let key = glossary.keys.first { $0.caseInsensitiveCompare(raw) == .orderedSame } ?? raw
                if let def = glossary[key] {
                    hit = DLGlossaryHit(term: key, definition: def)
                    return .handled
                }
                return .systemAction
            })
            .sheet(item: $hit) { entry in
                VStack(alignment: .leading, spacing: 12) {
                    Text(entry.term.capitalized)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(dlInk2)
                    Text(entry.definition)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(dlInk3)
                        .lineSpacing(4)
                    Spacer(minLength: 0)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .presentationDetents([.fraction(0.28), .medium])
                .presentationDragIndicator(.visible)
            }
    }
}

// MARK: - Segmented-text helpers

/// Renders `[.plain, .highlight, ...]` segments as a single Text with italic
/// + accent runs for the highlighted pieces.
private func segmentedText(
    _ segments: [DLSegment],
    highlight: Color
) -> Text {
    segments.reduce(Text("")) { acc, seg in
        switch seg {
        case .plain(let s):
            return acc + Text(s)
        case .highlight(let s):
            return acc + Text(s).italic().foregroundColor(highlight)
        }
    }
}

// MARK: - Action hint
//
// Sits adjacent to an interactive control inside a studio view so the reader
// can see at a glance which element accepts input. Dashed teal pill with a
// small eyebrow, an imperative line in italic serif, and an animated chevron
// pointing at the control. Optional `done` flag dims the hint once the user
// has completed the requested interaction, so it stops competing for
// attention on a second pass.
//
// Place ABOVE the control it refers to. Keep imperative short (≤7 words).

struct DLActionHint: View {
    let text: String
    var eyebrow: String = "TRY THIS"
    var icon: String = "arrow.down"
    var tint: Color = tealAccent
    var done: Bool = false

    @State private var bob: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tint)
                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(inkColor.opacity(0.82))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: done ? "checkmark" : icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(done ? Color(hex: "4a9c4a") : tint)
                .offset(y: (done || !bob) ? -1 : 3)
                .animation(
                    done
                        ? .default
                        : .easeInOut(duration: 0.95).repeatForever(autoreverses: true),
                    value: bob
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(done ? 0.04 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tint.opacity(done ? 0.18 : 0.32),
                                style: StrokeStyle(lineWidth: 1, dash: done ? [] : [3, 3]))
                )
        )
        .opacity(done ? 0.55 : 1.0)
        .onAppear { bob = true }
    }
}

// MARK: - Slot model
//
// The Daily Loop is a 7-card flow for most papers and an 8-card flow for the
// foundational bundle (which inserts an explanation card after the diagram).
// The view routes on slot, not raw index, so studio routing, gating, and the
// bottom button stay readable as the deck length changes.

enum DLSlot { case hook, core, eli, diagram, explain, viz1, viz2, complete }

// MARK: - State

final class DailyLoopState: ObservableObject {
    @Published var index: Int = 0
    @Published var startTime: Date = Date()

    @Published var openedAccordions: Set<Int> = []
    @Published var visitedNodes: Set<String> = []
    @Published var activeNode: String? = nil

    // Bespoke per-paper card slots can flip these when the reader has explored
    // enough to advance. Generic cards continue to gate via the rules below.
    @Published var customCardComplete: Set<Int> = []

    // Viz interaction state, keyed by deck index (4 = first viz card, 5 = second).
    @Published var vizActiveBar: [Int: Int] = [:]
    @Published var vizMorphProgress: [Int: Double] = [:]
    @Published var vizCurveSelection: [Int: CurveSelection] = [:]
    @Published var vizFlowSelection: [Int: String] = [:]
    @Published var vizEquationSelection: [Int: String] = [:]
    @Published var vizExplored: Set<Int> = []

    struct CurveSelection: Hashable { let series: Int; let point: Int }

    let totalVisitableNodes: Int
    let hasExplanation: Bool

    init(content: DailyLoopContent) {
        self.totalVisitableNodes = content.diagramNodes.count
        self.hasExplanation = content.explanationCard != nil
    }

    private var slotOrder: [DLSlot] {
        hasExplanation
            ? [.hook, .core, .eli, .diagram, .explain, .viz1, .viz2, .complete]
            : [.hook, .core, .eli, .diagram, .viz1, .viz2, .complete]
    }

    var lastIndex: Int { slotOrder.count - 1 }

    var currentSlot: DLSlot { slot(at: index) }

    func slot(at idx: Int) -> DLSlot {
        let bounded = max(0, min(idx, slotOrder.count - 1))
        return slotOrder[bounded]
    }

    func canAdvance() -> Bool {
        if customCardComplete.contains(index) { return true }
        switch currentSlot {
        case .hook, .eli, .explain, .viz1, .viz2: return true
        case .core:    return openedAccordions.count == 3
        case .diagram: return visitedNodes.count == totalVisitableNodes
        case .complete: return false
        }
    }

    var elapsed: String {
        let s = Int(Date().timeIntervalSince(startTime))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    func reset() {
        index = 0
        startTime = Date()
        openedAccordions.removeAll()
        visitedNodes.removeAll()
        activeNode = nil
        customCardComplete.removeAll()
        vizActiveBar.removeAll()
        vizMorphProgress.removeAll()
        vizCurveSelection.removeAll()
        vizFlowSelection.removeAll()
        vizEquationSelection.removeAll()
        vizExplored.removeAll()
    }
}

// MARK: - Root

struct DailyLoopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var savedStore = SavedPapersStore.shared
    @StateObject private var state: DailyLoopState
    let content: DailyLoopContent

    init(content: DailyLoopContent = .transformer) {
        self.content = content
        _state = StateObject(wrappedValue: DailyLoopState(content: content))
    }

    var body: some View {
        ZStack {
            // Background changes per card
            backgroundFor(state.index)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: state.index)

            VStack(spacing: 0) {
                progressRail
                topBar
                ZStack {
                    let isGPT3 = (content.paperTitle ?? "").contains("GPT-3")
                    let isAttention = (content.paperTitle ?? "").contains("Attention Is All")
                    let isResNet = (content.paperTitle ?? "").contains("Deep Residual")
                    let isGAN = (content.paperTitle ?? "").contains("Generative Adversarial")
                    let isWord2Vec = (content.paperTitle ?? "").contains("Word Representations")
                    let isAlexNet = (content.paperTitle ?? "").contains("ImageNet Classification")
                    let isSeq2Seq = (content.paperTitle ?? "").contains("Sequence to Sequence")
                    let isPerceptron = (content.paperTitle ?? "").contains("Perceptron")
                    let isBackprop = (content.paperTitle ?? "").contains("Back Propagating")
                    let isLeNet = (content.paperTitle ?? "").contains("LeNet")
                    switch state.currentSlot {
                    case .hook:    HookCard(state: state, content: content, dismiss: dismiss)
                    case .core:    CoreIdeaCard(state: state, content: content)
                    case .eli:     EliCard(state: state, content: content)
                    case .diagram:
                        if isGPT3 { GPT3PromptShotsView(state: state) }
                        else if isAttention { AttentionFlowView(state: state) }
                        else if isResNet { ResNetBlockView(state: state) }
                        else if isGAN { GANRoundView(state: state) }
                        else if isWord2Vec { Word2VecVectorView(state: state) }
                        else if isAlexNet { AlexNetAblationView(state: state) }
                        else if isSeq2Seq { Seq2SeqPipelineView(state: state) }
                        else if isPerceptron { PerceptronBoundaryView(state: state) }
                        else if isBackprop { BackpropFlowView(state: state) }
                        else if isLeNet { LeNetFilterView(state: state) }
                        else { DiagramCard(state: state, content: content) }
                    case .explain:
                        ExplanationCard(state: state, content: content)
                    case .viz1:
                        if isGPT3 { GPT3ScaleEmergenceView(state: state) }
                        else if isAttention { AttentionCorefView(state: state) }
                        else if isResNet { ResNetDepthView(state: state) }
                        else if isGAN { GANConvergenceView(state: state) }
                        else if isWord2Vec { Word2VecNegSamplingView(state: state) }
                        else if isAlexNet { AlexNetReluRaceView(state: state) }
                        else if isSeq2Seq { Seq2SeqLengthView(state: state) }
                        else if isPerceptron { PerceptronXORView(state: state) }
                        else if isBackprop { BackpropChainRuleView(state: state) }
                        else if isLeNet { LeNetReceptiveView(state: state) }
                        else { VizCardView(state: state, content: content, slot: 0, deckIndex: 4) }
                    case .viz2:
                        if isAttention { AttentionPathLengthView(state: state) }
                        else if isResNet { ResNetGradientView(state: state) }
                        else if isGAN { GANModeCollapseView(state: state) }
                        else if isWord2Vec { Word2VecArchView(state: state) }
                        else if isAlexNet { AlexNetCliffView(state: state) }
                        else if isSeq2Seq { Seq2SeqReverseView(state: state) }
                        else if isPerceptron { PerceptronAnatomyView(state: state) }
                        else if isBackprop { BackpropCreditView(state: state) }
                        else if isLeNet { LeNetParamView(state: state) }
                        else { VizCardView(state: state, content: content, slot: 1, deckIndex: 5) }
                    case .complete:
                        CompleteCard(state: state, content: content, dismiss: dismiss)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if state.index < state.lastIndex {
                    bottomBar
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { v in
                    let dx = v.translation.width
                    let dy = v.translation.height
                    let horizontal = abs(dx) > abs(dy)
                    // Horizontal swipe: left = advance, right = back.
                    // Vertical swipe-up on hook still advances (legacy).
                    if horizontal && dx < -70 && state.index < state.lastIndex {
                        advance()
                    } else if horizontal && dx > 70 && state.index > 0 {
                        back()
                    } else if state.index == 0 && dy < -50 {
                        advance()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let pid = content.paperId {
                RecentlyViewedStore.shared.record(pid)
            }
        }
    }

    private func backgroundFor(_ idx: Int) -> some View {
        let slot = state.slot(at: idx)
        return Group {
            switch slot {
            case .hook:
                // Editorial cream cover. Soft teal glow anchored upper-right
                // (where the watermark italic 'a' sits), faint amber wash at
                // the bottom, and an oversized italic 'a' watermark at very
                // low opacity. Echoes the home page hero card so the entry
                // experience feels continuous with the catalog.
                ZStack(alignment: .topTrailing) {
                    paperBg

                    RadialGradient(
                        colors: [tealAccent.opacity(0.16), .clear],
                        center: UnitPoint(x: 0.82, y: 0.18),
                        startRadius: 0, endRadius: 380
                    )

                    RadialGradient(
                        colors: [amberAccent.opacity(0.10), .clear],
                        center: UnitPoint(x: 0.5, y: 1.05),
                        startRadius: 0, endRadius: 360
                    )

                    Text("a")
                        .font(.system(size: 320, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(tealAccent.opacity(0.07))
                        .offset(x: 60, y: -90)
                        .allowsHitTesting(false)
                }
            case .complete:
                ZStack {
                    paperBg
                    RadialGradient(
                        colors: [amberAccent.opacity(0.18), .clear],
                        center: .top, startRadius: 0, endRadius: 320
                    )
                    RadialGradient(
                        colors: [tealAccent.opacity(0.15), .clear],
                        center: .bottom, startRadius: 0, endRadius: 280
                    )
                }
            default:
                paperBg
            }
        }
    }

    // Thin rail flush to the top edge, a continuous fill reflects lesson
    // progress like a book's bookmark, avoiding the stop-start feel of dots.
    private var progressRail: some View {
        let dark = false
        let total: Double = Double(state.lastIndex)
        let filled = min(Double(state.index) / total + 0.02, 1.0)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(dark ? Color.white.opacity(0.08) : dlLine)
                Rectangle()
                    .fill(dark ? dlTealBright : tealAccent)
                    .frame(width: geo.size.width * CGFloat(filled))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: state.index)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private var topBar: some View {
        let dark = false
        HStack(spacing: 12) {
            Button {
                if state.index == 0 { dismiss() } else { back() }
            } label: {
                Image(systemName: state.index == 0 ? "xmark" : "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(dark ? Color.white : inkColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(dark ? Color.white.opacity(0.12) : dlPaper2)
                    )
            }

            Spacer()

        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button {
                advance()
            } label: {
                HStack(spacing: 8) {
                    Text(nextButtonText)
                        .font(.system(size: 14, weight: .bold))
                    if state.canAdvance() {
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(state.canAdvance() ? paperBg : mutedText)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(state.canAdvance() ? inkColor : dlPaper3)
                )
            }
            .disabled(!state.canAdvance())

            if let pid = content.paperId {
                loopBookmarkIconButton(paperId: pid)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .padding(.top, 10)
    }

    private func loopBookmarkIconButton(paperId: String) -> some View {
        let saved = savedStore.isSaved(paperId)
        return Button {
            savedStore.toggleOrPromptSignIn(paperId)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(saved ? tealAccent : inkColor)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(saved ? "Remove from library" : "Save to library")
    }

    private var nextButtonText: String {
        let isGPT3 = (content.paperTitle ?? "").contains("GPT-3")
        let isAttention = (content.paperTitle ?? "").contains("Attention Is All")
        let isResNet = (content.paperTitle ?? "").contains("Deep Residual")
        let isGAN = (content.paperTitle ?? "").contains("Generative Adversarial")
        let isWord2Vec = (content.paperTitle ?? "").contains("Word Representations")
        let isAlexNet = (content.paperTitle ?? "").contains("ImageNet Classification")
        let isSeq2Seq = (content.paperTitle ?? "").contains("Sequence to Sequence")
        let isPerceptron = (content.paperTitle ?? "").contains("Perceptron")
        let isBackprop = (content.paperTitle ?? "").contains("Back Propagating")
        let isLeNet = (content.paperTitle ?? "").contains("LeNet")
        switch state.currentSlot {
        case .hook: return "Start learning"
        case .core: return state.canAdvance() ? "Got it" : "Open all three to continue"
        case .eli:  return "Continue"
        case .diagram:
            if isGPT3 { return state.canAdvance() ? "Nice, next" : "Try every shot count to continue" }
            if isAttention { return state.canAdvance() ? "Nice, next" : "Tap every token to continue" }
            if isResNet { return state.canAdvance() ? "Nice, next" : "Tap each target to continue" }
            if isGAN { return state.canAdvance() ? "Nice, next" : "Play 5 rounds to continue" }
            if isWord2Vec { return state.canAdvance() ? "Nice, next" : "Tap words across clusters or play the analogy" }
            if isAlexNet { return state.canAdvance() ? "Nice, next" : "Toggle each of the five tricks to continue" }
            if isSeq2Seq { return state.canAdvance() ? "Nice, next" : "Tap every stage to continue" }
            if isPerceptron { return state.canAdvance() ? "Nice, next" : "Tap STEP three times to continue" }
            if isBackprop { return state.canAdvance() ? "Nice, next" : "Tap every node to continue" }
            if isLeNet { return state.canAdvance() ? "Nice, next" : "Try every filter and drag the kernel to continue" }
            let total = state.totalVisitableNodes
            return state.canAdvance() ? "Nice, next" : "Tap each node (\(state.visitedNodes.count)/\(total))"
        case .explain:
            return "Continue"
        case .viz1:
            if isGPT3 { return state.canAdvance() ? "Continue" : "Drag through every size to continue" }
            if isAttention { return "Continue" }
            if isResNet { return "Continue" }
            if isGAN { return "Continue" }
            if isWord2Vec { return state.canAdvance() ? "Continue" : "Try at least three K stops" }
            if isAlexNet { return state.canAdvance() ? "Continue" : "Tap each activation to compare" }
            if isSeq2Seq { return state.canAdvance() ? "Continue" : "Drag the dial across at least three lengths" }
            if isPerceptron { return state.canAdvance() ? "Continue" : "Toggle AND, OR, XOR to continue" }
            if isBackprop { return state.canAdvance() ? "Continue" : "Drag the input across six stops" }
            if isLeNet { return state.canAdvance() ? "Continue" : "Tap every layer to continue" }
            return "Continue"
        case .viz2:
            if isWord2Vec { return state.canAdvance() ? "Finish deck" : "Toggle CBOW and Skip-Gram to finish" }
            if isAlexNet { return state.canAdvance() ? "Finish deck" : "Tap every year to finish" }
            if isSeq2Seq { return state.canAdvance() ? "Finish deck" : "Toggle Forward and Reversed to finish" }
            if isPerceptron { return state.canAdvance() ? "Finish deck" : "Tap each of the five parts to finish" }
            if isBackprop { return state.canAdvance() ? "Finish deck" : "Slide the epoch dial to finish" }
            if isLeNet { return state.canAdvance() ? "Finish deck" : "Toggle Conv and Dense to finish" }
            return "Finish deck"
        case .complete:
            return ""
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            if state.canAdvance() { state.index = min(state.index + 1, state.lastIndex) }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func back() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
            state.index = max(state.index - 1, 0)
        }
    }
}

// MARK: - Card 1, Hook (editorial cover)
//
// Opens the loop with the same editorial cover language as the home hero,
// giving the flow a "book turning" feel, the home peek becomes the real
// cover before the chapters begin. Empathy lever: the YOU'LL LEARN bullets
// show what's inside before the reader commits to page 2.

private struct HookCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent
    let dismiss: DismissAction

    private let subtle = Color(hex: "4a4e58")        // soft ink for body copy
    private let dim    = Color(hex: "8a8f9a")        // muted for eyebrow meta
    private let rule   = Color(hex: "d8d2c4")        // hairline on cream

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Eyebrow: small teal dot + category caps. Read-time meta sits
                // on the trailing edge as humble dim caps so it integrates with
                // the eyebrow rather than floating as a chip.
                HStack(spacing: 6) {
                    Circle()
                        .fill(tealAccent)
                        .frame(width: 5, height: 5)
                    Text(content.heroEyebrow)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(tealAccent)
                    Spacer()
                    Text("\(content.estimatedMinutes) MIN")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .tracking(1.4)
                        .foregroundStyle(dim)
                }
                .padding(.bottom, 14)

                // Ornament rule, thin line flanking a small accent dot
                HStack(spacing: 8) {
                    Rectangle().fill(rule).frame(height: 1)
                    Circle().fill(tealAccent.opacity(0.7)).frame(width: 4, height: 4)
                    Rectangle().fill(rule).frame(height: 1)
                }
                .padding(.bottom, 22)

                // Italic serif title, dark ink on cream for readability
                segmentedText(content.heroTitleSegments, highlight: tealAccent)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 14)

                GlossText(raw: content.heroBody,
                          glossary: content.glossary,
                          font: .system(size: 13, design: .serif),
                          color: subtle,
                          lineSpacing: 4)
                    .padding(.bottom, 26)

                Rectangle().fill(rule).frame(height: 1).padding(.bottom, 18)

                Text("BY THE END YOU'LL KNOW")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(dim)
                    .padding(.bottom, 12)

                // Prefer the curated learningObjectives (foundational bundle).
                // Fall back to coreIdeaItems.title for every other loop, which
                // still gives the reader a 3-bullet preview before they commit.
                VStack(alignment: .leading, spacing: 12) {
                    if let objs = content.learningObjectives, !objs.isEmpty {
                        ForEach(Array(objs.enumerated()), id: \.offset) { _, obj in
                            objectiveRow(text: obj.text, gloss: obj.gloss)
                        }
                    } else {
                        ForEach(Array(content.coreIdeaItems.enumerated()), id: \.offset) { _, item in
                            objectiveRow(text: item.title, gloss: nil)
                        }
                    }
                }
                .padding(.bottom, 28)

                if let paperTitle = content.paperTitle, !paperTitle.isEmpty {
                    Text(paperTitle)
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundStyle(dim)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    // Single objective bullet. Title in serif ink, optional one-line gloss in
    // muted serif underneath. Used for both `learningObjectives` (foundational
    // bundle) and the legacy fallback that mirrors coreIdeaItems.title.
    @ViewBuilder
    private func objectiveRow(text: String, gloss: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tealAccent.opacity(0.85))
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let g = gloss, !g.isEmpty {
                    Text(g)
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundStyle(subtle)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Card 2, Core Idea (chapter opener)
//
// Chapter-style opener: oversized serif "01" anchors the page like a book
// chapter, teal eyebrow labels the section, and the first core-idea item
// becomes an italic pull-quote above the accordion. The accordion stays as
// the engagement lever (open all 3 to advance), a gentle, Duolingo-like
// micro-interaction that beats a passive scroll.

private struct CoreIdeaCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row: big chapter numeral + eyebrow stack on the right
                HStack(alignment: .center, spacing: 16) {
                    Text("01")
                        .font(.system(size: 64, weight: .regular, design: .serif))
                        .foregroundStyle(inkColor.opacity(0.88))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("THE CORE IDEA")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.6)
                            .foregroundStyle(tealAccent)
                        Text("\(content.coreIdeaItems.count) ideas behind the paper. Tap each to expand.")
                            .font(.system(size: 12, design: .serif))
                            .italic()
                            .foregroundStyle(mutedText)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 18)

                // Italic serif title, the chapter's thesis
                segmentedText(content.coreIdeaSegments, highlight: tealAccent)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18)

                // Progress pip row
                HStack(alignment: .center, spacing: 10) {
                    Text("\(state.openedAccordions.count) of 3 opened")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(mutedText)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(dlPaper2)
                            Capsule()
                                .fill(tealAccent)
                                .frame(width: geo.size.width * CGFloat(state.openedAccordions.count) / 3)
                                .animation(.spring(response: 0.35), value: state.openedAccordions.count)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.bottom, 16)

                VStack(spacing: 10) {
                    ForEach(Array(content.coreIdeaItems.enumerated()), id: \.offset) { i, item in
                        AccordionRow(
                            roman: item.roman,
                            title: item.title,
                            detail: item.detail,
                            glossary: content.glossary,
                            isOpen: state.openedAccordions.contains(i)
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if state.openedAccordions.contains(i) {
                                    state.openedAccordions.remove(i)
                                } else {
                                    state.openedAccordions.insert(i)
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }
}

private struct AccordionRow: View {
    let roman: String
    let title: String
    let detail: String
    let glossary: [String: String]
    let isOpen: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(isOpen ? tealAccent : dlPaper2)
                            .frame(width: 28, height: 28)
                        Text(roman)
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(isOpen ? .white : mutedText)
                    }
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(inkColor)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(mutedText)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }

                if isOpen {
                    GlossText(raw: detail,
                              glossary: glossary,
                              font: .system(size: 12),
                              color: dlInk3,
                              lineSpacing: 4)
                        .padding(.top, 10)
                        .padding(.leading, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(dlLine, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card 3, ELI5

private struct EliCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Illustration
                VStack(spacing: 0) {
                    Group {
                        switch content.eliArt {
                        case .megaphone:    MegaphoneArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .scratchPaper: ScratchPaperArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .magnifier:    MagnifierArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .kitchen:      KitchenArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .map:          MapArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .whisper:      WhisperArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .forger:       ForgerArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .exit:         ExitArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .readers:      ReadersArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .librarian:    LibrarianArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .exoskeleton:  ExoskeletonArt().stroke(dlAmberDeep, lineWidth: 2)
                        case .bouncer:      BouncerArt().stroke(dlAmberDeep, lineWidth: 2)
                        }
                    }
                    .frame(width: 200, height: 120)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Rectangle()
                        .fill(dlAmberDeep.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)

                    Text(content.eliAnalogyLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(dlAmberDeep.opacity(0.75))
                        .padding(.bottom, 12)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18).fill(dlAmberLight))
                .padding(.horizontal, 16)
                .padding(.bottom, 18)

                segmentedText(content.eliHeadlineSegments, highlight: dlAmberDeep)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineSpacing(3)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                HighlightedBody(parts: content.eliBodyParts)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .padding(.top, 8)
        }
    }
}

private struct HighlightedBody: View {
    let parts: [DLHighlightPart]
    var body: some View {
        var text = Text("")
        for p in parts {
            switch p {
            case .plain(let s):
                text = text + Text(s)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(dlInk3)
            case .bold(let s):
                text = text + Text(s)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(inkColor)
            }
        }
        return text.lineSpacing(5)
    }
}

private struct MegaphoneArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Mic body (rect)
        let body = CGRect(x: rect.width*0.32, y: rect.height*0.36, width: rect.width*0.3, height: rect.height*0.28)
        p.addRoundedRect(in: body, cornerSize: CGSize(width: 8, height: 8))
        // Horn (triangle)
        p.move(to: CGPoint(x: rect.width*0.62, y: rect.height*0.42))
        p.addLine(to: CGPoint(x: rect.width*0.82, y: rect.height*0.30))
        p.addLine(to: CGPoint(x: rect.width*0.82, y: rect.height*0.70))
        p.addLine(to: CGPoint(x: rect.width*0.62, y: rect.height*0.58))
        p.closeSubpath()
        // Sound waves
        for (x, y) in [(0.15, 0.22), (0.20, 0.78), (0.85, 0.18), (0.90, 0.85)] {
            p.addEllipse(in: CGRect(
                x: rect.width*x-10, y: rect.height*y-10, width: 20, height: 20
            ))
        }
        return p
    }
}

/// Scratch-paper illustration: notepad with a curled top, three horizontal
/// rule-lines, and a short pencil resting on the right. Used as the ELI5 art
/// for chain-of-thought (the "space to think" metaphor).
private struct ScratchPaperArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Pad body
        let pad = CGRect(x: w*0.22, y: h*0.22, width: w*0.46, height: h*0.64)
        p.addRoundedRect(in: pad, cornerSize: CGSize(width: 8, height: 8))
        // Curl tab on top
        let tab = CGRect(x: w*0.30, y: h*0.14, width: w*0.30, height: h*0.10)
        p.addRoundedRect(in: tab, cornerSize: CGSize(width: 4, height: 4))
        // Rule lines
        for i in 0..<3 {
            let y = h*0.40 + CGFloat(i) * h*0.14
            p.move(to: CGPoint(x: w*0.28, y: y))
            p.addLine(to: CGPoint(x: w*0.62, y: y))
        }
        // Pencil shaft
        p.move(to: CGPoint(x: w*0.70, y: h*0.36))
        p.addLine(to: CGPoint(x: w*0.90, y: h*0.56))
        // Pencil tip
        p.move(to: CGPoint(x: w*0.88, y: h*0.50))
        p.addLine(to: CGPoint(x: w*0.94, y: h*0.60))
        p.addLine(to: CGPoint(x: w*0.86, y: h*0.62))
        p.closeSubpath()
        // Scribble mark to the left of the pad
        for (x, y) in [(0.12, 0.30), (0.10, 0.70), (0.80, 0.82)] {
            p.addEllipse(in: CGRect(
                x: w*x-8, y: h*y-8, width: 16, height: 16
            ))
        }
        return p
    }
}

// MARK: - ELI5 art per analogy

private struct MagnifierArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let lens = CGRect(x: w*0.18, y: h*0.18, width: w*0.50, height: h*0.50)
        p.addEllipse(in: lens)
        p.addEllipse(in: lens.insetBy(dx: w*0.06, dy: h*0.06))
        p.move(to: CGPoint(x: w*0.62, y: h*0.62))
        p.addLine(to: CGPoint(x: w*0.92, y: h*0.92))
        p.move(to: CGPoint(x: w*0.86, y: h*0.86))
        p.addLine(to: CGPoint(x: w*0.96, y: h*0.96))
        for (x, y) in [(0.30, 0.36), (0.50, 0.34), (0.40, 0.50)] {
            p.addEllipse(in: CGRect(x: w*x-3, y: h*y-3, width: 6, height: 6))
        }
        return p
    }
}

private struct KitchenArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let pot = CGRect(x: w*0.28, y: h*0.46, width: w*0.40, height: h*0.34)
        p.addRoundedRect(in: pot, cornerSize: CGSize(width: 4, height: 4))
        p.move(to: CGPoint(x: w*0.24, y: h*0.50))
        p.addLine(to: CGPoint(x: w*0.20, y: h*0.50))
        p.move(to: CGPoint(x: w*0.72, y: h*0.50))
        p.addLine(to: CGPoint(x: w*0.76, y: h*0.50))
        p.move(to: CGPoint(x: w*0.26, y: h*0.46))
        p.addLine(to: CGPoint(x: w*0.70, y: h*0.46))
        for (x, off) in [(0.38, 0.0), (0.48, 0.05), (0.58, 0.0)] {
            p.move(to: CGPoint(x: w*x, y: h*(0.36 + off)))
            p.addCurve(
                to: CGPoint(x: w*x, y: h*0.20),
                control1: CGPoint(x: w*(x-0.04), y: h*0.30),
                control2: CGPoint(x: w*(x+0.04), y: h*0.26)
            )
        }
        let burner = CGRect(x: w*0.24, y: h*0.84, width: w*0.48, height: h*0.06)
        p.addRoundedRect(in: burner, cornerSize: CGSize(width: 3, height: 3))
        return p
    }
}

private struct MapArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let map = CGRect(x: w*0.16, y: h*0.22, width: w*0.68, height: h*0.58)
        p.addRect(map)
        p.move(to: CGPoint(x: w*0.39, y: h*0.22))
        p.addLine(to: CGPoint(x: w*0.39, y: h*0.80))
        p.move(to: CGPoint(x: w*0.61, y: h*0.22))
        p.addLine(to: CGPoint(x: w*0.61, y: h*0.80))
        p.move(to: CGPoint(x: w*0.22, y: h*0.66))
        p.addCurve(
            to: CGPoint(x: w*0.78, y: h*0.40),
            control1: CGPoint(x: w*0.42, y: h*0.30),
            control2: CGPoint(x: w*0.55, y: h*0.78)
        )
        let star = CGPoint(x: w*0.78, y: h*0.40)
        p.move(to: CGPoint(x: star.x-6, y: star.y-6))
        p.addLine(to: CGPoint(x: star.x+6, y: star.y+6))
        p.move(to: CGPoint(x: star.x+6, y: star.y-6))
        p.addLine(to: CGPoint(x: star.x-6, y: star.y+6))
        p.addEllipse(in: CGRect(x: w*0.22-4, y: h*0.66-4, width: 8, height: 8))
        return p
    }
}

private struct WhisperArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: w*0.16, y: h*0.30, width: w*0.20, height: h*0.30))
        p.move(to: CGPoint(x: w*0.16, y: h*0.60))
        p.addCurve(
            to: CGPoint(x: w*0.36, y: h*0.60),
            control1: CGPoint(x: w*0.16, y: h*0.84),
            control2: CGPoint(x: w*0.36, y: h*0.84)
        )
        p.addEllipse(in: CGRect(x: w*0.64, y: h*0.30, width: w*0.20, height: h*0.30))
        p.move(to: CGPoint(x: w*0.64, y: h*0.60))
        p.addCurve(
            to: CGPoint(x: w*0.84, y: h*0.60),
            control1: CGPoint(x: w*0.64, y: h*0.84),
            control2: CGPoint(x: w*0.84, y: h*0.84)
        )
        for i in 0..<5 {
            let x = w*(0.40 + Double(i)*0.05)
            p.addEllipse(in: CGRect(x: x-2, y: h*0.44, width: 4, height: 4))
        }
        let note = CGPoint(x: w*0.50, y: h*0.18)
        p.addEllipse(in: CGRect(x: note.x-4, y: note.y, width: 8, height: 6))
        p.move(to: CGPoint(x: note.x+4, y: note.y+3))
        p.addLine(to: CGPoint(x: note.x+4, y: note.y-10))
        return p
    }
}

private struct ForgerArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let canvas = CGRect(x: w*0.14, y: h*0.20, width: w*0.40, height: h*0.50)
        p.addRect(canvas)
        p.move(to: CGPoint(x: w*0.20, y: h*0.32))
        p.addLine(to: CGPoint(x: w*0.46, y: h*0.32))
        p.move(to: CGPoint(x: w*0.20, y: h*0.46))
        p.addLine(to: CGPoint(x: w*0.40, y: h*0.46))
        p.move(to: CGPoint(x: w*0.22, y: h*0.70))
        p.addLine(to: CGPoint(x: w*0.18, y: h*0.88))
        p.move(to: CGPoint(x: w*0.46, y: h*0.70))
        p.addLine(to: CGPoint(x: w*0.50, y: h*0.88))
        let lens = CGRect(x: w*0.56, y: h*0.30, width: w*0.26, height: h*0.42)
        p.addEllipse(in: lens)
        p.addEllipse(in: lens.insetBy(dx: w*0.04, dy: h*0.06))
        p.move(to: CGPoint(x: w*0.78, y: h*0.66))
        p.addLine(to: CGPoint(x: w*0.92, y: h*0.84))
        return p
    }
}

private struct ExitArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let frame = CGRect(x: w*0.20, y: h*0.20, width: w*0.30, height: h*0.64)
        p.addRect(frame)
        p.addEllipse(in: CGRect(x: w*0.42, y: h*0.50, width: 5, height: 5))
        p.move(to: CGPoint(x: w*0.50, y: h*0.52))
        p.addCurve(
            to: CGPoint(x: w*0.86, y: h*0.52),
            control1: CGPoint(x: w*0.62, y: h*0.30),
            control2: CGPoint(x: w*0.78, y: h*0.30)
        )
        p.move(to: CGPoint(x: w*0.86, y: h*0.52))
        p.addLine(to: CGPoint(x: w*0.78, y: h*0.46))
        p.move(to: CGPoint(x: w*0.86, y: h*0.52))
        p.addLine(to: CGPoint(x: w*0.78, y: h*0.58))
        p.move(to: CGPoint(x: w*0.24, y: h*0.16))
        p.addLine(to: CGPoint(x: w*0.46, y: h*0.16))
        return p
    }
}

private struct ReadersArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        for i in 0..<3 {
            let row = CGFloat(i)
            let y = h*0.30 + row*h*0.18
            for j in 0..<3 {
                let col = CGFloat(j)
                let x = w*0.20 + col*w*0.22
                let book = CGRect(x: x, y: y, width: w*0.16, height: h*0.12)
                p.addRect(book)
                p.move(to: CGPoint(x: x + w*0.08, y: y))
                p.addLine(to: CGPoint(x: x + w*0.08, y: y + h*0.12))
            }
        }
        let center = CGPoint(x: w*0.50, y: h*0.18)
        p.move(to: CGPoint(x: center.x - 14, y: center.y + 6))
        p.addLine(to: CGPoint(x: center.x, y: center.y - 6))
        p.addLine(to: CGPoint(x: center.x + 14, y: center.y + 6))
        p.move(to: CGPoint(x: center.x, y: center.y - 6))
        p.addLine(to: CGPoint(x: center.x, y: center.y + 6))
        return p
    }
}

private struct LibrarianArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let shelf = CGRect(x: w*0.16, y: h*0.18, width: w*0.68, height: h*0.64)
        p.addRect(shelf)
        for i in 1..<3 {
            let y = h*0.18 + h*0.64 * CGFloat(i)/3
            p.move(to: CGPoint(x: w*0.16, y: y))
            p.addLine(to: CGPoint(x: w*0.84, y: y))
        }
        for row in 0..<3 {
            let yTop = h*0.18 + h*0.64 * CGFloat(row)/3
            let yBot = yTop + h*0.64/3
            for col in 0..<6 {
                let x = w*0.16 + (w*0.68/6) * CGFloat(col)
                p.move(to: CGPoint(x: x + w*0.04, y: yTop + h*0.02))
                p.addLine(to: CGPoint(x: x + w*0.04, y: yBot - h*0.02))
            }
        }
        let star = CGPoint(x: w*0.50, y: h*0.50)
        for k in 0..<5 {
            let a = CGFloat(k) * .pi * 2 / 5 - .pi/2
            let pt = CGPoint(x: star.x + cos(a)*8, y: star.y + sin(a)*8)
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private struct ExoskeletonArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: w*0.46, y: h*0.10, width: w*0.10, height: h*0.14))
        p.move(to: CGPoint(x: w*0.50, y: h*0.24))
        p.addLine(to: CGPoint(x: w*0.50, y: h*0.62))
        p.move(to: CGPoint(x: w*0.50, y: h*0.32))
        p.addLine(to: CGPoint(x: w*0.30, y: h*0.50))
        p.move(to: CGPoint(x: w*0.50, y: h*0.32))
        p.addLine(to: CGPoint(x: w*0.70, y: h*0.50))
        p.move(to: CGPoint(x: w*0.50, y: h*0.62))
        p.addLine(to: CGPoint(x: w*0.40, y: h*0.90))
        p.move(to: CGPoint(x: w*0.50, y: h*0.62))
        p.addLine(to: CGPoint(x: w*0.60, y: h*0.90))
        for (x, y) in [(0.46, 0.36), (0.54, 0.36), (0.42, 0.46), (0.58, 0.46),
                       (0.46, 0.66), (0.54, 0.66), (0.44, 0.78), (0.56, 0.78),
                       (0.34, 0.46), (0.66, 0.46)] {
            p.addRect(CGRect(x: w*x-3, y: h*y-3, width: 6, height: 6))
        }
        return p
    }
}

private struct BouncerArt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: w*0.30, y: h*0.10, width: w*0.14, height: h*0.18))
        p.move(to: CGPoint(x: w*0.37, y: h*0.28))
        p.addLine(to: CGPoint(x: w*0.37, y: h*0.62))
        p.move(to: CGPoint(x: w*0.30, y: h*0.40))
        p.addLine(to: CGPoint(x: w*0.44, y: h*0.40))
        p.move(to: CGPoint(x: w*0.37, y: h*0.62))
        p.addLine(to: CGPoint(x: w*0.30, y: h*0.92))
        p.move(to: CGPoint(x: w*0.37, y: h*0.62))
        p.addLine(to: CGPoint(x: w*0.44, y: h*0.92))
        let board = CGRect(x: w*0.52, y: h*0.30, width: w*0.32, height: h*0.50)
        p.addRoundedRect(in: board, cornerSize: CGSize(width: 4, height: 4))
        let clip = CGRect(x: w*0.62, y: h*0.24, width: w*0.12, height: h*0.10)
        p.addRoundedRect(in: clip, cornerSize: CGSize(width: 2, height: 2))
        for i in 0..<4 {
            let y = h*(0.40 + Double(i)*0.10)
            p.move(to: CGPoint(x: w*0.56, y: y))
            p.addLine(to: CGPoint(x: w*0.80, y: y))
        }
        return p
    }
}

// MARK: - Card 4, Interactive diagram

private struct DiagramCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent

    // Positions for each node id, computed from layout.
    private func positions(in size: CGSize) -> [String: CGPoint] {
        let w = size.width
        let h = size.height
        switch content.diagramLayout {
        case .hub:
            // Query top-left; three keys stacked top-right → bottom-right
            var map: [String: CGPoint] = [:]
            if content.diagramNodes.count >= 1 {
                map[content.diagramNodes[0].id] = CGPoint(x: w*0.22, y: h*0.2)
            }
            if content.diagramNodes.count >= 2 {
                map[content.diagramNodes[1].id] = CGPoint(x: w*0.78, y: h*0.2)
            }
            if content.diagramNodes.count >= 3 {
                map[content.diagramNodes[2].id] = CGPoint(x: w*0.78, y: h*0.5)
            }
            if content.diagramNodes.count >= 4 {
                map[content.diagramNodes[3].id] = CGPoint(x: w*0.78, y: h*0.78)
            }
            return map
        case .flow:
            // Even horizontal spread, mid-height, with a subtle zig-zag for
            // visual rhythm.
            var map: [String: CGPoint] = [:]
            let count = content.diagramNodes.count
            guard count > 0 else { return map }
            for (i, n) in content.diagramNodes.enumerated() {
                let t = count == 1 ? 0.5 : Double(i) / Double(count - 1)
                let x = w * (0.12 + 0.76 * CGFloat(t))
                let y = h * (i % 2 == 0 ? 0.30 : 0.62)
                map[n.id] = CGPoint(x: x, y: y)
            }
            return map
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CARD 04 · TAP TO EXPLORE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
                Spacer()
                Text("\(state.visitedNodes.count)/\(state.totalVisitableNodes) visited")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(mutedText)
            }
            .padding(.horizontal, 20)

            segmentedText(content.diagramSegments, highlight: tealAccent)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 12)

            // Diagram
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                GeometryReader { geo in
                    let pos = positions(in: geo.size)
                    // Edges
                    edgesLayer(pos: pos, size: geo.size)
                    // Nodes
                    nodesLayer(pos: pos, size: geo.size)

                    // Collapse marker (hub only)
                    if content.diagramLayout == .hub, let collapseText = content.diagramCollapseText {
                        Text(collapseText)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 9).fill(dlRoseLight)
                                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(dlRose, lineWidth: 1))
                            )
                            .foregroundStyle(Color(hex: "8a2a2a"))
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.88)
                    }

                    // Hint pulse (top-right)
                    if state.visitedNodes.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 5) {
                                    Circle().fill(tealAccent).frame(width: 6, height: 6)
                                    Text(hintLabel)
                                }
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(mutedText)
                                .padding(.trailing, 14)
                                .padding(.top, 12)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(1.05, contentMode: .fit)
            .padding(.horizontal, 16)

            // Explanation panel (rewrites)
            let info = state.activeNode.flatMap { id in
                content.diagramNodes.first(where: { $0.id == id })
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(info?.panelTitle.uppercased() ?? "TAP A NODE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(dlTealDeep)
                GlossText(raw: info?.panelBody ?? content.diagramDefaultPanelBody,
                          glossary: content.glossary,
                          font: .system(size: 13, weight: .medium, design: .serif),
                          color: inkColor,
                          lineSpacing: 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                HStack(spacing: 0) {
                    Rectangle().fill(tealAccent).frame(width: 3)
                    tealLight
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer()
        }
        .padding(.top, 6)
    }

    private var hintLabel: String {
        guard let first = content.diagramNodes.first else { return "TAP NODE" }
        // Short prompt: "TAP Q" / "TAP PROBLEM"
        let label = first.label.uppercased()
        let short = label.count <= 8 ? label : String(label.prefix(7))
        return "TAP \(short)"
    }

    @ViewBuilder
    private func edgesLayer(pos: [String: CGPoint], size: CGSize) -> some View {
        switch content.diagramLayout {
        case .hub:
            hubEdges(pos: pos, size: size)
        case .flow:
            flowEdges(pos: pos, size: size)
        }
    }

    @ViewBuilder
    private func hubEdges(pos: [String: CGPoint], size: CGSize) -> some View {
        let nodes = content.diagramNodes
        ZStack {
            // Q -> K1 (solid, becomes teal when both visited)
            if nodes.count >= 2,
               let q = pos[nodes[0].id], let k1 = pos[nodes[1].id] {
                let lit = state.visitedNodes.contains(nodes[0].id) && state.visitedNodes.contains(nodes[1].id)
                Path { p in
                    p.move(to: q)
                    p.addQuadCurve(to: k1, control: CGPoint(x: (q.x + k1.x) / 2, y: q.y))
                }
                .stroke(lit ? tealAccent : dlLine, lineWidth: 2.2)
            }
            // Q -> K2 (dashed)
            if nodes.count >= 3,
               let q = pos[nodes[0].id], let k2 = pos[nodes[2].id] {
                Path { p in
                    p.move(to: q)
                    p.addQuadCurve(to: k2, control: CGPoint(x: (q.x + k2.x) / 2, y: k2.y))
                }
                .stroke(dlLine, style: StrokeStyle(lineWidth: 1.3, dash: [4, 3]))
            }
            // Q -> K3 (dashed)
            if nodes.count >= 4,
               let q = pos[nodes[0].id], let k3 = pos[nodes[3].id] {
                Path { p in
                    p.move(to: q)
                    p.addQuadCurve(to: k3, control: CGPoint(x: (q.x + k3.x) / 2, y: k3.y))
                }
                .stroke(dlLine, style: StrokeStyle(lineWidth: 1.3, dash: [4, 3]))
            }
            // K1 -> collapse marker (rose)
            if content.diagramCollapseText != nil,
               nodes.count >= 2,
               let k1 = pos[nodes[1].id] {
                let collapsePt = CGPoint(x: size.width * 0.5, y: size.height * 0.88)
                Path { p in
                    p.move(to: CGPoint(x: k1.x, y: k1.y + 22))
                    p.addQuadCurve(to: collapsePt, control: CGPoint(x: k1.x, y: size.height * 0.68))
                }
                .stroke(dlRose, lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private func flowEdges(pos: [String: CGPoint], size: CGSize) -> some View {
        let nodes = content.diagramNodes
        ZStack {
            ForEach(0..<max(0, nodes.count - 1), id: \.self) { i in
                let from = pos[nodes[i].id] ?? .zero
                let to = pos[nodes[i + 1].id] ?? .zero
                let lit = state.visitedNodes.contains(nodes[i].id) && state.visitedNodes.contains(nodes[i + 1].id)
                let color = lit ? tealAccent : dlLine
                // Arc between consecutive nodes
                Path { p in
                    p.move(to: from)
                    let cx = (from.x + to.x) / 2
                    let cy = (from.y + to.y) / 2 - 14
                    p.addQuadCurve(to: to, control: CGPoint(x: cx, y: cy))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

                // Simple arrowhead at the destination
                Path { p in
                    let dx = to.x - from.x
                    let dy = to.y - from.y
                    let len = max(1, sqrt(dx*dx + dy*dy))
                    let ux = dx / len
                    let uy = dy / len
                    let tipX = to.x - ux * 20
                    let tipY = to.y - uy * 20
                    let nx = -uy
                    let ny = ux
                    p.move(to: CGPoint(x: tipX + nx * 5, y: tipY + ny * 5))
                    p.addLine(to: CGPoint(x: to.x - ux * 8, y: to.y - uy * 8))
                    p.addLine(to: CGPoint(x: tipX - nx * 5, y: tipY - ny * 5))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }

    @ViewBuilder
    private func nodesLayer(pos: [String: CGPoint], size: CGSize) -> some View {
        ForEach(Array(content.diagramNodes.enumerated()), id: \.element.id) { idx, node in
            let active = state.activeNode == node.id
            let visited = state.visitedNodes.contains(node.id)
            // For hub layout, the two "starved" keys (index 2,3) should dim
            // until tapped. For flow layout, nothing is dimmed, the chain
            // reads left-to-right and all nodes are equally live.
            let dim: Bool = {
                guard content.diagramLayout == .hub else { return false }
                return idx >= 2 && !visited
            }()

            AttnNode(label: node.label, sub: node.sublabel,
                     active: active, visited: visited, dim: dim)
                .position(pos[node.id] ?? .zero)
                .onTapGesture { tapNode(node.id) }
        }
    }

    private func tapNode(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            state.activeNode = id
            state.visitedNodes.insert(id)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}

private struct AttnNode: View {
    let label: String
    let sub: String?
    let active: Bool
    let visited: Bool
    var dim: Bool = false

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
            if let sub {
                Text(sub)
                    .font(.system(size: 8))
                    .opacity(0.7)
            }
        }
        .foregroundStyle(active ? Color.white : dlInk2)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 56)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(active ? tealAccent : (visited ? tealLight : dlPaper2))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(active ? tealAccent : dlLine, lineWidth: 1)
                )
                .shadow(color: active ? tealAccent.opacity(0.3) : .clear, radius: 8)
        )
        .scaleEffect(active ? 1.08 : 1.0)
        .opacity(dim ? 0.55 : 1.0)
    }
}

// MARK: - Cards 5 & 6, Visualizations
//
// Replaces the old quiz cards. Each viz card pairs an editorial title +
// caption with one DLVisualization payload. Two payload types ship today:
//   • barChart, categorical bars with optional secondary series and a
//     vertical "cliff" rule. Tap a bar to reveal its annotation.
//   • scatterMorph, points that interpolate between a "before" and "after"
//     position via a draggable scrubber. Auto-plays once on appear.
// Adding a new viz type = extend DLVisualization + add a case to the
// `payload` switch below.

private struct VizCardView: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent
    let slot: Int          // 0 or 1, index into content.vizCards
    let deckIndex: Int     // 4 or 5, index into state's per-card maps

    private var card: DLVizCard? {
        guard content.vizCards.indices.contains(slot) else { return nil }
        return content.vizCards[slot]
    }

    var body: some View {
        if let card {
            let isGPT3 = (content.paperTitle ?? "").contains("GPT-3")
            let hPad: CGFloat = isGPT3 ? 24 : 20
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(card.kicker)
                        .font(.system(size: isGPT3 ? 9 : 10, weight: .bold))
                        .tracking(isGPT3 ? 1.6 : 1.8)
                        .foregroundStyle(tealAccent)
                        .padding(.horizontal, hPad)
                        .padding(.bottom, isGPT3 ? 8 : 6)

                    segmentedText(card.titleSegments, highlight: tealAccent)
                        .font(.system(size: isGPT3 ? 24 : 22,
                                      weight: isGPT3 ? .regular : .semibold,
                                      design: .serif))
                        .foregroundStyle(inkColor)
                        .lineSpacing(isGPT3 ? 0 : 3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, hPad)
                        .padding(.bottom, isGPT3 ? 0 : 12)

                    Text(card.caption)
                        .font(.system(size: isGPT3 ? 12 : 13, design: .serif))
                        .foregroundStyle(isGPT3 ? mutedText : dlInk3)
                        .lineSpacing(isGPT3 ? 0 : 4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, hPad)
                        .padding(.top, isGPT3 ? 8 : 0)
                        .padding(.bottom, isGPT3 ? 18 : 14)

                    payload(card.visualization)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    // Sticky takeaway pill at the bottom of every viz card
                    HStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(amberAccent)
                        Text(card.takeaway)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundStyle(inkColor)
                            .italic()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dlAmberLight)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(amberAccent.opacity(0.25), lineWidth: 1))
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
    }

    @ViewBuilder
    private func payload(_ viz: DLVisualization) -> some View {
        switch viz {
        case .barChart(let spec):
            BarChartView(
                spec: spec,
                activeIndex: Binding(
                    get: { state.vizActiveBar[deckIndex] },
                    set: {
                        state.vizActiveBar[deckIndex] = $0
                        state.vizExplored.insert(deckIndex)
                    }
                )
            )
        case .scatterMorph(let spec):
            ScatterMorphView(
                spec: spec,
                progress: Binding(
                    get: { state.vizMorphProgress[deckIndex] ?? 0 },
                    set: {
                        state.vizMorphProgress[deckIndex] = $0
                        state.vizExplored.insert(deckIndex)
                    }
                )
            )
        case .trainingCurve(let spec):
            TrainingCurveView(
                spec: spec,
                selection: Binding(
                    get: { state.vizCurveSelection[deckIndex] },
                    set: {
                        state.vizCurveSelection[deckIndex] = $0
                        state.vizExplored.insert(deckIndex)
                    }
                )
            )
        case .flowRich(let spec):
            FlowRichView(
                spec: spec,
                selection: Binding(
                    get: { state.vizFlowSelection[deckIndex] },
                    set: {
                        state.vizFlowSelection[deckIndex] = $0
                        state.vizExplored.insert(deckIndex)
                    }
                )
            )
        case .equationRich(let spec):
            EquationRichView(
                spec: spec,
                selection: Binding(
                    get: { state.vizEquationSelection[deckIndex] },
                    set: {
                        state.vizEquationSelection[deckIndex] = $0
                        state.vizExplored.insert(deckIndex)
                    }
                )
            )
        }
    }
}

// MARK: - BarChartView
//
// Categorical bar chart with optional secondary series. Tap any bar (or its
// label) to "select" the column, the insight panel below the chart rewrites
// to the bar's annotation. An optional vertical dashed rule marks a cliff
// (e.g., "ChatGPT off" on day 7).

private struct BarChartView: View {
    let spec: DLBarChartSpec
    @Binding var activeIndex: Int?

    @State private var animatedIn: Bool = false

    private let plotHeight: CGFloat = 180
    private let topPad: CGFloat = 12
    private let bottomPad: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            legend

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                GeometryReader { geo in
                    let plotRect = CGRect(
                        x: 38,
                        y: topPad,
                        width: max(geo.size.width - 50, 0),
                        height: max(geo.size.height - topPad - bottomPad, 0)
                    )
                    yAxis(in: plotRect)
                    bars(in: plotRect)
                    cliffRule(in: plotRect)
                    xAxis(in: plotRect, totalWidth: geo.size.width)
                }
            }
            .frame(height: plotHeight + topPad + bottomPad)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) { animatedIn = true }
            }

            insightPanel
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2).fill(amberAccent).frame(width: 14, height: 9)
                Text(spec.primaryLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(dlInk3)
            }
            if let secondary = spec.secondaryLabel {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(tealAccent.opacity(0.55)).frame(width: 14, height: 9)
                    Text(secondary)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dlInk3)
                }
            }
            Spacer(minLength: 0)
            Text(spec.yAxisLabel.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(mutedText)
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func yAxis(in rect: CGRect) -> some View {
        let ticks = spec.yTickLabels
        ForEach(Array(ticks.enumerated()), id: \.offset) { i, label in
            let t = ticks.count <= 1 ? 0 : Double(i) / Double(ticks.count - 1)
            let y = rect.maxY - rect.height * CGFloat(t)
            Path { p in
                p.move(to: CGPoint(x: rect.minX, y: y))
                p.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
            .stroke(dlLine.opacity(0.6),
                    style: StrokeStyle(lineWidth: 0.6, dash: [3, 4]))
            Text(label)
                .font(.system(size: 9, weight: .semibold).monospaced())
                .foregroundStyle(mutedText)
                .position(x: rect.minX - 18, y: y)
        }
    }

    @ViewBuilder
    private func bars(in rect: CGRect) -> some View {
        let count = spec.points.count
        let groupWidth = count > 0 ? rect.width / CGFloat(count) : 0
        let hasSecondary = spec.secondaryLabel != nil
        let primaryWidth: CGFloat = hasSecondary ? groupWidth * 0.30 : groupWidth * 0.50
        let secondaryWidth: CGFloat = hasSecondary ? groupWidth * 0.30 : 0
        let gap: CGFloat = hasSecondary ? 4 : 0
        ForEach(Array(spec.points.enumerated()), id: \.offset) { i, point in
            let centerX = rect.minX + groupWidth * (CGFloat(i) + 0.5)
            let primaryH = animatedIn ? CGFloat(point.primary / spec.yMax) * rect.height : 0
            let secondaryH = animatedIn ? CGFloat((point.secondary ?? 0) / spec.yMax) * rect.height : 0
            let isActive = activeIndex == i
            let primaryX = hasSecondary ? centerX - primaryWidth - gap / 2 : centerX - primaryWidth / 2

            // Primary bar
            RoundedRectangle(cornerRadius: 4)
                .fill(amberAccent)
                .frame(width: primaryWidth, height: max(primaryH, 2))
                .position(x: primaryX + primaryWidth / 2, y: rect.maxY - max(primaryH, 2) / 2)
                .opacity(activeIndex == nil || isActive ? 1.0 : 0.45)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: animatedIn)

            // Secondary bar
            if hasSecondary {
                RoundedRectangle(cornerRadius: 4)
                    .fill(tealAccent.opacity(0.55))
                    .frame(width: secondaryWidth, height: max(secondaryH, 2))
                    .position(x: centerX + gap / 2 + secondaryWidth / 2, y: rect.maxY - max(secondaryH, 2) / 2)
                    .opacity(activeIndex == nil || isActive ? 1.0 : 0.45)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: animatedIn)
            }

            // Tap target, covers the whole column
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: groupWidth, height: rect.height)
                .position(x: centerX, y: rect.midY)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        activeIndex = (activeIndex == i) ? nil : i
                    }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
        }
    }

    @ViewBuilder
    private func cliffRule(in rect: CGRect) -> some View {
        if let idx = spec.cliffIndex, spec.points.indices.contains(idx) {
            let count = spec.points.count
            let groupWidth = rect.width / CGFloat(count)
            // Place rule between point[idx-1] and point[idx] for "happens after this column"
            let x = rect.minX + groupWidth * CGFloat(idx)
            Path { p in
                p.move(to: CGPoint(x: x, y: rect.minY))
                p.addLine(to: CGPoint(x: x, y: rect.maxY))
            }
            .stroke(dlRose, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))

            if let label = spec.cliffLabel {
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(Color(hex: "8a2a2a"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(dlRoseLight).overlay(Capsule().stroke(dlRose, lineWidth: 0.8))
                    )
                    .position(x: x, y: rect.minY + 8)
            }
        }
    }

    @ViewBuilder
    private func xAxis(in rect: CGRect, totalWidth: CGFloat) -> some View {
        let count = spec.points.count
        let groupWidth = count > 0 ? rect.width / CGFloat(count) : 0
        ForEach(Array(spec.points.enumerated()), id: \.offset) { i, point in
            let centerX = rect.minX + groupWidth * (CGFloat(i) + 0.5)
            VStack(spacing: 1) {
                Text(point.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(activeIndex == i ? inkColor : dlInk3)
                if let sub = point.sublabel {
                    Text(sub)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(mutedText)
                        .lineLimit(1)
                }
            }
            .frame(width: groupWidth - 4)
            .position(x: centerX, y: rect.maxY + 14)
        }
    }

    private var insightPanel: some View {
        let active = activeIndex.flatMap { spec.points.indices.contains($0) ? spec.points[$0] : nil }
        let title: String
        let body: String
        if let active, let annotation = active.annotation {
            title = "\(active.label.uppercased())\(active.sublabel.map { " · \($0.uppercased())" } ?? "")"
            body = annotation
        } else {
            title = "TAP A BAR"
            body = spec.defaultInsight
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(dlTealDeep)
            Text(body)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(inkColor)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            HStack(spacing: 0) {
                Rectangle().fill(tealAccent).frame(width: 3)
                tealLight
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        )
    }
}

// MARK: - ScatterMorphView
//
// 2D scatter that interpolates each dot's position from "before" to "after"
// based on a 0...1 progress value. The progress is driven by a draggable
// scrubber at the bottom of the view, and auto-plays once on appear so the
// transition is the first thing the user sees.

private struct ScatterMorphView: View {
    let spec: DLScatterMorphSpec
    @Binding var progress: Double

    @State private var hasAutoPlayed: Bool = false

    private let plotHeight: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header, before/after labels + legend
            HStack(spacing: 10) {
                labelChip(spec.beforeLabel, active: progress < 0.5)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(mutedText)
                labelChip(spec.afterLabel, active: progress >= 0.5)
                Spacer(minLength: 0)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                GeometryReader { geo in
                    let plotRect = CGRect(
                        x: 14, y: 14,
                        width: max(geo.size.width - 28, 0),
                        height: max(geo.size.height - 28, 0)
                    )
                    // Subtle grid
                    Path { p in
                        let mid = CGPoint(x: plotRect.midX, y: plotRect.midY)
                        p.move(to: CGPoint(x: plotRect.minX, y: mid.y))
                        p.addLine(to: CGPoint(x: plotRect.maxX, y: mid.y))
                        p.move(to: CGPoint(x: mid.x, y: plotRect.minY))
                        p.addLine(to: CGPoint(x: mid.x, y: plotRect.maxY))
                    }
                    .stroke(dlLine.opacity(0.5), style: StrokeStyle(lineWidth: 0.6, dash: [2, 4]))

                    // Dots
                    ForEach(Array(spec.dots.enumerated()), id: \.offset) { i, dot in
                        let x = dot.xBefore + (dot.xAfter - dot.xBefore) * progress
                        let y = dot.yBefore + (dot.yAfter - dot.yBefore) * progress
                        let px = plotRect.minX + plotRect.width * CGFloat(x)
                        let py = plotRect.minY + plotRect.height * CGFloat(1 - y) // flip y so up is +
                        Circle()
                            .fill(dot.isTreatment ? amberAccent : tealAccent.opacity(0.55))
                            .frame(width: dot.isTreatment ? 11 : 9, height: dot.isTreatment ? 11 : 9)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1.2)
                            )
                            .shadow(color: (dot.isTreatment ? amberAccent : tealAccent).opacity(0.25), radius: 3)
                            .position(x: px, y: py)
                            .id(i)
                    }

                    // Axis labels
                    Text(spec.xAxisLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(mutedText)
                        .position(x: plotRect.midX, y: plotRect.maxY + 4)
                    Text(spec.yAxisLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(mutedText)
                        .rotationEffect(.degrees(-90))
                        .position(x: plotRect.minX - 6, y: plotRect.midY)
                }
            }
            .frame(height: plotHeight)
            .onAppear {
                guard !hasAutoPlayed else { return }
                hasAutoPlayed = true
                // Play 0 → 1 once so the transition is visible without input
                progress = 0
                withAnimation(.easeInOut(duration: 1.6)) { progress = 1 }
            }

            // Caption, switches at the midpoint
            Text(progress < 0.5 ? spec.beforeCaption : spec.afterCaption)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(inkColor)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    HStack(spacing: 0) {
                        Rectangle().fill(tealAccent).frame(width: 3)
                        tealLight
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                )

            // Scrubber row
            HStack(spacing: 12) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tealAccent)
                Slider(
                    value: Binding(
                        get: { progress },
                        set: { newValue in progress = newValue }
                    ),
                    in: 0...1
                )
                .tint(tealAccent)
                Text(String(format: "%d%%", Int(progress * 100)))
                    .font(.system(size: 11, weight: .semibold).monospaced())
                    .foregroundStyle(mutedText)
                    .frame(width: 36, alignment: .trailing)
            }

            // Legend
            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Circle().fill(amberAccent).frame(width: 9, height: 9)
                    Text(spec.treatmentLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dlInk3)
                }
                HStack(spacing: 6) {
                    Circle().fill(tealAccent.opacity(0.55)).frame(width: 9, height: 9)
                    Text(spec.controlLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dlInk3)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func labelChip(_ text: String, active: Bool) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(active ? inkColor : mutedText)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(active ? Color.white : dlPaper2)
                    .overlay(Capsule().stroke(active ? tealAccent : dlLine, lineWidth: 1))
            )
    }
}
// MARK: - Complete (deck finished)
//
// Calm-celebratory close: a light sparkle burst around the +50 badge (no
// confetti cannon, we reward finishing, not conquering) and a single DONE
// pill. The restart button is gone, a "redo" here is usually an accidental
// tap; the user can just start the loop again from home if they want.

private struct CompleteCard: View {
    @ObservedObject var state: DailyLoopState
    let content: DailyLoopContent
    let dismiss: DismissAction

    @ObservedObject private var progressStore = ReadingProgressStore.shared
    @State private var browser: BrowserLink?

    private var quoteBody: String {
        var s = content.completeTakeaway
        let trimChars: Set<Character> = ["\"", "\u{201C}", "\u{201D}"]
        while let f = s.first, trimChars.contains(f) { s.removeFirst() }
        while let l = s.last,  trimChars.contains(l) { s.removeLast() }
        return s
    }

    private var attribution: String {
        let title = content.paperTitle ?? content.sourceLine
        return title
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("\u{201C}")
                    .font(.system(size: 96, weight: .regular, design: .serif))
                    .foregroundStyle(tealAccent.opacity(0.55))
                    .frame(height: 44, alignment: .top)
                    .padding(.top, 10)
                    .padding(.leading, -4)

                Text("\(quoteBody)\u{201D}")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(inkColor.opacity(0.92))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(tealAccent.opacity(0.55))
                        .frame(width: 18, height: 1)
                    Text(attribution)
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundStyle(mutedText)
                }
                .padding(.top, 18)

                Spacer(minLength: 40)

                // Optional bridge from the microlearning loop back to the
                // original research paper. Hidden when no URL is set so
                // legacy loops (no hosted source) keep a single CTA.
                if let urlString = content.paperURL,
                   let url = URL(string: urlString) {
                    Button {
                        browser = BrowserLink(url: url)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("READ THE ORIGINAL")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(1.6)
                                    .foregroundStyle(tealAccent)
                                Text("Open the full paper")
                                    .font(.system(size: 14, weight: .semibold, design: .serif))
                                    .foregroundStyle(inkColor)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(tealAccent)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(tealAccent.opacity(0.35), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
                    .sheet(item: $browser) { link in
                        SafariView(url: link.url).ignoresSafeArea()
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Done")
                                .tracking(1.2)
                            Image(systemName: "checkmark")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(paperBg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 14).fill(inkColor))
                    }
                    .buttonStyle(.plain)

                    if let pid = content.paperId {
                        CompleteCardBookmarkChip(paperId: pid)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .onAppear {
            // Prefer the routable paperId (e.g. `loop:foundational:perceptron`)
            // so bundle-step gating sees the completion. Falls back to the
            // sourceLine for legacy loops that never had a paperId stamped.
            let pid = content.paperId ?? content.sourceLine
            progressStore.markCompletedToday(paperId: pid)
            progressStore.markComplete(paperId: pid)
        }
    }
}

private struct CompleteCardBookmarkChip: View {
    let paperId: String
    @ObservedObject private var savedStore = SavedPapersStore.shared

    var body: some View {
        Button {
            savedStore.toggleOrPromptSignIn(paperId)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Image(systemName: savedStore.isSaved(paperId) ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(savedStore.isSaved(paperId) ? tealAccent : inkColor)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(savedStore.isSaved(paperId) ? "Remove from library" : "Save to library")
    }
}

// MARK: - TrainingCurveView
//
// Premium hand-drawn training curve. One or more series share a single set of
// axes; each series has tappable milestone dots that surface a narrative
// annotation. Designed for "metric over time" stories, loss falling, accuracy
// climbing, errors converging or oscillating.
//
// Render approach:
//   • Canvas draws the bg paper-grain card, dashed gridlines, splined paths,
//     and milestone dots. Hand-drawn vibe via slight stroke jitter on series.
//   • A separate overlay GeometryReader hosts invisible Buttons sized to each
//     milestone, tap targets stay precise even when the curve is dense.
//   • Below the chart: legend chips + an annotation panel that swaps copy when
//     a milestone is selected. Defaults to `defaultInsight`.

private struct TrainingCurveView: View {
    let spec: DLTrainingCurveSpec
    @Binding var selection: DailyLoopState.CurveSelection?

    @State private var animatedIn: Bool = false

    private let plotHeight: CGFloat = 200
    private let leftPad: CGFloat = 40
    private let rightPad: CGFloat = 12
    private let topPad: CGFloat = 14
    private let bottomPad: CGFloat = 26

    private var xDomain: (min: Double, max: Double) {
        let xs = spec.series.flatMap { $0.points.map(\.x) }
        return (xs.min() ?? 0, xs.max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            legend

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                GeometryReader { geo in
                    let plot = plotRect(in: geo.size)
                    ZStack {
                        gridAndAxes(plot: plot)
                        ForEach(Array(spec.series.enumerated()), id: \.offset) { idx, series in
                            curvePath(series: series, plot: plot)
                                .opacity(animatedIn ? 1 : 0)
                                .animation(.easeOut(duration: 0.7).delay(Double(idx) * 0.15), value: animatedIn)
                        }
                        ForEach(Array(spec.series.enumerated()), id: \.offset) { sIdx, series in
                            ForEach(Array(series.points.enumerated()), id: \.offset) { pIdx, point in
                                milestoneDot(series: series, sIdx: sIdx, point: point, pIdx: pIdx, plot: plot)
                            }
                        }
                    }
                }
                .frame(height: plotHeight + topPad + bottomPad)
            }

            insightPanel
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4).delay(0.1)) { animatedIn = true } }
    }

    // MARK: layout

    private func plotRect(in size: CGSize) -> CGRect {
        CGRect(
            x: leftPad,
            y: topPad,
            width: max(1, size.width - leftPad - rightPad),
            height: plotHeight
        )
    }

    private func position(x: Double, y: Double, in plot: CGRect) -> CGPoint {
        let xRange = max(0.0001, xDomain.max - xDomain.min)
        let nx = (x - xDomain.min) / xRange
        let ny = max(0, min(1, y))
        return CGPoint(
            x: plot.minX + CGFloat(nx) * plot.width,
            y: plot.maxY - CGFloat(ny) * plot.height
        )
    }

    // MARK: legend

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(Array(spec.series.enumerated()), id: \.offset) { _, series in
                HStack(spacing: 6) {
                    LegendStroke(color: tokenColor(series.color), dashed: series.dashed)
                        .frame(width: 18, height: 2)
                    Text(series.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dlInk2)
                }
            }
            Spacer()
        }
    }

    // MARK: grid + axes

    private func gridAndAxes(plot: CGRect) -> some View {
        ZStack {
            // y gridlines + tick labels (3)
            ForEach(0..<spec.yTickLabels.count, id: \.self) { i in
                let frac = Double(i) / Double(max(1, spec.yTickLabels.count - 1))
                let y = plot.maxY - CGFloat(frac) * plot.height
                Path { p in
                    p.move(to: CGPoint(x: plot.minX, y: y))
                    p.addLine(to: CGPoint(x: plot.maxX, y: y))
                }
                .stroke(dlLine, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                Text(spec.yTickLabels[i])
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(dlInk3)
                    .position(x: plot.minX - 18, y: y)
            }
            // x ticks
            ForEach(0..<spec.xTickLabels.count, id: \.self) { i in
                let frac = Double(i) / Double(max(1, spec.xTickLabels.count - 1))
                let x = plot.minX + CGFloat(frac) * plot.width
                Path { p in
                    p.move(to: CGPoint(x: x, y: plot.maxY))
                    p.addLine(to: CGPoint(x: x, y: plot.maxY + 4))
                }
                .stroke(dlInk3.opacity(0.6), lineWidth: 1)

                Text(spec.xTickLabels[i])
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(dlInk3)
                    .position(x: x, y: plot.maxY + 14)
            }
            // axis labels
            Text(spec.yAxisLabel)
                .font(.system(size: 9, weight: .medium, design: .serif))
                .foregroundStyle(dlInk3)
                .rotationEffect(.degrees(-90))
                .position(x: plot.minX - 32, y: plot.midY)

            Text(spec.xAxisLabel)
                .font(.system(size: 9, weight: .medium, design: .serif))
                .foregroundStyle(dlInk3)
                .position(x: plot.midX, y: plot.maxY + 24)
        }
    }

    // MARK: curves

    private func curvePath(series: DLTrainingCurveSeries, plot: CGRect) -> some View {
        let pts = series.points.map { position(x: $0.x, y: $0.y, in: plot) }
        return ShapePath { path in
            guard let first = pts.first else { return }
            path.move(to: first)
            // Smooth via Catmull-Rom-ish cubic between adjacent points
            for i in 1..<pts.count {
                let p0 = i >= 2 ? pts[i-2] : pts[i-1]
                let p1 = pts[i-1]
                let p2 = pts[i]
                let p3 = i+1 < pts.count ? pts[i+1] : pts[i]
                let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
                let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
                path.addCurve(to: p2, control1: c1, control2: c2)
            }
        }
        .stroke(
            tokenColor(series.color),
            style: StrokeStyle(
                lineWidth: 2.4,
                lineCap: .round,
                lineJoin: .round,
                dash: series.dashed ? [4, 4] : []
            )
        )
    }

    // MARK: milestone dots + tap targets

    private func milestoneDot(
        series: DLTrainingCurveSeries,
        sIdx: Int,
        point: DLTrainingCurvePoint,
        pIdx: Int,
        plot: CGRect
    ) -> some View {
        let p = position(x: point.x, y: point.y, in: plot)
        let isActive = selection == DailyLoopState.CurveSelection(series: sIdx, point: pIdx)
        let isMilestone = (point.milestone ?? "").isEmpty == false || (point.annotation ?? "").isEmpty == false
        let color = tokenColor(series.color)
        return ZStack {
            if isActive {
                Circle().fill(color.opacity(0.18)).frame(width: 22, height: 22)
            }
            Circle()
                .fill(Color.white)
                .frame(width: isMilestone ? 12 : 8, height: isMilestone ? 12 : 8)
                .overlay(Circle().stroke(color, lineWidth: 2))

            if let milestone = point.milestone, !milestone.isEmpty {
                Text(milestone)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white).overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1)))
                    .offset(y: -16)
            }
        }
        .position(p)
        .contentShape(Rectangle().size(width: 36, height: 36))
        .onTapGesture {
            guard isMilestone else { return }
            selection = DailyLoopState.CurveSelection(series: sIdx, point: pIdx)
        }
    }

    // MARK: insight panel

    private var insightPanel: some View {
        let body: String = {
            if let sel = selection,
               spec.series.indices.contains(sel.series),
               spec.series[sel.series].points.indices.contains(sel.point),
               let note = spec.series[sel.series].points[sel.point].annotation {
                return note
            }
            return spec.defaultInsight
        }()
        return Text(body)
            .font(.system(size: 12, design: .serif))
            .foregroundStyle(dlInk3)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(dlPaper2)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(dlLine, lineWidth: 1))
            )
    }

    // MARK: color tokens

    private func tokenColor(_ token: DLTrainingCurveColor) -> Color {
        switch token {
        case .teal:  return dlTealDeep
        case .amber: return dlAmberDeep
        case .rose:  return dlRose
        case .ink:   return dlInk2
        }
    }
}

private struct LegendStroke: View {
    let color: Color
    let dashed: Bool
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: dashed ? [4, 4] : []))
        }
    }
}

// Tiny helper so we can build a Path imperatively inside a View body without
// fighting Swift's `Path { }` overload resolution against ViewBuilder.
private struct ShapePath: Shape {
    let build: @Sendable (inout Path) -> Void
    func path(in rect: CGRect) -> Path {
        var p = Path()
        build(&p)
        return p
    }
}

// MARK: - FlowRichView
//
// Boxes-and-arrows architecture diagram. Nodes lay out on a column/row grid;
// edges connect them with kind-aware strokes (forward = solid teal, backward
// = dashed amber, skip = curved ink). Tap a node to surface its panel.
//
// Render approach:
//   • Compute node frames from grid columns × rows in a GeometryReader.
//   • Path layer draws every edge with stroke-on-appear animation.
//   • Node layer draws filled rounded rects on top, with role-tinted borders.
//   • Tap target = whole node rect; selected state pulls focus via halo + dim.
//   • Panel below swaps to selected node's body (defaults to spec.defaultInsight).

private struct FlowRichView: View {
    let spec: DLFlowRichSpec
    @Binding var selection: String?

    @State private var animatedIn: Bool = false

    private let nodeHeight: CGFloat = 64
    private let nodeRowCenterY: CGFloat = 80     // top band reserved for nodes
    private let plotHeight: CGFloat = 240
    private let hPad: CGFloat = 8
    private let nodeGap: CGFloat = 10

    private var maxColumn: Int { spec.nodes.map(\.column).max() ?? 0 }
    private var maxRow: Int { spec.nodes.map(\.row).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            legend

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                GeometryReader { geo in
                    let frames = nodeFrames(in: geo.size)
                    ZStack {
                        ForEach(Array(spec.edges.enumerated()), id: \.offset) { idx, edge in
                            edgePath(edge: edge, frames: frames)
                                .opacity(animatedIn ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.1 + Double(idx) * 0.06), value: animatedIn)
                        }
                        ForEach(Array(spec.nodes.enumerated()), id: \.offset) { _, node in
                            if let frame = frames[node.id] {
                                nodeView(node: node)
                                    .frame(width: frame.width, height: frame.height)
                                    .position(x: frame.midX, y: frame.midY)
                                    .opacity(animatedIn ? 1 : 0)
                                    .scaleEffect(animatedIn ? 1 : 0.92)
                                    .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(Double(node.column) * 0.08), value: animatedIn)
                            }
                        }
                    }
                }
                .frame(height: plotHeight)
            }

            insightPanel
        }
        .onAppear { withAnimation { animatedIn = true } }
    }

    // MARK: layout
    //
    // Nodes lay out on a single horizontal band (row 0). Width adapts to the
    // available container so they never overlap. Backward edges curve below
    // the band; forward edges run straight along the centerline. This keeps
    // the diagram readable on any iPhone width without horizontal scrolling.

    private func nodeFrames(in size: CGSize) -> [String: CGRect] {
        let cols = max(1, maxColumn + 1)
        let rows = max(1, maxRow + 1)
        let usableWidth = size.width - hPad * 2
        let totalGap = nodeGap * CGFloat(max(0, cols - 1))
        let nodeW = max(56, (usableWidth - totalGap) / CGFloat(cols))
        var frames: [String: CGRect] = [:]
        for n in spec.nodes {
            let x = hPad + CGFloat(n.column) * (nodeW + nodeGap)
            // Single-row layouts pin to nodeRowCenterY. Multi-row layouts
            // distribute rows around the centerline so skip branches read
            // as parallel paths.
            let cy: CGFloat = rows > 1
                ? nodeRowCenterY + CGFloat(n.row) * (nodeHeight + 28) - CGFloat(rows - 1) * (nodeHeight + 28) / 2
                : nodeRowCenterY
            frames[n.id] = CGRect(
                x: x,
                y: cy - nodeHeight / 2,
                width: nodeW,
                height: nodeHeight
            )
        }
        return frames
    }

    // MARK: legend

    private var legend: some View {
        let kinds = Set(spec.edges.map(\.kind))
        return HStack(spacing: 14) {
            if kinds.contains(.forward) {
                legendItem(color: dlTealDeep, dashed: false, label: "Forward")
            }
            if kinds.contains(.backward) {
                legendItem(color: dlAmberDeep, dashed: true, label: "Backward")
            }
            if kinds.contains(.skip) {
                legendItem(color: dlInk2, dashed: false, label: "Skip")
            }
            Spacer()
        }
    }

    private func legendItem(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            LegendStroke(color: color, dashed: dashed).frame(width: 18, height: 2)
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(dlInk2)
        }
    }

    // MARK: edges

    // Edge routing
    //
    // Forward edges run straight along the node row's vertical midline. Their
    // labels float above the line. Backward edges (and skip edges) duck out
    // from the bottom of one node, arc through a control point well below the
    // node row, and re-enter the destination from below, keeping them clear
    // of the forward arrows so the two passes never overlap.

    @ViewBuilder
    private func edgePath(edge: DLFlowRichEdge, frames: [String: CGRect]) -> some View {
        if let a = frames[edge.from], let b = frames[edge.to] {
            let color = edgeColor(edge.kind)
            let dashed = edge.kind == .backward
            let r = route(from: a, to: b, kind: edge.kind)
            ZStack {
                ShapePath { path in
                    path.move(to: r.start)
                    if let ctrl = r.control {
                        path.addQuadCurve(to: r.end, control: ctrl)
                    } else {
                        path.addLine(to: r.end)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: dashed ? [4, 4] : []))

                arrowhead(at: r.end, from: r.control ?? r.start, color: color)

                if let label = edge.label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(color)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(Color.white).overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 0.6)))
                        .position(r.labelPos)
                }
            }
        }
    }

    private struct Route {
        let start: CGPoint
        let end: CGPoint
        let control: CGPoint?      // nil = straight line
        let labelPos: CGPoint
    }

    private func route(from a: CGRect, to b: CGRect, kind: DLFlowRichEdgeKind) -> Route {
        let centerlineY = nodeRowCenterY
        switch kind {
        case .forward:
            // Straight horizontal along node row centerline. Label above the line.
            if a.midX < b.midX {
                let s = CGPoint(x: a.maxX + 2, y: centerlineY)
                let e = CGPoint(x: b.minX - 2, y: centerlineY)
                return Route(start: s, end: e, control: nil,
                             labelPos: CGPoint(x: (s.x + e.x) / 2, y: centerlineY - 12))
            } else {
                let s = CGPoint(x: a.minX - 2, y: centerlineY)
                let e = CGPoint(x: b.maxX + 2, y: centerlineY)
                return Route(start: s, end: e, control: nil,
                             labelPos: CGPoint(x: (s.x + e.x) / 2, y: centerlineY - 12))
            }
        case .backward:
            // Arc below the node band so backward path never overlaps forward.
            let dipY = nodeRowCenterY + nodeHeight / 2 + 56
            let s = CGPoint(x: a.midX - 8, y: a.maxY - 2)
            let e = CGPoint(x: b.midX + 8, y: b.maxY - 2)
            let ctrl = CGPoint(x: (s.x + e.x) / 2, y: dipY)
            return Route(start: s, end: e, control: ctrl,
                         labelPos: CGPoint(x: ctrl.x, y: dipY + 6))
        case .skip:
            // Arc above the node band, mirror of backward.
            let lift = nodeRowCenterY - nodeHeight / 2 - 36
            let s = CGPoint(x: a.midX, y: a.minY + 2)
            let e = CGPoint(x: b.midX, y: b.minY + 2)
            let ctrl = CGPoint(x: (s.x + e.x) / 2, y: lift)
            return Route(start: s, end: e, control: ctrl,
                         labelPos: CGPoint(x: ctrl.x, y: lift - 4))
        }
    }

    private func arrowhead(at tip: CGPoint, from origin: CGPoint, color: Color) -> some View {
        let dx = tip.x - origin.x
        let dy = tip.y - origin.y
        let angle = atan2(dy, dx)
        let size: CGFloat = 6
        return ShapePath { path in
            path.move(to: tip)
            path.addLine(to: CGPoint(
                x: tip.x - size * cos(angle - .pi / 7),
                y: tip.y - size * sin(angle - .pi / 7)
            ))
            path.addLine(to: CGPoint(
                x: tip.x - size * cos(angle + .pi / 7),
                y: tip.y - size * sin(angle + .pi / 7)
            ))
            path.closeSubpath()
        }
        .fill(color)
    }

    private func edgeColor(_ kind: DLFlowRichEdgeKind) -> Color {
        switch kind {
        case .forward:  return dlTealDeep
        case .backward: return dlAmberDeep
        case .skip:     return dlInk2
        }
    }

    // MARK: nodes

    @ViewBuilder
    private func nodeView(node: DLFlowRichNode) -> some View {
        let isActive = selection == node.id
        let role = roleStyle(node.role)
        Button(action: { selection = node.id }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? role.fill.opacity(0.18) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(role.stroke, lineWidth: isActive ? 2 : 1.2)
                    )
                    .shadow(color: isActive ? role.fill.opacity(0.20) : .clear, radius: 6, y: 2)

                VStack(spacing: 2) {
                    Text(node.label)
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(role.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let sub = node.sublabel {
                        Text(sub)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(role.text.opacity(0.65))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 6)
            }
            .opacity(selection == nil || isActive ? 1 : 0.55)
        }
        .buttonStyle(.plain)
    }

    private struct RoleStyle {
        let stroke: Color
        let fill: Color
        let text: Color
    }

    private func roleStyle(_ role: DLFlowRichRole) -> RoleStyle {
        switch role {
        case .input:    return RoleStyle(stroke: dlTealDeep.opacity(0.6), fill: dlTealDeep, text: dlInk2)
        case .process:  return RoleStyle(stroke: dlLine, fill: dlInk2, text: dlInk2)
        case .output:   return RoleStyle(stroke: dlAmberDeep.opacity(0.7), fill: dlAmberDeep, text: dlInk2)
        case .loss:     return RoleStyle(stroke: dlRose.opacity(0.7), fill: dlRose, text: dlInk2)
        case .skipNode: return RoleStyle(stroke: dlInk3.opacity(0.5), fill: dlInk3, text: dlInk2)
        }
    }

    // MARK: insight panel

    private var insightPanel: some View {
        let body: String = {
            if let id = selection, let n = spec.nodes.first(where: { $0.id == id }) {
                return n.panelBody
            }
            return spec.defaultInsight
        }()
        let title: String? = {
            if let id = selection, let n = spec.nodes.first(where: { $0.id == id }) {
                return n.panelTitle
            }
            return nil
        }()
        return VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(dlInk2.opacity(0.7))
            }
            Text(body)
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(dlInk3)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(dlPaper2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(dlLine, lineWidth: 1))
        )
    }
}

// MARK: - EquationRichView
//
// Hand-typeset interactive equation. Each tappable term lights up; an
// explanation panel below the equation swaps in the term's title + body.
// Operators are rendered muted and ignore taps. Layout is a single
// baseline-aligned HStack with sup/sub stacks, scaled down if the equation
// outgrows the available width.

private struct EquationRichView: View {
    let spec: DLEquationRichSpec
    @Binding var selection: String?

    @State private var animatedIn: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(dlLine, lineWidth: 1))

                VStack(spacing: 14) {
                    Text((spec.promptText ?? "TAP ANY TERM").uppercased())
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .tracking(1.4)
                        .foregroundStyle(dlInk3.opacity(0.55))

                    equationLine
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 14)
            }

            insightPanel
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { animatedIn = true } }
    }

    // MARK: equation

    private var equationLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            ForEach(Array(spec.terms.enumerated()), id: \.offset) { _, term in
                termView(term)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }

    @ViewBuilder
    private func termView(_ term: DLEquationTerm) -> some View {
        let isActive = selection == term.id
        let color = tokenColor(term.color)
        let glyph = HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(term.display)
                .font(.system(size: 30, design: .serif))
                .foregroundStyle(color)
            if let sup = term.sup {
                Text(sup)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(color)
                    .baselineOffset(14)
            }
            if let sub = term.sub {
                Text(sub)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(color)
                    .baselineOffset(-6)
            }
        }
        .padding(.horizontal, term.isTappable ? 5 : 2)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? color.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? color.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )

        if term.isTappable {
            Button(action: {
                selection = isActive ? nil : term.id
            }) {
                glyph
            }
            .buttonStyle(.plain)
        } else {
            glyph
        }
    }

    // MARK: panel

    private var insightPanel: some View {
        let active = spec.terms.first(where: { $0.id == selection && $0.isTappable })
        let color = active.map { tokenColor($0.color) } ?? dlLine
        return VStack(alignment: .leading, spacing: 6) {
            if let term = active, let title = term.panelTitle {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(color)
                Text(term.panelBody ?? "")
                    .font(.system(size: 12.5, design: .serif))
                    .foregroundStyle(dlInk3)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(spec.defaultInsight)
                    .font(.system(size: 12, design: .serif))
                    .italic()
                    .foregroundStyle(dlInk3.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(active != nil ? color.opacity(0.06) : dlPaper2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(active != nil ? 0.5 : 0.4), lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.18), value: selection)
    }

    private func tokenColor(_ token: DLEquationTermColor) -> Color {
        switch token {
        case .teal:  return dlTealDeep
        case .amber: return dlAmberDeep
        case .rose:  return dlRose
        case .ink:   return dlInk2
        case .muted: return dlInk3.opacity(0.5)
        }
    }
}

#Preview {
    DailyLoopView()
}
