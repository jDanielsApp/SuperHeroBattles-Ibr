import UIKit

/// Loads hero images over the network and keeps them in memory.
nonisolated protocol HeroImageLoading: Sendable {
    /// The image for `url`, downloaded when necessary.
    ///
    /// `nil` when the download fails or yields no decodable image.
    /// Failures are not cached: a later call retries the download.
    /// The call is never cancelled by the loader itself; a view that
    /// goes away simply stops caring about the result.
    func image(for url: URL) async -> UIImage?
}

/// Shared in-memory hero image cache with download coalescing.
///
/// One download per URL: concurrent requests await the same in-flight
/// task, and that task is owned by the store, so a view going away —
/// for example when a new search rebuilds the list — never cancels a
/// download other rows still need. Successes land in the cache (evicted
/// automatically under memory pressure), so repeated searches render
/// instantly instead of downloading again.
actor HeroImageStore: HeroImageLoading {
    /// Bounded cache: enough for a long browsing session of thumbnails.
    private static let cacheCountLimit = 400

    private let fetch: @Sendable (URL) async throws -> Data
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    init(fetch: @escaping @Sendable (URL) async throws -> Data = HeroImageStore.urlSessionFetch) {
        self.fetch = fetch
        cache.countLimit = Self.cacheCountLimit
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }

        if let flight = inFlight[url] {
            return await flight.value
        }

        let flight = Task { await self.download(url) }
        inFlight[url] = flight
        return await flight.value
    }

    /// Number of downloads currently running. Useful as a debugging
    /// aid and for deterministic tests.
    var activeDownloadCount: Int {
        inFlight.count
    }

    private func download(_ url: URL) async -> UIImage? {
        defer { inFlight[url] = nil }

        do {
            let data = try await fetch(url)
            guard let image = UIImage(data: data) else { return nil }
            cache.setObject(image, forKey: url as NSURL)
            return image
        } catch {
            return nil
        }
    }

    /// Default network fetch. The status code is validated before the
    /// body is used, mirroring the project's HTTP discipline.
    private static func urlSessionFetch(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw HeroImageFetchError.invalidStatus
        }
        return data
    }
}

private enum HeroImageFetchError: Error {
    case invalidStatus
}
