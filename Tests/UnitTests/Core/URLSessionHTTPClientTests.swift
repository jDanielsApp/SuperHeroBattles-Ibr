import XCTest
@testable import SuperHeroBattle

final class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.set(nil)
        super.tearDown()
    }

    func testExecuteReturnsStatusDataAndHeaders() async throws {
        URLProtocolStub.set(.init(response: { request in
            let url = try XCTUnwrap(request.url)
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: url,
                    statusCode: 201,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["X-Test": "yes"]
                )
            )
            return (response, Data("body".utf8))
        }))

        let response = try await makeClient().execute(try makeRequest(path: "test"))

        XCTAssertEqual(response.statusCode, 201)
        XCTAssertEqual(response.headers["X-Test"], "yes")
        XCTAssertEqual(String(data: response.data, encoding: .utf8), "body")
    }

    func testNonHTTPResponseIsInvalid() async throws {
        URLProtocolStub.set(.init(response: { request in
            let url = try XCTUnwrap(request.url)
            return (
                URLResponse(
                    url: url,
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil
                ),
                Data()
            )
        }))

        do {
            _ = try await makeClient().execute(try makeRequest(path: "test"))
            XCTFail("Expected invalid response")
        } catch let error as HTTPClientError {
            XCTAssertEqual(error, .invalidResponse)
        }
    }

    func testTransportErrorIsMapped() async throws {
        URLProtocolStub.set(.init(response: { _ in
            throw URLError(.notConnectedToInternet)
        }))

        do {
            _ = try await makeClient().execute(try makeRequest(path: "test"))
            XCTFail("Expected transport error")
        } catch let error as HTTPClientError {
            XCTAssertEqual(error, .transport)
        }
    }

    func testCancellationStopsLoadingAndThrowsCancellationError() async throws {
        let started = expectation(description: "request started")
        let stopped = expectation(description: "request stopped")

        URLProtocolStub.set(.init(
            onStart: { started.fulfill() },
            onStop: { stopped.fulfill() }
        ))

        let client = makeClient()
        let request = try makeRequest(path: "slow")
        let task = Task {
            try await client.execute(request)
        }

        await fulfillment(of: [started], timeout: 2)
        task.cancel()
        await fulfillment(of: [stopped], timeout: 2)

        let result = await task.result

        switch result {
        case .success:
            XCTFail("Expected cancellation")
        case .failure(let error):
            XCTAssertTrue(error is CancellationError)
        }
    }

    private func makeClient() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(session: session)
    }

    private func makeRequest(path: String) throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: "https://example.com/\(path)"))
        return URLRequest(url: url)
    }
}
