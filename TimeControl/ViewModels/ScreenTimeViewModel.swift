import SwiftUI
import FamilyControls

@MainActor
class ScreenTimeViewModel: ObservableObject {
    @Published var todayMinutes: Int = 0
    @Published var weekMinutes: Int = 0
    @Published var appLimits: [AppLimit] = []
    @Published var showAppPicker = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var limitHours: Int = 1
    @Published var limitMinutes: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let screenTimeService = ScreenTimeService.shared
    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared

    var isAuthorized: Bool { screenTimeService.isAuthorized }

    var totalLimitMinutes: Int { limitHours * 60 + limitMinutes }

    func load() async {
        appLimits = screenTimeService.appLimits
        refreshUsage()
    }

    func refreshUsage() {
        todayMinutes = screenTimeService.fetchTodayScreenTimeMinutes()
        weekMinutes = screenTimeService.fetchWeekScreenTimeMinutes()
    }

    func requestAuthorization() async {
        await screenTimeService.requestAuthorization()
    }

    func applyLimit() {
        guard totalLimitMinutes > 0 else { return }
        screenTimeService.setAppLimit(selection: selectedApps, limitMinutes: totalLimitMinutes)
        appLimits = screenTimeService.appLimits
        showAppPicker = false
    }

    func removeLimit(_ limit: AppLimit) {
        screenTimeService.removeLimit(for: limit)
        appLimits = screenTimeService.appLimits
    }

    func syncToFirebase() async {
        guard let uid = authService.appUser?.uid else { return }
        refreshUsage()
        do {
            try await firestoreService.updateScreenTime(uid: uid, todayMinutes: todayMinutes, weekMinutes: weekMinutes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var formattedToday: String { formatMinutes(todayMinutes) }
    var formattedWeek: String { formatMinutes(weekMinutes) }

    private func formatMinutes(_ total: Int) -> String {
        let h = total / 60
        let m = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
