import SwiftUI

struct ShopView: View {
    @State private var viewModel = ShopViewModel()
    let profile: Profile
    @State private var selectedCategory: ShopItemType = .avatarFrame
    @State private var confirmingPurchase: ShopItem?
    @State private var equippingItem: ShopItem?

    private let shopCategories: [(ShopItemType, String, String)] = [
        (.avatarFrame, "Cadres Avatar", "person.crop.circle.fill"),
        (.bannerGradient, "Bannières", "rectangle.fill"),
        (.streakRestore, "Boost", "flame.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 0) {
                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(shopCategories, id: \.0) { type, label, icon in
                                ShopCategoryTab(
                                    icon: icon,
                                    label: label,
                                    isSelected: selectedCategory == type,
                                    type: type
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedCategory = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Streak restore — featured separately
                            if selectedCategory == .streakRestore {
                                StreakRestoreSection(
                                    item: ShopItem.items(ofType: .streakRestore).first,
                                    isPurchased: ShopItem.items(ofType: .streakRestore).first.map { viewModel.hasPurchased($0.id) } ?? false,
                                    onPurchase: { item in confirmingPurchase = item }
                                )
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            } else {
                                let items = ShopItem.items(ofType: selectedCategory)
                                LazyVGrid(
                                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                                    spacing: 14
                                ) {
                                    ForEach(items) { item in
                                        ShopItemCard(
                                            item: item,
                                            isPurchased: viewModel.hasPurchased(item.id),
                                            isEquipped: isEquipped(item),
                                            onAction: {
                                                if viewModel.hasPurchased(item.id) {
                                                    Task { await viewModel.equip(item: item) }
                                                } else {
                                                    confirmingPurchase = item
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            }

                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .navigationTitle("Boutique")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await viewModel.load(profile: profile)
        }
        .alert("Acheter cet article", isPresented: Binding(
            get: { confirmingPurchase != nil },
            set: { if !$0 { confirmingPurchase = nil } }
        )) {
            if let item = confirmingPurchase {
                Button("Acheter \(item.formattedPrice)") {
                    Task { await viewModel.initiatePurchase(item: item) }
                    confirmingPurchase = nil
                }
                Button("Annuler", role: .cancel) { confirmingPurchase = nil }
            }
        } message: {
            if let item = confirmingPurchase {
                Text("Acheter \"\(item.name)\" pour \(item.formattedPrice) ?")
            }
        }
        .alert("Succès", isPresented: Binding(
            get: { viewModel.purchaseMessage != nil },
            set: { if !$0 { viewModel.purchaseMessage = nil } }
        )) {
            Button("OK") { viewModel.purchaseMessage = nil }
        } message: {
            Text(viewModel.purchaseMessage ?? "")
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .preferredColorScheme(.dark)
    }

    private func isEquipped(_ item: ShopItem) -> Bool {
        switch item.type {
        case .avatarFrame: return viewModel.profile?.avatarFrame == item.id
        case .bannerGradient: return viewModel.profile?.bannerGradient == item.id
        case .streakRestore: return false
        }
    }
}

// MARK: - Category Tab
struct ShopCategoryTab: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let type: ShopItemType
    let action: () -> Void

    private var tabColor: Color {
        switch type {
        case .avatarFrame: return Color.appAccentPurple
        case .bannerGradient: return Color.appAccentBlue
        case .streakRestore: return Color(hex: "#f97316")
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected
                ? tabColor.opacity(0.85)
                : Color.appCard
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: isSelected ? tabColor.opacity(0.4) : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Restore Section
struct StreakRestoreSection: View {
    let item: ShopItem?
    let isPurchased: Bool
    let onPurchase: (ShopItem) -> Void

    var body: some View {
        guard let item else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(spacing: 20) {
                // Hero area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#ff4500").opacity(0.3), Color(hex: "#ff8c00").opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(colors: [Color(hex: "#ff4500").opacity(0.5), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )

                    VStack(spacing: 14) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#ff4500"), Color(hex: "#ff8c00")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hex: "#ff4500").opacity(0.5), radius: 16, x: 0, y: 8)

                        Text(item.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text(item.description ?? "Restaurez votre streak de soirées brisé et continuez votre progression")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {
                            if !isPurchased { onPurchase(item) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isPurchased ? "checkmark.seal.fill" : "flame.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(isPurchased ? "Utilisé" : item.formattedPrice)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                isPurchased
                                ? AnyShapeStyle(Color.appTextSecondary)
                                : AnyShapeStyle(LinearGradient(colors: [Color(hex: "#ff4500"), Color(hex: "#ff8c00")], startPoint: .leading, endPoint: .trailing))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: isPurchased ? .clear : Color(hex: "#ff4500").opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        .disabled(isPurchased)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 28)
                }
            }
        )
    }
}

// MARK: - Shop Item Card
struct ShopItemCard: View {
    let item: ShopItem
    let isPurchased: Bool
    let isEquipped: Bool
    let onAction: () -> Void

    @State private var animateFrame = false

    private var actionLabel: String {
        if isEquipped { return "Équipé" }
        if isPurchased { return "Équiper" }
        return item.formattedPrice
    }

    private var actionColor: Color {
        if isEquipped { return Color.appSuccess }
        if isPurchased { return Color.appAccentBlue }
        return Color.appAccentPurple
    }

    var body: some View {
        VStack(spacing: 0) {
            // Preview area
            ZStack {
                if item.type == .avatarFrame {
                    // Avatar frame preview
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#0d0d18"))
                        .frame(height: 120)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: item.previewColors.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)

                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.appTextSecondary.opacity(0.6))

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: item.previewColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: animateFrame && isEquipped ? 4 : 3
                            )
                            .frame(width: 72, height: 72)
                            .scaleEffect(animateFrame && isEquipped ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateFrame)
                    }
                    .shadow(color: item.previewColors.first?.opacity(0.4) ?? .clear, radius: animateFrame && isEquipped ? 12 : 6, x: 0, y: 0)

                } else if item.type == .bannerGradient {
                    // Banner gradient preview
                    LinearGradient(
                        colors: item.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Owned badge overlay
                if isPurchased {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.appSuccess)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let desc = item.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                }

                Button(action: onAction) {
                    HStack(spacing: 5) {
                        if isEquipped {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                        } else if isPurchased {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                        } else {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Text(actionLabel)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isEquipped
                        ? AnyShapeStyle(Color.appSuccess.opacity(0.8))
                        : isPurchased
                            ? AnyShapeStyle(Color.appAccentBlue.opacity(0.9))
                            : AnyShapeStyle(LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .disabled(isEquipped)
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isEquipped
                            ? Color.appSuccess.opacity(0.4)
                            : isPurchased
                                ? Color.appAccentBlue.opacity(0.3)
                                : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            if isEquipped { animateFrame = true }
        }
        .onChange(of: isEquipped) { _, equipped in
            animateFrame = equipped
        }
    }
}
