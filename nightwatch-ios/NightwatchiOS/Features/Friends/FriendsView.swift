import SwiftUI

struct FriendsView: View {
    @State private var viewModel = FriendsViewModel()
    let profile: Profile
    @Binding var pendingCount: Int

    @State private var selectedFriend: Profile?

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)

                            TextField("Rechercher par pseudo...", text: $viewModel.searchQuery)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.searchQuery) { _, _ in
                                    Task { await viewModel.searchUsers() }
                                }

                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.searchQuery = ""
                                    viewModel.searchResults = []
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        .padding(.horizontal, 16)

                        // Search results
                        if !viewModel.searchResults.isEmpty || viewModel.isSearching {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(title: "Résultats", icon: "magnifyingglass")
                                    .padding(.horizontal, 16)

                                if viewModel.isSearching {
                                    HStack {
                                        Spacer()
                                        ProgressView().tint(Color.appAccentPurple)
                                        Spacer()
                                    }
                                    .padding(.vertical, 20)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(viewModel.searchResults) { result in
                                            SearchResultRow(
                                                profile: result,
                                                isAlreadyFriend: viewModel.isAlreadyFriend(result)
                                            ) {
                                                Task { await viewModel.sendRequest(to: result) }
                                            }
                                            .onTapGesture { selectedFriend = result }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // Contact suggestions section
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Personnes que vous connaissez", icon: "person.crop.circle.badge.plus")
                                .padding(.horizontal, 16)

                            if viewModel.isLoadingContacts {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView().tint(Color.appAccentPurple)
                                        Text("Recherche dans vos contacts...")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.appTextSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 24)
                            } else if viewModel.contactSuggestions.isEmpty {
                                Button {
                                    Task { await viewModel.searchContacts() }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.appAccentPurple)
                                        Text("Trouver des amis dans mes contacts")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.appAccentPurple)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color.appTextSecondary)
                                    }
                                    .padding(14)
                                    .background(Color.appCard.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.appAccentPurple.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.contactSuggestions) { suggestion in
                                        ContactSuggestionRow(profile: suggestion) {
                                            Task { await viewModel.sendRequest(to: suggestion) }
                                        }
                                        .onTapGesture { selectedFriend = suggestion }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Pending requests
                        if !viewModel.pendingReceived.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeader(
                                    title: "Demandes reçues",
                                    icon: "person.badge.plus",
                                    badge: viewModel.pendingReceived.count
                                )
                                .padding(.horizontal, 16)

                                VStack(spacing: 8) {
                                    ForEach(viewModel.pendingReceived) { entry in
                                        FriendRequestRow(entry: entry) {
                                            Task {
                                                await viewModel.acceptRequest(entry.friendship)
                                                pendingCount = viewModel.pendingReceived.count
                                            }
                                        } onDecline: {
                                            Task {
                                                await viewModel.rejectRequest(entry.friendship)
                                                pendingCount = viewModel.pendingReceived.count
                                            }
                                        }
                                        .onTapGesture { selectedFriend = entry.profile }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Friends list
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(
                                title: "Mes amis",
                                icon: "person.2.fill",
                                count: viewModel.friends.count
                            )
                            .padding(.horizontal, 16)

                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(Color.appAccentPurple)
                                    Spacer()
                                }
                                .padding(.vertical, 24)
                            } else if viewModel.friends.isEmpty {
                                EmptyFriendsView()
                                    .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(viewModel.friends) { entry in
                                        FriendRow(entry: entry) {
                                            selectedFriend = entry.profile
                                        } onRemove: {
                                            Task { await viewModel.removeFriend(entry.friendship) }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Amis")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadFriends() }
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
            pendingCount = viewModel.pendingReceived.count
        }
        .sheet(item: $selectedFriend) { friend in
            UserProfileModal(profile: friend, viewingUserId: profile.userId)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Contact Suggestion Row

struct ContactSuggestionRow: View {
    let profile: Profile
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                avatarUrl: profile.avatarUrl,
                pseudo: profile.pseudo,
                size: 46,
                frameId: profile.avatarFrame
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.pseudo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Dans vos contacts")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Spacer()

            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Ajouter")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [Color.appAccentPurple, Color.appAccentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    var badge: Int? = nil
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appAccentPurple)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            if let badge = badge, badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.appDanger)
                    .clipShape(Capsule())
            }

            if let count = count {
                Text("(\(count))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.appAccentPurple.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.4))
            }
            VStack(spacing: 6) {
                Text("Aucun ami pour le moment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text("Recherchez des utilisateurs pour les ajouter en ami")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
        )
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let profile: Profile
    let isAlreadyFriend: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                avatarUrl: profile.avatarUrl,
                pseudo: profile.pseudo,
                size: 46,
                frameId: profile.avatarFrame
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.pseudo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    if let city = profile.city, !city.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appTextSecondary)
                        Text(city)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    } else {
                        Text("Nightwatcher")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            Spacer()

            if isAlreadyFriend {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("Ajouté")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.appSuccess)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.appSuccess.opacity(0.1))
                .clipShape(Capsule())
            } else {
                Button(action: onAdd) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Ajouter")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color.appAccentPurple, Color.appAccentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let entry: FriendWithProfile
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                avatarUrl: entry.profile.avatarUrl,
                pseudo: entry.profile.pseudo,
                size: 46,
                frameId: entry.profile.avatarFrame
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.profile.pseudo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("vous a envoyé une demande d'ami")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appDanger)
                        .frame(width: 36, height: 36)
                        .background(Color.appDanger.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appSuccess)
                        .frame(width: 36, height: 36)
                        .background(Color.appSuccess.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appSuccess.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appAccentPurple.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appAccentPurple.opacity(0.15), lineWidth: 1))
        )
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let entry: FriendWithProfile
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarUrl: entry.profile.avatarUrl,
                    pseudo: entry.profile.pseudo,
                    size: 46,
                    frameId: entry.profile.avatarFrame
                )
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.appCard, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.profile.pseudo)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                if entry.currentBac > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: BACCalculator.level(for: entry.currentBac).colorHex))
                        Text(String(format: "%.3f g/dL", entry.currentBac))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: BACCalculator.level(for: entry.currentBac).colorHex))
                    }
                } else if let city = entry.profile.city, !city.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appTextSecondary)
                        Text(city)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                } else {
                    Text("Voir le profil")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appAccentPurple)
                }
            }

            Spacer()

            Button(action: onTap) {
                Text("Profil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appAccentPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.appAccentPurple.opacity(0.12))
                    .clipShape(Capsule())
            }

            Menu {
                Button(role: .destructive, action: onRemove) {
                    Label("Retirer l'ami", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .onTapGesture { onTap() }
    }
}
