import AppKit
import Foundation
import XCTest
@testable import PetHUDCore

final class PetEffectManifestTests: XCTestCase {
    func testLoadsYichaExampleCriticalAssets() throws {
        try withTemporaryDirectory { directory in
            let testFile = URL(fileURLWithPath: #filePath)
            let packageRoot = testFile
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let exampleDirectory = packageRoot
                .appendingPathComponent("Examples", isDirectory: true)
                .appendingPathComponent("yicha", isDirectory: true)

            for assetName in ["hud-effects.json", "hud-critical.png"] {
                try FileManager.default.copyItem(
                    at: exampleDirectory.appendingPathComponent(assetName),
                    to: directory.appendingPathComponent(assetName)
                )
            }

            let manifest = try XCTUnwrap(
                PetEffectManifest.load(directory: directory)
            )
            let panic = try XCTUnwrap(manifest.panic)
            let critical = try XCTUnwrap(manifest.critical)
            let image = try XCTUnwrap(
                NSImage(contentsOf: critical.imageURL)
            )

            XCTAssertNil(panic.spritesheetURL)
            XCTAssertEqual(panic.columns, 8)
            XCTAssertEqual(panic.framesPerSecond, 8)
            XCTAssertEqual(
                panic.leftEye,
                NormalizedPoint(x: 0.42, y: 0.31)
            )
            XCTAssertEqual(
                panic.rightEye,
                NormalizedPoint(x: 0.58, y: 0.31)
            )
            XCTAssertEqual(panic.eyeScale, 0.88)
            XCTAssertEqual(
                critical.headAnchor,
                NormalizedPoint(x: 0.50, y: 0.30)
            )
            XCTAssertEqual(critical.scale, 1.0)
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
        }
    }

    func testLoadsCriticalMetadataInsidePetDirectory() throws {
        try withTemporaryDirectory { directory in
            try Data([0x89]).write(
                to: directory.appendingPathComponent(
                    "hud-critical.png"
                )
            )
            try """
            {
              "version": 1,
              "panic": {
                "leftEye": [0.42, 0.31],
                "rightEye": [0.58, 0.31],
                "eyeScale": 1.0
              },
              "critical": {
                "image": "hud-critical.png",
                "headAnchor": [0.72, 0.30],
                "scale": 1.0
              }
            }
            """.write(
                to: directory.appendingPathComponent(
                    "hud-effects.json"
                ),
                atomically: true,
                encoding: .utf8
            )

            let manifest = try XCTUnwrap(
                PetEffectManifest.load(directory: directory)
            )

            XCTAssertEqual(
                manifest.panic?.leftEye,
                NormalizedPoint(x: 0.42, y: 0.31)
            )
            XCTAssertEqual(
                manifest.critical?.headAnchor,
                NormalizedPoint(x: 0.72, y: 0.30)
            )
        }
    }

    func testRejectsCriticalPathOutsidePetDirectory() throws {
        try withTemporaryDirectory { directory in
            try """
            {
              "version": 1,
              "critical": {
                "image": "../outside.png",
                "headAnchor": [0.5, 0.3],
                "scale": 1.0
              }
            }
            """.write(
                to: directory.appendingPathComponent(
                    "hud-effects.json"
                ),
                atomically: true,
                encoding: .utf8
            )

            XCTAssertThrowsError(
                try PetEffectManifest.load(directory: directory)
            ) {
                XCTAssertEqual(
                    $0 as? PetEffectManifestError,
                    .unsafeAssetPath
                )
            }
        }
    }

    func testRejectsCriticalAssetSymlinkEscapingPetDirectory() throws {
        try withTemporaryDirectory { root in
            let directory = root.appendingPathComponent(
                "pet",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let outside = root.appendingPathComponent("outside.png")
            try Data([0x89]).write(to: outside)
            try FileManager.default.createSymbolicLink(
                at: directory.appendingPathComponent("hud-critical.png"),
                withDestinationURL: outside
            )
            try """
            {
              "version": 1,
              "critical": {
                "image": "hud-critical.png",
                "headAnchor": [0.5, 0.3],
                "scale": 1.0
              }
            }
            """.write(
                to: directory.appendingPathComponent("hud-effects.json"),
                atomically: true,
                encoding: .utf8
            )

            XCTAssertThrowsError(
                try PetEffectManifest.load(directory: directory)
            ) {
                XCTAssertEqual(
                    $0 as? PetEffectManifestError,
                    .unsafeAssetPath
                )
            }
        }
    }

    func testRejectsMetadataSymlinkEscapingPetDirectory() throws {
        try withTemporaryDirectory { root in
            let directory = root.appendingPathComponent(
                "pet",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let outside = root.appendingPathComponent("hud-effects.json")
            try "{ \"version\": 1 }".write(
                to: outside,
                atomically: true,
                encoding: .utf8
            )
            try FileManager.default.createSymbolicLink(
                at: directory.appendingPathComponent("hud-effects.json"),
                withDestinationURL: outside
            )

            XCTAssertThrowsError(
                try PetEffectManifest.load(directory: directory)
            ) {
                XCTAssertEqual(
                    $0 as? PetEffectManifestError,
                    .unsafeAssetPath
                )
            }
        }
    }

    func testClampsEffectMetadataValuesToSafeRanges() throws {
        try withTemporaryDirectory { directory in
            try Data([0x89]).write(
                to: directory.appendingPathComponent("hud-panic.png")
            )
            try Data([0x89]).write(
                to: directory.appendingPathComponent("hud-critical.png")
            )
            try """
            {
              "version": 1,
              "panic": {
                "spritesheet": "hud-panic.png",
                "columns": 99,
                "framesPerSecond": 0,
                "leftEye": [-1, 2],
                "rightEye": [2, -1],
                "eyeScale": 9
              },
              "critical": {
                "image": "hud-critical.png",
                "headAnchor": [-1, 2],
                "scale": 0.1
              }
            }
            """.write(
                to: directory.appendingPathComponent("hud-effects.json"),
                atomically: true,
                encoding: .utf8
            )

            let manifest = try XCTUnwrap(
                PetEffectManifest.load(directory: directory)
            )
            let panic = try XCTUnwrap(manifest.panic)
            let critical = try XCTUnwrap(manifest.critical)

            XCTAssertEqual(panic.columns, 16)
            XCTAssertEqual(panic.framesPerSecond, 1)
            XCTAssertEqual(panic.leftEye, NormalizedPoint(x: 0, y: 1))
            XCTAssertEqual(panic.rightEye, NormalizedPoint(x: 1, y: 0))
            XCTAssertEqual(panic.eyeScale, 2)
            XCTAssertEqual(critical.headAnchor, NormalizedPoint(x: 0, y: 1))
            XCTAssertEqual(critical.scale, 0.5)
        }
    }

    func testReturnsNilWhenMetadataIsMissing() throws {
        try withTemporaryDirectory { directory in
            XCTAssertNil(try PetEffectManifest.load(directory: directory))
        }
    }
}
