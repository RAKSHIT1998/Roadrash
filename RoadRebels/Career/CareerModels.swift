import Foundation

struct CareerRace: Identifiable, Equatable {
    let id: String
    let name: String
    let distance: Float
    let rivals: [RivalProfile]
    let creditReward: Int
    let isBossRace: Bool
}

struct CareerRegion: Identifiable, Equatable {
    let id: String
    let name: String
    let races: [CareerRace]
}
