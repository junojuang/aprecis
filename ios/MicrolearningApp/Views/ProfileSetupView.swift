import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthViewModel

    @AppStorage("profile.dailyGoal")           private var dailyGoalStorage: Int = 3
    @AppStorage("profile.displayNameOverride") private var displayNameStorage: String = ""

    @State private var displayName: String = ""
    @State private var selectedTier: GoalTier = .steady
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var nameFocused: Bool

    enum GoalTier: String, CaseIterable, Identifiable {
        case light, steady, intense
        var id: String { rawValue }

        var label: String {
            switch self {
            case .light:   return "Light"
            case .steady:  return "Steady"
            case .intense: return "Intense"
            }
        }
        var papers: Int {
            switch self {
            case .light:   return 1
            case .steady:  return 3
            case .intense: return 7
            }
        }
        var subtitle: String {
            switch self {
            case .light:   return "One a day. Habit first."
            case .steady:  return "Three a day. The rhythm."
            case .intense: return "Seven a day. Obsessed."
            }
        }
        var glyph: String {
            switch self {
            case .light:   return "leaf.fill"
            case .steady:  return "flame.fill"
            case .intense: return "bolt.fill"
            }
        }
        static func from(papers: Int) -> GoalTier {
            switch papers {
            case ..<2:  return .light
            case 2...4: return .steady
            default:    return .intense
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 36) {
                header
                nameSection
                goalSection
                if let msg = errorMessage {
                    Text(msg)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                actionStack
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(paperBg.ignoresSafeArea())
        .onAppear {
            displayName  = displayNameStorage
            selectedTier = .from(papers: dailyGoalStorage)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Circle().fill(tealAccent).frame(width: 6, height: 6)
                Text("STEP 01 OF 01")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(tealAccent)
            }

            Text("Set the table.")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(inkColor)
                .multilineTextAlignment(.center)

            Text("Two small choices.\nThe feed reshapes around them.")
                .font(.system(size: 14))
                .foregroundStyle(mutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 6)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("01", title: "What should we call you?")

            ZStack(alignment: .leading) {
                if displayName.isEmpty {
                    Text("Your name, a handle, an alias")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(mutedText.opacity(0.6))
                        .allowsHitTesting(false)
                }
                TextField("", text: $displayName)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                    .tint(tealAccent)
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(nameFocused ? tealAccent : inkColor.opacity(0.18))
                    .frame(height: nameFocused ? 2 : 1)
                    .animation(.easeOut(duration: 0.18), value: nameFocused)
            }
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("02", title: "How much each day?")

            VStack(spacing: 12) {
                ForEach(GoalTier.allCases) { tier in
                    tierCard(tier)
                }
            }
        }
    }

    private func tierCard(_ tier: GoalTier) -> some View {
        let isSelected = selectedTier == tier

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) {
                selectedTier = tier
            }
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? tealAccent : tealLight)
                        .frame(width: 52, height: 52)
                    Image(systemName: tier.glyph)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : tealAccent)
                        .scaleEffect(isSelected ? 1.06 : 1.0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.label)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(inkColor)
                    Text(tier.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(mutedText)
                }

                Spacer()

                paperStack(count: tier.papers, highlighted: isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? inkColor : borderColor,
                            lineWidth: isSelected ? 1.6 : 1)
            )
            .shadow(color: isSelected ? inkColor.opacity(0.10) : .clear,
                    radius: 12, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.012 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func paperStack(count: Int, highlighted: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<min(count, 7), id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(highlighted ? inkColor : inkColor.opacity(0.18))
                    .frame(width: 4, height: 14 + CGFloat(idx % 3) * 3)
            }
        }
        .frame(width: 56, alignment: .trailing)
        .animation(.easeOut(duration: 0.22), value: highlighted)
    }

    // MARK: - Action stack

    private var actionStack: some View {
        VStack(spacing: 14) {
            Button(action: save) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(inkColor)
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView().tint(.white).scaleEffect(0.85)
                        }
                        Text(isSaving ? "Saving" : "Begin reading")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                        if !isSaving {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 56)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button {
                #if canImport(UIKit)
                UISelectionFeedbackGenerator().selectionChanged()
                #endif
                auth.markProfileSetupComplete()
            } label: {
                Text("Skip, set this up later")
                    .font(.system(size: 13))
                    .underline(true, color: mutedText.opacity(0.4))
                    .foregroundStyle(mutedText)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionLabel(_ index: String, title: String) -> some View {
        HStack(spacing: 10) {
            Text(index)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(tealAccent)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(tealLight)
                )
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(inkColor)
            Spacer(minLength: 0)
        }
    }

    private func save() {
        guard let session = auth.currentSession else {
            auth.markProfileSetupComplete()
            return
        }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = selectedTier.papers
        isSaving = true
        errorMessage = nil

        Task {
            do {
                _ = try await ProfileService.shared.updateProfile(
                    userId: session.user.id,
                    accessToken: session.accessToken,
                    displayName: trimmed.isEmpty ? nil : trimmed
                )
                displayNameStorage = trimmed
                dailyGoalStorage   = goal
                isSaving = false
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                auth.markProfileSetupComplete()
            } catch {
                isSaving = false
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
                withAnimation { errorMessage = "Could not save. \(error.localizedDescription)" }
            }
        }
    }
}
