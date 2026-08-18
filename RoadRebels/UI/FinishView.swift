import SwiftUI

struct FinishView: View {
    let result: RaceResult
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 22) {
                Text(result.didWin ? "1ST PLACE" : "2ND PLACE")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(result.didWin ? .yellow : .white)

                Text(String(format: "TIME   %.1fs", result.elapsedTime))
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

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
    }
}
