import SwiftUI
import UIKit

// MARK: - Tab swipe — Discover ⇄ Profile
//
// Matches tab bar geography: Discover (index 0) is left → swipe **left**
// reveals Profile. Profile is right → swipe **right** reveals Discover.
// The opposite swipe on each tab is ignored.

private struct AdjacentTabSwipeModifier: ViewModifier {
    @Binding var selection: Int
    let tabIndex: Int
    var demandingFocusContext: Bool = false

    func body(content: Content) -> some View {
        let minDx: CGFloat = demandingFocusContext ? 118 : 86
        let dominance: CGFloat = demandingFocusContext ? 2.38 : 1.62

        return content.simultaneousGesture(
            DragGesture(minimumDistance: demandingFocusContext ? 54 : 36)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > max(minDx, abs(dy) * dominance) else { return }
                    // Only start a tab swipe from the screen edge the sibling
                    // tab sits on. Page content (book shelves, card strips,
                    // search chips) keeps its own horizontal pans instead of
                    // flipping tabs.
                    let screenW = UIScreen.main.bounds.width
                    let edgeBand: CGFloat = 44
                    let startX = value.startLocation.x
                    switch tabIndex {
                    case 0:
                        // Discover → Profile: leftward swipe begun at the right edge.
                        guard dx < 0, startX > screenW - edgeBand else { return }
                    case 1:
                        // Profile → Discover: rightward swipe begun at the left edge.
                        guard dx > 0, startX < edgeBand else { return }
                    default:
                        return
                    }
                    if demandingFocusContext,
                       value.startLocation.y >= UIScreen.main.bounds.height * 0.5 {
                        return
                    }
                    let other = tabIndex == 0 ? 1 : 0
                    guard selection != other else { return }
                    withAnimation(.easeInOut(duration: 0.28)) {
                        selection = other
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
        )
    }
}

extension View {
    /// Switches MainTab to the sibling tab on a directional swipe (`tabIndex` 0 → left-swipe only, 1 → right-swipe only).
    func adjacentTabSwipe(selection: Binding<Int>, tabIndex: Int, demandingFocusContext: Bool = false) -> some View {
        modifier(AdjacentTabSwipeModifier(selection: selection, tabIndex: tabIndex, demandingFocusContext: demandingFocusContext))
    }
}

@main
struct MicrolearningApp: App {
    @StateObject private var viewModel  = FeedViewModel()
    @StateObject private var auth       = AuthViewModel()
    @State private var showLaunch       = true
    @AppStorage("onboarding.completed") private var onboardingCompleted: Bool = false

    init() {
        Self.clearBootstrappedFoundationalReadsIfNeeded()
    }

    // One-shot cleanup. An earlier build force-marked nine foundational
    // papers complete to unlock a bundle path that no longer exists. That
    // left bogus "read" stamps on Explore rail cards. If that bootstrap
    // ran (its flag is still present), zero those papers out and drop the
    // flag so this runs at most once. Fresh installs never had the flag.
    private static func clearBootstrappedFoundationalReadsIfNeeded() {
        let staleFlag = "debug.foundational.gpt3Unlocked.v1"
        guard UserDefaults.standard.bool(forKey: staleFlag) else { return }
        let slugs = ["perceptron", "backprop", "lenet", "alexnet",
                     "word2vec", "seq2seq", "gans", "resnet", "attention"]
        let store = ReadingProgressStore.shared
        for slug in slugs {
            store.setProgress(0.0, for: "loop:foundational:\(slug)")
        }
        UserDefaults.standard.removeObject(forKey: staleFlag)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingCompleted {
                    MainTabView(viewModel: viewModel)
                        .environmentObject(auth)
                        .preferredColorScheme(.light)
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .preferredColorScheme(.light)
                        .transition(.opacity)
                }

                if showLaunch {
                    LaunchScreen()
                        .transition(motionAwareTransition(.opacity.combined(with: .scale(scale: 1.05))))
                        .zIndex(1)
                }
            }
            .motionAware(.easeInOut(duration: 0.35), value: onboardingCompleted)
            .onAppear { scheduleLaunchDismiss() }
        }
    }

    private func scheduleLaunchDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.45)) {
                showLaunch = false
            }
        }
    }
}

/// The main-tab selection, persisted in UserDefaults so any view deep in a
/// NavigationStack can route to a tab without a binding threaded through the
/// hierarchy (e.g. a signed-out save attempt sending the reader to Profile).
enum AppTab {
    // v4: Discover (0) · Profile (1). Bumped from v3 (which had a Learn tab at
    // index 1) so existing users don't land on the removed tab after upgrade.
    static let storageKey = "selectedTab.v4"
    static let discover = 0
    static let profile  = 1

    @MainActor static func routeToProfile() {
        UserDefaults.standard.set(profile, forKey: storageKey)
    }
}

struct MainTabView: View {
    @ObservedObject var viewModel: FeedViewModel
    @AppStorage(AppTab.storageKey) private var selectedTab = AppTab.discover
    /// Incremented whenever Discover becomes active (selection change or re-tapping the tab).
    @State private var discoverPopNonce = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ExploreView(
                    viewModel: viewModel,
                    mainTabSelection: $selectedTab,
                    discoverPopToBrowseSignal: discoverPopNonce,
                    onDiscoverRepeatedTabBump: { discoverPopNonce &+= 1 }
                )
            }
            .tabItem { Label("Discover", systemImage: "safari") }
            .tag(AppTab.discover)

            NavigationStack {
                ProfileView(viewModel: viewModel, mainTabSelection: $selectedTab)
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(AppTab.profile)
        }
        .tint(tealAccent)
        .onChange(of: selectedTab) { _, new in
            if new == AppTab.discover { discoverPopNonce &+= 1 }
        }
    }
}