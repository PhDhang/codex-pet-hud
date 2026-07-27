import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetPresenceTrackerTests: XCTestCase {
    func testColdRestoredGeometryStaysHiddenBeforeStablePresence() {
        let restored = shellGeometry(
            id: 76,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
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

    func testAmbiguousNamedPresenceCannotReviveRestoredGeometry() {
        let restored = shellGeometry(
            id: 176,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
        )
        let observation = PetWindowLocator.observe(
            from: [
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: "Codex Pet Composition Surface",
                    layer: 3,
                    bounds: CGRect(
                        x: 0,
                        y: 0,
                        width: 768,
                        height: 912
                    ),
                    ownerPID: 1,
                    windowID: 177
                ),
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: "Codex Pet Voice Controls Backing",
                    layer: 3,
                    bounds: CGRect(
                        x: 0,
                        y: 0,
                        width: 24,
                        height: 24
                    ),
                    ownerPID: 2,
                    windowID: 178
                ),
            ]
        )

        XCTAssertFalse(observation.hasStablePresence)
        XCTAssertNil(observation.stablePresencePID)
        XCTAssertNil(
            tracker.update(
                observation: observation,
                now: Date(timeIntervalSince1970: 100)
            )
        )
    }

    func testRestoredGeometryAppearsOnlyWithStablePresence() {
        let restored = shellGeometry(
            id: 77,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
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

    func testRestoredGeometryRejectsStablePresencePIDMismatch() {
        let restored = shellGeometry(
            id: 177,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 1
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
        )

        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true,
                    stablePresencePID: 2
                ),
                now: Date(timeIntervalSince1970: 100)
            )
        )
    }

    func testColdFallbackGeometryConfirmsPresence() {
        var tracker = PetPresenceTracker()
        let fallback = fallbackGeometry(id: 78, x: 24)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: fallback.window,
                    visualGeometry: fallback,
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
        let initial = shellGeometry(
            id: 79,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        _ = tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 79),
                visualGeometry: initial,
                hasStablePresence: true
            ),
            now: start
        )

        for (offset, x) in [(0.5, 30.0), (1.5, 42.0), (2.5, 54.0)] {
            let fallback = fallbackGeometry(
                id: 80,
                x: CGFloat(x)
            )
            XCTAssertEqual(
                tracker.update(
                    observation: .init(
                        exactWindow: fallback.window,
                        visualGeometry: fallback,
                        hasStablePresence: false
                    ),
                    now: start.addingTimeInterval(offset)
                ),
                initial
            )
        }
    }

    func testUsesVisualGeometryForMovementAndResize() {
        var tracker = PetPresenceTracker()
        let exact = exactWindow(id: 10)
        let initialVisual = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        let resizedVisual = shellGeometry(
            id: 11,
            bounds: CGRect(x: 454, y: 500, width: 192, height: 208)
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exact,
                    visualGeometry: initialVisual,
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
                    visualGeometry: resizedVisual,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.25)
            ),
            resizedVisual
        )
    }

    func testShellThenFallbackRetainsHighConfidenceGeometry() {
        var tracker = PetPresenceTracker()
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        let fallback = PetVisualGeometry(
            window: fallbackWindow(id: 12, x: 300),
            source: .mascotFallback
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exactWindow(id: 10),
                    visualGeometry: shell,
                    hasStablePresence: true
                ),
                now: start
            ),
            shell
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: fallback.window,
                    visualGeometry: fallback,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.25)
            ),
            shell
        )
    }

    func testRestoredShellGeometrySurvivesColdFallback() {
        let restored = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
        )
        let fallback = PetVisualGeometry(
            window: fallbackWindow(id: 12, x: 300),
            source: .mascotFallback
        )

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: fallback.window,
                    visualGeometry: fallback,
                    hasStablePresence: true
                ),
                now: Date(timeIntervalSince1970: 100)
            ),
            restored
        )
    }

    func testReappearingShellImmediatelyReplacesFallback() {
        var tracker = PetPresenceTracker()
        let fallback = fallbackGeometry(id: 12, x: 300)
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 454, y: 500, width: 192, height: 208)
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: fallback.window,
                    visualGeometry: fallback,
                    hasStablePresence: true
                ),
                now: start
            ),
            fallback
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exactWindow(id: 10),
                    visualGeometry: shell,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.25)
            ),
            shell
        )
    }

    func testRetainsGeometryWhileIdleShellRemainsPresent() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let exact = exactWindow(id: 10)
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exact,
                    visualGeometry: shell,
                    hasStablePresence: true
                ),
                now: start
            ),
            shell
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(60)
            ),
            shell
        )
    }

    func testRetainedGeometryRejectsStablePresencePIDMismatch() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let shell = shellGeometry(
            id: 111,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 1
        )
        _ = tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 110),
                visualGeometry: shell,
                hasStablePresence: true,
                stablePresencePID: 1
            ),
            now: start
        )

        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true,
                    stablePresencePID: 2
                ),
                now: start.addingTimeInterval(60)
            )
        )
    }

    func testRequiresThreeMissingObservationsAcrossTwoSeconds() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let exact = exactWindow(id: 10)
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        _ = tracker.update(
            observation: .init(
                exactWindow: exact,
                visualGeometry: shell,
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
            shell
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: false
                ),
                now: start.addingTimeInterval(1.5)
            ),
            shell
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
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(3)
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

    private func fallbackGeometry(
        id: Int,
        x: CGFloat
    ) -> PetVisualGeometry {
        PetVisualGeometry(
            window: fallbackWindow(id: id, x: x),
            source: .mascotFallback
        )
    }

    private func shellGeometry(
        id: Int,
        bounds: CGRect,
        ownerPID: Int = 1
    ) -> PetVisualGeometry {
        PetVisualGeometry(
            window: WindowDescriptor(
                owner: "ChatGPT",
                name: "Codex",
                layer: 3,
                bounds: bounds,
                ownerPID: ownerPID,
                windowID: id
            ),
            source: .shellDerived
        )
    }
}
