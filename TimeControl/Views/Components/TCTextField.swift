import SwiftUI

struct TCTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(.tcTextSecondary)
                    .frame(width: 20)
            }
            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                }
            }
            .foregroundColor(.tcText)
            if isSecure {
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.tcTextSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.tcSurface2)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tcBorder, lineWidth: 1))
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.tcBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.tcGradient)
                Text("TimeControl")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.tcText)
            }
        }
    }
}

struct AvatarView: View {
    var photoURL: String?
    var displayName: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url = photoURL.flatMap({ URL(string: $0) }) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            LinearGradient(colors: [Color.tcPrimary, Color.tcAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        displayName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
            .uppercased()
    }
}

struct RankBadge: View {
    var rank: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(rankColor.opacity(0.2))
                .frame(width: 32, height: 32)
            if rank <= 3 {
                Text(medal)
                    .font(.system(size: 16))
            } else {
                Text("\(rank)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(rankColor)
            }
        }
    }

    private var medal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .tcYellow
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return .tcTextSecondary
        }
    }
}
