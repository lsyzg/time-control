import SwiftUI
import FirebaseFirestore

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [AppUser] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var screenTimeRequests: [ScreenTimeRequest] = []
    @Published var searchResults: [AppUser] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    private var listenerRegistration: ListenerRegistration?

    func loadFriends() async {
        guard let user = authService.appUser else { return }
        isLoading = true
        do {
            friends = try await firestoreService.fetchUsers(byIds: user.friendIds)
            pendingRequests = try await firestoreService.fetchPendingFriendRequests(forUserId: user.uid)
            screenTimeRequests = try await firestoreService.fetchPendingScreenTimeRequests(forUserId: user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func searchUsers() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else { searchResults = []; return }
        isLoading = true
        do {
            if let user = try await firestoreService.searchUser(byUsername: query) {
                let currentUid = authService.appUser?.uid ?? ""
                searchResults = user.uid == currentUid ? [] : [user]
            } else {
                searchResults = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func sendFriendRequest(to user: AppUser) async {
        guard let current = authService.appUser else { return }
        do {
            try await firestoreService.sendFriendRequest(from: current, to: user)
            successMessage = "Friend request sent to \(user.atUsername)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await firestoreService.respondToFriendRequest(request, accept: true)
            pendingRequests.removeAll { $0.id == request.id }
            await loadFriends()
            successMessage = "You and \(request.fromDisplayName) are now friends!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineRequest(_ request: FriendRequest) async {
        do {
            try await firestoreService.respondToFriendRequest(request, accept: false)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: AppUser) async {
        guard let current = authService.appUser else { return }
        do {
            try await firestoreService.removeFriend(currentUserId: current.uid, friendId: friend.uid)
            friends.removeAll { $0.uid == friend.uid }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestScreenTime(from friend: AppUser) async {
        guard let current = authService.appUser else { return }
        do {
            try await firestoreService.sendScreenTimeRequest(from: current, to: friend)
            successMessage = "Screen time request sent to \(friend.atUsername)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fulfillScreenTimeRequest(_ request: ScreenTimeRequest) async {
        let minutes = ScreenTimeService.shared.fetchTodayScreenTimeMinutes()
        do {
            try await firestoreService.fulfillScreenTimeRequest(request, screenTimeMinutes: minutes)
            screenTimeRequests.removeAll { $0.id == request.id }
            successMessage = "Screen time shared!"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isFriend(_ user: AppUser) -> Bool {
        authService.appUser?.friendIds.contains(user.uid) ?? false
    }

    func hasPendingRequest(to user: AppUser) -> Bool {
        // simplified check – would need a Firestore query for full accuracy
        false
    }
}
