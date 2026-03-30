import SwiftUI

struct UserProfileModal: View {
    let profile: Profile
    let viewingUserId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var drinks: [Drink] = []
    @State private var earnedBadges: [EarnedBadge] = []
    @State private var streakInfo: StreakInfo = StreakInfo(weeks: 0, color: .gray, label: "Aucun streak")
    @State private var currentBAC: Double = 0.0
    @State private var totalParties: Int = 0
    @State private var totalFriends: Int = 0
    @State private var totalDrinks: Int = 0
    @State private var isLoading = true
    @State private var selectedTab: ProfileTab = .about
    @State private var friendshipStatus: FriendshipStatus = .none
    @State private var isActionLoading = false

    enum ProfileTab: String, CaseIterable {
        case about = "À propos"
        case badges = "Badges"
        case cards = "Cartes"

        var icon: String {
            switch self {
            case .about: return "person.fill"
            case .badges: return "star.fill"
            case .cards: return "rectangle.stack.fill"
            }
        }
    }

    enum FriendshipStatus {
        case none
        case pending
        case friend
        case isSelf
    }

    private var bannerColors: [Color] {
        guard let gradientId = profile.bannerGradient else {
            return [Color.appAccentPurple.opacity(0.6), Color.appAccentBlue.opacity(0.4)]
        }
        let item = ShopItem.allItems.first { $0.id == gradientId }
        return item?.previewColors ?? [Color.appAccentPurple.opacity(0.6), Color.appAccentBlue.opacity(0.4)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Banner
                        LinearGradient(
                            colors: bannerColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 140)
                        .overlay(alignment: .bottom) {
                            // Avatar positioned over banner bottom edge
                            AvatarView(
                                avatarUrl: profile.avatarUrl,
                                pseudo: profile.pseudo,
                                size: 88,
                                frameId: profile.avatarFrame
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#0a0a0f"), lineWidth: 3)
                            )
                            .offset(y: 44)
                        }

                        // Profile info
                        VStack(spacing: 8) {
                            Spacer().frame(height: 52)

                            // Name + pseudo
                            VStack(spacing: 4) {
                                Text(profile.pseudo)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)

                                if let bio = profile.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.appTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                            }

                            // BAC + streak badges row
                            HStack(spacing: 10) {
                                if currentBAC > 0 {
                                    HStack(spacing: 5) {
                                        Image(systemName: "drop.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color(hex: BACCalculator.level(for: currentBAC).colorHex))
                                        Text(String(format: "%.3f g/L", currentBAC))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color(hex: BACCalculator.level(for: currentBAC).colorHex))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: BACCalculator.level(for: currentBAC).colorHex).opacity(0.15))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color(hex: BACCalculator.level(for: currentBAC).colorHex).opacity(0.3), lineWidth: 1))
                                }

                                if streakInfo.weeks > 0 {
                                    HStack(spacing: 5) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(streakInfo.color)
                                        Text("\(streakInfo.weeks) sem.")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(streakInfo.color)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(streakInfo.color.opacity(0.15))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(streakInfo.color.opacity(0.3), lineWidth: 1))
                                }
                            }

                            // Stats row
                            HStack(spacing: 0) {
                                ProfileStatCell(value: "\(totalParties)", label: "Soirées", icon: "party.popper.fill")
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                ProfileStatCell(value: "\(totalFriends)", label: "Amis", icon: "person.2.fill")
                                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 36)
                                ProfileStatCell(value: "\(totalDrinks)", label: "Boissons", icon: "mug.fill")
                            }
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.appCard.opacity(0.6))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // Friend action button
                            if friendshipStatus != .isSelf {
                                ProfileFriendButton(
                                    status: friendshipStatus,
                                    isLoading: isActionLoading,
                                    onAction: handleFriendAction
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 16)

                        // Tab selector
                        ProfileTabBar(selectedTab: $selectedTab)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)

                        // Tab content
                        switch selectedTab {
                        case .about:
                            ProfileAboutTab(profile: profile)
                                .padding(.horizontal, 16)
                        case .badges:
                            ProfileBadgesTab(earnedBadges: earnedBadges)
                                .padding(.horizontal, 16)
                        case .cards:
                            ProfileCardsTab(cards: profile.customCards ?? [])
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .ignoresSafeArea(edges: .top)

                if isLoading {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color.appAccentPurple)
                            .scaleEffect(1.3)
                        Text("Chargement...")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await loadUserData()
        }
        .preferredColorScheme(.dark)
    }

    private func handleFriendAction() {
        Task {
            isActionLoading = true
            defer { isActionLoading = false }
            do {
                if friendshipStatus == .friend {
                    // Remove friend
                    try await supabase
                        .from("friendships")
                        .delete()
                        .or("and(requester_id.eq.\(viewingUserId.uuidString),addressee_id.eq.\(profile.userId.uuidString)),and(requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(viewingUserId.uuidString))")
                        .execute()
                    friendshipStatus = .none
                } else if friendshipStatus == .none {
                    // Send request
                    struct FriendshipInsert: Codable {
                        let requesterId: UUID
                        let addresseeId: UUID
                        let status: String
                        enum CodingKeys: String, CodingKey {
                            case requesterId = "requester_id"
                            case addresseeId = "addressee_id"
                            case status
                        }
                    }
                    let insert = FriendshipInsert(requesterId: viewingUserId, addresseeId: profile.userId, status: "pending")
                    try await supabase
                        .from("friendships")
                        .insert(insert)
                        .execute()
                    friendshipStatus = .pending
                }
            } catch {}
        }
    }

    private func loadUserData() async {
        isLoading = true
        defer { Task { @MainActor in isLoading = false } }

        do {
            // Drinks today
            let today = Calendar.current.startOfDay(for: Date())
            let todayDrinks: [Drink] = try await supabase
                .from("drinks")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .gte("created_at", value: ISO8601DateFormatter().string(from: today))
                .execute()
                .value

            // All drinks for streak + stats
            let allDrinks: [Drink] = try await supabase
                .from("drinks")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            // Parties count
            let parties: [PartyMember] = try await supabase
                .from("party_members")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            // Friends count
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(profile.userId.uuidString)")
                .eq("status", value: "accepted")
                .execute()
                .value

            // Pukes for badge stats
            let pukes: [PukeEvent] = try await supabase
                .from("puke_events")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            // Shop events
            let shopEvts: [ShopEvent] = try await supabase
                .from("shop_events")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            // Viewing user friendship status
            var status: FriendshipStatus = .none
            if viewingUserId == profile.userId {
                status = .isSelf
            } else {
                let viewerFriendships: [Friendship] = try await supabase
                    .from("friendships")
                    .select()
                    .or("and(requester_id.eq.\(viewingUserId.uuidString),addressee_id.eq.\(profile.userId.uuidString)),and(requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(viewingUserId.uuidString))")
                    .execute()
                    .value

                if let existing = viewerFriendships.first {
                    status = existing.status == "accepted" ? .friend : .pending
                }
            }

            let stats = UserStats(
                totalDrinks: allDrinks.filter { $0.abv > 0 }.count,
                totalParties: parties.count,
                totalPukes: pukes.count,
                totalKisses: shopEvts.count,
                totalFriends: friendships.count
            )

            await MainActor.run {
                self.drinks = todayDrinks
                self.currentBAC = BACCalculator.calculateBAC(drinks: todayDrinks, profile: profile)
                self.streakInfo = StreakService.calculateStreak(drinks: allDrinks)
                self.earnedBadges = BadgeService.computeEarnedBadges(stats: stats)
                self.totalParties = parties.count
                self.totalFriends = friendships.count
                self.totalDrinks = allDrinks.filter { $0.abv > 0 }.count
                self.friendshipStatus = status
                self.isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Stat Cell
private struct ProfileStatCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appAccentPurple)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Button
private struct ProfileFriendButton: View {
    let status: UserProfileModal.FriendshipStatus
    let isLoading: Bool
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(buttonLabel)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading || status == .pending)
    }

    private var buttonIcon: String {
        switch status {
        case .friend: return "person.badge.minus"
        case .pending: return "clock.fill"
        case .none, .isSelf: return "person.badge.plus"
        }
    }

    private var buttonLabel: String {
        switch status {
        case .friend: return "Retirer l'ami"
        case .pending: return "Demande envoyée"
        case .none, .isSelf: return "Ajouter en ami"
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch status {
        case .friend:
            Color.appDanger.opacity(0.25)
        case .pending:
            Color.appTextSecondary.opacity(0.2)
        case .none, .isSelf:
            LinearGradient(
                colors: [Color.appAccentPurple, Color.appAccentBlue],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Tab Bar
private struct ProfileTabBar: View {
    @Binding var selectedTab: UserProfileModal.ProfileTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(UserProfileModal.ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        selectedTab == tab
                        ? LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
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
    }
}

// MARK: - About Tab
private struct ProfileAboutTab: View {
    let profile: Profile

    private var infoRows: [(String, String?, String)] {
        [
            ("location.fill", profile.city, "Ville"),
            ("building.columns.fill", profile.school, "École"),
            ("briefcase.fill", profile.job, "Emploi"),
            ("sparkles", profile.zodiac, "Zodiaque"),
            ("music.note", profile.musicTaste, "Musique"),
            ("star.fill", profile.partyStyle, "Style de soirée")
        ]
    }

    private var validInfoRows: [(String, String, String)] {
        infoRows.compactMap { icon, value, label in
            guard let v = value, !v.isEmpty else { return nil }
            return (icon, v, label)
        }
    }

    private struct SocialLink {
        let icon: String
        let handle: String
        let platform: String
        let appURL: URL?
        let webURL: URL?
    }

    private var validSocials: [SocialLink] {
        var result: [SocialLink] = []
        if let h = profile.snapchat, !h.isEmpty {
            let clean = h.hasPrefix("@") ? String(h.dropFirst()) : h
            result.append(SocialLink(
                icon: "camera.fill",
                handle: clean,
                platform: "Snapchat",
                appURL: URL(string: "snapchat://add/\(clean)"),
                webURL: URL(string: "https://www.snapchat.com/add/\(clean)")
            ))
        }
        if let h = profile.instagram, !h.isEmpty {
            let clean = h.hasPrefix("@") ? String(h.dropFirst()) : h
            result.append(SocialLink(
                icon: "photo.fill",
                handle: clean,
                platform: "Instagram",
                appURL: URL(string: "instagram://user?username=\(clean)"),
                webURL: URL(string: "https://www.instagram.com/\(clean)")
            ))
        }
        if let h = profile.tiktok, !h.isEmpty {
            let clean = h.hasPrefix("@") ? String(h.dropFirst()) : h
            result.append(SocialLink(
                icon: "play.rectangle.fill",
                handle: clean,
                platform: "TikTok",
                appURL: URL(string: "snssdk1233://user/profile/\(clean)"),
                webURL: URL(string: "https://www.tiktok.com/@\(clean)")
            ))
        }
        return result
    }

    private func openSocial(_ link: SocialLink) {
        if let appURL = link.appURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = link.webURL {
            UIApplication.shared.open(webURL)
        }
    }

    private func socialColor(_ platform: String) -> Color {
        switch platform {
        case "Snapchat": return Color(hex: "#FFFC00")
        case "Instagram": return Color(hex: "#E1306C")
        case "TikTok": return Color(hex: "#69C9D0")
        default: return Color.appAccentPurple
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if !validInfoRows.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Infos", systemImage: "person.text.rectangle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(validInfoRows, id: \.2) { icon, value, label in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appAccentPurple.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.appAccentPurple)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(label)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.appTextSecondary)
                                    Text(value)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appCard.opacity(0.7))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1))
                            )
                        }
                    }
                }
            }

            if !validSocials.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Réseaux sociaux", systemImage: "link")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)

                    HStack(spacing: 10) {
                        ForEach(validSocials, id: \.platform) { link in
                            Button {
                                openSocial(link)
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(socialColor(link.platform).opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: link.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(socialColor(link.platform))
                                    }

                                    VStack(spacing: 2) {
                                        Text("@\(link.handle)")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        Text(link.platform)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.appTextSecondary)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(socialColor(link.platform).opacity(0.6))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.appCard.opacity(0.7))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(socialColor(link.platform).opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if validInfoRows.isEmpty && validSocials.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                    Text("Aucune information disponible")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Badges Tab
private struct ProfileBadgesTab: View {
    let earnedBadges: [EarnedBadge]

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if earnedBadges.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "star.slash.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                    Text("Aucun badge encore")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FFD700"))
                    Text("\(earnedBadges.count) badge\(earnedBadges.count > 1 ? "s" : "") obtenus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(earnedBadges) { badge in
                        ProfileBadgeCell(badge: badge)
                    }
                }
            }
        }
    }
}

private struct ProfileBadgeCell: View {
    let badge: EarnedBadge

    private var categoryIcon: String {
        switch badge.definition.category {
        case .drinks: return "mug.fill"
        case .parties: return "party.popper.fill"
        case .pukes: return "exclamationmark.triangle.fill"
        case .kisses: return "heart.fill"
        case .friends: return "person.2.fill"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.tier.color.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(badge.tier.color.opacity(0.5), lineWidth: 2)
                    )

                Image(systemName: categoryIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(badge.tier.color)
            }

            Text(badge.definition.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(badge.tier.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(badge.tier.color)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCard.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(badge.tier.color.opacity(0.2), lineWidth: 1))
        )
    }
}

// MARK: - Cards Tab
private struct ProfileCardsTab: View {
    let cards: [CustomCard]

    var body: some View {
        VStack(spacing: 10) {
            if cards.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                    Text("Aucune carte personnalisée")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(cards) { card in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appAccentPurple.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: card.icon ?? "info.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.appAccentPurple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(card.value)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appCard.opacity(0.7))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
                    )
                }
            }
        }
    }
}
