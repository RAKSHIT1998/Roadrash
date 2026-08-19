import SwiftUI

/// Shared back-button + title + trailing-content header for every secondary
/// screen (Career, Garage, Store, Settings) — one consistent look instead of
/// four near-identical hand-rolled HStacks.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(IconButtonStyle())
            .accessibilityIdentifier("backButton")

            Spacer()
            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(Theme.textPrimary)
            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

/// Balances the back button's width so the title stays visually centered
/// when a screen has no trailing content (pass explicitly: `{ HeaderSpacer() }`).
struct HeaderSpacer: View {
    var body: some View { Color.clear.frame(width: 40, height: 1) }
}

/// A "X CR" credits pill, reused wherever a header needs to show the
/// player's balance.
struct CreditsPill: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 11, weight: .bold))
            Text("\(amount)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(Theme.accentYellow)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.accentYellow.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(Theme.accentYellow.opacity(0.3), lineWidth: 1))
    }
}
