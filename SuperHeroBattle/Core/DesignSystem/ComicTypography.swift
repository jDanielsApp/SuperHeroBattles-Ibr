import SwiftUI

/// Relative typography that respects Dynamic Type.
nonisolated enum ComicTypography {
    static let display = Font.system(.largeTitle, design: .rounded).weight(.black)
    static let title = Font.system(.title, design: .rounded).weight(.heavy)
    static let headline = Font.system(.headline, design: .rounded).weight(.bold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded).weight(.semibold)
}
