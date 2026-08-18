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
}
