import SwiftUI

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.appCard.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }

    func appBackground() -> some View {
        self.background(Color.appBackground.ignoresSafeArea())
    }

    func primaryButton() -> some View {
        self
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [Color.appAccentPurple, Color.appAccentBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func secondaryButton() -> some View {
        self
            .foregroundStyle(Color.appTextPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

struct GlassmorphismBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            RadialGradient(
                colors: [Color.appAccentPurple.opacity(0.15), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            RadialGradient(
                colors: [Color.appAccentBlue.opacity(0.10), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 350
            )
        }
        .ignoresSafeArea()
    }
}
