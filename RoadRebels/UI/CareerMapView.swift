import SwiftUI

struct CareerMapView: View {
    @ObservedObject var careerState: CareerState
    let onSelectRace: (CareerRace) -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            GameBackground(accent: Theme.accentViolet)
            VStack(spacing: 0) {
                ScreenHeader(title: "CAREER", onBack: onBack) {
                    CreditsPill(amount: careerState.credits)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(CareerContent.regions) { region in
                            regionSection(region)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private func regionSection(_ region: CareerRegion) -> some View {
        let unlocked = careerState.isRegionUnlocked(region)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(unlocked ? Theme.accentViolet : Color.white.opacity(0.15))
                    .frame(width: 7, height: 7)
                Text(region.name.uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(unlocked ? Theme.textPrimary : Theme.textTertiary)
            }

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
        let isNextUp = unlocked && !completed

        return Button {
            guard unlocked else { return }
            onSelectRace(race)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(completed ? Theme.accentGreen.opacity(0.18) : (unlocked ? Theme.accentRed.opacity(0.18) : Color.white.opacity(0.06)))
                        .frame(width: 34, height: 34)
                    Image(systemName: completed ? "checkmark" : (race.isBossRace ? "crown.fill" : (unlocked ? "flag.checkered" : "lock.fill")))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(completed ? Theme.accentGreen : (unlocked ? Theme.accentRed : Theme.textTertiary))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(unlocked ? Theme.textPrimary : Theme.textTertiary)
                    Text(race.isBossRace ? "BOSS · \(Int(race.distance))m" : "\(Int(race.distance))m")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(unlocked ? Theme.textSecondary : Theme.textTertiary)
                }

                Spacer()
                Text("+\(race.creditReward)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accentYellow.opacity(unlocked ? 1 : 0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .stroke(isNextUp ? Theme.accentRed.opacity(0.5) : Theme.cardStroke, lineWidth: isNextUp ? 1.5 : 1)
                    )
                    .shadow(color: isNextUp ? Theme.accentRed.opacity(0.25) : .clear, radius: 10)
            )
        }
        .buttonStyle(RowPressStyle())
        .disabled(!unlocked)
    }
}
