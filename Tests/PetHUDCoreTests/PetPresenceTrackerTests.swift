import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetPresenceTrackerTests: XCTestCase {
    func testLoneVisualShellCannotReviveMatchingRestoredGeometry() {
        let restored = shellGeometry(
            id: 70,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 7
        )
        var tracker = PetPresenceTracker(
            restoredGeometry: restored
        )
        let observation = PetWindowLocator.observe(
            from: [
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: "Codex",
                    layer: 3,
                    bounds: CGRect(
                        x: 52,
                        y: 749,
                        width: 384,
                        height: 126
                    ),
                    ownerPID: 7,
                    windowID: 71
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
                fallback
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

    func testLiveShellThenFallbackTracksMovingPet() {
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
            fallback
        )
    }

    func testCrossPIDFallbackFailsClosedBeforeNewProcessGeometry() {
        var tracker = PetPresenceTracker()
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 1
        )
        let foreignFallback = PetVisualGeometry(
            window: fallbackWindow(
                id: 12,
                x: 300,
                ownerPID: 2
            ),
            source: .mascotFallback
        )
        let newShell = shellGeometry(
            id: 13,
            bounds: CGRect(x: 420, y: 600, width: 116, height: 126),
            ownerPID: 2
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exactWindow(id: 10, ownerPID: 1),
                    visualGeometry: shell,
                    hasStablePresence: true
                ),
                now: start
            ),
            shell
        )
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: foreignFallback.window,
                    visualGeometry: foreignFallback,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.25)
            )
        )
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: foreignFallback.window,
                    visualGeometry: foreignFallback,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(0.5)
            )
        )
        XCTAssertNil(
            tracker.update(
                observation: .init(
                    exactWindow: nil,
                    hasStablePresence: true,
                    stablePresencePID: 2
                ),
                now: start.addingTimeInterval(0.75)
            )
        )
        XCTAssertEqual(
            tracker.update(
                observation: .init(
                    exactWindow: exactWindow(id: 14, ownerPID: 2),
                    visualGeometry: newShell,
                    hasStablePresence: true
                ),
                now: start.addingTimeInterval(1)
            ),
            newShell
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

    func testRestoredFallbackPromotesAfterSecondSameWindowAndTracksMovement() {
        let restored = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(restoredGeometry: restored)
        let start = Date(timeIntervalSince1970: 100)
        let first = fallbackGeometry(id: 12, x: 300)
        let second = fallbackGeometry(id: 12, x: 360)
        let moved = fallbackGeometry(id: 12, x: 420)

        XCTAssertEqual(
            tracker.update(observation: fallbackObservation(first), now: start),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(second),
                now: start.addingTimeInterval(0.25)
            ),
            second
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(moved),
                now: start.addingTimeInterval(0.5)
            ),
            moved
        )
    }

    func testRestoredFallbackDifferentWindowRestartsConfirmation() {
        let restored = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(restoredGeometry: restored)
        let start = Date(timeIntervalSince1970: 100)
        let first = fallbackGeometry(id: 12, x: 300)
        let replacement = fallbackGeometry(id: 13, x: 360)

        XCTAssertEqual(
            tracker.update(observation: fallbackObservation(first), now: start),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(replacement),
                now: start.addingTimeInterval(0.25)
            ),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(replacement),
                now: start.addingTimeInterval(0.5)
            ),
            replacement
        )
    }

    func testAmbiguityClearsRestoredFallbackConfirmation() {
        let restored = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(restoredGeometry: restored)
        let start = Date(timeIntervalSince1970: 100)
        let fallback = fallbackGeometry(id: 12, x: 300)

        XCTAssertEqual(
            tracker.update(observation: fallbackObservation(fallback), now: start),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: ambiguousExactObservation(ownerPID: 1),
                now: start.addingTimeInterval(0.25)
            ),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(fallback),
                now: start.addingTimeInterval(0.5)
            ),
            restored
        )
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(fallback),
                now: start.addingTimeInterval(0.75)
            ),
            fallback
        )
    }

    func testAbsenceExpiryClearsPendingFallbackConfirmation() {
        let restored = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
        )
        var tracker = PetPresenceTracker(restoredGeometry: restored)
        let start = Date(timeIntervalSince1970: 100)
        let fallback = fallbackGeometry(id: 12, x: 300)

        XCTAssertEqual(
            tracker.update(observation: fallbackObservation(fallback), now: start),
            restored
        )
        for offset in [0.5, 1.5, 2.5] {
            _ = tracker.update(
                observation: .init(exactWindow: nil, hasStablePresence: false),
                now: start.addingTimeInterval(offset)
            )
        }
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(fallback),
                now: start.addingTimeInterval(3)
            ),
            fallback
        )
    }

    func testAbsenceExpiryClearsCrossPIDFallbackBarrier() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let shell = shellGeometry(
            id: 11,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 1
        )
        let foreignFallback = PetVisualGeometry(
            window: fallbackWindow(id: 12, x: 300, ownerPID: 2),
            source: .mascotFallback
        )

        _ = tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 10, ownerPID: 1),
                visualGeometry: shell,
                hasStablePresence: true
            ),
            now: start
        )
        XCTAssertNil(
            tracker.update(
                observation: fallbackObservation(foreignFallback),
                now: start.addingTimeInterval(0.25)
            )
        )
        for offset in [0.5, 1.5, 2.5] {
            _ = tracker.update(
                observation: .init(exactWindow: nil, hasStablePresence: false),
                now: start.addingTimeInterval(offset)
            )
        }
        XCTAssertEqual(
            tracker.update(
                observation: fallbackObservation(foreignFallback),
                now: start.addingTimeInterval(3)
            ),
            foreignFallback
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

    func testSamePIDExactWindowAmbiguityExpiresRetainedGeometry() {
        var tracker = PetPresenceTracker()
        let start = Date(timeIntervalSince1970: 100)
        let shell = shellGeometry(
            id: 111,
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 7
        )
        _ = tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 110, ownerPID: 7),
                visualGeometry: shell,
                hasStablePresence: true,
                stablePresencePID: 7
            ),
            now: start
        )
        let ambiguous = ambiguousExactObservation(ownerPID: 7)

        XCTAssertTrue(ambiguous.hasExactWindowAmbiguity)
        XCTAssertEqual(
            tracker.update(
                observation: ambiguous,
                now: start.addingTimeInterval(0.5)
            ),
            shell
        )
        XCTAssertEqual(
            tracker.update(
                observation: ambiguous,
                now: start.addingTimeInterval(1.5)
            ),
            shell
        )
        XCTAssertNil(
            tracker.update(
                observation: ambiguous,
                now: start.addingTimeInterval(2.5)
            )
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

    private func exactWindow(
        id: Int,
        ownerPID: Int = 1
    ) -> WindowDescriptor {
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
            ownerPID: ownerPID,
            windowID: id
        )
    }

    private func ambiguousExactObservation(
        ownerPID: Int
    ) -> PetWindowObservation {
        PetWindowLocator.observe(
            from: [
                exactWindow(id: 210, ownerPID: ownerPID),
                exactWindow(id: 211, ownerPID: ownerPID),
            ]
        )
    }

    private func fallbackWindow(
        id: Int,
        x: CGFloat,
        ownerPID: Int = 1
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
            ownerPID: ownerPID,
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

    private func fallbackObservation(
        _ geometry: PetVisualGeometry
    ) -> PetWindowObservation {
        .init(
            exactWindow: geometry.window,
            visualGeometry: geometry,
            hasStablePresence: true
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
