import Foundation
import StoreKit

/// Aprecis Plus product identifiers. Must match the IDs configured in
/// App Store Connect and the local `Aprecis.storekit` test configuration.
enum AprecisProduct {
    static let monthly = "aprecis.app.plus.monthly"
    static let yearly  = "aprecis.app.plus.yearly"
    static let all: [String] = [monthly, yearly]

    /// Numeric subscription group ID. Matches `subscriptionGroups[0].id` in
    /// `Aprecis.storekit` and must match the group's identifier in
    /// App Store Connect when shipped. `SubscriptionStoreView(groupID:)`
    /// rejects the reference name and only loads on the numeric ID.
    static let subscriptionGroupID = "21500001"
}

/// Single source of truth for subscription entitlement.
///
/// Owns the StoreKit 2 `Transaction.updates` listener, the loaded `Product`
/// list, and the user's current entitlement state. Inject as an
/// `@EnvironmentObject` and read `isPlus` to gate paid features.
@MainActor
final class StoreService: ObservableObject {

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    /// Expiration date of the currently-active Plus subscription, if any.
    /// Used by the member sheet to show "Renews on …".
    @Published private(set) var plusRenewalDate: Date?
    /// Which product the active subscription is on. Lets the UI show
    /// "Monthly" vs "Yearly" without re-querying products.
    @Published private(set) var activeProductID: String?
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    var isPlus: Bool {
        !purchasedProductIDs.isEmpty
    }

    /// UserDefaults key used by non-SwiftUI stores (`SavedPapersStore`, etc.)
    /// to read the current entitlement without taking a hard dependency on
    /// `StoreService`. Mirrored on every refresh.
    static let isPlusDefaultsKey = "aprecis.plus.active"

    var monthlyProduct: Product? { products.first { $0.id == AprecisProduct.monthly } }
    var yearlyProduct:  Product? { products.first { $0.id == AprecisProduct.yearly  } }

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self?.refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    deinit { updatesTask?.cancel() }

    func bootstrap() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: AprecisProduct.all)
            products = loaded.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
        } catch {
            lastError = "Could not load products: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var entitled = Set<String>()
        var soonestRenewal: Date?
        var activeID: String?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil else { continue }
            if let expiration = transaction.expirationDate, expiration < Date() { continue }
            entitled.insert(transaction.productID)

            if AprecisProduct.all.contains(transaction.productID),
               let expiration = transaction.expirationDate {
                if soonestRenewal == nil || expiration < soonestRenewal! {
                    soonestRenewal = expiration
                    activeID = transaction.productID
                }
            }
        }
        purchasedProductIDs = entitled
        plusRenewalDate = soonestRenewal
        activeProductID = activeID
        UserDefaults.standard.set(!entitled.isEmpty, forKey: Self.isPlusDefaultsKey)
    }

    /// Human label for the active plan ("Monthly", "Yearly"), or nil if
    /// not subscribed. Used by the member sheet.
    var activePlanLabel: String? {
        switch activeProductID {
        case AprecisProduct.monthly: return "Monthly"
        case AprecisProduct.yearly:  return "Yearly"
        default: return nil
        }
    }

    /// Drives a one-shot purchase. Callers should present `PaywallView`
    /// for the full SubscriptionStoreView flow; this is a fallback used
    /// from custom CTAs.
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    lastError = "Purchase could not be verified."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }
}
