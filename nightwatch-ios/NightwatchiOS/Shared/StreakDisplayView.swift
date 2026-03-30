import SwiftUI

struct StreakDisplayView: View {
    let streakInfo: StreakInfo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(streakInfo.color.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(streakInfo.color.opacity(0.3), lineWidth: 1.5))

                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: streakInfo.weeks > 0
                                ? [streakInfo.color, streakInfo.color.opacity(0.7)]
                                : [Color.appTextSecondary, Color.appTextSecondary.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(streakInfo.label)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(streakInfo.weeks > 0 ? streakInfo.color : Color.appTextSecondary)

                Text("Streak hebdomadaire")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            if streakInfo.weeks > 0 {
                VStack(spacing: 2) {
                    Text("\(streakInfo.weeks)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(streakInfo.color)
                    Text("sem.")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(streakInfo.color.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(streakInfo.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(streakInfo.color.opacity(0.25), lineWidth: 1))
            } else {
                Text("Aucun")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appCard.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            streakInfo.weeks > 0
                                ? streakInfo.color.opacity(0.2)
                                : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
        )
    }
}
