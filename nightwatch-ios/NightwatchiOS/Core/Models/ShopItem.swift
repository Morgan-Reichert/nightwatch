import Foundation
import SwiftUI

enum ShopItemType: String, CaseIterable {
    case avatarFrame = "avatar_frame"
    case bannerGradient = "banner_gradient"
    case streakRestore = "streak_restore"

    var displayName: String {
        switch self {
        case .avatarFrame: return "Avatar Frames"
        case .bannerGradient: return "Banner Gradients"
        case .streakRestore: return "Streak Restore"
        }
    }
}

struct ShopItem: Identifiable, Equatable {
    let id: String
    let name: String
    let type: ShopItemType
    let price: Double
    let description: String?
    let previewColors: [Color]

    var formattedPrice: String {
        String(format: "€%.2f", price)
    }
}

extension ShopItem {
    static let allItems: [ShopItem] = [
        // Avatar Frames
        ShopItem(
            id: "gold_aura",
            name: "Gold Aura",
            type: .avatarFrame,
            price: 2.99,
            description: "A shimmering golden glow",
            previewColors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        ),
        ShopItem(
            id: "neon_arc",
            name: "Neon Arc",
            type: .avatarFrame,
            price: 1.99,
            description: "Electric neon outline",
            previewColors: [Color(hex: "#00FF88"), Color(hex: "#00BFFF")]
        ),
        ShopItem(
            id: "eternal_flame",
            name: "Eternal Flame",
            type: .avatarFrame,
            price: 3.99,
            description: "Blazing fire border",
            previewColors: [Color(hex: "#FF4500"), Color(hex: "#FF8C00")]
        ),
        ShopItem(
            id: "royal_ice",
            name: "Royal Ice",
            type: .avatarFrame,
            price: 2.99,
            description: "Crystal ice crown",
            previewColors: [Color(hex: "#87CEEB"), Color(hex: "#4682B4")]
        ),
        ShopItem(
            id: "vip_crown",
            name: "VIP Crown",
            type: .avatarFrame,
            price: 4.99,
            description: "Exclusive VIP status",
            previewColors: [Color(hex: "#9B59B6"), Color(hex: "#FFD700")]
        ),
        ShopItem(
            id: "galaxy",
            name: "Galaxy",
            type: .avatarFrame,
            price: 3.99,
            description: "Deep space aura",
            previewColors: [Color(hex: "#7C3AED"), Color(hex: "#2563EB")]
        ),
        // Banner Gradients
        ShopItem(
            id: "sunset",
            name: "Sunset",
            type: .bannerGradient,
            price: 1.99,
            description: "Warm sunset tones",
            previewColors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA07A"), Color(hex: "#FFD700")]
        ),
        ShopItem(
            id: "ocean_deep",
            name: "Ocean Deep",
            type: .bannerGradient,
            price: 1.99,
            description: "Deep ocean blues",
            previewColors: [Color(hex: "#0077B6"), Color(hex: "#00B4D8"), Color(hex: "#90E0EF")]
        ),
        ShopItem(
            id: "purple_haze",
            name: "Purple Haze",
            type: .bannerGradient,
            price: 1.99,
            description: "Mystic purple mist",
            previewColors: [Color(hex: "#7C3AED"), Color(hex: "#A855F7"), Color(hex: "#C084FC")]
        ),
        ShopItem(
            id: "forest_night",
            name: "Forest Night",
            type: .bannerGradient,
            price: 1.99,
            description: "Dark forest depths",
            previewColors: [Color(hex: "#134E4A"), Color(hex: "#047857"), Color(hex: "#10B981")]
        ),
        ShopItem(
            id: "cosmic",
            name: "Cosmic",
            type: .bannerGradient,
            price: 2.99,
            description: "Stars and nebulae",
            previewColors: [Color(hex: "#0A0A0F"), Color(hex: "#7C3AED"), Color(hex: "#2563EB")]
        ),
        ShopItem(
            id: "cherry_blossom",
            name: "Cherry Blossom",
            type: .bannerGradient,
            price: 1.99,
            description: "Soft sakura petals",
            previewColors: [Color(hex: "#FFB7C5"), Color(hex: "#FF85A1"), Color(hex: "#FF6B9D")]
        ),
        // Streak Restore
        ShopItem(
            id: "flame_restore",
            name: "Flame Restoration",
            type: .streakRestore,
            price: 0.99,
            description: "Restore your broken streak",
            previewColors: [Color(hex: "#FF4500"), Color(hex: "#FF8C00")]
        )
    ]

    static func items(ofType type: ShopItemType) -> [ShopItem] {
        allItems.filter { $0.type == type }
    }
}
