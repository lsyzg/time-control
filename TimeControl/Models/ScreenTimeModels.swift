import Foundation
import FamilyControls
import ManagedSettings

struct AppLimit: Codable, Identifiable {
    var id: String = UUID().uuidString
    var bundleIdentifier: String
    var appName: String
    var limitMinutes: Int
    var isEnabled: Bool
    var createdAt: Date

    var limitComponents: DateComponents {
        var c = DateComponents()
        c.minute = limitMinutes % 60
        c.hour = limitMinutes / 60
        return c
    }
}

struct DailyScreenTimeSummary: Codable {
    var date: Date
    var totalMinutes: Int
    var appBreakdown: [AppUsageItem]
}

struct AppUsageItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    var bundleIdentifier: String
    var appName: String
    var minutes: Int
    var hasLimit: Bool
    var limitMinutes: Int?
}
