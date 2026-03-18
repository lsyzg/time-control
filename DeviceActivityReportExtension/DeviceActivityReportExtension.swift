import DeviceActivity
import SwiftUI

/// Provides the SwiftUI view for DeviceActivityReport and also
/// writes aggregated usage data to the shared App Group so the main app
/// can read and sync it to Firebase.
@main
struct DeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { context in
            TotalActivityView(context: context)
        }
    }
}

struct TotalActivityReport: DeviceActivityReportScene {
    var body: some DeviceActivityReportScene {
        // Scene identifier matches what you pass in DeviceActivityReport()
        DeviceActivityReportScene.reporting(for: "totalActivity") { context in
            TotalActivityView(context: context)
        }
    }
}

struct TotalActivityView: View {
    var context: DeviceActivityResults<DeviceActivityData>
    @State private var totalMinutes = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTotal)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Total Today")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .task {
            await aggregateAndSync()
        }
    }

    private var formattedTotal: String {
        "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }

    private func aggregateAndSync() async {
        var total = 0
        for await data in context {
            for await activity in data.activitySegments {
                let mins = Int(activity.totalActivityDuration / 60)
                total += mins
            }
        }
        totalMinutes = total
        // Write to shared App Group so main app can read it
        let defaults = UserDefaults(suiteName: "group.com.timecontrol.shared")
        defaults?.set(total, forKey: "todayScreenTimeMinutes")
    }
}
