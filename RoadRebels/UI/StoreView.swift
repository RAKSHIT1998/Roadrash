import SwiftUI
import StoreKit

struct StoreView: View {
    @ObservedObject var storeService: StoreService
    let coordinator: PurchaseCoordinator
    let onBack: () -> Void

    @State private var purchasingID: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if storeService.products.isEmpty {
                    Spacer()
                    Text(storeService.isLoadingProducts ? "Loading…" : "Store unavailable.\nConfigure products in App Store Connect.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(storeService.products.sorted(by: { ($0.price ?? 0) < ($1.price ?? 0) }), id: \.id) { product in
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

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .accessibilityIdentifier("backButton")
            Spacer()
            Text("STORE")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func productRow(_ product: Product) -> some View {
        let owned = storeService.purchasedNonConsumables.contains(product.id)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(product.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            purchaseButton(product, owned: owned)
        }
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
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
            .background(owned ? Color.white.opacity(0.15) : Color.cyan, in: Capsule())
        }
        .buttonStyle(.plain)
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
