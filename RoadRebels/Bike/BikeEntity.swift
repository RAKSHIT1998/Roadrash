import RealityKit
import UIKit
import simd

enum BikeRole {
    case player
    case rival
}

/// Assembles a placeholder low-poly motorcycle + articulated rider out of
/// procedural RealityKit primitives — no real 3D character assets exist to
/// swap in, so the rider is built as a jointed figure (shoulder/hip pivots)
/// so combat and stunts read as motion, not just a static mannequin.
/// Structured so real 3D assets can later replace `buildModel()` without
/// touching any gameplay code that reads `BikeEntity.root`.
@MainActor
final class BikeEntity {
    let root: Entity
    private let bodyPitchNode: Entity
    private let role: BikeRole

    private let rightShoulderPivot: Entity
    private let rightHipPivot: Entity
    private var engineAudio: AudioPlaybackController?

    private static let armRestRotation = simd_quatf(angle: 0.35, axis: SIMD3<Float>(1, 0, 0))
    private static let armStrikeRotation = simd_quatf(angle: -1.7, axis: SIMD3<Float>(1, 0, 0))
    private static let legRestRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 0, 1))
    private static let legKickRotation = simd_quatf(angle: -1.1, axis: SIMD3<Float>(0, 0, 1))

    init(role: BikeRole) {
        self.role = role
        self.root = Entity()
        self.bodyPitchNode = Entity()
        root.addChild(bodyPitchNode)

        let rider = BikeEntity.RiderPivots()
        bodyPitchNode.addChild(Self.buildModel(role: role, rider: rider))
        self.rightShoulderPivot = rider.rightShoulder
        self.rightHipPivot = rider.rightHip

        let collisionShape = ShapeResource.generateBox(size: SIMD3<Float>(0.7, 1.1, 1.9))
        root.components.set(CollisionComponent(shapes: [collisionShape]))
        var physics = PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        physics.isRotationLocked = (true, true, true)
        root.components.set(physics)

        startEngineAudio()
    }

    /// A looping, positionally-spatialized engine sound attached to this
    /// bike — RealityKit pans/attenuates it by distance from the camera on
    /// its own, so it's real 3D audio, not a flat stereo loop. Pitch/volume
    /// are driven by `updateEngineSound(speedFraction:)` every frame.
    private func startEngineAudio() {
        guard let url = Bundle.main.url(forResource: "engineRev", withExtension: "wav") else { return }
        root.components.set(SpatialAudioComponent(gain: -18))
        Task { [weak self] in
            guard let self, let resource = try? await AudioFileResource(
                contentsOf: url, withName: "engineRev-\(self.role)-\(ObjectIdentifier(self.root))",
                configuration: .init(shouldLoop: true)
            ) else { return }
            let controller = self.root.prepareAudio(resource)
            controller.play()
            self.engineAudio = controller
        }
    }

    /// `speedFraction` is 0...1 of the bike's max speed — pitch and volume
    /// both rise with it, the classic racing-game engine feel.
    func updateEngineSound(speedFraction: Float) {
        guard let controller = engineAudio else { return }
        let clamped = max(0, min(1, speedFraction))
        let muted = AudioService.shared.isMuted
        controller.speed = Double(0.65 + clamped * 1.55)
        controller.gain = muted ? -80 : Double(-16 + clamped * 10) + Double(AudioService.shared.sfxVolume - 1) * 12
    }

    private struct RiderPivots {
        let rightShoulder = Entity()
        let rightHip = Entity()
    }

    private static func buildModel(role: BikeRole, rider: RiderPivots) -> Entity {
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

        container.addChild(buildRider(role: role, pivots: rider))

        return container
    }

    /// A jointed rider: torso + head fixed to the bike, two shoulder pivots
    /// (right one is the "punch" arm), two hip pivots (right one is the
    /// "kick" leg). Left limbs stay in a resting grip/foot-peg pose.
    private static func buildRider(role: BikeRole, pivots: RiderPivots) -> Entity {
        let rider = Entity()
        let suitColor: UIColor = role == .player ? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1) : UIColor(red: 0.14, green: 0.12, blue: 0.20, alpha: 1)
        let skinColor = UIColor(red: 0.75, green: 0.55, blue: 0.42, alpha: 1)

        let torso = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.34, 0.55, 0.3), cornerRadius: 0.1),
            materials: [SimpleMaterial(color: suitColor, isMetallic: false)]
        )
        torso.position = SIMD3<Float>(0, 1.35, 0.05)
        rider.addChild(torso)

        let helmetColor: UIColor = role == .player ? .systemRed : .systemBlue
        let head = ModelEntity(mesh: .generateSphere(radius: 0.16), materials: [SimpleMaterial(color: helmetColor, isMetallic: true)])
        head.position = SIMD3<Float>(0, 1.72, 0.05)
        rider.addChild(head)

        let visor = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.2, 0.08, 0.05), cornerRadius: 0.03),
            materials: [SimpleMaterial(color: UIColor(white: 0.08, alpha: 1), isMetallic: true)]
        )
        visor.position = SIMD3<Float>(0, 1.70, 0.20)
        rider.addChild(visor)

        // Right arm: the punch limb. Pivot sits at the shoulder joint so
        // rotating it swings the whole arm forward.
        pivots.rightShoulder.position = SIMD3<Float>(0.20, 1.5, 0.10)
        pivots.rightShoulder.transform.rotation = armRestRotation
        pivots.rightShoulder.addChild(buildLimbSegment(length: 0.42, radius: 0.07, color: suitColor, handColor: skinColor))
        rider.addChild(pivots.rightShoulder)

        // Left arm: static, gripping the handlebar.
        let leftShoulder = Entity()
        leftShoulder.position = SIMD3<Float>(-0.20, 1.5, 0.10)
        leftShoulder.transform.rotation = simd_quatf(angle: 1.1, axis: SIMD3<Float>(1, 0, 0))
        leftShoulder.addChild(buildLimbSegment(length: 0.38, radius: 0.07, color: suitColor, handColor: skinColor))
        rider.addChild(leftShoulder)

        // Right leg: the kick limb.
        pivots.rightHip.position = SIMD3<Float>(0.16, 1.05, -0.05)
        pivots.rightHip.transform.rotation = legRestRotation
        pivots.rightHip.addChild(buildLimbSegment(length: 0.5, radius: 0.09, color: suitColor, handColor: suitColor))
        rider.addChild(pivots.rightHip)

        // Left leg: static, on the foot peg.
        let leftHip = Entity()
        leftHip.position = SIMD3<Float>(-0.16, 1.05, -0.05)
        leftHip.addChild(buildLimbSegment(length: 0.5, radius: 0.09, color: suitColor, handColor: suitColor))
        rider.addChild(leftHip)

        return rider
    }

    /// A two-tone capsule-ish limb: the pivot is at the top (joint), the
    /// segment extends downward so rotating the parent pivot swings it like
    /// a real jointed limb instead of rotating in place.
    private static func buildLimbSegment(length: Float, radius: Float, color: UIColor, handColor: UIColor) -> Entity {
        let segment = Entity()
        let limb = ModelEntity(mesh: .generateCylinder(height: length, radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        limb.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        limb.position = SIMD3<Float>(0, 0, -length / 2)
        segment.addChild(limb)

        let end = ModelEntity(mesh: .generateSphere(radius: radius * 1.05), materials: [SimpleMaterial(color: handColor, isMetallic: false)])
        end.position = SIMD3<Float>(0, 0, -length)
        segment.addChild(end)
        return segment
    }

    /// Punches with the right arm — a quick forward swing and return,
    /// triggered whenever this rider lands an attack.
    func playPunchAnimation() {
        var strike = rightShoulderPivot.transform
        strike.rotation = Self.armStrikeRotation
        rightShoulderPivot.move(to: strike, relativeTo: rightShoulderPivot.parent, duration: 0.09, timingFunction: .easeOut)

        var rest = rightShoulderPivot.transform
        rest.rotation = Self.armRestRotation
        let pivot = rightShoulderPivot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pivot.move(to: rest, relativeTo: pivot.parent, duration: 0.22, timingFunction: .easeIn)
        }
    }

    /// Kicks outward with the right leg — an alternate strike animation for
    /// visual variety.
    func playKickAnimation() {
        var strike = rightHipPivot.transform
        strike.rotation = Self.legKickRotation
        rightHipPivot.move(to: strike, relativeTo: rightHipPivot.parent, duration: 0.1, timingFunction: .easeOut)

        var rest = rightHipPivot.transform
        rest.rotation = Self.legRestRotation
        let pivot = rightHipPivot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            pivot.move(to: rest, relativeTo: pivot.parent, duration: 0.24, timingFunction: .easeIn)
        }
    }

    /// Places the bike on the road spline given its pure-physics state,
    /// offsetting for jump height, and applies cosmetic lean/pitch on top.
    func applyTransform(state: BikeState, spline: RoadSpline) {
        let t = spline.transform(atDistance: state.distance, lateralOffset: state.lateralOffset)
        root.position = t.position + SIMD3<Float>(0, state.height, 0)
        root.transform.rotation = simd_quatf(angle: t.heading, axis: SIMD3<Float>(0, 1, 0))

        let airPitch: Float = state.isAirborne ? min(0.25, state.verticalVelocity * 0.03) : 0
        bodyPitchNode.transform.rotation = simd_quatf(angle: state.lean, axis: SIMD3<Float>(0, 0, 1))
            * simd_quatf(angle: airPitch, axis: SIMD3<Float>(1, 0, 0))
    }
}
