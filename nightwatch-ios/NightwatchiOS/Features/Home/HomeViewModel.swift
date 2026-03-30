import Foundation
import Observation
import Supabase

@Observable
class HomeViewModel {
    var profile: Profile?
    var drinks: [Drink] = []
    var currentBAC: Double = 0.0
    var isLoading = false
    var errorMessage: String?
    var activePartyId: UUID?
    var streakInfo: StreakInfo = StreakInfo(weeks: 0, color: .gray, label: "Aucun streak")
    var friendStories: [StoryWithProfile] = []
    var kissCount: Int = 0
    var pukeCount: Int = 0

    private var bacUpdateTimer: Timer?
    private var refreshTimer: Timer?

    init() {}

    @MainActor
    func load(profile: Profile) async {
        self.profile = profile
        isLoading = true
        await loadActiveParty()          // ← must run first so Kiss/Quiche know party state
        await loadDrinks()
        await loadAllDrinksForStreak()
        await loadFriendStories()
        await loadEventCounts()
        updateBAC()
        startBACTimer()
        subscribeToRealtimeDrinks()
        isLoading = false
    }

    // MARK: - Active Party

    @MainActor
    func loadActiveParty() async {
        guard let profile else { return }
        do {
            // Use ordering so we always pick the most recent membership
            struct MemberRow: Decodable {
                let partyId: UUID
                enum CodingKeys: String, CodingKey { case partyId = "party_id" }
            }
            let rows: [MemberRow] = try await supabase
                .from("party_members")
                .select("party_id")
                .eq("user_id", value: profile.userId.uuidString)
                .order("joined_at", ascending: false)
                .limit(5)          // grab a few in case some are inactive
                .execute()
                .value

            // Find the first one that belongs to an active party
            for row in rows {
                let parties: [Party] = try await supabase
                    .from("parties")
                    .select()
                    .eq("id", value: row.partyId.uuidString)
                    .eq("is_active", value: true)
                    .limit(1)
                    .execute()
                    .value
                if let active = parties.first {
                    activePartyId = active.id
                    return
                }
            }
            activePartyId = nil
        } catch {
            activePartyId = nil
        }
    }

    // MARK: - Drinks

    @MainActor
    func loadDrinks() async {
        guard let profile else { return }
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let drinks: [Drink] = try await supabase
                .from("drinks")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .gte("created_at", value: ISO8601DateFormatter().string(from: today))
                .order("created_at", ascending: false)
                .execute()
                .value
            self.drinks = drinks
            updateBAC()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadAllDrinksForStreak() async {
        guard let profile else { return }
        do {
            let allDrinks: [Drink] = try await supabase
                .from("drinks")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value
            streakInfo = StreakService.calculateStreak(drinks: allDrinks)
        } catch {}
    }

    @MainActor
    func loadFriendStories() async {
        guard let profile else { return }
        do {
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(profile.userId.uuidString)")
                .eq("status", value: "accepted")
                .execute()
                .value

            let friendIds = friendships.map { friendship -> UUID in
                friendship.requesterId == profile.userId ? friendship.addresseeId : friendship.requesterId
            }

            guard !friendIds.isEmpty else { return }

            let nowStr = ISO8601DateFormatter().string(from: Date())
            var storiesWithProfiles: [StoryWithProfile] = []

            for friendId in friendIds {
                do {
                    let stories: [Story] = try await supabase
                        .from("stories")
                        .select()
                        .eq("user_id", value: friendId.uuidString)
                        .gte("expires_at", value: nowStr)
                        .execute()
                        .value

                    if !stories.isEmpty {
                        let friendProfile: Profile = try await supabase
                            .from("profiles")
                            .select()
                            .eq("user_id", value: friendId.uuidString)
                            .single()
                            .execute()
                            .value
                        for story in stories {
                            storiesWithProfiles.append(StoryWithProfile(story: story, profile: friendProfile))
                        }
                    }
                } catch {}
            }

            self.friendStories = storiesWithProfiles
        } catch {}
    }

    // MARK: - Kiss / Puke Counts
    // Scoped to active party when in one, otherwise show today's total

    @MainActor
    func loadEventCounts() async {
        guard let profile else { return }

        if let partyId = activePartyId {
            // Party mode: count only events for this party → resets on new party
            do {
                let pukes: [PukeEvent] = try await supabase
                    .from("puke_events")
                    .select()
                    .eq("user_id",  value: profile.userId.uuidString)
                    .eq("party_id", value: partyId.uuidString)
                    .execute()
                    .value
                self.pukeCount = pukes.count
            } catch {}

            do {
                let kisses: [ShopEvent] = try await supabase
                    .from("shop_events")
                    .select()
                    .eq("user_id",  value: profile.userId.uuidString)
                    .eq("party_id", value: partyId.uuidString)
                    .execute()
                    .value
                self.kissCount = kisses.count
            } catch {}
        } else {
            // No party: counts are 0 (Kiss/Quiche buttons are disabled anyway)
            pukeCount = 0
            kissCount = 0
        }
    }

    @MainActor
    func logKiss() async {
        guard let profile else { return }
        do {
            let insert = KissInsert(
                userId: profile.userId,
                partyId: activePartyId
            )
            try await supabase
                .from("shop_events")
                .insert(insert)
                .execute()
            kissCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func logPuke() async {
        guard let profile else { return }
        do {
            let insert = PukeInsert(
                userId: profile.userId,
                partyId: activePartyId
            )
            try await supabase
                .from("puke_events")
                .insert(insert)
                .execute()
            pukeCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - BAC

    func updateBAC() {
        guard let profile else { return }
        currentBAC = BACCalculator.calculateBAC(drinks: drinks, profile: profile)
    }

    private func startBACTimer() {
        bacUpdateTimer?.invalidate()
        bacUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBAC()
        }
    }

    // MARK: - Refresh Timer (live updates toutes les 30s)

    private func subscribeToRealtimeDrinks() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.loadActiveParty()   // keep party state current across tabs
                await self?.loadDrinks()
                await self?.loadEventCounts()   // reload kiss/quiche counts scoped to party
            }
        }
    }

    // MARK: - Drink Logging

    @MainActor
    func logDrink(template: DrinkTemplate) async {
        guard let profile else { return }
        isLoading = true
        do {
            let drinkInsert = DrinkInsert(
                userId: profile.userId,
                partyId: activePartyId,
                name: template.name,
                volumeMl: template.volumeMl,
                abv: template.abv,
                alcoholGrams: template.alcoholGrams,
                detectedByAi: false
            )
            try await supabase
                .from("drinks")
                .insert(drinkInsert)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        // Always reload even if insert fails — keeps UI in sync with DB
        await loadDrinks()
        isLoading = false
    }

    @MainActor
    func logDrinkFromAI(name: String, volumeMl: Double, abv: Double) async {
        guard let profile else { return }
        isLoading = true
        do {
            let alcoholGrams = volumeMl * abv * 0.8
            let drinkInsert = DrinkInsert(
                userId: profile.userId,
                partyId: activePartyId,
                name: name,
                volumeMl: volumeMl,
                abv: abv,
                alcoholGrams: alcoholGrams,
                detectedByAi: true
            )
            try await supabase
                .from("drinks")
                .insert(drinkInsert)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        await loadDrinks()
        isLoading = false
    }

    @MainActor
    func deleteDrink(_ drink: Drink) async {
        do {
            try await supabase
                .from("drinks")
                .delete()
                .eq("id", value: drink.id.uuidString)
                .execute()
            drinks.removeAll { $0.id == drink.id }
            updateBAC()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Computed

    var bacLevel: BACLevel {
        BACCalculator.level(for: currentBAC)
    }

    var hoursUntilSober: Double {
        BACCalculator.hoursUntilSober(currentBAC: currentBAC)
    }

    var drinkCount: Int {
        drinks.filter { $0.abv > 0 }.count
    }

    deinit {
        bacUpdateTimer?.invalidate()
        refreshTimer?.invalidate()
    }
}

// MARK: - Private Insert Types

private struct DrinkInsert: Codable {
    let userId: UUID
    let partyId: UUID?
    let name: String
    let volumeMl: Double
    let abv: Double
    let alcoholGrams: Double
    let detectedByAi: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case partyId = "party_id"
        case name
        case volumeMl = "volume_ml"
        case abv
        case alcoholGrams = "alcohol_grams"
        case detectedByAi = "detected_by_ai"
    }
}

private struct KissInsert: Encodable {
    let userId: UUID
    let partyId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case partyId = "party_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(partyId, forKey: .partyId)
        // partyId omitted entirely (not null) when nil → avoids NOT NULL constraint
    }
}

private struct PukeInsert: Encodable {
    let userId: UUID
    let partyId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case partyId = "party_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(partyId, forKey: .partyId)
    }
}
