import CoreGraphics
import Foundation
import XCTest
@testable import PetHUDCore

final class NativePetWindowLocatorTests: XCTestCase {
    // Live, redacted CGWindow metadata from ChatGPT 26.901.31953.
    func testSeptemberNativeContainerFindsVisualPet() throws {
        let observation = observe([container()])
        let geometry = try XCTUnwrap(observation.visualGeometry)
        XCTAssertEqual(geometry.source, .nativeContainer)
        XCTAssertEqual(geometry.window.bounds, CGRect(x: 160.5, y: 621.5, width: 97, height: 106))
        XCTAssertEqual(observation.stablePresencePID, 7)
        XCTAssertEqual(PetWindowDiagnosticStatus.resolve(
            observation: observation, cachedGeometry: nil, now: Date()
        ), .found)
    }

    func testMovingContainerMovesPetWithoutSavedAnchor() throws {
        let geometry = try XCTUnwrap(observe([container(x: 137, y: -190)]).visualGeometry)
        XCTAssertEqual(geometry.window.bounds, CGRect(x: 460.5, y: 821.5, width: 97, height: 106))
    }

    func testResizeUsesCurrentPetSizeAndSameCenter() throws {
        let geometry = try XCTUnwrap(observe([container()], width: 160).visualGeometry)
        XCTAssertEqual(geometry.window.bounds, CGRect(x: 129, y: 587.5, width: 160, height: 174))
    }

    func testMenuBarAndExternalDisplayHeightAreAccountedFor() throws {
        let displays = [CGRect(x: 0, y: 25, width: 1920, height: 1055),
                        CGRect(x: 1920, y: 25, width: 2560, height: 1415)]
        let geometry = try XCTUnwrap(observe(
            [container(x: 2000, y: -700, height: 2799)], displays: displays
        ).visualGeometry)
        XCTAssertEqual(geometry.window.bounds.midX, 2372)
        XCTAssertEqual(geometry.window.bounds.midY, 699.5)
    }

    func testUnverifiedOwnerCannotImpersonatePet() {
        XCTAssertNil(observe([container(pid: 8)]).visualGeometry)
    }

    func testMainWindowOrQuickChatCannotImpersonatePet() {
        for window in [container(layer: 0), container(width: 384, height: 400),
                       container(width: 852), container(name: "Unrelated") ] {
            XCTAssertNil(observe([window]).visualGeometry)
        }
    }

    func testDuplicateNativeWindowsFailClosedEvenWithOldCache() {
        let observation = observe([container(), container(id: 2)])
        XCTAssertNil(observation.visualGeometry)
        XCTAssertTrue(observation.hasExactWindowAmbiguity)
        XCTAssertEqual(PetWindowDiagnosticStatus.resolve(
            observation: observation, cachedGeometry: oldGeometry(), now: Date()
        ), .missing)
    }

    func testRedactedTitleStillRequiresVerifiedOwnerAndExactShape() {
        XCTAssertNotNil(observe([container(name: "")]).visualGeometry)
        XCTAssertNil(observe([container(width: 773.5, name: "")]).visualGeometry)
    }

    func testClosedHiddenOrOffscreenPetIsMissing() {
        XCTAssertNil(observe([container()], open: false).visualGeometry)
        XCTAssertNil(observe([container()], visible: false).visualGeometry)
        XCTAssertNil(observe([container(x: 10000)]).visualGeometry)
        XCTAssertNil(observe([]).visualGeometry)
    }

    func testNewNativeGeometryReplacesStaleDifferentPIDCache() {
        let observation = observe([container()])
        var tracker = PetPresenceTracker(restoredGeometry: oldGeometry())
        XCTAssertEqual(tracker.update(observation: observation, now: Date()), observation.visualGeometry)
        XCTAssertEqual(PetWindowDiagnosticStatus.resolve(
            observation: observation, cachedGeometry: oldGeometry(), now: Date()
        ), .found)
    }

    func testNativeGeometryIsNeverPersistedAsLegacyShell() throws {
        let geometry = try XCTUnwrap(observe([container()]).visualGeometry)
        XCTAssertFalse(PetGeometryPersistenceState().needsPersistence(geometry))
    }

    func testLegacyAndNativePetTogetherAreAmbiguous() {
        let legacy = WindowDescriptor(owner: "ChatGPT", name: PetWindowLocator.exactWindowName,
                                      layer: 2, bounds: CGRect(x: 0, y: 0, width: 243, height: 252),
                                      ownerPID: 8, windowID: 3)
        let observation = observe([container(), legacy])
        XCTAssertTrue(observation.hasExactWindowAmbiguity)
        XCTAssertNil(observation.visualGeometry)
    }

    func testClosedNativePetStopsRenderingAfterAbsenceGrace() {
        var tracker = PetPresenceTracker()
        let now = Date(timeIntervalSince1970: 100)
        XCTAssertNotNil(tracker.update(observation: observe([container()]), now: now))
        let closed = observe([container()], open: false)
        XCTAssertNotNil(tracker.update(observation: closed, now: now.addingTimeInterval(1)))
        XCTAssertNotNil(tracker.update(observation: closed, now: now.addingTimeInterval(2)))
        XCTAssertNil(tracker.update(observation: closed, now: now.addingTimeInterval(3)))
    }

    func testNativeRejectsRedactedLegacyFallbackOrAmbiguousCompanions() {
        let mascot = WindowDescriptor(owner: "ChatGPT", name: "", layer: 2,
            bounds: CGRect(x: 0, y: 0, width: 243, height: 252), ownerPID: 8, windowID: 2)
        let voice = WindowDescriptor(owner: "ChatGPT", name: "", layer: 3,
            bounds: CGRect(x: 10, y: 10, width: 24, height: 24), ownerPID: 8, windowID: 3)
        let companions = [8, 9].map { pid in
            WindowDescriptor(owner: "ChatGPT", name: "Codex Pet Composition Surface", layer: 3,
                bounds: CGRect(x: 0, y: 0, width: 768, height: 912), ownerPID: pid, windowID: pid)
        }
        let secondMascot = WindowDescriptor(owner: "ChatGPT", name: "", layer: 2,
            bounds: CGRect(x: 0, y: 0, width: 243, height: 252), ownerPID: 9, windowID: 4)
        let secondVoice = WindowDescriptor(owner: "ChatGPT", name: "", layer: 3,
            bounds: CGRect(x: 10, y: 10, width: 24, height: 24), ownerPID: 9, windowID: 5)
        for legacy in [[mascot, voice], [mascot, voice, secondMascot, secondVoice], companions] {
            let observation = observe([container()] + legacy)
            XCTAssertTrue(observation.hasExactWindowAmbiguity)
            XCTAssertNil(observation.visualGeometry)
        }
    }

    func testUnsupportedDesktopTOMLSyntaxDoesNotSilentlyShowHiddenPet() {
        let data = Data(#"{"electron-avatar-overlay-open":true}"#.utf8)
        for config in ["desktop.avatar-overlay-pet-visible = false",
                       "desktop = { avatar-overlay-pet-visible = false }",
                       "\"desktop\".'avatar-overlay-pet-visible' = false",
                       "desktop . avatar-overlay-pet-visible = false",
                       #"["\u0064esktop"]"# + "\navatar-overlay-pet-visible = false",
                       "[desktop]\n" + #""avatar-overlay-\u0070et-visible" = false"#] {
            XCTAssertNil(NativePetSettings.parse(globalState: data, configTOML: config))
        }
        XCTAssertEqual(NativePetSettings.parse(globalState: data,
            configTOML: "[ desktop ]\navatar-overlay-pet-visible = false")?.petVisible, false)
    }

    func testSettingsReaderReloadsChangesAndDoesNotReuseInvalidState() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }
        let state = home.appendingPathComponent(".codex-global-state.json")
        let config = home.appendingPathComponent("config.toml")
        try Data(#"{"electron-avatar-overlay-open":true}"#.utf8).write(to: state)
        try Data("[desktop]\navatar-overlay-mascot-width-px = 97".utf8).write(to: config)
        var reader = NativePetSettingsReader()
        XCTAssertEqual(reader.load(codexHome: home)?.mascotWidth, 97)
        XCTAssertEqual(reader.load(codexHome: home)?.mascotWidth, 97)
        try Data("[desktop]\navatar-overlay-mascot-width-px = 160".utf8).write(to: config)
        XCTAssertEqual(reader.load(codexHome: home)?.mascotWidth, 160)
        try Data(#"{"electron-avatar-overlay-open":false}"#.utf8).write(to: state)
        XCTAssertEqual(reader.load(codexHome: home)?.overlayOpen, false)
        try Data("invalid".utf8).write(to: state)
        XCTAssertNil(reader.load(codexHome: home))
        XCTAssertNil(reader.load(codexHome: home))
    }

    func testSettingsReadOnlyKnownDesktopKeys() throws {
        let settings = try XCTUnwrap(NativePetSettings.parse(
            globalState: Data(#"{"electron-avatar-overlay-open":true,"unrelated":"ignored"}"#.utf8),
            configTOML: """
            avatar-overlay-mascot-width-px = 200
            [desktop]
            avatar-overlay-mascot-width-px = 97 # current size
            avatar-overlay-pet-visible = true
            [unrelated]
            avatar-overlay-mascot-width-px = 224
            """
        ))
        XCTAssertTrue(settings.overlayOpen)
        XCTAssertTrue(settings.petVisible)
        XCTAssertEqual(settings.mascotWidth, 97)
    }

    func testSettingsUseDocumentedDefaultsAndFailClosedOnMalformedValues() throws {
        let data = Data(#"{"electron-avatar-overlay-open":true}"#.utf8)
        XCTAssertEqual(NativePetSettings.parse(globalState: data, configTOML: "")?.mascotWidth, 112)
        for value in ["79", "225", "\"97\"", "invalid", "97\navatar-overlay-mascot-width-px = 98"] {
            XCTAssertNil(NativePetSettings.parse(globalState: data,
                configTOML: "[desktop]\navatar-overlay-mascot-width-px = \(value)"))
        }
        XCTAssertNil(NativePetSettings.parse(globalState: Data("{}".utf8), configTOML: ""))
        XCTAssertNil(NativePetSettings.parse(globalState: Data("bad".utf8), configTOML: ""))
        XCTAssertEqual(NativePetSettings.parse(globalState: data,
            configTOML: "[desktop]\navatar-overlay-pet-visible = false")?.petVisible, false)
    }

    func testUnrelatedNestedTOMLArraysDoNotDisableNativePet() {
        let data = Data(#"{"electron-avatar-overlay-open":true}"#.utf8)
        let config = """
        [desktop]
        avatar-overlay-mascot-width-px = 97
        [notice]
        model_migrations = [
          ["model-a", "model-b"],
          ["model-c", "model-d"],
        ]
        """
        XCTAssertEqual(NativePetSettings.parse(globalState: data, configTOML: config)?.mascotWidth, 97)
    }

    func testHashInsideQuotedUnrelatedTableKeyIsNotAComment() {
        let data = Data(#"{"electron-avatar-overlay-open":true}"#.utf8)
        let config = """
        [desktop]
        avatar-overlay-mascot-width-px = 97
        [plugins.entries."example#variant"]
        enabled = true
        """
        XCTAssertEqual(NativePetSettings.parse(globalState: data, configTOML: config)?.mascotWidth, 97)
    }

    private func observe(_ windows: [WindowDescriptor], width: CGFloat = 97,
                         open: Bool = true, visible: Bool = true,
                         displays: [CGRect] = [CGRect(x: 0, y: 0, width: 1920, height: 1080)]) -> PetWindowObservation {
        PetWindowLocator.observe(from: windows, nativeContext: NativePetWindowContext(
            settings: NativePetSettings(overlayOpen: open, petVisible: visible, mascotWidth: width),
            displays: displays, verifiedOwnerPIDs: [7]
        ))
    }

    private func container(x: CGFloat = -163, y: CGFloat = -390,
                           width: CGFloat = 772, height: CGFloat = 2129,
                           name: String = "ChatGPT", layer: Int = 3,
                           pid: Int = 7, id: Int = 1) -> WindowDescriptor {
        WindowDescriptor(owner: "ChatGPT", name: name, layer: layer,
                         bounds: CGRect(x: x, y: y, width: width, height: height), ownerPID: pid, windowID: id)
    }

    private func oldGeometry() -> PetVisualGeometry {
        PetVisualGeometry(window: container(pid: 1607), source: .shellDerived)
    }
}
