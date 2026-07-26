import Foundation

public protocol QuotaProviding: Sendable {
    func fetch() async throws -> QuotaSnapshot
}

public struct WhamUsageClient: QuotaProviding {
    public let authURL: URL
    public let session: URLSession
    public let now: @Sendable () -> Date

    public init(
        authURL: URL,
        session: URLSession = .shared,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.authURL = authURL
        self.session = session
        self.now = now
    }

    public func fetch() async throws -> QuotaSnapshot {
        let auth = try CodexAuth.load(from: authURL)
        var request = URLRequest(
            url: URL(
                string: "https://chatgpt.com/backend-api/wham/usage"
            )!
        )
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(auth.accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        if let accountID = auth.accountID {
            request.setValue(
                accountID,
                forHTTPHeaderField: "ChatGPT-Account-Id"
            )
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw QuotaProviderError.unavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuotaProviderError.invalidResponse
        }
        if httpResponse.statusCode == 401 ||
            httpResponse.statusCode == 403
        {
            throw QuotaProviderError.authenticationRequired
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw QuotaProviderError.httpStatus(
                httpResponse.statusCode
            )
        }

        return try WhamUsageParser.parse(
            data: data,
            fetchedAt: now()
        )
    }
}
