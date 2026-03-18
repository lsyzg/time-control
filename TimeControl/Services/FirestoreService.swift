import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: – User Search

    func searchUser(byUsername username: String) async throws -> AppUser? {
        let clean = username.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: clean)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: AppUser.self) }
    }

    func fetchUsers(byIds ids: [String]) async throws -> [AppUser] {
        guard !ids.isEmpty else { return [] }
        // Firestore "in" query supports up to 30 items
        let chunks = ids.chunked(into: 30)
        var results: [AppUser] = []
        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField("uid", in: chunk)
                .getDocuments()
            let users = try snapshot.documents.compactMap { try $0.data(as: AppUser.self) }
            results.append(contentsOf: users)
        }
        return results
    }

    // MARK: – Friend Requests

    func sendFriendRequest(from fromUser: AppUser, to toUser: AppUser) async throws {
        // Check not already friends or pending
        if fromUser.friendIds.contains(toUser.uid) { return }

        let request = FriendRequest(
            fromUserId: fromUser.uid,
            fromUsername: fromUser.username,
            fromDisplayName: fromUser.displayName,
            toUserId: toUser.uid,
            status: .pending,
            sentAt: Date()
        )
        let ref = db.collection("friendRequests").document()
        try ref.setData(from: request)

        // Add to toUser's pendingFriendIds
        try await db.collection("users").document(toUser.uid).updateData([
            "pendingFriendIds": FieldValue.arrayUnion([fromUser.uid])
        ])
    }

    func respondToFriendRequest(_ request: FriendRequest, accept: Bool) async throws {
        guard let reqId = request.id else { return }
        let status: FriendRequestStatus = accept ? .accepted : .declined
        try await db.collection("friendRequests").document(reqId).updateData(["status": status.rawValue])

        if accept {
            // Mutual friends
            try await db.collection("users").document(request.fromUserId).updateData([
                "friendIds": FieldValue.arrayUnion([request.toUserId])
            ])
            try await db.collection("users").document(request.toUserId).updateData([
                "friendIds": FieldValue.arrayUnion([request.fromUserId]),
                "pendingFriendIds": FieldValue.arrayRemove([request.fromUserId])
            ])
        } else {
            try await db.collection("users").document(request.toUserId).updateData([
                "pendingFriendIds": FieldValue.arrayRemove([request.fromUserId])
            ])
        }
    }

    func removeFriend(currentUserId: String, friendId: String) async throws {
        try await db.collection("users").document(currentUserId).updateData([
            "friendIds": FieldValue.arrayRemove([friendId])
        ])
        try await db.collection("users").document(friendId).updateData([
            "friendIds": FieldValue.arrayRemove([currentUserId])
        ])
    }

    func fetchPendingFriendRequests(forUserId uid: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: FriendRequest.self) }
    }

    // MARK: – Screen Time Requests

    func sendScreenTimeRequest(from fromUser: AppUser, to toUser: AppUser) async throws {
        let request = ScreenTimeRequest(
            fromUserId: fromUser.uid,
            fromUsername: fromUser.username,
            fromDisplayName: fromUser.displayName,
            toUserId: toUser.uid,
            status: .pending,
            sentAt: Date(),
            fulfilledAt: nil
        )
        let ref = db.collection("screenTimeRequests").document()
        try ref.setData(from: request)
    }

    func fetchPendingScreenTimeRequests(forUserId uid: String) async throws -> [ScreenTimeRequest] {
        let snapshot = try await db.collection("screenTimeRequests")
            .whereField("toUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: ScreenTimeRequestStatus.pending.rawValue)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: ScreenTimeRequest.self) }
    }

    func fulfillScreenTimeRequest(_ request: ScreenTimeRequest, screenTimeMinutes: Int) async throws {
        guard let reqId = request.id else { return }
        try await db.collection("screenTimeRequests").document(reqId).updateData([
            "status": ScreenTimeRequestStatus.fulfilled.rawValue,
            "fulfilledAt": Timestamp(date: Date())
        ])
        // Update requester's view of this user's screen time
        try await db.collection("users").document(request.toUserId).updateData([
            "totalScreenTimeToday": screenTimeMinutes,
            "lastSynced": Timestamp(date: Date())
        ])
    }

    // MARK: – Screen Time Sync

    func updateScreenTime(uid: String, todayMinutes: Int, weekMinutes: Int) async throws {
        try await db.collection("users").document(uid).updateData([
            "totalScreenTimeToday": todayMinutes,
            "totalScreenTimeWeek": weekMinutes,
            "lastSynced": Timestamp(date: Date())
        ])
    }

    // MARK: – Leaderboard

    func fetchLeaderboard(friendIds: [String], currentUserId: String) async throws -> [LeaderboardEntry] {
        let ids = friendIds + [currentUserId]
        let users = try await fetchUsers(byIds: ids)
        let sorted = users
            .filter { $0.isScreenTimePublic }
            .sorted { $0.totalScreenTimeToday < $1.totalScreenTimeToday }
        return sorted.enumerated().map { index, user in
            LeaderboardEntry(
                id: user.uid,
                username: user.username,
                displayName: user.displayName,
                photoURL: user.photoURL,
                totalMinutesToday: user.totalScreenTimeToday,
                rank: index + 1,
                isCurrentUser: user.uid == currentUserId
            )
        }
    }

    // MARK: – Real-time listener

    func listenToUser(uid: String, onChange: @escaping (AppUser) -> Void) -> ListenerRegistration {
        db.collection("users").document(uid).addSnapshotListener { snapshot, _ in
            guard let user = try? snapshot?.data(as: AppUser.self) else { return }
            onChange(user)
        }
    }
}

// MARK: – Array chunking helper
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
