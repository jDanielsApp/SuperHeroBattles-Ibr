import XCTest
@testable import SuperHeroBattle

final class NarrationErrorClassifierTests: XCTestCase {
    func testClassifiesGuardrailByDescription() {
        let error = NSError(domain: "FoundationModels", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "guardrailViolation: may contain sensitive or unsafe content"
        ])

        let classified = NarrationErrorClassifier.classify(error)

        guard case NarrationError.guardrail = classified else {
            return XCTFail("Debería clasificarse como guardrail: \(classified)")
        }
    }

    func testPassesThroughUnknownErrors() {
        let error = NSError(domain: "TestDomain", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "something else went wrong"
        ])

        let classified = NarrationErrorClassifier.classify(error)
        let nsError = classified as NSError

        XCTAssertEqual(nsError.domain, "TestDomain")
        XCTAssertEqual(nsError.code, 42)
    }

    func testPreservesCancellation() {
        let classified = NarrationErrorClassifier.classify(CancellationError())

        XCTAssertTrue(classified is CancellationError)
    }

    func testPassesThroughNarrationErrors() {
        let classified = NarrationErrorClassifier.classify(NarrationError.timeout)

        XCTAssertEqual(classified as? NarrationError, .timeout)
    }

    func testDetectsGuardrailByPattern() {
        let guardrailError = NSError(domain: "FoundationModels", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "guardrailViolation triggered"
        ])
        let otherError = NSError(domain: "FoundationModels", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "timeout exceeded"
        ])

        XCTAssertTrue(NarrationErrorClassifier.isGuardrail(guardrailError))
        XCTAssertFalse(NarrationErrorClassifier.isGuardrail(otherError))
    }
}
