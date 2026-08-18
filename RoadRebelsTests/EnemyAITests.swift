import XCTest
@testable import RoadRebels

final class EnemyAITests: XCTestCase {
    private func context(
        gap: Float = 0,
        defeated: Bool = false,
        hit: Bool = false,
        blocked: Bool = false,
        attackReached: Bool = false
    ) -> EnemyAIContext {
        EnemyAIContext(gapToPlayer: gap, isDefeated: defeated, justGotHit: hit, justBlocked: blocked, attackRangeReached: attackReached)
    }

    func testDefeatedStateIsSticky() {
        let next = EnemyAI.nextState(current: .racing, stateTimer: 0, context: context(defeated: true))
        XCTAssertEqual(next, .defeated)
        let stillDefeated = EnemyAI.nextState(current: .defeated, stateTimer: 5, context: context())
        XCTAssertEqual(stillDefeated, .defeated)
    }

    func testHitInterruptsToStunned() {
        let next = EnemyAI.nextState(current: .attacking, stateTimer: 0.1, context: context(hit: true))
        XCTAssertEqual(next, .stunned)
    }

    func testStunnedRecoversAfterDuration() {
        let stillStunned = EnemyAI.nextState(current: .stunned, stateTimer: 0.1, context: context())
        XCTAssertEqual(stillStunned, .stunned)
        let recovered = EnemyAI.nextState(current: .stunned, stateTimer: 1.0, context: context())
        XCTAssertEqual(recovered, .racing)
    }

    func testFarGapGoesToChasingOrRacing() {
        let chasing = EnemyAI.nextState(current: .racing, stateTimer: 0, context: context(gap: 50))
        XCTAssertEqual(chasing, .chasing)
        let racing = EnemyAI.nextState(current: .racing, stateTimer: 0, context: context(gap: -50))
        XCTAssertEqual(racing, .racing)
    }

    func testCloseGapGoesToOvertaking() {
        let next = EnemyAI.nextState(current: .racing, stateTimer: 0, context: context(gap: 3))
        XCTAssertEqual(next, .overtaking)
    }

    func testAttackRangeTriggersAttacking() {
        let next = EnemyAI.nextState(current: .overtaking, stateTimer: 0, context: context(gap: 1, attackReached: true))
        XCTAssertEqual(next, .attacking)
    }

    func testBlockedGoesToDefending() {
        let next = EnemyAI.nextState(current: .racing, stateTimer: 0, context: context(blocked: true))
        XCTAssertEqual(next, .defending)
    }
}

final class EnemyArchetypeTests: XCTestCase {
    func testDefenderIsTheOnlyArchetypeThatBlocks() {
        for archetype in EnemyArchetype.allCases {
            if archetype == .defender {
                XCTAssertGreaterThan(archetype.blockChance, 0)
            } else {
                XCTAssertEqual(archetype.blockChance, 0)
            }
        }
    }

    func testRammerHitsHarderThanSpeedster() {
        XCTAssertGreaterThan(EnemyArchetype.rammer.damageMultiplier, EnemyArchetype.speedster.damageMultiplier)
    }

    func testHunterRarelyEasesOffWhenAhead() {
        XCTAssertLessThan(EnemyArchetype.hunter.easeOffWhenAhead, EnemyArchetype.brawler.easeOffWhenAhead)
    }
}
