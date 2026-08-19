import SwiftUI

struct FinishView: View {
    let result: RaceResult
    @ObservedObject var careerState: CareerState
    let progression: ProgressionCoordinator
    let onContinue: () -> Void

    @State private var isSharing = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("\(placeLabel(result.position)) PLACE")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(result.didWin ? .yellow : .white)

                Text(String(format: "TIME   %.1fs", result.elapsedTime))
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

                if result.creditsEarned > 0 {
                    Text("+\(result.creditsEarned) CR")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                }

                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("CONTINUE")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 16)
                            .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        isSharing = true
                    } label: {
                        Label("SHARE", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            if let raceID = result.careerRaceID, result.didWin {
                careerState.completeRace(id: raceID, reward: result.creditsEarned)
            }
            progression.handleRaceFinished(result)
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: [ShareText.raceResult(result)])
        }
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
