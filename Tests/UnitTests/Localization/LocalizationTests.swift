import XCTest
@testable import SuperHeroBattle

final class LocalizationTests: XCTestCase {
    func testEnglishAndSpanishHaveTheSameKeys() throws {
        let english = try localizationKeys(for: "en")
        let spanish = try localizationKeys(for: "es")

        XCTAssertFalse(english.isEmpty)
        XCTAssertEqual(english, spanish)
    }

    func testEveryLocalizableKeyHasATranslation() throws {
        let english = try localizationKeys(for: "en")
        let missingKeys = LocalizableStringKey.allCases
            .map(\.rawValue)
            .filter { !english.contains($0) }

        XCTAssertTrue(missingKeys.isEmpty, "Missing translations: \(missingKeys)")
    }

    private func localizationKeys(for language: String) throws -> Set<String> {
        let bundle = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
        let lprojURL = URL(fileURLWithPath: bundle)
        let stringsURL = lprojURL.appendingPathComponent("Localizable.strings")
        let data = try Data(contentsOf: stringsURL)

        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let dictionary = try XCTUnwrap(plist as? [String: String])
        return Set(dictionary.keys)
    }
}
