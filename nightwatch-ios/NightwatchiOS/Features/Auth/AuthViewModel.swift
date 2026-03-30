import Foundation
import Supabase
import Observation

@Observable
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var currentProfile: Profile?
    var needsProfileSetup = false

    // Sign up fields
    var signUpEmail = ""
    var signUpPassword = ""
    var signUpPasswordConfirm = ""
    var signUpPseudo = ""
    var signUpGender = "male"
    var signUpWeight: Double = 70
    var signUpHeight: Double = 175
    var signUpAge: Int = 18

    // Sign in fields
    var signInEmail = ""
    var signInPassword = ""

    // Onboarding step
    var onboardingStep = 0

    init() {
        Task {
            await checkSession()
        }
    }

    @MainActor
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            if session.user.id != UUID() {
                isAuthenticated = true
                await loadCurrentProfile(userId: session.user.id)
            }
        } catch {
            isAuthenticated = false
        }
    }

    @MainActor
    func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signIn(
                email: signInEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                password: signInPassword
            )
            isAuthenticated = true
            await loadCurrentProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            let cleanEmail = signUpEmail.trimmingCharacters(in: .whitespacesAndNewlines)

            // 1. Créer le compte auth
            let authResponse = try await supabase.auth.signUp(
                email: cleanEmail,
                password: signUpPassword
            )
            let user = authResponse.user

            // 2. Activer la session si disponible (email confirmation désactivé)
            if let session = authResponse.session {
                try await supabase.auth.setSession(
                    accessToken: session.accessToken,
                    refreshToken: session.refreshToken
                )
                // 3. Insérer le profil avec session active
                try await insertProfile(userId: user.id)
                isAuthenticated = true
                await loadCurrentProfile(userId: user.id)
            } else {
                // Email confirmation activée → indiquer à l'utilisateur de vérifier sa boîte mail
                errorMessage = "Un email de confirmation a été envoyé. Confirme ton adresse puis connecte-toi."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func insertProfile(userId: UUID) async throws {
        let newProfile = ProfileInsert(
            userId: userId,
            pseudo: signUpPseudo.trimmingCharacters(in: .whitespaces),
            gender: signUpGender,
            weight: signUpWeight,
            height: signUpHeight,
            age: signUpAge
        )
        try await supabase
            .from("profiles")
            .insert(newProfile)
            .execute()
    }

    @MainActor
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func loadCurrentProfile(userId: UUID) async {
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentProfile = profile
        } catch {
            // Profile doesn't exist yet, needs setup
            needsProfileSetup = true
        }
    }

    @MainActor
    func resetPassword() async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.resetPasswordForEmail(signInEmail)
            errorMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// Codable struct for inserting profile
private struct ProfileInsert: Codable {
    let userId: UUID
    let pseudo: String
    let gender: String
    let weight: Double
    let height: Double
    let age: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pseudo
        case gender
        case weight
        case height
        case age
    }
}
