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
    /// Presents the "Topics" sheet (browse the catalog by theme).
    @State private var showTopicsSheet = false
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
                browseView
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
        .sheet(isPresented: $showTopicsSheet) {
            TopicsSheet(topics: Topic.all, count: { topicCount($0) }) { topic in
                openTopic(topic)
            }
        }
        .task {
            rebuildSearchIndex()          // index curated decks immediately
            await viewModel.loadAll()
            rebuildSearchIndex()          // reindex once backend decks arrive
        }
        .onChange(of: viewModel.decks.count) { _, _ in
            rebuildSearchIndex()
        }
        .motionAware(.snappy(duration: 0.28), value: displayMode)
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

    // Idle quick actions — Topics + Random. Same capsule chrome as `ExploreFocusView`.

    private var discoverChromeBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.95))
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            .shadow(color: inkColor.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    /// The two rounded entry points below the search bar in the idle state:
    /// Topics (browse by theme) on the left, Random (a surprise paper) on
    /// the right. Replaces the old recent-searches row.
    private var discoverActionPills: some View {
        HStack(spacing: 12) {
            discoverActionPill(icon: "square.grid.2x2", title: "Topics") {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                searchFocused = false
                showTopicsSheet = true
            }
            discoverActionPill(icon: "die.face.5", title: "Random") {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                focusedId = RelatedPapers.Entry.random.seedId()
                searchText = ""
                searchFocused = false
                withAnimation(.snappy(duration: 0.30)) { displayMode = .focus }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func discoverActionPill(icon: String,
                                    title: String,
                                    action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .scaledFont(size: 13, weight: .semibold)
                Text(title)
                    .scaledFont(size: 14, weight: .semibold)
            }
            .foregroundStyle(inkColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(discoverChromeBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title == "Topics" ? "Browse papers by topic" : "Open a random paper")
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
                .scaledFont(size: 440, weight: .regular, design: .serif)
                .italic()
                .foregroundStyle(tealAccent.opacity(0.04))
                .offset(x: 80, y: -20)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
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

            if queryNonEmpty {
                resultsCountLabel
                    .padding(.horizontal, compactExploreHeader ? 20 : 28)
                    .padding(.top, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            // No feed-error banner here on purpose: the backend feed is
            // additive over the bundled curated catalog, so a failed or
            // slow fetch leaves the app fully usable. Surfacing a network
            // error for it would alarm users for nothing.

            // Idle quick actions (Latest + Random). Collapses to zero height
            // while a query is active — same pattern the recent-searches row
            // used — so the search bar above keeps its sibling neighborhood
            // and is never recreated.
            discoverActionPills
                .padding(.top, 24)
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
        .motionAware(.spring(response: 0.42, dampingFraction: 0.88),
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
                .scaledFont(size: 28, weight: .regular, design: .serif)
                .tracking(-0.3)
                .foregroundStyle(inkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
            Text("A paper, a concept, or an idea.")
                .scaledFont(size: 14, weight: .regular, design: .serif)
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
                .scaledFont(size: 15, weight: .regular)
                .accessibilityHidden(true)
            TextField("Search papers, topics, or tags", text: $searchText)
                .scaledFont(size: 16, weight: .regular)
                .foregroundStyle(inkColor)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(mutedText.opacity(0.7))
                        .scaledFont(size: 15)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
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
        .motionAware(.easeOut(duration: 0.15), value: searchFocused)
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
                .scaledFont(size: 20, weight: .regular)
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

    /// Total matches after the optional topic filter (before the 12-row cap),
    /// so the subtle count under the bar reflects everything that matched.
    private var searchResultCount: Int {
        let ranked = rankedExploreSearchHits
        guard let filter = exploreTopicFilter else { return ranked.count }
        return ranked.filter { $0.cluster == filter }.count
    }

    /// Subtle "N results found" line under the search bar while a query is
    /// active. Hidden when nothing matches — the empty state speaks for that.
    @ViewBuilder
    private var resultsCountLabel: some View {
        let total = searchResultCount
        if total > 0 {
            Text("\(total) \(total == 1 ? "result" : "results") found")
                .scaledFont(size: 12, weight: .medium)
                .foregroundStyle(mutedText)
        }
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
                            .scaledFont(size: 9, weight: .bold)
                            .tracking(1.4)
                            .foregroundStyle(cluster.color)
                    }
                    Text(deck.title ?? "Untitled")
                        .scaledFont(size: 15, weight: .semibold, design: .serif)
                        .foregroundStyle(inkColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .scaledFont(size: 12, design: .serif)
                            .italic()
                            .foregroundStyle(mutedText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundStyle(tealAccent)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(deck.title ?? "Untitled"), \(cluster.label)")
        .accessibilityValue(subtitle)
        .accessibilityHint("Opens this paper")
        .accessibilityAddTraits(.isButton)
    }

    private var exploreEmptyResultsState: some View {
        let topicFilteredOut = exploreTopicFilter != nil
            && !rankedExploreSearchHits.isEmpty
            && searchResults.isEmpty

        return VStack(spacing: 10) {
            Image(systemName: topicFilteredOut ? "line.3.horizontal.decrease.circle" : "magnifyingglass")
                .scaledFont(size: 20, weight: .regular)
                .foregroundStyle(mutedText.opacity(0.5))
                .accessibilityHidden(true)
            if topicFilteredOut, let filter = exploreTopicFilter {
                Text("No \(filter.label) hits for \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .scaledFont(size: 15, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                Text("Try another topic filter or clear the filter to see all matches.")
                    .scaledFont(size: 13, weight: .regular)
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            } else {
                Text("No matches for \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .scaledFont(size: 15, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                Text("Try a topic tag (Vision, Language, Reasoning, …), a concept like attention, or a plain question.")
                    .scaledFont(size: 13, weight: .regular)
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

    /// Number of distinct papers in the corpus that match a topic's query.
    /// Mirrors the `contains` checks used by search ranking, but only counts
    /// hits — cheap enough to call once per topic when the sheet appears.
    private func topicCount(_ topic: Topic) -> Int {
        let q = topic.query.lowercased()
        guard !q.isEmpty else { return 0 }
        let tokens = q
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 }
        return searchIndex.reduce(into: 0) { acc, idx in
            var matched = idx.title.contains(q) || idx.concepts.contains(q)
                || idx.hook.contains(q) || idx.topicBlob.contains(q)
            if !matched {
                matched = tokens.contains { t in
                    idx.title.contains(t) || idx.concepts.contains(t)
                        || idx.hook.contains(t) || idx.topicBlob.contains(t)
                }
            }
            if matched { acc += 1 }
        }
    }

    /// Tapping a topic runs the existing corpus search for that topic's query,
    /// so the browse results list surfaces every matching paper. Reuses the
    /// search path rather than a bespoke topic feed, so ranking, topic-filter,
    /// and the focus hub all keep working unchanged.
    private func openTopic(_ topic: Topic) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        showTopicsSheet = false
        searchFocused = false
        exploreSearchCommitted = true
        withAnimation(.snappy(duration: 0.30)) {
            displayMode = .browse
            searchText = topic.query
        }
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

// MARK: - Topic

/// A browse-by-theme entry point. `query` is fed into the existing corpus
/// search when the topic is tapped, so each topic surfaces its matching papers
/// without a separate feed. Ordered by appeal; the first is the featured hero.
struct Topic: Identifiable {
    let id: String
    let title: String
    let blurb: String
    let query: String      // search string that surfaces this topic's papers
    let symbol: String     // SF Symbol shown top-right
    let accent: Color

    static let all: [Topic] = [
        Topic(id: "llm",
              title: "Large Language Models",
              blurb: "How machines learned to read, write, and reason in words.",
              query: "language model", symbol: "text.bubble", accent: tealAccent),
        Topic(id: "transformers",
              title: "Transformers & Attention",
              blurb: "The architecture under every modern model.",
              query: "attention", symbol: "rectangle.connected.to.line.below",
              accent: Color(hex: "2db8b8")),
        Topic(id: "reasoning",
              title: "Reasoning",
              blurb: "Teaching models to think step by step.",
              query: "reasoning", symbol: "brain", accent: Color(hex: "8a5a18")),
        Topic(id: "vision",
              title: "Computer Vision",
              blurb: "Making machines see and understand images.",
              query: "vision", symbol: "eye", accent: Color(hex: "8a4ec2")),
        Topic(id: "generative",
              title: "Generative Models",
              blurb: "AI that creates: images, audio, whole worlds.",
              query: "generative", symbol: "wand.and.stars", accent: Color(hex: "c25a8a")),
        Topic(id: "rl",
              title: "Reinforcement Learning",
              blurb: "Learning from reward instead of answer keys.",
              query: "reinforcement", symbol: "arrow.triangle.2.circlepath",
              accent: Color(hex: "c07014")),
        Topic(id: "foundations",
              title: "Foundations",
              blurb: "The building blocks: one neuron to backprop.",
              query: "foundations", symbol: "square.stack.3d.up", accent: Color(hex: "2a6d7a")),
        Topic(id: "embeddings",
              title: "Embeddings",
              blurb: "Turning words and things into geometry.",
              query: "embedding", symbol: "point.3.connected.trianglepath.dotted",
              accent: Color(hex: "3a7ca5")),
        Topic(id: "training",
              title: "Optimization & Training",
              blurb: "The tricks that make deep networks actually learn.",
              query: "optimization", symbol: "function", accent: Color(hex: "5a9fd8")),
        Topic(id: "scaling",
              title: "Scaling & Efficiency",
              blurb: "Bigger, faster, cheaper: more model for less.",
              query: "scaling", symbol: "chart.line.uptrend.xyaxis", accent: amberAccent),
        Topic(id: "alignment",
              title: "Alignment & Human Feedback",
              blurb: "Steering models toward what people actually want.",
              query: "feedback", symbol: "checkmark.shield", accent: Color(hex: "7a4040")),
    ]
}

// MARK: - TopicsSheet
//
// Presented from the "Topics" pill on Discover. An editorial browse page: a
// bold serif masthead, one featured topic with bespoke hand-built artwork, and
// a two-column grid of the rest. Every topic carries its own little illustration
// — an isometric stack of "papers" resting on a halftone-dot ground — so the
// page reads as crafted, not a wall of icons. Tapping a topic runs the corpus
// search for that topic and shows the results.

struct TopicsSheet: View {
    let topics: [Topic]
    /// Live count of papers matching each topic's query (0 hides the count).
    var count: (Topic) -> Int = { _ in 0 }
    let onSelect: (Topic) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                sheetBackdrop.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        if let featured = topics.first {
                            FeaturedTopicCard(topic: featured, count: count(featured)) {
                                onSelect(featured)
                            }
                        }
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(Array(topics.dropFirst())) { topic in
                                CompactTopicCard(topic: topic, count: count(topic)) {
                                    onSelect(topic)
                                }
                            }
                        }
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 2)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Text("Done")
                            .scaledFont(size: 14, weight: .semibold)
                            .foregroundStyle(inkColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color.white.opacity(0.95))
                                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // Soft paper backdrop with two faint blooms so the sheet reads as a
    // composed surface, not a flat list page.
    private var sheetBackdrop: some View {
        ZStack {
            paperBg
            RadialGradient(colors: [tealAccent.opacity(0.10), .clear],
                           center: UnitPoint(x: 0.86, y: 0.06),
                           startRadius: 0, endRadius: 340)
            RadialGradient(colors: [amberAccent.opacity(0.08), .clear],
                           center: UnitPoint(x: 0.1, y: 0.96),
                           startRadius: 0, endRadius: 320)
        }
    }

    // Editorial masthead: tracked eyebrow + a large bold serif title.
    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Circle().fill(tealAccent).frame(width: 5, height: 5)
                Text("RESEARCH, BY THEME")
                    .scaledFont(size: 10, weight: .bold)
                    .tracking(2.0)
                    .foregroundStyle(tealAccent)
            }
            Text("Explore topics")
                .scaledFont(size: 33, weight: .bold, design: .serif)
                .foregroundStyle(inkColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }
}

// MARK: - Topic cards

// The hero: a big white plate holding the topic's artwork with the title set
// over it bottom-left, then an italic descriptor + chevron beneath on the
// paper — the editorial rhythm of the reference shot.
private struct FeaturedTopicCard: View {
    let topic: Topic
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RadialGradient(colors: [topic.accent.opacity(0.12), .clear],
                                       center: UnitPoint(x: 0.85, y: 0.12),
                                       startRadius: 0, endRadius: 240)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    TopicGlyph(topic: topic)
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .padding(.top, 6)

                    Spacer(minLength: 12)

                    Text(topic.title)
                        .scaledFont(size: 23, weight: .bold, design: .serif)
                        .foregroundStyle(inkColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .bottom, spacing: 12) {
                        Text(topic.blurb)
                            .scaledFont(size: 13.5, design: .serif)
                            .italic()
                            .foregroundStyle(mutedText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .scaledFont(size: 13, weight: .bold)
                            .foregroundStyle(topic.accent)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(topic.accent.opacity(0.10)))
                    }
                    .padding(.top, 9)
                }
                .padding(20)

                if count > 0 {
                    TopicCountChip(count: count, accent: topic.accent)
                        .padding(18)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(borderColor.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: inkColor.opacity(0.08), radius: 16, x: 0, y: 7)
        }
        .buttonStyle(TopicCardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(topic.title)
        .accessibilityValue(count > 0 ? "\(count) \(count == 1 ? "paper" : "papers"). \(topic.blurb)" : topic.blurb)
        .accessibilityHint("Browse this topic")
        .accessibilityAddTraits(.isButton)
    }
}

// Grid tile: artwork plate on top, title + count set beneath on the paper.
private struct CompactTopicCard: View {
    let topic: Topic
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RadialGradient(colors: [topic.accent.opacity(0.12), .clear],
                                           center: UnitPoint(x: 0.84, y: 0.12),
                                           startRadius: 0, endRadius: 130)
                        )
                    TopicGlyph(topic: topic, compact: true)
                        .frame(maxWidth: .infinity)
                        .frame(height: 92)
                        .padding(.vertical, 10)
                }
                .frame(height: 118)
                .overlay(alignment: .topLeading) {
                    if count > 0 {
                        TopicCountChip(count: count, accent: topic.accent)
                            .padding(12)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(borderColor.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: inkColor.opacity(0.06), radius: 9, x: 0, y: 4)

                Text(topic.title)
                    .scaledFont(size: 14.5, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    // Reserve two lines so single-line titles keep the same
                    // height — that way every tile aligns on one horizontal line.
                    .frame(height: 40, alignment: .topLeading)
                    .padding(.horizontal, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TopicCardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(topic.title)
        .accessibilityValue(count > 0 ? "\(count) \(count == 1 ? "paper" : "papers")" : "")
        .accessibilityHint("Browse this topic")
        .accessibilityAddTraits(.isButton)
    }
}

// Small "N papers" pill that sits over the artwork plate.
private struct TopicCountChip: View {
    let count: Int
    let accent: Color
    var body: some View {
        Text("\(count) \(count == 1 ? "paper" : "papers")")
            .scaledFont(size: 10, weight: .bold)
            .tracking(0.4)
            .foregroundStyle(accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Color.white.opacity(0.92))
                    .overlay(Capsule().stroke(accent.opacity(0.32), lineWidth: 1))
            )
    }
}

// MARK: - TopicGlyph (bespoke per-topic artwork)
//
// Hand-built illustration shared by every topic: a halftone-dot ground (the
// "printed" texture from the reference), an isometric fan of three papers tinted
// with the topic's accent, and the topic's mark stamped on the front page over
// two ruled lines. Pure SwiftUI shapes — no asset files, no chart libraries —
// so it stays crisp at any size and recolors per topic.
struct TopicGlyph: View {
    let topic: Topic
    var compact: Bool = false

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let pw = h * 0.62          // paper width
            let ph = h * 0.82          // paper height
            ZStack {
                // Halftone ground — the isometric "shadow" the stack rests on.
                HalftoneField(color: topic.accent, gap: compact ? 6.5 : 8.5)
                    .frame(width: pw * 1.95, height: ph * 0.52)
                    .clipShape(Ellipse())
                    .rotationEffect(.degrees(-3))
                    .offset(y: ph * 0.36)
                    .opacity(0.65)

                // Back + middle papers, fanned and tinted.
                paper(fill: topic.accent.opacity(0.20),
                      stroke: topic.accent.opacity(0.40), w: pw, h: ph)
                    .rotationEffect(.degrees(-11))
                    .offset(x: -pw * 0.34, y: -h * 0.01)

                paper(fill: topic.accent.opacity(0.11),
                      stroke: topic.accent.opacity(0.30), w: pw, h: ph)
                    .rotationEffect(.degrees(9))
                    .offset(x: pw * 0.30, y: -h * 0.03)

                // Front page: white, with the topic mark + ruled lines.
                frontPaper(w: pw, h: ph)
                    .rotationEffect(.degrees(-2))
            }
            .frame(width: geo.size.width, height: h, alignment: .center)
        }
        .accessibilityHidden(true)
    }

    private func paper(fill: Color, stroke: Color, w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.11, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: w * 0.11, style: .continuous)
                    .stroke(stroke, lineWidth: 1.2)
            )
            .frame(width: w, height: h)
    }

    private func frontPaper(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.11, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.11, style: .continuous)
                        .stroke(topic.accent.opacity(0.5), lineWidth: 1.4)
                )
                .shadow(color: inkColor.opacity(0.14), radius: 5, x: 0, y: 4)

            VStack(spacing: h * 0.085) {
                Image(systemName: topic.symbol)
                    .scaledFont(size: w * 0.34, weight: .semibold)
                    .foregroundStyle(topic.accent)
                VStack(spacing: h * 0.05) {
                    Capsule().fill(topic.accent.opacity(0.22))
                        .frame(width: w * 0.54, height: max(2, h * 0.022))
                    Capsule().fill(topic.accent.opacity(0.15))
                        .frame(width: w * 0.38, height: max(2, h * 0.022))
                }
            }
        }
        .frame(width: w, height: h)
    }
}

// A grid of soft dots — the "halftone" print texture under each topic's stack.
private struct HalftoneField: View {
    let color: Color
    var dot: CGFloat = 2.3
    var gap: CGFloat = 8.5

    var body: some View {
        Canvas { ctx, size in
            guard gap > 0 else { return }
            let cols = Int(size.width / gap) + 1
            let rows = Int(size.height / gap) + 1
            for r in 0..<rows {
                for c in 0..<cols {
                    let x = CGFloat(c) * gap + gap / 2
                    let y = CGFloat(r) * gap + gap / 2
                    // Fade toward the bottom edge so the ground melts into paper.
                    let fade = 1 - Double(y / size.height)
                    let op = 0.08 + 0.34 * max(0, fade)
                    let rect = CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(op)))
                }
            }
        }
    }
}

// Subtle tactile press: the card settles slightly, like pressing a real card.
private struct TopicCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.015 : 0)
            .motionAware(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
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
                    .scaledFont(size: 9, weight: .bold)
                    .tracking(1.6)
                    .foregroundStyle(tealAccent)
                Text(headline)
                    .scaledFont(size: 14, weight: .semibold, design: .serif)
                    .foregroundStyle(inkColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if showProgress {
                    progressBar
                } else if let title = deck.title, !title.isEmpty, title != headline {
                    Text(title)
                        .scaledFont(size: 11)
                        .foregroundStyle(mutedText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .scaledFont(size: 12, weight: .semibold)
                .foregroundStyle(mutedText.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kicker). \(headline)")
        .accessibilityValue(showProgress ? "\(Int(progress * 100)) percent read" : "")
        .accessibilityAddTraits(.isButton)
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
