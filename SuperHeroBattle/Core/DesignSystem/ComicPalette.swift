import SwiftUI

/// Base colors of the comic book visual identity.
nonisolated enum ComicPalette {
    static let ink = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let midnight = Color(red: 0.07, green: 0.10, blue: 0.20)
    static let paper = Color(red: 0.97, green: 0.95, blue: 0.88)
    static let yellow = Color(red: 1.00, green: 0.82, blue: 0.16)
    static let red = Color(red: 0.91, green: 0.17, blue: 0.22)
    static let blue = Color(red: 0.12, green: 0.45, blue: 0.92)
    static let teal = Color(red: 0.00, green: 0.70, blue: 0.68)
    static let panelBorder = Color.black.opacity(0.85)
}

/// Distinct colors for the two teams.
nonisolated enum TeamPalette {
    static let teamA = Color(red: 0.93, green: 0.24, blue: 0.18)
    static let teamB = Color(red: 0.10, green: 0.48, blue: 0.95)
}
