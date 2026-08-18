import RealityKit
import Foundation

/// Owns a pooled set of traffic vehicles and keeps them cycling ahead of the
/// player. Pooling avoids the per-frame allocate/destroy churn called out as
/// a performance requirement in the mega-spec (section 40).
final class TrafficManager {
    private(set) var vehicles: [TrafficVehicle] = []
    private let laneOffsets: [Float]
    private let spline: RoadSpline

    init(spline: RoadSpline, parent: Entity) {
        self.spline = spline
        let laneWidth = GameConstants.roadWidth / Float(GameConstants.laneCount)
        self.laneOffsets = (0..<GameConstants.laneCount).map { lane in
            (Float(lane) - Float(GameConstants.laneCount - 1) / 2) * laneWidth
        }

        for _ in 0..<GameConstants.trafficVehicleCount {
            let vehicle = TrafficVehicle(
                distance: Float.random(in: 40...GameConstants.trafficSpawnAheadDistance),
                laneOffset: laneOffsets.randomElement() ?? 0,
                speed: Float.random(in: GameConstants.trafficMinSpeed...GameConstants.trafficMaxSpeed)
            )
            vehicles.append(vehicle)
            parent.addChild(vehicle.root)
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
        vehicle.speed = Float.random(in: GameConstants.trafficMinSpeed...GameConstants.trafficMaxSpeed)
        vehicle.hasTriggeredNearMiss = false
    }
}
