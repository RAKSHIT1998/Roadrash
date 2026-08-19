import Foundation

/// Progression through CareerContent, persisted via SaveManager. A race is
/// unlocked once the previous race in its region is complete (or it's the
/// region's first race and the region itself is unlocked); a region unlocks
/// once the previous region's final race is complete.
@MainActor
final class CareerState: ObservableObject {
    @Published private(set) var completedRaceIDs: Set<String>
    @Published private(set) var credits: Int

    private let saveManager: SaveManager

    init(saveManager: SaveManager = .shared) {
        self.saveManager = saveManager
        self.completedRaceIDs = saveManager.loadCompletedRaceIDs()
        self.credits = saveManager.loadCredits()
    }

    func isRaceCompleted(_ race: CareerRace) -> Bool {
        completedRaceIDs.contains(race.id)
    }

    var isFullyComplete: Bool {
        CareerContent.regions.allSatisfy { region in region.races.allSatisfy(isRaceCompleted) }
    }

    func isRegionUnlocked(_ region: CareerRegion) -> Bool {
        guard let index = CareerContent.regions.firstIndex(where: { $0.id == region.id }) else { return false }
        guard index > 0 else { return true }
        guard let lastRaceOfPreviousRegion = CareerContent.regions[index - 1].races.last else { return true }
        return isRaceCompleted(lastRaceOfPreviousRegion)
    }

    func isRaceUnlocked(_ race: CareerRace, in region: CareerRegion) -> Bool {
        guard isRegionUnlocked(region) else { return false }
        guard let index = region.races.firstIndex(where: { $0.id == race.id }) else { return false }
        guard index > 0 else { return true }
        return isRaceCompleted(region.races[index - 1])
    }

    @discardableResult
    func spendCredits(_ amount: Int) -> Bool {
        guard credits >= amount else { return false }
        credits -= amount
        saveManager.saveCredits(credits)
        return true
    }

    /// Credits granted from outside race completion, e.g. a Store purchase.
    func grantCredits(_ amount: Int) {
        credits += amount
        saveManager.saveCredits(credits)
    }

    func completeRace(id: String, reward: Int) {
        guard !completedRaceIDs.contains(id) else { return }
        completedRaceIDs.insert(id)
        credits += reward
        saveManager.saveCompletedRaceIDs(completedRaceIDs)
        saveManager.saveCredits(credits)
    }
}
