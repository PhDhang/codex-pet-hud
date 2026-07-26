import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import PetHUDCore

final class PetAtlasTests: XCTestCase {
    func testExtractsTopLeftNeutralCellFromEightByElevenAtlas() throws {
        try withTemporaryDirectory { root in
            let petDirectory = root.appendingPathComponent(
                "pet",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: petDirectory,
                withIntermediateDirectories: true
            )
            let spritesheetURL = petDirectory
                .appendingPathComponent("spritesheet.png")
            try writeAtlas(to: spritesheetURL)
            try Data(
                """
                {
                  "id": "pet",
                  "displayName": "Pet",
                  "spriteVersionNumber": 2,
                  "spritesheetPath": "spritesheet.png"
                }
                """.utf8
            ).write(
                to: petDirectory.appendingPathComponent("pet.json")
            )
            let manifest = try PetManifest.load(
                directory: petDirectory
            )

            let image = try PetAtlas.neutralImage(
                manifest: manifest
            )

            XCTAssertEqual(image.width, 2)
            XCTAssertEqual(image.height, 2)
            let bitmap = NSBitmapImageRep(cgImage: image)
            let color = try XCTUnwrap(
                bitmap.colorAt(x: 0, y: 0)?
                    .usingColorSpace(.deviceRGB)
            )
            XCTAssertGreaterThan(color.redComponent, 0.9)
            XCTAssertLessThan(color.blueComponent, 0.1)
        }
    }

    func testRejectsAtlasWithInvalidGridDimensions() throws {
        try withTemporaryDirectory { root in
            let petDirectory = root.appendingPathComponent(
                "pet",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: petDirectory,
                withIntermediateDirectories: true
            )
            let spritesheetURL = petDirectory
                .appendingPathComponent("spritesheet.png")
            try writeSolidImage(
                width: 15,
                height: 22,
                to: spritesheetURL
            )
            try Data(
                """
                {
                  "id": "pet",
                  "displayName": "Pet",
                  "spriteVersionNumber": 2,
                  "spritesheetPath": "spritesheet.png"
                }
                """.utf8
            ).write(
                to: petDirectory.appendingPathComponent("pet.json")
            )
            let manifest = try PetManifest.load(
                directory: petDirectory
            )

            XCTAssertThrowsError(
                try PetAtlas.neutralImage(manifest: manifest)
            ) { error in
                XCTAssertEqual(error as? PetAtlasError, .invalidDimensions)
            }
        }
    }

    private func writeAtlas(to url: URL) throws {
        let width = 16
        let height = 22
        let bytesPerPixel = 4
        var pixels = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let isNeutral = x < 2 && y < 2
                pixels[offset] = isNeutral ? 255 : 0
                pixels[offset + 1] = 0
                pixels[offset + 2] = isNeutral ? 0 : 255
                pixels[offset + 3] = 255
            }
        }

        try writePNG(
            pixels: pixels,
            width: width,
            height: height,
            to: url
        )
    }

    private func writeSolidImage(
        width: Int,
        height: Int,
        to url: URL
    ) throws {
        try writePNG(
            pixels: [UInt8](
                repeating: 255,
                count: width * height * 4
            ),
            width: width,
            height: height,
            to: url
        )
    }

    private func writePNG(
        pixels: [UInt8],
        width: Int,
        height: Int,
        to url: URL
    ) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let data = Data(pixels) as CFData
        let provider = try XCTUnwrap(
            CGDataProvider(data: data)
        )
        let image = try XCTUnwrap(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(
                    rawValue: CGImageAlphaInfo.last.rawValue
                ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }
}
