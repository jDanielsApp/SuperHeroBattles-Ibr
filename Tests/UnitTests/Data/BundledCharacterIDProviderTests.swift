import XCTest
@testable import SuperHeroBattle

final class BundledCharacterIDProviderTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("shb-ids-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    func testLoadsSortsAndDeduplicatesIDs() throws {
        let url = try write("[3, 1, 2, 1]")
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertEqual(try provider.characterIDs(), ["1", "2", "3"])
    }

    func testMissingResourceThrows() {
        let provider = BundledCharacterIDProvider(fileURL: nil)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .resourceMissing)
        }
    }

    func testInvalidJSONThrows() throws {
        let url = try write("{ not json }")
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .invalidFormat)
        }
    }

    func testNonIntegerValuesThrow() throws {
        let url = try write(#"["1", "2"]"#)
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .invalidFormat)
        }
    }

    func testZeroOrNegativeIDsThrow() throws {
        let url = try write("[0, 1, 2]")
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .invalidFormat)
        }
    }

    func testEmptyListThrows() throws {
        let url = try write("[]")
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .empty)
        }
    }

    func testUnreadableFileThrows() {
        let url = directory.appendingPathComponent("missing.json")
        let provider = BundledCharacterIDProvider(fileURL: url)

        XCTAssertThrowsError(try provider.characterIDs()) { error in
            XCTAssertEqual(error as? CharacterIDProviderError, .unreadable)
        }
    }

    private func write(_ contents: String) throws -> URL {
        let url = directory.appendingPathComponent("ids-\(UUID().uuidString).json")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
