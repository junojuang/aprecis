import Foundation
import SwiftUI

/// A shared observable store that tracks reading progress for papers.
@MainActor
final class ReadingProgressStore: ObservableObject {
    /// Singleton instance of the store.
    static let shared = ReadingProgressStore()

    /// The dictionary mapping paper IDs to progress values between 0.0 and 1.0.
    @Published private(set) var progressByPaperId: [String: Double]

    /// Paper IDs marked complete today, keyed by ISO date string (YYYY-MM-DD).
    /// Only the current day's set is meaningful; older keys are pruned on read.
    @Published private(set) var dailyCompletions: [String: Set<String>]

    /// Last-read raw card index per paper. Mirrors the fraction in
    /// `progressByPaperId` but avoids the rounding loss that happens when
    /// the deck's card count changes (canon vs gated, etc.). Read this
    /// when restoring reading position; read the fraction for progress
    /// rings and other percentage UI.
    @Published private(set) var lastCardIndexByPaperId: [String: Int]

    private let userDefaultsKey       = "readingProgress.v1"
    private let dailyCompletionsKey   = "dailyCompletions.v1"
    private let lastCardIndexKey      = "readingProgress.lastCardIndex.v1"

    // Server sync for the per-user lifetime papers-read counter.
    // `accessToken`/`syncUserId` are set by AuthViewModel on sign-in.
    // `reportedReads` is the set of paper IDs already counted on the server
    // for the current user, so a paper increments `profiles.papers_read` at
    // most once, ever (idempotent across re-reads, days, app launches).
    private var accessToken: String?
    private var syncUserId: String?
    private var reportedReads: Set<String> = []

    /// Initializes the store by loading saved progress from UserDefaults, or starting empty.
    private init() {
        if let saved = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Double] {
            var clampedProgress: [String: Double] = [:]
            for (key, value) in saved {
                clampedProgress[key] = min(max(value, 0.0), 1.0)
            }
            self.progressByPaperId = clampedProgress
        } else {
            self.progressByPaperId = [:]
        }

        if let saved = UserDefaults.standard.dictionary(forKey: dailyCompletionsKey) as? [String: [String]] {
            var rebuilt: [String: Set<String>] = [:]
            for (k, v) in saved { rebuilt[k] = Set(v) }
            self.dailyCompletions = rebuilt
        } else {
            self.dailyCompletions = [:]
        }

        if let saved = UserDefaults.standard.dictionary(forKey: lastCardIndexKey) as? [String: Int] {
            self.lastCardIndexByPaperId = saved
        } else {
            self.lastCardIndexByPaperId = [:]
        }
    }

    /// Returns the last-read card index for a paper, or `nil` if the
    /// reader has never advanced past the first card. Use this to resume
    /// reading exactly where they left off.
    ///
    /// Reads from per-paper UserDefaults keys first (the authoritative
    /// store), falling back to the in-memory dictionary for paper IDs
    /// written within this app session.
    func lastCardIndex(for paperId: String) -> Int? {
        let perPaperKey = Self.perPaperKey(paperId)
        if UserDefaults.standard.object(forKey: perPaperKey) != nil {
            let value = UserDefaults.standard.integer(forKey: perPaperKey)
            return value
        }
        return lastCardIndexByPaperId[paperId]
    }

    /// Records the reader's current card index. Persists to a per-paper
    /// UserDefaults key for resilience (one key per paper avoids the
    /// dictionary-cast issues seen across versions) and also updates the
    /// 0.0–1.0 progress fraction so existing progress rings keep working.
    func setLastCardIndex(_ index: Int, totalCards: Int, for paperId: String) {
        let clampedIndex = max(0, min(index, max(totalCards - 1, 0)))
        lastCardIndexByPaperId[paperId] = clampedIndex
        UserDefaults.standard.set(clampedIndex, forKey: Self.perPaperKey(paperId))
        // Mirror to the bulk dictionary too. Lets the legacy /reset path
        // wipe everything in one shot if it ever needs to.
        UserDefaults.standard.set(lastCardIndexByPaperId, forKey: lastCardIndexKey)

        guard totalCards > 1 else { return }
        let fraction = Double(clampedIndex) / Double(totalCards - 1)
        setProgress(fraction, for: paperId)
    }

    private static func perPaperKey(_ paperId: String) -> String {
        "readingProgress.lastCard.v1.\(paperId)"
    }

    /// Returns the reading progress for the given paper ID, or 0.0 if none exists.
    /// - Parameter paperId: The unique identifier of the paper.
    func progress(for paperId: String) -> Double {
        progressByPaperId[paperId] ?? 0.0
    }

    /// Sets the reading progress for the given paper ID, clamping the value between 0.0 and 1.0.
    /// Persists the updated progress.
    /// - Parameters:
    ///   - value: The progress value to set, between 0.0 and 1.0.
    ///   - paperId: The unique identifier of the paper.
    func setProgress(_ value: Double, for paperId: String) {
        let clampedValue = min(max(value, 0.0), 1.0)
        progressByPaperId[paperId] = clampedValue
        persist()
    }

    /// Marks the reading progress for the given paper ID as complete (1.0).
    /// Persists the updated progress.
    /// - Parameter paperId: The unique identifier of the paper.
    func markComplete(paperId: String) {
        progressByPaperId[paperId] = 1.0
        persist()
    }

    /// Marks paperId as completed today and returns the running count of distinct
    /// papers finished today (including this one). Idempotent: re-marking the same
    /// paper on the same day does not bump the count.
    @discardableResult
    func markCompletedToday(paperId: String) -> Int {
        let key = todayKey()
        var set = dailyCompletions[key] ?? []
        set.insert(paperId)
        dailyCompletions[key] = set
        persistDaily()
        reportLifetimeRead(paperId: paperId)
        return set.count
    }

    /// Wires the signed-in user's credentials so finished papers increment the
    /// server-side `profiles.papers_read` counter. Called by AuthViewModel
    /// when auth state changes; pass nil on sign-out. Loads the set of papers
    /// already reported for this user so the counter is never double-bumped.
    func setAuth(accessToken: String?, userId: String?) {
        self.accessToken = accessToken
        self.syncUserId  = userId
        if let userId {
            reportedReads = Set(UserDefaults.standard.array(forKey: reportedKey(userId)) as? [String] ?? [])
        } else {
            reportedReads = []
        }
    }

    /// Reports a finished paper to the server exactly once per user. No-op for
    /// guests (no token) or papers already counted. On failure the paper is
    /// un-marked so a later completion retries it.
    private func reportLifetimeRead(paperId: String) {
        guard let token = accessToken,
              let userId = syncUserId,
              !reportedReads.contains(paperId) else { return }
        reportedReads.insert(paperId)
        UserDefaults.standard.set(Array(reportedReads), forKey: reportedKey(userId))
        Task {
            do {
                _ = try await ProfileService.shared.incrementPapersRead(accessToken: token)
            } catch {
                reportedReads.remove(paperId)
                UserDefaults.standard.set(Array(reportedReads), forKey: reportedKey(userId))
            }
        }
    }

    private func reportedKey(_ userId: String) -> String {
        "reportedReads.v1.\(userId)"
    }

    /// Number of distinct papers completed today.
    func papersReadToday() -> Int {
        dailyCompletions[todayKey()]?.count ?? 0
    }

    /// Distinct papers marked fully read across all time.
    func totalCompleted() -> Int {
        progressByPaperId.values.filter { $0 >= 0.98 }.count
    }

    /// Consecutive days ending today with at least one completion. 0 if today empty.
    func currentStreak() -> Int {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let cal = Calendar(identifier: .iso8601)
        var day = Date()
        var streak = 0
        while true {
            let key = f.string(from: day)
            if let s = dailyCompletions[key], !s.isEmpty {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = prev
            } else {
                break
            }
        }
        return streak
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Wipes all local reading progress, daily completions, resume positions
    /// and the lifetime-read report cache. Used by the profile "Clear local
    /// data" action. Must clear every backing key, otherwise per-paper resume
    /// positions survive and reading appears to come back.
    func reset() {
        // Per-paper resume keys are written individually, so remove each one.
        let perPaperPrefix = "readingProgress.lastCard.v1."
        for key in UserDefaults.standard.dictionaryRepresentation().keys
        where key.hasPrefix(perPaperPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
        if let userId = syncUserId {
            UserDefaults.standard.removeObject(forKey: reportedKey(userId))
        }

        progressByPaperId = [:]
        dailyCompletions = [:]
        lastCardIndexByPaperId = [:]
        reportedReads = []

        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: dailyCompletionsKey)
        UserDefaults.standard.removeObject(forKey: lastCardIndexKey)
    }

    /// Persists the current progress dictionary to UserDefaults.
    private func persist() {
        UserDefaults.standard.set(progressByPaperId, forKey: userDefaultsKey)
    }

    private func persistDaily() {
        var encodable: [String: [String]] = [:]
        for (k, v) in dailyCompletions { encodable[k] = Array(v) }
        UserDefaults.standard.set(encodable, forKey: dailyCompletionsKey)
    }
}

// MARK: - SavedPapersStore
//
// Per-account bookmark store. Keys persist under the user id so a fresh login
// pulls that user's bookmarks, not the prior session's. Backend sync hook
// lives in `setUserId(_:)` for when /serve-cards/interaction gains a list
// endpoint; until then this is a local mirror.
@MainActor
final class SavedPapersStore: ObservableObject {
    static let shared = SavedPapersStore()

    @Published private(set) var savedIds: Set<String> = []
    private var userId: String? = nil

    private init() {
        savedIds = Set(UserDefaults.standard.array(forKey: key(for: nil)) as? [String] ?? [])
    }

    // Called by AuthViewModel when state flips. Loads saved set scoped to
    // that user, or the local guest set when signed out.
    func setUserId(_ id: String?) {
        self.userId = id
        if let raw = UserDefaults.standard.array(forKey: key(for: id)) as? [String] {
            savedIds = Set(raw)
        } else {
            savedIds = []
        }
    }

    func isSaved(_ paperId: String) -> Bool {
        savedIds.contains(paperId)
    }

    func toggle(_ paperId: String) {
        if savedIds.contains(paperId) {
            savedIds.remove(paperId)
        } else {
            savedIds.insert(paperId)
        }
        persist()
    }

    /// Toggles the bookmark. Saves persist locally under the guest scope;
    /// there is no account or save cap. Returns true once the set changed
    /// (always true here, kept for call-site compatibility).
    @discardableResult
    func toggleOrPromptSignIn(_ paperId: String) -> Bool {
        toggle(paperId)
        return true
    }

    /// Drop from the library bookmark set (Profile shelf). Safe if already absent.
    func remove(_ paperId: String) {
        guard savedIds.contains(paperId) else { return }
        savedIds.remove(paperId)
        persist()
    }

    /// Wipes the saved set for the current user. Used by the profile
    /// "Clear local data" action.
    func reset() {
        UserDefaults.standard.removeObject(forKey: key(for: userId))
        savedIds = []
    }

    private func key(for userId: String?) -> String {
        "savedPapers.v1.\(userId ?? "local")"
    }

    private func persist() {
        UserDefaults.standard.set(Array(savedIds), forKey: key(for: userId))
    }
}

// MARK: - RecentlyViewedStore
//
// Lightweight log of which papers the reader has opened, most recent first.
// Capped to keep the list useful (older entries fall off). Drives the
// "Recently viewed" section of the profile so the user can jump back into
// anything they glanced at, even if they never finished it.

struct RecentlyViewedEntry: Codable, Identifiable, Hashable {
    let paperId: String
    let openedAt: Date
    var id: String { paperId }
}

@MainActor
final class RecentlyViewedStore: ObservableObject {
    static let shared = RecentlyViewedStore()

    @Published private(set) var entries: [RecentlyViewedEntry] = []

    private let key = "recentlyViewed.v1"
    private let maxEntries = 30

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([RecentlyViewedEntry].self, from: data) {
            entries = decoded
        }
    }

    /// Push paperId to the front. Dedups so reopening a paper bumps it,
    /// not duplicates it. Trims the tail past `maxEntries`.
    func record(_ paperId: String) {
        guard !paperId.isEmpty else { return }
        var next = entries.filter { $0.paperId != paperId }
        next.insert(RecentlyViewedEntry(paperId: paperId, openedAt: Date()), at: 0)
        if next.count > maxEntries { next = Array(next.prefix(maxEntries)) }
        entries = next
        persist()
    }

    func reset() {
        entries = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
