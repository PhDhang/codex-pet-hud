import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetWindowTrackerTests: XCTestCase {
    func testRetainsExactWindowDuringGracePeriod() {
        var tracker = PetWindowTracker(
            graceInterval: 1.5
        )
        let start = Date(timeIntervalSince1970: 100)

        XCTAssertEqual(
            tracker.update(
                observed: exactWindow(id: 10),
                now: start
            )?.windowID,
            10
        )
        XCTAssertEqual(
            tracker.update(
                observed: nil,
                now: start.addingTimeInterval(1.4)
            )?.windowID,
            10
        )
    }

    func testDropsExactWindowAfterGracePeriod() {
        var tracker = PetWindowTracker(
            graceInterval: 1.5
        )
        let start = Date(timeIntervalSince1970: 100)
        _ = tracker.update(
            observed: exactWindow(id: 10),
            now: start
        )

        XCTAssertNil(
            tracker.update(
                observed: nil,
                now: start.addingTimeInterval(1.6)
            )
        )
    }

    func testReplacesWindowWhenResizeRecreatesIt() {
        var tracker = PetWindowTracker(
            graceInterval: 1.5
        )
        let start = Date(timeIntervalSince1970: 100)
        _ = tracker.update(
            observed: exactWindow(id: 10),
            now: start
        )
        let replacement = exactWindow(
            id: 11,
            bounds: CGRect(
                x: 493,
                y: 598,
                width: 378,
                height: 393
            )
        )

        XCTAssertEqual(
            tracker.update(
                observed: replacement,
                now: start.addingTimeInterval(0.2)
            ),
            replacement
        )
    }

    func testDoesNotRetainFallbackWindow() {
        var tracker = PetWindowTracker(
            graceInterval: 1.5
        )
        let start = Date(timeIntervalSince1970: 100)
        _ = tracker.update(
            observed: fallbackWindow(),
            now: start
        )

        XCTAssertNil(
            tracker.update(
                observed: nil,
                now: start.addingTimeInterval(0.2)
            )
        )
    }

    private func exactWindow(
        id: Int,
        bounds: CGRect = CGRect(
            x: 24,
            y: 775,
            width: 243,
            height: 252
        )
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: PetWindowLocator.exactWindowName,
            layer: 2,
            bounds: bounds,
            ownerPID: 1,
            windowID: id
        )
    }

    private func fallbackWindow() -> WindowDescriptor {
        WindowDescriptor(
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
    }
}
