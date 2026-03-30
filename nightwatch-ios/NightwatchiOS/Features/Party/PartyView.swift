import SwiftUI
import PhotosUI

struct PartyView: View {
    @State private var viewModel = PartyViewModel()
    let profile: Profile

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                if viewModel.isLoading && viewModel.currentParty == nil {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color.appAccentPurple)
                            .scaleEffect(1.3)
                        Text("Chargement...")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                } else if let party = viewModel.currentParty {
                    ActivePartyView(viewModel: viewModel, party: party, profile: profile)
                } else {
                    NoPartyView(viewModel: viewModel, profile: profile)
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.load(profile: profile)
        }
        .alert("Erreur", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - No Party View
struct NoPartyView: View {
    @Bindable var viewModel: PartyViewModel
    let profile: Profile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text("Soirées")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Créez ou rejoignez une soirée pour tracker ensemble")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal)

                // Main action cards
                HStack(spacing: 14) {
                    PartyActionCard(
                        icon: "party.popper.fill",
                        title: "Créer",
                        subtitle: "Nouvelle soirée",
                        gradient: [Color.appAccentPurple, Color.appAccentBlue]
                    ) {
                        viewModel.showCreateParty = true
                    }

                    PartyActionCard(
                        icon: "person.badge.plus",
                        title: "Rejoindre",
                        subtitle: "Avec un code",
                        gradient: [Color(hex: "#0891b2"), Color(hex: "#0d9488")]
                    ) {
                        viewModel.showJoinParty = true
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
        }
        .sheet(isPresented: $viewModel.showCreateParty) {
            CreatePartySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showJoinParty) {
            JoinPartySheet(viewModel: viewModel)
        }
    }
}

// MARK: - Party Action Card
struct PartyActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: gradient.map { $0.opacity(0.25) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appCard.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(colors: [gradient.first?.opacity(0.4) ?? .clear, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(pressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeIn(duration: 0.08)) { pressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.25)) { pressed = false } }
        )
    }
}

// MARK: - Active Party View
struct ActivePartyView: View {
    @Bindable var viewModel: PartyViewModel
    let party: Party
    let profile: Profile

    @State private var selectedTab = 0
    @State private var showLeaveAlert = false
    @State private var showEndAlert = false
    @State private var showInviteSheet = false

    private let tabs: [(String, String)] = [
        ("Membres", "person.3.fill"),
        ("Photos", "photo.fill"),
        ("Carte", "map.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Party header card
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(party.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            Image(systemName: "number")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.appAccentPurple)
                            Text(party.code)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.appAccentPurple)
                                .kerning(2)
                            Button {
                                UIPasteboard.general.string = party.code
                            } label: {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Button {
                            UIPasteboard.general.string = party.code
                        } label: {
                            Label("Copier le code", systemImage: "doc.on.doc")
                        }
                        Button {
                            showInviteSheet = true
                        } label: {
                            Label("Inviter un ami", systemImage: "person.badge.plus")
                        }
                        Button {
                            Task { await viewModel.logPukeEvent() }
                        } label: {
                            Label("Logger un vomi", systemImage: "cross.circle.fill")
                        }
                        Divider()
                        if party.createdBy == profile.userId {
                            Button(role: .destructive) { showEndAlert = true } label: {
                                Label("Terminer la soirée", systemImage: "xmark.circle.fill")
                            }
                        } else {
                            Button(role: .destructive) { showLeaveAlert = true } label: {
                                Label("Quitter la soirée", systemImage: "door.left.hand.open")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("\(viewModel.members.count) membres")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("\(viewModel.photos.count) photos")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            .background(
                Color.appCard.opacity(0.7)
                    .overlay(
                        LinearGradient(
                            colors: [Color.appAccentPurple.opacity(0.15), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )

            // Tab bar
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let (title, icon) = tabs[index]
                    let isSelected = selectedTab == index

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                Text(title)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            }
                            .foregroundStyle(isSelected ? Color.appAccentPurple : Color.appTextSecondary)

                            Rectangle()
                                .fill(isSelected ? Color.appAccentPurple : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.appCard)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            }

            // Content tabs
            TabView(selection: $selectedTab) {
                PartyMembersTab(members: viewModel.members, profile: profile, party: party, onInvite: { showInviteSheet = true }, viewModel: viewModel)
                    .tag(0)
                PartyPhotosView(partyId: party.id, profile: profile, photos: viewModel.photos)
                    .tag(1)
                MemberMapView(members: viewModel.members, partyId: party.id, profile: profile)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerPartySOS)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 2 }
        }
        .alert("Quitter la soirée ?", isPresented: $showLeaveAlert) {
            Button("Quitter", role: .destructive) { Task { await viewModel.leaveParty() } }
            Button("Annuler", role: .cancel) {}
        }
        .alert("Terminer la soirée ?", isPresented: $showEndAlert) {
            Button("Terminer", role: .destructive) { Task { await viewModel.endParty() } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cela terminera la soirée pour tous les membres.")
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteSheet(partyCode: party.code)
        }
    }
}

// MARK: - Members Tab
struct PartyMembersTab: View {
    let members: [PartyMemberWithProfile]
    let profile: Profile
    let party: Party
    let onInvite: () -> Void
    @Bindable var viewModel: PartyViewModel

    @State private var selectedMemberProfile: Profile? = nil
    @State private var showEndAlert = false
    @State private var showLeaveAlert = false

    private var isCreator: Bool { party.createdBy == profile.userId }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                ForEach(members.sorted { $0.drinkCount > $1.drinkCount }) { member in
                    PartyMemberRow(
                        member: member,
                        isSelf: member.profile.userId == profile.userId
                    )
                    .onTapGesture {
                        selectedMemberProfile = member.profile
                    }
                }

                // Invite button
                Button(action: onInvite) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appAccentPurple)
                        Text("Inviter un ami")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appAccentPurple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appAccentPurple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appAccentPurple.opacity(0.3), lineWidth: 1))
                }
                .padding(.top, 4)

                // Leave / End button — WITH confirmation
                Button {
                    if isCreator {
                        showEndAlert = true
                    } else {
                        showLeaveAlert = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCreator ? "xmark.circle.fill" : "door.left.hand.open")
                            .font(.system(size: 15, weight: .semibold))
                        Text(isCreator ? "Terminer la soirée" : "Quitter la soirée")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.appDanger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appDanger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appDanger.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .sheet(item: $selectedMemberProfile) { memberProfile in
            UserProfileModal(profile: memberProfile, viewingUserId: profile.userId)
        }
        // Confirmation : terminer la soirée (créateur)
        .alert("Terminer la soirée ?", isPresented: $showEndAlert) {
            Button("Terminer pour tout le monde", role: .destructive) {
                Task { await viewModel.endParty() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La soirée sera clôturée pour tous les membres. Cette action est irréversible.")
        }
        // Confirmation : quitter la soirée (membre)
        .alert("Quitter la soirée ?", isPresented: $showLeaveAlert) {
            Button("Quitter", role: .destructive) {
                Task { await viewModel.leaveParty() }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Tu ne pourras plus voir les membres ni les photos de cette soirée.")
        }
    }
}

// MARK: - Member Row
struct PartyMemberRow: View {
    let member: PartyMemberWithProfile
    let isSelf: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarUrl: member.profile.avatarUrl,
                    pseudo: member.profile.pseudo,
                    size: 46,
                    frameId: member.profile.avatarFrame
                )
                if isSelf {
                    Circle()
                        .fill(Color.appSuccess)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.appCard, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.profile.pseudo)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if isSelf {
                        Text("Moi")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.appAccentPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAccentPurple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("\(member.drinkCount) boissons")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            Spacer()

            if member.member.showBac {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.3f", member.currentBac))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: BACCalculator.level(for: member.currentBac).colorHex))
                    Text("g/L")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.appTextSecondary)
                }
            } else {
                Image(systemName: "eye.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.5))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.4))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelf ? Color.appAccentPurple.opacity(0.08) : Color.appCard.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelf ? Color.appAccentPurple.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - Invite Sheet
struct InviteSheet: View {
    let partyCode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.appAccentPurple)
                            .padding(.top, 40)

                        Text("Code de la soirée")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Partagez ce code avec vos amis pour qu'ils rejoignent")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    Text(partyCode)
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .kerning(6)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing),
                                            lineWidth: 2
                                        )
                                )
                        )

                    Button {
                        UIPasteboard.general.string = partyCode
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copier le code")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.horizontal)
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

// MARK: - Create Party Sheet
struct CreatePartySheet: View {
    @Bindable var viewModel: PartyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .padding(.top, 40)

                        Text("Créer une soirée")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Invitez vos amis avec le code généré automatiquement")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appAccentPurple)
                            Text("Nom de la soirée")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        TextField("Ma soirée (optionnel)", text: $viewModel.newPartyName)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    Button {
                        Task { await viewModel.createParty() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.9)
                            } else {
                                Image(systemName: "party.popper.fill")
                            }
                            Text("Créer la soirée")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.appAccentPurple, Color.appAccentBlue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Join Party Sheet
struct JoinPartySheet: View {
    @Bindable var viewModel: PartyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassmorphismBackground()

                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(colors: [Color(hex: "#0891b2"), Color(hex: "#0d9488")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .padding(.top, 40)

                        Text("Rejoindre une soirée")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Entrez le code à 6 caractères de la soirée")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    TextField("CODE", text: $viewModel.partyCode)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .kerning(4)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccentPurple.opacity(0.4), lineWidth: 2)
                        )
                        .padding(.horizontal)
                        .onChange(of: viewModel.partyCode) { _, v in
                            viewModel.partyCode = String(v.uppercased().prefix(6))
                        }

                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(Color.appDanger)
                    }

                    Button {
                        Task { await viewModel.joinParty() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.9)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text("Rejoindre")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color(hex: "#0891b2"), Color(hex: "#0d9488")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(viewModel.partyCode.count < 6 ? 0.5 : 1.0)
                    }
                    .disabled(viewModel.partyCode.count < 6 || viewModel.isLoading)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

