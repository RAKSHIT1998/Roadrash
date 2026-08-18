import Foundation

/// Glue that turns a resolved `AttackOutcome` into the two pieces of state a
/// hit actually changes: the defender's bike motion and their health.
enum HitReaction {
    static func apply(outcome: AttackOutcome, toBike bike: BikeState, combat: RiderCombatState) -> (BikeState, RiderCombatState) {
        let updatedBike = BikePhysics.applyKnockback(
            to: bike,
            lateralImpulse: outcome.lateralKnockback,
            speedLoss: outcome.speedLoss
        )
        let updatedCombat = CombatResolver.applyDamage(combat, outcome: outcome)
        return (updatedBike, updatedCombat)
    }
}
