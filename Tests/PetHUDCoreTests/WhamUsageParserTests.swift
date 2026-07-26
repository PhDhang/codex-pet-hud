import Foundation
import XCTest
@testable import PetHUDCore

final class WhamUsageParserTests: XCTestCase {
    func testParsesWeeklyWindowAndConvertsUnixReset() throws {
        let data = try fixture(named: "wham-usage.json")
        let fetchedAt = Date(timeIntervalSince1970: 1_785_086_400)

        let snapshot = try WhamUsageParser.parse(
            data: data,
            fetchedAt: fetchedAt
        )

        XCTAssertEqual(snapshot.weekly.usedPercent, 41)
        XCTAssertEqual(snapshot.weekly.remainingPercent, 59)
        XCTAssertEqual(snapshot.weekly.windowDurationSeconds, 604_800)
        XCTAssertEqual(
            snapshot.weekly.resetAt,
            Date(timeIntervalSince1970: 1_785_686_400)
        )
        XCTAssertEqual(snapshot.fetchedAt, fetchedAt)
    }

    func testAcceptsFloatingPointAndDefaultsWeeklyDuration() throws {
        let data = try fixture(named: "wham-usage-floating.json")

        let snapshot = try WhamUsageParser.parse(
            data: data,
            fetchedAt: .distantPast
        )

        XCTAssertEqual(snapshot.weekly.usedPercent, 8.5)
        XCTAssertEqual(snapshot.weekly.windowDurationSeconds, 604_800)
    }

    func testAcceptsPrimaryWindowWhenItIsWeekly() throws {
        let data = try fixture(named: "wham-usage-primary-weekly.json")

        let snapshot = try WhamUsageParser.parse(
            data: data,
            fetchedAt: .distantPast
        )

        XCTAssertEqual(snapshot.weekly.usedPercent, 23)
        XCTAssertEqual(snapshot.weekly.remainingPercent, 77)
        XCTAssertEqual(snapshot.weekly.windowDurationSeconds, 604_800)
        XCTAssertEqual(
            snapshot.weekly.resetAt,
            Date(timeIntervalSince1970: 1_785_637_162)
        )
    }

    func testRejectsPrimaryWindowWhenItIsNotWeekly() {
        let data = Data(
            """
            {
              "rate_limit": {
                "primary_window": {
                  "used_percent": 20,
                  "reset_at": 1785091200,
                  "limit_window_seconds": 18000
                }
              }
            }
            """.utf8
        )

        XCTAssertThrowsError(
            try WhamUsageParser.parse(data: data, fetchedAt: .distantPast)
        ) { error in
            XCTAssertEqual(error as? QuotaProviderError, .invalidPayload)
        }
    }

    func testRejectsPayloadWithoutWeeklyWindow() {
        let data = Data(#"{"rate_limit":{}}"#.utf8)

        XCTAssertThrowsError(
            try WhamUsageParser.parse(data: data, fetchedAt: .distantPast)
        ) { error in
            XCTAssertEqual(error as? QuotaProviderError, .invalidPayload)
        }
    }
}
