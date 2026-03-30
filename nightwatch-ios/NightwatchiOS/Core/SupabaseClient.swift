import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://vqkiypjxeazydizqhgar.supabase.co")!,
    supabaseKey: "sb_publishable_O6Hm_lrqn00XjrounXi7Og_O64VoV1u"
)

// MARK: - Shared date decoder
extension JSONDecoder {
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatter.date(from: string) {
                return date
            }
            if let date = fallbackFormatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return decoder
    }
}
