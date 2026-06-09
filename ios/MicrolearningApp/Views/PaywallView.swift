import SwiftUI
import StoreKit

/// The single Aprecis Plus paywall. Editorial cream-and-teal styling, kept
/// in brand voice and typography. Presented from the settings row, the
/// locked-card upsell on long decks, and the library cap upsell.
struct PaywallView: View {

    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    /// Optional context line shown above the headline. Trigger surfaces pass
    /// a short, honest reason so the paywall feels like an answer to what
    /// the reader just did, not a generic upsell.
    var contextLine: String? = nil

    private let termsURL   = URL(string: "https://aprecis.app/terms")!
    private let privacyURL = URL(string: "https://aprecis.app/privacy")!

    var body: some View {
        SubscriptionStoreView(
            groupID: AprecisProduct.subscriptionGroupID,
            visibleRelationships: .all
        ) {
            marketingHeader
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.action)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .redeemCode)
        .storeButton(.visible, for: .cancellation)
        .subscriptionStorePolicyDestination(url: termsURL,   for: .termsOfService)
        .subscriptionStorePolicyDestination(url: privacyURL, for: .privacyPolicy)
        .containerBackground(paperBg.gradient, for: .subscriptionStore)
        .tint(tealAccent)
        .onInAppPurchaseCompletion { _, result in
            if case .success(let purchaseResult) = result,
               case .success(let verification) = purchaseResult,
               case .verified(let transaction) = verification {
                await transaction.finish()
                await store.refreshEntitlements()
                dismiss()
            }
        }
        .task { await store.bootstrap() }
    }

    private var marketingHeader: some View {
        VStack(spacing: 22) {

            if let contextLine {
                Text(contextLine.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            EditorialMark()
                .frame(width: 64, height: 64)

            VStack(spacing: 8) {
                Text("Aprecis Plus")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(tealAccent)

                Text("Every paper, every day.")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(inkColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text("Make Aprecis your daily research tool.")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 2)
            }

            VStack(spacing: 0) {
                benefitRow(
                    numeral: "01",
                    title: "Every paper, every day",
                    detail: "Unlimited feed. The frontier doesn't stop at three a day."
                )
                editorialDivider
                benefitRow(
                    numeral: "02",
                    title: "Walk the graph",
                    detail: "Builds-on, Led-to, Adjacent. Trace where every idea came from and where it went."
                )
                editorialDivider
                benefitRow(
                    numeral: "03",
                    title: "Carry your library",
                    detail: "Save anything. Sync across your devices. Find it in a tap."
                )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 28)
        .padding(.bottom, 12)
    }

    private func benefitRow(numeral: String, title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(numeral)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(tealAccent)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(inkColor)
                Text(detail)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    private var editorialDivider: some View {
        Rectangle()
            .fill(borderColor)
            .frame(height: 1)
            .padding(.leading, 38)
    }
}

/// Editorial mark used in the paywall hero. A serif open quote inside a
/// thin cream/teal seal. Matches the library-style brand language without
/// importing a paper-specific glyph.
private struct EditorialMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(tealLight)
                .overlay(
                    Circle().stroke(tealAccent.opacity(0.35), lineWidth: 1)
                )

            Circle()
                .stroke(tealAccent.opacity(0.18), lineWidth: 1)
                .padding(6)

            Text("A")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(tealAccent)
                .offset(y: 1)
        }
    }
}

#Preview {
    PaywallView(contextLine: "You've reached the free preview")
        .environmentObject(StoreService())
}
