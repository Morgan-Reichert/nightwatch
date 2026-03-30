import Foundation
import Observation
import SwiftUI

// MARK: - Models

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let profile: Profile
    let value: Double
    let displayValue: String
    var rank: Int
}

enum LeaderboardCategory: String, CaseIterable {
    case alcohol   = "Alcool"
    case kisses    = "Bisous"
    case pukes     = "Quiches"
    case hydration = "Hydratation"

    var icon: String {
        switch self {
        case .alcohol:    return "drop.fill"
        case .kisses:     return "heart.fill"
        case .pukes:      return "exclamationmark.bubble.fill"
        case .hydration:  return "drop"
        }
    }

    var accentColor: Color {
        switch self {
        case .alcohol:    return .appWarning
        case .kisses:     return Color(hex: "#ec4899")
        case .pukes:      return Color(hex: "#f97316")
        case .hydration:  return .appAccentBlue
        }
    }
}

// Scope: either current party members only, or all friends (today)
enum LeaderboardScope: String, CaseIterable {
    case party   = "Soirée"
    case friends = "Amis"

    var icon: String {
        switch self {
        case .party:   return "party.popper.fill"
        case .friends: return "person.2.fill"
        }
    }
}

// MARK: - ViewModel

@Observable
class LeaderboardViewModel {
    var partyKings: [LeaderboardEntry]     = []
    var kissLeaders: [LeaderboardEntry]    = []
    var pukeLeaders: [LeaderboardEntry]    = []
    var hydrationHeroes: [LeaderboardEntry] = []
    var showMyBAC: Bool                    = true
    var selectedCategory: LeaderboardCategory = .alcohol
    var selectedScope: LeaderboardScope    = .party
    var isLoading                          = false
    var errorMessage: String?
    var profile: Profile?
    var activeParty: Party?

    // Legacy
    var selectedFilter: LeaderboardFilter = .bac

    var currentEntries: [LeaderboardEntry] {
        switch selectedCategory {
        case .alcohol:    return partyKings
        case .kisses:     return kissLeaders
        case .pukes:      return pukeLeaders
        case .hydration:  return hydrationHeroes
        }
    }

    var sortedEntries: [LeaderboardEntry] { currentEntries }

    @MainActor
    func load(profile: Profile) async {
        self.profile = profile
        await refresh()
    }

    @MainActor
    func refresh() async {
        guard let profile else { return }
        isLoading = true

        // Always resolve active party first
        await resolveActiveParty(for: profile)

        switch selectedScope {
        case .party:
            await loadPartyScope(profile: profile)
        case .friends:
            await loadFriendsScope(profile: profile)
        }

        isLoading = false
    }

    // MARK: - Scope: Soirée (party members, stats by party_id)

    @MainActor
    private func loadPartyScope(profile: Profile) async {
        guard let party = activeParty else {
            clearEntries()
            return
        }

        do {
            // Fetch all party members
            struct MemberRow: Decodable {
                let userId: UUID
                enum CodingKeys: String, CodingKey { case userId = "user_id" }
            }
            let memberRows: [MemberRow] = try await supabase
                .from("party_members")
                .select("user_id")
                .eq("party_id", value: party.id.uuidString)
                .execute()
                .value

            let memberIds = memberRows.map(\.userId)

            let today    = Calendar.current.startOfDay(for: Date())
            let todayStr = ISO8601DateFormatter().string(from: today)

            var kingsTemp:      [LeaderboardEntry] = []
            var kissTemp:       [LeaderboardEntry] = []
            var pukeTemp:       [LeaderboardEntry] = []
            var hydrationTemp:  [LeaderboardEntry] = []

            for userId in memberIds {
                do {
                    let userProfile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("user_id", value: userId.uuidString)
                        .single()
                        .execute()
                        .value

                    // Drinks filtered by today → same range as home page & friends scope
                    // so BAC is always consistent across all views
                    let drinks: [Drink] = try await supabase
                        .from("drinks")
                        .select()
                        .eq("user_id", value: userId.uuidString)
                        .gte("created_at", value: todayStr)
                        .execute()
                        .value

                    // Alcohol (BAC) — identical calculation to home page
                    let totalGrams = drinks.reduce(0.0) { $0 + $1.alcoholGrams }
                    let bac        = BACCalculator.calculateBAC(drinks: drinks, profile: userProfile)
                    let bacDisplay = (showMyBAC || userId != profile.userId)
                        ? String(format: "%.3f g/L", bac) : "---"
                    kingsTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                      value: totalGrams, displayValue: bacDisplay, rank: 0))

                    // Hydration (non-alcoholic, today)
                    let hydCount = Double(drinks.filter { $0.abv == 0 }.count)
                    hydrationTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                          value: hydCount,
                                                          displayValue: "\(Int(hydCount)) boissons", rank: 0))

                    // Kisses scoped to party
                    let kisses: [ShopEvent] = (try? await supabase
                        .from("shop_events")
                        .select()
                        .eq("user_id",  value: userId.uuidString)
                        .eq("party_id", value: party.id.uuidString)
                        .execute()
                        .value) ?? []
                    kissTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                     value: Double(kisses.count),
                                                     displayValue: "\(kisses.count) bisous", rank: 0))

                    // Pukes scoped to party
                    let pukes: [PukeEvent] = (try? await supabase
                        .from("puke_events")
                        .select()
                        .eq("user_id",  value: userId.uuidString)
                        .eq("party_id", value: party.id.uuidString)
                        .execute()
                        .value) ?? []
                    pukeTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                     value: Double(pukes.count),
                                                     displayValue: "\(pukes.count) quiches", rank: 0))
                } catch {}
            }

            partyKings      = ranked(kingsTemp.sorted      { $0.value > $1.value })
            kissLeaders     = ranked(kissTemp.sorted       { $0.value > $1.value })
            pukeLeaders     = ranked(pukeTemp.sorted       { $0.value > $1.value })
            hydrationHeroes = ranked(hydrationTemp.sorted  { $0.value > $1.value })

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Scope: Amis (all friends, stats today)

    @MainActor
    private func loadFriendsScope(profile: Profile) async {
        do {
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(profile.userId.uuidString)")
                .eq("status", value: "accepted")
                .execute()
                .value

            let friendIds  = friendships.map { f -> UUID in
                f.requesterId == profile.userId ? f.addresseeId : f.requesterId
            }
            let allUserIds = [profile.userId] + friendIds

            let today    = Calendar.current.startOfDay(for: Date())
            let todayStr = ISO8601DateFormatter().string(from: today)

            var kingsTemp:      [LeaderboardEntry] = []
            var kissTemp:       [LeaderboardEntry] = []
            var pukeTemp:       [LeaderboardEntry] = []
            var hydrationTemp:  [LeaderboardEntry] = []

            for userId in allUserIds {
                do {
                    let userProfile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("user_id", value: userId.uuidString)
                        .single()
                        .execute()
                        .value

                    let drinks: [Drink] = try await supabase
                        .from("drinks")
                        .select()
                        .eq("user_id",    value: userId.uuidString)
                        .gte("created_at", value: todayStr)
                        .execute()
                        .value

                    let totalGrams = drinks.reduce(0.0) { $0 + $1.alcoholGrams }
                    let bac        = BACCalculator.calculateBAC(drinks: drinks, profile: userProfile)
                    let bacDisplay = (showMyBAC || userId != profile.userId)
                        ? String(format: "%.3f g/L", bac) : "---"
                    kingsTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                      value: totalGrams, displayValue: bacDisplay, rank: 0))

                    let hydCount = Double(drinks.filter { $0.abv == 0 }.count)
                    hydrationTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                          value: hydCount,
                                                          displayValue: "\(Int(hydCount)) boissons", rank: 0))

                    let kisses: [ShopEvent] = (try? await supabase
                        .from("shop_events").select()
                        .eq("user_id", value: userId.uuidString)
                        .gte("created_at", value: todayStr)
                        .execute().value) ?? []
                    kissTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                     value: Double(kisses.count),
                                                     displayValue: "\(kisses.count) bisous", rank: 0))

                    let pukes: [PukeEvent] = (try? await supabase
                        .from("puke_events").select()
                        .eq("user_id", value: userId.uuidString)
                        .gte("created_at", value: todayStr)
                        .execute().value) ?? []
                    pukeTemp.append(LeaderboardEntry(id: userProfile.id, profile: userProfile,
                                                     value: Double(pukes.count),
                                                     displayValue: "\(pukes.count) quiches", rank: 0))
                } catch {}
            }

            partyKings      = ranked(kingsTemp.sorted      { $0.value > $1.value })
            kissLeaders     = ranked(kissTemp.sorted       { $0.value > $1.value })
            pukeLeaders     = ranked(pukeTemp.sorted       { $0.value > $1.value })
            hydrationHeroes = ranked(hydrationTemp.sorted  { $0.value > $1.value })

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    @MainActor
    private func resolveActiveParty(for profile: Profile) async {
        struct MemberRow: Decodable {
            let partyId: UUID
            enum CodingKeys: String, CodingKey { case partyId = "party_id" }
        }
        guard let rows = try? await (supabase
            .from("party_members")
            .select("party_id")
            .eq("user_id", value: profile.userId.uuidString)
            .order("joined_at", ascending: false)
            .limit(5)
            .execute()
            .value as [MemberRow]) else {
            activeParty = nil
            return
        }
        for row in rows {
            if let party = try? await (supabase
                .from("parties").select()
                .eq("id", value: row.partyId.uuidString)
                .eq("is_active", value: true)
                .limit(1)
                .execute()
                .value as [Party]).first {
                activeParty = party
                return
            }
        }
        activeParty = nil
    }

    @MainActor
    func toggleBACVisibility(partyId: UUID, userId: UUID) async {
        showMyBAC.toggle()
        rebuildAlcoholDisplay()
        Task {
            try? await supabase
                .from("party_members")
                .update(["show_bac": showMyBAC])
                .eq("party_id", value: partyId.uuidString)
                .eq("user_id",  value: userId.uuidString)
                .execute()
        }
    }

    @MainActor
    private func rebuildAlcoholDisplay() {
        guard let profile else { return }
        partyKings = partyKings.map { entry in
            guard entry.profile.userId == profile.userId else { return entry }
            return LeaderboardEntry(
                id: entry.id, profile: entry.profile, value: entry.value,
                displayValue: showMyBAC ? String(format: "%.3f g/L", entry.value) : "---",
                rank: entry.rank
            )
        }
    }

    private func clearEntries() {
        partyKings      = []
        kissLeaders     = []
        pukeLeaders     = []
        hydrationHeroes = []
    }

    private func ranked(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        entries.enumerated().map { index, entry in
            var e = entry; e.rank = index + 1; return e
        }
    }
}

// Legacy enum kept for compatibility
enum LeaderboardFilter: String, CaseIterable {
    case bac    = "BAC"
    case drinks = "Drinks"
}
