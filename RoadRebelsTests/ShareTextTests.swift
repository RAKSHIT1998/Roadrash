import XCTest
@testable import RoadRebels

final class ShareTextTests: XCTestCase {
    func testRaceResultShareIncludesPlaceAndTime() {
        let result = RaceResult(
            position: 1, totalRiders: 4, elapsedTime: 137.43, didWin: true,
            careerRaceID: nil, creditsEarned: 90,
            hadAnyCollision: false, tookAnyDamage: false, nearMisses: 5
        )
        let text = ShareText.raceResult(result)
        XCTAssertTrue(text.contains("ROAD REBELS"))
        XCTAssertTrue(text.contains("1ST PLACE"))
        XCTAssertTrue(text.contains("5 NEAR MISSES"))
    }

    func testBossRaceShareIncludesBossName() {
        let bossRace = CareerContent.regions[0].races.last! // isBossRace == true
        let result = RaceResult(
            position: 1, totalRiders: 3, elapsedTime: 90, didWin: true,
            careerRaceID: bossRace.id, creditsEarned: 200,
            hadAnyCollision: false, tookAnyDamage: false, nearMisses: 0
        )
        let text = ShareText.raceResult(result)
        XCTAssertTrue(text.contains("BOSS DEFEATED"))
    }

    func testEndlessResultShareIncludesScoreAndDistance() {
        let result = EndlessResult(distance: 842, nearMisses: 12, score: 1442)
        let text = ShareText.endlessResult(result)
        XCTAssertTrue(text.contains("1442"))
        XCTAssertTrue(text.contains("842m TRAVELED"))
    }
}
