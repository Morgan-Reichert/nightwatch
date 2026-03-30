import SwiftUI
import Supabase

@Observable
class AppState {
    var selectedTab: Int = 0
    var currentPartyId: UUID? = nil
    var currentProfile: Profile? = nil
    var pendingFriendRequestCount: Int = 0
    var pendingPartyInvitationCount: Int = 0
}

struct MainTabView: View {
    let profile: Profile
    let onSignOut: () -> Void
    @State private var appState = AppState()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView(profile: profile)
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(0)

            PartyView(profile: profile)
                .tabItem { Label("Soirée", systemImage: "party.popper.fill") }
                .tag(1)
                .badge(appState.pendingPartyInvitationCount > 0 ? appState.pendingPartyInvitationCount : 0)

            LeaderboardView(profile: profile)
                .tabItem { Label("Top", systemImage: "trophy.fill") }
                .tag(2)

            FriendsView(profile: profile, pendingCount: $appState.pendingFriendRequestCount)
                .tabItem { Label("Amis", systemImage: "person.2.fill") }
                .tag(3)
                .badge(appState.pendingFriendRequestCount > 0 ? appState.pendingFriendRequestCount : 0)

            SettingsView(profile: profile, onSignOut: onSignOut)
                .tabItem { Label("Profil", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .onAppear { setupTabBarAppearance() }
        .task { await loadBadgeCounts() }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToProfileTab)) { _ in
            appState.selectedTab = 4
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPartyTab)) { _ in
            appState.selectedTab = 1
        }
        .preferredColorScheme(.dark)
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.09, alpha: 0.95)

        // Selected state
        let selectedAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs

        // Normal state
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1)
    }

    private func loadBadgeCounts() async {
        do {
            // Pending friend requests
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .eq("addressee_id", value: profile.userId.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value
            appState.pendingFriendRequestCount = friendships.count
        } catch {}

        do {
            // Pending party invitations
            let invitations: [PartyRequest] = try await supabase
                .from("party_requests")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .eq("status", value: "pending")
                .execute()
                .value
            appState.pendingPartyInvitationCount = invitations.count
        } catch {}
    }
}
