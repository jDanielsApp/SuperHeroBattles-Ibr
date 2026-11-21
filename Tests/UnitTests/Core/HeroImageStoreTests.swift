import UIKit
import XCTest
@testable import SuperHeroBattle

final class HeroImageStoreTests: XCTestCase {
    private let url = URL(string: "https://example.com/hero.png")!

    /// 1×1 transparent PNG: the smallest data `UIImage(data:)` decodes.
    private let pngData = Data(
        base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    )!

    // MARK: - Coalescing

    func testConcurrentRequestsShareOneDownload() async {
        let gate = Gate()
        let spy = FetchSpy(results: [.success(pngData)])
        let store = HeroImageStore { url in
            await gate.arriveAndAwaitRelease()
            return try await spy.next(url)
        }

        // Local copy: `async let` must not capture the test instance.
        let heroURL = url

        async let first: UIImage? = store.image(for: heroURL)
        async let second: UIImage? = store.image(for: heroURL)

        // Both callers are served by the single parked download.
        await gate.waitForArrivals(1)
        await gate.release()

        let firstImage = await first
        let secondImage = await second

        XCTAssertNotNil(firstImage)
        XCTAssertNotNil(secondImage)
        let calls = await spy.callURLs
        XCTAssertEqual(calls, [heroURL], "Dos peticiones concurrentes deben compartir una sola descarga")
    }

    // MARK: - Cache

    func testSecondRequestHitsTheCacheWithoutDownloading() async {
        let spy = FetchSpy(results: [.success(pngData)])
        let store = HeroImageStore { url in try await spy.next(url) }

        let first = await store.image(for: url)
        let second = await store.image(for: url)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        let calls = await spy.callURLs
        XCTAssertEqual(calls, [url], "La segunda petición debe servirse desde la caché")
    }

    // MARK: - Failures

    func testFailedDownloadIsNotCachedAndRetries() async {
        let spy = FetchSpy(results: [.failure, .success(pngData)])
        let store = HeroImageStore { url in try await spy.next(url) }

        let first = await store.image(for: url)
        XCTAssertNil(first, "Una descarga fallida no debe producir imagen")

        // The failure was not cached: the next call retries and succeeds.
        let second = await store.image(for: url)
        XCTAssertNotNil(second)
        let calls = await spy.callURLs
        XCTAssertEqual(calls.count, 2, "El fallo no debe cachearse: el reintento descarga de nuevo")
    }

    func testUndecodableDataYieldsNoImageAndIsNotCached() async {
        let spy = FetchSpy(results: [.success(Data("not an image".utf8))])
        let store = HeroImageStore { url in try await spy.next(url) }

        let first = await store.image(for: url)
        XCTAssertNil(first)

        let second = await store.image(for: url)
        XCTAssertNil(second)
        let calls = await spy.callURLs
        XCTAssertEqual(calls.count, 2, "Los datos indecodificables no deben cachearse")
    }
}

// MARK: - Test doubles

private enum FetchResult {
    case success(Data)
    case failure
}

private actor FetchSpy {
    private var results: [FetchResult]
    private(set) var callURLs: [URL] = []

    init(results: [FetchResult]) {
        self.results = results
    }

    func next(_ url: URL) throws -> Data {
        callURLs.append(url)
        let result = results.isEmpty ? .failure : results.removeFirst()

        switch result {
        case .success(let data):
            return data
        case .failure:
            throw FetchError.network
        }
    }

    private enum FetchError: Error {
        case network
    }
}

/// Blocks the first `arriveAndAwaitRelease` callers until `release`.
/// Lets tests park a download deterministically.
private actor Gate {
    private(set) var arrivals = 0
    private var isReleased = false
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []
    private var arrivalWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func arriveAndAwaitRelease() async {
        arrivals += 1
        arrivalWaiters
            .filter { $0.count <= arrivals }
            .forEach { $0.continuation.resume() }
        arrivalWaiters.removeAll { $0.count <= arrivals }

        if !isReleased {
            await withCheckedContinuation { releaseWaiters.append($0) }
        }
    }

    func waitForArrivals(_ count: Int) async {
        guard arrivals < count else { return }
        await withCheckedContinuation { arrivalWaiters.append((count, $0)) }
    }

    func release() {
        isReleased = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters = []
    }
}
