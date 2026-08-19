import Foundation

/// Pure decision logic for which achievements a snapshot of player progress
/// newly satisfies. Kept free of GameKit/persistence so it's directly
/// unit-testable, matching the BikePhysics/CombatResolver/EnemyAI pattern.
enum AchievementEvaluator {
    /// Threshold judgment calls (the mega-spec names these achievements but
    /// doesn't specify numbers): MASTER_RIDER = finish every Career race,
    /// ROAD_LEGEND = a strong Endless high score.
    static let roadLegendScoreThreshold = 5000

    static func newlyEarned(
        stats: PlayerStatsSnapshot,
        alreadyUnlocked: Set<String>,
        careerFullyComplete: Bool,
        endlessHighScore: Int,
        latestRaceResult: RaceResult?
    ) -> [AchievementID] {
        var earned: [AchievementID] = []
        func consider(_ id: AchievementID, _ condition: @autoclosure () -> Bool) {
            guard !alreadyUnlocked.contains(id.rawValue), condition() else { return }
            earned.append(id)
        }

        consider(.firstRide, stats.totalRacesStarted >= 1)
        consider(.firstWin, stats.totalWins >= 1)
        consider(.tenWins, stats.totalWins >= 10)
        consider(.hundredWins, stats.totalWins >= 100)
        consider(.firstBoss, stats.totalBossWins >= 1)
        consider(.masterRider, careerFullyComplete)
        consider(.hundredNearMisses, stats.totalNearMisses >= 100)
        consider(.roadLegend, endlessHighScore >= roadLegendScoreThreshold)

        if let result = latestRaceResult {
            consider(.noCrashRun, !result.hadAnyCollision)
            consider(.perfectRace, result.didWin && !result.tookAnyDamage)
        }

        return earned
    }
}
