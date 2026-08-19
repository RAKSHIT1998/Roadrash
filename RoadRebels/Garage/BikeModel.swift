import Foundation

/// Original fictional motorcycles (mega-spec section 19) — no real-world
/// brand names. Base multipliers are relative to GameConstants' defaults;
/// GarageState layers upgrade levels on top to produce a final BikeTuning.
struct BikeModel: Identifiable, Equatable {
    let id: String
    let name: String
    let unlockCost: Int // 0 = owned from the start
    let baseSpeedMultiplier: Float
    let baseAccelMultiplier: Float
    let baseHandlingMultiplier: Float
    let baseBrakingMultiplier: Float
    let baseDurabilityBonus: Float
}

enum BikeCatalog {
    static let all: [BikeModel] = [
        BikeModel(id: "falcon250", name: "Falcon 250", unlockCost: 0,
                  baseSpeedMultiplier: 1.00, baseAccelMultiplier: 1.00, baseHandlingMultiplier: 1.00, baseBrakingMultiplier: 1.00, baseDurabilityBonus: 0),
        BikeModel(id: "viper400", name: "Viper 400", unlockCost: 300,
                  baseSpeedMultiplier: 1.12, baseAccelMultiplier: 1.05, baseHandlingMultiplier: 0.95, baseBrakingMultiplier: 0.95, baseDurabilityBonus: 0),
        BikeModel(id: "torquex", name: "Torque X", unlockCost: 450,
                  baseSpeedMultiplier: 0.95, baseAccelMultiplier: 0.90, baseHandlingMultiplier: 0.85, baseBrakingMultiplier: 1.10, baseDurabilityBonus: 40),
        BikeModel(id: "raven600", name: "Raven 600", unlockCost: 600,
                  baseSpeedMultiplier: 1.08, baseAccelMultiplier: 1.10, baseHandlingMultiplier: 1.05, baseBrakingMultiplier: 1.00, baseDurabilityBonus: 10),
        BikeModel(id: "phantomr", name: "Phantom R", unlockCost: 900,
                  baseSpeedMultiplier: 1.20, baseAccelMultiplier: 1.15, baseHandlingMultiplier: 1.10, baseBrakingMultiplier: 1.05, baseDurabilityBonus: 20),
    ]

    static func model(for id: String) -> BikeModel {
        all.first { $0.id == id } ?? all[0]
    }
}
