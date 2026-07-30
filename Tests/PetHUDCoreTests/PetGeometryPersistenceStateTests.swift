import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PetGeometryPersistenceStateTests: XCTestCase {
    func testOnlyChangedShellGeometryNeedsPersistence() {
        let initial = geometry(
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 7,
            windowID: 70
        )
        var state = PetGeometryPersistenceState(
            persistedGeometry: initial
        )

        XCTAssertFalse(state.needsPersistence(initial))

        let moved = geometry(
            bounds: CGRect(x: 220, y: 700, width: 116, height: 126),
            ownerPID: 7,
            windowID: 70
        )
        XCTAssertTrue(state.needsPersistence(moved))
        state.recordPersisted(moved)
        XCTAssertFalse(state.needsPersistence(moved))

        let newProcess = geometry(
            bounds: moved.window.bounds,
            ownerPID: 8,
            windowID: 70
        )
        XCTAssertTrue(state.needsPersistence(newProcess))
        state.recordPersisted(newProcess)

        let newWindow = geometry(
            bounds: moved.window.bounds,
            ownerPID: 8,
            windowID: 71
        )
        XCTAssertTrue(state.needsPersistence(newWindow))
    }

    func testFailedSaveRemainsEligibleForRetry() {
        let candidate = geometry(
            bounds: CGRect(x: 180, y: 749, width: 116, height: 126),
            ownerPID: 7,
            windowID: 70
        )
        var state = PetGeometryPersistenceState()

        XCTAssertTrue(state.needsPersistence(candidate))
        XCTAssertTrue(state.needsPersistence(candidate))

        state.recordPersisted(candidate)

        XCTAssertFalse(state.needsPersistence(candidate))
    }

    private func geometry(
        bounds: CGRect,
        ownerPID: Int,
        windowID: Int
    ) -> PetVisualGeometry {
        PetVisualGeometry(
            window: WindowDescriptor(
                owner: "ChatGPT",
                name: PetWindowLocator.visualWindowName,
                layer: 3,
                bounds: bounds,
                ownerPID: ownerPID,
                windowID: windowID
            ),
            source: .shellDerived
        )
    }
}
