import Foundation

/// SuperHeroAPI configuration read from `Info.plist`.
/// The token is never logged nor included in error messages.
nonisolated struct SuperHeroAPIConfiguration: Equatable, Sendable {
    let baseURL: URL
    let token: String

    init?(baseURLString: String, token: String) {
        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let uppercaseToken = trimmedToken.uppercased()

        // Rejects unresolved build markers (`$(...)`) and the example template.
        // A token wrapped in quotes is also caught here.
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

    /// Reads `SuperHeroAPIBaseURL` and `SuperHeroAPIToken` from the main bundle.
    static func live(bundle: Bundle = .main) -> SuperHeroAPIConfiguration? {
        guard let baseURL = bundle.object(forInfoDictionaryKey: "SuperHeroAPIBaseURL") as? String,
              let token = bundle.object(forInfoDictionaryKey: "SuperHeroAPIToken") as? String else {
            return nil
        }

        return SuperHeroAPIConfiguration(baseURLString: baseURL, token: token)
    }
}

extension SuperHeroAPIConfiguration: CustomStringConvertible {
    /// Prevents the token from ending up in logs or error messages.
    var description: String {
        "SuperHeroAPIConfiguration(baseURL: \(baseURL.absoluteString), token: <redacted>)"
    }
}
