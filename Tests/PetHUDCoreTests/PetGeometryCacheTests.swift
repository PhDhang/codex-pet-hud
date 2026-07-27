import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class PetGeometryCacheTests: XCTestCase {
    func testRoundTripsGeometryWithOwnerOnlyPermissions() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let cache = PetGeometryCache(url: url)
            let record = PetGeometryRecord(
                window: exactWindow(id: 42),
                updatedAt: Date(timeIntervalSince1970: 123)
            )

            try cache.save(record)

            XCTAssertEqual(try cache.load(), record)
            let attributes =
                try FileManager.default.attributesOfItem(
                    atPath: url.path
                )
            let mode = try XCTUnwrap(
                attributes[.posixPermissions] as? NSNumber
            )
            XCTAssertEqual(mode.intValue & 0o777, 0o600)
        }
    }

    func testRejectsCachedGeometryOutsideCurrentDisplays() throws {
        try withTemporaryDirectory { directory in
            let cache = PetGeometryCache(
                url: directory.appendingPathComponent(
                    "pet-geometry.json"
                )
            )
            let record = PetGeometryRecord(
                window: exactWindow(
                    id: 43,
                    bounds: CGRect(x: 5_000, y: 5_000, width: 100, height: 100)
                ),
                updatedAt: Date(timeIntervalSince1970: 123)
            )

            try cache.save(record)

            XCTAssertNil(
                try cache.load(
                    intersecting: [
                        CGRect(x: 0, y: 0, width: 1_920, height: 1_080),
                    ]
                )
            )
        }
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
}
