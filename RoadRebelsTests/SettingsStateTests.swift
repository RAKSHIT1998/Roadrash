import XCTest
@testable import RoadRebels

@MainActor
final class SettingsStateTests: XCTestCase {
    func testDefaultsMatchSaveDataDefaults() {
        let defaults = UserDefaults(suiteName: "SettingsStateTests.\(UUID().uuidString)")!
        let settings = SettingsState(saveManager: SaveManager(defaults: defaults))
        XCTAssertEqual(settings.musicVolume, 0.8, accuracy: 0.001)
        XCTAssertEqual(settings.sfxVolume, 1.0, accuracy: 0.001)
        XCTAssertTrue(settings.hapticsEnabled)
        XCTAssertFalse(settings.reducedMotionEnabled)
    }

    func testChangesPersistAcrossInstances() {
        let defaults = UserDefaults(suiteName: "SettingsStateTests.\(UUID().uuidString)")!
        let manager = SaveManager(defaults: defaults)

        let first = SettingsState(saveManager: manager)
        first.musicVolume = 0.3
        first.hapticsEnabled = false
        first.reducedMotionEnabled = true

        let second = SettingsState(saveManager: manager)
        XCTAssertEqual(second.musicVolume, 0.3, accuracy: 0.001)
        XCTAssertFalse(second.hapticsEnabled)
        XCTAssertTrue(second.reducedMotionEnabled)
    }

    func testReducedMotionTogglesCameraControllerFlag() {
        let defaults = UserDefaults(suiteName: "SettingsStateTests.\(UUID().uuidString)")!
        let settings = SettingsState(saveManager: SaveManager(defaults: defaults))
        settings.reducedMotionEnabled = true
        XCTAssertTrue(ChaseCameraController.reducedMotionEnabled)
        settings.reducedMotionEnabled = false
        XCTAssertFalse(ChaseCameraController.reducedMotionEnabled)
    }
}
