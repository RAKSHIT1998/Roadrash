import Foundation

/// Phase 1's single rival: a rubber-banded racer that closes the gap to the
/// player and, once alongside, throws attacks. This is intentionally a
/// simple scripted behavior — the archetype roster (Brawler/Speedster/
/// Defender/etc.) and their state-machine AI arrive in Phase 3.
final class EnemyRider {
    let entity: BikeEntity
    private(set) var bikeState: BikeState
    private(set) var combatState = RiderCombatState()

    init(startDistance: Float = 20, startLateral: Float = 3) {
        entity = BikeEntity(role: .rival)
        bikeState = BikeState(distance: startDistance, lateralOffset: startLateral)
    }

    func update(playerDistance: Float, playerLateral: Float, dt: Float) {
        let gap = playerDistance - bikeState.distance
        let rubberBand = max(-8, min(8, gap * 0.05))
        let targetSpeed = GameConstants.enemyCatchUpSpeed + rubberBand
        bikeState.speed += (targetSpeed - bikeState.speed) * min(1, 2.0 * dt)
        bikeState.speed = max(0, min(bikeState.speed, GameConstants.bikeMaxSpeed))
        bikeState.distance += bikeState.speed * dt

        if abs(gap) < 12 {
            let side: Float = bikeState.lateralOffset <= playerLateral ? -1.4 : 1.4
            let targetLateral = playerLateral + side
            bikeState.lateralOffset += (targetLateral - bikeState.lateralOffset) * min(1, 3.0 * dt)
        }
        let halfRange = GameConstants.bikeHalfLaneRange
        bikeState.lateralOffset = max(-halfRange, min(halfRange, bikeState.lateralOffset))

        combatState = CombatResolver.tickCooldown(combatState, dt: TimeInterval(dt))
    }

    @discardableResult
    func attemptAttack(onPlayerDistance playerDistance: Float, playerLateral: Float) -> AttackOutcome? {
        let (updated, outcome) = CombatResolver.attemptAttack(
            attackerState: combatState,
            attackerDistance: bikeState.distance,
            attackerLateral: bikeState.lateralOffset,
            defenderDistance: playerDistance,
            defenderLateral: playerLateral
        )
        combatState = updated
        return outcome
    }

    func receiveHit(_ outcome: AttackOutcome) {
        let (updatedBike, updatedCombat) = HitReaction.apply(outcome: outcome, toBike: bikeState, combat: combatState)
        bikeState = updatedBike
        combatState = updatedCombat
    }

    func applyTransform(spline: RoadSpline) {
        entity.applyTransform(state: bikeState, spline: spline)
    }
}
