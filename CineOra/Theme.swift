import SwiftUI

enum CineTheme {
    static let background = Color(red: 0.025, green: 0.035, blue: 0.055)
    static let surface = Color(red: 0.075, green: 0.09, blue: 0.125)
    static let surfaceRaised = Color(red: 0.105, green: 0.12, blue: 0.16)
    static let accent = Color(red: 1.0, green: 0.68, blue: 0.16)
    static let accentSoft = Color(red: 1.0, green: 0.83, blue: 0.48)
    static let blue = Color(red: 0.18, green: 0.55, blue: 0.95)
    static let secondaryText = Color.white.opacity(0.66)
    static let divider = Color.white.opacity(0.09)
    static let gradient = LinearGradient(colors: [accent, Color(red: 0.95, green: 0.42, blue: 0.12)], startPoint: .leading, endPoint: .trailing)
    static let backdropGradient = LinearGradient(colors: [.clear, background.opacity(0.55), background], startPoint: .top, endPoint: .bottom)
}

extension View {
    func cineCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(CineTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(CineTheme.divider, lineWidth: 1))
    }
}
