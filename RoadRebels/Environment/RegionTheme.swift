import UIKit

/// Per-region sky/lighting so each Career region reads as a distinct place
/// (mega-spec section 38: desert/coastal/night-city/mountain/industrial
/// variety) without needing any real environment art — just color and
/// light intensity, applied to the sky background and the sun.
struct RegionTheme {
    let skyColor: UIColor
    let sunColor: UIColor
    let sunIntensity: Float

    static let `default` = RegionTheme(
        skyColor: UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1.0),
        sunColor: .white,
        sunIntensity: 4000
    )
}

enum RegionThemeCatalog {
    static func theme(forRegionID regionID: String?) -> RegionTheme {
        guard let regionID else { return .default }
        switch regionID {
        case "dustline":
            return RegionTheme(
                skyColor: UIColor(red: 0.85, green: 0.72, blue: 0.52, alpha: 1.0),
                sunColor: UIColor(red: 1.0, green: 0.93, blue: 0.78, alpha: 1.0),
                sunIntensity: 5200
            )
        case "neoncoast":
            return RegionTheme(
                skyColor: UIColor(red: 0.78, green: 0.42, blue: 0.85, alpha: 1.0),
                sunColor: UIColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0),
                sunIntensity: 3800
            )
        case "ironvalley":
            return RegionTheme(
                skyColor: UIColor(red: 0.58, green: 0.60, blue: 0.63, alpha: 1.0),
                sunColor: UIColor(white: 0.92, alpha: 1.0),
                sunIntensity: 3400
            )
        case "blackcanyon":
            return RegionTheme(
                skyColor: UIColor(red: 0.42, green: 0.20, blue: 0.18, alpha: 1.0),
                sunColor: UIColor(red: 1.0, green: 0.55, blue: 0.35, alpha: 1.0),
                sunIntensity: 3600
            )
        case "nightfallcity":
            return RegionTheme(
                skyColor: UIColor(red: 0.06, green: 0.07, blue: 0.18, alpha: 1.0),
                sunColor: UIColor(red: 0.5, green: 0.6, blue: 1.0, alpha: 1.0),
                sunIntensity: 900
            )
        case "wasteland":
            return RegionTheme(
                skyColor: UIColor(red: 0.72, green: 0.58, blue: 0.40, alpha: 1.0),
                sunColor: UIColor(red: 1.0, green: 0.75, blue: 0.5, alpha: 1.0),
                sunIntensity: 4600
            )
        default:
            return .default
        }
    }
}
