import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PetWindowLocatorTests: XCTestCase {
    func testLoneVisualShellDoesNotReportStablePresence() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "Codex",
                    layer: 3,
                    width: 384,
                    height: 126,
                    id: 70,
                    ownerPID: 7
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertNil(observation.visualGeometry)
        XCTAssertFalse(observation.hasStablePresence)
        XCTAssertNil(observation.stablePresencePID)
    }

    func testVisualShellWithNamedCompanionRemainsStable() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "Codex",
                    layer: 3,
                    width: 384,
                    height: 126,
                    id: 71,
                    ownerPID: 7
                ),
                descriptor(
                    name: "Codex Pet Composition Surface",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 72,
                    ownerPID: 7
                ),
            ]
        )

        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(observation.stablePresencePID, 7)
    }

    func testShellDerivedGeometryRequiresQualifyingCompanionPID() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "",
                    layer: 2,
                    width: 243,
                    height: 252,
                    id: 73,
                    ownerPID: 1
                ),
                descriptor(
                    name: "Voice",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 74,
                    ownerPID: 1
                ),
                descriptor(
                    name: "Codex",
                    layer: 3,
                    width: 192,
                    height: 126,
                    id: 75,
                    ownerPID: 1
                ),
                descriptor(
                    name: "Codex Pet Composition Surface",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 76,
                    ownerPID: 2
                ),
            ]
        )

        XCTAssertEqual(observation.stablePresencePID, 2)
        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(
            observation.visualGeometry?.source,
            .mascotFallback
        )
    }

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
        XCTAssertEqual(observation.stablePresencePID, 1)
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
        XCTAssertEqual(observation.stablePresencePID, 1)
    }

    func testTitleRedactedIdleShellAcceptsCompactVoiceBacking() {
        let observation = PetWindowLocator.observe(
            from: redactedCluster(
                ownerPID: 7,
                startingID: 90,
                voiceHeight: 6
            )
        )

        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(observation.stablePresencePID, 7)
    }

    func testTitleRedactedIdleShellAcceptsExpandedVoiceBacking() {
        let observation = PetWindowLocator.observe(
            from: redactedCluster(
                ownerPID: 8,
                startingID: 100,
                voiceHeight: 74
            )
        )

        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(observation.stablePresencePID, 8)
    }

    func testTitleRedactedIdleShellRejectsTwoCompletePIDClusters() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: "",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 183,
                    ownerPID: 1
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 184,
                    ownerPID: 1
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 345,
                    height: 54,
                    id: 185,
                    ownerPID: 1
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 283,
                    ownerPID: 2
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 24,
                    height: 24,
                    id: 284,
                    ownerPID: 2
                ),
                descriptor(
                    name: "",
                    layer: 3,
                    width: 345,
                    height: 54,
                    id: 285,
                    ownerPID: 2
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertFalse(observation.hasStablePresence)
        XCTAssertNil(observation.stablePresencePID)
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
        XCTAssertNil(observation.stablePresencePID)
    }

    func testExactMascotAndNamedProbeFromDifferentPIDsFailClosed() {
        let observation = PetWindowLocator.observe(
            from: [
                WindowDescriptor(
                    owner: "ChatGPT",
                    name: PetWindowLocator.exactWindowName,
                    layer: 2,
                    bounds: CGRect(
                        x: 24,
                        y: 775,
                        width: 243,
                        height: 252
                    ),
                    ownerPID: 1,
                    windowID: 300
                ),
                descriptor(
                    name: "Codex Pet Composition Surface",
                    layer: 3,
                    width: 768,
                    height: 912,
                    id: 301,
                    ownerPID: 2
                ),
            ]
        )

        XCTAssertNotNil(observation.exactWindow)
        XCTAssertFalse(observation.hasStablePresence)
        XCTAssertNil(observation.stablePresencePID)
    }

    func testNamedAndRedactedSignalsFromDifferentPIDsFailClosed() {
        let observation = PetWindowLocator.observe(
            from:
                [
                    descriptor(
                        name: "Codex Pet Activity Stack Backing",
                        layer: 3,
                        width: 345,
                        height: 54,
                        id: 310,
                        ownerPID: 1
                    ),
                ] +
                redactedCluster(
                    ownerPID: 2,
                    startingID: 320
                )
        )

        XCTAssertFalse(observation.hasStablePresence)
        XCTAssertNil(observation.stablePresencePID)
    }

    func testNamedAndRedactedSignalsForOnePIDRemainStable() {
        let observation = PetWindowLocator.observe(
            from:
                [
                    descriptor(
                        name: "Codex",
                        layer: 3,
                        width: 384,
                        height: 126,
                        id: 330,
                        ownerPID: 7
                    ),
                    descriptor(
                        name: "Codex Pet Composition Surface",
                        layer: 3,
                        width: 768,
                        height: 912,
                        id: 331,
                        ownerPID: 7
                    ),
                ] +
                redactedCluster(
                    ownerPID: 7,
                    startingID: 340
                )
        )

        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(observation.stablePresencePID, 7)
    }

    func testDuplicateExactMascotWindowsFromSamePIDAreExplicitlyAmbiguous() {
        let observation = PetWindowLocator.observe(
            from: [
                descriptor(
                    name: PetWindowLocator.exactWindowName,
                    layer: 2,
                    width: 243,
                    height: 252,
                    id: 345,
                    ownerPID: 7
                ),
                descriptor(
                    name: PetWindowLocator.exactWindowName,
                    layer: 2,
                    width: 243,
                    height: 252,
                    id: 346,
                    ownerPID: 7
                ),
            ]
        )

        XCTAssertNil(observation.exactWindow)
        XCTAssertNil(observation.visualGeometry)
        XCTAssertTrue(observation.hasStablePresence)
        XCTAssertEqual(observation.stablePresencePID, 7)
        XCTAssertTrue(observation.hasExactWindowAmbiguity)
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

    func testLiveWindowFixtureDerivesVisualPetFrameFromCodexShell() throws {
        let shell = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 3,
            bounds: CGRect(
                x: 52,
                y: 749,
                width: 384,
                height: 126
            ),
            ownerPID: 51_007,
            windowID: 102
        )
        let observation = PetWindowLocator.observe(
            from: liveWindowFixture(shell: shell)
        )

        XCTAssertEqual(
            observation.exactWindow?.bounds,
            CGRect(x: 105, y: 683, width: 249, height: 259)
        )
        let exact = try XCTUnwrap(observation.exactWindow)
        let visual = try XCTUnwrap(observation.visualWindow)
        XCTAssertEqual(
            observation.visualGeometry?.source,
            .shellDerived
        )
        XCTAssertEqual(visual.ownerPID, 51_007)
        XCTAssertEqual(visual.windowID, shell.windowID)
        XCTAssertEqual(visual.bounds.height, 126, accuracy: 0.001)
        XCTAssertEqual(
            visual.bounds.width,
            126 * 192 / 208,
            accuracy: 0.001
        )
        XCTAssertEqual(
            visual.bounds.midX,
            exact.bounds.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            visual.bounds.midY,
            exact.bounds.midY,
            accuracy: 0.001
        )
    }

    func testLiveOffsetFixtureUsesMascotCenterAndShellHeight() throws {
        let mascotBounds = CGRect(
            x: 30,
            y: 643,
            width: 249,
            height: 259
        )
        let shell = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
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

        let observation = PetWindowLocator.observe(
            from: liveWindowFixture(
                shell: shell,
                mascotBounds: mascotBounds
            )
        )
        let visualGeometry = try XCTUnwrap(
            observation.visualGeometry
        )

        XCTAssertEqual(visualGeometry.source, .shellDerived)
        XCTAssertEqual(
            visualGeometry.window.bounds.midX,
            mascotBounds.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            visualGeometry.window.bounds.midY,
            mascotBounds.midY,
            accuracy: 0.001
        )
        XCTAssertEqual(
            visualGeometry.window.bounds.width,
            126 * 192 / 208,
            accuracy: 0.001
        )
        XCTAssertEqual(
            visualGeometry.window.bounds.height,
            126,
            accuracy: 0.001
        )
    }

    func testVisualShellMustShareMascotPIDAndUseLayerThree() throws {
        let differentPID = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 3,
            bounds: CGRect(x: 52, y: 749, width: 384, height: 126),
            ownerPID: 51_008,
            windowID: 103
        )
        let mainWindow = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 0,
            bounds: CGRect(x: 52, y: 749, width: 384, height: 126),
            ownerPID: 51_007,
            windowID: 104
        )

        for shell in [differentPID, mainWindow] {
            let observation = PetWindowLocator.observe(
                from: liveWindowFixture(shell: shell)
            )
            XCTAssertEqual(
                observation.visualGeometry?.source,
                .mascotFallback
            )
            let visual = try XCTUnwrap(observation.visualWindow)
            XCTAssertLessThan(visual.bounds.width, 130)
            XCTAssertLessThan(visual.bounds.height, 140)
            XCTAssertEqual(
                visual.bounds.midX,
                229.5,
                accuracy: 0.001
            )
        }
    }

    func testVisualPetFrameTracksShellMovementAndResize() throws {
        let initialShell = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 3,
            bounds: CGRect(x: 52, y: 749, width: 384, height: 126),
            ownerPID: 51_007,
            windowID: 102
        )
        let resizedShell = WindowDescriptor(
            owner: "ChatGPT",
            name: "Codex",
            layer: 3,
            bounds: CGRect(x: 300, y: 500, width: 500, height: 208),
            ownerPID: 51_007,
            windowID: 102
        )

        let initial = try XCTUnwrap(
            PetWindowLocator.observe(
                from: liveWindowFixture(shell: initialShell)
            ).visualWindow
        )
        let resized = try XCTUnwrap(
            PetWindowLocator.observe(
                from: liveWindowFixture(
                    shell: resizedShell,
                    mascotBounds: CGRect(
                        x: 410,
                        y: 450,
                        width: 280,
                        height: 310
                    )
                )
            ).visualWindow
        )

        XCTAssertEqual(initial.bounds.midX, 229.5, accuracy: 0.001)
        XCTAssertEqual(initial.bounds.midY, 812.5, accuracy: 0.001)
        XCTAssertEqual(initial.bounds.width, 126 * 192 / 208, accuracy: 0.001)
        XCTAssertEqual(initial.bounds.height, 126, accuracy: 0.001)
        XCTAssertEqual(resized.bounds.midX, 550, accuracy: 0.001)
        XCTAssertEqual(resized.bounds.midY, 605, accuracy: 0.001)
        XCTAssertEqual(resized.bounds.width, 192, accuracy: 0.001)
        XCTAssertEqual(resized.bounds.height, 208, accuracy: 0.001)
    }

    func testMascotBoundsRemainVisualFallbackWithoutShell() throws {
        let windows = liveWindowFixture(
            shell: WindowDescriptor(
                owner: "Other",
                name: "Codex",
                layer: 3,
                bounds: CGRect(x: 52, y: 749, width: 384, height: 126),
                ownerPID: 51_007,
                windowID: 102
            )
        )

        let observation = PetWindowLocator.observe(from: windows)

        let visual = try XCTUnwrap(observation.visualWindow)
        XCTAssertEqual(
            observation.visualGeometry?.source,
            .mascotFallback
        )
        XCTAssertLessThan(visual.bounds.width, 130)
        XCTAssertLessThan(visual.bounds.height, 140)
        XCTAssertEqual(visual.bounds.midX, 229.5, accuracy: 0.001)
        XCTAssertEqual(visual.bounds.midY, 812.5, accuracy: 0.001)
        XCTAssertTrue(observation.hasStablePresence)
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

    func testSingleConservativeFallbackAcceptsCompactVoiceBacking() {
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
            windowID: 14
        )

        XCTAssertEqual(
            PetWindowLocator.select(
                from: [
                    fallback,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 42,
                        height: 6
                    ),
                ]
            ),
            fallback
        )
    }

    func testSingleConservativeFallbackAcceptsExpandedVoiceBacking() {
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
            windowID: 16
        )

        XCTAssertEqual(
            PetWindowLocator.select(
                from: [
                    fallback,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 44,
                        height: 74
                    ),
                ]
            ),
            fallback
        )
    }

    func testConservativeFallbackRejectsVoiceBackingBelowHeightFloor() {
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
            windowID: 15
        )

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    fallback,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 43,
                        height: 5
                    ),
                ]
            )
        )
    }

    func testConservativeFallbackRejectsVoiceBackingAboveHeightCeiling() {
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
            windowID: 17
        )

        XCTAssertNil(
            PetWindowLocator.select(
                from: [
                    fallback,
                    voiceControl(
                        x: 180,
                        y: 820,
                        id: 45,
                        height: 81
                    ),
                ]
            )
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
        ownerPID: Int = 1,
        height: CGFloat = 24
    ) -> WindowDescriptor {
        WindowDescriptor(
            owner: "ChatGPT",
            name: "",
            layer: 3,
            bounds: CGRect(
                x: x,
                y: y,
                width: 24,
                height: height
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

    private func liveWindowFixture(
        shell: WindowDescriptor,
        mascotBounds: CGRect = CGRect(
            x: 105,
            y: 683,
            width: 249,
            height: 259
        )
    ) -> [WindowDescriptor] {
        [
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
                name: "Codex Pet Voice Controls Backing",
                layer: 3,
                bounds: CGRect(x: 220, y: 760, width: 24, height: 24),
                ownerPID: 51_007,
                windowID: 105
            ),
            WindowDescriptor(
                owner: "ChatGPT",
                name: "Codex Pet Activity Stack Backing",
                layer: 3,
                bounds: CGRect(x: 0, y: 0, width: 345, height: 54),
                ownerPID: 51_007,
                windowID: 106
            ),
            WindowDescriptor(
                owner: "ChatGPT",
                name: "Codex Pet Composition Surface",
                layer: 3,
                bounds: CGRect(x: 0, y: 0, width: 768, height: 912),
                ownerPID: 51_007,
                windowID: 107
            ),
        ]
    }

    private func redactedCluster(
        ownerPID: Int,
        startingID: Int,
        voiceHeight: CGFloat = 24
    ) -> [WindowDescriptor] {
        [
            descriptor(
                name: "",
                layer: 3,
                width: 768,
                height: 912,
                id: startingID,
                ownerPID: ownerPID
            ),
            descriptor(
                name: "",
                layer: 3,
                width: 24,
                height: voiceHeight,
                id: startingID + 1,
                ownerPID: ownerPID
            ),
            descriptor(
                name: "",
                layer: 3,
                width: 345,
                height: 54,
                id: startingID + 2,
                ownerPID: ownerPID
            ),
        ]
    }
}
