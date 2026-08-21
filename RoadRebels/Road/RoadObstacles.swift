import RealityKit
import UIKit
import simd

/// A fixed point along the route where driving through launches the bike
/// airborne (mega-spec's "perform stunts" ask) — placed once, checked for a
/// distance crossing each frame rather than treated as a collidable hazard.
struct RampPlacement {
    let distance: Float
    let laneOffset: Float
}

/// Jersey barrier — a stationary, collidable street obstacle distinct from
/// traffic (mega-spec "real life obstacles" / construction-zone flavor).
struct BarrierPlacement {
    let distance: Float
    let laneOffset: Float
}

enum RoadObstacles {
    static func buildRamp(spline: RoadSpline, placement: RampPlacement) -> Entity {
        let t = spline.transform(atDistance: placement.distance, lateralOffset: placement.laneOffset)
        let ramp = Entity()

        let deck = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(3.0, 0.2, 4.2), cornerRadius: 0.04),
            materials: [SimpleMaterial(color: UIColor(white: 0.28, alpha: 1), isMetallic: false)]
        )
        deck.transform.rotation = simd_quatf(angle: -0.38, axis: SIMD3<Float>(1, 0, 0))
        deck.position = SIMD3<Float>(0, 0.55, -0.6)
        ramp.addChild(deck)

        for stripeX: Float in [-1.1, 0, 1.1] {
            let stripe = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.3, 0.22, 4.3), cornerRadius: 0.02),
                materials: [SimpleMaterial(color: .systemYellow, isMetallic: false)]
            )
            stripe.transform.rotation = simd_quatf(angle: -0.38, axis: SIMD3<Float>(1, 0, 0))
            stripe.position = SIMD3<Float>(stripeX, 0.56, -0.6)
            ramp.addChild(stripe)
        }

        let wedge = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(3.0, 0.9, 0.4), cornerRadius: 0.04),
            materials: [SimpleMaterial(color: UIColor(white: 0.2, alpha: 1), isMetallic: false)]
        )
        wedge.position = SIMD3<Float>(0, 0.45, -2.6)
        ramp.addChild(wedge)

        ramp.position = t.position
        ramp.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
        return ramp
    }

    static func buildBarrier(spline: RoadSpline, placement: BarrierPlacement) -> Entity {
        let t = spline.transform(atDistance: placement.distance, lateralOffset: placement.laneOffset)
        let barrier = Entity()

        let body = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(3.0, 0.8, 0.5), cornerRadius: 0.1),
            materials: [SimpleMaterial(color: UIColor(white: 0.85, alpha: 1), isMetallic: false)]
        )
        body.position.y = 0.4
        barrier.addChild(body)

        for stripeX: Float in [-1.0, 0, 1.0] {
            let stripe = ModelEntity(
                mesh: .generateBox(size: SIMD3<Float>(0.5, 0.82, 0.52)),
                materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)]
            )
            stripe.position = SIMD3<Float>(stripeX, 0.41, 0)
            barrier.addChild(stripe)
        }

        let collisionShape = ShapeResource.generateBox(size: SIMD3<Float>(3.0, 0.8, 0.5))
        barrier.components.set(CollisionComponent(shapes: [collisionShape]))
        barrier.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))

        barrier.position = t.position
        barrier.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
        return barrier
    }
}
