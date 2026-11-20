import Foundation

/// Normalizes search queries so the API and the cache share the same criteria.
nonisolated enum SearchQueryNormalizer {
    /// Trims and collapses whitespace without changing case or accents.
    /// This is the text sent to the API.
    static func normalizedQuery(_ raw: String) -> String {
        raw
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    /// Stable cache key: no case and no diacritics.
    /// This way "Bátman", "batman", and "  BATMÁN  " share one entry.
    static func cacheKey(_ raw: String) -> String {
        normalizedQuery(raw)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}
