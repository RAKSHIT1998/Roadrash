import StoreKit

enum PurchaseOutcome: Equatable {
    case success(productID: String)
    case cancelled
    case pending
    case failed
}

/// Thin StoreKit 2 wrapper: loads products, executes purchases, and tracks
/// which non-consumables the player currently owns by re-checking
/// `Transaction.currentEntitlements` (the source of truth, not a local
/// cache). Deliberately has zero knowledge of credits/bikes/career —
/// PurchaseCoordinator applies those effects so this stays a pure
/// "talk to the App Store" layer, matching the mega-spec's "StoreKit
/// integration is isolated" QA requirement (section 65).
@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedNonConsumables: Set<String> = []
    @Published private(set) var isLoadingProducts = false

    private init() {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                if transaction.productType == .nonConsumable, transaction.revocationDate == nil {
                    self?.purchasedNonConsumables.insert(transaction.productID)
                }
            }
        }
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        products = (try? await Product.products(for: StoreProductID.allCases.map(\.rawValue))) ?? []
    }

    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedNonConsumables = owned
    }

    @discardableResult
    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                if transaction.productType == .nonConsumable {
                    purchasedNonConsumables.insert(transaction.productID)
                }
                return .success(productID: transaction.productID)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }
}
