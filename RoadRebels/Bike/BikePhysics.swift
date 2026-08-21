import Foundation

/// Pure kinematic state for a bike moving along the road spline.
/// `distance` is meters traveled along the centerline; `lateralOffset` is
/// meters left(-)/right(+) of center. `height` is meters above the road
/// surface (0 = grounded), driven by ramps and the player-triggered jump.
/// Kept free of RealityKit so it is trivially unit-testable.
struct BikeState: Equatable {
    var distance: Float = 0
    var lateralOffset: Float = 0
    var speed: Float = 0
    var lean: Float = 0
    var lateralVelocity: Float = 0
    var height: Float = 0
    var verticalVelocity: Float = 0

    var isAirborne: Bool { height > 0.001 }
}

enum BikePhysics {
    static let maxLateralSpeed: Float = 10.0
    static let lateralResponse: Float = 8.0
    static let gravity: Float = 22.0
    static let jumpSpeed: Float = 6.5

    static func step(state: BikeState, control: BikeControlState, dt: Float, tuning: BikeTuning = .default) -> BikeState {
        var next = state

        // Longitudinal: throttle/brake/drag, with a nitro boost and the
        // bike/upgrade tuning multipliers layered on top.
        let accelMultiplier: Float = (control.nitroActive ? GameConstants.nitroAccelMultiplier : 1) * tuning.accelMultiplier
        let baseMaxSpeed = GameConstants.bikeMaxSpeed * tuning.speedMultiplier
        let speedCap = control.nitroActive ? baseMaxSpeed * GameConstants.nitroSpeedMultiplier : baseMaxSpeed
        if control.brake {
            next.speed -= GameConstants.bikeBrakeDeceleration * tuning.brakeMultiplier * dt
        } else if control.throttle {
            next.speed += GameConstants.bikeAcceleration * accelMultiplier * dt
        } else {
            next.speed -= GameConstants.bikeDrag * dt
        }
        next.speed = max(0, min(next.speed, speedCap))

        // Lateral: steer input drives a target lateral velocity, smoothed.
        let targetLateralVelocity = control.steer * maxLateralSpeed * tuning.handlingMultiplier
        next.lateralVelocity += (targetLateralVelocity - next.lateralVelocity) * min(1, lateralResponse * dt)
        next.lateralOffset += next.lateralVelocity * dt
        let halfRange = GameConstants.bikeHalfLaneRange
        if next.lateralOffset > halfRange {
            next.lateralOffset = halfRange
            next.lateralVelocity = 0
        } else if next.lateralOffset < -halfRange {
            next.lateralOffset = -halfRange
            next.lateralVelocity = 0
        }

        // Lean is cosmetic, follows steer input.
        let targetLean = control.steer * GameConstants.bikeMaxLean
        next.lean += (targetLean - next.lean) * min(1, GameConstants.bikeLeanResponse * dt)

        // Vertical: a player-triggered hop when grounded, otherwise gravity
        // takes over (also used for the tail end of a ramp launch).
        if control.jumpRequested && !next.isAirborne {
            next.verticalVelocity = jumpSpeed
        }
        if next.isAirborne || next.verticalVelocity > 0 {
            next.verticalVelocity -= gravity * dt
            next.height += next.verticalVelocity * dt
            if next.height <= 0 {
                next.height = 0
                next.verticalVelocity = 0
            }
        }

        // Forward progress.
        next.distance += next.speed * dt

        return next
    }

    /// Applies an instantaneous knockback (e.g. from a hit), bleeding off speed
    /// and nudging the bike laterally without touching the pure step logic above.
    static func applyKnockback(to state: BikeState, lateralImpulse: Float, speedLoss: Float) -> BikeState {
        var next = state
        next.lateralVelocity += lateralImpulse
        next.speed = max(0, next.speed - speedLoss)
        return next
    }

    /// A ramp launch: stronger than the manual jump, only takes effect if
    /// the bike is currently grounded (re-driving off a ramp mid-air is a
    /// no-op, matching how real ramps work).
    static func applyRampLaunch(to state: BikeState, launchSpeed: Float) -> BikeState {
        guard !state.isAirborne else { return state }
        var next = state
        next.verticalVelocity = launchSpeed
        return next
    }
}
