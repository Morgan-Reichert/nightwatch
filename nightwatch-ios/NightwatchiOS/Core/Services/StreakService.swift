import Foundation
import SwiftUI

struct StreakInfo {
    let weeks: Int
    let color: Color
    let label: String
}

struct StreakService {

    static func calculateStreak(drinks: [Drink]) -> StreakInfo {
        let alcoholicDrinks = drinks.filter { $0.abv > 0 }
        guard !alcoholicDrinks.isEmpty else {
            return StreakInfo(weeks: 0, color: .gray, label: "Aucun streak")
        }

        let calendar = Calendar(identifier: .iso8601)
        var weeksWithDrinks = Set<String>()

        for drink in alcoholicDrinks {
            guard let date = drink.createdAt else { continue }
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            if let year = components.yearForWeekOfYear, let week = components.weekOfYear {
                weeksWithDrinks.insert("\(year)-\(week)")
            }
        }

        let sortedWeeks = weeksWithDrinks.sorted(by: >)
        guard let latestWeekStr = sortedWeeks.first else {
            return StreakInfo(weeks: 0, color: .gray, label: "Aucun streak")
        }

        let now = Date()
        let currentComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let currentYear = currentComponents.yearForWeekOfYear,
              let currentWeek = currentComponents.weekOfYear else {
            return StreakInfo(weeks: 0, color: .gray, label: "Aucun streak")
        }

        let currentWeekStr = "\(currentYear)-\(currentWeek)"
        let previousWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let prevComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: previousWeekDate)
        let prevWeekStr = "\(prevComponents.yearForWeekOfYear ?? 0)-\(prevComponents.weekOfYear ?? 0)"

        guard latestWeekStr == currentWeekStr || latestWeekStr == prevWeekStr else {
            return StreakInfo(weeks: 0, color: .gray, label: "Streak brisé")
        }

        var streak = 0
        var checkWeekDate = latestWeekStr == currentWeekStr ? now : previousWeekDate

        for _ in 0..<weeksWithDrinks.count {
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkWeekDate)
            guard let yr = comps.yearForWeekOfYear, let wk = comps.weekOfYear else { break }
            let weekStr = "\(yr)-\(wk)"
            if weeksWithDrinks.contains(weekStr) {
                streak += 1
                checkWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: checkWeekDate) ?? checkWeekDate
            } else {
                break
            }
        }

        return makeStreakInfo(weeks: streak)
    }

    private static func makeStreakInfo(weeks: Int) -> StreakInfo {
        switch weeks {
        case 0:
            return StreakInfo(weeks: 0, color: Color(hex: "#6B7280"), label: "Aucun streak")
        case 1...2:
            return StreakInfo(weeks: weeks, color: Color(hex: "#3B82F6"), label: "\(weeks) semaine\(weeks > 1 ? "s" : "")")
        case 3...4:
            return StreakInfo(weeks: weeks, color: Color(hex: "#8B5CF6"), label: "\(weeks) semaines")
        case 5...9:
            return StreakInfo(weeks: weeks, color: Color(hex: "#F59E0B"), label: "\(weeks) semaines")
        default:
            return StreakInfo(weeks: weeks, color: Color(hex: "#EF4444"), label: "\(weeks) semaines")
        }
    }
}
