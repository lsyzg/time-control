import SwiftUI

struct FriendSearchView: View {
    @EnvironmentObject var vm: FriendsViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 14) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.tcTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Color.tcSurface2)
                            .clipShape(Circle())
                    }
                    Text("Find Friends")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.tcText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.tcTextSecondary)
                    TextField("Search @username", text: $vm.searchText)
                        .foregroundColor(.tcText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($searchFocused)
                        .onChange(of: vm.searchText) { _, _ in
                            Task { await vm.searchUsers() }
                        }
                    if !vm.searchText.isEmpty {
                        Button { vm.searchText = ""; vm.searchResults = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.tcTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.tcSurface2)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tcBorder, lineWidth: 1))
                .padding(.horizontal, 20)

                Text("Search by exact @username")
                    .font(.system(size: 12))
                    .foregroundColor(.tcTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                // Results
                ScrollView {
                    VStack(spacing: 12) {
                        if vm.isLoading {
                            ProgressView().tint(.tcPrimary).padding(40)
                        } else if vm.searchResults.isEmpty && !vm.searchText.isEmpty && !vm.isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "person.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(.tcTextSecondary)
                                Text("No user found")
                                    .font(.system(size: 16))
                                    .foregroundColor(.tcTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(48)
                        } else {
                            ForEach(vm.searchResults) { user in
                                SearchResultRow(
                                    user: user,
                                    isFriend: vm.isFriend(user)
                                ) {
                                    Task { await vm.sendFriendRequest(to: user) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
        .onAppear { searchFocused = true }
        .overlay(alignment: .bottom) {
            if let msg = vm.successMessage {
                Text(msg)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.tcGreen)
                    .cornerRadius(24)
                    .shadow(radius: 8)
                    .padding(.bottom, 40)
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { vm.successMessage = nil } }
            }
        }
    }
}

struct SearchResultRow: View {
    var user: AppUser
    var isFriend: Bool
    var onAdd: () -> Void
    @State private var requestSent = false

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(photoURL: user.photoURL, displayName: user.displayName, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tcText)
                Text(user.atUsername)
                    .font(.system(size: 14))
                    .foregroundColor(.tcTextSecondary)
            }
            Spacer()
            if isFriend {
                Label("Friends", systemImage: "checkmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tcGreen)
            } else if requestSent {
                Text("Requested")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.tcTextSecondary)
            } else {
                Button {
                    onAdd()
                    requestSent = true
                } label: {
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(LinearGradient(colors: [Color.tcPrimary, Color.tcPrimaryLight],
                                                   startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .tcCard()
    }
}
