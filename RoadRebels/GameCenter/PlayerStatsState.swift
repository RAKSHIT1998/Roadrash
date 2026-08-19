import Foundation

struct PlayerStatsSnapshot {
    let totalRacesStarted: Int
    let totalWins: Int
    let totalBossWins: Int
    let totalNearMisses: Int
}

/// Cumulative lifetime counters used to evaluate achievements. Pure data +
/// persistence only — deciding which achievements those counters newly
/// unlock lives in AchievementEvaluator so that logic stays unit-testable.
@MainActor
final class PlayerStatsState: ObservableObject {
    @Published private(set) var totalRacesStarted: Int
    @Published private(set) var totalWins: Int
    @Published private(set) var totalBossWins: Int
    @Published private(set) var totalNearMisses: Int
    @Published private(set) var unlockedAchievementIDs: Set<String>

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        let data = saveManager.loadPlayerStats()
        totalRacesStarted = data.totalRacesStarted
        totalWins = data.totalWins
        totalBossWins = data.totalBossWins
        totalNearMisses = data.totalNearMisses
        unlockedAchievementIDs = data.unlockedAchievementIDs
    }

    var snapshot: PlayerStatsSnapshot {
        PlayerStatsSnapshot(
            totalRacesStarted: totalRacesStarted,
            totalWins: totalWins,
            totalBossWins: totalBossWins,
            totalNearMisses: totalNearMisses
        )
    }

    func recordRaceStart() {
        totalRacesStarted += 1
        persist()
    }

    func recordRaceFinish(didWin: Bool, isBossRace: Bool) {
        guard didWin else { return }
        totalWins += 1
        if isBossRace { totalBossWins += 1 }
        persist()
    }

    func addNearMisses(_ count: Int) {
        guard count > 0 else { return }
        totalNearMisses += count
        persist()
    }

    func markUnlocked(_ id: AchievementID) {
        unlockedAchievementIDs.insert(id.rawValue)
        persist()
    }

    private func persist() {
        saveManager.savePlayerStats(PlayerStatsSaveData(
            totalRacesStarted: totalRacesStarted,
            totalWins: totalWins,
            totalBossWins: totalBossWins,
            totalNearMisses: totalNearMisses,
            unlockedAchievementIDs: unlockedAchievementIDs
        ))
    }
}
