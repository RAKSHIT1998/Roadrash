import Foundation

/// The concrete, final multipliers BikePhysics/CombatResolver read for a
/// specific bike + upgrade combination. `.default` is neutral (all
/// multipliers 1, all bonuses 0) so passing it reproduces Phase 1/2/3
/// behavior exactly — existing physics/combat tests don't need to change.
struct BikeTuning: Equatable {
    var speedMultiplier: Float = 1
    var accelMultiplier: Float = 1
    var brakeMultiplier: Float = 1
    var handlingMultiplier: Float = 1
    var maxHealthBonus: Float = 0
    /// Multiplies incoming knockback/speed-loss from hits and collisions;
    /// below 1 means more resistant (frame/armor upgrades).
    var collisionResistance: Float = 1
    var attackDamageMultiplier: Float = 1
    var nitroDrainMultiplier: Float = 1

    static let `default` = BikeTuning()
}

enum UpgradeCategory: String, CaseIterable {
    case engine
    case transmission
    case brakes
    case tires
    case frame
    case nitro
    case armor
    case combat

    var displayName: String {
        rawValue.capitalized
    }
}

enum BikeTuningCalculator {
    static let maxUpgradeLevel = 5

    static func tuning(for bike: BikeModel, upgradeLevels: [UpgradeCategory: Int]) -> BikeTuning {
        func level(_ category: UpgradeCategory) -> Int {
            upgradeLevels[category] ?? 0
        }

        var tuning = BikeTuning()
        tuning.accelMultiplier = bike.baseAccelMultiplier * (1 + 0.05 * Float(level(.engine)))
        tuning.speedMultiplier = bike.baseSpeedMultiplier * (1 + 0.04 * Float(level(.transmission)))
        tuning.brakeMultiplier = bike.baseBrakingMultiplier * (1 + 0.05 * Float(level(.brakes)))
        tuning.handlingMultiplier = bike.baseHandlingMultiplier * (1 + 0.05 * Float(level(.tires)))
        tuning.collisionResistance = max(0.5, 1 - 0.06 * Float(level(.frame)))
        tuning.nitroDrainMultiplier = max(0.5, 1 - 0.08 * Float(level(.nitro)))
        tuning.maxHealthBonus = bike.baseDurabilityBonus + 8 * Float(level(.armor))
        tuning.attackDamageMultiplier = 1 + 0.06 * Float(level(.combat))
        return tuning
    }
}
