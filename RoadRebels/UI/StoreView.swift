import SwiftUI
import StoreKit

struct StoreView: View {
    @ObservedObject var storeService: StoreService
    let coordinator: PurchaseCoordinator
    let onBack: () -> Void

    @State private var purchasingID: String?

    var body: some View {
        ZStack {
            GameBackground(accent: Theme.accentYellow)
            VStack(spacing: 0) {
                ScreenHeader(title: "STORE", onBack: onBack) { HeaderSpacer() }
                if storeService.products.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(storeService.products.sorted(by: { ($0.price) < ($1.price) }), id: \.id) { product in
                                productRow(product)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .task {
            coordinator.syncEntitlements()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: storeService.isLoadingProducts ? "hourglass" : "bag.badge.questionmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
            Text(storeService.isLoadingProducts ? "Loading…" : "Store unavailable.\nConfigure products in App Store Connect.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding()
    }

    private func productRow(_ product: Product) -> some View {
        let owned = storeService.purchasedNonConsumables.contains(product.id)
        let isPro = product.id == StoreProductID.pro.rawValue
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isPro ? Theme.accentYellow.opacity(0.18) : Theme.cardFill)
                    .frame(width: 40, height: 40)
                Image(systemName: icon(for: product.id))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isPro ? Theme.accentYellow : Theme.accentCyan)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(product.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            purchaseButton(product, owned: owned)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .stroke(isPro ? Theme.accentYellow.opacity(0.4) : Theme.cardStroke, lineWidth: isPro ? 1.5 : 1)
                )
        )
    }

    private func icon(for productID: String) -> String {
        switch StoreProductID(rawValue: productID) {
        case .pro: return "crown.fill"
        case .removeAds: return "bolt.slash.fill"
        case .starterPack: return "gift.fill"
        case .creditsSmall, .creditsLarge: return "circle.hexagongrid.fill"
        case .none: return "bag.fill"
        }
    }

    private func purchaseButton(_ product: Product, owned: Bool) -> some View {
        Button {
            buy(product)
        } label: {
            Group {
                if purchasingID == product.id {
                    ProgressView().tint(.black)
                } else {
                    Text(owned ? "OWNED" : product.displayPrice)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(owned ? Color.white.opacity(0.15) : Theme.accentCyan, in: Capsule())
        }
        .buttonStyle(RowPressStyle())
        .disabled(owned || purchasingID != nil)
    }

    private func buy(_ product: Product) {
        purchasingID = product.id
        Task {
            _ = await coordinator.purchase(product)
            purchasingID = nil
        }
    }
}
