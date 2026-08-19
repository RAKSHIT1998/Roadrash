import XCTest
@testable import RoadRebels

final class RoadSplineExtensionTests: XCTestCase {
    func testAppendRandomSegmentGrowsTotalLength() {
        let spline = RoadSpline.generate(totalLength: 500)
        let before = spline.totalLength
        let appended = spline.appendRandomSegment(minLength: 200, maxLength: 200)
        XCTAssertEqual(spline.totalLength, before + 200, accuracy: 0.01)
        XCTAssertEqual(appended.startDistance, before, accuracy: 0.01)
    }

    func testAppendedSegmentContinuesSeamlessly() {
        let spline = RoadSpline.generate(totalLength: 500)
        let joinDistance = spline.totalLength
        let endBefore = spline.transform(atDistance: joinDistance)
        spline.appendRandomSegment(minLength: 150, maxLength: 150)
        let startOfNew = spline.transform(atDistance: joinDistance)
        // The new segment should start exactly where the old one ended.
        XCTAssertEqual(startOfNew.position.x, endBefore.position.x, accuracy: 0.01)
        XCTAssertEqual(startOfNew.position.z, endBefore.position.z, accuracy: 0.01)
    }
}

@MainActor
final class EndlessControllerSmokeTests: XCTestCase {
    func testEndlessRunsAndExtendsRoadWithoutCrashing() {
        let gameState = GameState()
        let input = BikeInputController()
        let controller = EndlessController(input: input, gameState: gameState)
        controller.start()

        let dt: Float = 1.0 / 60.0
        for frame in 0..<(60 * 30) { // 30 simulated seconds
            input.updateSteer(fromDragTranslationX: CGFloat(sin(Double(frame) * 0.03)) * 120, screenWidth: 900)
            input.setNitroHeld(frame % 150 < 30)
            controller.update(dt: dt)

            XCTAssertGreaterThanOrEqual(gameState.playerHealth, 0)
            XCTAssertGreaterThanOrEqual(gameState.endlessDistance, 0)

            if case .endlessFinished = gameState.screen { break }
        }
        // Either it ran the full duration or ended cleanly via a wreck — both are valid outcomes.
        XCTAssertGreaterThan(gameState.endlessDistance, 0)
    }
}
