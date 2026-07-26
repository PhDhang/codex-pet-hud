import Foundation

public struct CodexAuth: Sendable {
    public let accessToken: String
    public let accountID: String?

    private struct AuthDocument: Decodable {
        struct Tokens: Decodable {
            let accessToken: String?
            let accountID: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case accountID = "account_id"
            }
        }

        let tokens: Tokens?
    }

    public static func load(
        from url: URL
    ) throws -> CodexAuth {
        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(
                AuthDocument.self,
                from: data
            )
            guard
                let accessToken = document.tokens?.accessToken,
                !accessToken.isEmpty
            else {
                throw QuotaProviderError.authenticationRequired
            }
            return CodexAuth(
                accessToken: accessToken,
                accountID: document.tokens?.accountID
            )
        } catch let error as QuotaProviderError {
            throw error
        } catch {
            throw QuotaProviderError.authenticationRequired
        }
    }
}

extension CodexAuth: CustomStringConvertible {
    public var description: String {
        "CodexAuth(redacted)"
    }
}

