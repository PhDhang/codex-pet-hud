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
}

