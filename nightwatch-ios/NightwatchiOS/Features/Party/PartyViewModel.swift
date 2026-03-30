import Foundation
import Observation
import Supabase

@Observable
class PartyViewModel {
    var profile: Profile?
    var currentParty: Party?
    var members: [PartyMemberWithProfile] = []
    var photos: [PartyPhotoWithProfile] = []
    var isLoading = false
    var errorMessage: String?
    var partyCode = ""
    var newPartyName = ""
    var showCreateParty = false
    var showJoinParty = false

    @MainActor
    func load(profile: Profile) async {
        self.profile = profile
        isLoading = true
        await loadActiveParty()
        isLoading = false
    }

    @MainActor
    func loadActiveParty() async {
        guard let profile else { return }
        do {
            // ORDER BY joined_at DESC so we always get the most recent membership first
            let memberships: [PartyMember] = try await supabase
                .from("party_members")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .order("joined_at", ascending: false)
                .execute()
                .value

            // Walk memberships from newest to oldest — use first active party found
            for membership in memberships {
                let parties: [Party] = try await supabase
                    .from("parties")
                    .select()
                    .eq("id", value: membership.partyId.uuidString)
                    .eq("is_active", value: true)
                    .limit(1)
                    .execute()
                    .value

                if let party = parties.first {
                    currentParty = party
                    await loadMembers(partyId: party.id)
                    await loadPhotos(partyId: party.id)
                    return
                }
            }
            currentParty = nil
        } catch {
            currentParty = nil
        }
    }

    @MainActor
    func loadMembers(partyId: UUID) async {
        do {
            let memberRecords: [PartyMember] = try await supabase
                .from("party_members")
                .select()
                .eq("party_id", value: partyId.uuidString)
                .execute()
                .value

            var membersWithProfiles: [PartyMemberWithProfile] = []
            for member in memberRecords {
                do {
                    let memberProfile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("user_id", value: member.userId.uuidString)
                        .single()
                        .execute()
                        .value

                    // Calculate BAC for member
                    let today = Calendar.current.startOfDay(for: Date())
                    let drinks: [Drink] = try await supabase
                        .from("drinks")
                        .select()
                        .eq("user_id", value: member.userId.uuidString)
                        .gte("created_at", value: ISO8601DateFormatter().string(from: today))
                        .execute()
                        .value

                    var bac = 0.0
                    if member.showBac {
                        bac = BACCalculator.calculateBAC(drinks: drinks, profile: memberProfile)
                    }

                    membersWithProfiles.append(PartyMemberWithProfile(
                        id: member.id,
                        member: member,
                        profile: memberProfile,
                        currentBac: bac,
                        drinkCount: drinks.filter { $0.abv > 0 }.count
                    ))
                } catch {
                    // Skip member if profile not found
                }
            }
            self.members = membersWithProfiles
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadPhotos(partyId: UUID) async {
        do {
            let photoRecords: [PartyPhoto] = try await supabase
                .from("party_photos")
                .select()
                .eq("party_id", value: partyId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            var photosWithProfiles: [PartyPhotoWithProfile] = []
            for photo in photoRecords {
                do {
                    let photoProfile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("user_id", value: photo.userId.uuidString)
                        .single()
                        .execute()
                        .value
                    photosWithProfiles.append(PartyPhotoWithProfile(photo: photo, profile: photoProfile))
                } catch {}
            }
            self.photos = photosWithProfiles
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func createParty() async {
        guard let profile else { return }
        isLoading = true
        do {
            let code = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
            let partyInsert = PartyInsert(
                name: newPartyName.isEmpty ? "\(profile.pseudo)'s Party" : newPartyName,
                code: code,
                createdBy: profile.userId
            )
            let party: Party = try await supabase
                .from("parties")
                .insert(partyInsert)
                .select()
                .single()
                .execute()
                .value

            // Join the party
            let memberInsert = PartyMemberInsert(partyId: party.id, userId: profile.userId)
            try await supabase
                .from("party_members")
                .insert(memberInsert)
                .execute()

            currentParty = party
            showCreateParty = false
            newPartyName = ""
            await loadMembers(partyId: party.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func joinParty() async {
        guard let profile else { return }
        isLoading = true
        do {
            let party: Party = try await supabase
                .from("parties")
                .select()
                .eq("code", value: partyCode.uppercased())
                .eq("is_active", value: true)
                .single()
                .execute()
                .value

            let memberInsert = PartyMemberInsert(partyId: party.id, userId: profile.userId)
            try await supabase
                .from("party_members")
                .insert(memberInsert)
                .execute()

            currentParty = party
            partyCode = ""
            showJoinParty = false
            await loadMembers(partyId: party.id)
        } catch {
            errorMessage = "Party not found or already ended"
        }
        isLoading = false
    }

    @MainActor
    func leaveParty() async {
        guard let profile, let party = currentParty else { return }
        isLoading = true
        do {
            try await supabase
                .from("party_members")
                .delete()
                .eq("party_id", value: party.id.uuidString)
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
            currentParty = nil
            members = []
            photos = []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func endParty() async {
        guard let party = currentParty else { return }
        isLoading = true
        do {
            try await supabase
                .from("parties")
                .update(["is_active": false])
                .eq("id", value: party.id.uuidString)
                .execute()
            currentParty = nil
            members = []
            photos = []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func logPukeEvent() async {
        guard let profile, let party = currentParty else { return }
        do {
            let pukeInsert = PukeEventInsert(partyId: party.id, userId: profile.userId)
            try await supabase
                .from("puke_events")
                .insert(pukeInsert)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PartyInsert: Codable {
    let name: String
    let code: String
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case name
        case code
        case createdBy = "created_by"
    }
}

private struct PartyMemberInsert: Codable {
    let partyId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case userId = "user_id"
    }
}

private struct PukeEventInsert: Codable {
    let partyId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case partyId = "party_id"
        case userId = "user_id"
    }
}
