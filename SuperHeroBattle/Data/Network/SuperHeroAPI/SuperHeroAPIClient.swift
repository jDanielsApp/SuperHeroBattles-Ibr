import Foundation

/// Cliente de SuperHeroAPI. Devuelve DTOs y traduce HTTP/decoding a errores de dominio.
/// Nunca registra la URL completa porque contiene el token.
nonisolated struct SuperHeroAPIClient: Sendable {
    private let configuration: SuperHeroAPIConfiguration
    private let httpClient: any HTTPClient

    init(configuration: SuperHeroAPIConfiguration, httpClient: any HTTPClient) {
        self.configuration = configuration
        self.httpClient = httpClient
    }

    func fetchHeroes(query: String) async throws -> [HeroDTO] {
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)
        let data = try await execute(endpoint.search(query: query))

        let response: SearchResponseDTO
        do {
            response = try JSONDecoder().decode(SearchResponseDTO.self, from: data)
        } catch {
            throw apiError(from: data) ?? .decoding
        }

        if response.response?.lowercased() == "error" {
            throw classifiedAPIError(message: response.error)
        }

        return response.results ?? []
    }

    func fetchHero(id: String) async throws -> HeroDTO {
        let endpoint = SuperHeroAPIEndpoint(configuration: configuration)
        let data = try await execute(endpoint.hero(id: id))

        let hero: HeroDTO
        do {
            hero = try JSONDecoder().decode(HeroDTO.self, from: data)
        } catch {
            throw apiError(from: data) ?? .decoding
        }

        if hero.response?.lowercased() == "error" {
            throw classifiedAPIError(message: hero.error)
        }

        return hero
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let response: HTTPResponse

        do {
            response = try await httpClient.execute(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as HTTPClientError {
            throw map(error)
        } catch {
            throw HeroRepositoryError.transport
        }

        try validate(statusCode: response.statusCode)
        return response.data
    }

    private func validate(statusCode: Int) throws {
        switch statusCode {
        case 200...299:
            return
        case 401, 403:
            throw HeroRepositoryError.unauthorized
        case 404:
            throw HeroRepositoryError.notFound
        case 429:
            throw HeroRepositoryError.rateLimited
        default:
            throw HeroRepositoryError.server(status: statusCode)
        }
    }

    private func map(_ error: HTTPClientError) -> HeroRepositoryError {
        switch error {
        case .transport:
            return .transport
        case .invalidResponse:
            return .invalidResponse
        }
    }

    private func apiError(from data: Data) -> HeroRepositoryError? {
        guard let error = try? JSONDecoder().decode(APIErrorDTO.self, from: data),
              error.response?.lowercased() == "error" else {
            return nil
        }

        return classifiedAPIError(message: error.error)
    }

    /// La API puede devolver errores de autenticación con HTTP 200.
    /// Se clasifican como `unauthorized` para no mostrarlos como fallo genérico.
    private func classifiedAPIError(message: String?) -> HeroRepositoryError {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else {
            return .api(message: "unknown")
        }

        let lowercased = message.lowercased()
        let authenticationMarkers = [
            "access denied",
            "invalid api",
            "invalid token",
            "unauthorized",
            "forbidden",
            "api key",
        ]

        if authenticationMarkers.contains(where: { lowercased.contains($0) }) {
            return .unauthorized
        }

        return .api(message: message)
    }
}
