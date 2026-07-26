import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class ApplicationModelTests: XCTestCase {
    private let petWindow = WindowDescriptor(
        owner: "ChatGPT",
        name: "Codex Pet Mascot Effect",
        layer: 2,
        bounds: CGRect(x: 24, y: 775, width: 243, height: 252),
        ownerPID: 1,
        windowID: 11
    )

    func testNoPetWindowHidesBothPanels() {
        var model = ApplicationModel()
        _ = model.reduce(.quotaLoaded(snapshot(remaining: 93)))

        let presentation = model.reduce(.petWindowChanged(nil))

        XCTAssertFalse(presentation.showNameplate)
        XCTAssertFalse(presentation.showCriticalEffect)
    }

    func testHealthyQuotaShowsOnlyNameplate() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 93))
        )

        XCTAssertTrue(presentation.showNameplate)
        XCTAssertFalse(presentation.showCriticalEffect)
        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 93),
                band: .healthy
            )
        )
    }

    func testCriticalQuotaShowsCriticalEffect() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 2))
        )

        XCTAssertTrue(presentation.showNameplate)
        XCTAssertTrue(presentation.showCriticalEffect)
    }

    func testAuthenticationFailureKeepsNameplateVisible() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaFailed(.authenticationRequired)
        )

        XCTAssertTrue(presentation.showNameplate)
        XCTAssertFalse(presentation.showCriticalEffect)
        XCTAssertEqual(
            presentation.hudState,
            .authenticationRequired
        )
    }

    func testFreshHealthySnapshotClearsCriticalEffect() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))
        _ = model.reduce(.quotaLoaded(snapshot(remaining: 2)))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 40))
        )

        XCTAssertFalse(presentation.showCriticalEffect)
        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 40),
                band: .warning
            )
        )
    }

    private func snapshot(
        remaining: Double
    ) -> QuotaSnapshot {
        QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 100 - remaining,
                resetAt: Date(timeIntervalSince1970: 20_000),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: Date(timeIntervalSince1970: 10_000)
        )
    }
}
