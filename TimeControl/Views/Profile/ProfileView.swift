import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var screenTimeVM: ScreenTimeViewModel
    @State private var showShareToggleConfirm = false
    @State private var isPublic = true

    var user: AppUser? { authViewModel.currentUser }

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    statsSection
                    settingsSection
                    signOutSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            isPublic = user?.isScreenTimePublic ?? true
        }
    }

    // MARK: – Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 20)
            AvatarView(
                photoURL: user?.photoURL,
                displayName: user?.displayName ?? "User",
                size: 90
            )
            VStack(spacing: 6) {
                Text(user?.displayName ?? "")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.tcText)
                Text(user?.atUsername ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(.tcPrimary)
                Text(user?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.tcTextSecondary)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard("Today", value: screenTimeVM.formattedToday, icon: "sun.max.fill", color: .tcYellow)
            statCard("This Week", value: screenTimeVM.formattedWeek, icon: "calendar", color: .tcPrimary)
            statCard("Friends", value: "\(user?.friendIds.count ?? 0)", icon: "person.2.fill", color: .tcGreen)
        }
    }

    private func statCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.tcText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.tcTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .tcCard()
    }

    private var settingsSection: some View {
        VStack(spacing: 2) {
            sectionLabel("Preferences")

            // Share screen time toggle
            HStack(spacing: 14) {
                settingIcon("eye.fill", color: .tcPrimary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Share Screen Time")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.tcText)
                    Text("Friends can see you on the leaderboard")
                        .font(.system(size: 12))
                        .foregroundColor(.tcTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $isPublic)
                    .tint(.tcPrimary)
                    .labelsHidden()
                    .onChange(of: isPublic) { _, newValue in
                        Task { await updateShareSetting(newValue) }
                    }
            }
            .padding(16)
            .background(Color.tcSurface)
            .cornerRadius(12)

            Spacer().frame(height: 12)

            // Sync screen time
            Button {
                Task {
                    await screenTimeVM.syncToFirebase()
                }
            } label: {
                HStack(spacing: 14) {
                    settingIcon("arrow.triangle.2.circlepath", color: .tcGreen)
                    Text("Sync Screen Time Now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.tcText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.tcTextSecondary)
                        .font(.system(size: 13))
                }
                .padding(16)
                .background(Color.tcSurface)
                .cornerRadius(12)
            }
        }
    }

    private var signOutSection: some View {
        Button {
            authViewModel.signOut()
        } label: {
            HStack(spacing: 14) {
                settingIcon("rectangle.portrait.and.arrow.right", color: .tcRed)
                Text("Sign Out")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.tcRed)
                Spacer()
            }
            .padding(16)
            .background(Color.tcSurface)
            .cornerRadius(12)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.tcTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }

    private func settingIcon(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 34, height: 34)
            Image(systemName: name).font(.system(size: 15)).foregroundColor(color)
        }
    }

    private func updateShareSetting(_ value: Bool) async {
        guard var user = user else { return }
        user.isScreenTimePublic = value
        try? await AuthService.shared.saveUser(user)
        AuthService.shared.appUser = user
    }
}
