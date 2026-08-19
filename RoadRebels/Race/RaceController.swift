import RealityKit
import UIKit
import Foundation

/// Orchestrates one race: owns the road, player, a small field of archetyped
/// rivals, traffic, and camera, and drives them all from a single fixed-step
/// update. This is the "everything in one place" controller; Career's
/// multi-race structure (Phase 4) wraps this rather than replacing it.
@MainActor
final class RaceController {
    let sceneAnchor: AnchorEntity
    let cameraController: ChaseCameraController

    private let spline: RoadSpline
    private let playerEntity: BikeEntity
    private let rivals: [EnemyRider]
    private let traffic: TrafficManager
    private let input: BikeInputController
    private let gameState: GameState
    private let nitroTrail: Entity

    private var playerBikeState = BikeState(distance: 0, lateralOffset: -1.5)
    private var playerCombatState = RiderCombatState()
    private var trafficCollisionCooldown: Float = 0
    private var startTime: Date = Date()
    private var raceEnded = false

    private var nitroMeter: Float = 0
    private var wasNitroActive = false
    private var wasPlayerLeading = false

    private let config: RaceConfiguration
    private let tuning: BikeTuning

    init(input: BikeInputController, gameState: GameState, config: RaceConfiguration, tuning: BikeTuning = .default) {
        self.input = input
        self.gameState = gameState
        self.config = config
        self.tuning = tuning
        self.spline = .generate(totalLength: config.distance + 150)
        self.sceneAnchor = AnchorEntity(world: .zero)
        self.playerEntity = BikeEntity(role: .player)
        self.rivals = Self.makeRivals(from: config.rivals)
        self.traffic = TrafficManager(spline: spline, parent: sceneAnchor)
        self.cameraController = ChaseCameraController(initialPosition: SIMD3<Float>(0, GameConstants.cameraHeight, GameConstants.cameraFollowDistance))
        self.nitroTrail = ImpactEffects.attachNitroTrail(to: playerEntity.root)

        sceneAnchor.addChild(RoadBuilder.buildRoadEntity(spline: spline, finishDistance: config.distance))
        sceneAnchor.addChild(playerEntity.root)
        for rival in rivals {
            sceneAnchor.addChild(rival.entity.root)
        }
        sceneAnchor.addChild(cameraController.cameraEntity)
        addSun()
    }

    private static func makeRivals(from profiles: [RivalProfile]) -> [EnemyRider] {
        let laneOffsets: [Float] = [3, -3, 0, 5, -5]
        return profiles.enumerated().map { index, profile in
            EnemyRider(profile: profile, startDistance: Float(12 + index * 6), startLateral: laneOffsets[index % laneOffsets.count])
        }
    }

    private func addSun() {
        var light = DirectionalLightComponent(color: .white, intensity: 4000)
        light.isRealWorldProxy = false
        let sunEntity = Entity()
        sunEntity.components.set(light)
        sunEntity.look(at: SIMD3<Float>(0.4, -1, 0.3), from: SIMD3<Float>(0, 50, 0), relativeTo: nil)
        sceneAnchor.addChild(sunEntity)
    }

    func start() {
        startTime = Date()
        raceEnded = false
        playerBikeState = BikeState(distance: 0, lateralOffset: -1.5)
        playerCombatState = RiderCombatState(health: GameConstants.riderMaxHealth + tuning.maxHealthBonus)
        nitroMeter = 0
        wasNitroActive = false
        wasPlayerLeading = false
        gameState.playerMaxHealth = GameConstants.riderMaxHealth + tuning.maxHealthBonus
    }

    func update(dt: Float) {
        guard !raceEnded else { return }

        stepPlayer(dt: dt)
        stepCombat()
        stepTrafficAndCollisions(dt: dt)
        stepRivals(dt: dt)
        stepOvertake()

        applyTransforms()
        updateCamera(dt: dt)
        publishTelemetry()
        checkFinish()
    }

    private func stepPlayer(dt: Float) {
        let nitroActive = input.state.nitroHeld && nitroMeter > 0
        if nitroActive {
            nitroMeter = max(0, nitroMeter - GameConstants.nitroDrainPerSecond * tuning.nitroDrainMultiplier * dt)
        }
        if nitroActive != wasNitroActive {
            cameraController.setNitroBoost(active: nitroActive)
            ImpactEffects.setNitroTrail(nitroTrail, active: nitroActive)
            if nitroActive {
                HapticsService.shared.play(.nitroActivate)
                AudioService.shared.play(.nitro)
            }
            wasNitroActive = nitroActive
        }

        var control = input.state
        control.nitroActive = nitroActive
        playerBikeState = BikePhysics.step(state: playerBikeState, control: control, dt: dt, tuning: tuning)
        playerCombatState = CombatResolver.tickCooldown(playerCombatState, dt: TimeInterval(dt))
    }

    /// Player attacks whichever living rival is currently closest.
    private func stepCombat() {
        guard input.consumeAttackRequest() else { return }
        guard let target = nearestLivingRival() else { return }

        let (updatedAttacker, outcome) = CombatResolver.attemptAttack(
            attackerState: playerCombatState,
            attackerDistance: playerBikeState.distance,
            attackerLateral: playerBikeState.lateralOffset,
            defenderDistance: target.bikeState.distance,
            defenderLateral: target.bikeState.lateralOffset,
            damageMultiplier: tuning.attackDamageMultiplier
        )
        playerCombatState = updatedAttacker
        guard let outcome else { return }

        if target.attemptDefend() {
            HapticsService.shared.play(.nearMiss)
            return
        }

        target.receiveHit(outcome)
        nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnAttack)
        cameraController.addTrauma(0.35)
        HapticsService.shared.play(.attackImpact)
        AudioService.shared.play(.attackHit)
        ImpactEffects.spawnHitSpark(at: target.entity.root.position, in: sceneAnchor)
    }

    private func nearestLivingRival() -> EnemyRider? {
        rivals
            .filter { !$0.combatState.isDefeated }
            .min { lhs, rhs in
                let lhsGap = abs(lhs.bikeState.distance - playerBikeState.distance)
                let rhsGap = abs(rhs.bikeState.distance - playerBikeState.distance)
                return lhsGap < rhsGap
            }
    }

    private func stepTrafficAndCollisions(dt: Float) {
        traffic.update(playerDistance: playerBikeState.distance, dt: dt)
        trafficCollisionCooldown = max(0, trafficCollisionCooldown - dt)

        for vehicle in traffic.vehicles {
            let longitudinalGap = abs(vehicle.distance - playerBikeState.distance)
            let lateralGap = abs(vehicle.laneOffset - playerBikeState.lateralOffset)

            if trafficCollisionCooldown <= 0 && longitudinalGap < 2.4 && lateralGap < 1.7 {
                let pushDirection: Float = playerBikeState.lateralOffset >= vehicle.laneOffset ? 1 : -1
                playerBikeState = BikePhysics.applyKnockback(
                    to: playerBikeState,
                    lateralImpulse: pushDirection * 4 * tuning.collisionResistance,
                    speedLoss: 14 * tuning.collisionResistance
                )
                trafficCollisionCooldown = 0.6
                cameraController.addTrauma(0.55)
                HapticsService.shared.play(.collision)
                AudioService.shared.play(.collision)
                ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
                break
            }

            if !vehicle.hasTriggeredNearMiss && longitudinalGap < 3.5 && lateralGap >= 1.7 && lateralGap < 3.0 {
                vehicle.hasTriggeredNearMiss = true
                nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnNearMiss)
                HapticsService.shared.play(.nearMiss)
            } else if longitudinalGap > 8 {
                vehicle.hasTriggeredNearMiss = false
            }
        }
    }

    private func stepRivals(dt: Float) {
        for rival in rivals {
            guard !rival.combatState.isDefeated else { continue }
            rival.update(playerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset, dt: dt)
            if let outcome = rival.attemptAttack(onPlayerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset) {
                applyOutcomeToPlayer(outcome)
            }
        }
    }

    private func stepOvertake() {
        let isLeading = rivals.allSatisfy { playerBikeState.distance > $0.bikeState.distance }
        if isLeading && !wasPlayerLeading {
            nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnOvertake)
        }
        wasPlayerLeading = isLeading
    }

    private func applyOutcomeToPlayer(_ outcome: AttackOutcome) {
        let resisted = AttackOutcome(
            damage: outcome.damage,
            lateralKnockback: outcome.lateralKnockback * tuning.collisionResistance,
            speedLoss: outcome.speedLoss * tuning.collisionResistance
        )
        let (updatedBike, updatedCombat) = HitReaction.apply(outcome: resisted, toBike: playerBikeState, combat: playerCombatState)
        playerBikeState = updatedBike
        playerCombatState = updatedCombat
        cameraController.addTrauma(0.35)
        HapticsService.shared.play(.attackImpact)
        AudioService.shared.play(.collision)
        ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
    }

    private func applyTransforms() {
        playerEntity.applyTransform(state: playerBikeState, spline: spline)
        for rival in rivals {
            rival.applyTransform(spline: spline)
        }
    }

    private func updateCamera(dt: Float) {
        let t = spline.transform(atDistance: playerBikeState.distance, lateralOffset: playerBikeState.lateralOffset)
        cameraController.update(targetPosition: t.position, targetForward: t.forward, dt: dt)
    }

    private func currentPlayerPosition() -> Int {
        1 + rivals.filter { $0.bikeState.distance > playerBikeState.distance }.count
    }

    private func publishTelemetry() {
        gameState.playerSpeed = playerBikeState.speed
        gameState.playerHealth = playerCombatState.health
        gameState.playerPosition = currentPlayerPosition()
        gameState.raceProgress = max(0, min(1, playerBikeState.distance / config.distance))
        gameState.nitroMeter = nitroMeter
    }

    private func checkFinish() {
        guard playerBikeState.distance >= config.distance else { return }
        raceEnded = true
        let position = currentPlayerPosition()
        let didWin = position == 1
        let result = RaceResult(
            position: position,
            totalRiders: rivals.count + 1,
            elapsedTime: Date().timeIntervalSince(startTime),
            didWin: didWin,
            careerRaceID: config.careerRaceID,
            creditsEarned: didWin ? config.creditReward : 0
        )
        if didWin {
            HapticsService.shared.play(.victory)
            AudioService.shared.play(.victory)
        } else {
            AudioService.shared.play(.defeat)
        }
        gameState.finishRace(result: result)
    }
}
