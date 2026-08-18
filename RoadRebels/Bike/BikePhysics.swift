import Foundation

/// Pure kinematic state for a bike moving along the road spline.
/// `distance` is meters traveled along the centerline; `lateralOffset` is
/// meters left(-)/right(+) of center. Kept free of RealityKit so it is
/// trivially unit-testable.
struct BikeState: Equatable {
    var distance: Float = 0
    var lateralOffset: Float = 0
    var speed: Float = 0
    var lean: Float = 0
    var lateralVelocity: Float = 0
}

enum BikePhysics {
    static let maxLateralSpeed: Float = 10.0
    static let lateralResponse: Float = 8.0

    static func step(state: BikeState, control: BikeControlState, dt: Float) -> BikeState {
        var next = state

        // Longitudinal: throttle/brake/drag, with a nitro boost layered on top.
        let accelMultiplier: Float = control.nitroActive ? GameConstants.nitroAccelMultiplier : 1
        let speedCap = control.nitroActive ? GameConstants.bikeMaxSpeed * GameConstants.nitroSpeedMultiplier : GameConstants.bikeMaxSpeed
        if control.brake {
            next.speed -= GameConstants.bikeBrakeDeceleration * dt
        } else if control.throttle {
            next.speed += GameConstants.bikeAcceleration * accelMultiplier * dt
        } else {
            next.speed -= GameConstants.bikeDrag * dt
        }
        next.speed = max(0, min(next.speed, speedCap))

        // Lateral: steer input drives a target lateral velocity, smoothed.
        let targetLateralVelocity = control.steer * maxLateralSpeed
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
}
