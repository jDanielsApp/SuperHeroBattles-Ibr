import Foundation

/// Normaliza las búsquedas para que la API y la caché compartan criterios.
nonisolated enum SearchQueryNormalizer {
    /// Recorta y colapsa espacios sin alterar mayúsculas ni acentos.
    /// Es el texto que se envía a la API.
    static func normalizedQuery(_ raw: String) -> String {
        raw
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    /// Clave de caché estable: sin mayúsculas ni diacríticos.
    /// Así "Bátman", "batman" y "  BATMÁN  " comparten entrada.
    static func cacheKey(_ raw: String) -> String {
        normalizedQuery(raw)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}
