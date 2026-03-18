import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var passwordMismatch = false

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.tcTextSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.tcSurface2)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.tcText)
                        Text("Join your friends on TimeControl")
                            .font(.system(size: 15))
                            .foregroundColor(.tcTextSecondary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 36)

                    VStack(spacing: 14) {
                        TCTextField(placeholder: "Display Name", text: $displayName,
                                    icon: "person")
                        TCTextField(placeholder: "Username (e.g. cooluser)", text: $username,
                                    icon: "at", autocapitalization: .never)
                        TCTextField(placeholder: "Email", text: $email,
                                    icon: "envelope", keyboardType: .emailAddress,
                                    autocapitalization: .never)
                        TCTextField(placeholder: "Password", text: $password,
                                    icon: "lock", isSecure: true)
                        TCTextField(placeholder: "Confirm Password", text: $confirmPassword,
                                    icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 6) {
                        if passwordMismatch {
                            Label("Passwords do not match.", systemImage: "exclamationmark.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.tcRed)
                        }
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.tcRed)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                    // Username rules hint
                    Text("Username: 3–20 characters, letters, numbers, underscores.")
                        .font(.system(size: 12))
                        .foregroundColor(.tcTextSecondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 28)

                    Button {
                        guard password == confirmPassword else { passwordMismatch = true; return }
                        passwordMismatch = false
                        authViewModel.signUp(
                            email: email,
                            password: password,
                            username: username,
                            displayName: displayName
                        )
                    } label: {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                            }
                        }
                        .tcPrimaryButton()
                    }
                    .disabled(authViewModel.isLoading || formIncomplete)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)
                }
            }
        }
    }

    private var formIncomplete: Bool {
        displayName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
}
