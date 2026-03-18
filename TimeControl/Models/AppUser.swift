import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var uid: String
    var username: String          // lowercase, unique
    var displayName: String
    var email: String
    var photoURL: String?
    var friendIds: [String]
    var pendingFriendIds: [String] // incoming friend requests
    var totalScreenTimeToday: Int  // minutes
    var totalScreenTimeWeek: Int   // minutes
    var isScreenTimePublic: Bool
    var createdAt: Date
    var lastSynced: Date

    var atUsername: String { "@\(username)" }

    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        lhs.uid == rhs.uid
    }
}
