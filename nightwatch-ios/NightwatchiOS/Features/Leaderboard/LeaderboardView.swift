import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var selectedProfile: Profile?
    let profile: Profile

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 0) {
                    // Scope toggle: Soirée / Amis
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                                Button {
                                    if viewModel.selectedScope != scope {
                                        viewModel.selectedScope = scope
                                        Task { await viewModel.refresh() }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: scope.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(scope.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(viewModel.selectedScope == scope ? .white : Color.appTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.selectedScope == scope
                                            ? LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue],
                                                             startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))

                        // Context label under the toggle
                        if viewModel.selectedScope == .party, let party = viewModel.activeParty {
                            HStack(spacing: 5) {
                                Image(systemName: "party.popper.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.appAccentPurple)
                                Text(party.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.appTextSecondary)
                                Text("· stats de cette soirée uniquement")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                            }
                        } else if viewModel.selectedScope == .friends {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.appTextSecondary)
                                Text("Stats du jour — tous vos amis")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedCategory = category
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(category.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(viewModel.selectedCategory == category ? .white : Color.appTextSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        viewModel.selectedCategory == category
                                        ? LinearGradient(
                                            colors: [Color.appAccentPurple, Color.appAccentBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                        : LinearGradient(
                                            colors: [Color.appCard, Color.appCard],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            viewModel.selectedCategory == category
                                                ? Color.clear
                                                : Color.white.opacity(0.08),
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 10)

                    // BAC toggle for alcohol tab
                    if viewModel.selectedCategory == .alcohol {
                        HStack {
                            Image(systemName: viewModel.showMyBAC ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                            Text(viewModel.showMyBAC ? "Mon BAC visible" : "Mon BAC masqué")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                            Spacer()
                            Toggle("", isOn: $viewModel.showMyBAC)
                                .tint(Color.appAccentPurple)
                                .onChange(of: viewModel.showMyBAC) { _, _ in
                                    Task {
                                        if let party = viewModel.activeParty {
                                            await viewModel.toggleBACVisibility(
                                                partyId: party.id,
                                                userId: profile.userId
                                            )
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    if viewModel.isLoading {
                        Spacer()
                        VStack(spacing: 14) {
                            ProgressView().tint(Color.appAccentPurple).scaleEffect(1.3)
                            Text("Chargement...").font(.subheadline).foregroundStyle(Color.appTextSecondary)
                        }
                        Spacer()
                    } else if viewModel.selectedScope == .party && viewModel.activeParty == nil {
                        Spacer()
                        NoPartyLeaderboardView()
                        Spacer()
                    } else if viewModel.currentEntries.isEmpty {
                        Spacer()
                        EmptyLeaderboardView()
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 20) {
                                let entries = viewModel.currentEntries

                                // Podium
                                if entries.count >= 3 {
                                    LeaderboardPodiumNew(
                                        first: entries[0],
                                        second: entries[1],
                                        third: entries[2],
                                        category: viewModel.selectedCategory,
                                        onTap: { selectedProfile = $0 }
                                    )
                                    .padding(.horizontal, 16)
                                }

                                // Full ranked list
                                VStack(spacing: 8) {
                                    ForEach(entries) { entry in
                                        LeaderboardEntryRowNew(
                                            entry: entry,
                                            isCurrentUser: entry.profile.userId == profile.userId,
                                            category: viewModel.selectedCategory
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedProfile = entry.profile }
                                    }
                                }
                                .padding(.horizontal, 16)

                                Spacer(minLength: 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Classement")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
        }
        .task {
            await viewModel.load(profile: profile)
        }
        .sheet(item: $selectedProfile) { p in
            UserProfileModal(profile: p, viewingUserId: profile.userId)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - No Party State

struct NoPartyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appAccentPurple.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.5))
            }
            VStack(spacing: 8) {
                Text("Classement verrouillé")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Rejoins une soirée dans l'onglet Soirée\npour voir le classement de tes amis.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appAccentPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            VStack(spacing: 8) {
                Text("Pas encore de données")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Rejoins une soirée pour apparaître dans le classement")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Podium

struct LeaderboardPodiumNew: View {
    let first: LeaderboardEntry
    let second: LeaderboardEntry
    let third: LeaderboardEntry
    let category: LeaderboardCategory
    var onTap: ((Profile) -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            PodiumSlotNew(entry: second, rank: 2, barHeight: 90, category: category, onTap: onTap)
            PodiumSlotNew(entry: first, rank: 1, barHeight: 120, category: category, onTap: onTap)
            PodiumSlotNew(entry: third, rank: 3, barHeight: 68, category: category, onTap: onTap)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 1))
        )
    }
}

struct PodiumSlotNew: View {
    let entry: LeaderboardEntry
    let rank: Int
    let barHeight: CGFloat
    let category: LeaderboardCategory
    var onTap: ((Profile) -> Void)? = nil

    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        default: return "medal.fill"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        default: return Color(hex: "#CD7F32")
        }
    }

    private var barColors: [Color] {
        switch rank {
        case 1: return [Color(hex: "#FFD700").opacity(0.7), Color(hex: "#F59E0B").opacity(0.5)]
        case 2: return [Color(hex: "#C0C0C0").opacity(0.6), Color(hex: "#9CA3AF").opacity(0.4)]
        default: return [Color(hex: "#CD7F32").opacity(0.6), Color(hex: "#92400E").opacity(0.4)]
        }
    }

    var body: some View {
        Button {
            onTap?(entry.profile)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: rankIcon)
                    .font(.system(size: rank == 1 ? 22 : 16, weight: .bold))
                    .foregroundStyle(rankColor)
                    .padding(.bottom, 2)

                AvatarView(
                    avatarUrl: entry.profile.avatarUrl,
                    pseudo: entry.profile.pseudo,
                    size: rank == 1 ? 52 : 44,
                    frameId: entry.profile.avatarFrame
                )
                .overlay(
                    Circle().stroke(rankColor.opacity(0.5), lineWidth: rank == 1 ? 2.5 : 1.5)
                )

                Text(entry.profile.pseudo)
                    .font(.system(size: rank == 1 ? 13 : 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(entry.displayValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(rankColor)
                    .lineLimit(1)

                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: barColors, startPoint: .top, endPoint: .bottom))
                    .frame(height: barHeight)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(rankColor.opacity(0.3), lineWidth: 1))

                Text("#\(rank)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(rankColor)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Entry Row

struct LeaderboardEntryRowNew: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let category: LeaderboardCategory

    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.appTextSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if !rankIcon.isEmpty {
                    Image(systemName: rankIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(rankColor)
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(rankColor)
                }
            }
            .frame(width: 28)

            AvatarView(
                avatarUrl: entry.profile.avatarUrl,
                pseudo: entry.profile.pseudo,
                size: 42,
                frameId: entry.profile.avatarFrame
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.profile.pseudo)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if isCurrentUser {
                        Text("Moi")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.appAccentPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccentPurple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(entry.displayValue)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            // Category icon
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(category.accentColor.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrentUser ? Color.appAccentPurple.opacity(0.12) : Color.appCard.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isCurrentUser ? Color.appAccentPurple.opacity(0.4) : Color.white.opacity(0.06),
                            lineWidth: isCurrentUser ? 1.5 : 1
                        )
                )
        )
    }
}
