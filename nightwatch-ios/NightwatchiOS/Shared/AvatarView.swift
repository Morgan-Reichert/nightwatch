import SwiftUI

struct AvatarView: View {
    let avatarUrl: String?
    let pseudo: String
    let size: CGFloat
    var frameId: String? = nil

    private var initials: String {
        let letters = pseudo.prefix(2).uppercased()
        return String(letters)
    }

    private var avatarColor: Color {
        let colors: [Color] = [
            Color.appAccentPurple,
            Color.appAccentBlue,
            Color(hex: "#EC4899"),
            Color(hex: "#F59E0B"),
            Color(hex: "#10B981")
        ]
        let index = abs(pseudo.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        ZStack {
            if let url = avatarUrl, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        PlaceholderAvatar(initials: initials, color: avatarColor, size: size)
                    @unknown default:
                        PlaceholderAvatar(initials: initials, color: avatarColor, size: size)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                PlaceholderAvatar(initials: initials, color: avatarColor, size: size)
            }

            // Avatar frame overlay
            if let frameId {
                AvatarFrameOverlay(frameId: frameId, size: size)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PlaceholderAvatar: View {
    let initials: String
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}

struct AvatarFrameOverlay: View {
    let frameId: String
    let size: CGFloat

    private var frameColors: [Color] {
        switch frameId {
        case "gold_aura":
            return [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        case "neon_arc":
            return [Color(hex: "#00FF88"), Color(hex: "#00BFFF")]
        case "eternal_flame":
            return [Color(hex: "#FF4500"), Color(hex: "#FF8C00")]
        case "royal_ice":
            return [Color(hex: "#87CEEB"), Color(hex: "#4682B4")]
        case "vip_crown":
            return [Color(hex: "#9B59B6"), Color(hex: "#FFD700")]
        case "galaxy":
            return [Color(hex: "#7C3AED"), Color(hex: "#2563EB")]
        default:
            return [Color.appAccentPurple, Color.appAccentBlue]
        }
    }

    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: frameColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: size * 0.06
            )
            .frame(width: size, height: size)
    }
}
