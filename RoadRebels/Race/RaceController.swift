import RealityKit
import UIKit
import Foundation

/// Orchestrates one race: owns the road, player, single rival, traffic, and
/// camera, and drives them all from a single fixed-step update. This is the
/// Phase 1/2 "everything in one place" controller; as Career/multi-rival
/// races land in later phases this splits into RaceController + RaceRuleset.
@MainActor
final class RaceController {
    let sceneAnchor: AnchorEntity
    let cameraController: ChaseCameraController

    private let spline: RoadSpline
    private let playerEntity: BikeEntity
    private let rival: EnemyRider
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
    private var wasPlayerAheadOfRival = false

    init(input: BikeInputController, gameState: GameState) {
        self.input = input
        self.gameState = gameState
        self.spline = .standardPhase1()
        self.sceneAnchor = AnchorEntity(world: .zero)
        self.playerEntity = BikeEntity(role: .player)
        self.rival = EnemyRider(startDistance: 20, startLateral: 3)
        self.traffic = TrafficManager(spline: spline, parent: sceneAnchor)
        self.cameraController = ChaseCameraController(initialPosition: SIMD3<Float>(0, GameConstants.cameraHeight, GameConstants.cameraFollowDistance))
        self.nitroTrail = ImpactEffects.attachNitroTrail(to: playerEntity.root)

        sceneAnchor.addChild(RoadBuilder.buildRoadEntity(spline: spline))
        sceneAnchor.addChild(playerEntity.root)
        sceneAnchor.addChild(rival.entity.root)
        sceneAnchor.addChild(cameraController.cameraEntity)
        addSun()
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
        playerCombatState = RiderCombatState()
        nitroMeter = 0
        wasNitroActive = false
        wasPlayerAheadOfRival = false
    }

    func update(dt: Float) {
        guard !raceEnded else { return }

        stepPlayer(dt: dt)
        stepCombat()
        stepTrafficAndCollisions(dt: dt)
        rival.update(playerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset, dt: dt)
        if let outcome = rival.attemptAttack(onPlayerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset) {
            applyOutcomeToPlayer(outcome)
        }
        stepOvertake()

        applyTransforms()
        updateCamera(dt: dt)
        publishTelemetry()
        checkFinish()
    }

    private func stepPlayer(dt: Float) {
        let nitroActive = input.state.nitroHeld && nitroMeter > 0
        if nitroActive {
            nitroMeter = max(0, nitroMeter - GameConstants.nitroDrainPerSecond * dt)
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
        playerBikeState = BikePhysics.step(state: playerBikeState, control: control, dt: dt)
        playerCombatState = CombatResolver.tickCooldown(playerCombatState, dt: TimeInterval(dt))
    }

    private func stepCombat() {
        guard input.consumeAttackRequest() else { return }
        let (updatedAttacker, outcome) = CombatResolver.attemptAttack(
            attackerState: playerCombatState,
            attackerDistance: playerBikeState.distance,
            attackerLateral: playerBikeState.lateralOffset,
            defenderDistance: rival.bikeState.distance,
            defenderLateral: rival.bikeState.lateralOffset
        )
        playerCombatState = updatedAttacker
        guard let outcome else { return }

        rival.receiveHit(outcome)
        nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnAttack)
        cameraController.addTrauma(0.35)
        HapticsService.shared.play(.attackImpact)
        AudioService.shared.play(.attackHit)
        ImpactEffects.spawnHitSpark(at: rival.entity.root.position, in: sceneAnchor)
    }

    private func stepTrafficAndCollisions(dt: Float) {
        traffic.update(playerDistance: playerBikeState.distance, dt: dt)
        trafficCollisionCooldown = max(0, trafficCollisionCooldown - dt)

        for vehicle in traffic.vehicles {
            let longitudinalGap = abs(vehicle.distance - playerBikeState.distance)
            let lateralGap = abs(vehicle.laneOffset - playerBikeState.lateralOffset)

            if trafficCollisionCooldown <= 0 && longitudinalGap < 2.4 && lateralGap < 1.7 {
                let pushDirection: Float = playerBikeState.lateralOffset >= vehicle.laneOffset ? 1 : -1
                playerBikeState = BikePhysics.applyKnockback(to: playerBikeState, lateralImpulse: pushDirection * 4, speedLoss: 14)
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

    private func stepOvertake() {
        let isAhead = playerBikeState.distance > rival.bikeState.distance
        if isAhead && !wasPlayerAheadOfRival {
            nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnOvertake)
        }
        wasPlayerAheadOfRival = isAhead
    }

    private func applyOutcomeToPlayer(_ outcome: AttackOutcome) {
        let (updatedBike, updatedCombat) = HitReaction.apply(outcome: outcome, toBike: playerBikeState, combat: playerCombatState)
        playerBikeState = updatedBike
        playerCombatState = updatedCombat
        cameraController.addTrauma(0.35)
        HapticsService.shared.play(.attackImpact)
        AudioService.shared.play(.collision)
        ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
    }

    private func applyTransforms() {
        playerEntity.applyTransform(state: playerBikeState, spline: spline)
        rival.applyTransform(spline: spline)
    }

    private func updateCamera(dt: Float) {
        let t = spline.transform(atDistance: playerBikeState.distance, lateralOffset: playerBikeState.lateralOffset)
        cameraController.update(targetPosition: t.position, targetForward: t.forward, dt: dt)
    }

    private func publishTelemetry() {
        gameState.playerSpeed = playerBikeState.speed
        gameState.playerHealth = playerCombatState.health
        gameState.playerPosition = playerBikeState.distance >= rival.bikeState.distance ? 1 : 2
        gameState.raceProgress = max(0, min(1, playerBikeState.distance / GameConstants.raceDistance))
        gameState.nitroMeter = nitroMeter
    }

    private func checkFinish() {
        guard playerBikeState.distance >= GameConstants.raceDistance else { return }
        raceEnded = true
        let didWin = gameState.playerPosition == 1
        let result = RaceResult(
            position: gameState.playerPosition,
            totalRiders: 2,
            elapsedTime: Date().timeIntervalSince(startTime),
            didWin: didWin
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
