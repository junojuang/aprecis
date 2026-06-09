import SwiftUI
import UIKit

// MARK: - ExploreView
//
// Two-state Explore. Default = a single search field; Random sits
// top-right (matches focus chrome). Typing opens results; tapping Random
// opens the focus view: one paper hub with relationship rails (Builds
// on / Led to / Adjacent / Surprise). Stripped of entry chips so the
// surface reads like ChatGPT/Anthropic: one prompt, smart routing.

struct ExploreView: View {
    @ObservedObject var viewModel: FeedViewModel
    /// Root tab selection (Discover = 0) so horizontal swipes can jump to Profile.
    @Binding var mainTabSelection: Int
    /// Bumped by MainTabView when Discover is (re-)selected — pop brace hub back to browse.
    let discoverPopToBrowseSignal: Int
    /// Called when Discover tab is tapped while already selected (`TabView` selection does not change).
    let onDiscoverRepeatedTabBump: () -> Void

    @State private var searchText = ""
    @State private var focusedId: String = RelatedPapers.starter
    @State private var displayMode: DisplayMode = .browse
    @FocusState private var searchFocused: Bool
    /// True after keyboard dismiss / Search key with non-empty query; drives compact header layout.
    @State private var exploreSearchCommitted = false
    /// Optional Explore result filter (`nil` = all topics).
    @State private var exploreTopicFilter: SimilarityGraph.Cluster? = nil
    /// Search corpus, preprocessed once when decks change. Rebuilt off the
    /// keystroke path so typing only runs cheap `contains` checks, never the
    /// per-deck lowercasing and cluster inference that made search lag.
    @State private var searchIndex: [IndexedDeck] = []

    @ObservedObject private var recentSearches = RecentSearchesStore.shared

    enum DisplayMode: Equatable { case browse, focus }

    var body: some View {
        let root = ZStack(alignment: .top) {
            switch displayMode {
            case .browse:
                ZStack(alignment: .topTrailing) {
                    browseView
                    if !queryNonEmpty {
                        discoverRandomPill
                            .padding(.trailing, 14)
                            .padding(.top, 10)
                    }
                }
            case .focus:
                ExploreFocusView(
                    decks: allDecks,
                    focusedId: $focusedId,
                    query: searchText,
                    onDismiss: { dismissFocus() }
                )
            }
        }
        // Backdrop is a background, not a ZStack sibling — a sibling with
        // ignoresSafeArea inflates the ZStack to full screen and pins
        // top-aligned content under the status bar.
        .background(backdrop.ignoresSafeArea())
        Group {
            if displayMode == .browse {
                root.adjacentTabSwipe(selection: $mainTabSelection, tabIndex: 0)
            } else {
                root
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            rebuildSearchIndex()          // index curated decks immediately
            await viewModel.loadAll()
            rebuildSearchIndex()          // reindex once backend decks arrive
        }
        .onChange(of: viewModel.decks.count) { _, _ in
            rebuildSearchIndex()
        }
        .animation(.snappy(duration: 0.28), value: displayMode)
        .onChange(of: searchFocused) { _, focused in
            if !focused, queryNonEmpty {
                exploreSearchCommitted = true
            }
        }
        .onChange(of: searchText) { _, new in
            if new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                exploreSearchCommitted = false
                exploreTopicFilter = nil
            }
        }
        .onChange(of: discoverPopToBrowseSignal) { _, _ in
            resetDiscoverToIdleHomeFromTab()
        }
        // Passive tab-bar tap observer: re-tapping Discover while already on
        // it resets the hub back to the search page. Does not touch the
        // tab-bar delegate, so SwiftUI's selection binding stays intact.
        .background(
            DiscoverTabReselectProbe(onDiscoverRepeatedTap: onDiscoverRepeatedTabBump)
        )
    }

    // Random — same capsule chrome as `ExploreFocusView`.

    private var discoverChromeBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.95))
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            .shadow(color: inkColor.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var discoverRandomPill: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            focusedId = RelatedPapers.Entry.random.seedId()
            searchText = ""
            searchFocused = false
            withAnimation(.snappy(duration: 0.30)) { displayMode = .focus }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "die.face.5")
                    .font(.system(size: 11, weight: .semibold))
                Text("Random")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(inkColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(discoverChromeBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open a random paper")
    }

    // MARK: backdrop
    //
    // Centered composition needs visual weight or it reads as void. A
    // pair of soft radial blooms plus a giant italic "?" watermark
    // fills the negative space without competing with the search bar.
    private var backdrop: some View {
        ZStack {
            paperBg
            RadialGradient(
                colors: [tealAccent.opacity(0.14), .clear],
                center: UnitPoint(x: 0.18, y: 0.18),
                startRadius: 0, endRadius: 380
            )
            RadialGradient(
                colors: [amberAccent.opacity(0.12), .clear],
                center: UnitPoint(x: 0.85, y: 0.86),
                startRadius: 0, endRadius: 360
            )
            Text("?")
                .font(.system(size: 440, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(tealAccent.opacity(0.04))
                .offset(x: 80, y: -20)
                .allowsHitTesting(false)
        }
    }

    // MARK: browse
    //
    // Single view tree, single search-bar instance. Toggle hero/results
    // via opacity + frame collapse so the TextField is never recreated
    // (same reason we avoid branching into two unrelated layouts).
    //
    // Random is a separate overlay in `body`, aligned with focus chrome.
    private var browseView: some View {
        VStack(spacing: 0) {
            // Idle: hero sits under a top Spacer; fixed padding to the bar (no middle Spacer gap).
            // With text: spacer until compact header. Bar pins near top after commit.
            if compactExploreHeader {
                Color.clear.frame(height: 16)
            } else if !queryNonEmpty {
                Spacer(minLength: 0)
                heroCopy
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            } else {
                Spacer(minLength: 0)
            }

            exploreSearchChromeRow
                .padding(.horizontal, compactExploreHeader ? 20 : 28)
                .id("explore-searchbar")

            // Idle-only extras (recent searches) collapse the same way.
            // Kept inside the always-present tree so the search bar never
            // loses its sibling neighborhood.
            //
            // No feed-error banner here on purpose: the backend feed is
            // additive over the bundled curated catalog, so a failed or
            // slow fetch leaves the app fully usable. Surfacing a network
            // error for it would alarm users for nothing.
            VStack(spacing: 0) {
                if !recentSearches.queries.isEmpty {
                    recentChips
                        .padding(.top, 32)
                }
            }
            .opacity(queryNonEmpty ? 0 : 1)
            .frame(height: queryNonEmpty ? 0 : nil)
            .allowsHitTesting(!queryNonEmpty)
            .clipped()

            // Results appear when searching. We keep this inside the
            // same VStack rather than swapping the whole layout, so
            // the search bar above it stays the same view instance.
            if queryNonEmpty {
                resultsList
                    .padding(.top, 12)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: compactExploreHeader ? .infinity : nil,
                        alignment: .top
                    )
                    .transition(.opacity)
            }

            if compactExploreHeader {
                Color.clear.frame(height: 12)
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Smooth spring so the bar floats from middle to top rather
        // than snapping. Damping tuned so it lands without bounce.
        .animation(.spring(response: 0.42, dampingFraction: 0.88),
                   value: compactExploreHeader || queryNonEmpty)
        .contentShape(Rectangle())
        .onTapGesture { searchFocused = false }
    }

    private var queryNonEmpty: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var compactExploreHeader: Bool {
        queryNonEmpty && exploreSearchCommitted
    }

    // Headline + subtitle. Used to ship with the search bar inside
    // the same VStack — that nesting was what triggered the layout
    // swap, so the bar now lives one level up and this view holds
    // just the type.
    private var heroCopy: some View {
        VStack(spacing: 8) {
            Text("Where should we begin?")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(inkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
            Text("A paper, a concept, or a question.")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: search

    // System sans for the input. Serif inside a text field reads as
    // a styled label, not a place to type. Sans-serif here matches
    // every iOS search field the user already knows.
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(searchFocused ? tealAccent : mutedText)
                .font(.system(size: 15, weight: .regular))
            TextField("Search papers, topics, or tags", text: $searchText)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(inkColor)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(mutedText.opacity(0.7))
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(searchFocused ? tealAccent.opacity(0.45) : borderColor.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.035), radius: 10, x: 0, y: 3)
        .animation(.easeOut(duration: 0.15), value: searchFocused)
    }

    /// Search capsule + optional topic filter (`SimilarityGraph.Cluster`).
    private var exploreSearchChromeRow: some View {
        HStack(alignment: .center, spacing: 10) {
            searchBar
                .frame(maxWidth: .infinity)
            if queryNonEmpty {
                exploreTopicFilterMenuButton
            }
        }
    }

    private var exploreTopicFilterMenuButton: some View {
        Menu {
            Button("All topics") { exploreTopicFilter = nil }
            Divider()
            ForEach(SimilarityGraph.Cluster.allCases, id: \.self) { cluster in
                Button {
                    exploreTopicFilter = cluster
                } label: {
                    if exploreTopicFilter == cluster {
                        Label(cluster.label, systemImage: "checkmark")
                    } else {
                        Text(cluster.label)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(exploreTopicFilter == nil ? mutedText : tealAccent)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Filter search by topic")
    }

    // MARK: - Results

    /// Lightweight ranked hit. Carries the deck so the row can render
    /// title + meta without re-querying the corpus.
    private struct SearchHit: Identifiable {
        let deck: CardDeck
        let score: Int
        let cluster: SimilarityGraph.Cluster
        var id: String { deck.canonicalBraceKey }
    }

    /// One deck with its search fields lowercased and its cluster resolved
    /// ahead of time. Built by `rebuildSearchIndex()`, never on a keystroke.
    private struct IndexedDeck {
        let deck: CardDeck
        let title: String        // lowercased
        let hook: String         // lowercased
        let concepts: String     // lowercased, space-joined
        let topicBlob: String    // cluster.searchableBlob
        let cluster: SimilarityGraph.Cluster
    }

    /// Preprocess the corpus once. The expensive parts, lowercasing every
    /// field and inferring each deck's cluster, happen here instead of on
    /// every keystroke.
    private func rebuildSearchIndex() {
        searchIndex = allDecks.map { deck in
            let cl = SimilarityGraph.cluster(for: deck)
            return IndexedDeck(
                deck: deck,
                title: (deck.title ?? "").lowercased(),
                hook: (deck.hook ?? "").lowercased(),
                concepts: deck.concepts.map { $0.title.lowercased() }
                    .joined(separator: " "),
                topicBlob: cl.searchableBlob,
                cluster: cl)
        }
    }

    /// Ranked corpus hits for the query before applying `exploreTopicFilter`.
    /// Runs only `contains` checks over the prebuilt index.
    private var rankedExploreSearchHits: [SearchHit] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let tokens = q
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0) }
            .filter { !$0.isEmpty }

        return searchIndex.compactMap { idx -> SearchHit? in
            var score = 0

            if idx.title.contains(q) { score += 12 }
            if idx.concepts.contains(q) { score += 8 }
            if idx.hook.contains(q) { score += 6 }
            if idx.title.hasPrefix(q) { score += 8 }
            if idx.topicBlob.contains(q) { score += 11 }

            for t in tokens where t.count >= 2 {
                if idx.title.contains(t) { score += 5 }
                if idx.concepts.contains(t) { score += 3 }
                if idx.hook.contains(t) { score += 2 }
                if idx.topicBlob.contains(t) { score += 4 }
            }

            guard score > 0 else { return nil }
            return SearchHit(deck: idx.deck, score: score, cluster: idx.cluster)
        }
        .sorted { $0.score > $1.score }
    }

    /// Up to 12 rows after optional similarity-graph cluster filter.
    private var searchResults: [SearchHit] {
        let ranked = rankedExploreSearchHits
        guard let filter = exploreTopicFilter else {
            return Array(ranked.prefix(12))
        }
        return Array(ranked.filter { $0.cluster == filter }.prefix(12))
    }

    @ViewBuilder
    private var resultsList: some View {
        let hits = searchResults
        if hits.isEmpty {
            exploreEmptyResultsState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(hits) { hit in
                        resultRow(hit: hit)
                    }
                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 20)
            }
            // Only the results scroll dismisses the keyboard — and
            // only on an interactive drag, never on layout-driven
            // implicit scroll events that fire as the user types.
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func resultRow(hit: SearchHit) -> some View {
        let deck = hit.deck
        let cluster = SimilarityGraph.cluster(for: deck)
        let subtitle: String = {
            if let h = deck.hook, !h.isEmpty { return h }
            let names = deck.concepts.prefix(3).map(\.title)
            if !names.isEmpty { return names.joined(separator: " · ") }
            return deck.topicCluster.label
        }()

        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            commit(deck: deck)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Circle().fill(cluster.color).frame(width: 5, height: 5)
                        Text(cluster.label.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(cluster.color)
                    }
                    Text(deck.title ?? "Untitled")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, design: .serif))
                            .italic()
                            .foregroundStyle(mutedText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tealAccent)
                    .padding(.top, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: inkColor.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var exploreEmptyResultsState: some View {
        let topicFilteredOut = exploreTopicFilter != nil
            && !rankedExploreSearchHits.isEmpty
            && searchResults.isEmpty

        return VStack(spacing: 10) {
            Image(systemName: topicFilteredOut ? "line.3.horizontal.decrease.circle" : "magnifyingglass")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(mutedText.opacity(0.5))
            if topicFilteredOut, let filter = exploreTopicFilter {
                Text("No \(filter.label) hits for \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                Text("Try another topic filter or clear the filter to see all matches.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            } else {
                Text("No matches for \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                Text("Try a topic tag (Vision, Language, Reasoning, …), a concept like attention, or a plain question.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .padding(.top, 32)
    }

    // Commit: record query, set focus target, dismiss keyboard, swap to focus view.
    // The focus id is normalized to the paper's canonical id so a curated paper
    // reached via search opens the same hub (same rails) as via Random.
    private func commit(deck: CardDeck) {
        recentSearches.record(searchText)
        focusedId = RelatedPapers.preferredId(for: deck.paperId, deck: deck)
        searchFocused = false
        withAnimation(.snappy(duration: 0.30)) { displayMode = .focus }
    }

    private var recentChips: some View {
        VStack(spacing: 10) {
            Text("Recent searches")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(mutedText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(recentSearches.queries, id: \.self) { q in
                        Button {
                            searchText = q
                            searchFocused = true
                        } label: {
                            Text(q)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(inkColor.opacity(0.78))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(Color.white.opacity(0.6))
                                        .overlay(Capsule().stroke(borderColor.opacity(0.6), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
            }
        }
    }

    // MARK: dismiss

    /// Leave the brace hub (`ExploreFocusView`) without wiping an active query.
    /// When the user picked a hit from search, `searchText` stays → `browseView`
    /// still shows compact header + results for that query once committed. Clearing the
    /// field here wrongly jumped them to the idle hero ("explore homepage").
    private func dismissFocus() {
        searchFocused = false
        withAnimation(.snappy(duration: 0.30)) { displayMode = .browse }
    }

    /// Discover tab becomes active / re-tapped: hero homepage with empty search (not results list).
    private func resetDiscoverToIdleHomeFromTab() {
        searchFocused = false
        withAnimation(.snappy(duration: 0.30)) {
            displayMode = .browse
            searchText = ""
        }
        // `exploreSearchCommitted` / `exploreTopicFilter` clear via `onChange(of: searchText)`.
    }

    // MARK: helpers

    private var allDecks: [CardDeck] {
        var merged: [CardDeck] = []
        merged.append(contentsOf: viewModel.decks)
        for entry in DailyLoopContent.allPrepared {
            let stamped = entry.content.withPaperId(entry.paperId)
            merged.append(CardDeck.fromLoop(paperId: entry.paperId, content: stamped))
        }
        return merged.mergingCanonicalBraceDuplicates()
    }

}

// MARK: - Discover tab reselection (already on Discover, tap Discover again)

/// `TabView(selection:)` fires no change when the already-selected tab is
/// tapped. Rather than hijack the `UITabBarController` delegate (which
/// desynced SwiftUI's selection binding and trapped the user on Discover),
/// this attaches a *passive* tap recognizer to the tab bar: it observes the
/// tap and never consumes it, so SwiftUI's own tab handling is untouched.
private struct DiscoverTabReselectProbe: UIViewControllerRepresentable {
    let onDiscoverRepeatedTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDiscoverRepeatedTap: onDiscoverRepeatedTap)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.isHidden = true
        vc.view.isUserInteractionEnabled = false
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onDiscoverRepeatedTap = onDiscoverRepeatedTap
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(host: uiViewController)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onDiscoverRepeatedTap: () -> Void
        private weak var observedTabBar: UITabBar?
        private weak var tabBarController: UITabBarController?

        init(onDiscoverRepeatedTap: @escaping () -> Void) {
            self.onDiscoverRepeatedTap = onDiscoverRepeatedTap
        }

        func attachIfNeeded(host: UIViewController) {
            guard let tab = host.tabBarController else { return }
            tabBarController = tab
            let bar = tab.tabBar
            guard observedTabBar !== bar else { return }
            observedTabBar = bar
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTabBarTap(_:)))
            // Observe only — never swallow the touch, so the tab bar selects
            // normally and SwiftUI's binding stays in charge.
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            tap.delegate = self
            bar.addGestureRecognizer(tap)
        }

        @objc private func handleTabBarTap(_ gr: UITapGestureRecognizer) {
            guard let bar = observedTabBar,
                  let tab = tabBarController,
                  let count = bar.items?.count, count > 0 else { return }
            let x = gr.location(in: bar).x
            let itemIndex = Int(x / (bar.bounds.width / CGFloat(count)))
            // Discover is index 0. Fire only when it is re-tapped while
            // already the active tab.
            guard itemIndex == 0, tab.selectedIndex == 0 else { return }
            onDiscoverRepeatedTap()
        }

        // Run alongside the tab bar's own gesture handling.
        func gestureRecognizer(_: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

// MARK: - TrendingRowView (kept for ProfileView library list)

struct TrendingRowView: View {
    let deck: CardDeck
    var slot: Int = 0
    var showProgress: Bool = false

    @ObservedObject private var progressStore = ReadingProgressStore.shared
    private var progress: Double { progressStore.progress(for: deck.paperId) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(kicker.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                Text(headline)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if showProgress {
                    progressBar
                } else if let title = deck.title, !title.isEmpty, title != headline {
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundStyle(mutedText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(mutedText.opacity(0.7))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tealAccent.opacity(0.14)).frame(height: 3)
                Capsule().fill(tealAccent).frame(width: geo.size.width * CGFloat(progress), height: 3)
            }
        }
        .frame(height: 3)
        .padding(.top, 4)
    }

    private var kicker: String {
        for k in TopicKickers.list {
            for term in k.terms {
                let blob = (deck.title ?? "") + " " + (deck.hook ?? "") + " "
                    + deck.concepts.map(\.title).joined(separator: " ")
                if blob.localizedCaseInsensitiveContains(term) { return k.label }
            }
        }
        return TopicKickers.list[slot % TopicKickers.list.count].label
    }

    private var headline: String {
        if let h = deck.hook, !h.isEmpty { return h }
        if let t = deck.title, !t.isEmpty { return t }
        return "Untitled"
    }
}

enum TopicKickers {
    struct Kicker { let label: String; let terms: [String] }

    static let list: [Kicker] = [
        Kicker(label: "Foundations", terms: ["perceptron", "backprop", "lenet", "convolutional"]),
        Kicker(label: "Language",    terms: ["transformer", "attention", "language model", "gpt", "bert", "embedding", "word"]),
        Kicker(label: "Reasoning",   terms: ["chain of thought", "reasoning", "scratchpad"]),
        Kicker(label: "Vision",      terms: ["vision", "image", "diffusion", "imagenet"]),
        Kicker(label: "Alignment",   terms: ["rlhf", "alignment", "preference", "reward"]),
        Kicker(label: "Eval",        terms: ["benchmark", "evaluation", "gsm8k", "mmlu"]),
    ]
}
