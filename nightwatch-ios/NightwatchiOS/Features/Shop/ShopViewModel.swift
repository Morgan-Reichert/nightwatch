import Foundation
import Observation

@Observable
class ShopViewModel {
    var profile: Profile?
    var purchasedItemIds: Set<String> = []
    var isLoading = false
    var errorMessage: String?
    var purchaseMessage: String?

    @MainActor
    func load(profile: Profile) async {
        self.profile = profile
        await loadPurchases()
    }

    @MainActor
    func loadPurchases() async {
        guard let profile else { return }
        do {
            let purchases: [UserPurchase] = try await supabase
                .from("user_purchases")
                .select()
                .eq("user_id", value: profile.userId.uuidString)
                .execute()
                .value
            purchasedItemIds = Set(purchases.map { $0.itemId })
        } catch {
            // Silently handle
        }
    }

    func hasPurchased(_ itemId: String) -> Bool {
        purchasedItemIds.contains(itemId)
    }

    @MainActor
    func initiatePurchase(item: ShopItem) async {
        guard let profile else { return }

        if item.type == .streakRestore {
            await handleStreakRestore()
            return
        }

        isLoading = true
        errorMessage = nil

        // In a real app, this would:
        // 1. Create a Stripe checkout session via your backend
        // 2. Open a SafariViewController/ASWebAuthenticationSession with the Stripe URL
        // 3. Handle the redirect callback to confirm the purchase

        // For now, we simulate a direct purchase record
        // (In production, only a server-side webhook should write to user_purchases)
        do {
            let purchase = UserPurchaseInsert(
                userId: profile.userId,
                itemId: item.id
            )
            try await supabase
                .from("user_purchases")
                .insert(purchase)
                .execute()

            // Apply the purchased item to profile
            await applyPurchasedItem(item)

            purchasedItemIds.insert(item.id)
            purchaseMessage = "Successfully purchased \(item.name)!"
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    private func applyPurchasedItem(_ item: ShopItem) async {
        guard var profile = profile else { return }
        do {
            switch item.type {
            case .avatarFrame:
                try await supabase
                    .from("profiles")
                    .update(["avatar_frame": item.id])
                    .eq("user_id", value: profile.userId.uuidString)
                    .execute()
                profile.avatarFrame = item.id
            case .bannerGradient:
                try await supabase
                    .from("profiles")
                    .update(["banner_gradient": item.id])
                    .eq("user_id", value: profile.userId.uuidString)
                    .execute()
                profile.bannerGradient = item.id
            case .streakRestore:
                break
            }
            self.profile = profile
        } catch {}
    }

    @MainActor
    func equip(item: ShopItem) async {
        guard hasPurchased(item.id) else { return }
        await applyPurchasedItem(item)
    }

    @MainActor
    private func handleStreakRestore() async {
        isLoading = true
        // In a real app this would verify payment then reset streak
        purchaseMessage = "Streak restored! Keep it up!"
        isLoading = false
    }
}

private struct UserPurchaseInsert: Codable {
    let userId: UUID
    let itemId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case itemId = "item_id"
    }
}
