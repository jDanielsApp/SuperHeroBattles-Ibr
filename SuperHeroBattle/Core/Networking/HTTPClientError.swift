import Foundation

nonisolated enum HTTPClientError: Error, Equatable, Sendable {
    /// Connection, DNS, TLS, or timeout error. The UI presents it as "no connection".
    case transport
    /// The response is not a valid `HTTPURLResponse`.
    case invalidResponse
}
