import XCTest
@testable import RoadRebels

final class AchievementEvaluatorTests: XCTestCase {
    private func stats(races: Int = 0, wins: Int = 0, bossWins: Int = 0, nearMisses: Int = 0) -> PlayerStatsSnapshot {
        PlayerStatsSnapshot(totalRacesStarted: races, totalWins: wins, totalBossWins: bossWins, totalNearMisses: nearMisses)
    }

    private func raceResult(didWin: Bool = true, hadAnyCollision: Bool = false, tookAnyDamage: Bool = false) -> RaceResult {
        RaceResult(
            position: didWin ? 1 : 2,
            totalRiders: 4,
            elapsedTime: 60,
            didWin: didWin,
            careerRaceID: nil,
            creditsEarned: 0,
            hadAnyCollision: hadAnyCollision,
            tookAnyDamage: tookAnyDamage,
            nearMisses: 0
        )
    }

    func testFirstRideUnlocksOnFirstRaceStart() {
        let earned = AchievementEvaluator.newlyEarned(
            stats: stats(races: 1), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil
        )
        XCTAssertTrue(earned.contains(.firstRide))
    }

    func testAlreadyUnlockedIsNotReEarned() {
        let earned = AchievementEvaluator.newlyEarned(
            stats: stats(races: 1), alreadyUnlocked: [AchievementID.firstRide.rawValue], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil
        )
        XCTAssertFalse(earned.contains(.firstRide))
    }

    func testWinMilestonesUnlockAtCorrectThresholds() {
        let earnedAt9 = AchievementEvaluator.newlyEarned(stats: stats(wins: 9), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil)
        XCTAssertFalse(earnedAt9.contains(.tenWins))

        let earnedAt10 = AchievementEvaluator.newlyEarned(stats: stats(wins: 10), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil)
        XCTAssertTrue(earnedAt10.contains(.tenWins))
        XCTAssertTrue(earnedAt10.contains(.firstWin)) // lower thresholds also newly earned in one jump
        XCTAssertFalse(earnedAt10.contains(.hundredWins))
    }

    func testFirstBossRequiresBossWinCount() {
        let earned = AchievementEvaluator.newlyEarned(stats: stats(bossWins: 1), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil)
        XCTAssertTrue(earned.contains(.firstBoss))
    }

    func testMasterRiderRequiresFullCareerCompletion() {
        let notComplete = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: nil)
        XCTAssertFalse(notComplete.contains(.masterRider))

        let complete = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: true, endlessHighScore: 0, latestRaceResult: nil)
        XCTAssertTrue(complete.contains(.masterRider))
    }

    func testRoadLegendRequiresHighEndlessScore() {
        let below = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: AchievementEvaluator.roadLegendScoreThreshold - 1, latestRaceResult: nil)
        XCTAssertFalse(below.contains(.roadLegend))

        let above = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: AchievementEvaluator.roadLegendScoreThreshold, latestRaceResult: nil)
        XCTAssertTrue(above.contains(.roadLegend))
    }

    func testNoCrashRunOnlyRequiresNoCollisionRegardlessOfWinning() {
        let lostNoCrash = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: raceResult(didWin: false, hadAnyCollision: false))
        XCTAssertTrue(lostNoCrash.contains(.noCrashRun))

        let wonWithCrash = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: raceResult(didWin: true, hadAnyCollision: true))
        XCTAssertFalse(wonWithCrash.contains(.noCrashRun))
    }

    func testPerfectRaceRequiresWinAndNoDamageTaken() {
        let wonButDamaged = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: raceResult(didWin: true, tookAnyDamage: true))
        XCTAssertFalse(wonButDamaged.contains(.perfectRace))

        let perfectWin = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: raceResult(didWin: true, tookAnyDamage: false))
        XCTAssertTrue(perfectWin.contains(.perfectRace))

        let lostUndamaged = AchievementEvaluator.newlyEarned(stats: stats(), alreadyUnlocked: [], careerFullyComplete: false, endlessHighScore: 0, latestRaceResult: raceResult(didWin: false, tookAnyDamage: false))
        XCTAssertFalse(lostUndamaged.contains(.perfectRace))
    }
}

@MainActor
final class PlayerStatsStateTests: XCTestCase {
    func testRecordRaceStartIncrements() {
        let defaults = UserDefaults(suiteName: "PlayerStatsStateTests.\(UUID().uuidString)")!
        let stats = PlayerStatsState(saveManager: SaveManager(defaults: defaults))
        stats.recordRaceStart()
        stats.recordRaceStart()
        XCTAssertEqual(stats.totalRacesStarted, 2)
    }

    func testRecordRaceFinishOnlyCountsWins() {
        let defaults = UserDefaults(suiteName: "PlayerStatsStateTests.\(UUID().uuidString)")!
        let stats = PlayerStatsState(saveManager: SaveManager(defaults: defaults))
        stats.recordRaceFinish(didWin: false, isBossRace: false)
        XCTAssertEqual(stats.totalWins, 0)
        stats.recordRaceFinish(didWin: true, isBossRace: true)
        XCTAssertEqual(stats.totalWins, 1)
        XCTAssertEqual(stats.totalBossWins, 1)
    }

    func testStatsPersistAcrossInstances() {
        let defaults = UserDefaults(suiteName: "PlayerStatsStateTests.\(UUID().uuidString)")!
        let manager = SaveManager(defaults: defaults)
        let first = PlayerStatsState(saveManager: manager)
        first.recordRaceStart()
        first.markUnlocked(.firstRide)

        let second = PlayerStatsState(saveManager: manager)
        XCTAssertEqual(second.totalRacesStarted, 1)
        XCTAssertTrue(second.unlockedAchievementIDs.contains(AchievementID.firstRide.rawValue))
    }
}
