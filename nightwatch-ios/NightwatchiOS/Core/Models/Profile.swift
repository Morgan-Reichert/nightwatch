import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var pseudo: String
    var gender: String
    var weight: Double
    var height: Double
    var age: Int
    var avatarUrl: String?
    var emergencyContact: String?
    var phone: String?
    var bio: String?
    var customCards: [CustomCard]?
    var snapchat: String?
    var instagram: String?
    var tiktok: String?
    var city: String?
    var school: String?
    var job: String?
    var zodiac: String?
    var musicTaste: String?
    var partyStyle: String?
    var avatarFrame: String?
    var bannerGradient: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pseudo
        case gender
        case weight
        case height
        case age
        case avatarUrl = "avatar_url"
        case emergencyContact = "emergency_contact"
        case phone
        case bio
        case customCards = "custom_cards"
        case snapchat
        case instagram
        case tiktok
        case city
        case school
        case job
        case zodiac
        case musicTaste = "music_taste"
        case partyStyle = "party_style"
        case avatarFrame = "avatar_frame"
        case bannerGradient = "banner_gradient"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var kFactor: Double {
        gender == "female" ? 0.6 : 0.7
    }
}

struct CustomCard: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var value: String
    var icon: String?
}

extension Profile {
    static var placeholder: Profile {
        Profile(
            id: UUID(),
            userId: UUID(),
            pseudo: "nightwatcher",
            gender: "male",
            weight: 75,
            height: 178,
            age: 25,
            avatarUrl: nil,
            emergencyContact: nil,
            phone: nil,
            bio: nil,
            customCards: nil,
            snapchat: nil,
            instagram: nil,
            tiktok: nil,
            city: nil,
            school: nil,
            job: nil,
            zodiac: nil,
            musicTaste: nil,
            partyStyle: nil,
            avatarFrame: nil,
            bannerGradient: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
