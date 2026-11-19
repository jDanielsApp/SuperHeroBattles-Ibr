import Foundation

/// Stub de `URLProtocol` para probar `URLSessionHTTPClient` sin red.
nonisolated final class URLProtocolStub: URLProtocol {
    struct Stub {
        var onStart: (() -> Void)?
        var response: ((URLRequest) throws -> (URLResponse, Data))?
        var onStop: (() -> Void)?
    }

    nonisolated(unsafe) private static var currentStub: Stub?
    private static let lock = NSLock()

    static func set(_ stub: Stub?) {
        lock.lock()
        defer { lock.unlock() }
        currentStub = stub
    }

    private static func stub() -> Stub? {
        lock.lock()
        defer { lock.unlock() }
        return currentStub
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let stub = Self.stub() else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        stub.onStart?()

        guard let response = stub.response else {
            return
        }

        do {
            let (urlResponse, data) = try response(request)
            client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        Self.stub()?.onStop?()
    }
}
