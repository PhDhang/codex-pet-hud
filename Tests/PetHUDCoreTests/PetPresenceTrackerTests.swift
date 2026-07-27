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

    func testColdFallbackGeometryConfirmsPresence() {
        var tracker = PetPresenceTracker()
        let fallback = fallbackWindow(id: 78, x: 24)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: fallback,
                    hasStablePresence: false
                ),
                now: Date(timeIntervalSince1970: 100)
            ),
            fallback
        )
    }

    func testRepeatedFallbackGeometryDoesNotEnterAbsence() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        _ = tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 79),
                hasStablePresence: true
            ),
            now: start
        )

        for (offset, x) in [(0.5, 30.0), (1.5, 42.0), (2.5, 54.0)] {
            let fallback = fallbackWindow(
                id: 80,
                x: CGFloat(x)
            )
            XCTAssertEqual(
                tracker.update(
                    observation: .init(
                        exactWindow: fallback,
                        hasStablePresence: false
                    ),
                    now: start.addingTimeInterval(offset)
                ),
                fallback
            )
        }
    }

    func testUsesVisualGeometryForMovementAndResize() {
        var tracker = PetPresenceTracker()
        let exact = exactWindow(id: 10)
        let initialVisual = visualWindow(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        let resizedVisual = visualWindow(
            id: 11,
            bounds: CGRect(x: 454, y: 500, width: 192, height: 208)
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exact,
                    visualWindow: initialVisual,
                    hasStablePresence: true
                ),
                now: start
            ),
            initialVisual
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exact,
                    visualWindow: resizedVisual,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.25)
            ),
            resizedVisual
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

    private func fallbackWindow(
        id: Int,
        x: CGFloat
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 2,
            bounds: CGRect(
                x: x,
                y: 775,
                width: 243,
                height: 252
            ),
            ownerPID: 1,
            windowID: id
        )
    }

    private func visualWindow(
        id: Int,
        bounds: CGRect
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 3,
            bounds: bounds,
            ownerPID: 1,
            windowID: id
        )
    }
}
