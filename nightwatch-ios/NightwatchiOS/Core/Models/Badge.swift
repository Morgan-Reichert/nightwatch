import Foundation
import SwiftUI

enum BadgeTier: String {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case diamond = "Diamond"

    var color: Color {
        switch self {
        case .bronze: return Color(hex: "#CD7F32")
        case .silver: return Color(hex: "#C0C0C0")
        case .gold: return Color(hex: "#FFD700")
        case .diamond: return Color(hex: "#B9F2FF")
        }
    }

    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .diamond: return "💎"
        }
    }
}

enum BadgeCategory: String {
    case drinks = "Drinks"
    case parties = "Parties"
    case pukes = "Pukes"
    case kisses = "Kisses"
    case friends = "Friends"
}

struct BadgeDefinition: Identifiable {
    let id: String
    let name: String
    let category: BadgeCategory
    let thresholds: [Int]
    let emoji: String
    let description: String

    func tier(for count: Int) -> BadgeTier? {
        let achieved = thresholds.filter { count >= $0 }
        switch achieved.count {
        case 0: return nil
        case 1: return .bronze
        case 2: return .silver
        case 3: return .gold
        default: return .diamond
        }
    }

    func progress(for count: Int) -> Double {
        guard let nextThreshold = thresholds.first(where: { count < $0 }) else {
            return 1.0
        }
        let prevThreshold = thresholds.last(where: { count >= $0 }) ?? 0
        let range = Double(nextThreshold - prevThreshold)
        let progress = Double(count - prevThreshold)
        return range > 0 ? min(progress / range, 1.0) : 1.0
    }
}

struct EarnedBadge: Identifiable {
    var id: String { definition.id }
    let definition: BadgeDefinition
    let tier: BadgeTier
    let earnedAt: Date
}

extension BadgeDefinition {
    static let all: [BadgeDefinition] = [
        // Drinks
        BadgeDefinition(id: "drinks_first", name: "First Sip", category: .drinks, thresholds: [1, 10, 25, 50], emoji: "🍻", description: "Log your first drink"),
        BadgeDefinition(id: "drinks_10", name: "Getting Started", category: .drinks, thresholds: [10, 25, 50, 100], emoji: "🍺", description: "Log 10 drinks total"),
        BadgeDefinition(id: "drinks_25", name: "Regular", category: .drinks, thresholds: [25, 50, 100, 200], emoji: "🥂", description: "Log 25 drinks total"),
        BadgeDefinition(id: "drinks_50", name: "Heavy", category: .drinks, thresholds: [50, 100, 200, 500], emoji: "🍾", description: "Log 50 drinks total"),
        BadgeDefinition(id: "drinks_100", name: "Legend", category: .drinks, thresholds: [100, 200, 500, 1000], emoji: "👑", description: "Log 100 drinks total"),
        // Parties
        BadgeDefinition(id: "parties_1", name: "Newcomer", category: .parties, thresholds: [1, 5, 10, 25], emoji: "🎉", description: "Join your first party"),
        BadgeDefinition(id: "parties_5", name: "Party Animal", category: .parties, thresholds: [5, 10, 25, 50], emoji: "🦁", description: "Join 5 parties"),
        BadgeDefinition(id: "parties_10", name: "Social Legend", category: .parties, thresholds: [10, 25, 50, 100], emoji: "🌟", description: "Join 10 parties"),
        // Pukes
        BadgeDefinition(id: "pukes_1", name: "First Quiche", category: .pukes, thresholds: [1, 3, 5, 10], emoji: "🤢", description: "Your first puke event"),
        BadgeDefinition(id: "pukes_3", name: "Cast Iron", category: .pukes, thresholds: [3, 5, 10, 20], emoji: "💪", description: "3 puke events"),
        BadgeDefinition(id: "pukes_5", name: "Unstoppable", category: .pukes, thresholds: [5, 10, 20, 50], emoji: "🔥", description: "5 puke events"),
        // Kisses/ShopEvents
        BadgeDefinition(id: "kisses_1", name: "First Kiss", category: .kisses, thresholds: [1, 5, 10, 25], emoji: "💋", description: "First shop event"),
        BadgeDefinition(id: "kisses_5", name: "Heartbreaker", category: .kisses, thresholds: [5, 10, 25, 50], emoji: "💔", description: "5 shop events"),
        BadgeDefinition(id: "kisses_10", name: "Casanova", category: .kisses, thresholds: [10, 25, 50, 100], emoji: "😘", description: "10 shop events"),
        // Friends
        BadgeDefinition(id: "friends_1", name: "Making Friends", category: .friends, thresholds: [1, 5, 10, 25], emoji: "🤝", description: "Make your first friend"),
        BadgeDefinition(id: "friends_5", name: "Popular", category: .friends, thresholds: [5, 10, 25, 50], emoji: "😎", description: "Have 5 friends"),
        BadgeDefinition(id: "friends_10", name: "Social Butterfly", category: .friends, thresholds: [10, 25, 50, 100], emoji: "🦋", description: "Have 10 friends")
    ]
}
