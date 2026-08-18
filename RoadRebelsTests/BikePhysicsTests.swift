import XCTest
@testable import RoadRebels

final class BikePhysicsTests: XCTestCase {
    func testThrottleAccelerates() {
        var state = BikeState()
        let control = BikeControlState(steer: 0, throttle: true, brake: false)
        for _ in 0..<10 {
            state = BikePhysics.step(state: state, control: control, dt: 1.0 / 60.0)
        }
        XCTAssertGreaterThan(state.speed, 0)
        XCTAssertGreaterThan(state.distance, 0)
    }

    func testBrakeDeceleratesToZero() {
        var state = BikeState(speed: 20)
        let control = BikeControlState(steer: 0, throttle: false, brake: true)
        for _ in 0..<120 {
            state = BikePhysics.step(state: state, control: control, dt: 1.0 / 60.0)
        }
        XCTAssertEqual(state.speed, 0, accuracy: 0.01)
    }

    func testSpeedNeverExceedsMax() {
        var state = BikeState()
        let control = BikeControlState(steer: 0, throttle: true, brake: false)
        for _ in 0..<600 {
            state = BikePhysics.step(state: state, control: control, dt: 1.0 / 60.0)
        }
        XCTAssertLessThanOrEqual(state.speed, GameConstants.bikeMaxSpeed)
    }

    func testSteerClampsWithinLaneRange() {
        var state = BikeState()
        let control = BikeControlState(steer: 1, throttle: true, brake: false)
        for _ in 0..<600 {
            state = BikePhysics.step(state: state, control: control, dt: 1.0 / 60.0)
        }
        XCTAssertLessThanOrEqual(state.lateralOffset, GameConstants.bikeHalfLaneRange)
    }

    func testKnockbackReducesSpeedAndNudgesLateral() {
        let state = BikeState(lateralOffset: 0, speed: 20)
        let result = BikePhysics.applyKnockback(to: state, lateralImpulse: 3, speedLoss: 5)
        XCTAssertEqual(result.speed, 15)
        XCTAssertEqual(result.lateralVelocity, 3)
    }
}

final class CombatResolverTests: XCTestCase {
    func testAttackWithinRangeSucceedsAndAppliesCooldown() {
        let attacker = RiderCombatState()
        let (updated, outcome) = CombatResolver.attemptAttack(
            attackerState: attacker,
            attackerDistance: 10,
            attackerLateral: 0,
            defenderDistance: 11,
            defenderLateral: 0.5
        )
        XCTAssertNotNil(outcome)
        XCTAssertEqual(updated.attackCooldownRemaining, GameConstants.attackCooldown)
    }

    func testAttackOutOfRangeFails() {
        let attacker = RiderCombatState()
        let (_, outcome) = CombatResolver.attemptAttack(
            attackerState: attacker,
            attackerDistance: 0,
            attackerLateral: 0,
            defenderDistance: 100,
            defenderLateral: 0
        )
        XCTAssertNil(outcome)
    }

    func testAttackOnCooldownFails() {
        let attacker = RiderCombatState(health: 100, attackCooldownRemaining: 0.2)
        let (_, outcome) = CombatResolver.attemptAttack(
            attackerState: attacker,
            attackerDistance: 0,
            attackerLateral: 0,
            defenderDistance: 1,
            defenderLateral: 0
        )
        XCTAssertNil(outcome)
    }

    func testDamageReducesHealthAndClampsAtZero() {
        let defender = RiderCombatState(health: 10)
        let outcome = AttackOutcome(damage: 20, lateralKnockback: 0, speedLoss: 0)
        let updated = CombatResolver.applyDamage(defender, outcome: outcome)
        XCTAssertEqual(updated.health, 0)
        XCTAssertTrue(updated.isDefeated)
    }
}

final class RoadSplineTests: XCTestCase {
    func testStraightSegmentMovesAlongNegativeZ() {
        let spline = RoadSpline.standardPhase1()
        let t = spline.transform(atDistance: 100)
        XCTAssertEqual(t.position.x, 0, accuracy: 0.001)
        XCTAssertEqual(t.position.z, -100, accuracy: 0.001)
    }

    func testCurveChangesHeading() {
        let spline = RoadSpline.standardPhase1()
        let before = spline.transform(atDistance: 399)
        let after = spline.transform(atDistance: 450)
        XCTAssertNotEqual(before.heading, after.heading)
    }

    func testDistanceClampsToTotalLength() {
        let spline = RoadSpline.standardPhase1()
        let atEnd = spline.transform(atDistance: spline.totalLength)
        let beyond = spline.transform(atDistance: spline.totalLength + 500)
        XCTAssertEqual(atEnd.position, beyond.position)
    }
}
