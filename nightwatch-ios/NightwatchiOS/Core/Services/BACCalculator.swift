import Foundation

struct BACCalculator {

    /// BAC en g/L (grammes par litre de sang)
    /// Formule Widmark : BAC = Σ(alcool_g / (poids_kg × k)) − 0.15 × heures_écoulées
    /// k = 0.7 homme, 0.6 femme
    static func calculateBAC(drinks: [Drink], profile: Profile, at now: Date = Date()) -> Double {
        var bac = 0.0
        let k = profile.kFactor
        let weight = profile.weight

        for drink in drinks {
            guard let createdAt = drink.createdAt else { continue }
            let hoursSince = now.timeIntervalSince(createdAt) / 3600.0
            let contribution = (drink.alcoholGrams / (weight * k)) - (0.15 * hoursSince)
            bac += contribution
        }

        return max(0.0, bac)
    }

    /// Niveaux BAC en g/L (limite légale France = 0.5 g/L)
    static func level(for bac: Double) -> BACLevel {
        switch bac {
        case 0..<0.1:   return .sober        // sobre
        case 0.1..<0.3: return .light        // légère sensation
        case 0.3..<0.5: return .moderate     // sous la limite légale
        case 0.5..<0.8: return .significant  // au-dessus limite légale
        case 0.8..<1.5: return .heavy        // ivre
        default:         return .danger      // danger réel (1.5+ g/L)
        }
    }

    /// Temps estimé avant de retrouver 0.0 g/L (taux élimination : 0.15 g/L/h)
    static func hoursUntilSober(currentBAC: Double) -> Double {
        guard currentBAC > 0 else { return 0 }
        return currentBAC / 0.15
    }

    /// Temps estimé avant de passer sous la limite légale (0.5 g/L)
    static func hoursUntilLegal(currentBAC: Double) -> Double {
        let legalLimit = 0.5
        guard currentBAC > legalLimit else { return 0 }
        return (currentBAC - legalLimit) / 0.15
    }
}

enum BACLevel: String {
    case sober       = "Sobre"
    case light       = "Légère sensation"
    case moderate    = "Sous la limite"
    case significant = "Au-dessus limite"
    case heavy       = "Ivre"
    case danger      = "Danger"

    var colorHex: String {
        switch self {
        case .sober:       return "#10b981"
        case .light:       return "#10b981"
        case .moderate:    return "#f59e0b"
        case .significant: return "#f97316"
        case .heavy:       return "#ef4444"
        case .danger:      return "#ef4444"
        }
    }
}
