import XCTest
@testable import RoadRebels

/// Drives the real RaceController (real RealityKit entities, particles,
/// haptics/audio no-ops) through thousands of frames with varied input to
/// catch runtime crashes that a plain compile can't — e.g. bad RealityKit
/// API usage that only misbehaves once entities/components are live.
@MainActor
final class RaceControllerSmokeTests: XCTestCase {
    func testFullRaceRunsWithoutCrashing() {
        let gameState = GameState()
        let input = BikeInputController()
        let controller = RaceController(input: input, gameState: gameState)
        controller.start()

        let dt: Float = 1.0 / 60.0
        var frame = 0
        let maxFrames = 60 * 90 // 90 simulated seconds, generous margin over race distance

        while frame < maxFrames {
            if frame % 90 == 0 { input.requestAttack() }
            input.setNitroHeld(frame % 200 < 40)
            input.setBraking(frame % 500 < 10)
            input.updateSteer(fromDragTranslationX: CGFloat(sin(Double(frame) * 0.02)) * 80, screenWidth: 900)

            controller.update(dt: dt)

            XCTAssertGreaterThanOrEqual(gameState.playerHealth, 0)
            XCTAssertLessThanOrEqual(gameState.playerHealth, GameConstants.riderMaxHealth)
            XCTAssertGreaterThanOrEqual(gameState.nitroMeter, 0)
            XCTAssertLessThanOrEqual(gameState.nitroMeter, 1)

            if case .raceFinished = gameState.screen { break }
            frame += 1
        }

        guard case .raceFinished(let result) = gameState.screen else {
            XCTFail("Race did not finish within \(maxFrames) frames")
            return
        }
        XCTAssertGreaterThan(result.elapsedTime, 0)
    }
}
