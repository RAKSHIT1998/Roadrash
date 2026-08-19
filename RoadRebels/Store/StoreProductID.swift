import Foundation

/// Product identifiers, matching what's registered in RoadRebels.storekit
/// (for local Xcode testing) and what would be configured in App Store
/// Connect for a real release build.
enum StoreProductID: String, CaseIterable {
    case pro = "com.roadrebels.game.pro"
    case removeAds = "com.roadrebels.game.removeads"
    case starterPack = "com.roadrebels.game.starterpack"
    case creditsSmall = "com.roadrebels.game.credits.small"
    case creditsLarge = "com.roadrebels.game.credits.large"

    var creditGrant: Int {
        switch self {
        case .starterPack: return 500
        case .creditsSmall: return 200
        case .creditsLarge: return 1200
        case .pro, .removeAds: return 0
        }
    }
}
