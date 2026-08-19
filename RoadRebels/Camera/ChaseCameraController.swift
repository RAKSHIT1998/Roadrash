import RealityKit
import simd

/// Smoothed third-person chase camera with trauma-based shake and a nitro
/// FOV punch on top of the Phase 1 follow/lag/prediction behavior.
final class ChaseCameraController {
    /// Accessibility setting (mega-spec section 43): when true, shake and
    /// the nitro FOV punch are suppressed everywhere, not just in whichever
    /// controller instance is currently running a race.
    static var reducedMotionEnabled = false

    let cameraEntity: Entity
    private var smoothedPosition: SIMD3<Float>
    private var smoothedForward: SIMD3<Float>

    /// 0...1, decays over time; screen shake magnitude scales with trauma^2
    /// so small bumps barely register but big hits punch hard.
    private var trauma: Float = 0
    private var shakeSeed: Float = 0

    private var baseFOV: Float = 62
    private var currentFOV: Float = 62
    private var targetFOVBoost: Float = 0

    init(initialPosition: SIMD3<Float> = .zero, initialForward: SIMD3<Float> = SIMD3<Float>(0, 0, -1)) {
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent(near: 0.05, far: 3000, fieldOfViewInDegrees: baseFOV))
        self.cameraEntity = camera
        self.smoothedPosition = initialPosition
        self.smoothedForward = initialForward
        self.currentFOV = baseFOV
    }

    func addTrauma(_ amount: Float) {
        guard !Self.reducedMotionEnabled else { return }
        trauma = min(1, trauma + amount)
    }

    func setNitroBoost(active: Bool) {
        targetFOVBoost = (active && !Self.reducedMotionEnabled) ? 14 : 0
    }

    /// `targetPosition`/`targetForward` describe the bike being followed.
    func update(targetPosition: SIMD3<Float>, targetForward: SIMD3<Float>, dt: Float) {
        let desiredPosition = targetPosition
            - targetForward * GameConstants.cameraFollowDistance
            + SIMD3<Float>(0, GameConstants.cameraHeight, 0)

        let posBlend = min(1, GameConstants.cameraPositionSmoothing * dt)
        smoothedPosition += (desiredPosition - smoothedPosition) * posBlend

        let rotBlend = min(1, GameConstants.cameraRotationSmoothing * dt)
        smoothedForward = simd_normalize(smoothedForward + (targetForward - smoothedForward) * rotBlend)

        shakeSeed += dt * 40
        let shakeMagnitude = trauma * trauma
        let shakeOffset = SIMD3<Float>(
            sin(shakeSeed * 1.7) * shakeMagnitude * 0.35,
            sin(shakeSeed * 2.3 + 1.3) * shakeMagnitude * 0.25,
            0
        )
        trauma = max(0, trauma - dt * 1.6)

        let lookTarget = targetPosition + SIMD3<Float>(0, GameConstants.cameraLookAheadHeight, 0)
        let eyePosition = smoothedPosition + shakeOffset
        cameraEntity.position = eyePosition
        cameraEntity.look(at: lookTarget, from: eyePosition, relativeTo: nil)

        currentFOV += (baseFOV + targetFOVBoost - currentFOV) * min(1, 4 * dt)
        if var component = cameraEntity.components[PerspectiveCameraComponent.self] {
            component.fieldOfViewInDegrees = currentFOV
            cameraEntity.components.set(component)
        }
    }
}
