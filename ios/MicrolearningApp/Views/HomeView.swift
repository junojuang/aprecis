import SwiftUI
import UniformTypeIdentifiers

// MARK: - HomeView

struct HomeView: View {
    @ObservedObject var viewModel: FeedViewModel
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedLoop: IdentifiedLoop? = nil

    var body: some View {
        ZStack {
            homeSwipeBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HomeGreeting(name: greetingName)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 16)

                TodaysPaperDeck(
                    papers: previewPapers,
                    onPick: { picked in
                        selectedLoop = IdentifiedLoop(id: picked.paperId ?? UUID().uuidString,
                                                     content: picked)
                    },
                    onNeedMore: {
                        Task { await viewModel.loadMore() }
                    }
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 0)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.decks.isEmpty { await viewModel.loadFeed() }
        }
        .fullScreenCover(item: $selectedLoop) { wrapped in
            DailyLoopView(content: wrapped.content)
        }
    }

    @AppStorage("profile.displayNameOverride") private var displayNameOverride: String = ""

    private var greetingName: String? {
        let override = displayNameOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        if !override.isEmpty { return override }
        if case .loggedIn(let session) = auth.state,
           let email = session.user.email, !email.isEmpty {
            return String(email.split(separator: "@").first ?? Substring(email))
        }
        return nil
    }

    private var homeSwipeBackground: some View {
        ZStack {
            paperBg
            RadialGradient(
                colors: [tealAccent.opacity(0.18), .clear],
                center: UnitPoint(x: 0.86, y: 0.12),
                startRadius: 0,
                endRadius: 360
            )
            RadialGradient(
                colors: [amberAccent.opacity(0.16), .clear],
                center: UnitPoint(x: 0.16, y: 0.9),
                startRadius: 0,
                endRadius: 360
            )
        }
    }

    /// Papers shown in the swipeable Today's Lesson deck. Backend
    /// decks carrying a blueprint render first; then the curated catalog.
    /// Deduped by **canonical brace** so the same underlying arXiv work
    /// never appears twice (e.g. `arxiv:` + `hn:` ingest of the same preprint).
    private var previewPapers: [DailyLoopContent] {
        var seen = Set<String>()
        var out: [DailyLoopContent] = []
        for deck in viewModel.decks {
            guard let bp = deck.blueprint else { continue }
            let key = deck.canonicalBraceKey
            if seen.insert(key).inserted {
                out.append(DailyLoopContent(deck: deck, blueprint: bp).withPaperId(deck.paperId))
            }
        }
        for (id, c) in DailyLoopContent.allPrepared {
            let synthetic = CardDeck.fromLoop(paperId: id, content: c)
            let key = synthetic.canonicalBraceKey
            if seen.insert(key).inserted {
                out.append(c.withPaperId(id))
            }
        }
        return out
    }

}

// MARK: - BookshelfView
//
// Horizontal scrubbable bookshelf. Each saved paper becomes a vertical spine
// with deterministic width, height, and cover color derived from its paperId.
// The currently centered spine is bound via scrollPosition; its title floats
// in an editorial pill beneath the shelf. Tapping the centered spine opens
// the deck; tapping any other spine recenters it.

// Preference key used to bubble each spine's horizontal center up to
// the BookshelfView so the focused spine can be picked from scroll
// position without using `scrollPosition(id:)` as a two-way binding.
// The two-way binding caused the shelf to fight the user's scroll and
// jump back to the leftmost item when scrubbing.
private struct SpineCentersKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Bubbles up when the pinned unsave strip is idle (no spine being dragged) so Profile can treat
/// taps in surrounding editorial chrome as dismiss targets.
struct ShelfTrashTapAwayArmedKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct BookshelfView: View {
    let decks: [CardDeck]
    /// Parent increments this to collapse the pinned trash dock (tap-away outside the shelf).
    @Binding private var trayDismissNonce: Int

    @ObservedObject private var savedStore = SavedPapersStore.shared

    init(decks: [CardDeck], trayDismissNonce: Binding<Int> = .constant(0)) {
        self.decks = decks
        self._trayDismissNonce = trayDismissNonce
    }

    @State private var pendingNavId: String?
    @State private var focusedId: String?
    /// Highlights the trash can while a dragged book hovers over it (bound to `.onDrop(isTargeted:)`).
    @State private var pointerOverTrash: Bool = false
    /// Trash dock pinned while a book is being dragged and after a drag — it stays up for
    /// multi-unsaves until dismissed. Also set by long‑press on the gutter/title to reveal it.
    @State private var removeDockRevealed: Bool = false
    /// Last `trayDismissNonce` applied from the parent (Profile tap-away).
    @State private var lastConsumedTrayDismissNonce: Int = 0

    private let shelfHeight: CGFloat = 210
    private let trashDockHeight: CGFloat = 86
    private let shelfRevealGutterWidth: CGFloat = 22

    private var showTrashDock: Bool { removeDockRevealed }

    var body: some View {
        VStack(spacing: 10) {
            titleLabel
            shelfStack
        }
        .padding(.bottom, 4)
        .onAppear {
            if focusedId == nil { focusedId = decks.first?.id }
        }
        .onChange(of: decks.map(\.paperId).sorted()) { _, _ in
            if let fid = focusedId, decks.first(where: { $0.id == fid }) == nil {
                focusedId = decks.first?.id
            }
        }
        .onAppear { lastConsumedTrayDismissNonce = trayDismissNonce }
        .onChange(of: trayDismissNonce) { _, new in
            guard new != lastConsumedTrayDismissNonce else { return }
            lastConsumedTrayDismissNonce = new
            removeDockRevealed = false
        }
        .preference(key: ShelfTrashTapAwayArmedKey.self, value: showTrashDock)
        .navigationDestination(item: $pendingNavId) { id in
            if let deck = decks.first(where: { $0.id == id }) {
                DeckDestination(deck: deck)
            }
        }
    }

    private func revealTrashDockOutsideBooks() {
        guard !removeDockRevealed else { return }
        removeDockRevealed = true
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Fixed-width regions beside the horizontal scroll area (wood/plank shows through) — long-press to show the unsave dock.
    private func shelfOutsideBooksLongPressGutter() -> some View {
        Color.clear
            .frame(width: shelfRevealGutterWidth)
            .frame(height: shelfHeight)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.48) {
                revealTrashDockOutsideBooks()
            }
    }

    /// Begins a system drag for a book. Returns the item provider that carries the
    /// paper id so the trash `.onDrop` can identify which paper to unsave. The drag
    /// itself is driven by UIKit's drag interaction, which lifts the spine out of the
    /// scroll view without ever blocking a horizontal scroll swipe.
    private func beginBookDrag(_ deck: CardDeck) -> NSItemProvider {
        // Reveal the trash dock the moment a book is lifted, mirroring the
        // "grab a book, the bin slides up" intent. Deferred to the next runloop
        // tick so we never mutate state during a view update.
        DispatchQueue.main.async {
            if !removeDockRevealed {
                removeDockRevealed = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        return NSItemProvider(object: deck.paperId as NSString)
    }

    private func handleTrashDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let paperId = object as? String else { return }
            DispatchQueue.main.async { unsaveDroppedPaper(paperId) }
        }
        return true
    }

    private func unsaveDroppedPaper(_ paperId: String) {
        guard let deck = decks.first(where: { $0.paperId == paperId }) else { return }
        if focusedId == deck.id {
            focusedId = decks.first(where: { $0.paperId != paperId })?.id
        }
        savedStore.remove(paperId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Keep `removeDockRevealed` so multiple books can be dragged out in a row;
        // a tap-away on surrounding chrome collapses it.
    }

    private var shelfStack: some View {
        GeometryReader { geo in
            let midX = geo.size.width / 2
            let sidePad = max(midX - 30, 24)
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    shelfPlank
                        .mask(edgeFadeMask)

                    HStack(spacing: 0) {
                        shelfOutsideBooksLongPressGutter()

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 6) {
                                ForEach(decks) { deck in
                                    BookSpine(deck: deck)
                                        .scaleEffect(deck.id == focusedId ? 1.06 : 0.94, anchor: .bottom)
                                        .opacity(deck.id == focusedId ? 1.0 : 0.78)
                                        .motionAware(.snappy(duration: 0.18, extraBounce: 0.18), value: focusedId)
                                        .background(
                                            GeometryReader { proxy in
                                                Color.clear.preference(
                                                    key: SpineCentersKey.self,
                                                    value: [deck.id: proxy.frame(in: .named("shelfScroll")).midX]
                                                )
                                            }
                                        )
                                        .contentShape(Rectangle())
                                        // Hold-to-lift + drag-to-trash is delegated to the system
                                        // drag interaction. Unlike a SwiftUI `DragGesture`, it lifts
                                        // the spine out of the scroll view without starving the
                                        // horizontal pan, so a quick swipe still scrolls and a press
                                        // still lifts a book — one finger, one continuous motion.
                                        .onDrag { beginBookDrag(deck) } preview: {
                                            BookSpine(deck: deck)
                                                .shadow(color: inkColor.opacity(0.3), radius: 12, x: 0, y: 8)
                                        }
                                        .onTapGesture { pendingNavId = deck.id }
                                        // VoiceOver / Switch Control / Voice Control: the spine is a
                                        // button that opens the paper, plus a custom action to remove
                                        // it (the drag-to-trash gesture is unreachable for these users).
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel(deck.title ?? deck.hook ?? "Saved paper")
                                        .accessibilityValue(spineProgressDescription(for: deck))
                                        .accessibilityHint("Opens this paper")
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAction(named: "Remove from shelf") {
                                            unsaveDroppedPaper(deck.paperId)
                                        }
                                }
                            }
                            .padding(.horizontal, sidePad)
                            .frame(height: shelfHeight, alignment: .bottom)
                        }
                        .coordinateSpace(name: "shelfScroll")
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                        .sensoryFeedback(.selection, trigger: focusedId)

                        shelfOutsideBooksLongPressGutter()
                    }
                    .overlay(alignment: .top) {
                        // Narrow band above spines (~6pt clears largest scaled spine tops; outside book covers).
                        Color.clear
                            .frame(height: 6)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onLongPressGesture(minimumDuration: 0.48) {
                                revealTrashDockOutsideBooks()
                            }
                    }
                    .mask(edgeFadeMask)
                    .onPreferenceChange(SpineCentersKey.self) { centers in
                        guard !centers.isEmpty else { return }
                        if let closest = centers.min(by: { abs($0.value - midX) < abs($1.value - midX) })?.key,
                           closest != focusedId {
                            focusedId = closest
                        }
                    }
                }
                .frame(height: shelfHeight + 14)

                if showTrashDock {
                    shelfTrashDock
                        .frame(height: trashDockHeight)
                        .transition(motionAwareTransition(.move(edge: .bottom).combined(with: .opacity)))
                }
            }
            .coordinateSpace(name: "shelfRoot")
        }
        .frame(height: shelfHeight + 14 + (showTrashDock ? trashDockHeight : 0))
        .motionAware(.spring(response: 0.36, dampingFraction: 0.86), value: showTrashDock)
    }

    /// Spoken reading-state for a spine, so VoiceOver conveys progress that the
    /// printed ribbon shows only visually.
    private func spineProgressDescription(for deck: CardDeck) -> String {
        let p = ReadingProgressStore.shared.progress(for: deck.paperId)
        if p >= 0.98 { return "Finished" }
        if p > 0.04 { return "\(Int((p * 100).rounded())) percent read" }
        return "Not started"
    }

    private var shelfTrashDock: some View {
        VStack(spacing: 10) {
            Image(systemName: "trash")
                .symbolRenderingMode(.hierarchical)
                .scaledFont(size: 20, weight: .semibold)
                .foregroundStyle(pointerOverTrash ? Color.white : inkColor.opacity(0.92))
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(pointerOverTrash ? Color.red.opacity(0.95) : Color.white.opacity(0.95))
                )
                .overlay(
                    Circle()
                        .stroke(pointerOverTrash ? Color.clear : borderColor.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: inkColor.opacity(pointerOverTrash ? 0.12 : 0.06), radius: pointerOverTrash ? 10 : 4, x: 0, y: 4)
                .scaleEffect(pointerOverTrash ? 1.08 : 1.0)

            Text("Release to unsave")
                .scaledFont(size: 10, weight: .bold)
                .tracking(1.1)
                .foregroundStyle(mutedText.opacity(0.95))
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tealAccent.opacity(pointerOverTrash ? 0.14 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(borderColor.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 8)
        )
        .contentShape(Rectangle())
        .onDrop(of: [.text], isTargeted: $pointerOverTrash) { providers in
            handleTrashDrop(providers)
        }
        .onChange(of: pointerOverTrash) { _, isOver in
            if isOver { UISelectionFeedbackGenerator().selectionChanged() }
        }
    }

    // Single-line serif title of the focused deck, with a tiny meta
    // caption underneath. Updates live as the user scrubs because the
    // scrollPosition binding drives `focusedId`.
    private var titleLabel: some View {
        let active = decks.first(where: { $0.id == focusedId }) ?? decks.first
        return VStack(spacing: 6) {
            Text(active?.title ?? active?.hook ?? "")
                .scaledFont(size: 17, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .truncationMode(.tail)
                .padding(.horizontal, 26)
                .id("title-\(active?.id ?? "")")
                .transition(.opacity)
            Text(metaLine(for: active))
                .scaledFont(size: 10, weight: .semibold)
                .tracking(1.4)
                .foregroundStyle(mutedText)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .id("meta-\(active?.id ?? "")")
                .transition(.opacity)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.48) {
            revealTrashDockOutsideBooks()
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                guard removeDockRevealed else { return }
                removeDockRevealed = false
            }
        )
        .motionAware(.snappy(duration: 0.14, extraBounce: 0.12), value: focusedId)
    }

    private func metaLine(for deck: CardDeck?) -> String {
        guard let deck else { return "" }
        let tag = deck.topicTagUppercased
        if let date = deck.publishedAt {
            let f = DateFormatter(); f.dateFormat = "yyyy"
            return "\(tag) · \(f.string(from: date))"
        }
        return tag
    }

    private var edgeFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.00),
                .init(color: .black, location: 0.06),
                .init(color: .black, location: 0.94),
                .init(color: .clear, location: 1.00),
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var shelfPlank: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [inkColor.opacity(0.10), .clear],
                startPoint: .bottom, endPoint: .top
            )
            .frame(height: 10)
            Rectangle()
                .fill(inkColor.opacity(0.22))
                .frame(height: 1)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "d9cdb6"), Color(hex: "c2b193")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 6)
            Rectangle()
                .fill(inkColor.opacity(0.12))
                .frame(height: 1)
        }
    }
}

// MARK: - BookSpine

// MARK: - BookSpine (closed)

struct BookSpine: View {
    let deck: CardDeck

    @ObservedObject private var progressStore = ReadingProgressStore.shared

    var body: some View {
        let geometry = SpineGeometry.compute(for: deck.paperId)
        let palette  = SpinePalette.pick(for: deck.paperId)
        let progress = progressStore.progress(for: deck.paperId)

        spineContent(geometry: geometry, palette: palette, progress: progress)
    }

    @ViewBuilder
    private func spineContent(geometry: SpineGeometry.Result,
                              palette: SpinePalette.Resolved,
                              progress: Double) -> some View {
        ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.cover, palette.coverDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                hatching(color: palette.shadow)

                // Top + bottom accent bands
                VStack {
                    Rectangle().fill(palette.accent).frame(height: 1).padding(.top, 10)
                    Spacer()
                    Rectangle().fill(palette.accent).frame(height: 1).padding(.bottom, 10)
                }

                // Centered emblem (deterministic glyph per paper)
                spineEmblem(width: geometry.width,
                            height: geometry.height,
                            palette: palette)

                // Read-state ribbon overlay
                readRibbon(progress: progress,
                           geometry: geometry,
                           palette: palette)
            }
            .frame(width: geometry.width, height: geometry.height)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(palette.shadow.opacity(0.55), lineWidth: 0.5)
            )
            .shadow(color: inkColor.opacity(0.10), radius: 4, x: 0, y: 2)
    }

    // Cheap cloth-weave illusion via repeating LinearGradient stops.
    // Avoids Canvas redraw cost during scroll.
    private func hatching(color: Color) -> some View {
        LinearGradient(
            stops: [
                .init(color: color.opacity(0.10), location: 0.00),
                .init(color: .clear,              location: 0.05),
                .init(color: color.opacity(0.06), location: 0.50),
                .init(color: .clear,              location: 0.95),
                .init(color: color.opacity(0.12), location: 1.00)
            ],
            startPoint: .leading, endPoint: .trailing
        )
        .allowsHitTesting(false)
    }

    private func spineEmblem(width: CGFloat,
                             height: CGFloat,
                             palette: SpinePalette.Resolved) -> some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            Rectangle()
                .fill(palette.accent.opacity(0.75))
                .frame(width: width * 0.45, height: 0.5)
            Image(systemName: SpineEmblem.pick(for: deck.paperId))
                .scaledFont(size: 13, weight: .regular)
                .foregroundStyle(palette.accent)
                .padding(.vertical, 2)
            Rectangle()
                .fill(palette.accent.opacity(0.75))
                .frame(width: width * 0.45, height: 0.5)
            Spacer(minLength: 0)
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func readRibbon(progress: Double,
                            geometry: SpineGeometry.Result,
                            palette: SpinePalette.Resolved) -> some View {
        if progress >= 0.98 {
            // Completed: chevron pennant tucked at top
            VStack {
                ZStack {
                    Triangle()
                        .fill(palette.accent)
                        .frame(width: geometry.width - 8, height: 9)
                    Image(systemName: "checkmark")
                        .scaledFont(size: 6, weight: .heavy)
                        .foregroundStyle(palette.coverDeep)
                        .offset(y: -1)
                }
                .padding(.top, 2)
                Spacer()
            }
        } else if progress > 0.04 {
            // In-progress: thin bookmark line at read-percent position
            VStack(spacing: 0) {
                Spacer().frame(height: geometry.height * CGFloat(progress))
                Rectangle()
                    .fill(palette.accent)
                    .frame(height: 2)
                Spacer()
            }
            .frame(width: geometry.width)
        }
    }
}

// MARK: - Triangle (for completed ribbon)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - OpenBook
//
// The centered shelf item. Renders as a real open book: two cream pages
// hinged at a center fold, framed by a thin cover band drawn from the
// paper's palette. Left page = summary excerpt, right page = title + meta.
// Tap (handled by parent) opens the deck.

struct OpenBook: View {
    let deck: CardDeck
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let palette = SpinePalette.pick(for: deck.paperId)
        let pageW = (width - 14) / 2

        ZStack {
            // Outer cover band — book hardcover edge visible behind pages
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.cover, palette.coverDeep],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Pages (cream, slightly inset from cover)
            HStack(spacing: 0) {
                page(width: pageW, side: .left, palette: palette)
                centerGutter
                page(width: pageW, side: .right, palette: palette)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 6)
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(palette.shadow.opacity(0.5), lineWidth: 0.6)
        )
        .shadow(color: inkColor.opacity(0.22), radius: 16, x: 0, y: 8)
        .offset(y: -8)
    }

    private enum Side { case left, right }

    @ViewBuilder
    private func page(width: CGFloat, side: Side, palette: SpinePalette.Resolved) -> some View {
        ZStack {
            // Cream page w/ subtle vertical paper grain
            LinearGradient(
                colors: [Color(hex: "f9f3e4"), Color(hex: "ece2c9")],
                startPoint: side == .left ? .leading : .trailing,
                endPoint: side == .left ? .trailing : .leading
            )

            VStack(alignment: .leading, spacing: 0) {
                if side == .left {
                    leftPageBody
                } else {
                    rightPageBody(palette: palette)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width)
    }

    private var leftPageBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SUMMARY")
                .scaledFont(size: 7, weight: .bold)
                .tracking(1.6)
                .foregroundStyle(mutedText)
            Rectangle().fill(inkColor.opacity(0.12)).frame(height: 0.5)
            Text(deck.hook ?? deck.title ?? "")
                .scaledFont(size: 9, design: .serif)
                .foregroundStyle(inkColor.opacity(0.82))
                .lineSpacing(2)
                .lineLimit(10)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }

    private func rightPageBody(palette: SpinePalette.Resolved) -> some View {
        let topic = deck.topicCluster
        return VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 4)
            HStack(spacing: 5) {
                Circle().fill(topic.color).frame(width: 3, height: 3)
                Text(topic.label.uppercased())
                    .scaledFont(size: 7, weight: .bold)
                    .tracking(1.4)
                    .foregroundStyle(mutedText)
            }
            Text(deck.title ?? deck.hook ?? "Untitled")
                .scaledFont(size: 11, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
                .lineSpacing(1)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
            Rectangle().fill(palette.cover.opacity(0.6)).frame(width: 22, height: 0.6)
            if let year = yearLabel {
                Text(year)
                    .scaledFont(size: 8, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
            }
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Text("OPEN →")
                    .scaledFont(size: 7, weight: .bold)
                    .tracking(1.4)
                    .foregroundStyle(palette.cover)
            }
        }
    }

    private var yearLabel: String? {
        guard let date = deck.publishedAt else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy"
        return f.string(from: date)
    }

    // Center gutter: subtle shadow seam of the book fold
    private var centerGutter: some View {
        LinearGradient(
            colors: [
                inkColor.opacity(0.0),
                inkColor.opacity(0.22),
                inkColor.opacity(0.0)
            ],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(width: 4)
    }
}

// MARK: - Spine geometry + palette

private enum SpineGeometry {
    struct Result { let width: CGFloat; let height: CGFloat }

    static func compute(for id: String) -> Result {
        let h = stableHash(id)
        let widths: [CGFloat]  = [30, 34, 38, 42, 46, 52]
        let heights: [CGFloat] = [156, 168, 174, 180, 186, 192]
        return Result(
            width: widths[Int(h % UInt32(widths.count))],
            height: heights[Int((h / 7) % UInt32(heights.count))]
        )
    }
}

enum SpinePalette {
    struct Resolved { let cover: Color; let coverDeep: Color; let accent: Color; let shadow: Color }

    private static let palettes: [Resolved] = [
        // Burgundy
        Resolved(cover: Color(hex: "7a2a2a"), coverDeep: Color(hex: "551a1a"),
                 accent: Color(hex: "d9b46a"), shadow: Color(hex: "2a0a0a")),
        // Forest teal
        Resolved(cover: Color(hex: "1d3a3a"), coverDeep: Color(hex: "0b2222"),
                 accent: Color(hex: "c8b078"), shadow: Color(hex: "030f0f")),
        // Ink navy
        Resolved(cover: Color(hex: "1a2746"), coverDeep: Color(hex: "0c152a"),
                 accent: Color(hex: "d9b46a"), shadow: Color(hex: "050a18")),
        // Ochre
        Resolved(cover: Color(hex: "8a5a18"), coverDeep: Color(hex: "5a3a0a"),
                 accent: Color(hex: "f4ddae"), shadow: Color(hex: "2c1c05")),
        // Plum
        Resolved(cover: Color(hex: "432a5a"), coverDeep: Color(hex: "2a1b3a"),
                 accent: Color(hex: "d8c79a"), shadow: Color(hex: "150a22")),
        // Hunter green
        Resolved(cover: Color(hex: "2b4a2b"), coverDeep: Color(hex: "182d18"),
                 accent: Color(hex: "d4b87a"), shadow: Color(hex: "0a160a")),
        // Cream w/ ink (rare contrast spine)
        Resolved(cover: Color(hex: "e6dcc4"), coverDeep: Color(hex: "c8bb9a"),
                 accent: Color(hex: "5a3a18"), shadow: Color(hex: "8a7a55")),
        // Slate
        Resolved(cover: Color(hex: "3a4654"), coverDeep: Color(hex: "232b35"),
                 accent: Color(hex: "c9b88a"), shadow: Color(hex: "0e131a")),
    ]

    static func pick(for id: String) -> Resolved {
        let h = stableHash(id)
        return palettes[Int(h % UInt32(palettes.count))]
    }
}

private func stableHash(_ s: String) -> UInt32 {
    var h: UInt32 = 5381
    for b in s.utf8 { h = (h &* 33) &+ UInt32(b) }
    return h
}

// MARK: - SpineEmblem

private enum SpineEmblem {
    static let glyphs: [String] = [
        "asterisk",
        "circle",
        "diamond",
        "hexagon",
        "triangle",
        "seal",
        "sparkle",
        "moon.stars",
        "leaf",
        "key",
        "flame",
        "atom"
    ]

    static func pick(for id: String) -> String {
        let h = stableHash(id)
        return glyphs[Int(h % UInt32(glyphs.count))]
    }
}

// MARK: - EditorialDivider
//
// Thin rule with a centered teal accent dot and offset secondary tick. Sits
// between major home sections to give the feed an editorial spine and lifts
// the Library beneath it into its own destination, rather than another row.

struct EditorialDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(borderColor).frame(height: 1)
            Circle().fill(tealAccent.opacity(0.55)).frame(width: 5, height: 5)
            Rectangle().fill(borderColor).frame(height: 1)
            Rectangle().fill(borderColor.opacity(0.5)).frame(width: 22, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 14)
    }
}

// MARK: - LibraryCard
//
// Heavyweight library row with serif title, cover thumb, source eyebrow, and
// a progress underline at the foot. Bigger than `PaperRowView` so the saved
// shelf reads as a destination, not just another list of feed items.

struct LibraryCard: View {
    let deck: CardDeck
    let colorIndex: Int
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var progress: Double { progressStore.progress(for: deck.paperId) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    libraryEyebrow

                    Text(deck.hook ?? deck.title ?? "Untitled")
                        .scaledFont(size: 15, weight: .semibold, design: .serif)
                        .foregroundStyle(inkColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if deck.hook != nil, let title = deck.title {
                        Text(title)
                            .scaledFont(size: 11)
                            .foregroundStyle(mutedText)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    if progress > 0.01 {
                        HStack(spacing: 6) {
                            Image(systemName: progress >= 0.98 ? "checkmark.circle.fill" : "book.fill")
                                .scaledFont(size: 10, weight: .semibold)
                                .foregroundStyle(tealAccent)
                            Text(progress >= 0.98 ? "Read" : "\(Int(progress * 100))% read")
                                .scaledFont(size: 10, weight: .bold)
                                .tracking(0.6)
                                .foregroundStyle(tealAccent)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundStyle(mutedText.opacity(0.55))
                    .padding(.top, 4)
            }
            .padding(14)

            if progress > 0.01 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(tealAccent.opacity(0.12))
                        Rectangle()
                            .fill(tealAccent)
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 2)
            }
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var libraryEyebrow: some View {
        let c = deck.topicCluster
        return HStack(spacing: 6) {
            Circle().fill(c.color).frame(width: 5, height: 5)
            Text(libraryEyebrowCaption)
                .scaledFont(size: 9, weight: .bold)
                .tracking(1.4)
                .foregroundStyle(c.color)
        }
    }

    private var libraryEyebrowCaption: String {
        let tag = deck.topicTagUppercased
        if let date = deck.publishedAt {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            return "\(tag) · \(f.string(from: date).uppercased())"
        }
        return tag
    }
}

// Routes decks via `PaperReadingExperience`—curator catalog, blueprint, or legacy concepts.
struct DeckDestination: View {
    let deck: CardDeck
    @Environment(\.dismiss) private var dismiss

    private var resolved: PaperReadingExperience { PaperReadingExperience.resolve(deck) }

    var body: some View {
        Group {
            // Hand-curated free-form lessons take precedence over the generic
            // daily-loop reader for the papers that have one.
            if let lesson = LearningLesson.forPaperId(deck.paperId) {
                LearningFlowView(lesson: lesson, onClose: { dismiss() })
            } else {
                switch resolved {
                case .dailyLoop(let content):
                    DailyLoopView(content: content)
                case .legacy(let legacyDeck):
                    PaperDetailView(deck: legacyDeck)
                }
            }
        }
        .onAppear { RecentlyViewedStore.shared.record(deck.paperId) }
    }
}

// MARK: - HomeGreeting (soft, non-pressurising welcome)

struct HomeGreeting: View {
    var name: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(personalisedGreeting)
                .scaledFont(size: 26, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
            Text("Swipe through new research hits.")
                .scaledFont(size: 14, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
        }
    }

    private var personalisedGreeting: String {
        let base = timeGreeting
        // Late-night fallback ("Still up?") stays anonymous, the question form
        // doesn't take a name graciously and reads better unaltered.
        guard base.hasSuffix(".") else { return base }
        guard let n = name?.trimmingCharacters(in: .whitespaces), !n.isEmpty else {
            return base
        }
        let trimmed = base.trimmingCharacters(in: .punctuationCharacters)
        return "\(trimmed), \(n)."
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<22: return "Good evening."
        default:      return "Still up?"
        }
    }
}

// MARK: - IdentifiedLoop
//
// Wrapper so fullScreenCover(item:) can drive a DailyLoopView from a
// tapped paper. DailyLoopContent itself isn't Identifiable, and its
// paperId is optional (preview fixtures), so we attach a stable id here.

struct IdentifiedLoop: Identifiable, Hashable {
    let id: String
    let content: DailyLoopContent

    static func == (lhs: IdentifiedLoop, rhs: IdentifiedLoop) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Today's Paper Deck (swipeable preview of multiple papers)
//
// Stacked card deck where each card is a different paper's cover. Same
// drag-to-consume mechanic as the full loop, but here each consumed card
// reveals the next paper, not the next page of the same paper. Tap the
// top card to open that paper's full loop. After the last paper, a
// "caught up" terminal card invites a reset.

struct TodaysPaperDeck: View {
    let papers: [DailyLoopContent]
    let onPick: (DailyLoopContent) -> Void
    let onNeedMore: () -> Void

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var crossedThreshold: Bool = false
    @State private var peekHaptic: Int = 0
    @State private var commitHaptic: Int = 0
    @State private var freshPulse: Bool = false
    @State private var ctaGlow: Bool = false
    @State private var savedBurst: Int = 0
    @ObservedObject private var savedStore = SavedPapersStore.shared

    private let cardHeight: CGFloat = 430
    private let swipeThreshold: CGFloat = 90
    private let flyOff: CGFloat = 700

    private var todayLabel: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE · MMM d"
        return df.string(from: Date())
    }

    private var paperCount: Int { papers.count }
    private var logicalIndex: Int {
        guard paperCount > 0 else { return 0 }
        return currentIndex % paperCount
    }

    var body: some View {
        VStack(spacing: 12) {
            actionRail
            ZStack {
                // Top card + up to two behind. zIndex inverted so the front
                // card draws last (on top).
                ForEach(visibleIndices, id: \.self) { idx in
                    let depth = idx - currentIndex
                    cardView(at: idx)
                        // Aged-back-issue feel: rear cards desaturate and
                        // darken slightly, so the stack reads like a run
                        // of older editions sitting under today's front.
                        .saturation(1 - 0.05 * Double(depth))
                        .brightness(-0.008 * Double(depth))
                        .modifier(StackedCardModifier(
                            depth: depth,
                            drag: depth == 0 ? dragOffset : .zero
                        ))
                        .overlay(alignment: .topLeading) {
                            if depth == 0 {
                                SwipeCueOverlay(drag: dragOffset)
                            }
                        }
                        .zIndex(Double(10 - depth))
                        .gesture(depth == 0 ? dragGesture : nil)
                        .onTapGesture { handleTap() }
                        .allowsHitTesting(depth == 0)
                }
            }
            .frame(height: cardHeight)
            .frame(maxWidth: .infinity)
            .padding(.trailing, 14)
            .sensoryFeedback(.selection, trigger: peekHaptic)
            .sensoryFeedback(.impact(weight: .medium), trigger: commitHaptic)
            .sensoryFeedback(.success, trigger: savedBurst)

            HStack(spacing: 10) {
                Text("Swipe left for next")
                Circle().fill(mutedText.opacity(0.4)).frame(width: 3, height: 3)
                Text("Swipe right to save")
            }
            .scaledFont(size: 12, weight: .semibold, design: .serif)
            .italic()
            .foregroundStyle(mutedText)
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .onChange(of: currentIndex) { _, _ in requestMoreIfNeeded() }
    }

    private var visibleIndices: [Int] {
        guard paperCount > 0 else { return [0] }
        let visibleCount = min(4, paperCount)
        return Array(currentIndex..<(currentIndex + visibleCount)).reversed()
    }

    @ViewBuilder
    private func cardView(at idx: Int) -> some View {
        if paperCount > 0 {
            coverCard(for: papers[wrappedIndex(idx)], index: idx)
        } else {
            loadingCard
        }
    }

    // MARK: tap + drag

    private func handleTap() {
        guard paperCount > 0 else { return }
        onPick(papers[logicalIndex])
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { val in
                dragOffset = val.translation
                let crossed = abs(val.translation.width) > swipeThreshold
                if crossed != crossedThreshold {
                    crossedThreshold = crossed
                    if crossed { peekHaptic &+= 1 }
                }
            }
            .onEnded { val in
                let dx = val.translation.width
                if abs(dx) > swipeThreshold {
                    consumeCard(direction: dx < 0 ? .left : .right)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        dragOffset = .zero
                    }
                    crossedThreshold = false
                }
            }
    }

    private enum SwipeDirection { case left, right }

    private func consumeCard(direction: SwipeDirection) {
        guard paperCount > 0 else { return }
        let content = papers[logicalIndex]
        recordSwipe(direction, for: content)

        let signed: CGFloat = direction == .left ? -1 : 1
        withAnimation(.easeOut(duration: 0.22)) {
            dragOffset = CGSize(width: signed * flyOff, height: dragOffset.height)
        }
        commitHaptic &+= 1
        crossedThreshold = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            currentIndex += 1
            dragOffset = .zero
        }
    }

    private func wrappedIndex(_ idx: Int) -> Int {
        guard paperCount > 0 else { return 0 }
        return idx % paperCount
    }

    private func requestMoreIfNeeded() {
        guard paperCount > 0 else { return }
        let remainingBeforeWrap = paperCount - logicalIndex
        if remainingBeforeWrap <= 4 {
            onNeedMore()
        }
    }

    private func recordSwipe(_ direction: SwipeDirection, for content: DailyLoopContent) {
        guard let paperId = content.paperId else { return }
        if direction == .right, !savedStore.isSaved(paperId) {
            savedStore.toggle(paperId)
            savedBurst &+= 1
        }
        Task {
            try? await APIService.shared.markInteraction(
                paperId: paperId,
                action: direction == .right ? .swipedRight : .swipedLeft
            )
        }
    }

    // MARK: card chrome

    private var actionRail: some View {
        HStack(spacing: 10) {
            ActionRailPill(icon: "xmark", title: "NEXT", tint: amberAccent)
                .opacity(dragOffset.width < -12 ? 1 : 0.72)
                .scaleEffect(dragOffset.width < -12 ? 1.04 : 1.0)
            Spacer(minLength: 10)
            Text(paperCount > 0 ? "Card \(currentIndex + 1)" : "Loading")
                .scaledFont(size: 11, weight: .heavy, design: .serif)
                .tracking(1.8)
                .foregroundStyle(mutedText)
            Spacer(minLength: 10)
            ActionRailPill(icon: "bookmark.fill", title: "SAVE", tint: tealAccent)
                .opacity(dragOffset.width > 12 ? 1 : 0.72)
                .scaleEffect(dragOffset.width > 12 ? 1.04 : 1.0)
        }
        .motionAware(.snappy(duration: 0.18, extraBounce: 0.16), value: dragOffset.width)
    }

    // Shared shell. Paper-feel comes from a soft top-down lightness
    // gradient (top brighter, bottom warmed by amber) plus a thin inner
    // highlight at the top edge. The big italic "a" watermark was
    // removed: it read as a placeholder rather than a brand mark.
    private func cardShell<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(EdgeInsets(top: 22, leading: 22, bottom: 20, trailing: 22))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: cardHeight, alignment: .top)
            .background(
                ZStack {
                    cardBg
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear, amberAccent.opacity(0.07)],
                        startPoint: .top, endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [amberAccent.opacity(0.06), .clear],
                        startPoint: .topTrailing, endPoint: .bottomLeading
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.8)
            )
            .overlay(
                // Faint highlight along the top edge: makes the card
                // read as a sheet of paper rather than a flat slab.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), .clear],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 0.6
                    )
                    .allowsHitTesting(false)
            )
            .shadow(color: tealAccent.opacity(0.10), radius: 26, x: 0, y: 16)
            .shadow(color: inkColor.opacity(0.08), radius: 14, x: 0, y: 6)
            .shadow(color: inkColor.opacity(0.04), radius: 3, x: 0, y: 1)
            .contentShape(Rectangle())
    }

    // Per-paper cover preview, editorial-journal styling.
    // Layout (top→bottom): masthead with edition № + read time, hairline
    // rule, headline with oversized initial letter (raised-cap effect),
    // paper title in italic serif, provenance line (authors · year),
    // "In this issue" italic label + hairline, three-idea TOC, fleuron
    // divider, tight "Begin reading →" CTA.
    private func coverCard(for content: DailyLoopContent, index: Int) -> some View {
        let title = plainTitle(for: content)
        let head = String(title.prefix(1))
        let tail = String(title.dropFirst())
        let prov = provenance(for: content)
        let isFresh = index == currentIndex
        return cardShell {
            VStack(alignment: .leading, spacing: 0) {
                // Date eyebrow with "fresh today" pulse on the first
                // card. Gives the user an immediate "this is new for
                // you, right now" signal every time they open the app.
                HStack(spacing: 8) {
                    Text(todayLabel.uppercased())
                        .scaledFont(size: 9, weight: .heavy, design: .serif)
                        .tracking(2.0)
                        .foregroundStyle(mutedText)
                    if isFresh {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(amberAccent)
                                .frame(width: 5, height: 5)
                                .shadow(color: amberAccent.opacity(0.65), radius: freshPulse ? 4 : 1)
                                .scaleEffect(freshPulse ? 1.25 : 1.0)
                                .motionAware(.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                                           value: freshPulse)
                            Text("NEW")
                                .scaledFont(size: 9, weight: .heavy, design: .serif)
                                .tracking(1.6)
                                .foregroundStyle(amberAccent)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 10)

                // Masthead.
                HStack(alignment: .firstTextBaseline) {
                    Text(editionLabel(for: index))
                        .scaledFont(size: 10, weight: .semibold, design: .serif)
                        .italic()
                        .tracking(1.2)
                        .foregroundStyle(tealAccent)
                    Spacer()
                    Text("\(content.estimatedMinutes) min read")
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                }
                .padding(.bottom, 6)
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 0.5)
                    .padding(.bottom, 14)

                // Headline with raised initial cap.
                (
                    Text(head)
                        .font(scaledSystemFont(42, weight: .regular, design: .serif))
                        .foregroundStyle(inkColor)
                  + Text(tail)
                        .font(scaledSystemFont(24, weight: .regular, design: .serif))
                        .foregroundStyle(inkColor)
                )
                .lineLimit(3)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

                // Paper title in italic serif.
                if let sub = content.paperTitle, !sub.isEmpty, sub != title {
                    Text(sub)
                        .scaledFont(size: 12, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                        .lineLimit(2)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 6)
                }

                // Provenance: authors + year, journal-citation style.
                if !prov.isEmpty {
                    Text(prov)
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText.opacity(0.7))
                        .lineLimit(1)
                        .padding(.bottom, 14)
                }

                // Soft "In this issue" label + trailing hairline.
                HStack(spacing: 8) {
                    Text("In this issue")
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 0.4)
                }
                .padding(.bottom, 8)

                // TOC.
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(content.coreIdeaItems.prefix(3).enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(item.roman)
                                .scaledFont(size: 11, design: .serif)
                                .italic()
                                .foregroundStyle(tealAccent)
                                .frame(width: 16, alignment: .trailing)
                            Text(item.title)
                                .scaledFont(size: 13, design: .serif)
                                .foregroundStyle(inkColor.opacity(0.82))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Primary CTA: filled teal pill, full-width, with a soft
                // breathing glow on the first card so the user knows
                // exactly where to tap.
                HStack(spacing: 8) {
                    Text("Begin reading")
                        .scaledFont(size: 15, weight: .semibold, design: .serif)
                    Image(systemName: "arrow.right")
                        .scaledFont(size: 13, weight: .bold)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tealAccent)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
                        .blendMode(.overlay)
                )
                .shadow(color: tealAccent.opacity(isFresh && ctaGlow ? 0.45 : 0.22),
                        radius: isFresh && ctaGlow ? 12 : 6, x: 0, y: 3)
                .motionAware(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                           value: ctaGlow)

                // Footer hint: position in today's edition + swipe nudge.
                HStack {
                    Text("drop \(index + 1)")
                        .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                        .foregroundStyle(mutedText)
                    Spacer()
                    if paperCount > 1 {
                        Text(savedStore.isSaved(content.paperId ?? "") ? "saved" : "more waiting")
                            .scaledFont(size: 10, design: .serif)
                            .italic()
                            .foregroundStyle(savedStore.isSaved(content.paperId ?? "") ? tealAccent : mutedText.opacity(0.75))
                    }
                }
                .padding(.top, 10)
            }
            .onAppear {
                freshPulse = true
                ctaGlow = true
            }
        }
    }

    private var loadingCard: some View {
        cardShell {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tealAccent)
                        .frame(width: 5, height: 5)
                        .opacity(freshPulse ? 1 : 0.35)
                    Text("BUILDING YOUR STACK")
                        .scaledFont(size: 10, weight: .heavy, design: .serif)
                        .tracking(1.8)
                        .foregroundStyle(tealAccent)
                }
                .padding(.bottom, 16)

                Text("Fresh papers are coming in.")
                    .scaledFont(size: 30, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
                    .padding(.bottom, 10)

                Text("Hold tight. The next research hit should appear in a moment.")
                    .scaledFont(size: 14, design: .serif)
                    .italic()
                    .lineSpacing(4)
                    .foregroundStyle(mutedText)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(tealAccent.opacity(0.25 + Double(i) * 0.18))
                            .frame(width: 44, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .onAppear { freshPulse = true }
        }
    }

    // Terminal card after all papers consumed. Editorial parity with
    // coverCard: same masthead width, hairline, fleuron, italic CTA.
    private var caughtUpCard: some View {
        cardShell {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("END OF EDITION")
                        .scaledFont(size: 10, weight: .semibold, design: .serif)
                        .italic()
                        .tracking(1.2)
                        .foregroundStyle(amberAccent)
                    Spacer()
                    Text("caught up")
                        .scaledFont(size: 10, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                }
                .padding(.bottom, 6)
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 0.5)
                    .padding(.bottom, 18)

                Text("You're all caught up.")
                    .scaledFont(size: 26, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)

                Text("Fresh papers land every morning. Until then, take a breath, or revisit one from your shelf.")
                    .scaledFont(size: 13, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Text("· · ·")
                        .scaledFont(size: 14, design: .serif)
                        .tracking(6)
                        .foregroundStyle(amberAccent.opacity(0.5))
                    Spacer()
                }
                .padding(.bottom, 8)

                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .scaledFont(size: 13, weight: .bold)
                    Text("Restart the deck")
                        .scaledFont(size: 15, weight: .semibold, design: .serif)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(amberAccent)
                )
                .shadow(color: amberAccent.opacity(0.25), radius: 6, x: 0, y: 3)
            }
        }
    }

    // "№ 003" style edition stamp. Three-digit zero-pad gives every paper
    // the same weight in the masthead column.
    private func editionLabel(for index: Int) -> String {
        "№ \(String(format: "%03d", index + 1))"
    }

    // Strip an "arXiv:..." prefix off the source line so the visible
    // provenance reads like a clean citation ("Wei et al., 2022") rather
    // than a tracking id ("arXiv:2201.11903 · Wei et al., 2022").
    private func provenance(for content: DailyLoopContent) -> String {
        let s = content.sourceLine.trimmingCharacters(in: .whitespaces)
        if s.lowercased().hasPrefix("arxiv:"),
           let r = s.range(of: " · ") {
            return String(s[r.upperBound...])
        }
        return s
    }

    private func plainTitle(for content: DailyLoopContent) -> String {
        content.heroTitleSegments.map { seg in
            switch seg {
            case .plain(let s), .highlight(let s): return s
            }
        }.joined()
    }

    private var accessibilityLabel: String {
        guard paperCount > 0 else { return "Home feed is loading papers." }
        let title = plainTitle(for: papers[logicalIndex])
        return "Home feed. Card \(currentIndex + 1). Swipe left for next, swipe right to save. \(title)."
    }
}

// MARK: - StackedCardModifier
//
// Places a card in the stack at `depth` (0 = top, 1 = back, 2 = deepest).
// While the top card is being dragged, the cards behind anticipate the
// promotion by easing one rung forward proportional to drag distance —
// so the deck visibly "consumes" the top card instead of just sliding
// it past. Tilt + offset on the top card follows the drag like the real
// deck swipe inside the loop, so the gesture maps to a single learned
// motion across surfaces.

private struct StackedCardModifier: ViewModifier {
    let depth: Int
    let drag: CGSize

    func body(content: Content) -> some View {
        let dragMag = sqrt(drag.width * drag.width + drag.height * drag.height)
        let dragProgress = min(dragMag / 200, 1)        // 0 ... 1
        let signedTilt = Double(drag.width / 18)          // rotation while top card flies

        // Effective depth eases up by drag progress for behind-cards, so
        // they climb toward the top slot as the front card leaves.
        let d = max(CGFloat(depth) - (depth > 0 ? dragProgress : 0), 0)

        let scale = 1 - 0.04 * d
        // Back cards stay flush with the top edge of the front card and
        // only peek to the right + slightly down. Previous negative
        // yOff pushed them above the hero, overlapping the section
        // label above ("TODAY'S LESSON").
        let yOff: CGFloat = 4 * d
        let xOff: CGFloat = depth == 0 ? drag.width : 6 * d
        let yShift: CGFloat = depth == 0 ? drag.height : yOff
        let rotation: Double = depth == 0 ? signedTilt : 1.5 * Double(d)
        // Fade behind-cards in slightly as they promote forward.
        let opacity: Double = depth == 0 ? 1.0 : 1.0 - 0.10 * Double(d)

        return content
            .scaleEffect(scale, anchor: .top)
            .rotationEffect(.degrees(rotation), anchor: .bottom)
            .offset(x: xOff, y: yShift)
            .opacity(opacity)
            .motionAware(.interactiveSpring(response: 0.28, dampingFraction: 0.85, blendDuration: 0.1), value: drag)
    }
}

private struct ActionRailPill: View {
    let icon: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .scaledFont(size: 10, weight: .heavy)
            Text(title)
                .scaledFont(size: 10, weight: .heavy, design: .serif)
                .tracking(1.5)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 0.8)
        )
    }
}

private struct SwipeCueOverlay: View {
    let drag: CGSize

    private var progress: Double {
        min(Double(abs(drag.width) / 110), 1)
    }

    private var isSave: Bool { drag.width > 0 }

    var body: some View {
        if progress > 0.08 {
            HStack(spacing: 7) {
                Image(systemName: isSave ? "bookmark.fill" : "arrow.forward")
                    .scaledFont(size: 13, weight: .heavy)
                Text(isSave ? "SAVE" : "NEXT")
                    .scaledFont(size: 13, weight: .heavy, design: .serif)
                    .tracking(2)
            }
            .foregroundStyle(isSave ? tealAccent : amberAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(cardBg.opacity(0.92))
                    .shadow(color: (isSave ? tealAccent : amberAccent).opacity(0.20),
                            radius: 10, x: 0, y: 4)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke((isSave ? tealAccent : amberAccent).opacity(0.45), lineWidth: 1)
            )
            .opacity(progress)
            .rotationEffect(.degrees(isSave ? -8 : 8))
            .padding(18)
            .transition(.scale(scale: 0.82).combined(with: .opacity))
        }
    }
}

// MARK: - HeroPressStyle
//
// Subtle scale + softening on press. Whole hero card behaves like a slab
// you actually pushed, instead of an opaque button that just dims.
private struct HeroPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .motionAware(.spring(response: 0.32, dampingFraction: 0.82),
                       value: configuration.isPressed)
    }
}

// MARK: - AprecisMark
//
// Native SwiftUI rendering of the brand glyph: dark teal rounded square with
// an italic serif 'a' centered. Drawn in code rather than imported as an
// image so it scales perfectly at any size and never picks up JPEG fringing.
// Used in `AprecisLogo` and as a subtle watermark in the hero cover.

struct AprecisMark: View {
    let size: CGFloat

    init(_ size: CGFloat = 22) { self.size = size }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color(hex: "0e3434"))
            Text("a")
                .scaledFont(size: size * 0.62, weight: .semibold, design: .serif)
                .italic()
                .foregroundStyle(Color(hex: "6fb3a8"))
                .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - AprecisLogo

struct AprecisLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            AprecisMark(22)
            HStack(spacing: 0) {
                Text("aprecis")
                    .scaledFont(size: 18, weight: .semibold, design: .serif)
                    .foregroundStyle(tealAccent)
                Text(".")
                    .scaledFont(size: 18, weight: .semibold, design: .serif)
                    .italic()
                    .foregroundStyle(inkColor)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - SectionLabel

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .scaledFont(size: 11, weight: .semibold)
            .tracking(1.2)
            .foregroundStyle(mutedText)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
    }
}

// MARK: - FeaturedPaperCard

struct FeaturedPaperCard: View {
    let deck: CardDeck
    let colorIndex: Int
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var progress: Double { progressStore.progress(for: deck.paperId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tag + progress ring
            HStack(spacing: 5) {
                Circle().fill(tealAccent).frame(width: 5, height: 5)
                Text(categoryLabel)
                    .scaledFont(size: 10, weight: .semibold)
                    .tracking(0.8)
                    .foregroundStyle(tealAccent)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(tealLight)
            .clipShape(Capsule())
            .padding(.bottom, 10)

            // Hook (catchy headline)
            Text(deck.hook ?? deck.title ?? "Untitled")
                .scaledFont(size: 16, weight: .bold, design: .serif)
                .foregroundStyle(inkColor)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            // Paper title (if hook exists, show actual title underneath)
            if deck.hook != nil, let paperTitle = deck.title {
                Text(paperTitle)
                    .scaledFont(size: 11)
                    .foregroundStyle(mutedText)
                    .lineLimit(2)
                    .padding(.bottom, 4)
            }

            // Source / date
            Text(metaLine)
                .font(.system(size: 11).monospaced())
                .foregroundStyle(mutedText)
                .lineLimit(1)
                .padding(.bottom, 12)

            Spacer(minLength: 0)

            // Concept cover image (DALL-E or fallback gradient)
            ConceptCoverImage(
                imageUrl: deck.concepts.first?.conceptImageUrl,
                colorIndex: colorIndex
            )
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.bottom, 12)

            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .scaledFont(size: 10, weight: .semibold)
                    .foregroundStyle(tealAccent)
                Text("\(max(1, deck.concepts.count * 2)) min read")
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundStyle(tealAccent)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(tealLight))
        }
        .padding(18)
        .frame(width: 270, height: 270)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: inkColor.opacity(0.07), radius: 12, x: 0, y: 2)
        .shadow(color: inkColor.opacity(0.04), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if progress > 0.01 {
                ProgressRing(progress: progress)
                    .frame(width: 26, height: 26)
                    .padding(14)
            }
        }
    }

    private var categoryLabel: String {
        deck.topicCluster.label
    }

    private var metaLine: String {
        let tag = deck.topicTagUppercased
        if let date = deck.publishedAt {
            let f = DateFormatter()
            f.dateStyle = .medium
            return "\(tag) · \(f.string(from: date))"
        }
        return tag
    }
}

// MARK: - FeaturedLoopCard
//
// Pinned left-most card in the Featured Papers carousel. Mirrors the
// `TodaysPaperDeck` editorial cream cover at carousel scale with the same
// brand watermark in the corner, keeps the page aesthetically cohesive
// instead of dropping back to a dark surface in the middle of the scroll.

struct FeaturedLoopCard: View {
    let content: DailyLoopContent

    private let cream     = Color(hex: "fbf6ed")
    private let cream_2   = Color(hex: "ede2cd")
    private let warm_dim  = Color(hex: "7a6f5e")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Faint italic 'a' watermark, same brand cue as the main hero,
            // smaller offset since this card is itself smaller.
            Text("a")
                .scaledFont(size: 180, weight: .regular, design: .serif)
                .italic()
                .foregroundStyle(tealAccent.opacity(0.06))
                .offset(x: 28, y: -42)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tealAccent)
                        .frame(width: 5, height: 5)
                    Text(content.heroEyebrow)
                        .scaledFont(size: 9, weight: .semibold)
                        .tracking(1.4)
                        .foregroundStyle(tealAccent)
                }
                .padding(.bottom, 12)

                loopTitle
                    .scaledFont(size: 17, weight: .regular, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineSpacing(2)
                    .padding(.bottom, 8)
                    .fixedSize(horizontal: false, vertical: true)

                Text(content.heroBody)
                    .scaledFont(size: 11, design: .serif)
                    .foregroundStyle(warm_dim)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text(content.sourceLine)
                    .font(.system(size: 10).monospaced())
                    .foregroundStyle(warm_dim)
                    .lineLimit(1)
                    .padding(.bottom, 10)

                HStack(spacing: 6) {
                    Text("Start learning")
                        .tracking(1.2)
                    Image(systemName: "arrow.right")
                        .scaledFont(size: 10, weight: .bold)
                }
                .scaledFont(size: 11, weight: .bold)
                .foregroundStyle(paperBg)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous).fill(inkColor)
                )
            }
            .padding(16)
        }
        .frame(width: 270, height: 270)
        .background(
            LinearGradient(
                colors: [cream, cream_2],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(inkColor.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.06), radius: 14, x: 0, y: 4)
        .shadow(color: inkColor.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    // Hero title: builds from the content's heroTitleSegments so the highlight
    // piece renders italic + teal, matching the Today's Paper hero style.
    private var loopTitle: Text {
        content.heroTitleSegments.reduce(Text("")) { acc, seg in
            switch seg {
            case .plain(let s):
                return acc + Text(s)
            case .highlight(let s):
                return acc + Text(s).italic().foregroundColor(tealAccent)
            }
        }
    }
}

// MARK: - ProgressRing

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(tealAccent.opacity(0.18), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(tealAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 0.98 {
                Image(systemName: "checkmark")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundStyle(tealAccent)
            } else {
                Text("\(Int(progress * 100))")
                    .scaledFont(size: 9, weight: .bold)
                    .foregroundStyle(tealAccent)
            }
        }
        .background(
            Circle().fill(cardBg.opacity(0.95))
        )
    }
}

// MARK: - ConceptPreviewCanvas

struct ConceptPreviewCanvas: View {
    let colorIndex: Int

    private var gradient: LinearGradient {
        switch colorIndex % 3 {
        case 0:
            return LinearGradient(
                colors: [Color(hex: "e8f5f5"), Color(hex: "d0eeee")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1:
            return LinearGradient(
                colors: [Color(hex: "fef3e2"), Color(hex: "fde8c0")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(
                colors: [Color(hex: "f0e8f5"), Color(hex: "e4d4f0")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack {
            gradient
            Canvas { ctx, size in
                drawDiagram(ctx: &ctx, size: size)
            }
        }
    }

    private func drawDiagram(ctx: inout GraphicsContext, size: CGSize) {
        let primary: Color
        switch colorIndex % 3 {
        case 0: primary = Color(hex: "1a8a8a")
        case 1: primary = Color(hex: "c07014")
        default: primary = Color(hex: "7b4ba4")
        }
        let shading = GraphicsContext.Shading.color(primary)
        let faded = GraphicsContext.Shading.color(primary.opacity(0.4))
        let stroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

        if colorIndex % 2 == 0 {
            // Flow: three boxes connected by arrows
            let bw: CGFloat = 54, bh: CGFloat = 28
            let y = size.height / 2 - bh / 2
            let xs: [CGFloat] = [16, (size.width - bw) / 2, size.width - 16 - bw]
            let labels = ["Input", "Attn", "Output"]

            for (i, x) in xs.enumerated() {
                ctx.stroke(Path(roundedRect: CGRect(x: x, y: y, width: bw, height: bh), cornerRadius: 6),
                           with: i == 1 ? GraphicsContext.Shading.color(Color(hex: "2db8b8")) : shading,
                           style: stroke)
                ctx.draw(
                    Text(labels[i]).font(scaledSystemFont(7, weight: .medium)).foregroundStyle(primary),
                    at: CGPoint(x: x + bw / 2, y: size.height / 2)
                )
                if i < xs.count - 1 {
                    let nx = xs[i + 1]
                    var line = Path()
                    line.move(to: CGPoint(x: x + bw + 2, y: size.height / 2))
                    line.addLine(to: CGPoint(x: nx - 6, y: size.height / 2))
                    ctx.stroke(line, with: shading, style: stroke)
                    // Arrowhead
                    var arrow = Path()
                    let ax = nx - 3
                    let ay = size.height / 2
                    arrow.move(to: CGPoint(x: ax, y: ay))
                    arrow.addLine(to: CGPoint(x: ax - 7, y: ay - 4))
                    arrow.addLine(to: CGPoint(x: ax - 7, y: ay + 4))
                    arrow.closeSubpath()
                    ctx.fill(arrow, with: shading)
                }
            }
        } else {
            // Hub-spoke network
            let cx = size.width / 2, cy = size.height / 2
            let r: CGFloat = min(size.width, size.height) * 0.3
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 12, y: cy - 12, width: 24, height: 24)), with: shading)
            for i in 0..<5 {
                let angle = Double(i) * 2 * .pi / 5 - .pi / 2
                let px = cx + r * CGFloat(cos(angle))
                let py = cy + r * CGFloat(sin(angle))
                var line = Path()
                line.move(to: CGPoint(x: cx, y: cy))
                line.addLine(to: CGPoint(x: px, y: py))
                ctx.stroke(line, with: faded, style: StrokeStyle(lineWidth: 1))
                ctx.stroke(Path(ellipseIn: CGRect(x: px - 6, y: py - 6, width: 12, height: 12)),
                           with: shading, style: StrokeStyle(lineWidth: 1.5))
            }
        }
        // Amber accent dot
        ctx.fill(Path(ellipseIn: CGRect(x: 8, y: 8, width: 6, height: 6)),
                 with: GraphicsContext.Shading.color(Color(hex: "e8a020")))
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - PaperRowView

struct PaperRowView: View {
    let deck: CardDeck
    var colorIndex: Int = 0
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var progress: Double { progressStore.progress(for: deck.paperId) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ConceptCoverImage(
                    imageUrl: deck.concepts.first?.conceptImageUrl,
                    colorIndex: colorIndex
                )
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.hook ?? deck.title ?? "Untitled")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundStyle(inkColor)
                        .lineLimit(2)
                    if deck.hook != nil, let paperTitle = deck.title {
                        Text(paperTitle)
                            .scaledFont(size: 10)
                            .foregroundStyle(mutedText)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Text(subtitle)
                            .scaledFont(size: 11)
                            .foregroundStyle(mutedText)
                        if progress > 0.01 {
                            Text("·")
                                .scaledFont(size: 11)
                                .foregroundStyle(mutedText)
                            Text(progress >= 0.98 ? "Read" : "\(Int(progress * 100))%")
                                .scaledFont(size: 11, weight: .semibold)
                                .foregroundStyle(tealAccent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            if progress > 0.01 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(tealAccent)
                        .frame(width: geo.size.width * CGFloat(progress), height: 2)
                }
                .frame(height: 2)
            }
        }
        .background(cardBg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(borderColor).frame(height: 1)
        }
    }

    private var subtitle: String {
        let tag = deck.topicCluster.label
        if let date = deck.publishedAt {
            let f = DateFormatter()
            f.dateStyle = .medium
            return "\(tag) · \(f.string(from: date))"
        }
        return tag
    }
}

// MARK: - ContinueCard
//
// Compact horizontal card for the "Continue Reading" row. Shows the
// concept cover, a short title, and the progress ring, small footprint,
// just enough to invite a return tap. Only ever rendered when there's
// non-zero progress on the deck.

struct ContinueCard: View {
    let deck: CardDeck
    let colorIndex: Int
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var progress: Double { progressStore.progress(for: deck.paperId) }

    var body: some View {
        HStack(spacing: 12) {
            ConceptCoverImage(
                imageUrl: deck.concepts.first?.conceptImageUrl,
                colorIndex: colorIndex
            )
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.hook ?? deck.title ?? "Untitled")
                    .scaledFont(size: 13, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(Int(progress * 100))% read")
                    .scaledFont(size: 10, weight: .semibold)
                    .tracking(0.4)
                    .foregroundStyle(tealAccent)
            }
            .frame(width: 130, alignment: .leading)

            ProgressRing(progress: progress)
                .frame(width: 26, height: 26)
        }
        .padding(12)
        .frame(width: 260, height: 76)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Skeletons

private struct FeaturedCardSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.1)).frame(width: 100, height: 22)
            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.08)).frame(height: 52)
            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.06)).frame(height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.08)).frame(height: 90)
        }
        .padding(18)
        .frame(width: 270, height: 270)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: inkColor.opacity(0.05), radius: 8)
        .opacity(pulse ? 0.55 : 1.0)
        .motionAware(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

private struct PaperRowSkeleton: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.09)).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.09)).frame(height: 13)
                RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.06)).frame(width: 120, height: 11)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .opacity(pulse ? 0.55 : 1.0)
        .motionAware(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}


