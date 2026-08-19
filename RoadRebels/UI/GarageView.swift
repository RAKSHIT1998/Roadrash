import SwiftUI

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
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                bikePicker
                ScrollView {
                    VStack(spacing: 14) {
                        statsCard
                        upgradesCard
                        actionButton
                    }
                    .padding(20)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
            }
            Spacer()
            Text("GARAGE")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text("\(careerState.credits) CR")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
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
            selectedBikeID = bike.id
        } label: {
            VStack(spacing: 4) {
                Text(bike.name)
                    .font(.system(size: 13, weight: .bold))
                if !owned {
                    Text("\(bike.unlockCost) CR")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundStyle(isSelected ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.white.opacity(owned ? 0.1 : 0.05), in: RoundedRectangle(cornerRadius: 10))
            .opacity(owned ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }

    private var statsCard: some View {
        let tuning = garageState.tuning(for: selectedBikeID)
        return VStack(alignment: .leading, spacing: 10) {
            statRow("SPEED", tuning.speedMultiplier)
            statRow("ACCELERATION", tuning.accelMultiplier)
            statRow("HANDLING", tuning.handlingMultiplier)
            statRow("BRAKING", tuning.brakeMultiplier)
            statRow("DURABILITY", 1 + tuning.maxHealthBonus / GameConstants.riderMaxHealth)
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statRow(_ label: String, _ multiplier: Float) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    Capsule().fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(min(1.4, multiplier) / 1.4))
                }
            }
            .frame(width: 120, height: 8)
        }
    }

    private var upgradesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPGRADES")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            ForEach(UpgradeCategory.allCases, id: \.self) { category in
                upgradeRow(category)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private func upgradeRow(_ category: UpgradeCategory) -> some View {
        let owned = garageState.isOwned(selectedBike)
        let level = garageState.upgradeLevel(category, for: selectedBikeID)
        let maxed = level >= BikeTuningCalculator.maxUpgradeLevel
        let cost = garageState.upgradeCost(category, for: selectedBikeID)

        return HStack {
            Text(category.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            HStack(spacing: 3) {
                ForEach(0..<BikeTuningCalculator.maxUpgradeLevel, id: \.self) { pip in
                    Circle()
                        .fill(pip < level ? Color.cyan : Color.white.opacity(0.15))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button {
                garageState.upgrade(category, for: selectedBikeID, careerState: careerState)
            } label: {
                Text(maxed ? "MAX" : "+\(cost) CR")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(maxed ? .white.opacity(0.4) : .black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(maxed ? Color.white.opacity(0.1) : Color.cyan, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(maxed || !owned || careerState.credits < cost)
        }
    }

    private var actionButton: some View {
        let owned = garageState.isOwned(selectedBike)
        return Button {
            if owned {
                garageState.selectBike(selectedBike)
            } else {
                garageState.unlockBike(selectedBike, careerState: careerState)
            }
        } label: {
            Text(owned ? (garageState.selectedBikeID == selectedBikeID ? "SELECTED" : "SELECT") : "UNLOCK · \(selectedBike.unlockCost) CR")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(owned && garageState.selectedBikeID == selectedBikeID)
    }
}
