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

    func testV2PetsRenderLowAndCriticalHUDWithoutEffectMetadata() throws {
        try withTemporaryDirectory { root in
            let pets = [
                (
                    directory: try makePet(
                        root: root,
                        id: "yicha",
                        displayName: "一茬",
                        version: 2
                    ),
                    displayName: "一茬"
                ),
                (
                    directory: try makePet(
                        root: root,
                        id: "pixel-cat",
                        displayName: "Pixel Cat",
                        version: 2
                    ),
                    displayName: "Pixel Cat"
                ),
            ]
            let now = Date(timeIntervalSince1970: 10_000)

            for pet in pets {
                let manifest = try PetManifest.load(directory: pet.directory)
                let low = HUDPresentationData.make(
                    manifest: manifest,
                    state: .quota(
                        snapshot: snapshot(remaining: 8, now: now),
                        band: .low
                    ),
                    now: now
                )
                XCTAssertEqual(low.petName, pet.displayName)
                XCTAssertEqual(low.statusLabel, "PANIC · QUOTA LOW")

                let critical = HUDPresentationData.make(
                    manifest: manifest,
                    state: .quota(
                        snapshot: snapshot(remaining: 2, now: now),
                        band: .critical
                    ),
                    now: now
                )
                XCTAssertEqual(critical.petName, pet.displayName)
                XCTAssertEqual(
                    critical.statusLabel,
                    "EXHAUSTED · SIGNAL CRITICAL"
                )
            }
        }
    }

    private func snapshot(
        remaining: Double,
        now: Date
    ) -> QuotaSnapshot {
        QuotaSnapshot(
            weekly: QuotaWindow(
                usedPercent: 100 - remaining,
                resetAt: now.addingTimeInterval(3_600),
                windowDurationSeconds: 604_800
            ),
            fetchedAt: now
        )
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
