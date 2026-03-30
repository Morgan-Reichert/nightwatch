import SwiftUI

struct BACGaugeView: View {
    let bac: Double
    let level: BACLevel
    let hoursUntilSober: Double
    let drinkCount: Int

    private let maxBAC: Double = 2.0       // g/L : danger réel à 2.0 g/L
    private let legalLimit: Double = 0.5   // g/L : limite légale France
    private let gaugeSize: CGFloat = 260

    private var progress: Double {
        min(bac / maxBAC, 1.0)
    }

    private var gaugeColor: Color {
        Color(hex: level.colorHex)
    }

    private var hoursUntilLegal: Double {
        guard bac > legalLimit else { return 0 }
        return (bac - legalLimit) / 0.15   // 0.15 g/L/h = taux d'élimination moyen
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background arc track
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 22, lineCap: .round))
                    .frame(width: gaugeSize, height: gaugeSize)
                    .rotationEffect(.degrees(135))

                // Gradient background track (faint)
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.appSuccess.opacity(0.25),
                                Color.appWarning.opacity(0.25),
                                Color.appDanger.opacity(0.25)
                            ],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(405)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: gaugeSize, height: gaugeSize)
                    .rotationEffect(.degrees(135))

                // Active filled arc
                Circle()
                    .trim(from: 0, to: 0.75 * progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.appSuccess,
                                Color(hex: "#84cc16"),
                                Color.appWarning,
                                Color(hex: "#f97316"),
                                Color.appDanger
                            ],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(405)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: gaugeSize, height: gaugeSize)
                    .rotationEffect(.degrees(135))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                // Glow indicator dot
                if bac > 0.001 {
                    GaugeDot(
                        progress: progress,
                        radius: gaugeSize / 2,
                        color: gaugeColor
                    )
                }

                // Center content
                VStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(gaugeColor)

                    Text(String(format: "%.3f", bac))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: bac)

                    Text("g/L")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)

                    Text(levelLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(gaugeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(gaugeColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(width: gaugeSize, height: gaugeSize)
            .padding(.top, 20)
            .padding(.horizontal, 16)

            // Stats row
            HStack(spacing: 0) {
                BACStatCell(
                    icon: "bed.double.fill",
                    value: hoursUntilSober > 0 ? formatHours(hoursUntilSober) : "Sobre",
                    label: "Sobre dans",
                    color: Color.appSuccess
                )

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 44)

                BACStatCell(
                    icon: "car.fill",
                    value: hoursUntilLegal > 0 ? formatHours(hoursUntilLegal) : "Légal",
                    label: "Légal dans",
                    color: Color.appWarning
                )

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 44)

                BACStatCell(
                    icon: "drop.fill",
                    value: "\(drinkCount)",
                    label: "Boissons",
                    color: Color.appAccentPurple
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appCard.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: gaugeColor.opacity(0.1), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 16)
    }

    private var statusIcon: String {
        switch level {
        case .sober, .light: return "checkmark.circle.fill"
        case .moderate, .significant: return "exclamationmark.triangle.fill"
        case .heavy, .danger: return "xmark.octagon.fill"
        }
    }

    private var levelLabel: String {
        switch level {
        case .sober: return "Sobre"
        case .light: return "Léger"
        case .moderate: return "Bien"
        case .significant: return "Éméché"
        case .heavy: return "Ivre"
        case .danger: return "Danger"
        }
    }

    private func formatHours(_ h: Double) -> String {
        if h < 1 {
            return "\(max(1, Int(h * 60)))min"
        }
        let hrs = Int(h)
        let mins = Int((h - Double(hrs)) * 60)
        if mins == 0 { return "\(hrs)h" }
        return "\(hrs)h\(mins)m"
    }
}

struct GaugeDot: View {
    let progress: Double
    let radius: CGFloat
    let color: Color

    @State private var pulsing = false

    private var angle: Double {
        let sweep = 270.0
        return (135 + sweep * progress) * .pi / 180
    }

    private var dotX: CGFloat {
        CGFloat(cos(angle)) * (radius - 11)
    }

    private var dotY: CGFloat {
        CGFloat(sin(angle)) * (radius - 11)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 28, height: 28)
                .scaleEffect(pulsing ? 1.7 : 1.0)
                .opacity(pulsing ? 0 : 0.8)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulsing)

            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .shadow(color: color.opacity(0.9), radius: 8, x: 0, y: 0)
        }
        .offset(x: dotX, y: dotY)
        .onAppear { pulsing = true }
    }
}

struct BACStatCell: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
