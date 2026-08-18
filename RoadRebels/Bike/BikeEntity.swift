import RealityKit
import UIKit
import simd

enum BikeRole {
    case player
    case rival
}

/// Assembles a placeholder low-poly motorcycle out of procedural RealityKit
/// primitives. Structured so a real 3D asset can later replace `buildModel()`
/// without touching any gameplay code that reads `BikeEntity.root`.
final class BikeEntity {
    let root: Entity
    private let bodyPitchNode: Entity
    private let role: BikeRole

    init(role: BikeRole) {
        self.role = role
        self.root = Entity()
        self.bodyPitchNode = Entity()
        root.addChild(bodyPitchNode)
        bodyPitchNode.addChild(Self.buildModel(role: role))

        let collisionShape = ShapeResource.generateBox(size: SIMD3<Float>(0.7, 1.1, 1.9))
        root.components.set(CollisionComponent(shapes: [collisionShape]))
        var physics = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        physics.isRotationLocked = (true, true, true)
        root.components.set(physics)
    }

    private static func buildModel(role: BikeRole) -> Entity {
        let container = Entity()
        let accentColor: UIColor = role == .player ? .systemRed : .systemBlue

        let bodyMesh = MeshResource.generateBox(size: SIMD3<Float>(0.55, 0.55, 1.7), cornerRadius: 0.08)
        let bodyMaterial = SimpleMaterial(color: accentColor, isMetallic: true)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        body.position = SIMD3<Float>(0, 0.75, 0)
        container.addChild(body)

        let seatMesh = MeshResource.generateBox(size: SIMD3<Float>(0.4, 0.15, 0.6), cornerRadius: 0.04)
        let seat = ModelEntity(mesh: seatMesh, materials: [SimpleMaterial(color: .black, isMetallic: false)])
        seat.position = SIMD3<Float>(0, 1.05, 0.2)
        container.addChild(seat)

        let wheelMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let wheelMesh = MeshResource.generateCylinder(height: 0.12, radius: 0.32)
        let frontWheel = ModelEntity(mesh: wheelMesh, materials: [wheelMaterial])
        frontWheel.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
        frontWheel.position = SIMD3<Float>(0, 0.32, 0.85)
        container.addChild(frontWheel)

        let rearWheel = ModelEntity(mesh: wheelMesh, materials: [wheelMaterial])
        rearWheel.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
        rearWheel.position = SIMD3<Float>(0, 0.32, -0.85)
        container.addChild(rearWheel)

        let torsoMesh = MeshResource.generateBox(size: SIMD3<Float>(0.34, 0.55, 0.3), cornerRadius: 0.1)
        let torso = ModelEntity(mesh: torsoMesh, materials: [SimpleMaterial(color: .darkGray, isMetallic: false)])
        torso.position = SIMD3<Float>(0, 1.35, 0.05)
        container.addChild(torso)

        let headMesh = MeshResource.generateSphere(radius: 0.16)
        let head = ModelEntity(mesh: headMesh, materials: [SimpleMaterial(color: .darkGray, isMetallic: false)])
        head.position = SIMD3<Float>(0, 1.72, 0.05)
        container.addChild(head)

        return container
    }

    /// Places the bike on the road spline given its pure-physics state, and
    /// applies a cosmetic lean rotation on top of the road heading.
    func applyTransform(state: BikeState, spline: RoadSpline) {
        let t = spline.transform(atDistance: state.distance, lateralOffset: state.lateralOffset)
        root.position = t.position
        root.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
        bodyPitchNode.transform.rotation = simd_quatf(angle: state.lean, axis: SIMD3<Float>(0, 0, 1))
    }
}
