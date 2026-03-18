import SwiftUI

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared

    func loadLeaderboard() async {
        guard let user = authService.appUser else { return }
        isLoading = true
        do {
            entries = try await firestoreService.fetchLeaderboard(
                friendIds: user.friendIds,
                currentUserId: user.uid
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
