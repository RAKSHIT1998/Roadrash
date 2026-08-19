import RealityKit
import UIKit
import Foundation

/// The "Highway Rush" endless mode (mega-spec section 26): a rolling road
/// with no finish line, ramping traffic density/speed over time, scored by
/// distance and near-misses. No rivals/combat here — Career/Quick Race own
/// that side of the game; this mode is about survival and skillful dodging.
@MainActor
final class EndlessController {
    let sceneAnchor: AnchorEntity
    let cameraController: ChaseCameraController

    private let spline: RoadSpline
    private let playerEntity: BikeEntity
    private let traffic: TrafficManager
    private let input: BikeInputController
    private let gameState: GameState
    private let nitroTrail: Entity
    private let tuning: BikeTuning

    private var playerBikeState = BikeState(distance: 0, lateralOffset: 0)
    private var playerCombatState = RiderCombatState()
    private var trafficCollisionCooldown: Float = 0
    private var nitroMeter: Float = 0
    private var wasNitroActive = false

    private var elapsedTime: Float = 0
    private var timeSinceLastRamp: Float = 0
    private var nearMissCount = 0
    private var runEnded = false

    init(input: BikeInputController, gameState: GameState, tuning: BikeTuning = .default) {
        self.input = input
        self.gameState = gameState
        self.tuning = tuning
        self.spline = .generate(totalLength: 700)
        self.sceneAnchor = AnchorEntity(world: .zero)
        self.playerEntity = BikeEntity(role: .player)
        self.traffic = TrafficManager(spline: spline, parent: sceneAnchor)
        self.cameraController = ChaseCameraController(initialPosition: SIMD3<Float>(0, GameConstants.cameraHeight, GameConstants.cameraFollowDistance))
        self.nitroTrail = ImpactEffects.attachNitroTrail(to: playerEntity.root)

        sceneAnchor.addChild(RoadBuilder.buildRoadChunk(spline: spline, from: 0, to: spline.totalLength))
        sceneAnchor.addChild(playerEntity.root)
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
        runEnded = false
        playerBikeState = BikeState(distance: 0, lateralOffset: 0)
        playerCombatState = RiderCombatState(health: GameConstants.riderMaxHealth + tuning.maxHealthBonus)
        nitroMeter = 0
        wasNitroActive = false
        elapsedTime = 0
        timeSinceLastRamp = 0
        nearMissCount = 0
        gameState.playerMaxHealth = GameConstants.riderMaxHealth + tuning.maxHealthBonus
    }

    func update(dt: Float) {
        guard !runEnded else { return }
        elapsedTime += dt

        stepPlayer(dt: dt)
        stepRoadExtension()
        stepDifficultyRamp(dt: dt)
        stepTrafficAndCollisions(dt: dt)

        playerEntity.applyTransform(state: playerBikeState, spline: spline)
        let t = spline.transform(atDistance: playerBikeState.distance, lateralOffset: playerBikeState.lateralOffset)
        cameraController.update(targetPosition: t.position, targetForward: t.forward, dt: dt)

        publishTelemetry()
        checkEnd()
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

    private func stepRoadExtension() {
        while playerBikeState.distance > spline.totalLength - GameConstants.endlessRoadExtendBuffer {
            let previousEnd = spline.totalLength
            let newElement = spline.appendRandomSegment()
            sceneAnchor.addChild(RoadBuilder.buildRoadChunk(spline: spline, from: previousEnd, to: newElement.endDistance))
        }
    }

    private func stepDifficultyRamp(dt: Float) {
        timeSinceLastRamp += dt
        guard timeSinceLastRamp >= GameConstants.endlessDifficultyRampInterval else { return }
        timeSinceLastRamp = 0
        traffic.increaseDifficulty(speedBoost: GameConstants.endlessTrafficSpeedBoostPerRamp, cap: GameConstants.endlessTrafficSpeedCap)
        traffic.addVehicle(parent: sceneAnchor, aheadOfPlayer: playerBikeState.distance, maxCount: GameConstants.endlessMaxTrafficCount)
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
                playerCombatState = CombatResolver.applyDamage(playerCombatState, outcome: AttackOutcome(damage: 22, lateralKnockback: 0, speedLoss: 0))
                trafficCollisionCooldown = 0.6
                cameraController.addTrauma(0.55)
                HapticsService.shared.play(.collision)
                AudioService.shared.play(.collision)
                ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
                break
            }

            if !vehicle.hasTriggeredNearMiss && longitudinalGap < 3.5 && lateralGap >= 1.7 && lateralGap < 3.0 {
                vehicle.hasTriggeredNearMiss = true
                nearMissCount += 1
                nitroMeter = min(1, nitroMeter + GameConstants.nitroGainOnNearMiss)
                HapticsService.shared.play(.nearMiss)
            } else if longitudinalGap > 8 {
                vehicle.hasTriggeredNearMiss = false
            }
        }
    }

    private func publishTelemetry() {
        gameState.playerSpeed = playerBikeState.speed
        gameState.playerHealth = playerCombatState.health
        gameState.playerPosition = 1
        gameState.raceProgress = 0
        gameState.nitroMeter = nitroMeter
        gameState.endlessDistance = playerBikeState.distance
    }

    private var currentScore: Int {
        Int(playerBikeState.distance) + nearMissCount * GameConstants.endlessNearMissScore
    }

    private func checkEnd() {
        guard playerCombatState.isDefeated else { return }
        runEnded = true
        HapticsService.shared.play(.collision)
        AudioService.shared.play(.defeat)
        gameState.finishEndless(result: EndlessResult(
            distance: playerBikeState.distance,
            nearMisses: nearMissCount,
            score: currentScore
        ))
    }
}
