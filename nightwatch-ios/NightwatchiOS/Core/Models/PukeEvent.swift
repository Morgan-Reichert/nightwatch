import Foundation

struct PukeEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
