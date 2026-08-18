import RealityKit
import simd

/// Smoothed third-person chase camera. Phase 1 only implements follow +
/// lag/prediction; shake, FOV punch, and jump/impact reactions arrive in
/// Phase 2 as documented in the mega-spec.
final class ChaseCameraController {
    let cameraEntity: Entity
    private var smoothedPosition: SIMD3<Float>
    private var smoothedForward: SIMD3<Float>

    init(initialPosition: SIMD3<Float> = .zero, initialForward: SIMD3<Float> = SIMD3<Float>(0, 0, -1)) {
        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent(near: 0.05, far: 3000, fieldOfViewInDegrees: 62))
        self.cameraEntity = camera
        self.smoothedPosition = initialPosition
        self.smoothedForward = initialForward
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

        let lookTarget = targetPosition + SIMD3<Float>(0, GameConstants.cameraLookAheadHeight, 0)
        cameraEntity.position = smoothedPosition
        cameraEntity.look(at: lookTarget, from: smoothedPosition, relativeTo: nil)
    }
}
