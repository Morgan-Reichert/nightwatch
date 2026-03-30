import Foundation

struct Story: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var partyId: UUID?
    var imageUrl: String?
    var caption: String?
    var bacAtPost: Double?
    let expiresAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partyId = "party_id"
        case imageUrl = "image_url"
        case caption
        case bacAtPost = "bac_at_post"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }
}

struct StoryWithProfile: Identifiable, Equatable {
    var id: UUID { story.id }
    let story: Story
    let profile: Profile
}
