import SwiftUI

/// Short, auto-advancing tips layered over real gameplay during the
/// player's first race — never a blocking text wall, and skippable at any
/// time. Driven purely by live race telemetry already on GameState, so it
/// needs no changes to RaceController.
struct TutorialOverlay: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var tutorialState: TutorialState

    @State private var elapsed: TimeInterval = 0
    @State private var currentStep: TutorialStep = .none

    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if !tutorialState.hasCompletedTutorial, currentStep != .none {
                VStack {
                    HStack(spacing: 12) {
                        Text(currentStep.message)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                        Button {
                            tutorialState.markCompleted()
                        } label: {
                            Text("SKIP")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 70)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onReceive(timer) { _ in
            guard !tutorialState.hasCompletedTutorial else { return }
            elapsed += 0.25
            let next = TutorialStepSelector.step(elapsedTime: elapsed, raceProgress: gameState.raceProgress, nitroMeter: gameState.nitroMeter)
            if next != currentStep {
                withAnimation(.easeInOut(duration: 0.2)) { currentStep = next }
            }
            if gameState.raceProgress >= 0.99 {
                tutorialState.markCompleted()
            }
        }
    }
}
