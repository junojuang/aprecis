import SwiftUI

// MARK: - ExploreFocusView
//
// The Explore experience as a single paper hub. One paper is in focus
// at any time; the screen shows its hero (title, hook, field), then
// three relationship rails (Builds on, Led to, Adjacent ideas) and a
// single Surprise pick. Tapping any rail card swaps the focus to that
// paper with a smooth transition and pushes a breadcrumb.
//
// Scales because only the focused paper + its ~10 neighbors render at
// once. No global graph layout, no force sim, no overlapping nodes.

struct ExploreFocusView: View {
    let decks: [CardDeck]
    @Binding var focusedId: String
    var query: String = ""
    var onDismiss: (() -> Void)? = nil
    /// When false, tapping a rail card opens that paper in an **Explore** sheet (hub + rails).
    /// When true (e.g. sheet already showing a hub), rail taps advance focus in-place with trail.
    var drillDownRelatedInPlace: Bool = false

    @State private var trail: [String] = []
    @State private var presentedPaper: PresentedPaper? = nil
    @State private var savedFlash: Bool = false
    @State private var previewId: String? = nil
    @State private var infoRailLabel: String? = nil
    @State private var pageDragX: CGFloat = 0
    @State private var pageDragActive: Bool = false
    @State private var activeRail: RailKind = .buildsOn
    @Namespace private var railTabNS

    /// Relationship rails for the focused paper. Loaded async from the backend
    /// graph (with the curated canon merged on top); starts empty and is
    /// populated by `loadBundle()` whenever the focus changes.
    @State private var bundle: RelatedPapers.Bundle = .empty
    @State private var bundleLoading = false

    private enum PresentedPaper: Identifiable, Hashable {
        case exploreHub(paperId: String)
        case readDeck(paperId: String)

        var id: String {
            switch self {
            case .exploreHub(let paperId): return "explore-hub:\(paperId)"
            case .readDeck(let paperId):  return "read-deck:\(paperId)"
            }
        }
    }

    /// One of the three relationship rails the user can switch between
    /// via the segmented control. Keeping label/caption/info/accent on
    /// the enum lets the tab bar and the rail body share one source of
    /// truth and avoids three near-identical rail() call sites.
    private enum RailKind: CaseIterable {
        case buildsOn, ledTo, adjacent
        var label: String {
            switch self {
            case .buildsOn: return "Builds on"
            case .ledTo:    return "Led to"
            case .adjacent: return "Adjacent"
            }
        }
        var info: String {
            switch self {
            case .buildsOn: return "Earlier work that this paper directly extends or relies on. Read these first if a concept here feels unfamiliar."
            case .ledTo:    return "Later papers that build directly on this one's ideas, methods, or results."
            case .adjacent: return "Papers from the same era and field that share concepts, even if neither cites the other."
            }
        }
    }

    private func ids(for kind: RailKind) -> [String] {
        switch kind {
        case .buildsOn: return bundle.buildsOn
        case .ledTo:    return bundle.ledTo
        case .adjacent: return bundle.adjacent
        }
    }

    private func accent(for kind: RailKind) -> Color {
        switch kind {
        case .buildsOn: return amberAccent
        case .ledTo:    return tealAccent
        case .adjacent: return tealMid
        }
    }

    @ObservedObject private var savedStore = SavedPapersStore.shared
    @ObservedObject private var progressStore = ReadingProgressStore.shared

    private var deckById: [String: CardDeck] { Dictionary(uniqueKeysWithValues: decks.map { ($0.paperId, $0) }) }

    /// Deck for the brace in focus — API row, bundled preview, or synthetic loop.
    private var focusedDeck: CardDeck? {
        deckById[focusedId] ?? DailyLoopContent.byPaperId(focusedId).map {
            CardDeck.fromLoop(paperId: focusedId, content: $0)
        }
    }

    private var topicCluster: SimilarityGraph.Cluster {
        if let d = focusedDeck { return SimilarityGraph.cluster(for: d) }
        return SimilarityGraph.displayCluster(forPaperId: focusedId, deckHint: nil)
    }

    /// Load the rails for the current focus from the backend paper graph.
    /// `railsLoadingState` covers the brief empty window while it lands.
    private func loadBundle() async {
        bundle = .empty
        bundleLoading = true
        let loaded = await RelatedPapers.bundle(for: focusedId, focusedDeck: focusedDeck)
        // Guard against a stale result if focus changed mid-flight.
        guard !Task.isCancelled else { return }
        bundle = loaded
        bundleLoading = false
        syncActiveRail()
    }

    var body: some View {
        ZStack(alignment: .top) {
            paperBg.ignoresSafeArea()
            clusterTint.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 56)
                    // Page back-swipe is scoped to hero + breadcrumbs only — not the rail strip,
                    // so horizontal swipes on Builds on / Led to / Adjacent change tabs instead of dismissing.
                    VStack(alignment: .leading, spacing: 0) {
                        if !trail.isEmpty { trailStrip.padding(.bottom, 8) }
                        hero
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                    .simultaneousGesture(pageSwipeGesture)

                    if availableRails.count > 0 {
                        VStack(alignment: .leading, spacing: 0) {
                            railTabBar
                                .padding(.horizontal, 22)
                                .padding(.bottom, 12)
                                .simultaneousGesture(railSectionSwipeGesture)
                            railBody
                                .padding(.bottom, 22)
                        }
                    } else if bundleLoading {
                        railsLoadingState
                            .padding(.horizontal, 22)
                            .padding(.bottom, 22)
                    }

                    bottomActions.padding(.horizontal, 22).padding(.bottom, 32)
                }
            }
            .id(focusedId) // reset scroll when focus changes
            .motionAware(.snappy(duration: 0.26), value: focusedId)
            .offset(x: pageDragX)

            topChrome
                .padding(.horizontal, 14)
                .padding(.top, 10)

            if let pid = previewId {
                previewOverlay(id: pid)
                    .transition(.opacity)
            }
        }
        .sheet(item: $presentedPaper) { item in
            switch item {
            case .exploreHub(let paperId):
                ExplorePaperHubSheet(
                    decks: decks,
                    entryPaperId: paperId,
                    onDismiss: { presentedPaper = nil }
                )
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])

            case .readDeck(let paperId):
                Group {
                    readDeckDestination(paperId: paperId)
                }
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: query) { _, new in
            applySearch(new)
        }
        // Reloads (and cancels any in-flight load) whenever the focus changes.
        .task(id: focusedId) { await loadBundle() }
    }

    /// Reset the active tab to the first non-empty rail whenever the
    /// focused paper changes, so we never show an empty body.
    private func syncActiveRail() {
        let avail = availableRails
        guard !avail.isEmpty else { return }
        if !avail.contains(activeRail), let first = avail.first {
            activeRail = first
        }
    }

    // MARK: top chrome

    private var topChrome: some View {
        HStack(spacing: 8) {
            if onDismiss != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onDismiss?()
                } label: {
                    Image(systemName: "chevron.left")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundStyle(inkColor)
                        .frame(width: 30, height: 30)
                        .background(chromeBackground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                let pick = SimilarityGraph.papers.randomElement()?.id ?? RelatedPapers.starter
                focus(on: pick, addToTrail: false)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "die.face.5")
                        .scaledFont(size: 11, weight: .semibold)
                    Text("Random")
                        .scaledFont(size: 11, weight: .semibold)
                }
                .foregroundStyle(inkColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(chromeBackground)
            }
            .buttonStyle(.plain)
        }
    }

    private var chromeBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.95))
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            .shadow(color: inkColor.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: trail breadcrumbs

    private var trailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(trail.enumerated()), id: \.offset) { idx, id in
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        // Pop trail back to this entry; tail becomes new focus.
                        trail = Array(trail.prefix(idx))
                        withAnimation(.snappy(duration: 0.22)) {
                            focusedId = id
                        }
                    } label: {
                        Text(shortTitle(for: id))
                            .scaledFont(size: 10, weight: .semibold, design: .serif)
                            .foregroundStyle(mutedText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white)
                                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                    Image(systemName: "chevron.right")
                        .scaledFont(size: 8, weight: .bold)
                        .foregroundStyle(mutedText.opacity(0.6))
                        .accessibilityHidden(true)
                }
                Text(shortTitle(for: focusedId))
                    .scaledFont(size: 10, weight: .bold, design: .serif)
                    .foregroundStyle(inkColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: hero

    private var hero: some View {
        let meta = SimilarityGraph.metaById[focusedId]
        let cluster = topicCluster
        let title = title(for: focusedId)
        let hook = hook(for: focusedId)
        let progress = progressStore.progress(for: focusedId)
        let trending = meta?.trending ?? 0
        let minutes = estReadMin(for: focusedId)

        return VStack(alignment: .leading, spacing: 10) {
            // Meta strip: cluster, HOT, READ, and read duration share
            // one editorial row — duration stays italic/grays so it
            // reads as footnote typography, not a third chrome chip.
            HStack(spacing: 6) {
                Circle().fill(cluster.color).frame(width: 6, height: 6)
                Text(cluster.label.uppercased())
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(1.6)
                    .foregroundStyle(cluster.color)
                if trending > 0.5 {
                    Text("· HOT")
                        .scaledFont(size: 10, weight: .bold)
                        .tracking(1.6)
                        .foregroundStyle(amberAccent)
                }
                if progress >= 0.98 {
                    HStack(spacing: 3) {
                        Text("· READ")
                            .scaledFont(size: 10, weight: .bold)
                            .tracking(1.6)
                            .foregroundStyle(progressGreen)
                        Image(systemName: "checkmark")
                            .scaledFont(size: 9, weight: .bold)
                            .foregroundStyle(progressGreen)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Read")
                }
                Text("· \(minutes) min read")
                    .scaledFont(size: 10, design: .serif)
                    .italic()
                    .tracking(0.3)
                    .foregroundStyle(mutedText.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityLabel("\(minutes) minute read")
            }
            Text(title)
                .scaledFont(size: 28, weight: .regular, design: .serif)
                .foregroundStyle(inkColor)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
            if let hook, !hook.isEmpty {
                Text(hook)
                    .scaledFont(size: 14, design: .serif)
                    .italic()
                    .foregroundStyle(mutedText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: rails (segmented)

    /// Non-empty rails for the current focus, in canonical order.
    /// Drives both the tab bar and the fallback behavior when the
    /// active rail becomes empty after a focus change.
    private var availableRails: [RailKind] {
        RailKind.allCases.filter { !ids(for: $0).isEmpty }
    }

    /// Editorial tab bar. No filled capsules — labels sit in a row
    /// like a magazine section index, with a hairline rule beneath
    /// the whole strip and a thicker accent-colored bar gliding
    /// underneath the active tab via matchedGeometryEffect. Count
    /// is rendered as a small superscript figure next to the label
    /// rather than a badge, so the whole thing reads as type, not
    /// as UI chrome.
    private var railTabBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(availableRails.enumerated()), id: \.offset) { idx, kind in
                    if idx > 0 { railTabDivider }
                    railTab(for: kind)
                }
            }
            // Hairline base rule under every label so the underline
            // indicator reads against a quiet ground, not naked paper.
            Rectangle()
                .fill(inkColor.opacity(0.08))
                .frame(height: 0.5)
                .padding(.top, 4)
        }
    }

    /// Swipe on the Builds on / Led to / Adjacent **tab strip**: swipe **left** → next rail,
    /// **right** → previous (only among rails that currently have rows). Attached here — not on
    /// the card carousels — so horizontal scrolling of papers stays unaffected.
    private var railSectionSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { v in
                let rails = availableRails
                guard rails.count >= 2 else { return }
                let dx = v.translation.width
                let dy = v.translation.height
                guard abs(dx) > max(64, abs(dy) * 1.95) else { return }
                guard let idx = rails.firstIndex(of: activeRail) else { return }
                if dx < 0 {
                    let nxt = idx + 1
                    guard nxt < rails.count else { return }
                    withAnimation(.snappy(duration: 0.28)) { activeRail = rails[nxt] }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else {
                    let prv = idx - 1
                    guard prv >= 0 else { return }
                    withAnimation(.snappy(duration: 0.28)) { activeRail = rails[prv] }
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
    }

    // Slim vertical rule, anchored at the top of the tab row so it
    // spans only the label band — never crosses the active-tab
    // underline or the count caption below it.
    private var railTabDivider: some View {
        Rectangle()
            .fill(inkColor.opacity(0.18))
            .frame(width: 0.5, height: 16)
            .padding(.top, 2)
            .padding(.horizontal, 14)
    }

    private func railTab(for kind: RailKind) -> some View {
        let isActive = (activeRail == kind)
        let tint = accent(for: kind)
        let count = ids(for: kind).count

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.snappy(duration: 0.28)) { activeRail = kind }
        } label: {
            VStack(spacing: 5) {
                Text(kind.label)
                    .scaledFont(size: 15,
                                  weight: isActive ? .semibold : .regular,
                                  design: .serif)
                    .foregroundStyle(isActive ? inkColor : mutedText.opacity(0.85))
                // Active-tab ink line. Owned by matchedGeometryEffect
                // so the bar slides between labels when activeRail
                // changes inside withAnimation.
                ZStack {
                    if isActive {
                        Rectangle()
                            .fill(tint)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "rail-underline", in: railTabNS)
                    } else {
                        Color.clear.frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                // Count sits below the underline like an editorial
                // sub-caption. Pulled out of the top-right corner so
                // it no longer competes with the info dot for that
                // same real estate.
                Text("\(count)")
                    .scaledFont(size: 10, weight: .medium, design: .monospaced)
                    .tracking(0.4)
                    .foregroundStyle(isActive ? tint : mutedText.opacity(0.55))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(kind.label), \(count) papers")
        // Per-tab info dot pinned to the top-right of the label.
        // Floats slightly above and outside the label so it reads as
        // a margin annotation rather than part of the title.
        .overlay(alignment: .topTrailing) {
            tabInfoDot(for: kind)
                .offset(x: 8, y: -6)
        }
    }

    /// Tiny editorial "i" affordance, one per tab. Hairline circle +
    /// italic lowercase serif i, sized small enough to read as a
    /// margin mark, not as a chrome button. Anchors its own popover.
    private func tabInfoDot(for kind: RailKind) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            infoRailLabel = (infoRailLabel == kind.label) ? nil : kind.label
        } label: {
            ZStack {
                Circle()
                    .stroke(inkColor.opacity(0.30), lineWidth: 0.7)
                    .frame(width: 13, height: 13)
                Text("i")
                    .scaledFont(size: 9, weight: .regular, design: .serif)
                    .italic()
                    .foregroundStyle(inkColor.opacity(0.6))
                    .baselineOffset(-0.5)
            }
            .frame(width: 22, height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What does \(kind.label) mean?")
        .popover(
            isPresented: Binding(
                get: { infoRailLabel == kind.label },
                set: { presented in
                    if !presented, infoRailLabel == kind.label {
                        infoRailLabel = nil
                    }
                }
            ),
            attachmentAnchor: .point(.bottom),
            arrowEdge: .top
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text(kind.label)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                Text(kind.info)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 240, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .presentationCompactAdaptation(.popover)
        }
    }

    /// Content for the active rail: horizontal card scroller. The
    /// caption used to live above the cards but the info popover now
    /// carries the same explanation, so the caption row was duplicate
    /// noise and got pulled.
    private var railBody: some View {
        let kind = activeRail
        let railIds = ids(for: kind)
        let tint = accent(for: kind)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(railIds, id: \.self) { id in
                    relCard(id: id, accent: tint)
                }
            }
            .padding(.horizontal, 22)
        }
        .id("rail-\(kind.label)")
        .transition(.opacity)
    }

    /// Shown while the backend graph loads for a paper with no curated rails
    /// yet — keeps the hub from looking dead-ended for a freshly ingested paper.
    private var railsLoadingState: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Finding related papers")
                .scaledFont(size: 12, design: .serif)
                .italic()
                .foregroundStyle(mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func relCard(id: String, accent: Color) -> some View {
        let cluster = SimilarityGraph.displayCluster(forPaperId: id, deckHint: deckById[id])
        let progress = progressStore.progress(for: id)

        let isRead = progress >= 0.98

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if drillDownRelatedInPlace {
                focus(on: id, addToTrail: true)
            } else {
                presentedPaper = .exploreHub(paperId: id)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Circle().fill(cluster.color).frame(width: 5, height: 5)
                    Text(cluster.label.uppercased())
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.2)
                        .foregroundStyle(cluster.color)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                // Always show the canonical paper title — never substitute
                // hook / distill copy, which confused users ("description"
                // instead of bibliographic title) on Builds on / Led to / Adjacent.
                Text(title(for: id))
                    .scaledFont(size: 13, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor.opacity(isRead ? 0.65 : 1.0))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .scaledFont(size: 9, weight: .bold)
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .frame(width: 180, height: 140, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isRead ? Color(hex: "f5efe2") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isRead ? tealAccent.opacity(0.35) : accent.opacity(0.30),
                            lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isRead {
                    readStamp
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                }
            }
            .shadow(color: accent.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.32) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.snappy(duration: 0.18)) { previewId = id }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title(for: id))
        .accessibilityValue("\(cluster.label)\(isRead ? ", read" : "")")
        .accessibilityHint("Opens this related paper")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Preview") {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.snappy(duration: 0.18)) { previewId = id }
        }
    }

    /// Quiet editorial "read" mark. Italic serif lowercase, hairline
    /// teal underline, tiny check. No fill, no rotation. Reads like
    /// a margin annotation rather than a postmark.
    private var readStamp: some View {
        let color = tealAccent
        return HStack(spacing: 4) {
            Text("read")
                .scaledFont(size: 11, weight: .regular, design: .serif)
                .italic()
                .foregroundStyle(color)
            Image(systemName: "checkmark")
                .scaledFont(size: 8, weight: .semibold)
                .foregroundStyle(color.opacity(0.75))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(color.opacity(0.55))
                .frame(height: 0.6)
                .padding(.horizontal, 6)
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            Button {
                presentedPaper = .readDeck(paperId: focusedId)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Text("Open paper")
                        .scaledFont(size: 14, weight: .semibold)
                    Image(systemName: "arrow.right")
                        .scaledFont(size: 12, weight: .bold)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tealAccent)
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the reading flow for this paper")

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                // Signed out: route to Profile to sign in, skip the flash.
                guard savedStore.toggleOrPromptSignIn(focusedId) else { return }
                savedFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { savedFlash = false }
            } label: {
                Image(systemName: savedStore.isSaved(focusedId) ? "bookmark.fill" : "bookmark")
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundStyle(savedStore.isSaved(focusedId) ? tealAccent : inkColor)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .scaleEffect(savedFlash ? 1.18 : 1.0)
                    .motionAware(.snappy, value: savedFlash)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(savedStore.isSaved(focusedId) ? "Remove from library" : "Save to library")
        }
    }

    // MARK: cluster tint + meta

    private var clusterTint: some View {
        let c = topicCluster.color
        return LinearGradient(
            colors: [c.opacity(0.05), c.opacity(0.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }

    private func estReadMin(for id: String) -> Int {
        let n = cardCount(for: id) ?? 6
        return max(3, Int(Double(n) * 1.8))
    }

    private func cardCount(for id: String) -> Int? {
        if let deck = deckById[id], !deck.concepts.isEmpty { return deck.concepts.count + 2 }
        if DailyLoopContent.byPaperId(id) != nil { return 6 }
        return nil
    }

    // MARK: preview overlay (long-press)

    private func previewOverlay(id: String) -> some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.18)) { previewId = nil }
                }
                .accessibilityLabel("Dismiss preview")
                .accessibilityAddTraits(.isButton)
            VStack(alignment: .leading, spacing: 10) {
                let pcl = SimilarityGraph.displayCluster(forPaperId: id, deckHint: deckById[id])
                HStack(spacing: 5) {
                    Circle().fill(pcl.color).frame(width: 5, height: 5)
                    Text(pcl.label.uppercased())
                        .scaledFont(size: 9, weight: .bold)
                        .tracking(1.4)
                        .foregroundStyle(pcl.color)
                    Spacer()
                }
                Text(title(for: id))
                    .scaledFont(size: 18, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if let hook = hook(for: id), !hook.isEmpty {
                    Text(hook)
                        .scaledFont(size: 13, design: .serif)
                        .italic()
                        .foregroundStyle(mutedText)
                        .lineSpacing(2)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    Button {
                        let target = id
                        withAnimation(.snappy(duration: 0.18)) { previewId = nil }
                        // Defer the sheet present until after the
                        // overlay's opacity transition completes, so
                        // we don't fight two simultaneous animations.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            presentedPaper = .readDeck(paperId: target)
                        }
                    } label: {
                        Text("Open")
                            .scaledFont(size: 12, weight: .semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(tealAccent)
                            )
                    }
                    .buttonStyle(.plain)
                    Button {
                        withAnimation(.snappy(duration: 0.18)) { previewId = nil }
                    } label: {
                        Text("Dismiss")
                            .scaledFont(size: 12, weight: .semibold)
                            .foregroundStyle(inkColor)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: inkColor.opacity(0.25), radius: 28, x: 0, y: 12)
            .padding(.horizontal, 28)
            .accessibilityAddTraits(.isModal)
        }
    }

    // MARK: page swipe

    /// Horizontal swipe on the hero / breadcrumb stack only — back (right edge).
    /// Not attached to the ScrollView viewport so swipes on the rail tab strip
    /// (`railSectionSwipeGesture`) are not swallowed as a page dismiss / trail pop.
    private var pageSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { v in
                let dx = v.translation.width
                let dy = v.translation.height
                guard abs(dx) > abs(dy) * 1.8 else { return }
                // Visual tug follows only deliberate horizontal drags.
                guard dx > 0 else {
                    pageDragActive = true
                    pageDragX = max(-20, dx * 0.15)
                    return
                }
                pageDragActive = true
                let capped = min(dx, 140)
                let overflow = dx - capped
                pageDragX = capped + overflow * 0.18
            }
            .onEnded { v in
                let dx = v.translation.width
                let dy = v.translation.height
                let predominantlyHorizontal = abs(dx) > abs(dy) * 1.8
                let pastThreshold = dx > 80
                pageDragActive = false
                withAnimation(.snappy(duration: 0.22)) { pageDragX = 0 }
                guard predominantlyHorizontal, pastThreshold else { return }
                if popTrail() {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else if let onDismiss {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    onDismiss()
                }
            }
    }

    // MARK: actions

    /// Swap the focused paper. `addToTrail` defaults to true so rail-card
    /// taps build a breadcrumb the user can walk back. Pass `false`
    /// for "fresh start" actions like Random — otherwise repeated
    /// presses pile up trail entries the user never asked for.
    /// If `id` already appears anywhere in the trail, trim back to that
    /// ancestor instead of lengthening — keeps breadcrumbs unique without cycles.
    private func focus(on rawId: String, addToTrail: Bool = true) {
        // Normalize to the paper's canonical id, so a rail card or search hit
        // for a curated paper always lands on the same hub with the same rails.
        let id = RelatedPapers.preferredId(for: rawId, deck: deckById[rawId])
        guard id != focusedId else { return }
        if addToTrail {
            if let rewind = trail.firstIndex(of: id) {
                trail = Array(trail.prefix(rewind))
                withAnimation(.snappy(duration: 0.22)) { focusedId = id }
                return
            }
            trail.append(focusedId)
            if trail.count > 8 { trail = Array(trail.suffix(8)) }
        }
        withAnimation(.snappy(duration: 0.22)) { focusedId = id }
    }

    /// Swipe-right: pop trail back one step. Returns true if popped.
    private func popTrail() -> Bool {
        guard let last = trail.last else { return false }
        trail.removeLast()
        withAnimation(.snappy(duration: 0.22)) { focusedId = last }
        return true
    }

    private func applySearch(_ q: String) {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        // Find the best match by simple substring score.
        let scored = SimilarityGraph.papers.map { p -> (String, Int) in
            let hay = (title(for: p.id) + " " + (hook(for: p.id) ?? "") + " "
                       + p.concepts.joined(separator: " ")).lowercased()
            var s = 0
            if hay.contains(trimmed) { s += 5 }
            for c in p.concepts where c.contains(trimmed) { s += 3 }
            if p.cluster.searchableBlob.contains(trimmed) { s += 8 }
            return (p.id, s)
        }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        if let best = scored.first?.0, best != focusedId {
            focus(on: best)
        }
    }

    // MARK: helpers

    private func title(for id: String) -> String {
        if let deck = deckById[id], let t = deck.title, !t.isEmpty { return t }
        if let loop = DailyLoopContent.byPaperId(id) {
            if let t = loop.paperTitle, !t.isEmpty { return t }
            return loop.sourceLine
        }
        return fallbackTitle(id: id)
    }

    private func hook(for id: String) -> String? {
        if let deck = deckById[id], let h = deck.hook, !h.isEmpty { return h }
        if let loop = DailyLoopContent.byPaperId(id) { return loop.hookBody }
        return nil
    }

    private func fallbackTitle(id: String) -> String {
        id.replacingOccurrences(of: "loop:foundational:", with: "")
          .replacingOccurrences(of: "loop:", with: "")
          .replacingOccurrences(of: "-", with: " ")
          .capitalized
    }

    private func shortTitle(for id: String) -> String {
        let t = title(for: id)
        if t.count <= 22 { return t }
        return String(t.prefix(20)) + "…"
    }

    /// Reading flow deck (loops + API cards) launched from Open / preview.
    @ViewBuilder
    private func readDeckDestination(paperId: String) -> some View {
        if let deck = deckById[paperId] {
            DeckDestination(deck: deck)
        } else if let loop = DailyLoopContent.byPaperId(paperId) {
            DeckDestination(deck: CardDeck.fromLoop(paperId: paperId, content: loop))
        } else {
            VStack(spacing: 14) {
                Text("Couldn't open this paper")
                    .scaledFont(size: 16, weight: .semibold, design: .serif)
                Text(paperId)
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(mutedText)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(paperBg)
        }
    }
}

// MARK: - ExplorePaperHubSheet
//
// Presents the same Discover brace hub (hero + Builds on / Led to / Adjacent)
// inside a modal. Rail cards inside drill down in-place; "Open paper" still
// surfaces the reading-flow sheet on top.

private struct ExplorePaperHubSheet: View {
    let decks: [CardDeck]
    let entryPaperId: String
    let onDismiss: () -> Void

    @State private var hubFocusedId: String

    init(decks: [CardDeck], entryPaperId: String, onDismiss: @escaping () -> Void) {
        self.decks = decks
        self.entryPaperId = entryPaperId
        self.onDismiss = onDismiss
        // Normalize so a rail card opening a curated paper's hub keys on the
        // same canonical id as every other entry path.
        _hubFocusedId = State(initialValue: RelatedPapers.preferredId(for: entryPaperId))
    }

    var body: some View {
        ExploreFocusView(
            decks: decks,
            focusedId: $hubFocusedId,
            query: "",
            onDismiss: onDismiss,
            drillDownRelatedInPlace: true
        )
    }
}
