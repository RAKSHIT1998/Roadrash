import Foundation
import CoreGraphics

/// Normalized control values produced by touch input, consumed by BikePhysics.
struct BikeControlState {
    var steer: Float = 0       // -1 (left) ... 1 (right)
    var throttle: Bool = false
    var brake: Bool = false
    var attackRequested: Bool = false
    var nitroHeld: Bool = false
}

/// Translates raw touch gestures (see UI/RaceControlsOverlay) into a BikeControlState.
/// Left half of screen: horizontal drag = steer, auto-throttle while racing.
/// Right half: upper tap = attack, lower tap = brake, long-press = nitro.
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
}
