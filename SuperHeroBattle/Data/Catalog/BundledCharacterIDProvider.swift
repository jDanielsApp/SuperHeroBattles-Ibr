import Foundation

/// Reads `data/character_ids.json` from the app bundle.
///
/// The file contains only a list of integers. The provider validates it,
/// sorts it, and converts it to `String` for the rest of the app.
nonisolated struct BundledCharacterIDProvider: CharacterIDProviding {
    static let resourceName = "character_ids"

    private let fileURL: URL?

    init(bundle: Bundle = .main, resourceName: String = BundledCharacterIDProvider.resourceName) {
        self.fileURL = bundle.url(forResource: resourceName, withExtension: "json")
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    func characterIDs() throws -> [String] {
        guard let fileURL else {
            throw CharacterIDProviderError.resourceMissing
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw CharacterIDProviderError.unreadable
        }

        let rawIDs: [Int]
        do {
            rawIDs = try JSONDecoder().decode([Int].self, from: data)
        } catch {
            throw CharacterIDProviderError.invalidFormat
        }

        guard rawIDs.allSatisfy({ $0 > 0 }) else {
            throw CharacterIDProviderError.invalidFormat
        }

        let uniqueIDs = Array(Set(rawIDs)).sorted()
        guard !uniqueIDs.isEmpty else {
            throw CharacterIDProviderError.empty
        }

        return uniqueIDs.map { String($0) }
    }
}
