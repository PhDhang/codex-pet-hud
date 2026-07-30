import Foundation
import XCTest
@testable import PetHUDCore

private final class TestURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler:
        ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(
                self,
                didFailWithError: QuotaProviderError.unavailable
            )
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class WhamUsageClientTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.handler = nil
        super.tearDown()
    }

    func testBuildsReadOnlyAuthenticatedRequest() async throws {
        try await withTemporaryAuth { authURL in
            let session = makeSession()
            TestURLProtocol.handler = { request in
                XCTAssertEqual(
                    request.url?.absoluteString,
                    "https://chatgpt.com/backend-api/wham/usage"
                )
                XCTAssertEqual(request.httpMethod, "GET")
                XCTAssertEqual(
                    request.value(forHTTPHeaderField: "Authorization"),
                    ["Bearer", "TEST_ACCESS_VALUE"].joined(
                        separator: " "
                    )
                )
                XCTAssertEqual(
                    request.value(
                        forHTTPHeaderField: "ChatGPT-Account-Id"
                    ),
                    "TEST_ACCOUNT_VALUE"
                )
                return (
                    HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!,
                    try fixture(named: "wham-usage-five-hour.json")
                )
            }

            let client = WhamUsageClient(
                authURL: authURL,
                session: session,
                now: { Date(timeIntervalSince1970: 1_785_086_400) }
            )

            let snapshot = try await client.fetch()

            XCTAssertEqual(snapshot.weekly.remainingPercent, 82)
            XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 63.5)
        }
    }

    func testMapsUnauthorizedResponseToAuthenticationRequired() async throws {
        try await withTemporaryAuth { authURL in
            let session = makeSession()
            TestURLProtocol.handler = { request in
                (
                    HTTPURLResponse(
                        url: request.url!,
                        statusCode: 401,
                        httpVersion: nil,
                        headerFields: nil
                    )!,
                    Data()
                )
            }
            let client = WhamUsageClient(
                authURL: authURL,
                session: session,
                now: Date.init
            )

            do {
                _ = try await client.fetch()
                XCTFail("Expected authentication failure")
            } catch {
                XCTAssertEqual(
                    error as? QuotaProviderError,
                    .authenticationRequired
                )
                XCTAssertFalse(
                    String(describing: error)
                        .contains("TEST_ACCESS_VALUE")
                )
            }
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func withTemporaryAuth<T>(
        _ body: (URL) async throws -> T
    ) async throws -> T {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let authURL = directory.appendingPathComponent("auth.json")
        try Data(
            """
            {
              "tokens": {
                "access_token": "TEST_ACCESS_VALUE",
                "account_id": "TEST_ACCOUNT_VALUE"
              }
            }
            """.utf8
        ).write(to: authURL)
        return try await body(authURL)
    }
}
