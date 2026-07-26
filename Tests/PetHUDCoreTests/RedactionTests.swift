import XCTest
@testable import PetHUDCore

final class RedactionTests: XCTestCase {
    func testRemovesBearerTokensEmailsAndAccountIdentifiers() {
        let testBearer = ["Bearer", "TEST_REDACTION_VALUE"]
            .joined(separator: " ")
        let testEmail = ["person", "example.invalid"]
            .joined(separator: "@")
        let input = """
        Authorization: \(testBearer)
        user=\(testEmail)
        account_id=TEST_ACCOUNT_VALUE
        """

        let sanitized = Redaction.sanitize(input)

        XCTAssertFalse(sanitized.contains("TEST_REDACTION_VALUE"))
        XCTAssertFalse(sanitized.contains(testEmail))
        XCTAssertFalse(sanitized.contains("TEST_ACCOUNT_VALUE"))
        XCTAssertTrue(sanitized.contains("[REDACTED]"))
    }

    func testLeavesNormalDiagnosticTextReadable() {
        XCTAssertEqual(
            Redaction.sanitize(
                "petWindow=found weeklyRemainingPercent=59"
            ),
            "petWindow=found weeklyRemainingPercent=59"
        )
    }
}
