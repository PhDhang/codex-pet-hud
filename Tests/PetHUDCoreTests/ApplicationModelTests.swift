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

    func testNoPetWindowHidesHUD() {
        var model = ApplicationModel()
        _ = model.reduce(.quotaLoaded(snapshot(remaining: 93)))

        let presentation = model.reduce(.petWindowChanged(nil))

        XCTAssertFalse(presentation.showHUD)
    }

    func testHealthyQuotaShowsHUDWithHealthyBand() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 93))
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 93),
                band: .healthy
            )
        )
    }

    func testSameGeometryKeepsHUDVisibleAcrossQuotaTicks() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))
        _ = model.reduce(.quotaLoaded(snapshot(remaining: 93)))

        let presentation = model.reduce(
            .clockTick(
                Date(timeIntervalSince1970: 10_060)
            )
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(presentation.petWindow, petWindow)
    }

    func testCriticalQuotaShowsHUDWithCriticalBand() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 2))
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 2),
                band: .critical
            )
        )
    }

    func testStaleCriticalSnapshotShowsStaleHUD() {
        let current = Date(timeIntervalSince1970: 10_301)
        let staleSnapshot = snapshot(remaining: 2)
        var model = ApplicationModel(now: current)
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(staleSnapshot)
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(
            presentation.hudState,
            .stale(snapshot: staleSnapshot)
        )
    }

    func testAuthenticationFailureKeepsHUDVisible() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaFailed(.authenticationRequired)
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(
            presentation.hudState,
            .authenticationRequired
        )
    }

    func testFreshWarningSnapshotShowsWarningBand() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))
        _ = model.reduce(.quotaLoaded(snapshot(remaining: 2)))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 40))
        )

        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 40),
                band: .warning
            )
        )
    }

    func testLowQuotaShowsHUDWithLowBand() {
        var model = ApplicationModel()
        _ = model.reduce(.petWindowChanged(petWindow))

        let presentation = model.reduce(
            .quotaLoaded(snapshot(remaining: 8))
        )

        XCTAssertTrue(presentation.showHUD)
        XCTAssertEqual(
            presentation.hudState,
            .quota(
                snapshot: snapshot(remaining: 8),
                band: .low
            )
        )
    }

    func testStaleQuotaKeepsHUDVisible() {
        let now = Date(timeIntervalSince1970: 20_000)
        var model = ApplicationModel(now: now)
        _ = model.reduce(.petWindowChanged(petWindow))
        _ = model.reduce(
            .quotaLoaded(
                QuotaSnapshot(
                    weekly: QuotaWindow(
                        usedPercent: 98,
                        resetAt:
                            now.addingTimeInterval(172_800),
                        windowDurationSeconds: 604_800
                    ),
                    fetchedAt: now
                )
            )
        )

        let presentation = model.reduce(
            .clockTick(now.addingTimeInterval(301))
        )

        XCTAssertTrue(presentation.showHUD)
        guard case .stale = presentation.hudState else {
            return XCTFail("Expected stale HUD state")
        }
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
