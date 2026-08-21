import RealityKit
import Foundation

/// Owns a pooled set of traffic vehicles and stationary hazards (cones/
/// barrels) and keeps them cycling ahead of the player. Pooling avoids the
/// per-frame allocate/destroy churn called out as a performance requirement
/// in the mega-spec (section 40). Endless mode grows the pool and raises the
/// speed range over time via `addVehicle`/`increaseDifficulty` instead of
/// building a new manager.
final class TrafficManager {
    private(set) var vehicles: [TrafficVehicle] = []
    private let laneOffsets: [Float]
    private let spline: RoadSpline

    private var minSpeed = GameConstants.trafficMinSpeed
    private var maxSpeed = GameConstants.trafficMaxSpeed

    init(spline: RoadSpline, parent: Entity) {
        self.spline = spline
        let laneWidth = GameConstants.roadWidth / Float(GameConstants.laneCount)
        self.laneOffsets = (0..<GameConstants.laneCount).map { lane in
            (Float(lane) - Float(GameConstants.laneCount - 1) / 2) * laneWidth
        }

        for _ in 0..<GameConstants.trafficVehicleCount {
            let kind = Self.randomKind()
            let vehicle = TrafficVehicle(
                distance: Float.random(in: 40...GameConstants.trafficSpawnAheadDistance),
                laneOffset: laneOffsets.randomElement() ?? 0,
                speed: kind.isStationaryHazard ? 0 : Float.random(in: minSpeed...maxSpeed),
                kind: kind
            )
            vehicles.append(vehicle)
            parent.addChild(vehicle.root)
        }
    }

    /// Weighted so the road still reads primarily as traffic, with cones and
    /// barrels as an occasional extra thing to dodge (mega-spec's "various
    /// things that happen on the street").
    private static func randomKind() -> TrafficVehicleKind {
        switch Float.random(in: 0...1) {
        case ..<0.76: return .car
        case ..<0.90: return .cone
        default: return .barrel
        }
    }

    /// Advances all vehicles and recycles any that fall behind the player or
    /// run off the end of the spline back out ahead of the player.
    func update(playerDistance: Float, dt: Float) {
        for vehicle in vehicles {
            vehicle.distance += vehicle.speed * dt

            let fellBehind = vehicle.distance < playerDistance - 30
            let ranOffRoad = vehicle.distance > spline.totalLength
            if fellBehind || ranOffRoad {
                respawnAhead(vehicle, playerDistance: playerDistance)
            }
            vehicle.applyTransform(spline: spline)
        }
    }

    private func respawnAhead(_ vehicle: TrafficVehicle, playerDistance: Float) {
        var candidate = playerDistance + Float.random(in: GameConstants.trafficSafeSpawnGap...GameConstants.trafficSpawnAheadDistance)
        candidate = min(candidate, spline.totalLength - 5)
        vehicle.distance = max(candidate, playerDistance + GameConstants.trafficSafeSpawnGap)
        vehicle.speed = vehicle.kind.isStationaryHazard ? 0 : Float.random(in: minSpeed...maxSpeed)
        vehicle.hasTriggeredNearMiss = false
    }

    /// Endless mode: raises the traffic speed band, capped so it stays
    /// dodgeable rather than becoming unfair.
    func increaseDifficulty(speedBoost: Float, cap: Float) {
        minSpeed = min(minSpeed + speedBoost, cap)
        maxSpeed = min(maxSpeed + speedBoost, cap * 1.3)
    }

    /// Endless mode: grows the pool as the run gets harder, up to `maxCount`.
    func addVehicle(parent: Entity, aheadOfPlayer playerDistance: Float, maxCount: Int) {
        guard vehicles.count < maxCount else { return }
        let kind = Self.randomKind()
        let vehicle = TrafficVehicle(
            distance: playerDistance + Float.random(in: GameConstants.trafficSafeSpawnGap...GameConstants.trafficSpawnAheadDistance),
            laneOffset: laneOffsets.randomElement() ?? 0,
            speed: kind.isStationaryHazard ? 0 : Float.random(in: minSpeed...maxSpeed),
            kind: kind
        )
        vehicles.append(vehicle)
        parent.addChild(vehicle.root)
    }
}
