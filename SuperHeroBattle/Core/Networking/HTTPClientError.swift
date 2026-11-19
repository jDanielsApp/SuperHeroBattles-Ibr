import Foundation

nonisolated enum HTTPClientError: Error, Equatable, Sendable {
    /// Error de conexión, DNS, TLS o timeout. La UI lo traduce a "sin conexión".
    case transport
    /// La respuesta no es un `HTTPURLResponse` válido.
    case invalidResponse
}
