import Foundation

/// Implementación de `HTTPClient` basada en `URLSession` y `async/await`.
nonisolated final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func execute(_ request: URLRequest) async throws -> HTTPResponse {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }

            var headers: [String: String] = [:]
            for (key, value) in httpResponse.allHeaderFields {
                guard let key = key as? String, let value = value as? String else { continue }
                headers[key] = value
            }

            return HTTPResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                headers: headers
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as HTTPClientError {
            throw error
        } catch {
            throw HTTPClientError.transport
        }
    }
}
