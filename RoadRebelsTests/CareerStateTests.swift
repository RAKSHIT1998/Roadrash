import XCTest
@testable import RoadRebels

@MainActor
final class CareerStateTests: XCTestCase {
    private func makeIsolatedState() -> CareerState {
        let suiteName = "CareerStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return CareerState(saveManager: SaveManager(defaults: defaults))
    }

    func testFirstRegionUnlockedByDefault() {
        let state = makeIsolatedState()
        let firstRegion = CareerContent.regions[0]
        XCTAssertTrue(state.isRegionUnlocked(firstRegion))
        XCTAssertTrue(state.isRaceUnlocked(firstRegion.races[0], in: firstRegion))
        XCTAssertFalse(state.isRaceUnlocked(firstRegion.races[1], in: firstRegion))
    }

    func testSecondRegionLockedUntilFirstRegionBossCompleted() {
        let state = makeIsolatedState()
        let first = CareerContent.regions[0]
        let second = CareerContent.regions[1]
        XCTAssertFalse(state.isRegionUnlocked(second))

        for race in first.races {
            state.completeRace(id: race.id, reward: race.creditReward)
        }
        XCTAssertTrue(state.isRegionUnlocked(second))
        XCTAssertTrue(state.isRaceUnlocked(second.races[0], in: second))
    }

    func testCompletingRaceAwardsCreditsOnce() {
        let state = makeIsolatedState()
        let race = CareerContent.regions[0].races[0]
        state.completeRace(id: race.id, reward: 100)
        XCTAssertEqual(state.credits, 100)
        state.completeRace(id: race.id, reward: 100) // duplicate should not double-award
        XCTAssertEqual(state.credits, 100)
    }

    func testProgressPersistsAcrossInstancesWithSameDefaults() {
        let suiteName = "CareerStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let manager = SaveManager(defaults: defaults)

        let first = CareerState(saveManager: manager)
        let race = CareerContent.regions[0].races[0]
        first.completeRace(id: race.id, reward: 60)

        let second = CareerState(saveManager: manager)
        XCTAssertTrue(second.isRaceCompleted(race))
        XCTAssertEqual(second.credits, 60)
    }
}
