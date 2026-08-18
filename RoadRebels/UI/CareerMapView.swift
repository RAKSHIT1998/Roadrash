import SwiftUI

struct CareerMapView: View {
    @ObservedObject var careerState: CareerState
    let onSelectRace: (CareerRace) -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(CareerContent.regions) { region in
                            regionSection(region)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
            }
            Spacer()
            Text("CAREER")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("\(careerState.credits) CR")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func regionSection(_ region: CareerRegion) -> some View {
        let unlocked = careerState.isRegionUnlocked(region)
        return VStack(alignment: .leading, spacing: 10) {
            Text(region.name.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(unlocked ? .white : .white.opacity(0.35))

            VStack(spacing: 8) {
                ForEach(region.races) { race in
                    raceRow(race, in: region)
                }
            }
        }
    }

    private func raceRow(_ race: CareerRace, in region: CareerRegion) -> some View {
        let unlocked = careerState.isRaceUnlocked(race, in: region)
        let completed = careerState.isRaceCompleted(race)

        return Button {
            guard unlocked else { return }
            onSelectRace(race)
        } label: {
            HStack {
                Image(systemName: completed ? "checkmark.seal.fill" : (unlocked ? "flag.checkered" : "lock.fill"))
                    .foregroundStyle(completed ? .green : (unlocked ? .white : .white.opacity(0.3)))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(unlocked ? .white : .white.opacity(0.35))
                    Text(race.isBossRace ? "BOSS · \(Int(race.distance))m" : "\(Int(race.distance))m")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()
                Text("+\(race.creditReward) CR")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(unlocked ? 1 : 0.3))
            }
            .padding(12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}
