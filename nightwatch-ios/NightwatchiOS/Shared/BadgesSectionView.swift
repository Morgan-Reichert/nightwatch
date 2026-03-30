import SwiftUI

struct BadgesSectionView: View {
    let earnedBadges: [EarnedBadge]
    let stats: UserStats

    private let columns = [
        GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Stats summary
                HStack(spacing: 0) {
                    BadgeStatCell(label: "Boissons", value: "\(stats.totalDrinks)", icon: "mug.fill", color: Color.appAccentBlue)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 40)
                    BadgeStatCell(label: "Soirées", value: "\(stats.totalParties)", icon: "party.popper.fill", color: Color.appAccentPurple)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 40)
                    BadgeStatCell(label: "Amis", value: "\(stats.totalFriends)", icon: "person.2.fill", color: Color.appSuccess)
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appCard.opacity(0.7))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
                )
                .padding(.horizontal)

                // Progress header
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FFD700"))
                    Text("Badges (\(earnedBadges.count)/\(BadgeDefinition.all.count))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Overall progress
                    Text("\(Int(Double(earnedBadges.count) / Double(BadgeDefinition.all.count) * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appAccentPurple)
                }
                .padding(.horizontal)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appCard)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appAccentPurple, Color.appAccentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, geo.size.width * CGFloat(earnedBadges.count) / CGFloat(max(1, BadgeDefinition.all.count))),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)

                // Badges grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(BadgeDefinition.all) { definition in
                        let earned = earnedBadges.first { $0.definition.id == definition.id }
                        BadgeCell(definition: definition, earned: earned, stats: stats)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Stat Cell
struct BadgeStatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Badge Cell
struct BadgeCell: View {
    let definition: BadgeDefinition
    let earned: EarnedBadge?
    let stats: UserStats

    private var count: Int {
        switch definition.category {
        case .drinks: return stats.totalDrinks
        case .parties: return stats.totalParties
        case .pukes: return stats.totalPukes
        case .kisses: return stats.totalKisses
        case .friends: return stats.totalFriends
        }
    }

    private var categoryIcon: String {
        switch definition.category {
        case .drinks: return "mug.fill"
        case .parties: return "party.popper.fill"
        case .pukes: return "exclamationmark.triangle.fill"
        case .kisses: return "heart.fill"
        case .friends: return "person.2.fill"
        }
    }

    private var tierIcon: String {
        guard let earned else { return "" }
        switch earned.tier {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(earned != nil ? earned!.tier.color.opacity(0.15) : Color.appCard.opacity(0.5))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle().stroke(
                            earned != nil ? earned!.tier.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: earned != nil ? 2 : 1
                        )
                    )

                Image(systemName: categoryIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        earned != nil
                            ? earned!.tier.color
                            : Color.appTextSecondary.opacity(0.3)
                    )

                // Lock overlay for unearned
                if earned == nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#0a0a0f"))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }
                    }
                    .frame(width: 58, height: 58)
                }

                // Tier badge for earned
                if let earned {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#0a0a0f"))
                                    .frame(width: 20, height: 20)
                                Image(systemName: tierIcon)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(earned.tier.color)
                            }
                            .offset(x: 4, y: -4)
                        }
                        Spacer()
                    }
                    .frame(width: 58, height: 58)
                }
            }

            Text(definition.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(earned != nil ? .white : Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 28)

            if let earned {
                Text(earned.tier.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(earned.tier.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(earned.tier.color.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                // Progress bar
                let progress = definition.progress(for: count)
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appCard)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.appAccentPurple.opacity(0.7))
                                .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 4)
                        }
                    }
                    .frame(height: 4)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(earned != nil ? 0.8 : 0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            earned != nil ? earned!.tier.color.opacity(0.2) : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
    }
}
