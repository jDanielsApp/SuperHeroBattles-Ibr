import Foundation
@testable import SuperHeroBattle

/// Cliente HTTP falso con respuestas en cola y peticiones registradas.
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
