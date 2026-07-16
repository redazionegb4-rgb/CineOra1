import SwiftUI

enum CineTheme {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.055)
    static let card = Color.white.opacity(0.075)
    static let cardStrong = Color.white.opacity(0.12)
    static let accent = Color(red: 0.98, green: 0.18, blue: 0.35)
    static let accent2 = Color(red: 0.48, green: 0.22, blue: 0.98)
    static let secondaryText = Color.white.opacity(0.66)
    static let gradient = LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension View {
    func cineCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(CineTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
