import Foundation

/// Respuesta HTTP normalizada para desacoplar la capa de datos de `URLSession`.
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

/// Cliente HTTP mínimo. Permite sustituirlo por un fake en los tests.
nonisolated protocol HTTPClient: Sendable {
    func execute(_ request: URLRequest) async throws -> HTTPResponse
}
