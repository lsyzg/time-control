import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var vm: FriendsViewModel
    @State private var showSearch = false

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if !vm.pendingRequests.isEmpty {
                        pendingRequestsSection
                    }
                    if !vm.screenTimeRequests.isEmpty {
                        screenTimeRequestsSection
                    }
                    friendsListSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showSearch) {
            FriendSearchView()
                .environmentObject(vm)
        }
        .task { await vm.loadFriends() }
        .refreshable { await vm.loadFriends() }
        .overlay(alignment: .bottom) {
            if let msg = vm.successMessage {
                toastBanner(msg, color: .tcGreen)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { vm.successMessage = nil } }
            }
        }
    }

    // MARK: – Sections

    private var headerSection: some View {
        HStack {
            Text("Friends")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.tcText)
            if !vm.pendingRequests.isEmpty {
                Text("\(vm.pendingRequests.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.tcAccent)
                    .clipShape(Capsule())
            }
            Spacer()
            Button { showSearch = true } label: {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.tcPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.tcSurface2)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 20)
    }

    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Requests")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.tcText)
            ForEach(vm.pendingRequests) { req in
                FriendRequestRow(request: req) {
                    Task { await vm.acceptRequest(req) }
                } onDecline: {
                    Task { await vm.declineRequest(req) }
                }
            }
        }
    }

    private var screenTimeRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Time Requests")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.tcText)
            ForEach(vm.screenTimeRequests) { req in
                ScreenTimeRequestRow(request: req) {
                    Task { await vm.fulfillScreenTimeRequest(req) }
                }
            }
        }
    }

    private var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Friends (\(vm.friends.count))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.tcText)

            if vm.isLoading {
                ProgressView().tint(.tcPrimary).frame(maxWidth: .infinity).padding(40)
            } else if vm.friends.isEmpty {
                emptyFriendsCard
            } else {
                ForEach(vm.friends) { friend in
                    FriendRow(friend: friend) {
                        Task { await vm.requestScreenTime(from: friend) }
                    } onRemove: {
                        Task { await vm.removeFriend(friend) }
                    }
                }
            }
        }
    }

    private var emptyFriendsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(.system(size: 36))
                .foregroundColor(.tcTextSecondary)
            Text("No Friends Yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.tcText)
            Text("Search by @username to add your first friend.")
                .font(.system(size: 14))
                .foregroundColor(.tcTextSecondary)
                .multilineTextAlignment(.center)
            Button { showSearch = true } label: {
                Text("Find Friends")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tcPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .tcCard()
    }

    private func toastBanner(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(24)
            .shadow(radius: 8)
            .padding(.bottom, 100)
    }
}

// MARK: – Row Components

struct FriendRow: View {
    var friend: AppUser
    var onRequestScreenTime: () -> Void
    var onRemove: () -> Void
    @State private var showOptions = false

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(photoURL: friend.photoURL, displayName: friend.displayName)
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tcText)
                Text(friend.atUsername)
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            if friend.isScreenTimePublic {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatMins(friend.totalScreenTimeToday))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.tcText)
                    Text("today")
                        .font(.system(size: 11))
                        .foregroundColor(.tcTextSecondary)
                }
            }
            Menu {
                Button { onRequestScreenTime() } label: {
                    Label("Request Screen Time", systemImage: "timer")
                }
                Divider()
                Button(role: .destructive) { onRemove() } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.tcTextSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(16)
        .tcCard()
    }

    private func formatMins(_ m: Int) -> String {
        m > 60 ? "\(m/60)h \(m%60)m" : "\(m)m"
    }
}

struct FriendRequestRow: View {
    var request: FriendRequest
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(displayName: request.fromDisplayName, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromDisplayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tcText)
                Text("@\(request.fromUsername)")
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tcRed)
                        .frame(width: 36, height: 36)
                        .background(Color.tcRed.opacity(0.12))
                        .clipShape(Circle())
                }
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tcGreen)
                        .frame(width: 36, height: 36)
                        .background(Color.tcGreen.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color.tcPrimary.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tcPrimary.opacity(0.2), lineWidth: 1))
    }
}

struct ScreenTimeRequestRow: View {
    var request: ScreenTimeRequest
    var onFulfill: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.tcYellow.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "timer")
                    .foregroundColor(.tcYellow)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(request.fromDisplayName) wants your screen time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tcText)
                Text("@\(request.fromUsername)")
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            Button(action: onFulfill) {
                Text("Share")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.tcPrimary)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.tcYellow.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tcYellow.opacity(0.25), lineWidth: 1))
    }
}
