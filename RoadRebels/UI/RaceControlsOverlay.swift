import SwiftUI

/// Touch control scheme: left half = swipe to steer, right half top = attack,
/// right half bottom = hold to brake. Matches "CONTROL MODE C" style discrete
/// zones from the design spec; tilt/gamepad alternatives land in a later
/// phase alongside the settings screen that lets the player choose.
struct RaceControlsOverlay: View {
    @ObservedObject var input: BikeInputController

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                steerZone(width: geo.size.width / 2)
                VStack(spacing: 0) {
                    attackZone
                    brakeZone
                }
                .frame(width: geo.size.width / 2)
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
            .onTapGesture { input.requestAttack() }
            .overlay(alignment: .center) { ControlLabel(text: "ATTACK") }
    }

    private var brakeZone: some View {
        Color.white.opacity(0.001)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in input.setBraking(true) }
                    .onEnded { _ in input.setBraking(false) }
            )
            .overlay(alignment: .center) { ControlLabel(text: "BRAKE") }
    }
}

private struct ControlLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.35))
    }
}
