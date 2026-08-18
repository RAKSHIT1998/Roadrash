import Foundation

/// The rival roster from the design spec (section 16). Each case is a bundle
/// of tuning multipliers rather than a subclass — behavior differences live
/// in EnemyRider/EnemyAI, which read these multipliers.
enum EnemyArchetype: String, CaseIterable {
    case brawler
    case speedster
    case defender
    case trickster
    case rammer
    case hunter

    /// Added to the base catch-up speed used for rubber-banding.
    var speedBias: Float {
        switch self {
        case .brawler: return 0
        case .speedster: return 10
        case .defender: return -3
        case .trickster: return 2
        case .rammer: return 4
        case .hunter: return 6
        }
    }

    /// How eagerly this rival closes the gap when ahead of the player
    /// (1 = eases off like a normal racer, 0 = never eases off / relentless).
    var easeOffWhenAhead: Float {
        self == .hunter ? 0.15 : 1.0
    }

    /// Multiplies GameConstants.attackCooldown (lower = attacks more often).
    var attackCooldownMultiplier: Float {
        switch self {
        case .brawler: return 0.7
        case .rammer: return 0.85
        case .hunter: return 0.9
        default: return 1.0
        }
    }

    /// Multiplies outgoing damage when this rival lands a hit.
    var damageMultiplier: Float {
        switch self {
        case .speedster: return 0.6
        case .rammer: return 1.3
        default: return 1.0
        }
    }

    /// Multiplies the lateral knockback this rival's attacks apply.
    var knockbackMultiplier: Float {
        self == .rammer ? 2.0 : 1.0
    }

    /// Chance (0...1) to block an incoming player attack outright.
    var blockChance: Float {
        self == .defender ? 0.55 : 0.0
    }

    /// How often (seconds) a trickster wanders to a new lane even without
    /// the player nearby. 0 disables wandering.
    var laneWanderInterval: Float {
        self == .trickster ? 1.4 : 0
    }
}
