import RealityKit
import UIKit
import Foundation

/// The "Highway Rush" endless mode (mega-spec section 26): a rolling road
/// with no finish line, ramping traffic density/speed over time, scored by
/// distance and near-misses. No rider-vs-rider combat here — Career/Quick
/// Race own that side of the game; this mode is about survival, dodging,
/// stunts, and — once you've gone far enough — outrunning the police.
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
    private var barrierCollisionCooldown: Float = 0
    private var nitroMeter: Float = 0
    private var wasNitroActive = false
    private var wasAirborne = false

    private var ramps: [RampPlacement] = []
    private var barriers: [BarrierPlacement] = []

    private var policeCar: PoliceCar?
    private var policeBustTimer: Float = 0
    private var endReason: EndlessEndReason = .wrecked

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
        sceneAnchor.addChild(SceneryBuilder.buildProps(spline: spline, from: 0, to: spline.totalLength, theme: .default))
        sceneAnchor.addChild(playerEntity.root)
        sceneAnchor.addChild(cameraController.cameraEntity)
        addSun()
    }

    private func addSun() {
        var light = DirectionalLightComponent(color: .white, intensity: 4000)
        light.isRealWorldProxy = false
        let sunEntity = Entity()
        sunEntity.components.set(light)
        sunEntity.components.set(DirectionalLightComponent.Shadow(maximumDistance: 60, depthBias: 1.5))
        sunEntity.look(at: SIMD3<Float>(0.4, -1, 0.3), from: SIMD3<Float>(0, 50, 0), relativeTo: nil)
        sceneAnchor.addChild(sunEntity)

        var fill = DirectionalLightComponent(color: .white, intensity: 700)
        fill.isRealWorldProxy = false
        let fillEntity = Entity()
        fillEntity.components.set(fill)
        fillEntity.look(at: SIMD3<Float>(-0.4, -0.5, -0.3), from: SIMD3<Float>(0, 30, 0), relativeTo: nil)
        sceneAnchor.addChild(fillEntity)
    }

    func start() {
        runEnded = false
        playerBikeState = BikeState(distance: 0, lateralOffset: 0)
        playerCombatState = RiderCombatState(health: GameConstants.riderMaxHealth + tuning.maxHealthBonus)
        nitroMeter = 0
        wasNitroActive = false
        wasAirborne = false
        elapsedTime = 0
        timeSinceLastRamp = 0
        nearMissCount = 0
        policeCar = nil
        policeBustTimer = 0
        endReason = .wrecked
        gameState.playerMaxHealth = GameConstants.riderMaxHealth + tuning.maxHealthBonus
    }

    func update(dt: Float) {
        guard !runEnded else { return }
        elapsedTime += dt

        let previousDistance = playerBikeState.distance
        stepPlayer(dt: dt)
        stepRamps(previousDistance: previousDistance)
        stepLanding()
        stepRoadExtension()
        stepDifficultyRamp(dt: dt)
        stepTrafficAndCollisions(dt: dt)
        stepBarrierCollisions(dt: dt)
        stepPolice(dt: dt)

        playerEntity.applyTransform(state: playerBikeState, spline: spline)
        playerEntity.updateEngineSound(speedFraction: playerBikeState.speed / GameConstants.bikeMaxSpeed)
        let t = spline.transform(atDistance: playerBikeState.distance, lateralOffset: playerBikeState.lateralOffset)
        let liftedPosition = t.position + SIMD3<Float>(0, playerBikeState.height, 0)
        cameraController.update(targetPosition: liftedPosition, targetForward: t.forward, dt: dt)

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
        control.jumpRequested = input.consumeJumpRequest()
        playerBikeState = BikePhysics.step(state: playerBikeState, control: control, dt: dt, tuning: tuning)
        playerCombatState = CombatResolver.tickCooldown(playerCombatState, dt: TimeInterval(dt))
    }

    private func stepRamps(previousDistance: Float) {
        guard !ramps.isEmpty else { return }
        for ramp in ramps {
            guard previousDistance < ramp.distance, playerBikeState.distance >= ramp.distance else { continue }
            guard abs(playerBikeState.lateralOffset - ramp.laneOffset) < GameConstants.rampLaneTolerance else { continue }
            playerBikeState = BikePhysics.applyRampLaunch(to: playerBikeState, launchSpeed: GameConstants.rampLaunchSpeed)
            cameraController.addTrauma(0.2)
            HapticsService.shared.play(.nitroActivate)
            AudioService.shared.play(.nitro)
        }
    }

    private func stepLanding() {
        let isAirborne = playerBikeState.isAirborne
        if wasAirborne && !isAirborne {
            cameraController.addTrauma(0.4)
            HapticsService.shared.play(.collision)
            AudioService.shared.play(.collision)
            ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
        }
        wasAirborne = isAirborne
    }

    private func stepRoadExtension() {
        while playerBikeState.distance > spline.totalLength - GameConstants.endlessRoadExtendBuffer {
            let previousEnd = spline.totalLength
            let newElement = spline.appendRandomSegment()
            sceneAnchor.addChild(RoadBuilder.buildRoadChunk(spline: spline, from: previousEnd, to: newElement.endDistance))
            sceneAnchor.addChild(SceneryBuilder.buildProps(spline: spline, from: previousEnd, to: newElement.endDistance, theme: .default))
            spawnObstacles(from: previousEnd, to: newElement.endDistance)
        }
    }

    private func spawnObstacles(from: Float, to: Float) {
        let laneOffsets: [Float] = [-4.6, 0, 4.6]
        if Float.random(in: 0...1) < 0.35, to - from > 80 {
            let ramp = RampPlacement(distance: Float.random(in: (from + 30)..<(to - 30)), laneOffset: laneOffsets.randomElement() ?? 0)
            ramps.append(ramp)
            sceneAnchor.addChild(RoadObstacles.buildRamp(spline: spline, placement: ramp))
        }
        if Float.random(in: 0...1) < 0.4, to - from > 60 {
            let barrier = BarrierPlacement(distance: Float.random(in: (from + 20)..<(to - 20)), laneOffset: laneOffsets.randomElement() ?? 0)
            barriers.append(barrier)
            sceneAnchor.addChild(RoadObstacles.buildBarrier(spline: spline, placement: barrier))
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
        guard !playerBikeState.isAirborne else { return }

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

    private func stepBarrierCollisions(dt: Float) {
        barrierCollisionCooldown = max(0, barrierCollisionCooldown - dt)
        guard !barriers.isEmpty, barrierCollisionCooldown <= 0, !playerBikeState.isAirborne else { return }

        for barrier in barriers {
            let longitudinalGap = abs(barrier.distance - playerBikeState.distance)
            let lateralGap = abs(barrier.laneOffset - playerBikeState.lateralOffset)
            guard longitudinalGap < 2.2, lateralGap < GameConstants.barrierLaneTolerance else { continue }

            let pushDirection: Float = playerBikeState.lateralOffset >= barrier.laneOffset ? 1 : -1
            playerBikeState = BikePhysics.applyKnockback(
                to: playerBikeState,
                lateralImpulse: pushDirection * 4.5 * tuning.collisionResistance,
                speedLoss: 18 * tuning.collisionResistance
            )
            playerCombatState = CombatResolver.applyDamage(playerCombatState, outcome: AttackOutcome(damage: 18, lateralKnockback: 0, speedLoss: 0))
            barrierCollisionCooldown = 0.6
            cameraController.addTrauma(0.6)
            HapticsService.shared.play(.collision)
            AudioService.shared.play(.collision)
            ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
            break
        }
    }

    /// Once the player has gone far enough, a police car spawns behind them
    /// and gives chase. It caps out just under the player's un-boosted top
    /// speed, so steady, clean driving keeps them just ahead and nitro
    /// opens a real gap — but a collision that costs speed lets it close in.
    private func stepPolice(dt: Float) {
        if policeCar == nil, playerBikeState.distance > GameConstants.policeChaseStartDistance {
            let spawnDistance = max(0, playerBikeState.distance - 45)
            let car = PoliceCar(startDistance: spawnDistance, laneOffset: playerBikeState.lateralOffset)
            policeCar = car
            sceneAnchor.addChild(car.entity)
            HapticsService.shared.play(.nearMiss)
        }

        guard let car = policeCar else { return }
        car.update(dt: dt)
        car.applyTransform(spline: spline)

        let gap = playerBikeState.distance - car.distance
        if gap <= GameConstants.policeBustDistance {
            policeBustTimer += dt
        } else {
            policeBustTimer = max(0, policeBustTimer - dt * 2)
        }
    }

    private func publishTelemetry() {
        gameState.playerSpeed = playerBikeState.speed
        gameState.playerHealth = playerCombatState.health
        gameState.playerPosition = 1
        gameState.raceProgress = 0
        gameState.nitroMeter = nitroMeter
        gameState.endlessDistance = playerBikeState.distance
        if let car = policeCar {
            gameState.endlessPoliceGap = playerBikeState.distance - car.distance
            gameState.endlessBustProgress = min(1, policeBustTimer / GameConstants.policeBustDuration)
        } else {
            gameState.endlessPoliceGap = nil
            gameState.endlessBustProgress = 0
        }
    }

    private var currentScore: Int {
        Int(playerBikeState.distance) + nearMissCount * GameConstants.endlessNearMissScore
    }

    private func checkEnd() {
        if policeBustTimer >= GameConstants.policeBustDuration {
            endReason = .busted
        } else if playerCombatState.isDefeated {
            endReason = .wrecked
        } else {
            return
        }

        runEnded = true
        HapticsService.shared.play(.collision)
        AudioService.shared.play(.defeat)
        gameState.finishEndless(result: EndlessResult(
            distance: playerBikeState.distance,
            nearMisses: nearMissCount,
            score: currentScore,
            reason: endReason
        ))
    }
}
