import Foundation

struct PartyPhoto: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var imageUrl: String?
    var caption: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case imageUrl = "image_url"
        case caption
        case createdAt = "created_at"
    }
}

struct PartyPhotoWithProfile: Identifiable, Equatable {
    var id: UUID { photo.id }
    let photo: PartyPhoto
    let profile: Profile
}
