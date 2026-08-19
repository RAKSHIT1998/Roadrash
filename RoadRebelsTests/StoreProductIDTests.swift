import XCTest
@testable import RoadRebels

final class StoreProductIDTests: XCTestCase {
    func testOnlyConsumablesAndStarterPackGrantCredits() {
        XCTAssertEqual(StoreProductID.starterPack.creditGrant, 500)
        XCTAssertEqual(StoreProductID.creditsSmall.creditGrant, 200)
        XCTAssertEqual(StoreProductID.creditsLarge.creditGrant, 1200)
        XCTAssertEqual(StoreProductID.pro.creditGrant, 0)
        XCTAssertEqual(StoreProductID.removeAds.creditGrant, 0)
    }

    func testAllRawValuesAreUniqueAndBundlePrefixed() {
        let rawValues = StoreProductID.allCases.map(\.rawValue)
        XCTAssertEqual(Set(rawValues).count, rawValues.count)
        XCTAssertTrue(rawValues.allSatisfy { $0.hasPrefix("com.roadrebels.game.") })
    }
}
