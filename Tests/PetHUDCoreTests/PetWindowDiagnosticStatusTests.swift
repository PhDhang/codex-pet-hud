import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetWindowDiagnosticStatusTests: XCTestCase {
    func testColdIdlePresenceWithoutGeometryIsMissing() {
        let observation = PetWindowObservation(
            exactWindow: nil,
            hasStablePresence: true,
            stablePresencePID: 7
        )

        XCTAssertEqual(
            PetWindowDiagnosticStatus.resolve(
                observation: observation,
                cachedGeometry: nil,
                now: Date(timeIntervalSince1970: 100)
            ),
            .missing
        )
    }

    func testCurrentGeometryIsFound() {
        let current = geometry(ownerPID: 7)
        let observation = PetWindowObservation(
            exactWindow: current.window,
            visualGeometry: current,
            hasStablePresence: false
        )

        XCTAssertEqual(
            PetWindowDiagnosticStatus.resolve(
                observation: observation,
                cachedGeometry: nil,
                now: Date(timeIntervalSince1970: 100)
            ),
            .found
        )
    }

    func testMatchingCachedGeometryDuringIdleIsFound() {
        let cached = geometry(ownerPID: 7)
        let observation = PetWindowObservation(
            exactWindow: nil,
            hasStablePresence: true,
            stablePresencePID: 7
        )

        XCTAssertEqual(
            PetWindowDiagnosticStatus.resolve(
                observation: observation,
                cachedGeometry: cached,
                now: Date(timeIntervalSince1970: 100)
            ),
            .found
        )
    }

    func testMismatchedCachedGeometryDuringIdleIsMissing() {
        let observation = PetWindowObservation(
            exactWindow: nil,
            hasStablePresence: true,
            stablePresencePID: 8
        )

        XCTAssertEqual(
            PetWindowDiagnosticStatus.resolve(
                observation: observation,
                cachedGeometry: geometry(ownerPID: 7),
                now: Date(timeIntervalSince1970: 100)
            ),
            .missing
        )
    }

    func testSamePIDDuplicateExactWindowsAreMissingWithCachedGeometry() {
        let observation = PetWindowLocator.observe(
            from: [
                exactWindow(id: 71, ownerPID: 7),
                exactWindow(id: 72, ownerPID: 7),
            ]
        )

        XCTAssertTrue(observation.hasExactWindowAmbiguity)
        XCTAssertEqual(
            PetWindowDiagnosticStatus.resolve(
                observation: observation,
                cachedGeometry: geometry(ownerPID: 7),
                now: Date(timeIntervalSince1970: 100)
            ),
            .missing
        )
    }

    private func exactWindow(
        id: Int,
        ownerPID: Int
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

    private func geometry(
        ownerPID: Int
    ) -> PetVisualGeometry {
        PetVisualGeometry(
            window: WindowDescriptor(
                owner: "ChatGPT",
                name: PetWindowLocator.visualWindowName,
                layer: 3,
                bounds: CGRect(
                    x: 180,
                    y: 749,
                    width: 116,
                    height: 126
                ),
                ownerPID: ownerPID,
                windowID: 70
            ),
            source: .shellDerived
        )
    }
}
