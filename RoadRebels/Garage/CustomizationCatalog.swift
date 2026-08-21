import UIKit

/// The player's current visual loadout — everything BikeEntity needs to
/// render the player's own bike/rider distinctly from purchased cosmetics,
/// independent of the performance tuning in BikeTuning.
struct BikeAppearance: Equatable {
    var paintColor: UIColor
    var helmetColor: UIColor

    static let `default` = BikeAppearance(
        paintColor: PaintCatalog.all[0].color,
        helmetColor: HelmetCatalog.all[0].color
    )
}

struct PaintOption: Identifiable, Equatable {
    let id: String
    let name: String
    let cost: Int
    let color: UIColor

    static func == (lhs: PaintOption, rhs: PaintOption) -> Bool { lhs.id == rhs.id }
}

/// Purchasable bike paint jobs (mega-spec "cosmetic customization"). First
/// entry is free/owned from the start so a fresh save always has a valid
/// selection.
enum PaintCatalog {
    static let all: [PaintOption] = [
        PaintOption(id: "crimson", name: "Crimson Red", cost: 0, color: .systemRed),
        PaintOption(id: "cobalt", name: "Cobalt Blue", cost: 150, color: .systemBlue),
        PaintOption(id: "toxic", name: "Toxic Green", cost: 150, color: UIColor(red: 0.42, green: 0.9, blue: 0.15, alpha: 1)),
        PaintOption(id: "carbon", name: "Carbon Black", cost: 200, color: UIColor(white: 0.08, alpha: 1)),
        PaintOption(id: "sunset", name: "Sunset Gold", cost: 250, color: UIColor(red: 1.0, green: 0.72, blue: 0.15, alpha: 1)),
        PaintOption(id: "chrome", name: "Chrome Silver", cost: 300, color: UIColor(white: 0.75, alpha: 1)),
    ]

    static func option(for id: String) -> PaintOption {
        all.first { $0.id == id } ?? all[0]
    }
}

struct HelmetOption: Identifiable, Equatable {
    let id: String
    let name: String
    let cost: Int
    let color: UIColor

    static func == (lhs: HelmetOption, rhs: HelmetOption) -> Bool { lhs.id == rhs.id }
}

/// Purchasable helmet colors for the player's rider.
enum HelmetCatalog {
    static let all: [HelmetOption] = [
        HelmetOption(id: "redHelmet", name: "Crimson", cost: 0, color: .systemRed),
        HelmetOption(id: "blackHelmet", name: "Blackout", cost: 100, color: UIColor(white: 0.06, alpha: 1)),
        HelmetOption(id: "whiteHelmet", name: "Ghost White", cost: 100, color: UIColor(white: 0.92, alpha: 1)),
        HelmetOption(id: "goldHelmet", name: "Gold Rush", cost: 180, color: UIColor(red: 1.0, green: 0.78, blue: 0.2, alpha: 1)),
        HelmetOption(id: "toxicHelmet", name: "Toxic", cost: 180, color: UIColor(red: 0.42, green: 0.9, blue: 0.15, alpha: 1)),
    ]

    static func option(for id: String) -> HelmetOption {
        all.first { $0.id == id } ?? all[0]
    }
}
