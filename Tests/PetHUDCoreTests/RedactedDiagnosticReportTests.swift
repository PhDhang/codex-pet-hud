import Foundation
import XCTest
@testable import PetHUDCore

final class RedactedDiagnosticReportTests: XCTestCase {
    private let allowedKeys: Set<String> = [
        "configuration",
        "pet",
        "petWindow",
        "provider",
        "weeklyRemainingPercent",
        "fiveHourRemainingPercent",
        "fiveHourStatus",
    ]

    func testMeasuredReportRoundsPercentagesAndExcludesNormalizedSnapshot() throws {
        let output = try output(
            snapshot: snapshot(
                weeklyUsedPercent: 41.6,
                fiveHourUsedPercent: 36.5
            )
        )

        XCTAssertEqual(output["weeklyRemainingPercent"] as? Int, 58)
        XCTAssertEqual(output["fiveHourRemainingPercent"] as? Int, 64)
        XCTAssertEqual(output["fiveHourStatus"] as? String, "measured")
        assertAllowedAndRedacted(
            output,
            expectedKeys: allowedKeys
        )
    }

    func testMaxReportOmitsFiveHourPercentage() throws {
        let output = try output(
            snapshot: snapshot(weeklyUsedPercent: 41.6)
        )

        XCTAssertEqual(output["fiveHourStatus"] as? String, "max")
        XCTAssertNil(output["fiveHourRemainingPercent"])
        assertAllowedAndRedacted(
            output,
            expectedKeys: allowedKeys.subtracting([
                "fiveHourRemainingPercent",
            ])
        )
    }

    func testUnavailableReportUsesUnavailableStatus() throws {
        let output = try output(
            snapshot: nil,
            provider: "unavailable",
            includeQuota: true
        )

        XCTAssertEqual(output["fiveHourStatus"] as? String, "unavailable")
        XCTAssertNil(output["weeklyRemainingPercent"])
        XCTAssertNil(output["fiveHourRemainingPercent"])
        assertAllowedAndRedacted(
            output,
            expectedKeys: allowedKeys.subtracting([
                "weeklyRemainingPercent",
                "fiveHourRemainingPercent",
            ])
        )
    }

    func testSkippedReportUsesSkippedStatus() throws {
        let output = try output(
            snapshot: nil,
            provider: "skipped",
            includeQuota: false
        )

        XCTAssertEqual(output["fiveHourStatus"] as? String, "skipped")
        XCTAssertNil(output["weeklyRemainingPercent"])
        XCTAssertNil(output["fiveHourRemainingPercent"])
        assertAllowedAndRedacted(
            output,
            expectedKeys: allowedKeys.subtracting([
                "weeklyRemainingPercent",
                "fiveHourRemainingPercent",
            ])
        )
    }

    private func output(
        snapshot: QuotaSnapshot?,
        provider: String = "reachable",
        includeQuota: Bool = true
    ) throws -> [String: Any] {
        let report = RedactedDiagnosticReport(
            configuration: "ok",
            pet: "found",
            petWindow: "found",
            provider: provider,
            snapshot: snapshot,
            includeQuota: includeQuota
        )
        return try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: encoded(report)
            ) as? [String: Any]
        )
    }

    private func assertAllowedAndRedacted(
        _ output: [String: Any],
        expectedKeys: Set<String>
    ) {
        XCTAssertEqual(Set(output.keys), expectedKeys)
        XCTAssertTrue(Set(output.keys).isSubset(of: allowedKeys))
        let encoded = String(
            data: try! JSONSerialization.data(withJSONObject: output),
            encoding: .utf8
        )!
        for forbiddenKey in [
            "resetAt",
            "fetchedAt",
            "usedPercent",
            "windowDurationSeconds",
            "rawPayload",
            "accessToken",
            "account",
            "email",
            "cookie",
            "snapshot",
        ] {
            XCTAssertFalse(encoded.contains(forbiddenKey))
        }
    }

    private func encoded(
        _ report: RedactedDiagnosticReport
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report)
    }

    private func snapshot(
        weeklyUsedPercent: Double,
        fiveHourUsedPercent: Double? = nil
    ) -> QuotaSnapshot {
        let now = Date(timeIntervalSince1970: 1_785_686_400)
        return QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: weeklyUsedPercent,
                resetAt: now.addingTimeInterval(604_800),
                windowDurationSeconds: 604_800
            ),
            fiveHour: fiveHourUsedPercent.map {
                QuotaWindow(
                    usedPercent: $0,
                    resetAt: now.addingTimeInterval(18_000),
                    windowDurationSeconds: 18_000
                )
            },
            fetchedAt: now
        )
    }
}
