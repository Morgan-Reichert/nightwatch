import Foundation
import Observation
import PhotosUI
import SwiftUI

@Observable
class SettingsViewModel {
    var profile: Profile?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var isSaving = false

    // Editable fields
    var pseudo = ""
    var bio = ""
    var gender = "male"
    var weight: Double = 70
    var height: Double = 175
    var age: Int = 21
    var emergencyContact = ""
    var phone = ""
    var city = ""
    var school = ""
    var job = ""
    var zodiac = ""
    var musicTaste = ""
    var partyStyle = ""
    var snapchat = ""
    var instagram = ""
    var tiktok = ""
    var customCards: [CustomCard] = []

    @MainActor
    func load(profile: Profile) {
        self.profile = profile
        populateFields(from: profile)
    }

    private func populateFields(from profile: Profile) {
        pseudo = profile.pseudo
        bio = profile.bio ?? ""
        gender = profile.gender
        weight = profile.weight
        height = profile.height
        age = profile.age
        emergencyContact = profile.emergencyContact ?? ""
        phone = profile.phone ?? ""
        city = profile.city ?? ""
        school = profile.school ?? ""
        job = profile.job ?? ""
        zodiac = profile.zodiac ?? ""
        musicTaste = profile.musicTaste ?? ""
        partyStyle = profile.partyStyle ?? ""
        snapchat = profile.snapchat ?? ""
        instagram = profile.instagram ?? ""
        tiktok = profile.tiktok ?? ""
        customCards = profile.customCards ?? []
    }

    @MainActor
    func saveProfile() async {
        guard let profile else { return }
        isSaving = true
        errorMessage = nil

        let updates = ProfileUpdate(
            pseudo: pseudo,
            bio: bio.isEmpty ? nil : bio,
            gender: gender,
            weight: weight,
            height: height,
            age: age,
            emergencyContact: emergencyContact.isEmpty ? nil : emergencyContact,
            phone: phone.isEmpty ? nil : phone,
            city: city.isEmpty ? nil : city,
            school: school.isEmpty ? nil : school,
            job: job.isEmpty ? nil : job,
            zodiac: zodiac.isEmpty ? nil : zodiac,
            musicTaste: musicTaste.isEmpty ? nil : musicTaste,
            partyStyle: partyStyle.isEmpty ? nil : partyStyle,
            snapchat: snapchat.isEmpty ? nil : snapchat,
            instagram: instagram.isEmpty ? nil : instagram,
            tiktok: tiktok.isEmpty ? nil : tiktok,
            customCards: customCards.isEmpty ? nil : customCards
        )

        do {
            try await supabase
                .from("profiles")
                .update(updates)
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
            successMessage = "Profile saved!"
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    @MainActor
    func uploadAvatar(imageData: Data) async {
        guard let profile else { return }
        isLoading = true
        do {
            let fileName = "\(profile.userId.uuidString)/avatar.jpg"
            try await supabase.storage
                .from("avatars")
                .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

            let url = try supabase.storage
                .from("avatars")
                .getPublicURL(path: fileName)

            try await supabase
                .from("profiles")
                .update(["avatar_url": url.absoluteString])
                .eq("user_id", value: profile.userId.uuidString)
                .execute()

            successMessage = "Avatar updated!"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct ProfileUpdate: Codable {
    let pseudo: String
    let bio: String?
    let gender: String
    let weight: Double
    let height: Double
    let age: Int
    let emergencyContact: String?
    let phone: String?
    let city: String?
    let school: String?
    let job: String?
    let zodiac: String?
    let musicTaste: String?
    let partyStyle: String?
    let snapchat: String?
    let instagram: String?
    let tiktok: String?
    let customCards: [CustomCard]?

    enum CodingKeys: String, CodingKey {
        case pseudo
        case bio
        case gender
        case weight
        case height
        case age
        case emergencyContact = "emergency_contact"
        case phone
        case city
        case school
        case job
        case zodiac
        case musicTaste = "music_taste"
        case partyStyle = "party_style"
        case snapchat
        case instagram
        case tiktok
        case customCards = "custom_cards"
    }
}
