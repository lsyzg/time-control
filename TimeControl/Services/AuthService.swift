import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import UIKit

enum AuthState: Equatable {
    case loading
    case signedOut
    case needsUsername(User)
    case signedIn

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.signedOut, .signedOut), (.signedIn, .signedIn): return true
        case (.needsUsername(let a), .needsUsername(let b)): return a.uid == b.uid
        default: return false
        }
    }
}

enum AuthError: LocalizedError {
    case noClientID, noIDToken, usernameTaken, usernameInvalid, weakPassword, emailInUse, invalidCredentials

    var errorDescription: String? {
        switch self {
        case .noClientID:         return "Firebase configuration error."
        case .noIDToken:          return "Google Sign-In failed. Try again."
        case .usernameTaken:      return "That username is already taken."
        case .usernameInvalid:    return "Username must be 3–20 characters: letters, numbers, underscores only."
        case .weakPassword:       return "Password must be at least 8 characters."
        case .emailInUse:         return "An account with this email already exists."
        case .invalidCredentials: return "Invalid email or password."
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    @Published var currentFirebaseUser: User?
    @Published var appUser: AppUser?

    private init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentFirebaseUser = user
        }
    }

    // MARK: – Google Sign-In

    func signInWithGoogle(presenting vc: UIViewController) async throws -> AuthState {
        guard let clientID = FirebaseApp.app()?.options.clientID else { throw AuthError.noClientID }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: vc)
        guard let idToken = result.user.idToken?.tokenString else { throw AuthError.noIDToken }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return try await resolveUser(authResult.user, displayName: result.user.profile?.name, photoURL: result.user.profile?.imageURL(withDimension: 200)?.absoluteString)
    }

    // MARK: – Email Sign-In / Sign-Up

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await fetchAppUser(uid: result.user.uid)
            appUser = user
        } catch let error as NSError {
            if error.code == AuthErrorCode.wrongPassword.rawValue ||
               error.code == AuthErrorCode.invalidEmail.rawValue ||
               error.code == AuthErrorCode.userNotFound.rawValue {
                throw AuthError.invalidCredentials
            }
            throw error
        }
    }

    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        guard isValidUsername(username) else { throw AuthError.usernameInvalid }
        guard password.count >= 8 else { throw AuthError.weakPassword }

        let usernameDoc = try await db.collection("usernames").document(username.lowercased()).getDocument()
        if usernameDoc.exists { throw AuthError.usernameTaken }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let newUser = AppUser(
            uid: result.user.uid,
            username: username.lowercased(),
            displayName: displayName,
            email: email,
            photoURL: nil,
            friendIds: [],
            pendingFriendIds: [],
            totalScreenTimeToday: 0,
            totalScreenTimeWeek: 0,
            isScreenTimePublic: true,
            createdAt: Date(),
            lastSynced: Date()
        )
        try await saveUser(newUser)
        try await db.collection("usernames").document(username.lowercased()).setData(["uid": result.user.uid])
        appUser = newUser
    }

    func setupUsername(for firebaseUser: User, username: String, displayName: String) async throws {
        guard isValidUsername(username) else { throw AuthError.usernameInvalid }
        let usernameDoc = try await db.collection("usernames").document(username.lowercased()).getDocument()
        if usernameDoc.exists { throw AuthError.usernameTaken }

        let newUser = AppUser(
            uid: firebaseUser.uid,
            username: username.lowercased(),
            displayName: displayName,
            email: firebaseUser.email ?? "",
            photoURL: firebaseUser.photoURL?.absoluteString,
            friendIds: [],
            pendingFriendIds: [],
            totalScreenTimeToday: 0,
            totalScreenTimeWeek: 0,
            isScreenTimePublic: true,
            createdAt: Date(),
            lastSynced: Date()
        )
        try await saveUser(newUser)
        try await db.collection("usernames").document(username.lowercased()).setData(["uid": firebaseUser.uid])
        appUser = newUser
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        appUser = nil
    }

    func loadCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        appUser = try? await fetchAppUser(uid: uid)
    }

    // MARK: – Helpers

    func fetchAppUser(uid: String) async throws -> AppUser {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: AppUser.self)
    }

    func saveUser(_ user: AppUser) async throws {
        try db.collection("users").document(user.uid).setData(from: user)
    }

    private func resolveUser(_ firebaseUser: User, displayName: String?, photoURL: String?) async throws -> AuthState {
        let doc = try await db.collection("users").document(firebaseUser.uid).getDocument()
        if doc.exists, let user = try? doc.data(as: AppUser.self) {
            appUser = user
            return .signedIn
        }
        return .needsUsername(firebaseUser)
    }

    private func isValidUsername(_ username: String) -> Bool {
        let regex = "^[a-zA-Z0-9_]{3,20}$"
        return username.range(of: regex, options: .regularExpression) != nil
    }
}
