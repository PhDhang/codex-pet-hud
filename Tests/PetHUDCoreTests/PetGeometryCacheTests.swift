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
            let geometry = shellGeometry(
                id: 42
            )

            XCTAssertTrue(
                try cache.save(
                    geometry,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )

            let loaded = try XCTUnwrap(cache.load())
            XCTAssertEqual(loaded.geometry, geometry)
            XCTAssertEqual(
                loaded.updatedAt,
                Date(timeIntervalSince1970: 123)
            )
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
            let geometry = shellGeometry(
                id: 43,
                bounds: CGRect(
                    x: 5_000,
                    y: 5_000,
                    width: 100,
                    height: 100
                )
            )

            XCTAssertTrue(
                try cache.save(
                    geometry,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )

            XCTAssertNil(
                try cache.load(
                    intersecting: [
                        CGRect(x: 0, y: 0, width: 1_920, height: 1_080),
                    ]
                )
            )
        }
    }

    func testPersistsCurrentVersionAndShellSource() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let cache = PetGeometryCache(url: url)
            let geometry = shellGeometry(id: 44)

            XCTAssertTrue(
                try cache.save(
                    geometry,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )

            let json = try String(
                contentsOf: url,
                encoding: .utf8
            )
            XCTAssertTrue(json.contains("\"version\" : 1"))
            XCTAssertTrue(
                json.contains("\"source\" : \"shellDerived\"")
            )
            XCTAssertFalse(json.contains("\"owner\""))
            XCTAssertFalse(json.contains("\"name\""))
            XCTAssertFalse(json.contains("\"layer\""))
            XCTAssertEqual(
                try cache.load()?.geometry,
                geometry
            )
        }
    }

    func testInvalidatesLegacyUnversionedGeometry() throws {
        struct LegacyRecord: Encodable {
            let bounds: CGRect
            let ownerPID: Int
            let updatedAt: Date
            let windowID: Int
        }

        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let legacy = LegacyRecord(
                bounds: CGRect(
                    x: 105,
                    y: 683,
                    width: 249,
                    height: 259
                ),
                ownerPID: 51_007,
                updatedAt: Date(timeIntervalSince1970: 123),
                windowID: 101
            )
            try JSONEncoder().encode(legacy).write(to: url)

            XCTAssertThrowsError(
                try PetGeometryCache(url: url).load()
            ) { error in
                XCTAssertEqual(
                    error as? PetGeometryCacheError,
                    .legacyUnversioned
                )
            }
        }
    }

    func testRejectsUnknownFutureGeometryVersion() throws {
        struct FutureRecord: Encodable {
            let version: Int
            let source: String
            let bounds: CGRect
            let ownerPID: Int
            let updatedAt: Date
            let windowID: Int
        }

        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let future = FutureRecord(
                version: 2,
                source: "shellDerived",
                bounds: CGRect(
                    x: 185.85,
                    y: 749,
                    width: 116.31,
                    height: 126
                ),
                ownerPID: 51_007,
                updatedAt: Date(timeIntervalSince1970: 123),
                windowID: 102
            )
            try JSONEncoder().encode(future).write(to: url)

            XCTAssertThrowsError(
                try PetGeometryCache(url: url).load()
            ) { error in
                XCTAssertEqual(
                    error as? PetGeometryCacheError,
                    .unsupportedVersion(2)
                )
            }
        }
    }

    func testFallbackNeverPersistsOrOverwritesShellGeometry() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let cache = PetGeometryCache(url: url)
            let shell = shellGeometry(id: 45)
            let fallback = PetVisualGeometry(
                window: exactWindow(
                    id: 43,
                    bounds: CGRect(
                        x: 180,
                        y: 749,
                        width: 119,
                        height: 129
                    )
                ),
                source: .mascotFallback
            )

            XCTAssertTrue(
                try cache.save(
                    shell,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )
            XCTAssertFalse(
                try cache.save(
                    fallback,
                    updatedAt: Date(timeIntervalSince1970: 124)
                )
            )

            let loaded = try XCTUnwrap(cache.load())
            XCTAssertEqual(loaded.geometry, shell)
            XCTAssertEqual(
                loaded.updatedAt,
                Date(timeIntervalSince1970: 123)
            )
        }
    }

    func testFallbackDoesNotCreateFreshCache() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent(
                "pet-geometry.json"
            )
            let fallback = PetVisualGeometry(
                window: exactWindow(
                    id: 46,
                    bounds: CGRect(
                        x: 180,
                        y: 749,
                        width: 119,
                        height: 129
                    )
                ),
                source: .mascotFallback
            )

            XCTAssertFalse(
                try PetGeometryCache(url: url).save(
                    fallback,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: url.path)
            )
        }
    }

    func testPersistsShellSizedGeometryAtExactMascotCenter() throws {
        try withTemporaryDirectory { directory in
            let mascotBounds = CGRect(
                x: 30,
                y: 643,
                width: 249,
                height: 259
            )
            let shell = WindowDescriptor(
                owner: "ChatGPT",
                name: PetWindowLocator.visualWindowName,
                layer: 3,
                bounds: CGRect(
                    x: 0,
                    y: 709,
                    width: 384,
                    height: 126
                ),
                ownerPID: 51_007,
                windowID: 102
            )
            let geometry = try XCTUnwrap(
                PetWindowLocator.observe(
                    from: [
                        WindowDescriptor(
                            owner: "ChatGPT",
                            name: PetWindowLocator.exactWindowName,
                            layer: 2,
                            bounds: mascotBounds,
                            ownerPID: 51_007,
                            windowID: 101
                        ),
                        shell,
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
                            ownerPID: 51_007,
                            windowID: 107
                        ),
                    ]
                ).visualGeometry
            )
            let cache = PetGeometryCache(
                url: directory.appendingPathComponent(
                    "pet-geometry.json"
                )
            )

            XCTAssertEqual(geometry.source, .shellDerived)
            XCTAssertTrue(
                try cache.save(
                    geometry,
                    updatedAt: Date(timeIntervalSince1970: 123)
                )
            )
            let cachedBounds = try XCTUnwrap(
                cache.load()?.geometry.window.bounds
            )
            XCTAssertEqual(
                cachedBounds.midX,
                mascotBounds.midX,
                accuracy: 0.001
            )
            XCTAssertEqual(
                cachedBounds.midY,
                mascotBounds.midY,
                accuracy: 0.001
            )
            XCTAssertEqual(
                cachedBounds.width,
                126 * 192 / 208,
                accuracy: 0.001
            )
            XCTAssertEqual(
                cachedBounds.height,
                126,
                accuracy: 0.001
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

    private func shellGeometry(
        id: Int,
        bounds: CGRect = CGRect(
            x: 185.85,
            y: 749,
            width: 116.31,
            height: 126
        )
    ) -> PetVisualGeometry {
        PetVisualGeometry(
            window: WindowDescriptor(
                owner: "ChatGPT",
                name: PetWindowLocator.visualWindowName,
                layer: 3,
                bounds: bounds,
                ownerPID: 51_007,
                windowID: id
            ),
            source: .shellDerived
        )
    }
}
