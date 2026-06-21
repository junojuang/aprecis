import SwiftUI

// MARK: - Learning Flow
//
// A free-form, card-by-card learning engine for hand-curated paper lessons.
// Unlike DailyLoopView's fixed 8-slot sequence, a lesson is an ordered array
// of cards of any kind and any length — cover, prose, in-context glossary,
// bespoke interactive, recap. The engine handles paging, the progress rail,
// gated advancement (interactive cards must be explored before Continue
// unlocks), and the editorial chrome. Card content is supplied per lesson.

// MARK: Flow progress

/// Shared, per-session exploration state. Interactive cards mark themselves
/// explored once the reader has actually engaged with them, which unlocks the
/// Continue button for that card.
final class FlowProgress: ObservableObject {
    @Published private(set) var explored: Set<String> = []
    func markExplored(_ id: String) { explored.insert(id) }
    func isExplored(_ id: String) -> Bool { explored.contains(id) }
}

// MARK: Card theme

/// The visual mood of a card. The cover runs dark and dramatic; teaching
/// cards run on warm paper; interactive cards get a faint teal focus wash.
enum LessonTheme {
    case cover, paper, focus

    var ink: Color {
        switch self {
        case .cover: return Color(hex: "f4f1ea")
        case .paper, .focus: return inkColor
        }
    }
    var muted: Color {
        switch self {
        case .cover: return Color(hex: "f4f1ea").opacity(0.62)
        case .paper, .focus: return mutedText
        }
    }

    @ViewBuilder var background: some View {
        switch self {
        case .cover:
            ZStack {
                Color(hex: "10131a")
                RadialGradient(colors: [tealAccent.opacity(0.28), .clear],
                               center: .init(x: 0.5, y: 0.34),
                               startRadius: 4, endRadius: 460)
            }
        case .paper:
            paperBg
        case .focus:
            ZStack {
                paperBg
                LinearGradient(colors: [tealLight.opacity(0.5), .clear],
                               startPoint: .top, endPoint: .center)
            }
        }
    }
}

// MARK: Card model

/// One card in a lesson. `build` receives the shared `FlowProgress` so
/// interactive cards can report exploration. `requiresExploration` gates the
/// Continue button until the card's id is marked explored.
struct LessonCard: Identifiable {
    let id: String
    let theme: LessonTheme
    let advanceLabel: String
    let requiresExploration: Bool
    /// Terms this card contributes to the lesson glossary. Set by the
    /// `.glossary` factory; every other card kind leaves it empty.
    let glossaryTerms: [LessonGlossaryTerm]
    let build: (FlowProgress) -> AnyView

    init(id: String,
         theme: LessonTheme,
         advanceLabel: String = "Continue",
         requiresExploration: Bool = false,
         glossaryTerms: [LessonGlossaryTerm] = [],
         @ViewBuilder build: @escaping (FlowProgress) -> some View) {
        self.id = id
        self.theme = theme
        self.advanceLabel = advanceLabel
        self.requiresExploration = requiresExploration
        self.glossaryTerms = glossaryTerms
        self.build = { AnyView(build($0)) }
    }
}

struct LearningLesson {
    let paperId: String

    /// Cards exactly as authored, including any standalone `.glossary` card.
    /// Kept private so the visible flow can drop glossary cards while their
    /// terms still feed the inline tappable glossary below.
    private let authoredCards: [LessonCard]

    init(paperId: String, cards: [LessonCard]) {
        self.paperId = paperId
        self.authoredCards = cards
    }

    /// Cards shown in the flow. The standalone glossary ("words, in plain
    /// English") card is intentionally removed from every lesson — it felt
    /// forced and appeared out of nowhere mid-narrative. Its terms are still
    /// preserved in `glossary` below, so tappable terms in prose keep
    /// resolving. Glossary cards are the only cards that carry `glossaryTerms`,
    /// so filtering on that removes exactly them and nothing else.
    var cards: [LessonCard] {
        authoredCards.filter { $0.glossaryTerms.isEmpty }
    }

    /// Inline glossary for the whole lesson: every technical term tappable in
    /// prose resolves through here. Sourced from the curated
    /// `FoundationalGlossaries` for this paper, then overlaid with the
    /// lesson's own in-context glossary-card entries (which win, being
    /// hand-written for this exact lesson) even though that card is no longer
    /// shown in the flow.
    var glossary: [String: String] {
        let slug = paperId.split(separator: ":").last.map(String.init) ?? ""
        var dict = FoundationalGlossaries.dict(for: slug)
        for card in authoredCards {
            for t in card.glossaryTerms { dict[t.term] = t.definition }
        }
        return dict
    }
}

// MARK: - Flow view

struct LearningFlowView: View {
    let lesson: LearningLesson
    var onClose: () -> Void = {}

    @StateObject private var progress = FlowProgress()
    @State private var index: Int
    @State private var dragX: CGFloat = 0

    init(lesson: LearningLesson, onClose: @escaping () -> Void = {}) {
        self.lesson = lesson
        self.onClose = onClose
        // Resume exactly where the reader left off. The shared store keeps a
        // per-paper last-card index; clamp it to the current card count in
        // case the lesson changed length since it was last opened.
        let saved = ReadingProgressStore.shared.lastCardIndex(for: lesson.paperId) ?? 0
        let clamped = max(0, min(saved, max(lesson.cards.count - 1, 0)))
        _index = State(initialValue: clamped)
    }
    /// Direction of the most recent index change. Drives the asymmetric
    /// transition so swiping back actually reads as back (new card slides
    /// in from the left, old card slides off to the right) instead of
    /// reusing the forward-direction animation.
    @State private var goingBack = false

    private var card: LessonCard { lesson.cards[min(index, lesson.cards.count - 1)] }
    private var isLast: Bool { index >= lesson.cards.count - 1 }
    private var canAdvance: Bool {
        // Don't trap assistive-technology users behind an interactive they may
        // not be able to operate: VoiceOver / Switch Control / Full Keyboard
        // Access users can always advance, exploration-gated or not.
        if assistiveTechRunning { return true }
        return !card.requiresExploration || progress.isExplored(card.id)
    }

    private var assistiveTechRunning: Bool {
        UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }

    var body: some View {
        ZStack {
            card.theme.background
                .ignoresSafeArea()
                .motionAware(.easeInOut(duration: 0.4), value: index)

            VStack(spacing: 0) {
                topChrome
                cardBody
                advanceBar
            }
        }
        // The flow carries its own close button + progress rail, so suppress
        // any host NavigationStack chrome.
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { persistProgress() }
        .onChange(of: index) { _, _ in persistProgress() }
    }

    /// Records the current card index so the paper resumes here next time and
    /// the 0...1 fraction (used by progress bars / rings) stays in sync. Once
    /// the reader reaches the final card the paper counts as finished, which
    /// feeds the daily goal, streak, and bundle-step gating.
    private func persistProgress() {
        let store = ReadingProgressStore.shared
        store.setLastCardIndex(index, totalCards: lesson.cards.count, for: lesson.paperId)

        if lesson.cards.count > 1, index >= lesson.cards.count - 1 {
            store.markCompletedToday(paperId: lesson.paperId)
            store.markComplete(paperId: lesson.paperId)
        }
    }

    // MARK: chrome

    private var topChrome: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundStyle(card.theme.ink.opacity(0.7))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close lesson")

            // Segmented progress rail — one segment per card.
            HStack(spacing: 4) {
                ForEach(lesson.cards.indices, id: \.self) { i in
                    Capsule()
                        .fill(card.theme.ink.opacity(i <= index ? 0.9 : 0.18))
                        .frame(height: 3)
                }
            }
            .motionAware(.easeInOut(duration: 0.3), value: index)
            .accessibilityHidden(true)

            Text("\(index + 1)/\(lesson.cards.count)")
                .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundStyle(card.theme.muted)
                .frame(width: 38)
                .accessibilityLabel("Card \(index + 1) of \(lesson.cards.count)")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private var cardBody: some View {
        ScrollView(showsIndicators: false) {
            card.build(progress)
                .environment(\.lessonGlossary, lesson.glossary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
        }
        .id(index) // reset scroll + retrigger card transition
        .offset(x: dragX)
        .transition(.asymmetric(
            insertion: .move(edge: goingBack ? .leading : .trailing)
                .combined(with: .opacity),
            removal: .move(edge: goingBack ? .trailing : .leading)
                .combined(with: .opacity)))
        .motionAware(.snappy(duration: 0.34), value: index)
        .simultaneousGesture(backSwipe)
    }

    private var advanceBar: some View {
        VStack(spacing: 8) {
            if card.requiresExploration && !canAdvance {
                Text("Try it above to continue")
                    .scaledFont(size: 12, design: .serif)
                    .italic()
                    .foregroundStyle(card.theme.muted)
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if isLast { onClose() } else {
                    goingBack = false
                    withAnimation(.snappy(duration: 0.34)) { index += 1 }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(isLast ? "Finish" : card.advanceLabel)
                        .scaledFont(size: 15, weight: .semibold)
                    Image(systemName: isLast ? "checkmark" : "arrow.right")
                        .scaledFont(size: 12, weight: .bold)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(canAdvance ? .white : card.theme.muted)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canAdvance ? tealAccent : card.theme.ink.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
            .motionAware(.easeOut(duration: 0.2), value: canAdvance)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 26)
    }

    /// Right-swipe goes back a card; never advances (forward is gated by the
    /// Continue button so interactive cards are actually explored).
    ///
    /// Scoped to an *edge* swipe — the drag must start within 32pt of the left
    /// edge. Interior drags belong to the card's own interactive controls
    /// (weight sliders, draggable diagrams), so they no longer get hijacked.
    private static let edgeZone: CGFloat = 32

    private var backSwipe: some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { v in
                guard v.startLocation.x < Self.edgeZone,
                      v.translation.width > 0, index > 0 else { return }
                // Follow the finger 1:1 up to a soft limit so the card
                // actually reads as moving with the swipe; past the limit
                // the motion rubber-bands so it never feels uncontrolled.
                let raw = v.translation.width
                let soft: CGFloat = 120
                dragX = raw <= soft ? raw : soft + (raw - soft) * 0.35
            }
            .onEnded { v in
                let onEdge = v.startLocation.x < Self.edgeZone
                let pastThreshold = v.translation.width > 80
                if onEdge, pastThreshold, index > 0 {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    goingBack = true
                    withAnimation(.snappy(duration: 0.34)) {
                        index -= 1
                        dragX = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        dragX = 0
                    }
                }
            }
    }
}
