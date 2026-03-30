import Foundation
import Observation
import Contacts

@Observable
class FriendsViewModel {
    var profile: Profile?
    var friends: [FriendWithProfile] = []
    var pendingReceived: [FriendWithProfile] = []
    var pendingSent: [FriendWithProfile] = []
    var searchResults: [Profile] = []
    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?
    var isSearching = false
    var contactSuggestions: [Profile] = []
    var isLoadingContacts = false

    @MainActor
    func load(profile: Profile) async {
        self.profile = profile
        await loadFriends()
    }

    @MainActor
    func loadFriends() async {
        guard let profile else { return }
        isLoading = true
        do {
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(profile.userId.uuidString)")
                .execute()
                .value

            var friendsTemp: [FriendWithProfile] = []
            var receivedTemp: [FriendWithProfile] = []
            var sentTemp: [FriendWithProfile] = []

            for friendship in friendships {
                let otherUserId = friendship.requesterId == profile.userId
                    ? friendship.addresseeId
                    : friendship.requesterId

                do {
                    let otherProfile: Profile = try await supabase
                        .from("profiles")
                        .select()
                        .eq("user_id", value: otherUserId.uuidString)
                        .single()
                        .execute()
                        .value

                    let entry = FriendWithProfile(friendship: friendship, profile: otherProfile)

                    switch friendship.status {
                    case "accepted":
                        friendsTemp.append(entry)
                    case "pending":
                        if friendship.addresseeId == profile.userId {
                            receivedTemp.append(entry)
                        } else {
                            sentTemp.append(entry)
                        }
                    default:
                        break
                    }
                } catch {}
            }

            friends = friendsTemp
            pendingReceived = receivedTemp
            pendingSent = sentTemp
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func searchUsers() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            let results: [Profile] = try await supabase
                .from("profiles")
                .select()
                .ilike("pseudo", pattern: "%\(searchQuery)%")
                .limit(20)
                .execute()
                .value
            searchResults = results.filter { $0.userId != profile?.userId }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSearching = false
    }

    @MainActor
    func sendRequest(to targetProfile: Profile) async {
        guard let profile else { return }
        do {
            let insert = FriendshipInsert(
                requesterId: profile.userId,
                addresseeId: targetProfile.userId
            )
            try await supabase
                .from("friendships")
                .insert(insert)
                .execute()
            searchResults.removeAll { $0.id == targetProfile.id }
            contactSuggestions.removeAll { $0.id == targetProfile.id }
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func acceptRequest(_ friendship: Friendship) async {
        do {
            try await supabase
                .from("friendships")
                .update(["status": "accepted"])
                .eq("id", value: friendship.id.uuidString)
                .execute()
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func rejectRequest(_ friendship: Friendship) async {
        do {
            try await supabase
                .from("friendships")
                .update(["status": "rejected"])
                .eq("id", value: friendship.id.uuidString)
                .execute()
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func removeFriend(_ friendship: Friendship) async {
        do {
            try await supabase
                .from("friendships")
                .delete()
                .eq("id", value: friendship.id.uuidString)
                .execute()
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isAlreadyFriend(_ targetProfile: Profile) -> Bool {
        friends.contains { $0.profile.userId == targetProfile.userId } ||
        pendingSent.contains { $0.profile.userId == targetProfile.userId } ||
        pendingReceived.contains { $0.profile.userId == targetProfile.userId }
    }

    // MARK: - Contacts Search

    @MainActor
    func searchContacts() async {
        guard let profile else { return }
        isLoadingContacts = true
        contactSuggestions = []

        let store = CNContactStore()
        let granted: Bool
        do {
            granted = try await store.requestAccess(for: .contacts)
        } catch {
            isLoadingContacts = false
            return
        }

        guard granted else {
            isLoadingContacts = false
            return
        }

        // Fetch contacts with phone numbers
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        var phoneNumbers: [String] = []
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)

        do {
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                for phone in contact.phoneNumbers {
                    let normalized = Self.normalizePhone(phone.value.stringValue)
                    if !normalized.isEmpty {
                        phoneNumbers.append(normalized)
                    }
                }
            }
        } catch {
            isLoadingContacts = false
            return
        }

        guard !phoneNumbers.isEmpty else {
            isLoadingContacts = false
            return
        }

        // Query Supabase for profiles matching these phone numbers
        do {
            // Query in batches of 50 to avoid URL length issues
            var foundProfiles: [Profile] = []
            let chunks = stride(from: 0, to: phoneNumbers.count, by: 50).map {
                Array(phoneNumbers[$0..<min($0 + 50, phoneNumbers.count)])
            }
            for chunk in chunks {
                let inFilter = chunk.map { "\"\($0)\"" }.joined(separator: ",")
                let results: [Profile] = (try? await supabase
                    .from("profiles")
                    .select()
                    .filter("phone", operator: "in", value: "(\(inFilter))")
                    .execute()
                    .value) ?? []
                foundProfiles.append(contentsOf: results)
            }

            // Filter out self and existing friends
            let existingIds = Set(
                friends.map { $0.profile.userId } +
                pendingSent.map { $0.profile.userId } +
                pendingReceived.map { $0.profile.userId }
            )
            contactSuggestions = foundProfiles.filter {
                $0.userId != profile.userId && !existingIds.contains($0.userId)
            }
        } catch {
            // Silently fail contact query
        }

        isLoadingContacts = false
    }

    private static func normalizePhone(_ phone: String) -> String {
        var digits = phone.filter { $0.isNumber || $0 == "+" }
        // Strip leading country code for FR (+33 -> 0)
        if digits.hasPrefix("+33") {
            digits = "0" + digits.dropFirst(3)
        }
        // Remove spaces and dashes already filtered above
        return digits
    }
}

private struct FriendshipInsert: Codable {
    let requesterId: UUID
    let addresseeId: UUID

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
    }
}
