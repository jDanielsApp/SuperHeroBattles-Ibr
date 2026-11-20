import Foundation
@testable import SuperHeroBattle

/// Fake HTTP client with queued responses and recorded requests.
actor FakeHTTPClient: HTTPClient {
    enum Outcome: Sendable {
        case success(HTTPResponse)
        case failure(HTTPClientError)
        case cancellation
    }

    private var outcomes: [Outcome]
    private var recordedRequests: [URLRequest] = []

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func execute(_ request: URLRequest) async throws -> HTTPResponse {
        recordedRequests.append(request)

        guard !outcomes.isEmpty else {
            throw HTTPClientError.transport
        }

        switch outcomes.removeFirst() {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case .cancellation:
            throw CancellationError()
        }
    }

    func requests() -> [URLRequest] {
        recordedRequests
    }
}
