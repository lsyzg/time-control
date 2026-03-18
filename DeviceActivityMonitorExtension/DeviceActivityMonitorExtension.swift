import DeviceActivity
import ManagedSettings
import Foundation

/// This extension is called by the system when a DeviceActivity threshold is crossed.
/// It runs in a separate process — it cannot access the main app's memory directly.
/// Communication is via App Groups (shared UserDefaults).
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.timecontrol.shared")

    // Called when an event threshold (app limit) is reached
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // The system automatically shows the ShieldConfiguration at this point.
        // We record the threshold breach so the main app can react.
        sharedDefaults?.set(Date(), forKey: "lastThresholdReached_\(event.rawValue)")
    }

    // Called at the start of a DeviceActivity interval (midnight for daily)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Reset today counter at start of new interval
        sharedDefaults?.set(0, forKey: "todayScreenTimeMinutes")
    }

    // Called when the DeviceActivity interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
}
