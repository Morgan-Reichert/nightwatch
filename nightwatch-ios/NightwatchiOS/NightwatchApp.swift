import SwiftUI

@main
struct NightwatchApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentRootView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let profile = authViewModel.currentProfile {
                MainTabView(profile: profile) {
                    Task { await authViewModel.signOut() }
                }
            } else {
                AuthView()
                    .environment(authViewModel)
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}
