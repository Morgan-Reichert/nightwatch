import Foundation

struct Drink: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var partyId: UUID?
    var name: String
    var volumeMl: Double
    var abv: Double
    var alcoholGrams: Double
    var imageUrl: String?
    var detectedByAi: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partyId = "party_id"
        case name
        case volumeMl = "volume_ml"
        case abv
        case alcoholGrams = "alcohol_grams"
        case imageUrl = "image_url"
        case detectedByAi = "detected_by_ai"
        case createdAt = "created_at"
    }
}

struct DrinkTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let category: DrinkCategory
    let volumeMl: Double
    let abv: Double
    let emoji: String

    var alcoholGrams: Double {
        volumeMl * abv * 0.8
    }
}

enum DrinkCategory: String, CaseIterable {
    case beer = "Beers"
    case wine = "Wines"
    case cocktail = "Cocktails"
    case spirit = "Spirits"
    case nonAlcoholic = "Non-Alcoholic"

    var emoji: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍹"
        case .spirit: return "🥃"
        case .nonAlcoholic: return "💧"
        }
    }
}

extension DrinkTemplate {
    static let allDrinks: [DrinkTemplate] = [
        // Beers
        DrinkTemplate(id: "beer_25cl", name: "Beer 25cl", category: .beer, volumeMl: 250, abv: 0.05, emoji: "🍺"),
        DrinkTemplate(id: "beer_33cl", name: "Beer 33cl", category: .beer, volumeMl: 330, abv: 0.05, emoji: "🍺"),
        DrinkTemplate(id: "beer_50cl", name: "Beer 50cl", category: .beer, volumeMl: 500, abv: 0.05, emoji: "🍺"),
        DrinkTemplate(id: "pint", name: "Pint", category: .beer, volumeMl: 568, abv: 0.05, emoji: "🍻"),
        DrinkTemplate(id: "strong_beer", name: "Strong Beer", category: .beer, volumeMl: 330, abv: 0.085, emoji: "🍺"),
        // Wines
        DrinkTemplate(id: "red_wine", name: "Red Wine", category: .wine, volumeMl: 150, abv: 0.13, emoji: "🍷"),
        DrinkTemplate(id: "white_wine", name: "White Wine", category: .wine, volumeMl: 150, abv: 0.125, emoji: "🥂"),
        DrinkTemplate(id: "rose", name: "Rosé", category: .wine, volumeMl: 150, abv: 0.12, emoji: "🍷"),
        DrinkTemplate(id: "champagne", name: "Champagne", category: .wine, volumeMl: 125, abv: 0.125, emoji: "🥂"),
        DrinkTemplate(id: "dessert_wine", name: "Dessert Wine", category: .wine, volumeMl: 75, abv: 0.18, emoji: "🍷"),
        // Cocktails
        DrinkTemplate(id: "mojito", name: "Mojito", category: .cocktail, volumeMl: 300, abv: 0.12, emoji: "🍹"),
        DrinkTemplate(id: "margarita", name: "Margarita", category: .cocktail, volumeMl: 250, abv: 0.20, emoji: "🍸"),
        DrinkTemplate(id: "gin_tonic", name: "G&T", category: .cocktail, volumeMl: 200, abv: 0.10, emoji: "🥃"),
        DrinkTemplate(id: "sex_on_beach", name: "Sex on the Beach", category: .cocktail, volumeMl: 250, abv: 0.15, emoji: "🍹"),
        DrinkTemplate(id: "long_island", name: "Long Island", category: .cocktail, volumeMl: 300, abv: 0.20, emoji: "🍹"),
        DrinkTemplate(id: "spritz", name: "Spritz", category: .cocktail, volumeMl: 200, abv: 0.08, emoji: "🥂"),
        DrinkTemplate(id: "cosmopolitan", name: "Cosmopolitan", category: .cocktail, volumeMl: 200, abv: 0.18, emoji: "🍸"),
        // Spirits
        DrinkTemplate(id: "shot", name: "Shot", category: .spirit, volumeMl: 40, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "double_shot", name: "Double Shot", category: .spirit, volumeMl: 80, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "whisky", name: "Whisky", category: .spirit, volumeMl: 50, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "vodka", name: "Vodka", category: .spirit, volumeMl: 50, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "rum", name: "Rum", category: .spirit, volumeMl: 50, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "tequila", name: "Tequila", category: .spirit, volumeMl: 40, abv: 0.40, emoji: "🥃"),
        DrinkTemplate(id: "gin", name: "Gin", category: .spirit, volumeMl: 50, abv: 0.43, emoji: "🥃"),
        // Non-Alcoholic
        DrinkTemplate(id: "water", name: "Water", category: .nonAlcoholic, volumeMl: 250, abv: 0.0, emoji: "💧"),
        DrinkTemplate(id: "juice", name: "Juice", category: .nonAlcoholic, volumeMl: 200, abv: 0.0, emoji: "🧃"),
        DrinkTemplate(id: "soda", name: "Soda", category: .nonAlcoholic, volumeMl: 330, abv: 0.0, emoji: "🥤"),
        DrinkTemplate(id: "energy_drink", name: "Energy Drink", category: .nonAlcoholic, volumeMl: 250, abv: 0.0, emoji: "⚡")
    ]

    static func byCategory(_ category: DrinkCategory) -> [DrinkTemplate] {
        allDrinks.filter { $0.category == category }
    }
}
