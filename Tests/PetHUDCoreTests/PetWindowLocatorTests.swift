import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PetWindowLocatorTests: XCTestCase {
    func testIdleShellReportsPresenceWithoutExactGeometry() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "Codex Pet Composition Surface",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 80
                ),
                descriptor(
                    name: "Codex Pet Voice Controls Backing",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 81
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertTrue(observation.hasStablePresence)
    }

    func testUnrelatedChatGPTWindowDoesNotReportPetPresence() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "ChatGPT",
                    layer: 0,
                    width: 1200,
                    height: 800,
                    id: 82
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertFalse(observation.hasStablePresence)
    }

    func testTitleRedactedIdleShellNeedsCompanionCluster() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 83
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 84
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 345,
                    height: 54,
                    id: 85
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertTrue(observation.hasStablePresence)
    }

    func testTitleRedactedIdleShellRejectsCrossProcessCluster() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 86
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 87,
                    ownerPID: 2
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 345,
                    height: 54,
                    id: 88
                ),
            ]
        )

        XCTAssertFalse(observation.hasStablePresence)
    }

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

    func testExactMascotMatchesAfterLargeResize() {
        let resized = WindowDescriptor(
            owner: "ChatGPT",
            name: PetWindowLocator.exactWindowName,
            layer: 2,
            bounds: CGRect(
                x: 493,
                y: 598,
                width: 378,
                height: 393
            ),
            ownerPID: 1,
            windowID: 99
        )

        XCTAssertEqual(
            PetWindowLocator.select(from: [resized]),
            resized
        )
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
            PetWindowLocator.select(
                from: [
                    fallback,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 30
                    ),
                ]
            ),
            fallback
        )
    }

    func testFallbackMatchesLargeResizedPet() {
        let resized = WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 2,
            bounds: CGRect(
                x: 493,
                y: 598,
                width: 378,
                height: 393
            ),
            ownerPID: 1,
            windowID: 17
        )

        XCTAssertEqual(
            PetWindowLocator.select(
                from: [
                    resized,
                    voiceControl(
                        x: 746,
                        y: 699,
                        id: 31
                    ),
                ]
            ),
            resized
        )
    }

    func testFallbackRejectsUntitledWindowWithoutVoiceControl() {
        let unrelated = WindowDescriptor(
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
            windowID: 32
        )

        XCTAssertNil(
            PetWindowLocator.select(from: [unrelated])
        )
    }

    func testFallbackRejectsPartiallyOverlappingVoiceControl() {
        let unrelated = WindowDescriptor(
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
            windowID: 38
        )

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    unrelated,
                    voiceControl(
                        x: 254,
                        y: 820,
                        id: 39
                    ),
                ]
            )
        )
    }

    func testFallbackRejectsVoiceControlFromDifferentProcess() {
        let unrelated = WindowDescriptor(
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
            windowID: 40
        )

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    unrelated,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 41,
                        ownerPID: 2
                    ),
                ]
            )
        )
    }

    func testFallbackRejectsNonMascotAspectRatio() {
        let unrelated = WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 2,
            bounds: CGRect(
                x: 20,
                y: 700,
                width: 300,
                height: 250
            ),
            ownerPID: 1,
            windowID: 33
        )

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    unrelated,
                    voiceControl(
                        x: 200,
                        y: 800,
                        id: 34
                    ),
                ]
            )
        )
    }

    func testFallbackRejectsNamedUnrelatedWindow() {
        let unrelated = WindowDescriptor(
            owner: "ChatGPT",
            name: "Unrelated Overlay",
            layer: 2,
            bounds: CGRect(
                x: 24,
                y: 775,
                width: 243,
                height: 252
            ),
            ownerPID: 1,
            windowID: 18
        )

        XCTAssertNil(
            PetWindowLocator.select(from: [unrelated])
        )
    }

    func testFallbackRejectsLayerThreeWindow() {
        let unrelated = WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 3,
            bounds: CGRect(
                x: 24,
                y: 775,
                width: 243,
                height: 252
            ),
            ownerPID: 1,
            windowID: 19
        )

        XCTAssertNil(
            PetWindowLocator.select(from: [unrelated])
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
            voiceControl(
                x: 100,
                y: 100,
                id: 35
            ),
            voiceControl(
                x: 400,
                y: 100,
                id: 36
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

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    oversized,
                    voiceControl(
                        x: 300,
                        y: 300,
                        id: 37
                    ),
                ]
            )
        )
    }

    private func voiceControl(
        x: CGFloat,
        y: CGFloat,
        id: Int,
        ownerPID: Int = 1
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 3,
            bounds: CGRect(
                x: x,
                y: y,
                width: 24,
                height: 24
            ),
            ownerPID: ownerPID,
            windowID: id
        )
    }

    private func descriptor(
        name: String,
        layer: Int,
        width: CGFloat,
        height: CGFloat,
        id: Int,
        ownerPID: Int = 1
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: name,
            layer: layer,
            bounds: CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            ),
            ownerPID: ownerPID,
            windowID: id
        )
    }
}
