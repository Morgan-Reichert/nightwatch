import SwiftUI
import UserNotifications

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    let profile: Profile

    @State private var showDrinkSelector = false
    @State private var showCameraScanner = false
    @State private var showDrinkHistory = false
    @State private var showProfileModal = false
    @State private var showStoryFullscreen = false
    @State private var selectedStoryIndex: Int = 0
    @State private var showNotifAlert = false
    @State private var notifAlertMessage = ""
    @State private var showNoPartyAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Stories bar
                        if !viewModel.friendStories.isEmpty {
                            StoryCirclesRow(
                                stories: viewModel.friendStories,
                                currentProfile: profile,
                                onAddStory: {},
                                onSelectStory: { index in
                                    selectedStoryIndex = index
                                    showStoryFullscreen = true
                                }
                            )
                            .padding(.bottom, 12)
                        }

                        // Header
                        HomeHeaderView(
                            profile: profile,
                            streakInfo: viewModel.streakInfo,
                            onAvatarTap: { showProfileModal = true },
                            onNotificationTap: {
                            Task { await requestNotificationPermission() }
                        }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)

                        // BAC Gauge
                        BACGaugeView(
                            bac: viewModel.currentBAC,
                            level: viewModel.bacLevel,
                            hoursUntilSober: viewModel.hoursUntilSober,
                            drinkCount: viewModel.drinkCount
                        )
                        .padding(.bottom, 16)

                        // Quick Actions
                        VStack(spacing: 10) {
                            // Row 1: Big add drink button
                            Button {
                                showDrinkSelector = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Ajouter une boisson")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.appAccentPurple, Color.appAccentBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.appAccentPurple.opacity(0.4), radius: 12, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)

                            // Row 2: Kiss + Quiche (nécessitent une soirée active)
                            let inParty = viewModel.activePartyId != nil
                            HStack(spacing: 10) {
                                // Kiss button
                                Button {
                                    if inParty {
                                        Task { await viewModel.logKiss() }
                                    } else {
                                        showNoPartyAlert = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: inParty ? "heart.fill" : "heart.slash.fill")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("Kiss")
                                            .font(.system(size: 15, weight: .bold))
                                        if viewModel.kissCount > 0 {
                                            Text("\(viewModel.kissCount)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(Color.white.opacity(0.25))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .foregroundStyle(.white.opacity(inParty ? 1.0 : 0.55))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: inParty
                                                ? [Color(hex: "#ec4899"), Color(hex: "#be185d")]
                                                : [Color.appCard, Color.appCard],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        inParty ? nil :
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "#ec4899").opacity(0.35), lineWidth: 1.5)
                                    )
                                    .shadow(color: Color(hex: "#ec4899").opacity(inParty ? 0.35 : 0), radius: 8, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)

                                // Quiche button
                                Button {
                                    if inParty {
                                        Task { await viewModel.logPuke() }
                                    } else {
                                        showNoPartyAlert = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.bubble.fill")
                                            .font(.system(size: 17, weight: .semibold))
                                        Text("Quiche")
                                            .font(.system(size: 15, weight: .bold))
                                        if viewModel.pukeCount > 0 {
                                            Text("\(viewModel.pukeCount)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(Color.white.opacity(0.25))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .foregroundStyle(.white.opacity(inParty ? 1.0 : 0.55))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: inParty
                                                ? [Color(hex: "#f97316"), Color(hex: "#c2410c")]
                                                : [Color.appCard, Color.appCard],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        inParty ? nil :
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: "#f97316").opacity(0.35), lineWidth: 1.5)
                                    )
                                    .shadow(color: Color(hex: "#f97316").opacity(inParty ? 0.35 : 0), radius: 8, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)

                        // Recent drinks
                        if !viewModel.drinks.isEmpty {
                            RecentDrinksSection(
                                drinks: viewModel.drinks,
                                onDelete: { drink in
                                    Task { await viewModel.deleteDrink(drink) }
                                },
                                onSeeAll: { showDrinkHistory = true }
                            )
                            .padding(.bottom, 16)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }

                // Loading overlay
                if viewModel.isLoading && viewModel.drinks.isEmpty {
                    VStack {
                        ProgressView()
                            .tint(Color.appAccentPurple)
                            .scaleEffect(1.3)
                    }
                }

            }
            .navigationBarHidden(true)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Scanner bubble — always visible just above emergency strip
                HStack {
                    Spacer()
                    Button {
                        showCameraScanner = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 17, weight: .bold))
                            Text("Scanner")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.appAccentPurple, Color.appAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.appAccentPurple.opacity(0.7), radius: 12, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                }

                HomeEmergencyStrip(profile: profile)
            }
        }
        .task {
            await viewModel.load(profile: profile)
        }
        .sheet(isPresented: $showDrinkSelector, onDismiss: {
            // Force reload when sheet closes to ensure BAC gauge updates
            Task { await viewModel.loadDrinks() }
        }) {
            DrinkSelectorView { template in
                Task { await viewModel.logDrink(template: template) }
            }
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showCameraScanner) {
            CameraScannerView { name, volumeMl, abv in
                Task { await viewModel.logDrinkFromAI(name: name, volumeMl: volumeMl, abv: abv) }
            }
        }
        .sheet(isPresented: $showDrinkHistory) {
            DrinkHistoryView(drinks: viewModel.drinks) { drink in
                Task { await viewModel.deleteDrink(drink) }
            }
        }
        .sheet(isPresented: $showProfileModal) {
            UserProfileModal(profile: profile, viewingUserId: profile.userId)
        }
        .fullScreenCover(isPresented: $showStoryFullscreen) {
            StoryFullscreenView(stories: viewModel.friendStories, currentIndex: selectedStoryIndex)
        }
        .alert("Soirée requise", isPresented: $showNoPartyAlert) {
            Button("Rejoindre une soirée") {
                NotificationCenter.default.post(name: .navigateToPartyTab, object: nil)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Kiss et Quiche sont enregistrés dans la soirée. Rejoins ou crée une soirée pour les utiliser.")
        }
        .alert(notifAlertMessage, isPresented: $showNotifAlert) {
            if notifAlertMessage.contains("Paramètres") {
                Button("Ouvrir Paramètres") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Annuler", role: .cancel) {}
            } else {
                Button("OK") {}
            }
        }
        .preferredColorScheme(.dark)
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()

        switch current.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            await MainActor.run {
                notifAlertMessage = granted
                    ? "Notifications activées ! Tu recevras des alertes Nightwatch."
                    : "Notifications refusées."
                showNotifAlert = true
            }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                notifAlertMessage = "Les notifications sont déjà activées."
                showNotifAlert = true
            }
        case .denied:
            await MainActor.run {
                notifAlertMessage = "Notifications désactivées. Ouvre les Paramètres iOS pour les réactiver."
                showNotifAlert = true
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Header

struct HomeHeaderView: View {
    let profile: Profile
    let streakInfo: StreakInfo
    let onAvatarTap: () -> Void
    let onNotificationTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onAvatarTap) {
                AvatarView(
                    avatarUrl: profile.avatarUrl,
                    pseudo: profile.pseudo,
                    size: 46,
                    frameId: profile.avatarFrame
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Bonsoir,")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.appTextSecondary)
                Text(profile.pseudo)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            if streakInfo.weeks > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(streakInfo.color)
                    Text("\(streakInfo.weeks)sem")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(streakInfo.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(streakInfo.color.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(streakInfo.color.opacity(0.3), lineWidth: 1))
            }

            Button(action: onNotificationTap) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.appCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
}

// MARK: - Emergency Strip (inline, above tab bar)

struct HomeEmergencyStrip: View {
    let profile: Profile?
    @State private var showUrgenceDialog = false
    @State private var showCallAlert = false
    @State private var showNoContactSheet = false

    var body: some View {
        HStack(spacing: 10) {
            // Emergency contact
            Button {
                showUrgenceDialog = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Urgence")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.appSuccess)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .confirmationDialog("Que veux-tu faire ?", isPresented: $showUrgenceDialog, titleVisibility: .visible) {
                Button("📞 Appeler mon contact d'urgence") {
                    if let contact = profile?.emergencyContact, !contact.isEmpty {
                        showCallAlert = true
                    } else {
                        showNoContactSheet = true
                    }
                }
                Button("🆘 SOS Soirée — Demander de l'aide") {
                    NotificationCenter.default.post(name: .navigateToPartyTab, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: .triggerPartySOS, object: nil)
                    }
                }
                Button("Annuler", role: .cancel) {}
            }

            // Uber
            Button {
                if let url = URL(string: "uber://"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: "https://m.uber.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Uber")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#1f2937"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            // SOS 112
            Button {
                if let url = URL(string: "tel://112") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("SOS 112")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.appDanger)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.bottom, 12)
        .background(
            Color.appBackground.opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
        .alert("Appeler le contact d'urgence ?", isPresented: $showCallAlert) {
            Button("Appeler \(profile?.emergencyContact ?? "")") {
                let number = (profile?.emergencyContact ?? "").filter("0123456789+".contains)
                if let url = URL(string: "tel://\(number)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous allez appeler \(profile?.emergencyContact ?? "votre contact d'urgence").")
        }
        .sheet(isPresented: $showNoContactSheet) {
            NoContactSetupSheet()
        }
    }
}

// MARK: - Quick Action (kept for other potential uses)

struct QuickActionButton: View {
    let icon: String
    let label: String
    let gradient: [Color]
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: gradient.first?.opacity(0.4) ?? .clear, radius: 10, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appCard.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.1)) { pressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.3)) { pressed = false } }
        )
    }
}

// MARK: - Recent Drinks Section

struct RecentDrinksSection: View {
    let drinks: [Drink]
    let onDelete: (Drink) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Boissons récentes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onSeeAll) {
                    Text("Voir tout")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appAccentPurple)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                ForEach(drinks.prefix(5)) { drink in
                    DrinkHistoryRow(drink: drink) {
                        onDelete(drink)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Drink Row

struct DrinkHistoryRow: View {
    let drink: Drink
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(drinkGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: drinkIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(drink.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if drink.detectedByAi {
                        Text("IA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.appAccentPurple)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.appAccentPurple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text("\(Int(drink.volumeMl))ml  •  \(Int(drink.abv * 100))% ABV")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "+%.1fg", drink.alcoholGrams))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.appWarning)
                if let date = drink.createdAt {
                    Text(date, style: .time)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appDanger.opacity(0.7))
                    .padding(8)
                    .background(Color.appDanger.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private var drinkIcon: String {
        let lower = drink.name.lowercased()
        if lower.contains("beer") || lower.contains("biere") || lower.contains("bière") || lower.contains("pint") { return "mug.fill" }
        if lower.contains("wine") || lower.contains("vin") || lower.contains("rosé") { return "wineglass.fill" }
        if lower.contains("champagne") { return "wineglass" }
        if lower.contains("water") || lower.contains("eau") { return "drop.fill" }
        if lower.contains("juice") || lower.contains("jus") { return "cup.and.saucer.fill" }
        if lower.contains("shot") || lower.contains("whisky") || lower.contains("vodka") ||
           lower.contains("rum") || lower.contains("tequila") || lower.contains("gin") { return "chart.bar.fill" }
        if lower.contains("cocktail") || lower.contains("mojito") { return "bubbles.and.sparkles" }
        return "drop.fill"
    }

    private var drinkGradient: LinearGradient {
        let lower = drink.name.lowercased()
        if lower.contains("beer") || lower.contains("biere") || lower.contains("bière") || lower.contains("pint") {
            return LinearGradient(colors: [Color(hex: "#f59e0b"), Color(hex: "#d97706")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if lower.contains("wine") || lower.contains("vin") || lower.contains("rosé") {
            return LinearGradient(colors: [Color(hex: "#9f1239"), Color(hex: "#7c3aed")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if lower.contains("water") || lower.contains("eau") {
            return LinearGradient(colors: [Color(hex: "#0891b2"), Color(hex: "#0ea5e9")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if drink.abv == 0 {
            return LinearGradient(colors: [Color(hex: "#0d9488"), Color(hex: "#0891b2")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if drink.abv > 0.2 {
            return LinearGradient(colors: [Color(hex: "#92400e"), Color(hex: "#d97706")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Drink History Sheet

struct DrinkHistoryView: View {
    let drinks: [Drink]
    let onDelete: (Drink) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                if drinks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                        Text("Aucune boisson aujourd'hui")
                            .font(.headline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(drinks) { drink in
                                DrinkHistoryRow(drink: drink) {
                                    onDelete(drink)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
