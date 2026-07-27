import Foundation
import XCTest
@testable import PetHUDCore

final class HUDPresentationDataTests: XCTestCase {
    func testBuildsHealthyDungeonNameplateValues() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 7,
                resetAt: now.addingTimeInterval(172_800),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )

        let data = HUDPresentationData.make(
            petName: "一茬",
            state: .quota(snapshot: snapshot, band: .healthy),
            now: now
        )

        XCTAssertEqual(data.petName, "一茬")
        XCTAssertEqual(data.statusLabel, "CODEX · WEEKLY")
        XCTAssertEqual(data.hpText, "93%")
        XCTAssertEqual(data.hpFraction, 0.93, accuracy: 0.001)
        XCTAssertEqual(data.spCellsLit, 5)
        XCTAssertEqual(data.resetText, "2d")
        XCTAssertEqual(data.band, .healthy)
    }

    func testCriticalStateUsesExhaustedLabel() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 98,
                resetAt: now.addingTimeInterval(3_600),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )

        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .quota(snapshot: snapshot, band: .critical),
            now: now
        )

        XCTAssertEqual(data.statusLabel, "EXHAUSTED · SIGNAL CRITICAL")
        XCTAssertEqual(data.hpText, "2%")
        XCTAssertEqual(data.resetText, "1h")
    }

    func testLowStateUsesPanicLabel() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 92,
                resetAt: now.addingTimeInterval(3_600),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )

        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .quota(snapshot: snapshot, band: .low),
            now: now
        )

        XCTAssertEqual(data.statusLabel, "PANIC · QUOTA LOW")
    }

    func testStaleStateKeepsNumericValuesAndBandColor() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 92,
                resetAt: now.addingTimeInterval(3_600),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )

        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .stale(snapshot: snapshot),
            now: now
        )

        XCTAssertEqual(data.hpText, "8%")
        XCTAssertEqual(data.band, .low)
    }

    func testFractionalHPLabelsMatchRawBandAndDistressState() {
        let samples: [
            (
                remaining: Double,
                label: String,
                band: HPBand,
                distress: PetDistressState
            )
        ] = [
            (9.6, "9.6%", .low, .panic),
            (3.4, "3.4%", .low, .panic),
            (90.4, "90.4%", .healthy, .normal),
            (50.5, "50.5%", .normal, .normal),
        ]

        for sample in samples {
            let snapshot = snapshot(remaining: sample.remaining)
            let state = HUDState.evaluate(
                snapshot: snapshot,
                now: snapshot.fetchedAt
            )
            let data = HUDPresentationData.make(
                petName: "Pet",
                state: state,
                now: snapshot.fetchedAt
            )

            XCTAssertEqual(
                data.hpText,
                sample.label,
                "remaining=\(sample.remaining)"
            )
            XCTAssertEqual(
                data.band,
                sample.band,
                "remaining=\(sample.remaining)"
            )
            XCTAssertEqual(
                PetDistressState.evaluate(
                    hudState: state,
                    previous: .normal
                ),
                sample.distress,
                "remaining=\(sample.remaining)"
            )
        }
    }

    func testExactHPBoundariesKeepIntegralLabels() {
        let samples: [
            (remaining: Double, label: String, band: HPBand)
        ] = [
            (3, "3%", .critical),
            (10, "10%", .warning),
            (50, "50%", .warning),
            (90, "90%", .normal),
        ]

        for sample in samples {
            let snapshot = snapshot(remaining: sample.remaining)
            let state = HUDState.evaluate(
                snapshot: snapshot,
                now: snapshot.fetchedAt
            )
            let data = HUDPresentationData.make(
                petName: "Pet",
                state: state,
                now: snapshot.fetchedAt
            )

            XCTAssertEqual(data.hpText, sample.label)
            XCTAssertEqual(data.band, sample.band)
        }
    }

    func testNearBoundaryHPUsesCanonicalBandDistressBarAndLabel() {
        let samples: [
            (
                raw: Double,
                canonical: Double,
                label: String,
                band: HPBand,
                distress: PetDistressState
            )
        ] = [
            (3.04, 3, "3%", .critical, .critical),
            (3.99, 3.9, "3.9%", .low, .panic),
            (4.09, 4, "4%", .low, .panic),
            (9.96, 9.9, "9.9%", .low, .panic),
            (10.09, 10, "10%", .warning, .normal),
            (50.09, 50, "50%", .warning, .normal),
            (50.99, 50.9, "50.9%", .normal, .normal),
            (51.09, 51, "51%", .normal, .normal),
            (90.09, 90, "90%", .normal, .normal),
            (90.99, 90.9, "90.9%", .healthy, .normal),
            (91.09, 91, "91%", .healthy, .normal),
            (99.96, 99.9, "99.9%", .healthy, .normal),
            (100.04, 100, "100%", .healthy, .normal),
        ]

        for sample in samples {
            let snapshot = snapshot(remaining: sample.raw)
            let state = HUDState.evaluate(
                snapshot: snapshot,
                now: snapshot.fetchedAt
            )
            let data = HUDPresentationData.make(
                petName: "Pet",
                state: state,
                now: snapshot.fetchedAt
            )

            XCTAssertEqual(
                snapshot.weekly.remainingPercent,
                sample.canonical,
                accuracy: 0.000_001,
                "raw=\(sample.raw)"
            )
            XCTAssertEqual(data.hpText, sample.label)
            XCTAssertLessThanOrEqual(data.hpText.count, 5)
            XCTAssertEqual(
                data.hpFraction,
                sample.canonical / 100,
                accuracy: 0.000_001
            )
            XCTAssertEqual(data.band, sample.band)
            XCTAssertEqual(
                PetDistressState.evaluate(
                    hudState: state,
                    previous: .normal
                ),
                sample.distress
            )
        }
    }

    func testAuthenticationStateUsesPlaceholderValues() {
        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .authenticationRequired,
            now: .distantPast
        )

        XCTAssertEqual(data.statusLabel, "SIGN IN")
        XCTAssertEqual(data.hpText, "--")
        XCTAssertEqual(data.hpFraction, 0)
        XCTAssertEqual(data.spCellsLit, 0)
    }

    private func snapshot(
        remaining: Double
    ) -> QuotaSnapshot {
        let now = Date(timeIntervalSince1970: 10_000)
        return QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 100 - remaining,
                resetAt: now.addingTimeInterval(3_600),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )
    }
}
