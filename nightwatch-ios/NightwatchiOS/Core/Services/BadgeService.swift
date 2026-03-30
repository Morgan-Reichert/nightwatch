import Foundation

struct UserStats {
    let totalDrinks: Int
    let totalParties: Int
    let totalPukes: Int
    let totalKisses: Int
    let totalFriends: Int
}

struct BadgeService {

    static func computeEarnedBadges(stats: UserStats) -> [EarnedBadge] {
        var earned: [EarnedBadge] = []

        for definition in BadgeDefinition.all {
            let count: Int
            switch definition.category {
            case .drinks: count = stats.totalDrinks
            case .parties: count = stats.totalParties
            case .pukes: count = stats.totalPukes
            case .kisses: count = stats.totalKisses
            case .friends: count = stats.totalFriends
            }

            if let tier = definition.tier(for: count) {
                earned.append(EarnedBadge(
                    definition: definition,
                    tier: tier,
                    earnedAt: Date()
                ))
            }
        }

        return earned
    }

    static func badgeProgress(definition: BadgeDefinition, count: Int) -> Double {
        definition.progress(for: count)
    }

    static func nextMilestone(definition: BadgeDefinition, count: Int) -> Int? {
        definition.thresholds.first(where: { count < $0 })
    }
}
