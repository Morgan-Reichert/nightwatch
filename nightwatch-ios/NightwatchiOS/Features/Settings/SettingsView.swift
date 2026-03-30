import SwiftUI
import PhotosUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    let profile: Profile
    let onSignOut: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingBadges = false
    @State private var showSignOutAlert = false
    @State private var showAddCard = false
    @State private var newCardTitle = ""
    @State private var newCardValue = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Profile header
                        SettingsProfileHeader(
                            viewModel: viewModel,
                            profile: profile,
                            selectedPhotoItem: $selectedPhotoItem
                        )

                        VStack(spacing: 20) {
                            // Boutique
                            NavigationLink {
                                ShopView(profile: profile)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "bag.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.appAccentPurple)
                                        .frame(width: 30, height: 30)
                                        .background(Color.appAccentPurple.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text("Boutique")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.appCard.opacity(0.8))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
                                )
                            }
                            .padding(.horizontal, 16)

                            // Informations physiques
                            SettingsSection(title: "Informations physiques", icon: "figure.stand") {
                                SettingsField(label: "Genre", icon: "person.fill") {
                                    AnyView(GenderSegmentPicker(gender: $viewModel.gender))
                                }
                                SettingsSliderField(
                                    label: "Poids",
                                    icon: "scalemass.fill",
                                    value: $viewModel.weight,
                                    range: 40...150,
                                    unit: "kg"
                                )
                                SettingsSliderField(
                                    label: "Taille",
                                    icon: "ruler.fill",
                                    value: $viewModel.height,
                                    range: 140...220,
                                    unit: "cm"
                                )
                                SettingsStepperField(
                                    label: "Âge",
                                    icon: "calendar",
                                    value: $viewModel.age,
                                    range: 18...99
                                )
                            }

                            // Réseaux sociaux
                            SettingsSection(title: "Réseaux sociaux", icon: "person.2.wave.2.fill") {
                                SettingsInputField(label: "Snapchat", icon: "camera.fill", text: $viewModel.snapchat, placeholder: "@ton_snap", color: Color(hex: "#FFFC00"))
                                SettingsInputField(label: "Instagram", icon: "photo.fill", text: $viewModel.instagram, placeholder: "@ton_insta", color: Color(hex: "#E1306C"))
                                SettingsInputField(label: "TikTok", icon: "music.note", text: $viewModel.tiktok, placeholder: "@ton_tiktok", color: Color(hex: "#ff0050"))
                            }

                            // À propos
                            SettingsSection(title: "À propos de toi", icon: "person.text.rectangle.fill") {
                                SettingsInputField(label: "Pseudo", icon: "at", text: $viewModel.pseudo, placeholder: "Ton pseudo")
                                SettingsInputField(label: "Ville", icon: "location.fill", text: $viewModel.city, placeholder: "Paris")
                                SettingsInputField(label: "École / Université", icon: "building.columns.fill", text: $viewModel.school, placeholder: "Ton école")
                                SettingsInputField(label: "Travail", icon: "briefcase.fill", text: $viewModel.job, placeholder: "Ton job")
                                SettingsInputField(label: "Signe astrologique", icon: "star.fill", text: $viewModel.zodiac, placeholder: "Capricorne")
                                SettingsInputField(label: "Style musical", icon: "music.note.list", text: $viewModel.musicTaste, placeholder: "Hip-hop, Techno...")
                                SettingsInputField(label: "Style de soirée", icon: "party.popper.fill", text: $viewModel.partyStyle, placeholder: "Rave, Club, Apéro...")
                                SettingsBioField(bio: $viewModel.bio)
                            }

                            // Contact d'urgence
                            SettingsSection(title: "Contact d'urgence", icon: "cross.circle.fill") {
                                SettingsInputField(label: "Numéro d'urgence", icon: "phone.fill", text: $viewModel.emergencyContact, placeholder: "+33 6 00 00 00 00", keyboard: .phonePad, color: Color.appDanger)
                                SettingsInputField(label: "Votre téléphone", icon: "iphone", text: $viewModel.phone, placeholder: "+33 6 00 00 00 00", keyboard: .phonePad)
                            }

                            // Cartes personnalisées
                            SettingsSection(title: "Cartes personnalisées", icon: "rectangle.stack.fill") {
                                ForEach(viewModel.customCards.indices, id: \.self) { idx in
                                    CustomCardRow(
                                        title: viewModel.customCards[idx].title,
                                        value: viewModel.customCards[idx].value,
                                        onDelete: {
                                            viewModel.customCards.remove(at: idx)
                                        }
                                    )
                                }

                                Button {
                                    showAddCard = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.appAccentPurple)
                                        Text("Ajouter une carte")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.appAccentPurple)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                }
                            }

                            // Mes badges
                            Button {
                                showingBadges = true
                            } label: {
                                SettingsNavRow(icon: "medal.fill", label: "Mes badges", iconColor: Color.appWarning)
                            }
                            .padding(.horizontal, 16)

                            // Sécurité
                            SettingsSection(title: "Sécurité", icon: "shield.fill") {
                                Button {
                                    // Password change logic
                                } label: {
                                    SettingsNavRow(icon: "lock.fill", label: "Changer le mot de passe", iconColor: Color.appAccentBlue)
                                }
                            }

                            // Save button
                            Button {
                                Task { await viewModel.saveProfile() }
                            } label: {
                                HStack(spacing: 8) {
                                    if viewModel.isSaving {
                                        ProgressView().tint(.white).scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    Text(viewModel.isSaving ? "Sauvegarde..." : "Sauvegarder le profil")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(viewModel.isSaving)
                            .padding(.horizontal, 16)

                            // Déconnexion
                            Button {
                                showSignOutAlert = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Déconnexion")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(Color.appDanger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appDanger.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                            }
                            .padding(.horizontal, 16)

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView().tint(Color.appAccentPurple).scaleEffect(0.8)
                    } else {
                        Button("Sauv.") {
                            Task { await viewModel.saveProfile() }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appAccentPurple)
                    }
                }
            }
        }
        .onAppear {
            viewModel.load(profile: profile)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                await viewModel.uploadAvatar(imageData: data)
            }
        }
        .alert("Profil sauvegardé", isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Déconnexion ?", isPresented: $showSignOutAlert) {
            Button("Se déconnecter", role: .destructive) { onSignOut() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous serez redirigé vers l'écran de connexion.")
        }
        .sheet(isPresented: $showingBadges) {
            BadgesDetailView(profile: profile)
        }
        .sheet(isPresented: $showAddCard) {
            AddCustomCardSheet(
                title: $newCardTitle,
                value: $newCardValue
            ) {
                if !newCardTitle.isEmpty && !newCardValue.isEmpty {
                    viewModel.customCards.append(CustomCard(
                        id: UUID().uuidString,
                        title: newCardTitle,
                        value: newCardValue
                    ))
                    newCardTitle = ""
                    newCardValue = ""
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Profile Header
struct SettingsProfileHeader: View {
    let viewModel: SettingsViewModel
    let profile: Profile
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarUrl: profile.avatarUrl,
                    pseudo: profile.pseudo,
                    size: 96,
                    frameId: profile.avatarFrame
                )

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(
                            LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                }
            }

            VStack(spacing: 4) {
                Text(viewModel.pseudo.isEmpty ? profile.pseudo : viewModel.pseudo)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                if !viewModel.city.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextSecondary)
                        Text(viewModel.city)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.appAccentPurple)
                    .scaleEffect(0.9)
            }
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.appAccentPurple.opacity(0.12), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Section Container
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appAccentPurple)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Settings Field wrapper
struct SettingsField<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.leading, 50)
        }
    }
}

// MARK: - Settings Input Field
struct SettingsInputField: View {
    let label: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    var keyboard: UIKeyboardType = .default
    var color: Color = Color.appAccentPurple

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.leading, 50)
        }
    }
}

// MARK: - Bio field
struct SettingsBioField: View {
    @Binding var bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "text.quote")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 22)
                Text("Bio")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
            TextField("Parle-toi en quelques mots...", text: $bio, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(3...6)
                .padding(.leading, 34)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Slider Field
struct SettingsSliderField: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Slider(value: $value, in: range, step: 1)
                .tint(Color.appAccentPurple)
                .padding(.leading, 34)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.leading, 50)
        }
    }
}

// MARK: - Stepper Field
struct SettingsStepperField: View {
    let label: String
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 30)
                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appAccentPurple)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Gender Picker
struct GenderSegmentPicker: View {
    @Binding var gender: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach([("male", "Homme"), ("female", "Femme")], id: \.0) { value, label in
                Button {
                    gender = value
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(gender == value ? .white : Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(gender == value ? Color.appAccentPurple : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(3)
        .background(Color.appBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

// MARK: - Custom Card Row
struct CustomCardRow: View {
    let title: String
    let value: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.appAccentPurple.opacity(0.7))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appDanger.opacity(0.7))
                    .padding(7)
                    .background(Color.appDanger.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5).padding(.leading, 50)
        }
    }
}

// MARK: - Settings Navigation Row
struct SettingsNavRow: View {
    let icon: String
    let label: String
    var iconColor: Color = Color.appAccentPurple

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 30, height: 30)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCard.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
        )
    }
}

// MARK: - Add Custom Card Sheet
struct AddCustomCardSheet: View {
    @Binding var title: String
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .padding(.top, 32)

                        Text("Nouvelle carte")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 12) {
                        SettingsInputField(label: "Titre", icon: "tag.fill", text: $title, placeholder: "Ex: Film préféré")
                        SettingsInputField(label: "Valeur", icon: "text.alignleft", text: $value, placeholder: "Ex: Interstellar")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCard.opacity(0.8))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1))
                    )
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button("Annuler") { dismiss() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 13))

                        Button {
                            onSave()
                            dismiss()
                        } label: {
                            Text("Ajouter")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        }
                        .disabled(title.isEmpty || value.isEmpty)
                        .opacity(title.isEmpty || value.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Badges Detail View
struct BadgesDetailView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @State private var userStats: UserStats?
    @State private var earnedBadges: [EarnedBadge] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView().tint(Color.appAccentPurple).scaleEffect(1.2)
                        Text("Chargement des badges...").font(.subheadline).foregroundStyle(Color.appTextSecondary)
                    }
                } else if let stats = userStats {
                    BadgesSectionView(earnedBadges: earnedBadges, stats: stats)
                }
            }
            .navigationTitle("Mes badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .task { await loadStats() }
        .preferredColorScheme(.dark)
    }

    private func loadStats() async {
        do {
            let drinks: [Drink] = try await supabase
                .from("drinks")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            let parties: [PartyMember] = try await supabase
                .from("party_members")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            let pukes: [PukeEvent] = try await supabase
                .from("puke_events")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            let shopEvents: [ShopEvent] = try await supabase
                .from("shop_events")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value

            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(profile.userId.uuidString),addressee_id.eq.\(profile.userId.uuidString)")
                .eq("status", value: "accepted")
                .execute()
                .value

            let stats = UserStats(
                totalDrinks: drinks.filter { $0.abv > 0 }.count,
                totalParties: parties.count,
                totalPukes: pukes.count,
                totalKisses: shopEvents.count,
                totalFriends: friendships.count
            )

            await MainActor.run {
                self.userStats = stats
                self.earnedBadges = BadgeService.computeEarnedBadges(stats: stats)
                self.isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}
