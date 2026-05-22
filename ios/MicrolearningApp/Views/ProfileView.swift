import SwiftUI
import AuthenticationServices

// MARK: - ProfileView

struct ProfileView: View {
    @ObservedObject var viewModel: FeedViewModel
    /// Root tab selection (Profile = 1); horizontal swipe returns to Discover.
    @Binding var mainTabSelection: Int
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            switch auth.state {
            case .loggedOut:
                SignedOutView()
            case .loggedIn(let session):
                SignedInView(session: session, viewModel: viewModel)
            case .confirmationRequired(let email):
                ConfirmationView(email: email)
            }
        }
        .adjacentTabSwipe(selection: $mainTabSelection, tabIndex: 1)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SignedOutView

private struct SignedOutView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(tealLight).frame(width: 72, height: 72)
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(tealAccent)
                }
                Text("Read smarter.")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(inkColor)
                Text("Sign in to sync your library and\ntrack your reading progress.")
                    .font(.system(size: 13))
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                auth.startAppleSignIn()
            } label: {
                HStack(spacing: 8) {
                    if auth.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16, weight: .medium))
                        Text("Sign in with Apple")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 280, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black)
                )
            }
            .buttonStyle(.plain)
            .disabled(auth.isLoading)

            if let err = auth.error, !err.isEmpty {
                signInErrorCard(message: err)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.22), value: auth.error)
    }

    private func signInErrorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(amberAccent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in didn't go through")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(inkColor)
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button {
                    auth.clearError()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(mutedText)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Button {
                    auth.retryAppleSignIn()
                } label: {
                    Text("Try again")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(inkColor)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: "mailto:hello@aprecis.app?subject=Sign%20in%20issue") {
                        #if canImport(UIKit)
                        UIApplication.shared.open(url)
                        #endif
                    }
                } label: {
                    Text("Email us")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(inkColor.opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(amberAccent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: inkColor.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - SignedInView

private struct SignedInView: View {
    @EnvironmentObject var auth: AuthViewModel
    let session: AuthSession
    @ObservedObject var viewModel: FeedViewModel

    @ObservedObject private var progressStore = ReadingProgressStore.shared
    @ObservedObject private var savedStore    = SavedPapersStore.shared
    @ObservedObject private var recentStore   = RecentlyViewedStore.shared

    @AppStorage("profile.dailyGoal")            private var dailyGoal: Int = 3
    @AppStorage("profile.displayNameOverride")  private var displayNameOverride: String = ""
    @AppStorage("profile.subscriptionTier")      private var subscriptionTier: String = "early_access"
    @AppStorage("profile.notificationsEnabled") private var notificationsEnabled: Bool = true

    @State private var showEditName        = false
    @State private var showGoalSheet       = false
    @State private var showSettings        = false
    @State private var showSignOutConfirm  = false
    @State private var showClearDataConfirm = false
    @State private var showDeleteConfirm    = false

    @State private var shelfTrashTrayArmedForDismiss = false
    @State private var shelfTrashTrayDismissNonce = 0

    // MARK: Derived

    private var displayName: String {
        let override = displayNameOverride.trimmingCharacters(in: .whitespacesAndNewlines)
        if !override.isEmpty { return override }
        if let email = session.user.email, !email.isEmpty {
            return String(email.split(separator: "@").first ?? Substring(email))
        }
        return "Reader"
    }

    // MARK: Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {

                identityHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 22)

                goalCard
                    .padding(.horizontal, 20)

                libraryHeader
                libraryGated

                recentlyViewedStrip

                Spacer(minLength: 40)
            }
            .padding(.bottom, 40)
        }
        .onPreferenceChange(ShelfTrashTapAwayArmedKey.self) { shelfTrashTrayArmedForDismiss = $0 }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showEditName) {
            EditDisplayNameSheet(name: $displayNameOverride)
        }
        .sheet(isPresented: $showGoalSheet) {
            DailyGoalSheet(goal: $dailyGoal)
        }
    }

    private func dismissShelfTrashIfAwayArmed() {
        guard shelfTrashTrayArmedForDismiss else { return }
        shelfTrashTrayDismissNonce += 1
    }

    // MARK: - Daily goal card

    private var goalCard: some View {
        let read = progressStore.papersReadToday()
        let goal = max(1, dailyGoal)
        let pct  = min(Double(read) / Double(goal), 1.0)
        let hit  = read >= goal

        return Button { showGoalSheet = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(borderColor, lineWidth: 4)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: pct)
                        .stroke(hit ? progressGreen : tealAccent,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 56, height: 56)
                        .animation(.snappy, value: pct)
                    Text("\(read)/\(goal)")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY'S GOAL")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(mutedText)
                    Text(goalHeadline(read: read, goal: goal))
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(inkColor)
                    Text(goalSubcopy(read: read, goal: goal))
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundStyle(mutedText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mutedText.opacity(0.7))
            }
            .padding(14)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func goalHeadline(read: Int, goal: Int) -> String {
        if read == 0 { return "Begin today's reading" }
        if read >= goal { return "Goal hit. Streak safe." }
        let left = goal - read
        return left == 1 ? "1 more to lock in today" : "\(left) more to lock in today"
    }

    private func goalSubcopy(read: Int, goal: Int) -> String {
        let streak = progressStore.currentStreak()
        if streak == 0 { return "Tap to set your daily target" }
        return streak == 1 ? "1 day streak" : "\(streak) day streak"
    }

    // MARK: - Recently viewed strip

    @ViewBuilder
    private var recentlyViewedStrip: some View {
        let recents = recentDecks
        if !recents.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(amberAccent).frame(width: 4, height: 4)
                    Text("RECENTLY OPENED")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(amberAccent)
                }
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissShelfTrashIfAwayArmed()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recents.prefix(8), id: \.deck.id) { item in
                            NavigationLink(destination: DeckDestination(deck: item.deck)) {
                                recentChip(deck: item.deck, openedAt: item.openedAt)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 4)
        }
    }

    private var recentDecks: [(deck: CardDeck, openedAt: Date)] {
        recentStore.entries.compactMap { entry -> (CardDeck, Date)? in
            if let d = viewModel.decks.first(where: { $0.paperId == entry.paperId }) {
                return (d, entry.openedAt)
            }
            if let loop = DailyLoopContent.byPaperId(entry.paperId) {
                return (CardDeck.fromLoop(paperId: entry.paperId, content: loop), entry.openedAt)
            }
            return nil
        }
    }

    /// Terse relative time since a paper was last opened, e.g. "3 hours ago",
    /// "Yesterday", "2 days ago" — shown on each recently-opened chip.
    private func relativeVisit(_ date: Date) -> String {
        let s = Date().timeIntervalSince(date)
        if s < 60 { return "Just now" }
        let m = Int(s / 60)
        if m < 60 { return m == 1 ? "1 minute ago" : "\(m) minutes ago" }
        let h = Int(s / 3600)
        if h < 24 { return h == 1 ? "1 hour ago" : "\(h) hours ago" }
        let d = Int(s / 86400)
        if d == 1 { return "Yesterday" }
        if d < 7 { return "\(d) days ago" }
        let w = d / 7
        return w == 1 ? "1 week ago" : "\(w) weeks ago"
    }

    private func recentChip(deck: CardDeck, openedAt: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(deck.title ?? "Untitled")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(inkColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(width: 140, alignment: .leading)
            // Re-ticks every 60s so the relative time stays accurate while
            // the profile is on screen, instead of freezing at render time.
            TimelineView(.periodic(from: openedAt, by: 60)) { _ in
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 8, weight: .semibold))
                    Text(relativeVisit(openedAt))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(mutedText)
            }
        }
        .padding(12)
        .frame(width: 164, height: 80, alignment: .topLeading)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }


    // MARK: Library (moved from Home)
    //
    // Editorial "From your shelf" header + bookshelf strip. Sits beneath
    // the identity row so the profile centers on saved reading, while the
    // home surface stays focused on the swipeable daily-lesson deck.

    private var libraryDecks: [CardDeck] {
        savedStore.savedIds
            .compactMap { id -> CardDeck? in
                if let deck = viewModel.decks.first(where: { $0.paperId == id }) {
                    return deck
                }
                if let loop = DailyLoopContent.byPaperId(id) {
                    return CardDeck.fromLoop(paperId: id, content: loop)
                }
                return nil
            }
            .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    @ViewBuilder
    private var libraryGated: some View {
        if libraryDecks.isEmpty {
            librarySavedEmpty
        } else {
            BookshelfView(decks: libraryDecks, trayDismissNonce: $shelfTrashTrayDismissNonce)
        }
    }

    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(tealAccent).frame(width: 4, height: 4)
                Text("FROM YOUR SHELF")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(tealAccent)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Library")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                Spacer()
                if !libraryDecks.isEmpty {
                    Text("\(libraryDecks.count)".uppercased())
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(tealAccent)
                }
            }
            Text(libraryHeaderSubtitle)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(mutedText)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissShelfTrashIfAwayArmed()
        }
    }

    private var libraryHeaderSubtitle: String {
        let n = libraryDecks.count
        if n == 0 { return "Nothing saved yet. Bookmark a paper to start your shelf." }
        return n == 1 ? "1 paper saved · tap to revisit" : "\(n) papers saved · tap to revisit"
    }

    private var librarySavedEmpty: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(borderColor, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .frame(width: 72, height: 72)
                Image(systemName: "bookmark")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(mutedText.opacity(0.7))
            }
            Text("Your shelf is empty")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundStyle(inkColor)
            Text("Tap the bookmark on any paper to keep it here.")
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
    }

    // MARK: 1. Identity header

    private var identityHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            avatarCircle
                .onTapGesture { showEditName = true }

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineLimit(1)
                tierBadge
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tealAccent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tealLight))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var avatarCircle: some View {
        let initial = String(displayName.prefix(1)).uppercased()
        return ZStack {
            Circle()
                .fill(tealLight)
            Circle()
                .stroke(tealAccent.opacity(0.25), lineWidth: 1)
            Text(initial)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(tealAccent)
        }
        .frame(width: 52, height: 52)
        .accessibilityLabel("Edit display name")
    }

    private var tierBadge: some View {
        let info = tierInfo
        return HStack(spacing: 5) {
            if let icon = info.icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(info.label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
        }
        .foregroundStyle(info.fg)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(info.bg))
        .overlay(Capsule().stroke(info.fg.opacity(0.18), lineWidth: 1))
    }

    private var tierInfo: (label: String, icon: String?, fg: Color, bg: Color) {
        switch subscriptionTier.lowercased() {
        case "pro":
            return ("Pro", "crown.fill", Color(hex: "8a5a18"), Color(hex: "fdf0d6"))
        case "premium":
            return ("Premium", "sparkles", tealAccent, tealLight)
        default:
            return ("Early Access", nil, Color(hex: "8a5a18"), Color(hex: "fdf0d6"))
        }
    }

    // MARK: 8. Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Preferences", trailing: nil)
            VStack(spacing: 0) {
                prefTapRow(label: "Daily goal",
                           value: "\(dailyGoal) \(dailyGoal == 1 ? "paper" : "papers")",
                           action: { showGoalSheet = true })
                rowDivider
                prefTapRow(label: "Display name",
                           value: displayName,
                           action: { showEditName = true })
                rowDivider
                prefToggleRow(label: "Notifications", isOn: $notificationsEnabled)
                rowDivider
                prefTapRow(label: "Replay onboarding",
                           value: "Show",
                           action: {
                               UserDefaults.standard.set(false, forKey: "onboarding.completed")
                               showSettings = false
                           })
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private var rowDivider: some View {
        Rectangle().fill(borderColor).frame(height: 1).padding(.leading, 16)
    }

    private func prefTapRow(label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(mutedText)
                Spacer()
                Text(value)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(inkColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mutedText.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func prefToggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(mutedText)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(tealAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: 9. Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Account", trailing: nil)
            VStack(spacing: 0) {
                accountRow(label: "Email", value: session.user.email ?? "Hidden by Apple")
                rowDivider
                accountRow(label: "Auth", value: "Apple Sign In")
                rowDivider
                accountRow(label: "Version", value: appVersion)
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private func accountRow(label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(mutedText)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(inkColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: 10. Danger zone

    private var dangerZone: some View {
        VStack(spacing: 10) {
            Button { showClearDataConfirm = true } label: {
                Text("Clear local data")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(mutedText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Button { showSignOutConfirm = true } label: {
                Text("Sign out")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            Button { showDeleteConfirm = true } label: {
                Text("Delete account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.9))
                    )
            }
            .buttonStyle(.plain)

            Text("Deleting your account permanently removes your profile and reading history. This cannot be undone.")
                .font(.system(size: 11))
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func clearLocalData() {
        progressStore.reset()
        savedStore.reset()
        recentStore.reset()
    }

    // MARK: Settings sheet

    private var settingsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    preferencesSection
                    accountSection
                    dangerZone
                    Spacer(minLength: 24)
                }
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .background(paperBg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                        .foregroundStyle(tealAccent)
                }
            }
        }
        .sheet(isPresented: $showEditName) {
            EditDisplayNameSheet(name: $displayNameOverride)
        }
        .sheet(isPresented: $showGoalSheet) {
            DailyGoalSheet(goal: $dailyGoal)
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) { Task { await auth.signOut() } }
        } message: {
            Text("Your saved papers and progress stay on this device.")
        }
        .alert("Clear local data?", isPresented: $showClearDataConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearLocalData() }
        } message: {
            Text("Removes reading progress, streaks and saved papers from this device. Cannot be undone.")
        }
        .alert("Delete account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete account", role: .destructive) {
                Task { await auth.deleteAccount() }
            }
        } message: {
            Text("This permanently deletes your account, profile and reading history. This cannot be undone.")
        }
    }

    // MARK: Shared bits

    private func sectionHeader(_ title: String, trailing: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(inkColor)
            Spacer()
            if let trailing = trailing {
                Text(trailing.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(mutedText)
            }
        }
        .padding(.horizontal, 20)
    }

}

// MARK: - EditDisplayNameSheet

private struct EditDisplayNameSheet: View {
    @Binding var name: String
    @State private var draft: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Text("Display name")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                Text("How you'll appear in Aprecis. Leave blank to use your email handle.")
                    .font(.system(size: 13))
                    .foregroundStyle(mutedText)

                TextField("e.g. Justin", text: $draft)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focused)
                    .font(.system(size: 16, design: .serif))
                    .padding(14)
                    .background(cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(inkColor)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(tealAccent)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 14, weight: .semibold))

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            draft = name
            focused = true
        }
        .presentationDetents([.height(320)])
    }
}

// MARK: - DailyGoalSheet

private struct DailyGoalSheet: View {
    @Binding var goal: Int
    @State private var draft: Int = 3
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 22) {
                Text("Daily goal")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                Text("Papers to read each day. Streak counts any day you hit at least one.")
                    .font(.system(size: 13))
                    .foregroundStyle(mutedText)

                HStack(spacing: 18) {
                    stepperButton(symbol: "minus", enabled: draft > 1) {
                        if draft > 1 { draft -= 1 }
                    }

                    VStack(spacing: 4) {
                        Text("\(draft)")
                            .font(.system(size: 56, weight: .regular, design: .serif))
                            .foregroundStyle(tealAccent)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: draft)
                        Text(draft == 1 ? "PAPER / DAY" : "PAPERS / DAY")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(mutedText)
                    }
                    .frame(maxWidth: .infinity)

                    stepperButton(symbol: "plus", enabled: draft < 20) {
                        if draft < 20 { draft += 1 }
                    }
                }
                .padding(.vertical, 6)

                Button {
                    goal = draft
                    dismiss()
                } label: {
                    Text("Save goal")
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(tealAccent)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(24)
        }
        .onAppear { draft = max(1, goal) }
        .presentationDetents([.height(360)])
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 46, height: 46)
                .foregroundStyle(enabled ? inkColor : mutedText.opacity(0.5))
                .background(
                    Circle().stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - SavedPapersListView (push destination from Library "View all")

struct SavedPapersListView: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject private var savedStore = SavedPapersStore.shared
    @Environment(\.dismiss) private var dismiss

    private var saved: [CardDeck] {
        savedStore.savedIds.compactMap { id -> CardDeck? in
            if let d = viewModel.decks.first(where: { $0.paperId == id }) { return d }
            if let loop = DailyLoopContent.byPaperId(id) {
                return CardDeck.fromLoop(paperId: id, content: loop)
            }
            return nil
        }
        .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            paperBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIBRARY")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(mutedText)
                            Text("Saved papers")
                                .font(.system(size: 28, weight: .regular, design: .serif))
                                .foregroundStyle(inkColor)
                        }
                        Spacer()
                        Text("\(saved.count)".uppercased())
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(tealAccent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                    if saved.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 28))
                                .foregroundStyle(mutedText.opacity(0.7))
                            Text("Empty library")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(inkColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 56)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(saved.enumerated()), id: \.element.id) { idx, deck in
                                NavigationLink(destination: DeckDestination(deck: deck)) {
                                    TrendingRowView(deck: deck, slot: idx)
                                }
                                .buttonStyle(.plain)
                                if idx < saved.count - 1 {
                                    Rectangle().fill(borderColor).frame(height: 1).padding(.leading, 16)
                                }
                            }
                        }
                        .background(cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ConfirmationView

private struct ConfirmationView: View {
    @EnvironmentObject var auth: AuthViewModel
    let email: String

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(tealLight).frame(width: 72, height: 72)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(tealAccent)
            }
            Text("Check your email")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(inkColor)
            Text("We sent a confirmation link to\n**\(email)**\n\nClick it to activate your account.")
                .font(.system(size: 14))
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                auth.state = .loggedOut
                auth.error = nil
            } label: {
                Label("Back to Sign In", systemImage: "arrow.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tealAccent)
            }
            .padding(.top, 8)
        }
        .padding(40)
    }
}
