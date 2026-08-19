import SwiftUI

struct EndlessResultView: View {
    let result: EndlessResult
    @ObservedObject var endlessState: EndlessState
    let onContinue: () -> Void

    @State private var isNewHighScore = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("WRECKED")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.red)

                if isNewHighScore {
                    Text("NEW BEST")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.yellow)
                }

                Text("\(result.score)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 4) {
                    Text(String(format: "%.0f m traveled", result.distance))
                    Text("\(result.nearMisses) near misses")
                }
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

                Button(action: onContinue) {
                    Text("CONTINUE")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 16)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            isNewHighScore = endlessState.submit(score: result.score)
        }
    }
}
