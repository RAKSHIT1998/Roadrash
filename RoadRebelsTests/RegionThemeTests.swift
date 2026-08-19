import XCTest
@testable import RoadRebels

final class RegionThemeTests: XCTestCase {
    func testEveryRegionHasADistinctTheme() {
        let skyColors = CareerContent.regions.map { RegionThemeCatalog.theme(forRegionID: $0.id).skyColor }
        XCTAssertEqual(Set(skyColors).count, skyColors.count, "every region should read as visually distinct")
    }

    func testUnknownRegionFallsBackToDefault() {
        let theme = RegionThemeCatalog.theme(forRegionID: "not-a-real-region")
        XCTAssertEqual(theme.skyColor, RegionTheme.default.skyColor)
    }

    func testNilRegionFallsBackToDefault() {
        let theme = RegionThemeCatalog.theme(forRegionID: nil)
        XCTAssertEqual(theme.skyColor, RegionTheme.default.skyColor)
    }
}

final class CareerContentRegionLookupTests: XCTestCase {
    func testRegionForRaceIDFindsCorrectRegion() {
        let bossRace = CareerContent.regions[2].races.last!
        let found = CareerContent.region(forRaceID: bossRace.id)
        XCTAssertEqual(found?.id, CareerContent.regions[2].id)
    }

    func testRegionForUnknownRaceIDReturnsNil() {
        XCTAssertNil(CareerContent.region(forRaceID: "nope"))
    }
}
