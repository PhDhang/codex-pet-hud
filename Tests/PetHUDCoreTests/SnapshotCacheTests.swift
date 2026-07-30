import Darwin
import Foundation
import XCTest
@testable import PetHUDCore

final class SnapshotCacheTests: XCTestCase {
    func testRoundTripsNormalizedSnapshotWithoutCredentials() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("snapshot.json")
            let cache = SnapshotCache(url: url)
            let snapshot = QuotaSnapshot(
                weekly: QuotaWindow(
                    usedPercent: 41,
                    resetAt: Date(timeIntervalSince1970: 1_785_686_400),
                    windowDurationSeconds: 604_800
                ),
                fiveHour: QuotaWindow(
                    usedPercent: 36.5,
                    resetAt: Date(timeIntervalSince1970: 1_785_402_000),
                    windowDurationSeconds: 18_000
                ),
                fetchedAt: Date(timeIntervalSince1970: 1_785_086_400)
            )

            try cache.save(snapshot)

            XCTAssertEqual(try cache.load(), snapshot)
            let text = try String(contentsOf: url, encoding: .utf8)
            XCTAssertTrue(text.contains("usedPercent"))
            XCTAssertFalse(text.contains("access_token"))
            XCTAssertFalse(text.contains("account_id"))
            XCTAssertFalse(text.contains("Authorization"))
            let attributes = try FileManager.default.attributesOfItem(
                atPath: url.path
            )
            let mode = try XCTUnwrap(
                attributes[.posixPermissions] as? NSNumber
            )
            XCTAssertEqual(mode.intValue & 0o777, 0o600)
        }
    }

    func testMissingCacheReturnsNil() throws {
        try withTemporaryDirectory { directory in
            let cache = SnapshotCache(
                url: directory.appendingPathComponent("missing.json")
            )

            XCTAssertNil(try cache.load())
        }
    }

    func testDecodesLegacySnapshotWithoutFiveHourWindow() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("snapshot.json")
            let cache = SnapshotCache(url: url)
            let legacy = Data(
                """
                {
                  "weekly": {
                    "usedPercent": 18,
                    "resetAt": -978307200,
                    "windowDurationSeconds": 604800
                  },
                  "fetchedAt": -978307200
                }
                """.utf8
            )
            try legacy.write(to: url)

            let loaded = try XCTUnwrap(cache.load())

            XCTAssertNil(loaded.fiveHour)
        }
    }
}
