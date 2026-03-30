import SwiftUI
import MapKit
import CoreLocation
import UserNotifications
import AudioToolbox
import AVFoundation

// MARK: - CLLocationManager Observable Wrapper

@Observable
class LocationManagerWrapper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var lastLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - MemberMapView

struct MemberMapView: View {
    let members: [PartyMemberWithProfile]
    let partyId: UUID
    let profile: Profile

    @State private var locationWrapper = LocationManagerWrapper()
    @State private var memberLocations: [MemberLocation] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isSharing = true
    @State private var locationTimer: Timer?
    @State private var showSOSConfirm = false
    @State private var locationRefreshTimer: Timer?
    @State private var isPulsingOwn = false
    @State private var selectedMember: PartyMemberWithProfile?
    @State private var selectedMemberLocation: MemberLocation?
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var showProfileSheet = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $cameraPosition) {
                ForEach(memberLocations, id: \.id) { location in
                    if let member = members.first(where: { $0.profile.userId == location.userId }) {
                        Annotation(
                            "",
                            coordinate: CLLocationCoordinate2D(
                                latitude: location.latitude,
                                longitude: location.longitude
                            )
                        ) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    if selectedMember?.profile.userId == member.profile.userId {
                                        selectedMember = nil
                                        selectedMemberLocation = nil
                                    } else {
                                        selectedMember = member
                                        selectedMemberLocation = location
                                    }
                                }
                            } label: {
                                MapMemberPin(
                                    member: member,
                                    isCurrentUser: member.profile.userId == profile.userId,
                                    isSharing: isSharing && member.profile.userId == profile.userId,
                                    isPulsing: isPulsingOwn && member.profile.userId == profile.userId,
                                    isSelected: selectedMember?.profile.userId == member.profile.userId
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .preferredColorScheme(.dark)
            .ignoresSafeArea(edges: .bottom)

            // Recenter button
            Button {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if let loc = locationWrapper.lastLocation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    } else {
                        cameraPosition = .automatic
                    }
                }
            } label: {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.appAccentPurple)
                    .padding(10)
                    .background(Color.appCard.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Selected member card
                if let member = selectedMember, let location = selectedMemberLocation {
                    SelectedMemberCard(
                        member: member,
                        location: location,
                        currentUserId: profile.userId,
                        onViewProfile: { showProfileSheet = true },
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedMember = nil
                                selectedMemberLocation = nil
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                mapBottomSheet
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            if let member = selectedMember {
                UserProfileModal(profile: member.profile, viewingUserId: profile.userId)
            }
        }
        .task { await loadMemberLocations() }
        .task { subscribeToRealtimeLocations() }
        .task {
            // Auto-start location sharing as soon as the map opens
            locationWrapper.requestAuthorization()
            locationWrapper.startUpdating()
            startLocationUpdates()
        }
        .onDisappear {
            locationTimer?.invalidate()
            locationRefreshTimer?.invalidate()
        }
        .alert("Demande de l'aide ?", isPresented: $showSOSConfirm) {
            Button("Envoyer SOS", role: .destructive) {
                sendSOSNotification()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Une notification SOS sera envoyée aux membres de la soirée.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerPartySOS)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSOSConfirm = true
            }
        }
    }

    // MARK: - Bottom Sheet

    private var mapBottomSheet: some View {
        VStack(spacing: 14) {
            // Sharing toggle
            HStack(spacing: 12) {
                Image(systemName: isSharing ? "location.fill" : "location.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSharing ? Color.appSuccess : Color.appTextSecondary)
                    .frame(width: 28, height: 28)
                    .background((isSharing ? Color.appSuccess : Color.appTextSecondary).opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Partager ma position")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(isSharing ? "Visible par tes amis de soirée" : "Ta position est privée")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Toggle("", isOn: $isSharing)
                    .tint(Color.appSuccess)
                    .onChange(of: isSharing) { _, newVal in
                        if newVal {
                            locationWrapper.requestAuthorization()
                            locationWrapper.startUpdating()
                            startLocationUpdates()
                        } else {
                            stopLocationUpdates()
                        }
                    }
            }
            .padding(14)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                isSharing ? Color.appSuccess.opacity(0.3) : Color.white.opacity(0.08),
                lineWidth: 1
            ))

            // SOS button
            Button {
                showSOSConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("SOS — Demander de l'aide")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appDanger)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .padding(.bottom, 8)
        .background(
            Color.appBackground.opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    // MARK: - Location Logic

    private func startLocationUpdates() {
        // Guard against double-start (e.g. auto-start + toggle)
        guard locationTimer == nil else { return }

        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isPulsingOwn = true
        }
        // Upload own position every 30 seconds
        locationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { await uploadCurrentLocation() }
        }
        // First upload immediately
        Task { await uploadCurrentLocation() }
    }

    private func stopLocationUpdates() {
        locationTimer?.invalidate()
        locationTimer = nil
        isPulsingOwn = false
        locationWrapper.stopUpdating()
        Task {
            do {
                try await supabase
                    .from("member_locations")
                    .delete()
                    .eq("user_id", value: profile.userId.uuidString)
                    .eq("party_id", value: partyId.uuidString)
                    .execute()
                await MainActor.run {
                    memberLocations.removeAll { $0.userId == profile.userId }
                }
            } catch {}
        }
    }

    private func uploadCurrentLocation() async {
        guard let loc = locationWrapper.lastLocation else { return }
        do {
            let upsert = MemberLocationUpsert(
                userId: profile.userId,
                partyId: partyId,
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
            try await supabase
                .from("member_locations")
                .upsert(upsert)
                .execute()
        } catch {}
    }

    private func loadMemberLocations() async {
        do {
            let locations: [MemberLocation] = try await supabase
                .from("member_locations")
                .select()
                .eq("party_id", value: partyId.uuidString)
                .execute()
                .value
            await MainActor.run {
                // If the current user has stopped sharing, exclude their own entry
                // regardless of what the DB returns (handles propagation delay)
                let filtered = isSharing
                    ? locations
                    : locations.filter { $0.userId != profile.userId }
                self.memberLocations = filtered
            }
        } catch {}
    }

    private func subscribeToRealtimeLocations() {
        locationRefreshTimer?.invalidate()
        locationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task { await loadMemberLocations() }
        }
    }

    private func sendSOSNotification() {
        // ── Push notification to all party members ────────────────────────
        let content = UNMutableNotificationContent()
        content.title = "SOS — Aide demandée"
        content.body = "\(profile.pseudo) a besoin d'aide !"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        // ── Local alarm on the sender's phone (~3 seconds) ────────────────
        playSOSAlarm()
    }

    /// Plays 5 rapid beeps + vibrations over ≈3 seconds, then a voice
    /// says "SOS reçu !" so the sender gets clear audio confirmation.
    private func playSOSAlarm() {
        // Force audio playback even if the phone is on silent —
        // essential for an SOS alert.
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            options: [.duckOthers, .mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        Task {
            for i in 0..<5 {
                AudioServicesPlayAlertSound(1005)          // sharp beep
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

                // After the 2nd beep, launch the voice concurrently
                // so it overlaps the remaining beeps naturally
                if i == 1 {
                    let utterance = AVSpeechUtterance(string: "S.O.S. reçu !")
                    utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
                    utterance.rate          = 0.42   // slightly slower = clearer
                    utterance.volume        = 1.0
                    utterance.pitchMultiplier = 1.15  // slightly higher pitch = alert feel
                    utterance.preUtteranceDelay = 0.05
                    speechSynthesizer.speak(utterance)
                }

                if i < 4 {
                    try? await Task.sleep(nanoseconds: 650_000_000) // 0.65 s
                }
            }
        }
    }
}

// MARK: - Map Member Pin

struct MapMemberPin: View {
    let member: PartyMemberWithProfile
    let isCurrentUser: Bool
    let isSharing: Bool
    let isPulsing: Bool
    var isSelected: Bool = false

    private var bacColor: Color {
        Color(hex: BACCalculator.level(for: member.currentBac).colorHex)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Pulsing ring for current sharing user
                    if isSharing {
                        Circle()
                            .stroke(Color.appSuccess.opacity(isPulsing ? 0.6 : 0.2), lineWidth: 3)
                            .frame(width: 52, height: 52)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                    }

                    // Border ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isCurrentUser
                                    ? [Color.appAccentPurple, Color.appAccentBlue]
                                    : [Color(hex: "#7c3aed"), Color(hex: "#2563eb")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                        )

                    AvatarView(
                        avatarUrl: member.profile.avatarUrl,
                        pseudo: member.profile.pseudo,
                        size: 40
                    )
                }

                // BAC badge
                if member.currentBac > 0 {
                    Text(String(format: "%.2f", member.currentBac))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(bacColor)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }

            Text(member.profile.pseudo)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Selected Member Card

struct SelectedMemberCard: View {
    let member: PartyMemberWithProfile
    let location: MemberLocation
    let currentUserId: UUID
    let onViewProfile: () -> Void
    let onDismiss: () -> Void

    private var bacColor: Color {
        Color(hex: BACCalculator.level(for: member.currentBac).colorHex)
    }

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(
                avatarUrl: member.profile.avatarUrl,
                pseudo: member.profile.pseudo,
                size: 50,
                frameId: member.profile.avatarFrame
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.profile.pseudo)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    if member.profile.userId == currentUserId {
                        Text("Moi")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.appAccentPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccentPurple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                if member.currentBac > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(bacColor)
                        Text(String(format: "%.3f g/L", member.currentBac))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(bacColor)
                    }
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 8) {
                Button(action: onViewProfile) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.appAccentPurple)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    openInGoogleMaps(lat: location.latitude, lng: location.longitude, name: member.profile.pseudo)
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.appSuccess)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.appCard
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    private func openInGoogleMaps(lat: Double, lng: Double, name: String) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        // Try Google Maps app first
        if let appURL = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking&q=\(encodedName)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        }
        // Fallback: Apple Maps (always available)
        else if let appleURL = URL(string: "maps://?daddr=\(lat),\(lng)&dirflg=w") {
            UIApplication.shared.open(appleURL)
        }
        // Final fallback: Google Maps web
        else if let webURL = URL(string: "https://maps.google.com/?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - Private Models

private struct MemberLocationUpsert: Codable {
    let userId: UUID
    let partyId: UUID
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case partyId = "party_id"
        case latitude
        case longitude
    }
}
