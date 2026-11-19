import XCTest
@testable import SuperHeroBattle

final class ComicLottieTests: XCTestCase {
    func testPlaysAnimationOnlyWhenAssetExistsAndMotionIsAllowed() {
        XCTAssertEqual(
            ComicLottie.decision(assetExists: true, reduceMotion: false),
            .animation
        )
    }

    func testReduceMotionAlwaysFallsBack() {
        XCTAssertEqual(
            ComicLottie.decision(assetExists: true, reduceMotion: true),
            .staticFallback
        )
    }

    func testMissingAssetAlwaysFallsBack() {
        XCTAssertEqual(
            ComicLottie.decision(assetExists: false, reduceMotion: false),
            .staticFallback
        )
    }

    func testMissingAssetWithReduceMotionFallsBack() {
        XCTAssertEqual(
            ComicLottie.decision(assetExists: false, reduceMotion: true),
            .staticFallback
        )
    }

    func testUnknownAssetIsNotPresentInTheBundle() {
        XCTAssertFalse(
            ComicLottie.assetExists(named: "definitely-not-a-registered-lottie-asset"),
            "Un nombre inexistente nunca debe considerarse presente"
        )
    }
}
