import Foundation

/// Bike ownership + upgrade progression, persisted via SaveManager. Spending
/// credits goes through the passed-in CareerState so there is exactly one
/// place that owns the credits balance.
@MainActor
final class GarageState: ObservableObject {
    @Published private(set) var ownedBikeIDs: Set<String>
    @Published private(set) var selectedBikeID: String
    @Published private(set) var upgradeLevels: [String: [String: Int]]

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let data = saveManager.loadGarage()
        self.ownedBikeIDs = data.ownedBikeIDs
        self.selectedBikeID = data.selectedBikeID
        self.upgradeLevels = data.upgradeLevels
    }

    var selectedBike: BikeModel {
        BikeCatalog.model(for: selectedBikeID)
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
        return true
    }

    private func persist() {
        saveManager.saveGarage(GarageSaveData(
            ownedBikeIDs: ownedBikeIDs,
            selectedBikeID: selectedBikeID,
            upgradeLevels: upgradeLevels
        ))
    }
}
