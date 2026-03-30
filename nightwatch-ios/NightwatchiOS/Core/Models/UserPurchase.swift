import Foundation

struct UserPurchase: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let itemId: String
    var stripeSessionId: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case stripeSessionId = "stripe_session_id"
        case createdAt = "created_at"
    }
}
