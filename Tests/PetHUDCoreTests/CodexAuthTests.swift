import Foundation
import XCTest
@testable import PetHUDCore

final class CodexAuthTests: XCTestCase {
    func testLoadsOnlyRequiredTokenFields() throws {
        try withTemporaryDirectory { directory in
            let authURL = directory.appendingPathComponent("auth.json")
            let data = Data(
                """
                {
                  "auth_mode": "chatgpt",
                  "tokens": {
                    "access_token": "TEST_ACCESS_VALUE",
                    "account_id": "TEST_ACCOUNT_VALUE",
                    "id_token": "TEST_ID_VALUE",
                    "refresh_token": "TEST_REFRESH_VALUE"
                  }
                }
                """.utf8
            )
            try data.write(to: authURL)

            let auth = try CodexAuth.load(from: authURL)

            XCTAssertEqual(auth.accessToken, "TEST_ACCESS_VALUE")
            XCTAssertEqual(auth.accountID, "TEST_ACCOUNT_VALUE")
            XCTAssertEqual(String(describing: auth), "CodexAuth(redacted)")
        }
    }

    func testMissingAccessTokenRequiresAuthentication() throws {
        try withTemporaryDirectory { directory in
            let authURL = directory.appendingPathComponent("auth.json")
            try Data(#"{"tokens":{}}"#.utf8).write(to: authURL)

            XCTAssertThrowsError(try CodexAuth.load(from: authURL)) { error in
                XCTAssertEqual(
                    error as? QuotaProviderError,
                    .authenticationRequired
                )
            }
        }
    }
}
