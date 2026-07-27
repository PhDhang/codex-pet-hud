import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetPresenceTrackerTests: XCTestCase {
    func testColdRestoredGeometryStaysHiddenBeforeStablePresence() {
        let restored = exactWindow(id: 76)
        var tracker = PetPresenceTracker(
            restoredWindow: restored
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start
            )
        )
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start.addingTimeInterval(1)
            )
        )
    }

    func testRestoredGeometryAppearsOnlyWithStablePresence() {
        let restored = exactWindow(id: 77)
        var tracker = PetPresenceTracker(
            restoredWindow: restored
        )
        let now = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true
                ),
                now: now
            ),
            restored
        )
    }

    func testRetainsGeometryWhileIdleShellRemainsPresent() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let exact = exactWindow(id: 10)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exact,
                    hasStablePresence: true
                ),
                now: start
            ),
            exact
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(60)
            ),
            exact
        )
    }

    func testRequiresThreeMissingObservationsAcrossTwoSeconds() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let exact = exactWindow(id: 10)
        _ = tracker.update(
            observation: .init(
                exactWindow: exact,
                hasStablePresence: true
            ),
            now: start
        )

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start.addingTimeInterval(0.5)
            ),
            exact
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start.addingTimeInterval(1.5)
            ),
            exact
        )
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start.addingTimeInterval(2.5)
            )
        )
    }

    func testCompatibilityTrackerDoesNotRetainFallbackWindow() {
        var tracker = PetWindowTracker(graceInterval: 1.5)
        let start = Date(timeIntervalSince1970: 100)
        let fallback = WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 2,
            bounds: CGRect(
                x: 24,
                y: 775,
                width: 243,
                height: 252
            ),
            ownerPID: 1,
            windowID: 20
        )

        XCTAssertEqual(
            tracker.update(observed: fallback, now: start),
            fallback
        )
        XCTAssertNil(
            tracker.update(
                observed: nil,
                now: start.addingTimeInterval(0.2)
            )
        )
    }

    private func exactWindow(id: Int) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: PetWindowLocator.exactWindowName,
            layer: 2,
            bounds: CGRect(
                x: 24,
                y: 775,
                width: 243,
                height: 252
            ),
            ownerPID: 1,
            windowID: id
        )
    }
}
