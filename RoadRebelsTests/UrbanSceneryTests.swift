import XCTest
@testable import RoadRebels

@MainActor
final class UrbanSceneryTests: XCTestCase {
    func testUrbanThemeProducesBuildingsAndPedestrians() {
        let spline = RoadSpline.generate(totalLength: 500)
        let theme = RegionThemeCatalog.theme(forRegionID: "neoncoast")
        XCTAssertTrue(theme.isUrban)

        let props = SceneryBuilder.buildProps(spline: spline, from: 0, to: 500, theme: theme)
        XCTAssertGreaterThan(props.children.count, 0, "urban scenery should place at least some props over 500m")
    }

    func testRuralThemeStaysNonUrban() {
        let theme = RegionThemeCatalog.theme(forRegionID: "dustline")
        XCTAssertFalse(theme.isUrban)
    }

    /// Full end-to-end smoke test through a real Career race in an urban
    /// region (Neon Coast) — exercises RaceController's building/sidewalk/
    /// pedestrian/parked-car scene construction and several seconds of real
    /// gameplay against it, the same rigor as the rural smoke test.
    func testCareerRaceInUrbanRegionRunsWithoutCrashing() {
        let neonCoastRace = CareerContent.regions.first { $0.id == "neoncoast" }!.races.first!
        let config = RaceConfiguration(careerRace: neonCoastRace)
        let gameState = GameState()
        let input = BikeInputController()
        let controller = RaceController(input: input, gameState: gameState, config: config)
        controller.start()

        let dt: Float = 1.0 / 60.0
        for frame in 0..<(60 * 20) {
            input.updateSteer(fromDragTranslationX: CGFloat(sin(Double(frame) * 0.02)) * 80, screenWidth: 900)
            if frame % 90 == 0 { input.requestAttack() }
            controller.update(dt: dt)
            if case .raceFinished = gameState.screen { break }
        }

        XCTAssertGreaterThan(gameState.raceProgress, 0)
    }
}
