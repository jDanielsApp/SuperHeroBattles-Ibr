import Foundation

/// Builds GET requests for SuperHeroAPI.
/// The query is encoded as a path component using `URL.appending(component:)`.
nonisolated struct SuperHeroAPIEndpoint: Sendable {
    private let configuration: SuperHeroAPIConfiguration

    init(configuration: SuperHeroAPIConfiguration) {
        self.configuration = configuration
    }

    func search(query: String) -> URLRequest {
        request(pathComponents: ["search", query])
    }

    func hero(id: String) -> URLRequest {
        request(pathComponents: [id])
    }

    private func request(pathComponents: [String]) -> URLRequest {
        var url = configuration.baseURL
        url = url.appending(component: configuration.token)
        for component in pathComponents {
            url = url.appending(component: component)
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
}
