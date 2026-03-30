import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    // App design system colors
    static let appBackground = Color(hex: "#0a0a0f")
    static let appCard = Color(hex: "#13131a")
    static let appAccentPurple = Color(hex: "#7c3aed")
    static let appAccentBlue = Color(hex: "#2563eb")
    static let appSuccess = Color(hex: "#10b981")
    static let appWarning = Color(hex: "#f59e0b")
    static let appDanger = Color(hex: "#ef4444")
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(hex: "#9ca3af")
    static let appBorder = Color.white.opacity(0.1)
}
