import SwiftUI

extension Color {
    static let tcBackground   = Color(hex: "#0D0D0F")
    static let tcSurface      = Color(hex: "#1A1A1F")
    static let tcSurface2     = Color(hex: "#242429")
    static let tcPrimary      = Color(hex: "#7C5CFC")
    static let tcPrimaryLight = Color(hex: "#A080FF")
    static let tcAccent       = Color(hex: "#FF6B9D")
    static let tcGreen        = Color(hex: "#4ADE80")
    static let tcYellow       = Color(hex: "#FBBF24")
    static let tcRed          = Color(hex: "#F87171")
    static let tcText         = Color(hex: "#F1F1F5")
    static let tcTextSecondary = Color(hex: "#8E8E9A")
    static let tcBorder       = Color(hex: "#2E2E38")

    static let tcGradient = LinearGradient(
        colors: [Color(hex: "#7C5CFC"), Color(hex: "#FF6B9D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension View {
    func tcCard() -> some View {
        self
            .background(Color.tcSurface)
            .cornerRadius(16)
    }

    func tcPrimaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(colors: [Color.tcPrimary, Color.tcPrimaryLight],
                               startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(14)
    }

    func tcSecondaryButton() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.tcPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.tcSurface2)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tcPrimary.opacity(0.4), lineWidth: 1))
    }
}
