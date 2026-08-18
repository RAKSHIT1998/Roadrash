import Foundation

/// Per-rider combat bookkeeping. Kept as plain state (not a RealityKit
/// Component) so the resolution math is pure and unit-testable, matching the
/// BikePhysics approach. Combos/defense/critical hits arrive with the full
/// combat pass later; Phase 1 is range + cooldown + damage + knockback only.
struct RiderCombatState: Equatable {
    var health: Float = GameConstants.riderMaxHealth
    var attackCooldownRemaining: TimeInterval = 0
    var isDefeated: Bool { health <= 0 }
}

struct AttackOutcome {
    let damage: Float
    /// Positive = knock the defender to their right relative to the road.
    let lateralKnockback: Float
    let speedLoss: Float
}

enum CombatResolver {
    /// Ticks cooldown timers; call once per fixed step for every rider.
    static func tickCooldown(_ state: RiderCombatState, dt: TimeInterval) -> RiderCombatState {
        var next = state
        next.attackCooldownRemaining = max(0, next.attackCooldownRemaining - dt)
        return next
    }

    /// Returns an outcome (and puts the attacker on cooldown) if `attacker` is
    /// within range of `defender` and off cooldown; otherwise nil and state
    /// is returned unchanged.
    static func attemptAttack(
        attackerState: RiderCombatState,
        attackerDistance: Float,
        attackerLateral: Float,
        defenderDistance: Float,
        defenderLateral: Float
    ) -> (updatedAttacker: RiderCombatState, outcome: AttackOutcome?) {
        guard attackerState.attackCooldownRemaining <= 0 else {
            return (attackerState, nil)
        }
        let dx = defenderDistance - attackerDistance
        let dz = defenderLateral - attackerLateral
        let separation = sqrt(dx * dx + dz * dz)
        guard separation <= GameConstants.attackRange else {
            return (attackerState, nil)
        }

        var updatedAttacker = attackerState
        updatedAttacker.attackCooldownRemaining = GameConstants.attackCooldown

        let knockDirection: Float = defenderLateral >= attackerLateral ? 1 : -1
        let outcome = AttackOutcome(
            damage: GameConstants.attackDamage,
            lateralKnockback: knockDirection * GameConstants.attackKnockback,
            speedLoss: 4.0
        )
        return (updatedAttacker, outcome)
    }

    static func applyDamage(_ state: RiderCombatState, outcome: AttackOutcome) -> RiderCombatState {
        var next = state
        next.health = max(0, next.health - outcome.damage)
        return next
    }
}
