import Foundation

/// Configuration centrale de l'app
/// ⚠️ Remplace MISTRAL_API_KEY par ta vraie clé sur mistral.ai
enum AppConfig {
    static let supabaseURL = "https://vqkiypjxeazydizqhgar.supabase.co"
    static let supabaseAnonKey = "sb_publishable_O6Hm_lrqn00XjrounXi7Og_O64VoV1u"

    /// Clé API Mistral pour le scan de boissons par IA
    /// Obtenir une clé sur : https://console.mistral.ai/api-keys
    static let mistralApiKey = "HsUCCD0905Fr1WHyGBXxhIBQQ5LXhbCJ"
}
