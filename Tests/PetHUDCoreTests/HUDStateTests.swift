import XCTest
@testable import PetHUDCore

final class HUDStateTests: XCTestCase {
    func testCanonicalHPFloorsToTenthsAfterClamping() {
        let samples: [(raw: Double, canonical: Double)] = [
            (-0.04, 0),
            (3.04, 3),
            (3.99, 3.9),
            (4.09, 4),
            (9.96, 9.9),
            (10.09, 10),
            (50.09, 50),
            (50.99, 50.9),
            (51.09, 51),
            (90.09, 90),
            (90.99, 90.9),
            (91.09, 91),
            (99.96, 99.9),
            (100, 100),
            (100.04, 100),
        ]

        for sample in samples {
            XCTAssertEqual(
                HPPrecision.canonical(sample.raw),
                sample.canonical,
                accuracy: 0.000_001,
                "raw=\(sample.raw)"
            )
        }
    }

    func testBandsUseCanonicalNearBoundaryValues() {
        let samples: [(raw: Double, band: HPBand)] = [
            (3.04, .critical),
            (3.99, .low),
            (4.09, .low),
            (9.96, .low),
            (10.09, .warning),
            (50.09, .warning),
            (50.99, .normal),
            (51.09, .normal),
            (90.09, .normal),
            (90.99, .healthy),
            (91.09, .healthy),
            (99.96, .healthy),
            (100.04, .healthy),
        ]

        for sample in samples {
            XCTAssertEqual(
                HUDState.band(
                    forRemainingPercent: sample.raw
                ),
                sample.band,
                "raw=\(sample.raw)"
            )
        }
    }

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
