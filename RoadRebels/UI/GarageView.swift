import SwiftUI
import UIKit

struct GarageView: View {
    @ObservedObject var garageState: GarageState
    @ObservedObject var careerState: CareerState
    let onBack: () -> Void

    @State private var selectedBikeID: String

    init(garageState: GarageState, careerState: CareerState, onBack: @escaping () -> Void) {
        self.garageState = garageState
        self.careerState = careerState
        self.onBack = onBack
        self._selectedBikeID = State(initialValue: garageState.selectedBikeID)
    }

    private var selectedBike: BikeModel { BikeCatalog.model(for: selectedBikeID) }

    var body: some View {
        ZStack {
            GameBackground(accent: Theme.accentCyan)
            VStack(spacing: 0) {
                ScreenHeader(title: "GARAGE", onBack: onBack) {
                    CreditsPill(amount: careerState.credits)
                }
                bikePicker
                ScrollView {
                    VStack(spacing: 14) {
                        statsCard
                        upgradesCard
                        actionButton
                        appearanceCard
                    }
                    .padding(20)
                }
            }
        }
    }

    private var bikePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BikeCatalog.all) { bike in
                    bikeChip(bike)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func bikeChip(_ bike: BikeModel) -> some View {
        let owned = garageState.isOwned(bike)
        let isSelected = bike.id == selectedBikeID
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedBikeID = bike.id
            }
        } label: {
            VStack(spacing: 4) {
                Text(bike.name)
                    .font(.system(size: 13, weight: .bold))
                if !owned {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill").font(.system(size: 8))
                        Text("\(bike.unlockCost) CR")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundStyle(isSelected ? .black : Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Theme.cardFill),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? .clear : Theme.cardStroke, lineWidth: 1)
            )
            .opacity(owned ? 1 : 0.65)
        }
        .buttonStyle(RowPressStyle())
    }

    private var statsCard: some View {
        let tuning = garageState.tuning(for: selectedBikeID)
        return VStack(alignment: .leading, spacing: 12) {
            Label("PERFORMANCE", systemImage: "chart.bar.fill")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            statRow("SPEED", tuning.speedMultiplier)
            statRow("ACCELERATION", tuning.accelMultiplier)
            statRow("HANDLING", tuning.handlingMultiplier)
            statRow("BRAKING", tuning.brakeMultiplier)
            statRow("DURABILITY", 1 + tuning.maxHealthBonus / GameConstants.riderMaxHealth)
        }
        .padding(16)
        .cardStyle()
    }

    private func statRow(_ label: String, _ multiplier: Float) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.accentRed.opacity(0.7), Theme.accentRed], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(min(1.4, multiplier) / 1.4))
                }
            }
            .frame(width: 120, height: 8)
        }
    }

    private var upgradesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("UPGRADES", systemImage: "wrench.and.screwdriver.fill")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            ForEach(UpgradeCategory.allCases, id: \.self) { category in
                upgradeRow(category)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func upgradeRow(_ category: UpgradeCategory) -> some View {
        let owned = garageState.isOwned(selectedBike)
        let level = garageState.upgradeLevel(category, for: selectedBikeID)
        let maxed = level >= BikeTuningCalculator.maxUpgradeLevel
        let cost = garageState.upgradeCost(category, for: selectedBikeID)

        return HStack {
            Text(category.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 3) {
                ForEach(0..<BikeTuningCalculator.maxUpgradeLevel, id: \.self) { pip in
                    Circle()
                        .fill(pip < level ? Theme.accentCyan : Color.white.opacity(0.15))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    _ = garageState.upgrade(category, for: selectedBikeID, careerState: careerState)
                }
            } label: {
                Text(maxed ? "MAX" : "+\(cost) CR")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(maxed ? Theme.textTertiary : .black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(maxed ? Color.white.opacity(0.1) : Theme.accentCyan, in: Capsule())
            }
            .buttonStyle(RowPressStyle())
            .disabled(maxed || !owned || careerState.credits < cost)
        }
    }

    private var actionButton: some View {
        let owned = garageState.isOwned(selectedBike)
        let isCurrent = owned && garageState.selectedBikeID == selectedBikeID
        return Button {
            if owned {
                garageState.selectBike(selectedBike)
            } else {
                garageState.unlockBike(selectedBike, careerState: careerState)
            }
        } label: {
            HStack {
                Image(systemName: isCurrent ? "checkmark.circle.fill" : (owned ? "checkmark" : "lock.open.fill"))
                Text(owned ? (isCurrent ? "SELECTED" : "SELECT") : "UNLOCK · \(selectedBike.unlockCost) CR")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isCurrent)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("APPEARANCE", systemImage: "paintbrush.fill")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            Text("PAINT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PaintCatalog.all) { paint in
                        swatch(
                            color: Color(paint.color),
                            name: paint.name,
                            cost: paint.cost,
                            owned: garageState.isOwned(paint),
                            selected: garageState.selectedPaintID == paint.id,
                            canAfford: careerState.credits >= paint.cost
                        ) {
                            if garageState.isOwned(paint) {
                                garageState.selectPaint(paint)
                            } else {
                                garageState.unlockPaint(paint, careerState: careerState)
                            }
                        }
                    }
                }
            }

            Text("HELMET")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HelmetCatalog.all) { helmet in
                        swatch(
                            color: Color(helmet.color),
                            name: helmet.name,
                            cost: helmet.cost,
                            owned: garageState.isOwned(helmet),
                            selected: garageState.selectedHelmetID == helmet.id,
                            canAfford: careerState.credits >= helmet.cost
                        ) {
                            if garageState.isOwned(helmet) {
                                garageState.selectHelmet(helmet)
                            } else {
                                garageState.unlockHelmet(helmet, careerState: careerState)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func swatch(color: Color, name: String, cost: Int, owned: Bool, selected: Bool, canAfford: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle().stroke(selected ? Color.white : Theme.cardStroke, lineWidth: selected ? 3 : 1)
                    )
                    .overlay(
                        Group {
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(color.isLight ? .black : .white)
                            } else if !owned {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(color.isLight ? .black : .white)
                            }
                        }
                    )
                Text(owned ? name : "\(cost) CR")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(RowPressStyle())
        .disabled(owned ? selected : !canAfford)
        .opacity(!owned && !canAfford ? 0.5 : 1)
    }
}

private extension Color {
    var isLight: Bool {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return false }
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness > 0.6
    }
}
