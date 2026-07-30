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
