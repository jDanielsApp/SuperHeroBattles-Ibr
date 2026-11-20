import Foundation

/// Normalized HTTP response that decouples the data layer from `URLSession`.
nonisolated struct HTTPResponse: Sendable, Equatable {
    let data: Data
    let statusCode: Int
    let headers: [String: String]

    init(data: Data, statusCode: Int, headers: [String: String] = [:]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}

/// Minimal HTTP client that tests can replace with a fake.
nonisolated protocol HTTPClient: Sendable {
    func execute(_ request: URLRequest) async throws -> HTTPResponse
}
