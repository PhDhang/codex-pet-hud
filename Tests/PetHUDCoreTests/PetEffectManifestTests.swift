import AppKit
import Foundation
import XCTest
@testable import PetHUDCore

final class PetEffectManifestTests: XCTestCase {
    func testCustomPanicStripDoesNotRequireEyeOverlayMetadata() throws {
        try withTemporaryDirectory { directory in
            try Data([0x89]).write(
                to: directory.appendingPathComponent("hud-panic.png")
            )
            try """
            {
              "version": 1,
              "panic": {
                "spritesheet": "hud-panic.png",
                "columns": 8,
                "framesPerSecond": 8
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

            XCTAssertEqual(
                panic.spritesheetURL?.lastPathComponent,
                "hud-panic.png"
            )
            XCTAssertEqual(panic.columns, 8)
            XCTAssertEqual(panic.framesPerSecond, 8)
        }
    }

    func testLoadsYichaExampleEffectAssets() throws {
        try withTemporaryDirectory { directory in
            let testFile = URL(fileURLWithPath: #filePath)
            let packageRoot = testFile
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            let exampleDirectory = packageRoot
                .appendingPathComponent("Examples", isDirectory: true)
                .appendingPathComponent("yicha", isDirectory: true)

            for assetName in [
                "hud-effects.json",
                "hud-panic.png",
                "hud-critical.png",
            ] {
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
            let panicURL = try XCTUnwrap(panic.spritesheetURL)
            let panicBitmap = try XCTUnwrap(
                NSBitmapImageRep(
                    data: Data(contentsOf: panicURL)
                )
            )
            let panicFrames = try PetAtlas.stripImages(
                url: panicURL,
                columns: panic.columns
            )
            let image = try XCTUnwrap(
                NSImage(contentsOf: critical.imageURL)
            )
            let bitmap = try XCTUnwrap(
                NSBitmapImageRep(
                    data: Data(contentsOf: critical.imageURL)
                )
            )

            XCTAssertEqual(
                panic.spritesheetURL?.lastPathComponent,
                "hud-panic.png"
            )
            XCTAssertEqual(panic.columns, 8)
            XCTAssertEqual(panic.framesPerSecond, 8)
            XCTAssertEqual(panicBitmap.pixelsWide, 1536)
            XCTAssertEqual(panicBitmap.pixelsHigh, 208)
            XCTAssertEqual(panicFrames.count, 8)
            for (index, frame) in panicFrames.enumerated() {
                XCTAssertEqual(frame.width, 192, "frame \(index)")
                XCTAssertEqual(frame.height, 208, "frame \(index)")
                let frameBitmap = NSBitmapImageRep(cgImage: frame)
                XCTAssertTrue(
                    hasVisiblePixels(in: frameBitmap),
                    "frame \(index) is empty"
                )
                XCTAssertTrue(
                    hasTransparentBorder(in: frameBitmap),
                    "frame \(index) touches its cell border"
                )
                XCTAssertEqual(
                    visibleComponentCount(in: frameBitmap),
                    1,
                    "frame \(index) contains detached artwork"
                )
            }
            XCTAssertEqual(
                critical.headAnchor,
                NormalizedPoint(x: 0.50, y: 0.30)
            )
            XCTAssertEqual(critical.scale, 1.0)
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
            XCTAssertEqual(bitmap.pixelsWide, 192)
            XCTAssertEqual(bitmap.pixelsHigh, 208)
            for artifactRow in 27...28 {
                for x in 84...107 {
                    XCTAssertEqual(
                        bitmap.colorAt(
                            x: x,
                            y: artifactRow
                        )?.alphaComponent,
                        0
                    )
                }
            }
            XCTAssertEqual(visibleComponentCount(in: bitmap), 1)
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

    private func visibleComponentCount(
        in bitmap: NSBitmapImageRep
    ) -> Int {
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        var visited = Array(
            repeating: false,
            count: width * height
        )
        var componentCount = 0

        for y in 0..<height {
            for x in 0..<width {
                let start = y * width + x
                guard !visited[start],
                      (bitmap.colorAt(
                        x: x,
                        y: y
                      )?.alphaComponent ?? 0) > 0
                else {
                    continue
                }

                componentCount += 1
                var queue = [(x, y)]
                var cursor = 0
                visited[start] = true

                while cursor < queue.count {
                    let (currentX, currentY) = queue[cursor]
                    cursor += 1

                    for (nextX, nextY) in [
                        (currentX - 1, currentY),
                        (currentX + 1, currentY),
                        (currentX, currentY - 1),
                        (currentX, currentY + 1),
                    ] {
                        guard nextX >= 0,
                              nextX < width,
                              nextY >= 0,
                              nextY < height
                        else {
                            continue
                        }
                        let next = nextY * width + nextX
                        guard !visited[next],
                              (bitmap.colorAt(
                                x: nextX,
                                y: nextY
                              )?.alphaComponent ?? 0) > 0
                        else {
                            continue
                        }
                        visited[next] = true
                        queue.append((nextX, nextY))
                    }
                }
            }
        }

        return componentCount
    }

    private func hasVisiblePixels(
        in bitmap: NSBitmapImageRep
    ) -> Bool {
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide
            where (bitmap.colorAt(
                x: x,
                y: y
            )?.alphaComponent ?? 0) > 0 {
                return true
            }
        }
        return false
    }

    private func hasTransparentBorder(
        in bitmap: NSBitmapImageRep
    ) -> Bool {
        let maxX = bitmap.pixelsWide - 1
        let maxY = bitmap.pixelsHigh - 1
        for x in 0...maxX {
            if (bitmap.colorAt(x: x, y: 0)?.alphaComponent ?? 0) > 0 ||
                (bitmap.colorAt(x: x, y: maxY)?.alphaComponent ?? 0) > 0 {
                return false
            }
        }
        for y in 0...maxY {
            if (bitmap.colorAt(x: 0, y: y)?.alphaComponent ?? 0) > 0 ||
                (bitmap.colorAt(x: maxX, y: y)?.alphaComponent ?? 0) > 0 {
                return false
            }
        }
        return true
    }
}
