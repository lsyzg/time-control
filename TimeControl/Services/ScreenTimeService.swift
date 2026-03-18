import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@MainActor
class ScreenTimeService: ObservableObject {
    static let shared = ScreenTimeService()

    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var appLimits: [AppLimit] = []
    @Published var selectedApps = FamilyActivitySelection()

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let limitsKey = "app_limits"

    private init() {
        loadSavedLimits()
        checkAuthorization()
    }

    // MARK: – Authorization

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
            authorizationError = nil
        } catch {
            isAuthorized = false
            authorizationError = error.localizedDescription
        }
    }

    private func checkAuthorization() {
        isAuthorized = center.authorizationStatus == .approved
    }

    // MARK: – App Limits

    func setAppLimit(selection: FamilyActivitySelection, limitMinutes: Int) {
        // Build a ManagedSettings shield for each app token
        var newLimits: [AppLimit] = []

        for app in selection.applicationTokens {
            let bundleId = app.description // token description as proxy
            let limit = AppLimit(
                bundleIdentifier: bundleId,
                appName: bundleId,
                limitMinutes: limitMinutes,
                isEnabled: true,
                createdAt: Date()
            )
            newLimits.append(limit)
        }

        // Apply via DeviceActivity schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let activityName = DeviceActivityName("dailyLimit")
        let center = DeviceActivityCenter()

        // Build events for each app
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for token in selection.applicationTokens {
            let eventName = DeviceActivityEvent.Name(token.description)
            events[eventName] = DeviceActivityEvent(
                applications: [token],
                threshold: DateComponents(minute: limitMinutes)
            )
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: events)
        } catch {
            print("Failed to start monitoring: \(error)")
        }

        // Apply shield (blocks app after limit)
        store.shield.applications = selection.applicationTokens

        appLimits.append(contentsOf: newLimits)
        saveLimits()
    }

    func removeLimit(for limit: AppLimit) {
        appLimits.removeAll { $0.id == limit.id }
        // If no more limits, clear the shield
        if appLimits.isEmpty {
            store.shield.applications = nil
            DeviceActivityCenter().stopMonitoring([DeviceActivityName("dailyLimit")])
        }
        saveLimits()
    }

    func toggleLimit(_ limit: AppLimit) {
        guard let index = appLimits.firstIndex(where: { $0.id == limit.id }) else { return }
        appLimits[index].isEnabled.toggle()
        saveLimits()
    }

    // MARK: – Persistence

    private func saveLimits() {
        if let data = try? JSONEncoder().encode(appLimits) {
            UserDefaults.standard.set(data, forKey: limitsKey)
        }
    }

    private func loadSavedLimits() {
        guard let data = UserDefaults.standard.data(forKey: limitsKey),
              let limits = try? JSONDecoder().decode([AppLimit].self, from: data) else { return }
        appLimits = limits
    }

    // MARK: – Screen Time Estimation
    // Note: FamilyControls does not expose raw usage numbers directly.
    // DeviceActivityReport (app extension) renders usage; here we provide
    // a hook to receive synced data from the extension via App Group.

    func fetchTodayScreenTimeMinutes() -> Int {
        let defaults = UserDefaults(suiteName: "group.com.timecontrol.shared")
        return defaults?.integer(forKey: "todayScreenTimeMinutes") ?? 0
    }

    func fetchWeekScreenTimeMinutes() -> Int {
        let defaults = UserDefaults(suiteName: "group.com.timecontrol.shared")
        return defaults?.integer(forKey: "weekScreenTimeMinutes") ?? 0
    }
}
