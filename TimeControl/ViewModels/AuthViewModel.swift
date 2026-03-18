import SwiftUI
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { await self?.resolveAuthState(user: user) }
        }
    }

    deinit {
        if let handle = listenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool { authState == .signedIn }
    var currentUser: AppUser? { authService.appUser }

    // MARK: – Auth actions

    func signInWithGoogle(presenting vc: UIViewController) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let state = try await authService.signInWithGoogle(presenting: vc)
                authState = state
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signIn(email: String, password: String) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await authService.signIn(email: email, password: password)
                authState = .signedIn
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signUp(email: String, password: String, username: String, displayName: String) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await authService.signUp(email: email, password: password, username: username, displayName: displayName)
                authState = .signedIn
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func setupUsername(firebaseUser: User, username: String, displayName: String) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await authService.setupUsername(for: firebaseUser, username: username, displayName: displayName)
                authState = .signedIn
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            authState = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: – Private

    private func resolveAuthState(user: User?) async {
        guard let user else {
            authState = .signedOut
            return
        }
        // Try fetching existing profile
        if let appUser = try? await authService.fetchAppUser(uid: user.uid) {
            authService.appUser = appUser
            authState = .signedIn
        } else {
            authState = .needsUsername(user)
        }
    }
}
