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

    func testNilManifestUsesDefaultPetNameAndLowQuotaLabel() {
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
            manifest: nil,
            state: .quota(snapshot: snapshot, band: .low),
            now: now
        )

        XCTAssertEqual(data.petName, "CODEX PET")
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

    func testFractionalHPLabelsMatchRawBand() {
        let samples: [
            (
                remaining: Double,
                label: String,
                band: HPBand
            )
        ] = [
            (9.6, "9.6%", .low),
            (3.4, "3.4%", .low),
            (90.4, "90.4%", .healthy),
            (50.5, "50.5%", .normal),
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

    func testNearBoundaryHPUsesCanonicalBandBarAndLabel() {
        let samples: [
            (
                raw: Double,
                canonical: Double,
                label: String,
                band: HPBand
            )
        ] = [
            (3.04, 3, "3%", .critical),
            (3.99, 3.9, "3.9%", .low),
            (4.09, 4, "4%", .low),
            (9.96, 9.9, "9.9%", .low),
            (10.09, 10, "10%", .warning),
            (50.09, 50, "50%", .warning),
            (50.99, 50.9, "50.9%", .normal),
            (51.09, 51, "51%", .normal),
            (90.09, 90, "90%", .normal),
            (90.99, 90.9, "90.9%", .healthy),
            (91.09, 91, "91%", .healthy),
            (99.96, 99.9, "99.9%", .healthy),
            (100.04, 100, "100%", .healthy),
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

    func testMeasuredMPUsesFiveHourQuota() {
        let now = Date(timeIntervalSince1970: 10_000)
        let snapshot = QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 18,
                resetAt: now.addingTimeInterval(172_800),
                windowDurationSeconds: 604_800
            ),
            fiveHour: QuotaWindow(
                usedPercent: 36.5,
                resetAt: now.addingTimeInterval(7_200),
                windowDurationSeconds: 18_000
            ),
            fetchedAt: now
        )

        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .quota(snapshot: snapshot, band: .normal),
            now: now
        )

        XCTAssertEqual(data.mpText, "63.5%")
        XCTAssertEqual(data.mpFraction, 0.635, accuracy: 0.000_001)
        XCTAssertEqual(data.mpMode, .measured)
        XCTAssertEqual(data.mpDangerLevel, .none)
    }

    func testWeeklyOnlySnapshotUsesUnlimitedMP() {
        let snapshot = snapshot(remaining: 82)
        let data = HUDPresentationData.make(
            petName: "Pet",
            state: .quota(snapshot: snapshot, band: .normal),
            now: snapshot.fetchedAt
        )

        XCTAssertEqual(data.mpText, "MAX")
        XCTAssertEqual(data.mpFraction, 1)
        XCTAssertEqual(data.mpMode, .unlimited)
        XCTAssertEqual(data.mpDangerLevel, .none)
    }

    func testUnavailableStatesUseMPPlaceholderValues() {
        for state in [HUDState.offline, .authenticationRequired] {
            let data = HUDPresentationData.make(
                petName: "Pet",
                state: state,
                now: .distantPast
            )

            XCTAssertEqual(data.mpText, "--")
            XCTAssertEqual(data.mpFraction, 0)
            XCTAssertEqual(data.mpMode, .unavailable)
        }
    }

    func testMeasuredMPDangerLevelsUseIndependentThresholds() {
        let now = Date(timeIntervalSince1970: 10_000)
        let samples: [(remaining: Double, danger: QuotaDangerLevel)] = [
            (9, .low),
            (4, .low),
            (3, .critical),
        ]

        for sample in samples {
            let snapshot = QuotaSnapshot(
                weekly: QuotaWindow(
                    usedPercent: 18,
                    resetAt: now.addingTimeInterval(172_800),
                    windowDurationSeconds: 604_800
                ),
                fiveHour: QuotaWindow(
                    usedPercent: 100 - sample.remaining,
                    resetAt: now.addingTimeInterval(7_200),
                    windowDurationSeconds: 18_000
                ),
                fetchedAt: now
            )
            let data = HUDPresentationData.make(
                petName: "Pet",
                state: .quota(snapshot: snapshot, band: .normal),
                now: now
            )

            XCTAssertEqual(
                data.mpDangerLevel,
                sample.danger,
                "remaining=\(sample.remaining)"
            )
            XCTAssertEqual(data.hpDangerLevel, .none)
        }
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
