import SwiftUI

extension Notification.Name {
    static let navigateToProfileTab = Notification.Name("navigateToProfileTab")
    static let navigateToPartyTab   = Notification.Name("navigateToPartyTab")
    static let triggerPartySOS      = Notification.Name("triggerPartySOS")
}

struct EmergencyActionsView: View {
    let profile: Profile?
    @State private var showingCallAlert = false
    @State private var showingSOSSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)

            HStack(spacing: 12) {
                EmergencyButton(
                    icon: "phone.fill",
                    label: "Call Contact",
                    color: Color.appSuccess
                ) {
                    if let contact = profile?.emergencyContact, !contact.isEmpty {
                        showingCallAlert = true
                    } else {
                        showingSOSSheet = true
                    }
                }

                EmergencyButton(
                    icon: "car.fill",
                    label: "Get a Ride",
                    color: Color.appAccentBlue
                ) {
                    if let url = URL(string: "uber://") {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else if let uberURL = URL(string: "https://m.uber.com") {
                            UIApplication.shared.open(uberURL)
                        }
                    }
                }

                EmergencyButton(
                    icon: "cross.fill",
                    label: "First Aid",
                    color: Color.appDanger
                ) {
                    if let url = URL(string: "tel://112") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding(.horizontal)
        }
        .alert("Call Emergency Contact", isPresented: $showingCallAlert) {
            Button("Call \(profile?.emergencyContact ?? "")") {
                let number = (profile?.emergencyContact ?? "").filter("0123456789+".contains)
                if let url = URL(string: "tel://\(number)") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to call \(profile?.emergencyContact ?? "your emergency contact")?")
        }
        .sheet(isPresented: $showingSOSSheet) {
            NoContactSetupSheet()
        }
    }
}

struct EmergencyButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(Circle())
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()
        }
    }
}

struct NoContactSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.appWarning)
                        .padding(.top, 40)

                    Text("Aucun contact d'urgence")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Configure un contact d'urgence dans ton profil. En cas de problème, on pourra appeler quelqu'un pour toi.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Aller dans Profil") {
                        NotificationCenter.default.post(name: .navigateToProfileTab, object: nil)
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .primaryButton()
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
