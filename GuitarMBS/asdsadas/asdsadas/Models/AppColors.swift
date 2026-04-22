import SwiftUI

extension Color {
    /// App-wide consistent dark background
    static let appBackground = Color(white: 0.06)
    /// Slightly lighter surface for cards
    static let appSurface = Color(white: 0.10)
    /// App accent
    static let appAccent = Color.orange
}

extension LinearGradient {
    /// Standard dark gradient used across all tabs
    static let appBackground = LinearGradient(
        colors: [Color(white: 0.08), Color(white: 0.04)],
        startPoint: .top,
        endPoint: .bottom
    )
}
