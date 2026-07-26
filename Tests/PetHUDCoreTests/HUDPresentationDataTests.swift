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

        XCTAssertEqual(data.statusLabel, "EXHAUSTED")
        XCTAssertEqual(data.hpText, "2%")
        XCTAssertEqual(data.resetText, "1h")
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
}
