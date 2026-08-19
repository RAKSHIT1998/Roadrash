import XCTest
@testable import RoadRebels

final class BikeTuningCalculatorTests: XCTestCase {
    func testDefaultBikeNoUpgradesMatchesBaseStats() {
        let bike = BikeCatalog.all[0] // Falcon 250, all multipliers 1.0
        let tuning = BikeTuningCalculator.tuning(for: bike, upgradeLevels: [:])
        XCTAssertEqual(tuning.speedMultiplier, 1.0, accuracy: 0.001)
        XCTAssertEqual(tuning.accelMultiplier, 1.0, accuracy: 0.001)
        XCTAssertEqual(tuning.maxHealthBonus, 0, accuracy: 0.001)
    }

    func testUpgradeLevelsIncreaseRelevantStatOnly() {
        let bike = BikeCatalog.all[0]
        let tuning = BikeTuningCalculator.tuning(for: bike, upgradeLevels: [.engine: 3])
        XCTAssertGreaterThan(tuning.accelMultiplier, 1.0)
        XCTAssertEqual(tuning.speedMultiplier, 1.0, accuracy: 0.001) // transmission untouched
        XCTAssertEqual(tuning.handlingMultiplier, 1.0, accuracy: 0.001)
    }

    func testArmorIncreasesHealthBonus() {
        let bike = BikeCatalog.all[0]
        let tuning = BikeTuningCalculator.tuning(for: bike, upgradeLevels: [.armor: 5])
        XCTAssertEqual(tuning.maxHealthBonus, 40, accuracy: 0.001) // 8 * 5
    }

    func testNitroDrainNeverGoesBelowFloor() {
        let bike = BikeCatalog.all[0]
        let tuning = BikeTuningCalculator.tuning(for: bike, upgradeLevels: [.nitro: 5])
        XCTAssertGreaterThanOrEqual(tuning.nitroDrainMultiplier, 0.5)
    }
}

@MainActor
final class GarageStateTests: XCTestCase {
    private func makeStates() -> (GarageState, CareerState) {
        let suiteName = "GarageStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let manager = SaveManager(defaults: defaults)
        return (GarageState(saveManager: manager), CareerState(saveManager: manager))
    }

    func testStarterBikeOwnedByDefault() {
        let (garage, _) = makeStates()
        XCTAssertTrue(garage.isOwned(BikeCatalog.all[0]))
        XCTAssertEqual(garage.selectedBikeID, BikeCatalog.all[0].id)
    }

    func testCannotUnlockBikeWithoutEnoughCredits() {
        let (garage, career) = makeStates()
        let expensiveBike = BikeCatalog.all.max(by: { $0.unlockCost < $1.unlockCost })!
        XCTAssertFalse(garage.unlockBike(expensiveBike, careerState: career))
        XCTAssertFalse(garage.isOwned(expensiveBike))
    }

    func testUnlockingBikeSpendsCredits() {
        let (garage, career) = makeStates()
        let bike = BikeCatalog.all[1]
        career.completeRace(id: "seed", reward: bike.unlockCost)
        XCTAssertTrue(garage.unlockBike(bike, careerState: career))
        XCTAssertTrue(garage.isOwned(bike))
        XCTAssertEqual(career.credits, 0)
    }

    func testUpgradeCannotExceedMaxLevel() {
        let (garage, career) = makeStates()
        career.completeRace(id: "seed", reward: 10_000)
        let bikeID = BikeCatalog.all[0].id
        for _ in 0..<10 {
            garage.upgrade(.engine, for: bikeID, careerState: career)
        }
        XCTAssertEqual(garage.upgradeLevel(.engine, for: bikeID), BikeTuningCalculator.maxUpgradeLevel)
    }
}
