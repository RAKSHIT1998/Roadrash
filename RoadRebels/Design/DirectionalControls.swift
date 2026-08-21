import SwiftUI

/// Visible LEFT / RIGHT / JUMP buttons layered over the invisible swipe-to-
/// steer zone — a discrete, "signposted" alternative to swiping, plus the
/// player-triggered jump (ramps also launch the bike automatically).
/// Shared by RaceControlsOverlay and EndlessControlsOverlay.
struct DirectionalJumpControls: View {
    @ObservedObject var input: BikeInputController

    @State private var leftHeld = false
    @State private var rightHeld = false
    @State private var isJumping = false

    var body: some View {
        HStack(spacing: 12) {
            arrowButton(direction: -1, isHeld: $leftHeld, systemImage: "arrowtriangle.left.fill")
            arrowButton(direction: 1, isHeld: $rightHeld, systemImage: "arrowtriangle.right.fill")
            jumpButton
        }
    }

    private func arrowButton(direction: Float, isHeld: Binding<Bool>, systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(isHeld.wrappedValue ? .white : .white.opacity(0.6))
            .frame(width: 46, height: 46)
            .background(Circle().fill(isHeld.wrappedValue ? Theme.accentRed.opacity(0.55) : Color.white.opacity(0.08)))
            .overlay(Circle().stroke(.white.opacity(isHeld.wrappedValue ? 0.5 : 0.2), lineWidth: 1.5))
            .shadow(color: isHeld.wrappedValue ? Theme.accentRed.opacity(0.6) : .clear, radius: 8)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isHeld.wrappedValue = true
                        input.setSteerButton(direction)
                    }
                    .onEnded { _ in
                        isHeld.wrappedValue = false
                        input.resetSteer()
                    }
            )
            .animation(.easeOut(duration: 0.1), value: isHeld.wrappedValue)
    }

    private var jumpButton: some View {
        Image(systemName: "arrow.up.circle.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(isJumping ? .white : Theme.accentCyan)
            .frame(width: 50, height: 50)
            .background(Circle().fill(isJumping ? Theme.accentCyan.opacity(0.6) : Color.white.opacity(0.08)))
            .overlay(Circle().stroke(.white.opacity(isJumping ? 0.55 : 0.2), lineWidth: 1.5))
            .shadow(color: isJumping ? Theme.accentCyan.opacity(0.6) : .clear, radius: 8)
            .contentShape(Circle())
            .onTapGesture {
                input.requestJump()
                isJumping = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isJumping = false }
            }
            .animation(.easeOut(duration: 0.1), value: isJumping)
    }
}
