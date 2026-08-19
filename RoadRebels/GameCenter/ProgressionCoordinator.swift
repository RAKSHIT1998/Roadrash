import Foundation

/// Glue between a finished race/endless run and PlayerStatsState +
/// GameCenterService: updates lifetime counters, submits leaderboard
/// scores, and reports any newly-earned achievements. Kept out of the
/// Views (which already call CareerState/EndlessState directly for their
/// own concerns) so this cross-cutting bookkeeping lives in one place.
@MainActor
final class ProgressionCoordinator {
    let playerStats: PlayerStatsState
    let careerState: CareerState
    let endlessState: EndlessState
    let gameCenter: GameCenterService

    init(playerStats: PlayerStatsState, careerState: CareerState, endlessState: EndlessState, gameCenter: GameCenterService = .shared) {
        self.playerStats = playerStats
        self.careerState = careerState
        self.endlessState = endlessState
        self.gameCenter = gameCenter
    }

    func handleRaceStart() {
        playerStats.recordRaceStart()
        reportNewAchievements(latestRaceResult: nil)
    }

    func handleRaceFinished(_ result: RaceResult) {
        let isBossRace = result.careerRaceID.flatMap(CareerContent.race(withID:))?.isBossRace ?? false
        playerStats.recordRaceFinish(didWin: result.didWin, isBossRace: isBossRace)
        playerStats.addNearMisses(result.nearMisses)
        if result.didWin {
            let centiseconds = Int((result.elapsedTime * 100).rounded())
            gameCenter.submitScore(centiseconds, leaderboard: .fastestRace)
        }
        reportNewAchievements(latestRaceResult: result)
    }

    /// Returns whether this run set a new local high score.
    @discardableResult
    func handleEndlessFinished(_ result: EndlessResult) -> Bool {
        playerStats.addNearMisses(result.nearMisses)
        gameCenter.submitScore(result.score, leaderboard: .endlessDistance)
        let isNewHighScore = endlessState.submit(score: result.score)
        reportNewAchievements(latestRaceResult: nil)
        return isNewHighScore
    }

    private func reportNewAchievements(latestRaceResult: RaceResult?) {
        let earned = AchievementEvaluator.newlyEarned(
            stats: playerStats.snapshot,
            alreadyUnlocked: playerStats.unlockedAchievementIDs,
            careerFullyComplete: careerState.isFullyComplete,
            endlessHighScore: endlessState.highScore,
            latestRaceResult: latestRaceResult
        )
        for id in earned {
            playerStats.markUnlocked(id)
            gameCenter.reportAchievement(id)
        }
    }
}
