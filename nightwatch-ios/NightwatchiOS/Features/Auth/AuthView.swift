import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @State private var isSignUp = false
    @State private var showingOnboarding = false

    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            GlassmorphismBackground()

            if showingOnboarding {
                OnboardingView(viewModel: vm, onComplete: {
                    showingOnboarding = false
                })
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo / Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.appAccentPurple, Color.appAccentBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                Text("🌙")
                                    .font(.system(size: 40))
                            }
                            Text("Nightwatch")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Social Glow Meter")
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(.top, 60)

                        // Toggle
                        HStack(spacing: 0) {
                            Button {
                                withAnimation { isSignUp = false }
                            } label: {
                                Text("Sign In")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(isSignUp ? Color.appTextSecondary : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSignUp ? Color.clear : Color.appAccentPurple)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            Button {
                                withAnimation { isSignUp = true }
                            } label: {
                                Text("Sign Up")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(isSignUp ? .white : Color.appTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSignUp ? Color.appAccentPurple : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(4)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        if isSignUp {
                            SignUpFormView(viewModel: vm, showingOnboarding: $showingOnboarding)
                        } else {
                            SignInFormView(viewModel: vm)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }

            if viewModel.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sign In

struct SignInFormView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                AppTextField(
                    placeholder: "Email",
                    text: $viewModel.signInEmail,
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                AppTextField(
                    placeholder: "Password",
                    text: $viewModel.signInPassword,
                    icon: "lock",
                    isSecure: true
                )
            }
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.appDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await viewModel.signIn() }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .primaryButton()
            }
            .padding(.horizontal)
            .disabled(viewModel.isLoading)

            Button {
                Task { await viewModel.resetPassword() }
            } label: {
                Text("Forgot password?")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}

// MARK: - Sign Up (email + password uniquement)

struct SignUpFormView: View {
    @Bindable var viewModel: AuthViewModel
    @Binding var showingOnboarding: Bool

    private var passwordsMatch: Bool {
        viewModel.signUpPassword == viewModel.signUpPasswordConfirm
    }

    private var isFormValid: Bool {
        !viewModel.signUpEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.signUpEmail.contains("@") &&
        viewModel.signUpPassword.count >= 6 &&
        passwordsMatch
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                AppTextField(
                    placeholder: "Email",
                    text: $viewModel.signUpEmail,
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                AppTextField(
                    placeholder: "Password (min. 6 caractères)",
                    text: $viewModel.signUpPassword,
                    icon: "lock",
                    isSecure: true
                )
                AppTextField(
                    placeholder: "Confirmer le mot de passe",
                    text: $viewModel.signUpPasswordConfirm,
                    icon: "lock.fill",
                    isSecure: true
                )

                // Indicateur si les mots de passe ne correspondent pas
                if !viewModel.signUpPasswordConfirm.isEmpty && !passwordsMatch {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Les mots de passe ne correspondent pas")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.appDanger)
                    .padding(.horizontal, 4)
                }

                if !viewModel.signUpPasswordConfirm.isEmpty && passwordsMatch && viewModel.signUpPassword.count >= 6 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mots de passe identiques")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.appSuccess)
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.appDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                viewModel.errorMessage = nil
                showingOnboarding = true
            } label: {
                Text("Continuer")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .primaryButton()
            }
            .padding(.horizontal)
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.5)
        }
    }
}

// MARK: - Onboarding (pseudo + infos profil)

struct OnboardingView: View {
    @Bindable var viewModel: AuthViewModel
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Complète ton profil")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Ces infos servent à calculer ton taux d'alcool avec précision")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 20) {
                    // Pseudo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pseudo")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                        AppTextField(
                            placeholder: "Ton pseudo unique",
                            text: $viewModel.signUpPseudo,
                            icon: "at"
                        )
                    }

                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genre")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                        HStack(spacing: 12) {
                            ForEach(["male", "female"], id: \.self) { gender in
                                Button {
                                    viewModel.signUpGender = gender
                                } label: {
                                    Text(gender == "male" ? "♂ Homme" : "♀ Femme")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(viewModel.signUpGender == gender ? Color.appAccentPurple : Color.appCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    viewModel.signUpGender == gender ? Color.appAccentPurple : Color.appBorder,
                                                    lineWidth: 1
                                                )
                                        )
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }

                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Poids : \(Int(viewModel.signUpWeight)) kg")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                        Slider(value: $viewModel.signUpWeight, in: 40...150, step: 1)
                            .tint(Color.appAccentPurple)
                    }

                    // Height
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taille : \(Int(viewModel.signUpHeight)) cm")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                        Slider(value: $viewModel.signUpHeight, in: 140...220, step: 1)
                            .tint(Color.appAccentPurple)
                    }

                    // Age
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Âge")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                        Stepper(value: $viewModel.signUpAge, in: 16...99) {
                            Text("\(viewModel.signUpAge) ans")
                                .foregroundStyle(.white)
                        }
                        .padding(12)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.appDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        await viewModel.signUp()
                        if viewModel.isAuthenticated {
                            onComplete()
                        }
                    }
                } label: {
                    Text("Créer mon compte")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .primaryButton()
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading || viewModel.signUpPseudo.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(viewModel.signUpPseudo.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                Button {
                    onComplete()
                } label: {
                    Text("Retour")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - AppTextField

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
