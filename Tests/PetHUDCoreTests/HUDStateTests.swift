import XCTest
@testable import PetHUDCore

final class HUDStateTests: XCTestCase {
    func testThresholdsUseApprovedInclusiveBoundaries() {
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 91),
            .healthy
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 90),
            .normal
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 51),
            .normal
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 50),
            .warning
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 10),
            .warning
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 9),
            .low
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 4),
            .low
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 3),
            .critical
        )
        XCTAssertEqual(
            HUDState.band(forRemainingPercent: 0),
            .critical
        )
    }

    func testFreshSnapshotUsesQuotaState() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 7,
                resetAt: now.addingTimeInterval(172_800),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now.addingTimeInterval(-60)
        )

        XCTAssertEqual(
            HUDState.evaluate(snapshot: snapshot, now: now),
            .quota(snapshot: snapshot, band: .healthy)
        )
    }

    func testSnapshotOlderThanFiveMinutesIsStale() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 50,
                resetAt: now,
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now.addingTimeInterval(-301)
        )

        XCTAssertEqual(
            HUDState.evaluate(snapshot: snapshot, now: now),
            .stale(snapshot: snapshot)
        )
    }

    func testSnapshotOlderThanThirtyMinutesIsOffline() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 50,
                resetAt: now,
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now.addingTimeInterval(-1_801)
        )

        XCTAssertEqual(
            HUDState.evaluate(snapshot: snapshot, now: now),
            .offline
        )
    }
}
