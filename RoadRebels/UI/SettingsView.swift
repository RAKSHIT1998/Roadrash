import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsState
    let onBack: () -> Void

    var body: some View {
        ZStack {
            GameBackground(accent: Theme.accentGreen)
            VStack(spacing: 0) {
                ScreenHeader(title: "SETTINGS", onBack: onBack) { HeaderSpacer() }
                ScrollView {
                    VStack(spacing: 16) {
                        sliderRow(title: "MUSIC VOLUME", icon: "music.note", value: $settings.musicVolume)
                        sliderRow(title: "SFX VOLUME", icon: "speaker.wave.2.fill", value: $settings.sfxVolume)
                        toggleRow(title: "HAPTICS", icon: "iphone.radiowaves.left.and.right", isOn: $settings.hapticsEnabled)
                        toggleRow(title: "REDUCED MOTION", icon: "figure.walk.motion", isOn: $settings.reducedMotionEnabled)
                    }
                    .padding(20)
                }
            }
        }
    }

    private func sliderRow(title: String, icon: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.85))
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Float($0) }), in: 0...1)
                .tint(Theme.accentRed)
        }
        .padding(16)
        .cardStyle()
    }

    private func toggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary.opacity(0.85))
        }
        .tint(Theme.accentRed)
        .padding(16)
        .cardStyle()
    }
}
