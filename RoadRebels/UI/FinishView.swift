import SwiftUI

struct FinishView: View {
    let result: RaceResult
    @ObservedObject var careerState: CareerState
    let progression: ProgressionCoordinator
    let onContinue: () -> Void

    @State private var isSharing = false
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            GameBackground(accent: result.didWin ? Theme.accentYellow : Theme.accentRed)
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: result.didWin ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(result.didWin ? Theme.accentYellow : Theme.textSecondary)
                    .shadow(color: result.didWin ? Theme.accentYellow.opacity(0.6) : .clear, radius: 16)

                Text("\(placeLabel(result.position)) PLACE")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(result.didWin ? Theme.accentYellow : Theme.textPrimary)

                statGrid

                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("CONTINUE")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .white))

                    Button {
                        isSharing = true
                    } label: {
                        Label("SHARE", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(RowPressStyle())
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.85)
        }
        .onAppear {
            if let raceID = result.careerRaceID, result.didWin {
                careerState.completeRace(id: raceID, reward: result.creditsEarned)
            }
            progression.handleRaceFinished(result)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: [ShareText.raceResult(result)])
        }
    }

    private var statGrid: some View {
        HStack(spacing: 10) {
            statChip(icon: "stopwatch.fill", value: String(format: "%.1fs", result.elapsedTime), color: Theme.accentCyan)
            statChip(icon: "arrow.triangle.swap", value: "\(result.nearMisses)", color: Theme.accentViolet)
            if result.creditsEarned > 0 {
                statChip(icon: "circle.hexagongrid.fill", value: "+\(result.creditsEarned)", color: Theme.accentYellow)
            }
        }
    }

    private func statChip(icon: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: 78, height: 62)
        .cardStyle()
    }

    private func placeLabel(_ position: Int) -> String {
        switch position {
        case 1: return "1ST"
        case 2: return "2ND"
        case 3: return "3RD"
        default: return "\(position)TH"
        }
    }
}
