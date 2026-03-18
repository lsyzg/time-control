import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                SplashView()
            case .signedOut:
                LoginView()
            case .needsUsername(let firebaseUser):
                UsernameSetupView(firebaseUser: firebaseUser)
            case .signedIn:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
    }
}
