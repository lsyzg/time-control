import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var screenTimeVM = ScreenTimeViewModel()
    @StateObject private var friendsVM = FriendsViewModel()
    @StateObject private var leaderboardVM = LeaderboardViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tcBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(screenTimeVM)
                    .tag(0)

                FriendsView()
                    .environmentObject(friendsVM)
                    .tag(1)

                LeaderboardView()
                    .environmentObject(leaderboardVM)
                    .tag(2)

                ProfileView()
                    .environmentObject(screenTimeVM)
                    .tag(3)
            }
            .tabViewStyle(.automatic)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, friendsVM: friendsVM)
        }
        .task {
            await screenTimeVM.load()
            await friendsVM.loadFriends()
            await leaderboardVM.loadLeaderboard()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject var friendsVM: FriendsViewModel

    private let items: [(icon: String, label: String)] = [
        ("timer", "Dashboard"),
        ("person.2.fill", "Friends"),
        ("trophy.fill", "Leaderboard"),
        ("person.circle.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: items[i].icon)
                                .font(.system(size: 22, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .tcPrimary : .tcTextSecondary)

                            // Badge for pending friend requests
                            if i == 1 && !friendsVM.pendingRequests.isEmpty {
                                Circle()
                                    .fill(Color.tcAccent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                        Text(items[i].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == i ? .tcPrimary : .tcTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            Color.tcSurface
                .overlay(Rectangle().fill(Color.tcBorder).frame(height: 0.5), alignment: .top)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: -2)
    }
}
