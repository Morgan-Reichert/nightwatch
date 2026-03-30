import SwiftUI

// MARK: - Story Circles Row (used in HomeView)

struct StoryCirclesRow: View {
    let stories: [StoryWithProfile]
    let currentProfile: Profile
    let onAddStory: () -> Void
    let onSelectStory: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // "Ma story" bubble
                Button(action: onAddStory) {
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.appAccentPurple, Color.appAccentBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.5
                                )
                                .frame(width: 62, height: 62)

                            AvatarView(
                                avatarUrl: currentProfile.avatarUrl,
                                pseudo: currentProfile.pseudo,
                                size: 56
                            )

                            // Plus indicator
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.appAccentPurple)
                                .background(Circle().fill(Color.appBackground).frame(width: 16, height: 16))
                                .offset(x: 2, y: 2)
                        }

                        Text("Ma story")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .frame(width: 62)
                    }
                }
                .buttonStyle(.plain)

                // Friend stories
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, storyWithProfile in
                    Button {
                        onSelectStory(index)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                // Gradient ring (unseen = purple/blue, could track seen state)
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.appAccentPurple, Color.appAccentBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                                    .frame(width: 62, height: 62)

                                AvatarView(
                                    avatarUrl: storyWithProfile.profile.avatarUrl,
                                    pseudo: storyWithProfile.profile.pseudo,
                                    size: 56
                                )
                            }

                            Text(storyWithProfile.profile.pseudo)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(1)
                                .frame(width: 62)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Story Fullscreen Viewer

struct StoryFullscreenView: View {
    let stories: [StoryWithProfile]
    @State var currentIndex: Int
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    private let storyDuration: Double = 5.0

    var currentStory: StoryWithProfile? {
        guard currentIndex >= 0 && currentIndex < stories.count else { return nil }
        return stories[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let story = currentStory {
                // Story image
                if let imageUrl = story.story.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .ignoresSafeArea()
                        case .failure:
                            storyPlaceholder
                        case .empty:
                            storyPlaceholder
                                .overlay(ProgressView().tint(.white))
                        @unknown default:
                            storyPlaceholder
                        }
                    }
                } else {
                    storyPlaceholder
                }

                // Dark gradient overlay at top and bottom
                VStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)

                    Spacer()

                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }
                .ignoresSafeArea()

                // Content overlay
                VStack(spacing: 0) {
                    // Progress bars
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { i in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .clipShape(Capsule())

                                    Rectangle()
                                        .fill(Color.white)
                                        .clipShape(Capsule())
                                        .frame(width: progressWidth(for: i, totalWidth: geo.size.width))
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 56)

                    // Header: avatar + pseudo + time
                    HStack(spacing: 10) {
                        AvatarView(
                            avatarUrl: story.profile.avatarUrl,
                            pseudo: story.profile.pseudo,
                            size: 40
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(story.profile.pseudo)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            if let date = story.story.createdAt {
                                Text(date, style: .relative)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }

                        Spacer()

                        // BAC badge
                        if let bac = story.story.bacAtPost, bac > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(String(format: "%.2f", bac))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(hex: BACCalculator.level(for: bac).colorHex).opacity(0.8))
                            .clipShape(Capsule())
                        }

                        // Dismiss
                        Button {
                            stopTimer()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    Spacer()

                    // Caption
                    if let caption = story.story.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 48)
                    }
                }

                // Tap zones
                HStack(spacing: 0) {
                    // Left tap: previous
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            goToPrevious()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Right tap: next
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            goToNext()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()
            } else {
                // No story
                VStack(spacing: 16) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Aucune story disponible")
                        .foregroundStyle(Color.appTextSecondary)
                }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .padding(.top, 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Helpers

    private var storyPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appCard, Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "photo.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.appTextSecondary.opacity(0.3))
        }
        .ignoresSafeArea()
    }

    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentIndex {
            return totalWidth
        } else if index == currentIndex {
            return totalWidth * CGFloat(progress / storyDuration)
        } else {
            return 0
        }
    }

    private func startTimer() {
        progress = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            progress += 0.05
            if progress >= storyDuration {
                goToNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func goToNext() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            stopTimer()
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        } else {
            // Restart current
            startTimer()
        }
    }
}

// MARK: - Legacy SocialFeedView (kept for compatibility)

struct SocialFeedView: View {
    let stories: [StoryWithProfile]

    var body: some View {
        EmptyView()
    }
}
