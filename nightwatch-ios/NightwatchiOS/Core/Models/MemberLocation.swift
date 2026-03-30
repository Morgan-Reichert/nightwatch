import Foundation

struct MemberLocation: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let partyId: UUID
    var latitude: Double
    var longitude: Double
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partyId = "party_id"
        case latitude
        case longitude
        case updatedAt = "updated_at"
    }
}
