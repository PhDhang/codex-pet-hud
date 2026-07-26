import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PetWindowLocatorTests: XCTestCase {
    func testExactMascotEffectWins() {
        let selected = PetWindowLocator.select(
            from: [
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: "Codex",
                    layer: 3,
                    bounds: CGRect(
                        x: 0,
                        y: 840,
                        width: 384,
                        height: 122
                    ),
                    ownerPID: 1,
                    windowID: 10
                ),
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: "Codex Pet Mascot Effect",
                    layer: 2,
                    bounds: CGRect(
                        x: 24,
                        y: 775,
                        width: 243,
                        height: 252
                    ),
                    ownerPID: 1,
                    windowID: 11
                ),
            ]
        )

        XCTAssertEqual(
            selected?.name,
            "Codex Pet Mascot Effect"
        )
        XCTAssertEqual(selected?.windowID, 11)
    }

    func testNonChatGPTOwnerCannotMatchExactWindowName() {
        let selected = PetWindowLocator.select(
            from: [
                WindowDescriptor(
                    owner: "Other",
                    name: "Codex Pet Mascot Effect",
                    layer: 2,
                    bounds: CGRect(
                        x: 24,
                        y: 775,
                        width: 243,
                        height: 252
                    ),
                    ownerPID: 2,
                    windowID: 12
                ),
            ]
        )

        XCTAssertNil(selected)
    }

    func testSingleConservativeFallbackCanMatch() {
        let fallback = WindowDescriptor(
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
            windowID: 13
        )

        XCTAssertEqual(
            PetWindowLocator.select(from: [fallback]),
            fallback
        )
    }

    func testAmbiguousFallbackReturnsNil() {
        let candidates = [
            WindowDescriptor(
                owner: "ChatGPT",
                name: "",
                layer: 2,
                bounds: CGRect(
                    x: 0,
                    y: 0,
                    width: 240,
                    height: 250
                ),
                ownerPID: 1,
                windowID: 14
            ),
            WindowDescriptor(
                owner: "ChatGPT",
                name: "",
                layer: 2,
                bounds: CGRect(
                    x: 300,
                    y: 0,
                    width: 240,
                    height: 250
                ),
                ownerPID: 1,
                windowID: 15
            ),
        ]

        XCTAssertNil(PetWindowLocator.select(from: candidates))
    }

    func testFallbackRejectsOversizedWindow() {
        let oversized = WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 2,
            bounds: CGRect(
                x: 0,
                y: 0,
                width: 768,
                height: 912
            ),
            ownerPID: 1,
            windowID: 16
        )

        XCTAssertNil(PetWindowLocator.select(from: [oversized]))
    }
}

