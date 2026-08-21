import RealityKit
import UIKit
import simd

/// The late-game threat in Endless mode: a police cruiser that spawns
/// behind the player once they've gone far enough and gives chase, lights
/// flashing. Catching the player (staying within bust range long enough)
/// ends the run — matches the mega-spec's "POLICE ESCAPE" race type
/// (section 6) as an emergent Endless-mode event rather than a separate mode.
final class PoliceCar {
    let entity: Entity
    var distance: Float
    var laneOffset: Float
    private(set) var speed: Float = 0

    private let redLight: Entity
    private let blueLight: Entity
    private var lightPhase: Float = 0

    init(startDistance: Float, laneOffset: Float) {
        self.distance = startDistance
        self.laneOffset = laneOffset

        let container = Entity()
        let body = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(1.9, 1.3, 3.8), cornerRadius: 0.12),
            materials: [SimpleMaterial(color: .white, isMetallic: false)]
        )
        body.position.y = 0.68
        container.addChild(body)

        let stripe = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(1.92, 0.3, 3.82)),
            materials: [SimpleMaterial(color: UIColor(red: 0.08, green: 0.1, blue: 0.5, alpha: 1), isMetallic: false)]
        )
        stripe.position.y = 0.68
        container.addChild(stripe)

        let bar = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.95, 0.12, 0.32), cornerRadius: 0.03),
            materials: [SimpleMaterial(color: UIColor(white: 0.05, alpha: 1), isMetallic: false)]
        )
        bar.position = SIMD3<Float>(0, 1.42, 0.2)
        container.addChild(bar)

        let redLight = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.4, 0.1, 0.28)), materials: [SimpleMaterial(color: .systemRed, isMetallic: false)])
        redLight.position = SIMD3<Float>(-0.24, 1.42, 0.2)
        container.addChild(redLight)
        self.redLight = redLight

        let blueLight = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.4, 0.1, 0.28)), materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
        blueLight.position = SIMD3<Float>(0.24, 1.42, 0.2)
        container.addChild(blueLight)
        self.blueLight = blueLight

        let wheelMesh = MeshResource.generateCylinder(height: 0.12, radius: 0.32)
        let wheelMaterial = SimpleMaterial(color: .black, isMetallic: false)
        for z: Float in [0.9, -0.9] {
            for x: Float in [-0.75, 0.75] {
                let wheel = ModelEntity(mesh: wheelMesh, materials: [wheelMaterial])
                wheel.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
                wheel.position = SIMD3<Float>(x, 0.32, z)
                container.addChild(wheel)
            }
        }

        self.entity = container
    }

    func update(dt: Float) {
        speed += (GameConstants.policeMaxSpeed - speed) * min(1, 1.4 * dt)
        distance += speed * dt

        lightPhase += dt
        let blink = lightPhase.truncatingRemainder(dividingBy: 0.3) < 0.15
        redLight.isEnabled = blink
        blueLight.isEnabled = !blink
    }

    func applyTransform(spline: RoadSpline) {
        let t = spline.transform(atDistance: distance, lateralOffset: laneOffset)
        entity.position = t.position
        entity.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))
    }
}
