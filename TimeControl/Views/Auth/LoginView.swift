import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Spacer().frame(height: 60)
                        ZStack {
                            Circle()
                                .fill(Color.tcPrimary.opacity(0.15))
                                .frame(width: 90, height: 90)
                            Image(systemName: "timer")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color.tcPrimary, Color.tcAccent],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        Text("TimeControl")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.tcText)
                        Text("Screen time, together.")
                            .font(.system(size: 16))
                            .foregroundColor(.tcTextSecondary)
                    }

                    Spacer().frame(height: 48)

                    // Form
                    VStack(spacing: 14) {
                        TCTextField(placeholder: "Email", text: $email,
                                    icon: "envelope", keyboardType: .emailAddress,
                                    autocapitalization: .never)
                        TCTextField(placeholder: "Password", text: $password,
                                    icon: "lock", isSecure: true)
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

                    Spacer().frame(height: 24)

                    // Sign In Button
                    Button {
                        authViewModel.signIn(email: email, password: password)
                    } label: {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                            }
                        }
                        .tcPrimaryButton()
                    }
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.tcBorder).frame(height: 1)
                        Text("or").font(.system(size: 14)).foregroundColor(.tcTextSecondary).padding(.horizontal, 12)
                        Rectangle().fill(Color.tcBorder).frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                    // Google Sign-In
                    GoogleSignInButtonWrapper {
                        authViewModel.signInWithGoogle(presenting: topViewController())
                    }
                    .frame(height: 52)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.tcTextSecondary)
                        Button("Sign Up") { showSignUp = true }
                            .foregroundColor(.tcPrimary)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))

                    Spacer().frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authViewModel)
        }
    }

    private func topViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return UIViewController()
        }
        var current = root
        while let presented = current.presentedViewController { current = presented }
        return current
    }
}

struct GoogleSignInButtonWrapper: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.tcText)
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.tcText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.tcSurface2)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tcBorder, lineWidth: 1))
        }
    }
}
