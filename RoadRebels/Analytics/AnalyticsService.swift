import Foundation
import os

/// Event catalog from the mega-spec (section 52). No third-party SDK here —
/// this is a local/no-op sink (just os_log) with the exact call sites a real
/// analytics backend would need, so wiring one in later is a one-file change
/// rather than a hunt through the codebase. Never carries PII.
enum AnalyticsEvent {
    case gameStarted
    case tutorialCompleted
    case raceStarted(mode: String)
    case raceFinished(mode: String, position: Int)
    case raceWon(mode: String)
    case raceLost(mode: String)
    case bikeUnlocked(bikeID: String)
    case upgradePurchased(category: String, bikeID: String)
    case bossDefeated(raceID: String)
    case challengeCompleted(id: String)
    case endlessStarted
    case endlessFinished(score: Int)
    case storeOpened
    case purchaseStarted(productID: String)
    case purchaseCompleted(productID: String)
    case purchaseFailed(productID: String)

    var name: String {
        switch self {
        case .gameStarted: return "game_started"
        case .tutorialCompleted: return "tutorial_completed"
        case .raceStarted: return "race_started"
        case .raceFinished: return "race_finished"
        case .raceWon: return "race_won"
        case .raceLost: return "race_lost"
        case .bikeUnlocked: return "bike_unlocked"
        case .upgradePurchased: return "upgrade_purchased"
        case .bossDefeated: return "boss_defeated"
        case .challengeCompleted: return "challenge_completed"
        case .endlessStarted: return "endless_started"
        case .endlessFinished: return "endless_finished"
        case .storeOpened: return "store_opened"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .gameStarted, .tutorialCompleted, .endlessStarted, .storeOpened:
            return [:]
        case .raceStarted(let mode), .raceWon(let mode), .raceLost(let mode):
            return ["mode": mode]
        case .raceFinished(let mode, let position):
            return ["mode": mode, "position": String(position)]
        case .bikeUnlocked(let bikeID):
            return ["bikeID": bikeID]
        case .upgradePurchased(let category, let bikeID):
            return ["category": category, "bikeID": bikeID]
        case .bossDefeated(let raceID):
            return ["raceID": raceID]
        case .challengeCompleted(let id):
            return ["id": id]
        case .endlessFinished(let score):
            return ["score": String(score)]
        case .purchaseStarted(let productID), .purchaseCompleted(let productID), .purchaseFailed(let productID):
            return ["productID": productID]
        }
    }
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let logger = Logger(subsystem: "com.roadrebels.game", category: "analytics")

    private init() {}

    func log(_ event: AnalyticsEvent) {
        let paramsDescription = String(describing: event.parameters)
        logger.debug("[analytics] \(event.name, privacy: .public) \(paramsDescription, privacy: .public)")
    }
}
