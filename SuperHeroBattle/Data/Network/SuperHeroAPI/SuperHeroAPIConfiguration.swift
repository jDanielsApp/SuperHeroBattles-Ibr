import Foundation

/// Configuración de SuperHeroAPI leída de `Info.plist`.
/// El token nunca se registra ni se incluye en mensajes de error.
nonisolated struct SuperHeroAPIConfiguration: Equatable, Sendable {
    let baseURL: URL
    let token: String

    init?(baseURLString: String, token: String) {
        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let uppercaseToken = trimmedToken.uppercased()

        // Rechaza marcadores de build sin resolver (`$(...)`) y la plantilla
        // de ejemplo. Si el token llega con comillas, también se detecta aquí.
        guard !trimmedToken.isEmpty,
              !trimmedToken.contains("$("),
              !uppercaseToken.hasPrefix("YOUR_"),
              let url = URL(string: trimmedBaseURL),
              url.scheme?.lowercased() == "https",
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        self.baseURL = url
        self.token = trimmedToken
    }

    /// Lee `SuperHeroAPIBaseURL` y `SuperHeroAPIToken` del bundle principal.
    static func live(bundle: Bundle = .main) -> SuperHeroAPIConfiguration? {
        guard let baseURL = bundle.object(forInfoDictionaryKey: "SuperHeroAPIBaseURL") as? String,
              let token = bundle.object(forInfoDictionaryKey: "SuperHeroAPIToken") as? String else {
            return nil
        }

        return SuperHeroAPIConfiguration(baseURLString: baseURL, token: token)
    }
}

extension SuperHeroAPIConfiguration: CustomStringConvertible {
    /// Evita que el token acabe en logs o mensajes de error.
    var description: String {
        "SuperHeroAPIConfiguration(baseURL: \(baseURL.absoluteString), token: <redacted>)"
    }
}
