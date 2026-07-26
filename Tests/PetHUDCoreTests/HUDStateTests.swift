import XCTest
@testable import PetHUDCore

final class HUDStateTests: XCTestCase {
    func testThresholdsUseRemainingPercentage() {
        XCTAssertEqual(HUDState.band(forRemainingPercent: 93), .healthy)
        XCTAssertEqual(HUDState.band(forRemainingPercent: 60), .normal)
        XCTAssertEqual(HUDState.band(forRemainingPercent: 25), .warning)
        XCTAssertEqual(HUDState.band(forRemainingPercent: 8), .low)
        XCTAssertEqual(HUDState.band(forRemainingPercent: 3), .critical)
        XCTAssertEqual(HUDState.band(forRemainingPercent: 0), .critical)
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
