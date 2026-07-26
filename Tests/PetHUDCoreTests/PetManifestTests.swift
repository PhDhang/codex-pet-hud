import Foundation
import XCTest
@testable import PetHUDCore

final class PetManifestTests: XCTestCase {
    func testLoadsV2Manifest() throws {
        try withTemporaryDirectory { root in
            let directory = try makePet(
                root: root,
                id: "test-pet",
                displayName: "测试宠物",
                version: 2
            )

            let manifest = try PetManifest.load(directory: directory)

            XCTAssertEqual(manifest.id, "test-pet")
            XCTAssertEqual(manifest.displayName, "测试宠物")
            XCTAssertEqual(manifest.spriteVersionNumber, 2)
            XCTAssertEqual(
                manifest.spritesheetURL,
                directory.appendingPathComponent("spritesheet.png")
            )
        }
    }

    func testRejectsNonV2Manifest() throws {
        try withTemporaryDirectory { root in
            let directory = try makePet(
                root: root,
                id: "old-pet",
                displayName: "旧宠物",
                version: 1
            )

            XCTAssertThrowsError(
                try PetManifest.load(directory: directory)
            ) { error in
                XCTAssertEqual(error as? PetManifestError, .unsupportedVersion)
            }
        }
    }

    func testRejectsSpritesheetOutsidePetDirectory() throws {
        try withTemporaryDirectory { root in
            let directory = root.appendingPathComponent(
                "unsafe",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try Data(
                """
                {
                  "id": "unsafe",
                  "displayName": "Unsafe",
                  "spriteVersionNumber": 2,
                  "spritesheetPath": "../outside.png"
                }
                """.utf8
            ).write(to: directory.appendingPathComponent("pet.json"))

            XCTAssertThrowsError(
                try PetManifest.load(directory: directory)
            ) { error in
                XCTAssertEqual(error as? PetManifestError, .unsafeSpritesheetPath)
            }
        }
    }

    func testAutoDiscoverySelectsOnlyValidPet() throws {
        try withTemporaryDirectory { root in
            let valid = try makePet(
                root: root,
                id: "valid",
                displayName: "Valid",
                version: 2
            )
            _ = try makePet(
                root: root,
                id: "old",
                displayName: "Old",
                version: 1
            )

            let discovered = try PetDiscovery.discover(
                configuredPath: nil,
                petsRoot: root
            )

            XCTAssertEqual(discovered?.directoryURL, valid)
        }
    }

    func testAutoDiscoveryReturnsNilWhenAmbiguous() throws {
        try withTemporaryDirectory { root in
            _ = try makePet(
                root: root,
                id: "one",
                displayName: "One",
                version: 2
            )
            _ = try makePet(
                root: root,
                id: "two",
                displayName: "Two",
                version: 2
            )

            XCTAssertNil(
                try PetDiscovery.discover(
                    configuredPath: nil,
                    petsRoot: root
                )
            )
        }
    }

    private func makePet(
        root: URL,
        id: String,
        displayName: String,
        version: Int
    ) throws -> URL {
        let directory = root.appendingPathComponent(
            id,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let manifest = """
        {
          "id": "\(id)",
          "displayName": "\(displayName)",
          "description": "Fixture pet",
          "spriteVersionNumber": \(version),
          "spritesheetPath": "spritesheet.png"
        }
        """
        try Data(manifest.utf8).write(
            to: directory.appendingPathComponent("pet.json")
        )
        try Data().write(
            to: directory.appendingPathComponent("spritesheet.png")
        )
        return directory
    }
}
