import Foundation
import XCTest
@testable import PetHUDCore

final class AppConfigurationTests: XCTestCase {
    func testMissingFileReturnsDefaults() throws {
        try withTemporaryDirectory { directory in
            let configuration = try AppConfiguration.load(
                url: directory.appendingPathComponent("missing.json"),
                homeDirectory: directory
            )

            XCTAssertEqual(configuration, .defaults)
        }
    }

    func testClampsUnsafeValuesAndExpandsPetPath() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("config.json")
            try Data(
                """
                {
                  "petPath": "~/.codex/pets/yicha",
                  "refreshIntervalSeconds": 5,
                  "criticalThresholdPercent": 40,
                  "nameplateOffset": -500,
                  "podScale": 9,
                  "podOffsetX": -900,
                  "podOffsetY": 900,
                  "launchAtLogin": false
                }
                """.utf8
            ).write(to: url)

            let configuration = try AppConfiguration.load(
                url: url,
                homeDirectory: directory
            )

            XCTAssertEqual(
                configuration.petPath,
                directory.appendingPathComponent(
                    ".codex/pets/yicha"
                ).path
            )
            XCTAssertEqual(
                configuration.refreshIntervalSeconds,
                300
            )
            XCTAssertEqual(
                configuration.criticalThresholdPercent,
                10
            )
            XCTAssertEqual(configuration.nameplateOffset, -100)
            XCTAssertEqual(configuration.podScale, 1.6)
            XCTAssertEqual(configuration.podOffsetX, -300)
            XCTAssertEqual(configuration.podOffsetY, 300)
            XCTAssertFalse(configuration.launchAtLogin)
        }
    }

    func testMissingPodSettingsUseProportionalDefaults() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("config.json")
            try Data(
                """
                {
                  "nameplateOffset": 42
                }
                """.utf8
            ).write(to: url)

            let configuration = try AppConfiguration.load(
                url: url,
                homeDirectory: directory
            )

            XCTAssertEqual(configuration.podScale, 1.14)
            XCTAssertEqual(configuration.podOffsetX, 0)
            XCTAssertEqual(configuration.podOffsetY, 0)
            XCTAssertEqual(configuration.nameplateOffset, 42)
        }
    }

    func testPodScaleAllowsCompactTacticalHUD() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("config.json")
            try Data(
                """
                { "podScale": 0.65 }
                """.utf8
            ).write(to: url)

            let configuration = try AppConfiguration.load(
                url: url,
                homeDirectory: directory
            )

            XCTAssertEqual(configuration.podScale, 0.65)
        }
    }

    func testInvalidJSONReportsOnlyConfigurationPath() throws {
        try withTemporaryDirectory { directory in
            let url = directory.appendingPathComponent("config.json")
            try Data("not-json".utf8).write(to: url)

            XCTAssertThrowsError(
                try AppConfiguration.load(
                    url: url,
                    homeDirectory: directory
                )
            ) { error in
                XCTAssertEqual(
                    error as? AppConfigurationError,
                    .invalidConfiguration(url.path)
                )
                XCTAssertFalse(
                    String(describing: error).contains("not-json")
                )
            }
        }
    }
}
