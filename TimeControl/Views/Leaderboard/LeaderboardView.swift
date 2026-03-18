import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var vm: LeaderboardViewModel

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if vm.isLoading {
                        ProgressView().tint(.tcPrimary).frame(maxWidth: .infinity).padding(60)
                    } else if vm.entries.isEmpty {
                        emptyState
                    } else {
                        podiumSection
                        fullListSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .task { await vm.loadLeaderboard() }
        .refreshable { await vm.loadLeaderboard() }
    }

    // MARK: – Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Leaderboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.tcText)
                Text("Lower is better — less screen time wins!")
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            Button { Task { await vm.loadLeaderboard() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
                    .foregroundColor(.tcPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.tcSurface2)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 20)
    }

    private var podiumSection: some View {
        let top3 = Array(vm.entries.prefix(3))
        return HStack(alignment: .bottom, spacing: 12) {
            if top3.count >= 2 {
                podiumCard(entry: top3[1], height: 120)
            }
            if top3.count >= 1 {
                podiumCard(entry: top3[0], height: 150)
            }
            if top3.count >= 3 {
                podiumCard(entry: top3[2], height: 100)
            }
        }
        .padding(.top, 8)
    }

    private func podiumCard(_ entry: LeaderboardEntry, height: CGFloat) -> some View {
        let isFirst = entry.rank == 1
        return VStack(spacing: 8) {
            AvatarView(photoURL: entry.photoURL, displayName: entry.displayName, size: isFirst ? 60 : 48)
                .overlay(alignment: .bottom) {
                    if entry.isCurrentUser {
                        Text("You")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tcPrimary)
                            .cornerRadius(6)
                            .offset(y: 8)
                    }
                }
                .padding(.bottom, entry.isCurrentUser ? 10 : 0)

            RankBadge(rank: entry.rank)

            Text(entry.displayName.components(separatedBy: " ").first ?? entry.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tcText)
                .lineLimit(1)

            Text(entry.formattedTime)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isFirst ? .tcYellow : .tcText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(height: height + 80)
        .background(
            isFirst
                ? LinearGradient(colors: [Color.tcYellow.opacity(0.12), Color.tcYellow.opacity(0.04)],
                                 startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Color.tcSurface, Color.tcSurface],
                                 startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isFirst ? Color.tcYellow.opacity(0.3) : Color.tcBorder, lineWidth: 1)
        )
    }

    private var fullListSection: some View {
        VStack(spacing: 10) {
            ForEach(vm.entries.dropFirst(min(3, vm.entries.count))) { entry in
                LeaderboardRow(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.tcTextSecondary)
            Text("No Friends Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.tcText)
            Text("Add friends to compare screen time and compete for the top spot.")
                .font(.system(size: 15))
                .foregroundColor(.tcTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct LeaderboardRow: View {
    var entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            RankBadge(rank: entry.rank)
            AvatarView(photoURL: entry.photoURL, displayName: entry.displayName, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.tcText)
                    if entry.isCurrentUser {
                        Text("You")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tcPrimary)
                            .cornerRadius(6)
                    }
                }
                Text("@\(entry.username)")
                    .font(.system(size: 13))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            Text(entry.formattedTime)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(entry.isCurrentUser ? .tcPrimary : .tcText)
        }
        .padding(14)
        .background(entry.isCurrentUser ? Color.tcPrimary.opacity(0.08) : Color.tcSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(entry.isCurrentUser ? Color.tcPrimary.opacity(0.25) : Color.clear, lineWidth: 1)
        )
    }
}
