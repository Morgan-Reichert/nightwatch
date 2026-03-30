import Foundation

struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    var status: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
    }
}

struct FriendWithProfile: Identifiable, Equatable {
    var id: UUID { friendship.id }
    let friendship: Friendship
    let profile: Profile
    var currentBac: Double = 0.0
    var drinkCount: Int = 0
}
