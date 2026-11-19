import Foundation

/// Lee `data/character_ids.json` desde el bundle de la app.
///
/// El archivo contiene únicamente una lista de enteros. El proveedor la valida,
/// la ordena y la convierte a `String` para el resto de la aplicación.
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
