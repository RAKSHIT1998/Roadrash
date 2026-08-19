import SwiftUI

struct EndlessResultView: View {
    let result: EndlessResult
    let progression: ProgressionCoordinator
    let onContinue: () -> Void

    @State private var isNewHighScore = false
    @State private var isSharing = false
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            GameBackground(accent: Theme.accentRed)
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.accentRed)
                    .shadow(color: Theme.accentRed.opacity(0.6), radius: 14)

                Text("WRECKED")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                if isNewHighScore {
                    Text("NEW BEST")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Theme.accentYellow, in: Capsule())
                }

                Text("\(result.score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.accentYellow, Theme.accentRed], startPoint: .leading, endPoint: .trailing)
                    )

                HStack(spacing: 10) {
                    statChip(icon: "arrow.left.and.right", value: String(format: "%.0fm", result.distance), color: Theme.accentCyan)
                    statChip(icon: "arrow.triangle.swap", value: "\(result.nearMisses)", color: Theme.accentViolet)
                }

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
            isNewHighScore = progression.handleEndlessFinished(result)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $isSharing) {
            ShareSheet(items: [ShareText.endlessResult(result)])
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
}
