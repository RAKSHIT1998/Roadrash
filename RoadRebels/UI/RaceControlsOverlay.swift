import SwiftUI

/// Touch control scheme: left half = swipe to steer, right half top = attack,
/// right half bottom = hold to brake. Matches "CONTROL MODE C" style discrete
/// zones from the design spec; tilt/gamepad alternatives land in a later
/// phase alongside the settings screen that lets the player choose.
struct RaceControlsOverlay: View {
    @ObservedObject var input: BikeInputController

    @State private var isAttackFlashing = false
    @State private var isNitroHeld = false
    @State private var isBraking = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 0) {
                    steerZone(width: geo.size.width / 2)
                    VStack(spacing: 0) {
                        attackZone
                        nitroZone
                        brakeZone
                    }
                    .frame(width: geo.size.width / 2)
                }
                DirectionalJumpControls(input: input)
                    .padding(.leading, 24)
                    .padding(.bottom, 22)
            }
        }
        .ignoresSafeArea()
    }

    private func steerZone(width: CGFloat) -> some View {
        Color.white.opacity(0.001)
            .frame(width: width)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        input.updateSteer(fromDragTranslationX: value.translation.width, screenWidth: width * 2)
                    }
                    .onEnded { _ in input.resetSteer() }
            )
    }

    private var attackZone: some View {
        Color.white.opacity(0.001)
            .contentShape(Rectangle())
            .onTapGesture {
                input.requestAttack()
                isAttackFlashing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isAttackFlashing = false }
            }
            .overlay(alignment: .center) {
                ControlLabel(icon: "hand.raised.fill", text: "ATTACK", isActive: isAttackFlashing)
            }
    }

    private var nitroZone: some View {
        Color.white.opacity(0.001)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        input.setNitroHeld(true)
                        isNitroHeld = true
                    }
                    .onEnded { _ in
                        input.setNitroHeld(false)
                        isNitroHeld = false
                    }
            )
            .overlay(alignment: .center) {
                ControlLabel(icon: "bolt.fill", text: "NITRO", isActive: isNitroHeld, activeColor: Theme.accentCyan)
            }
    }

    private var brakeZone: some View {
        Color.white.opacity(0.001)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        input.setBraking(true)
                        isBraking = true
                    }
                    .onEnded { _ in
                        input.setBraking(false)
                        isBraking = false
                    }
            )
            .overlay(alignment: .center) {
                ControlLabel(icon: "hand.point.down.fill", text: "BRAKE", isActive: isBraking)
            }
    }
}

private struct ControlLabel: View {
    let icon: String
    let text: String
    var isActive: Bool = false
    var activeColor: Color = Theme.accentRed

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isActive ? .white : .white.opacity(0.55))
                .frame(width: 50, height: 50)
                .background(Circle().fill(isActive ? activeColor.opacity(0.55) : Color.white.opacity(0.07)))
                .overlay(Circle().stroke(.white.opacity(isActive ? 0.55 : 0.18), lineWidth: 1.5))
                .shadow(color: isActive ? activeColor.opacity(0.6) : .clear, radius: 10)
            Text(text)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.38))
        }
        .animation(.easeOut(duration: 0.12), value: isActive)
    }
}
