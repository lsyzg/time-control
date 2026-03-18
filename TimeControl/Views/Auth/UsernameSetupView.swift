import SwiftUI
import FirebaseAuth

/// Shown after Google Sign-In when user has no profile yet.
struct UsernameSetupView: View {
    var firebaseUser: User
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var username = ""
    @State private var displayName = ""

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(LinearGradient(colors: [Color.tcPrimary, Color.tcAccent],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("One More Step")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.tcText)
                    Text("Set your username to find and be found by friends.")
                        .font(.system(size: 15))
                        .foregroundColor(.tcTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer().frame(height: 48)

                VStack(spacing: 14) {
                    TCTextField(placeholder: "Display Name", text: $displayName, icon: "person")
                    TCTextField(placeholder: "Username", text: $username, icon: "at", autocapitalization: .never)
                }
                .padding(.horizontal, 24)

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.tcRed)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 32)

                Button {
                    authViewModel.setupUsername(firebaseUser: firebaseUser, username: username, displayName: displayName)
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue")
                        }
                    }
                    .tcPrimaryButton()
                }
                .disabled(authViewModel.isLoading || username.isEmpty || displayName.isEmpty)
                .padding(.horizontal, 24)

                Spacer()

                Button("Sign Out") { authViewModel.signOut() }
                    .font(.system(size: 15))
                    .foregroundColor(.tcTextSecondary)
                    .padding(.bottom, 32)
            }
        }
    }
}
