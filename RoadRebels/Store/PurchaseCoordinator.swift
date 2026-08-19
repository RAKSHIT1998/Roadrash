import StoreKit

/// Applies gameplay effects for a completed purchase (credits, free bike
/// unlock) — the bridge between StoreService (pure StoreKit mechanics) and
/// CareerState/GarageState, mirroring ProgressionCoordinator's role for
/// Game Center.
@MainActor
final class PurchaseCoordinator {
    let storeService: StoreService
    let careerState: CareerState
    let garageState: GarageState

    init(storeService: StoreService, careerState: CareerState, garageState: GarageState) {
        self.storeService = storeService
        self.careerState = careerState
        self.garageState = garageState
    }

    @discardableResult
    func purchase(_ product: Product) async -> PurchaseOutcome {
        AnalyticsService.shared.log(.purchaseStarted(productID: product.id))
        let outcome = await storeService.purchase(product)
        switch outcome {
        case .success(let productID):
            applyEffect(for: productID)
            AnalyticsService.shared.log(.purchaseCompleted(productID: productID))
        case .failed:
            AnalyticsService.shared.log(.purchaseFailed(productID: product.id))
        case .cancelled, .pending:
            break
        }
        return outcome
    }

    /// Re-applies one-time entitlement effects that might not have landed
    /// yet (e.g. Pro's free bike, if it was purchased on another device).
    func syncEntitlements() {
        if storeService.purchasedNonConsumables.contains(StoreProductID.pro.rawValue) {
            applyProEffect()
        }
    }

    private func applyEffect(for productID: String) {
        guard let id = StoreProductID(rawValue: productID) else { return }
        if id.creditGrant > 0 {
            careerState.grantCredits(id.creditGrant)
        }
        if id == .pro {
            applyProEffect()
        }
    }

    private func applyProEffect() {
        garageState.grantBikeFree(BikeCatalog.model(for: "phantomr"))
    }
}
