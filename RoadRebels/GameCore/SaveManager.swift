import Foundation

/// Single point of contact with local persistence (mega-spec section 28:
/// "never scatter UserDefaults calls throughout the project"). Everything
/// that needs to survive an app relaunch goes through here, not through
/// UserDefaults directly.
final class SaveManager {
    static let shared = SaveManager()

    private let defaults: UserDefaults
    private enum Key {
        static let completedRaceIDs = "career.completedRaceIDs"
        static let credits = "career.credits"
        static let garage = "garage.data"
        static let endlessHighScore = "endless.highScore"
        static let playerStats = "player.stats"
        static let settings = "app.settings"
        static let hasCompletedTutorial = "tutorial.completed"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadCompletedRaceIDs() -> Set<String> {
        Set(defaults.stringArray(forKey: Key.completedRaceIDs) ?? [])
    }

    func saveCompletedRaceIDs(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: Key.completedRaceIDs)
    }

    func loadCredits() -> Int {
        defaults.integer(forKey: Key.credits)
    }

    func saveCredits(_ value: Int) {
        defaults.set(value, forKey: Key.credits)
    }

    func loadGarage() -> GarageSaveData {
        guard let data = defaults.data(forKey: Key.garage),
              let decoded = try? JSONDecoder().decode(GarageSaveData.self, from: data)
        else {
            return GarageSaveData()
        }
        return decoded
    }

    func saveGarage(_ value: GarageSaveData) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: Key.garage)
    }

    func loadEndlessHighScore() -> Int {
        defaults.integer(forKey: Key.endlessHighScore)
    }

    func saveEndlessHighScore(_ value: Int) {
        defaults.set(value, forKey: Key.endlessHighScore)
    }

    func loadPlayerStats() -> PlayerStatsSaveData {
        guard let data = defaults.data(forKey: Key.playerStats),
              let decoded = try? JSONDecoder().decode(PlayerStatsSaveData.self, from: data)
        else {
            return PlayerStatsSaveData()
        }
        return decoded
    }

    func savePlayerStats(_ value: PlayerStatsSaveData) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: Key.playerStats)
    }

    func loadSettings() -> SettingsSaveData {
        guard let data = defaults.data(forKey: Key.settings),
              let decoded = try? JSONDecoder().decode(SettingsSaveData.self, from: data)
        else {
            return SettingsSaveData()
        }
        return decoded
    }

    func saveSettings(_ value: SettingsSaveData) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: Key.settings)
    }

    func loadHasCompletedTutorial() -> Bool {
        defaults.bool(forKey: Key.hasCompletedTutorial)
    }

    func saveHasCompletedTutorial(_ value: Bool) {
        defaults.set(value, forKey: Key.hasCompletedTutorial)
    }
}

struct GarageSaveData: Codable {
    var ownedBikeIDs: Set<String> = [BikeCatalog.all[0].id]
    var selectedBikeID: String = BikeCatalog.all[0].id
    var upgradeLevels: [String: [String: Int]] = [:] // bikeID -> UpgradeCategory.rawValue -> level
}

struct PlayerStatsSaveData: Codable {
    var totalRacesStarted: Int = 0
    var totalWins: Int = 0
    var totalBossWins: Int = 0
    var totalNearMisses: Int = 0
    var unlockedAchievementIDs: Set<String> = []
}

struct SettingsSaveData: Codable {
    var musicVolume: Float = 0.8
    var sfxVolume: Float = 1.0
    var hapticsEnabled: Bool = true
    var reducedMotionOverride: Bool = false
}
