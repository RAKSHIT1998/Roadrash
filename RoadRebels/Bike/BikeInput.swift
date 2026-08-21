import Foundation
import CoreGraphics

/// Normalized control values produced by touch input, consumed by BikePhysics.
struct BikeControlState {
    var steer: Float = 0       // -1 (left) ... 1 (right)
    var throttle: Bool = false
    var brake: Bool = false
    var attackRequested: Bool = false
    var nitroHeld: Bool = false
    var jumpRequested: Bool = false
    /// Set by RaceController (not the input layer) once the nitro meter has
    /// been checked — distinct from `nitroHeld`, which is just the raw touch.
    var nitroActive: Bool = false
}

/// Translates raw touch gestures (see UI/RaceControlsOverlay) into a BikeControlState.
/// Left half of screen: horizontal drag = steer, auto-throttle while racing.
/// Right half: upper tap = attack, lower tap = brake, long-press = nitro.
/// On-screen LEFT/RIGHT/JUMP buttons (RaceStuntControls) offer the same
/// steer/jump inputs with a visible, discrete control for players who'd
/// rather tap than swipe.
@MainActor
final class BikeInputController: ObservableObject {
    @Published private(set) var state = BikeControlState(throttle: true)

    func updateSteer(fromDragTranslationX dx: CGFloat, screenWidth: CGFloat) {
        let normalized = Float(dx / (screenWidth * 0.35))
        state.steer = max(-1, min(1, normalized))
    }

    func resetSteer() {
        state.steer = 0
    }

    /// Sets steer directly to full left/right — used by the on-screen arrow
    /// buttons, which are discrete rather than a proportional drag.
    func setSteerButton(_ direction: Float) {
        state.steer = max(-1, min(1, direction))
    }

    func setBraking(_ braking: Bool) {
        state.brake = braking
    }

    func setNitroHeld(_ held: Bool) {
        state.nitroHeld = held
    }

    func requestAttack() {
        state.attackRequested = true
    }

    /// Called once per simulation step after the request has been consumed.
    func consumeAttackRequest() -> Bool {
        guard state.attackRequested else { return false }
        state.attackRequested = false
        return true
    }

    func requestJump() {
        state.jumpRequested = true
    }

    func consumeJumpRequest() -> Bool {
        guard state.jumpRequested else { return false }
        state.jumpRequested = false
        return true
    }
}
