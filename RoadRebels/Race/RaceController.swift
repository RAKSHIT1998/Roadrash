import RealityKit
import UIKit
import Foundation

/// Orchestrates one race: owns the road, player, a small field of archetyped
/// rivals, traffic, obstacles, and camera, and drives them all from a single
/// fixed-step update. This is the "everything in one place" controller;
/// Career's multi-race structure (Phase 4) wraps this rather than replacing it.
@MainActor
final class RaceController {
    let sceneAnchor: AnchorEntity
    let cameraController: ChaseCameraController
    let regionTheme: RegionTheme

    private let spline: RoadSpline
    private let playerEntity: BikeEntity
    private let rivals: [EnemyRider]
    private let traffic: TrafficManager
    private let input: BikeInputController
    private let gameState: GameState
    private let nitroTrail: Entity
    private let ramps: [RampPlacement]
    private let barriers: [BarrierPlacement]

    private var playerBikeState = BikeState(distance: 0, lateralOffset: -1.5)
    private var playerCombatState = RiderCombatState()
    private var trafficCollisionCooldown: Float = 0
    private var barrierCollisionCooldown: Float = 0
    private var startTime: Date = Date()
    private var raceEnded = false
    private var wasAirborne = false

    private var nitroMeter: Float = 0
    private var wasNitroActive = false
    private var wasPlayerLeading = false

    private var hadAnyCollision = false
    private var tookAnyDamage = false
    private var nearMissCount = 0

    private let config: RaceConfiguration
    private let tuning: BikeTuning

    init(input: BikeInputController, gameState: GameState, config: RaceConfiguration, tuning: BikeTuning = .default, appearance: BikeAppearance = .default) {
        self.input = input
        self.gameState = gameState
        self.config = config
        self.tuning = tuning
        let regionID = config.careerRaceID.flatMap(CareerContent.region(forRaceID:))?.id
        self.regionTheme = RegionThemeCatalog.theme(forRegionID: regionID)
        self.spline = .generate(totalLength: config.distance + 150)
        self.sceneAnchor = AnchorEntity(world: .zero)
        self.playerEntity = BikeEntity(role: .player, appearance: appearance)
        self.rivals = Self.makeRivals(from: config.rivals)
        self.traffic = TrafficManager(spline: spline, parent: sceneAnchor)
        self.ramps = Self.makeRamps(routeLength: config.distance)
        self.barriers = Self.makeBarriers(routeLength: config.distance, ramps: ramps)
        self.cameraController = ChaseCameraController(initialPosition: SIMD3<Float>(0, GameConstants.cameraHeight, GameConstants.cameraFollowDistance))
        self.nitroTrail = ImpactEffects.attachNitroTrail(to: playerEntity.root)

        sceneAnchor.addChild(RoadBuilder.buildRoadEntity(spline: spline, finishDistance: config.distance))
        sceneAnchor.addChild(SceneryBuilder.buildProps(spline: spline, from: 0, to: spline.totalLength, theme: regionTheme))
        for ramp in ramps {
            sceneAnchor.addChild(RoadObstacles.buildRamp(spline: spline, placement: ramp))
        }
        for barrier in barriers {
            sceneAnchor.addChild(RoadObstacles.buildBarrier(spline: spline, placement: barrier))
        }
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

    private static func makeRamps(routeLength: Float) -> [RampPlacement] {
        guard routeLength > 400 else { return [] }
        let laneOffsets: [Float] = [-4.6, 0, 4.6]
        var ramps: [RampPlacement] = []
        var distance: Float = 220
        while distance < routeLength - 120 {
            ramps.append(RampPlacement(distance: distance, laneOffset: laneOffsets.randomElement() ?? 0))
            distance += GameConstants.rampSpacing + Float.random(in: -40...40)
        }
        return ramps
    }

    private static func makeBarriers(routeLength: Float, ramps: [RampPlacement]) -> [BarrierPlacement] {
        guard routeLength > 300 else { return [] }
        let laneOffsets: [Float] = [-4.6, 0, 4.6]
        var barriers: [BarrierPlacement] = []
        var distance: Float = 160
        while distance < routeLength - 100 {
            if !ramps.contains(where: { abs($0.distance - distance) < 30 }) {
                barriers.append(BarrierPlacement(distance: distance, laneOffset: laneOffsets.randomElement() ?? 0))
            }
            distance += GameConstants.barrierSpacing + Float.random(in: -30...30)
        }
        return barriers
    }

    /// A key sun light (with shadows) plus a dim, opposite-angled fill light
    /// so shadowed surfaces aren't pure black — cheap depth/quality win with
    /// no new assets.
    private func addSun() {
        var light = DirectionalLightComponent(color: regionTheme.sunColor, intensity: regionTheme.sunIntensity)
        light.isRealWorldProxy = false
        let sunEntity = Entity()
        sunEntity.components.set(light)
        sunEntity.components.set(DirectionalLightComponent.Shadow(maximumDistance: 60, depthBias: 1.5))
        sunEntity.look(at: SIMD3<Float>(0.4, -1, 0.3), from: SIMD3<Float>(0, 50, 0), relativeTo: nil)
        sceneAnchor.addChild(sunEntity)

        var fill = DirectionalLightComponent(color: .white, intensity: regionTheme.sunIntensity * 0.18)
        fill.isRealWorldProxy = false
        let fillEntity = Entity()
        fillEntity.components.set(fill)
        fillEntity.look(at: SIMD3<Float>(-0.4, -0.5, -0.3), from: SIMD3<Float>(0, 30, 0), relativeTo: nil)
        sceneAnchor.addChild(fillEntity)
    }

    func start() {
        startTime = Date()
        raceEnded = false
        playerBikeState = BikeState(distance: 0, lateralOffset: -1.5)
        playerCombatState = RiderCombatState(health: GameConstants.riderMaxHealth + tuning.maxHealthBonus)
        nitroMeter = 0
        wasNitroActive = false
        wasPlayerLeading = false
        wasAirborne = false
        hadAnyCollision = false
        tookAnyDamage = false
        nearMissCount = 0
        gameState.playerMaxHealth = GameConstants.riderMaxHealth + tuning.maxHealthBonus
    }

    func update(dt: Float) {
        guard !raceEnded else { return }

        let previousDistance = playerBikeState.distance
        stepPlayer(dt: dt)
        stepRamps(previousDistance: previousDistance)
        stepLanding()
        stepCombat()
        stepTrafficAndCollisions(dt: dt)
        stepBarrierCollisions(dt: dt)
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
        control.jumpRequested = input.consumeJumpRequest()
        playerBikeState = BikePhysics.step(state: playerBikeState, control: control, dt: dt, tuning: tuning)
        playerCombatState = CombatResolver.tickCooldown(playerCombatState, dt: TimeInterval(dt))
    }

    /// Launches the player off any ramp their lane crossed this frame.
    private func stepRamps(previousDistance: Float) {
        guard !ramps.isEmpty else { return }
        for ramp in ramps {
            guard previousDistance < ramp.distance, playerBikeState.distance >= ramp.distance else { continue }
            guard abs(playerBikeState.lateralOffset - ramp.laneOffset) < GameConstants.rampLaneTolerance else { continue }
            playerBikeState = BikePhysics.applyRampLaunch(to: playerBikeState, launchSpeed: GameConstants.rampLaunchSpeed)
            cameraController.setNitroBoost(active: true)
            cameraController.addTrauma(0.2)
            HapticsService.shared.play(.nitroActivate)
            AudioService.shared.play(.nitro)
        }
    }

    /// Detects the airborne → grounded transition for a landing thump.
    private func stepLanding() {
        let isAirborne = playerBikeState.isAirborne
        if wasAirborne && !isAirborne {
            cameraController.addTrauma(0.4)
            cameraController.setNitroBoost(active: false)
            HapticsService.shared.play(.collision)
            AudioService.shared.play(.collision)
            ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
        }
        wasAirborne = isAirborne
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
        if Bool.random() { playerEntity.playPunchAnimation() } else { playerEntity.playKickAnimation() }
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
                trafficCollisionCooldown = 0.6
                hadAnyCollision = true
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

    /// Static jersey barriers — jumping over one (via a ramp) skips the hit.
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
            barrierCollisionCooldown = 0.6
            hadAnyCollision = true
            cameraController.addTrauma(0.6)
            HapticsService.shared.play(.collision)
            AudioService.shared.play(.collision)
            ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
            break
        }
    }

    private func stepRivals(dt: Float) {
        for rival in rivals {
            guard !rival.combatState.isDefeated else { continue }
            rival.update(playerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset, dt: dt)
            if let outcome = rival.attemptAttack(onPlayerDistance: playerBikeState.distance, playerLateral: playerBikeState.lateralOffset) {
                if Bool.random() { rival.entity.playPunchAnimation() } else { rival.entity.playKickAnimation() }
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
        tookAnyDamage = true
        cameraController.addTrauma(0.35)
        HapticsService.shared.play(.attackImpact)
        AudioService.shared.play(.collision)
        ImpactEffects.spawnHitSpark(at: playerEntity.root.position, in: sceneAnchor)
    }

    private func applyTransforms() {
        playerEntity.applyTransform(state: playerBikeState, spline: spline)
        playerEntity.updateEngineSound(speedFraction: playerBikeState.speed / GameConstants.bikeMaxSpeed)
        for rival in rivals {
            rival.applyTransform(spline: spline)
            rival.entity.updateEngineSound(speedFraction: rival.bikeState.speed / GameConstants.bikeMaxSpeed)
        }
    }

    private func updateCamera(dt: Float) {
        let t = spline.transform(atDistance: playerBikeState.distance, lateralOffset: playerBikeState.lateralOffset)
        let liftedPosition = t.position + SIMD3<Float>(0, playerBikeState.height, 0)
        cameraController.update(targetPosition: liftedPosition, targetForward: t.forward, dt: dt)
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
            creditsEarned: didWin ? config.creditReward : 0,
            hadAnyCollision: hadAnyCollision,
            tookAnyDamage: tookAnyDamage,
            nearMisses: nearMissCount
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
