import Foundation

/// One rival racer: an archetype's stat multipliers driving a small state
/// machine (EnemyAIState) on top of the same BikeState/RiderCombatState
/// building blocks the player uses. Multiple of these with different
/// archetypes make up the field in a race.
@MainActor
final class EnemyRider {
    let archetype: EnemyArchetype
    let displayName: String
    let entity: BikeEntity
    private(set) var bikeState: BikeState
    private(set) var combatState = RiderCombatState()
    private(set) var aiState: EnemyAIState = .racing

    private var stateTimer: Float = 0
    private var wanderTarget: Float = 0
    private var wanderTimer: Float = 0
    private var pendingHitFlag = false
    private var pendingBlockFlag = false

    init(profile: RivalProfile, startDistance: Float, startLateral: Float) {
        self.archetype = profile.archetype
        self.displayName = profile.name
        self.entity = BikeEntity(role: .rival)
        self.bikeState = BikeState(distance: startDistance, lateralOffset: startLateral)
        self.wanderTarget = startLateral
    }

    func update(playerDistance: Float, playerLateral: Float, dt: Float) {
        let gap = playerDistance - bikeState.distance
        stepLongitudinal(gap: gap, dt: dt)
        stepLateral(gap: gap, playerLateral: playerLateral, dt: dt)
        stepState(gap: gap, dt: dt)
        combatState = CombatResolver.tickCooldown(combatState, dt: TimeInterval(dt))
    }

    private func stepLongitudinal(gap: Float, dt: Float) {
        let rubberBand = max(-8, min(8, gap * 0.05))
        let easing: Float = gap < 0 ? archetype.easeOffWhenAhead : 1.0
        let targetSpeed = GameConstants.enemyCatchUpSpeed + archetype.speedBias + rubberBand * easing
        bikeState.speed += (targetSpeed - bikeState.speed) * min(1, 2.0 * dt)
        bikeState.speed = max(0, min(bikeState.speed, GameConstants.bikeMaxSpeed))
        bikeState.distance += bikeState.speed * dt
    }

    private func stepLateral(gap: Float, playerLateral: Float, dt: Float) {
        let halfRange = GameConstants.bikeHalfLaneRange
        var targetLateral = bikeState.lateralOffset

        if abs(gap) < 12 {
            let side: Float = bikeState.lateralOffset <= playerLateral ? -1.4 : 1.4
            targetLateral = playerLateral + side
        } else if archetype.laneWanderInterval > 0 {
            targetLateral = wanderTarget
            wanderTimer -= dt
            if wanderTimer <= 0 {
                wanderTimer = archetype.laneWanderInterval
                wanderTarget = Float.random(in: -halfRange...halfRange)
            }
        }

        bikeState.lateralOffset += (targetLateral - bikeState.lateralOffset) * min(1, 3.0 * dt)
        bikeState.lateralOffset = max(-halfRange, min(halfRange, bikeState.lateralOffset))
    }

    private func stepState(gap: Float, dt: Float) {
        let attackReached = abs(gap) < GameConstants.enemyAttackRange && combatState.attackCooldownRemaining <= 0
        let context = EnemyAIContext(
            gapToPlayer: gap,
            isDefeated: combatState.isDefeated,
            justGotHit: pendingHitFlag,
            justBlocked: pendingBlockFlag,
            attackRangeReached: attackReached
        )
        let next = EnemyAI.nextState(current: aiState, stateTimer: stateTimer, context: context)
        stateTimer = next == aiState ? stateTimer + dt : 0
        aiState = next
        pendingHitFlag = false
        pendingBlockFlag = false
    }

    @discardableResult
    func attemptAttack(onPlayerDistance playerDistance: Float, playerLateral: Float) -> AttackOutcome? {
        let (updated, outcome) = CombatResolver.attemptAttack(
            attackerState: combatState,
            attackerDistance: bikeState.distance,
            attackerLateral: bikeState.lateralOffset,
            defenderDistance: playerDistance,
            defenderLateral: playerLateral,
            cooldownMultiplier: archetype.attackCooldownMultiplier,
            damageMultiplier: archetype.damageMultiplier,
            knockbackMultiplier: archetype.knockbackMultiplier
        )
        combatState = updated
        return outcome
    }

    /// Rolls this rider's block chance against an incoming player attack.
    /// Returns true if the hit should be fully negated.
    func attemptDefend() -> Bool {
        guard archetype.blockChance > 0 else { return false }
        let blocked = Float.random(in: 0...1) < archetype.blockChance
        if blocked { pendingBlockFlag = true }
        return blocked
    }

    func receiveHit(_ outcome: AttackOutcome) {
        let (updatedBike, updatedCombat) = HitReaction.apply(outcome: outcome, toBike: bikeState, combat: combatState)
        bikeState = updatedBike
        combatState = updatedCombat
        pendingHitFlag = true
    }

    func applyTransform(spline: RoadSpline) {
        entity.applyTransform(state: bikeState, spline: spline)
    }
}
