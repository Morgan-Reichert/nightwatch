import Foundation

struct Party: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let code: String
    let createdBy: UUID
    var isActive: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case createdBy = "created_by"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct PartyMember: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let joinedAt: Date?
    var showBac: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case showBac = "show_bac"
    }
}

struct PartyMemberWithProfile: Identifiable, Equatable {
    let id: UUID
    let member: PartyMember
    let profile: Profile
    var currentBac: Double = 0.0
    var drinkCount: Int = 0
}

struct PartyRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    var status: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case status
        case createdAt = "created_at"
    }
}
