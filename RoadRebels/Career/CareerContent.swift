import Foundation

/// Static career definition: 6 regions x 3 races (2 standard + 1 boss),
/// matching the region roster from the design spec (section 5). Distance and
/// rival toughness ramp up region over region; boss races add an extra rival
/// and use a named RivalProfile as the headline opponent.
enum CareerContent {
    static let regions: [CareerRegion] = [
        region(id: "dustline", name: "Dustline County", baseDistance: 700, rivalPool: [RivalRoster.razor, RivalRoster.ghost], boss: RivalRoster.ironJack),
        region(id: "neoncoast", name: "Neon Coast", baseDistance: 850, rivalPool: [RivalRoster.ghost, RivalRoster.vixen], boss: RivalRoster.wrecker),
        region(id: "ironvalley", name: "Iron Valley", baseDistance: 1000, rivalPool: [RivalRoster.ironJack, RivalRoster.razor], boss: RivalRoster.fang),
        region(id: "blackcanyon", name: "Black Canyon", baseDistance: 1150, rivalPool: [RivalRoster.wrecker, RivalRoster.fang], boss: RivalRoster.vixen),
        region(id: "nightfallcity", name: "Nightfall City", baseDistance: 1300, rivalPool: [RivalRoster.vixen, RivalRoster.wrecker, RivalRoster.ghost], boss: RivalRoster.razor),
        region(id: "wasteland", name: "The Wasteland", baseDistance: 1500, rivalPool: [RivalRoster.fang, RivalRoster.ironJack, RivalRoster.razor, RivalRoster.ghost], boss: RivalRoster.wrecker),
    ]

    static func race(withID id: String) -> CareerRace? {
        regions.lazy.compactMap { region in region.races.first { $0.id == id } }.first
    }

    private static func region(id: String, name: String, baseDistance: Float, rivalPool: [RivalProfile], boss: RivalProfile) -> CareerRegion {
        let sprint = CareerRace(
            id: "\(id).sprint",
            name: "\(name) Sprint",
            distance: baseDistance,
            rivals: Array(rivalPool.prefix(2)),
            creditReward: 60,
            isBossRace: false
        )
        let circuit = CareerRace(
            id: "\(id).circuit",
            name: "\(name) Circuit",
            distance: baseDistance + 200,
            rivals: rivalPool,
            creditReward: 90,
            isBossRace: false
        )
        let bossRace = CareerRace(
            id: "\(id).boss",
            name: "\(boss.name)'s Gauntlet",
            distance: baseDistance + 350,
            rivals: (rivalPool.prefix(2) + [boss]),
            creditReward: 200,
            isBossRace: true
        )
        return CareerRegion(id: id, name: name, races: [sprint, circuit, bossRace])
    }
}
