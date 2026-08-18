import RealityKit
import UIKit
import simd

/// Placeholder civilian vehicle: a colored box on the road spline. Phase 1
/// keeps a single silhouette with varied color/scale to stand in for the
/// car/SUV/van/truck roster described in the mega-spec (section 14); swapping
/// in real per-type meshes later only touches `buildModel`.
final class TrafficVehicle {
    let root: Entity
    var distance: Float
    let laneOffset: Float
    var speed: Float

    init(distance: Float, laneOffset: Float, speed: Float) {
        self.distance = distance
        self.laneOffset = laneOffset
        self.speed = speed
        self.root = TrafficVehicle.buildModel()

        let collisionShape = ShapeResource.generateBox(size: SIMD3<Float>(1.8, 1.4, 3.6))
        root.components.set(CollisionComponent(shapes: [collisionShape]))
        root.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic))
    }

    private static func buildModel() -> Entity {
        let palette: [UIColor] = [.systemGray, .systemOrange, .systemGreen, .systemTeal, .white]
        let color = palette.randomElement() ?? .systemGray
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(1.8, 1.3, 3.6), cornerRadius: 0.12)
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, isMetallic: false)])
        entity.position.y = 0.65
        let container = Entity()
        container.addChild(entity)
        return container
    }

    func applyTransform(spline: RoadSpline) {
        let t = spline.transform(atDistance: distance, lateralOffset: laneOffset)
        root.position = t.position
        root.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
    }
}
