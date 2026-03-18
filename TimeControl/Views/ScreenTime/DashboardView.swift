import SwiftUI
import FamilyControls

struct DashboardView: View {
    @EnvironmentObject var vm: ScreenTimeViewModel
    @State private var showLimitSheet = false

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if !vm.isAuthorized {
                        authorizationBanner
                    }
                    usageSummarySection
                    appLimitsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showLimitSheet) {
            AppLimitSheet()
                .environmentObject(vm)
        }
        .task {
            if !vm.isAuthorized {
                await vm.requestAuthorization()
            }
            await vm.syncToFirebase()
        }
        .refreshable {
            vm.refreshUsage()
            await vm.syncToFirebase()
        }
    }

    // MARK: – Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.tcText)
                Text(todayDateString)
                    .font(.system(size: 14))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            Button { Task { vm.refreshUsage(); await vm.syncToFirebase() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.tcPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.tcSurface2)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 20)
    }

    private var authorizationBanner: some View {
        Button { Task { await vm.requestAuthorization() } } label: {
            HStack(spacing: 14) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.tcYellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Screen Time Access")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tcText)
                    Text("Tap to grant permission and unlock all features.")
                        .font(.system(size: 13))
                        .foregroundColor(.tcTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.tcTextSecondary)
            }
            .padding(16)
            .background(Color.tcYellow.opacity(0.1))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tcYellow.opacity(0.3), lineWidth: 1))
        }
    }

    private var usageSummarySection: some View {
        VStack(spacing: 12) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.tcBorder, lineWidth: 12)
                    .frame(width: 160, height: 160)
                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(
                        LinearGradient(colors: [Color.tcPrimary, Color.tcAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progressFraction)

                VStack(spacing: 4) {
                    Text(vm.formattedToday)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.tcText)
                    Text("Today")
                        .font(.system(size: 13))
                        .foregroundColor(.tcTextSecondary)
                }
            }
            .padding(.vertical, 8)

            // Weekly card
            HStack(spacing: 12) {
                statCard(label: "This Week", value: vm.formattedWeek, icon: "calendar", color: .tcPrimary)
                statCard(label: "Daily Avg", value: dailyAvg, icon: "chart.bar.fill", color: .tcGreen)
            }
        }
    }

    private func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.tcTextSecondary)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.tcText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tcCard()
    }

    private var appLimitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("App Limits")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.tcText)
                Spacer()
                Button { showLimitSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.tcPrimary)
                        .clipShape(Circle())
                }
            }

            if vm.appLimits.isEmpty {
                emptyLimitsCard
            } else {
                ForEach(vm.appLimits) { limit in
                    AppLimitRow(limit: limit) {
                        vm.removeLimit(limit)
                    }
                }
            }
        }
    }

    private var emptyLimitsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 32))
                .foregroundColor(.tcTextSecondary)
            Text("No App Limits Set")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.tcText)
            Text("Tap + to limit time on specific apps.")
                .font(.system(size: 14))
                .foregroundColor(.tcTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .tcCard()
    }

    // MARK: – Helpers

    private var progressFraction: CGFloat {
        // Assume 6 hours (360 min) is "full" ring
        min(CGFloat(vm.todayMinutes) / 360.0, 1.0)
    }

    private var dailyAvg: String {
        let avg = vm.weekMinutes / 7
        let h = avg / 60, m = avg % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}

struct AppLimitRow: View {
    var limit: AppLimit
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.tcPrimary.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "app.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.tcPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(limit.appName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tcText)
                Text("\(limit.limitMinutes / 60)h \(limit.limitMinutes % 60)m limit")
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15))
                    .foregroundColor(.tcRed)
            }
        }
        .padding(16)
        .tcCard()
    }
}

struct AppLimitSheet: View {
    @EnvironmentObject var vm: ScreenTimeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Handle
                Capsule().fill(Color.tcBorder).frame(width: 36, height: 4).padding(.top, 12)

                Text("Set App Limit")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.tcText)
                    .padding(.top, 24)

                // App picker
                Button {
                    vm.showAppPicker = true
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .foregroundColor(.tcPrimary)
                        Text("Choose Apps")
                            .foregroundColor(.tcText)
                        Spacer()
                        Text(vm.selectedApps.applicationTokens.isEmpty ? "None" : "\(vm.selectedApps.applicationTokens.count) selected")
                            .foregroundColor(.tcTextSecondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.tcTextSecondary)
                    }
                    .padding(16)
                    .tcCard()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Time picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Limit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tcText)
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $vm.limitHours) {
                            ForEach(0..<24, id: \.self) { Text("\($0)h") }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        Picker("Minutes", selection: $vm.limitMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { Text("\($0)m") }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 150)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()

                Button {
                    vm.applyLimit()
                    dismiss()
                } label: {
                    Text("Apply Limit")
                        .tcPrimaryButton()
                }
                .disabled(vm.selectedApps.applicationTokens.isEmpty || vm.totalLimitMinutes == 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .familyActivityPicker(isPresented: $vm.showAppPicker, selection: $vm.selectedApps)
    }
}
