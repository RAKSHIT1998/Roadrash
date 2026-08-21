import RealityKit
import UIKit
import simd

enum TrafficVehicleKind {
    case car
    case cone
    case barrel

    /// Cones/barrels are stationary road hazards, not moving traffic — same
    /// collision/near-miss handling, just parked in a lane.
    var isStationaryHazard: Bool { self != .car }
}

/// A moving car or a stationary road hazard (cone/barrel) on the road
/// spline — placeholder geometry standing in for the mega-spec's car/SUV/
/// van/truck roster (section 14) and its street-obstacle asks; swapping in
/// real per-type meshes later only touches `buildModel`.
final class TrafficVehicle {
    let root: Entity
    let kind: TrafficVehicleKind
    var distance: Float
    let laneOffset: Float
    var speed: Float
    /// Debounces the near-miss reward so one slow pass alongside this vehicle
    /// only scores once, not every frame it stays close.
    var hasTriggeredNearMiss = false

    init(distance: Float, laneOffset: Float, speed: Float, kind: TrafficVehicleKind = .car) {
        self.distance = distance
        self.laneOffset = laneOffset
        self.speed = speed
        self.kind = kind
        self.root = TrafficVehicle.buildModel(kind: kind)

        let collisionSize: SIMD3<Float> = kind == .car
            ? SIMD3<Float>(1.8, 1.4, 3.6)
            : SIMD3<Float>(0.55, 0.9, 0.55)
        root.components.set(CollisionComponent(shapes: [.generateBox(size: collisionSize)]))
        root.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
    }

    private static func buildModel(kind: TrafficVehicleKind) -> Entity {
        switch kind {
        case .car: return buildCar()
        case .cone: return buildCone()
        case .barrel: return buildBarrel()
        }
    }

    private static func buildCar() -> Entity {
        let palette: [UIColor] = [.systemGray, .systemOrange, .systemGreen, .systemTeal, .white]
        let color = palette.randomElement() ?? .systemGray
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(1.8, 1.3, 3.6), cornerRadius: 0.12)
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.position.y = 0.65
        let container = Entity()
        container.addChild(entity)
        return container
    }

    private static func buildCone() -> Entity {
        let container = Entity()
        let base = ModelEntity(
            mesh: .generateCylinder(height: 0.06, radius: 0.28),
            materials: [SimpleMaterial(color: UIColor(white: 0.15, alpha: 1), isMetallic: false)]
        )
        base.position.y = 0.03
        container.addChild(base)

        let cone = ModelEntity(
            mesh: .generateCone(height: 0.55, radius: 0.2),
            materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)]
        )
        cone.position.y = 0.06 + 0.275
        container.addChild(cone)

        let stripe = ModelEntity(
            mesh: .generateCylinder(height: 0.08, radius: 0.13),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        stripe.position.y = 0.06 + 0.34
        container.addChild(stripe)
        return container
    }

    private static func buildBarrel() -> Entity {
        let container = Entity()
        let body = ModelEntity(
            mesh: .generateCylinder(height: 0.85, radius: 0.28),
            materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)]
        )
        body.position.y = 0.425
        container.addChild(body)

        for bandY: Float in [0.22, 0.62] {
            let band = ModelEntity(
                mesh: .generateCylinder(height: 0.1, radius: 0.285),
                materials: [SimpleMaterial(color: .white, isMetallic: false)]
            )
            band.position.y = bandY
            container.addChild(band)
        }
        return container
    }

    func applyTransform(spline: RoadSpline) {
        let t = spline.transform(atDistance: distance, lateralOffset: laneOffset)
        root.position = t.position
        root.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
    }
}
