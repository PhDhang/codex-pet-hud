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

            let loaded = try XCTUnwrap(cache.load())
            XCTAssertEqual(loaded.window.bounds, record.window.bounds)
            XCTAssertEqual(loaded.window.ownerPID, record.window.ownerPID)
            XCTAssertEqual(loaded.window.windowID, record.window.windowID)
            XCTAssertEqual(loaded.updatedAt, record.updatedAt)
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

    func testPersistsOnlyRestorableGeometryFields() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let record = PetGeometryRecord(
                window: exactWindow(id: 44),
                updatedAt: Date(timeIntervalSince1970: 123)
            )

            try PetGeometryCache(url: url).save(record)

            let json = try String(
                contentsOf: url,
                encoding: .utf8
            )
            XCTAssertTrue(json.contains("\"bounds\""))
            XCTAssertTrue(json.contains("\"ownerPID\""))
            XCTAssertTrue(json.contains("\"windowID\""))
            XCTAssertFalse(json.contains("\"owner\""))
            XCTAssertFalse(json.contains("\"name\""))
            XCTAssertFalse(json.contains("\"layer\""))
            XCTAssertEqual(
                try PetGeometryCache(url: url).load()?.window.bounds,
                record.window.bounds
            )
        }
    }

    func testLoadsLegacyWindowDescriptorCache() throws {
        struct LegacyRecord: Encodable {
            let window: WindowDescriptor
            let updatedAt: Date
        }

        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let window = exactWindow(id: 45)
            let legacy = LegacyRecord(
                window: window,
                updatedAt: Date(timeIntervalSince1970: 123)
            )
            try JSONEncoder().encode(legacy).write(to: url)

            let record = try XCTUnwrap(
                PetGeometryCache(url: url).load()
            )
            XCTAssertEqual(record.window.bounds, window.bounds)
            XCTAssertEqual(record.window.ownerPID, window.ownerPID)
            XCTAssertEqual(record.window.windowID, window.windowID)
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
