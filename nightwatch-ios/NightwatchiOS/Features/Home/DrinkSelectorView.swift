import SwiftUI

struct DrinkSelectorView: View {
    let onSelect: (DrinkTemplate) -> Void
    @State private var selectedCategory: DrinkCategory = .beer
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 36, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DrinkCategory.allCases, id: \.self) { category in
                                CategoryTab(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    // Drinks grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(DrinkTemplate.byCategory(selectedCategory)) { template in
                                DrinkTemplateCard(template: template) {
                                    onSelect(template)
                                    dismiss()
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Ajouter une boisson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: DrinkCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 13, weight: .semibold))
                Text(categoryLabel)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: categoryGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).opacity(1)
                    : LinearGradient(
                        colors: [Color.appCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).opacity(1)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .shadow(color: isSelected ? categoryGradient.first?.opacity(0.4) ?? .clear : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var categoryIcon: String {
        switch category {
        case .beer: return "mug.fill"
        case .wine: return "wineglass.fill"
        case .cocktail: return "bubbles.and.sparkles"
        case .spirit: return "chart.bar.fill"
        case .nonAlcoholic: return "drop.fill"
        }
    }

    private var categoryLabel: String {
        switch category {
        case .beer: return "Bières"
        case .wine: return "Vins"
        case .cocktail: return "Cocktails"
        case .spirit: return "Spiritueux"
        case .nonAlcoholic: return "Sans alcool"
        }
    }

    private var categoryGradient: [Color] {
        switch category {
        case .beer: return [Color(hex: "#f59e0b"), Color(hex: "#d97706")]
        case .wine: return [Color(hex: "#9f1239"), Color(hex: "#7c3aed")]
        case .cocktail: return [Color(hex: "#ec4899"), Color(hex: "#f97316")]
        case .spirit: return [Color(hex: "#92400e"), Color(hex: "#b45309")]
        case .nonAlcoholic: return [Color(hex: "#0d9488"), Color(hex: "#0891b2")]
        }
    }
}

// MARK: - Drink Template Card
struct DrinkTemplateCard: View {
    let template: DrinkTemplate
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon area with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: categoryGradient.map { $0.opacity(0.25) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 70)

                    Image(systemName: drinkIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: categoryGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text("\(Int(template.volumeMl))ml")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)

                        if template.abv > 0 {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextSecondary)
                            Text("\(Int(template.abv * 100))%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(categoryGradient.first ?? Color.appAccentPurple)
                        } else {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appTextSecondary)
                            Text("0%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.appSuccess)
                        }
                    }

                    if template.abv > 0 {
                        Text(String(format: "%.1fg alcool", template.alcoholGrams))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.appWarning.opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.08)) { pressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.25)) { pressed = false } }
        )
    }

    private var drinkIcon: String {
        switch template.category {
        case .beer: return "mug.fill"
        case .wine: return "wineglass.fill"
        case .cocktail: return "bubbles.and.sparkles"
        case .spirit: return "chart.bar.fill"
        case .nonAlcoholic: return "drop.fill"
        }
    }

    private var categoryGradient: [Color] {
        switch template.category {
        case .beer: return [Color(hex: "#f59e0b"), Color(hex: "#d97706")]
        case .wine: return [Color(hex: "#db2777"), Color(hex: "#9333ea")]
        case .cocktail: return [Color(hex: "#ec4899"), Color(hex: "#f97316")]
        case .spirit: return [Color(hex: "#d97706"), Color(hex: "#92400e")]
        case .nonAlcoholic: return [Color(hex: "#0891b2"), Color(hex: "#0d9488")]
        }
    }
}
