import XCTest
@testable import RoadRebels

final class TutorialStepSelectorTests: XCTestCase {
    func testShowsSteerTipImmediately() {
        let step = TutorialStepSelector.step(elapsedTime: 1, raceProgress: 0, nitroMeter: 0)
        XCTAssertEqual(step, .steer)
    }

    func testSteerTipExpiresIntoNoneBeforeAttackWindow() {
        let step = TutorialStepSelector.step(elapsedTime: 6, raceProgress: 0.05, nitroMeter: 0)
        XCTAssertEqual(step, .none)
    }

    func testAttackTipAppearsAtProgressThreshold() {
        let step = TutorialStepSelector.step(elapsedTime: 20, raceProgress: 0.2, nitroMeter: 0)
        XCTAssertEqual(step, .attack)
    }

    func testBrakeTipAppearsLaterThanAttack() {
        let step = TutorialStepSelector.step(elapsedTime: 40, raceProgress: 0.5, nitroMeter: 0)
        XCTAssertEqual(step, .brake)
    }

    func testNitroTipOverridesProgressBasedTipsWhenMeterFull() {
        let step = TutorialStepSelector.step(elapsedTime: 40, raceProgress: 0.5, nitroMeter: 1.0)
        XCTAssertEqual(step, .nitro)
    }

    func testFinishTipTakesPriorityNearTheEnd() {
        let step = TutorialStepSelector.step(elapsedTime: 60, raceProgress: 0.95, nitroMeter: 1.0)
        XCTAssertEqual(step, .finish)
    }
}

@MainActor
final class TutorialStateTests: XCTestCase {
    func testMarkCompletedPersists() {
        let defaults = UserDefaults(suiteName: "TutorialStateTests.\(UUID().uuidString)")!
        let manager = SaveManager(defaults: defaults)
        let first = TutorialState(saveManager: manager)
        XCTAssertFalse(first.hasCompletedTutorial)
        first.markCompleted()
        XCTAssertTrue(first.hasCompletedTutorial)

        let second = TutorialState(saveManager: manager)
        XCTAssertTrue(second.hasCompletedTutorial)
    }
}
