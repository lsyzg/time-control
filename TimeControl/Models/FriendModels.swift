import Foundation
import FirebaseFirestore

struct FriendRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUserId: String
    var fromUsername: String
    var fromDisplayName: String
    var toUserId: String
    var status: FriendRequestStatus
    var sentAt: Date
}

enum FriendRequestStatus: String, Codable {
    case pending, accepted, declined
}

struct ScreenTimeRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUserId: String
    var fromUsername: String
    var fromDisplayName: String
    var toUserId: String
    var status: ScreenTimeRequestStatus
    var sentAt: Date
    var fulfilledAt: Date?
}

enum ScreenTimeRequestStatus: String, Codable {
    case pending, fulfilled, declined
}

struct LeaderboardEntry: Identifiable {
    var id: String           // uid
    var username: String
    var displayName: String
    var photoURL: String?
    var totalMinutesToday: Int
    var rank: Int
    var isCurrentUser: Bool

    var formattedTime: String {
        let hours = totalMinutesToday / 60
        let mins = totalMinutesToday % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
