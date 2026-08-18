import Foundation

/// Everything RaceController needs to build one race: how far it is and who
/// is in it. A Career race and the menu's Quick Race both boil down to one
/// of these, so RaceController itself never needs to know about Career.
struct RaceConfiguration: Equatable {
    let distance: Float
    let rivals: [RivalProfile]
    let creditReward: Int
    let careerRaceID: String?

    static let quickRace = RaceConfiguration(
        distance: GameConstants.raceDistance,
        rivals: [RivalRoster.razor, RivalRoster.ghost, RivalRoster.ironJack],
        creditReward: 50,
        careerRaceID: nil
    )

    init(distance: Float, rivals: [RivalProfile], creditReward: Int, careerRaceID: String?) {
        self.distance = distance
        self.rivals = rivals
        self.creditReward = creditReward
        self.careerRaceID = careerRaceID
    }

    init(careerRace: CareerRace) {
        self.init(
            distance: careerRace.distance,
            rivals: careerRace.rivals,
            creditReward: careerRace.creditReward,
            careerRaceID: careerRace.id
        )
    }
}
