import Foundation

/// Central tuning values for Phase 1. Deliberately arcade-scaled, not real-world units.
enum GameConstants {
    // Bike physics
    static let bikeMaxSpeed: Float = 42.0          // m/s
    static let bikeAcceleration: Float = 18.0       // m/s^2
    static let bikeBrakeDeceleration: Float = 30.0  // m/s^2
    static let bikeDrag: Float = 3.0                // passive deceleration m/s^2
    static let bikeSteerRate: Float = 2.4           // radians/sec at full steer input
    static let bikeMaxLean: Float = 0.5             // radians
    static let bikeLeanResponse: Float = 6.0
    static let bikeHalfLaneRange: Float = 6.0       // lateral clamp either side of road center

    // Camera
    static let cameraFollowDistance: Float = 7.0
    static let cameraHeight: Float = 3.2
    static let cameraLookAheadHeight: Float = 1.0
    static let cameraPositionSmoothing: Float = 6.0
    static let cameraRotationSmoothing: Float = 5.0

    // Road
    static let roadLength: Float = 1200.0
    static let roadWidth: Float = 14.0
    static let laneCount: Int = 3

    // Race
    static let raceDistance: Float = 1000.0
    static let finishLineTolerance: Float = 5.0

    // Traffic
    static let trafficVehicleCount: Int = 8
    static let trafficMinSpeed: Float = 8.0
    static let trafficMaxSpeed: Float = 16.0
    static let trafficSpawnAheadDistance: Float = 900.0
    static let trafficSafeSpawnGap: Float = 60.0

    // Combat
    static let attackRange: Float = 2.6
    static let attackCooldown: TimeInterval = 0.6
    static let attackDamage: Float = 20.0
    static let attackKnockback: Float = 6.0
    static let riderMaxHealth: Float = 100.0

    // Enemy
    static let enemyCatchUpSpeed: Float = 40.0
    static let enemyAttackRange: Float = 3.0

    // Simulation
    static let fixedTimestep: Double = 1.0 / 60.0
}
