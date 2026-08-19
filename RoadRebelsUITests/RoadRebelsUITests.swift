import XCTest

/// Real end-to-end visual verification: launches the actual app, taps
/// through real UI, and captures screenshots of what's actually on screen —
/// not just "the code ran without crashing" like the unit-test smoke tests.
final class RoadRebelsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMenuCareerGarageAndLiveRace() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["RIDE"].waitForExistence(timeout: 10))
        attach(app, name: "01_menu")

        // Career map, then back.
        app.buttons["CAREER"].tap()
        sleep(1)
        attach(app, name: "02_career_map")
        app.buttons["backButton"].tap()
        sleep(1)

        // Garage, then back.
        XCTAssertTrue(app.buttons["GARAGE"].waitForExistence(timeout: 5))
        app.buttons["GARAGE"].tap()
        sleep(1)
        attach(app, name: "03_garage")
        app.buttons["backButton"].tap()
        sleep(1)

        // Quick race — the actual RealityKit scene.
        XCTAssertTrue(app.buttons["RIDE"].waitForExistence(timeout: 5))
        app.buttons["RIDE"].tap()
        sleep(3)
        attach(app, name: "04_race_start")

        // Steer right for a couple seconds to prove touch input reaches the game.
        let steerZone = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5))
        let steerTarget = app.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5))
        steerZone.press(forDuration: 1.5, thenDragTo: steerTarget)

        sleep(3)
        attach(app, name: "05_race_after_steer")
        sleep(4)
        attach(app, name: "06_race_later")
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
