import Foundation

/// Pairs an archetype with a name/personality, per the "give major opponents
/// personalities" requirement (mega-spec section 17). All names are original
/// — no connection to any existing motorcycle-combat media.
struct RivalProfile: Equatable {
    let name: String
    let archetype: EnemyArchetype
}

enum RivalRoster {
    static let razor = RivalProfile(name: "Razor", archetype: .brawler)
    static let ghost = RivalProfile(name: "Ghost", archetype: .speedster)
    static let ironJack = RivalProfile(name: "Iron Jack", archetype: .defender)
    static let vixen = RivalProfile(name: "Vixen", archetype: .trickster)
    static let wrecker = RivalProfile(name: "Wrecker", archetype: .rammer)
    static let fang = RivalProfile(name: "Fang", archetype: .hunter)

    static let all: [RivalProfile] = [razor, ghost, ironJack, vixen, wrecker, fang]
}
