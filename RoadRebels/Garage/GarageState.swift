import Foundation

/// Bike ownership + upgrade progression, persisted via SaveManager. Spending
/// credits goes through the passed-in CareerState so there is exactly one
/// place that owns the credits balance.
@MainActor
final class GarageState: ObservableObject {
    @Published private(set) var ownedBikeIDs: Set<String>
    @Published private(set) var selectedBikeID: String
    @Published private(set) var upgradeLevels: [String: [String: Int]]
    @Published private(set) var ownedPaintIDs: Set<String>
    @Published private(set) var selectedPaintID: String
    @Published private(set) var ownedHelmetIDs: Set<String>
    @Published private(set) var selectedHelmetID: String

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let data = saveManager.loadGarage()
        self.ownedBikeIDs = data.ownedBikeIDs
        self.selectedBikeID = data.selectedBikeID
        self.upgradeLevels = data.upgradeLevels
        self.ownedPaintIDs = data.ownedPaintIDs
        self.selectedPaintID = data.selectedPaintID
        self.ownedHelmetIDs = data.ownedHelmetIDs
        self.selectedHelmetID = data.selectedHelmetID
    }

    var selectedBike: BikeModel {
        BikeCatalog.model(for: selectedBikeID)
    }

    /// What BikeEntity should actually render for the player right now.
    var appearance: BikeAppearance {
        BikeAppearance(
            paintColor: PaintCatalog.option(for: selectedPaintID).color,
            helmetColor: HelmetCatalog.option(for: selectedHelmetID).color
        )
    }

    func isOwned(_ bike: BikeModel) -> Bool {
        ownedBikeIDs.contains(bike.id)
    }

    func upgradeLevel(_ category: UpgradeCategory, for bikeID: String) -> Int {
        upgradeLevels[bikeID]?[category.rawValue] ?? 0
    }

    func upgradeCost(_ category: UpgradeCategory, for bikeID: String) -> Int {
        50 * (upgradeLevel(category, for: bikeID) + 1)
    }

    func tuning(for bikeID: String) -> BikeTuning {
        let bike = BikeCatalog.model(for: bikeID)
        var levels: [UpgradeCategory: Int] = [:]
        for category in UpgradeCategory.allCases {
            levels[category] = upgradeLevel(category, for: bikeID)
        }
        return BikeTuningCalculator.tuning(for: bike, upgradeLevels: levels)
    }

    func selectBike(_ bike: BikeModel) {
        guard isOwned(bike) else { return }
        selectedBikeID = bike.id
        persist()
    }

    @discardableResult
    func unlockBike(_ bike: BikeModel, careerState: CareerState) -> Bool {
        guard !isOwned(bike) else { return true }
        guard careerState.spendCredits(bike.unlockCost) else { return false }
        ownedBikeIDs.insert(bike.id)
        persist()
        AnalyticsService.shared.log(.bikeUnlocked(bikeID: bike.id))
        return true
    }

    /// Grants ownership with no credit cost, e.g. the Road Rebels Pro
    /// purchase unlocking a bike outright.
    func grantBikeFree(_ bike: BikeModel) {
        guard !isOwned(bike) else { return }
        ownedBikeIDs.insert(bike.id)
        persist()
    }

    @discardableResult
    func upgrade(_ category: UpgradeCategory, for bikeID: String, careerState: CareerState) -> Bool {
        guard upgradeLevel(category, for: bikeID) < BikeTuningCalculator.maxUpgradeLevel else { return false }
        let cost = upgradeCost(category, for: bikeID)
        guard careerState.spendCredits(cost) else { return false }
        var bikeUpgrades = upgradeLevels[bikeID] ?? [:]
        bikeUpgrades[category.rawValue] = upgradeLevel(category, for: bikeID) + 1
        upgradeLevels[bikeID] = bikeUpgrades
        persist()
        AnalyticsService.shared.log(.upgradePurchased(category: category.rawValue, bikeID: bikeID))
        return true
    }

    func isOwned(_ paint: PaintOption) -> Bool {
        ownedPaintIDs.contains(paint.id)
    }

    func selectPaint(_ paint: PaintOption) {
        guard isOwned(paint) else { return }
        selectedPaintID = paint.id
        persist()
    }

    @discardableResult
    func unlockPaint(_ paint: PaintOption, careerState: CareerState) -> Bool {
        guard !isOwned(paint) else { return true }
        guard careerState.spendCredits(paint.cost) else { return false }
        ownedPaintIDs.insert(paint.id)
        persist()
        return true
    }

    func isOwned(_ helmet: HelmetOption) -> Bool {
        ownedHelmetIDs.contains(helmet.id)
    }

    func selectHelmet(_ helmet: HelmetOption) {
        guard isOwned(helmet) else { return }
        selectedHelmetID = helmet.id
        persist()
    }

    @discardableResult
    func unlockHelmet(_ helmet: HelmetOption, careerState: CareerState) -> Bool {
        guard !isOwned(helmet) else { return true }
        guard careerState.spendCredits(helmet.cost) else { return false }
        ownedHelmetIDs.insert(helmet.id)
        persist()
        return true
    }

    private func persist() {
        saveManager.saveGarage(GarageSaveData(
            ownedBikeIDs: ownedBikeIDs,
            selectedBikeID: selectedBikeID,
            upgradeLevels: upgradeLevels,
            ownedPaintIDs: ownedPaintIDs,
            selectedPaintID: selectedPaintID,
            ownedHelmetIDs: ownedHelmetIDs,
            selectedHelmetID: selectedHelmetID
        ))
    }
}
