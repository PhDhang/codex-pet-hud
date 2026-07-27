import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PanelGeometryTests: XCTestCase {
    private let display = DisplayDescriptor(
        cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )

    func testConvertsPetRectFromTopLeftToAppKitCoordinates() throws {
        let pet = CGRect(x: 24, y: 775, width: 243, height: 252)

        let converted = try XCTUnwrap(
            PanelGeometry.appKitPetFrame(
                pet: pet,
                displays: [display]
            )
        )

        XCTAssertEqual(converted, CGRect(x: 24, y: 53, width: 243, height: 252))
    }

    func testTacticalHUDScalesAbovePetCenter() throws {
        let pet = CGRect(x: 24, y: 775, width: 200, height: 250)

        let frame = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: pet,
                displays: [display],
                scale: 1,
                offset: .zero
            )
        )

        XCTAssertEqual(frame.width, 210, accuracy: 0.001)
        XCTAssertEqual(frame.height, 58, accuracy: 0.001)
        XCTAssertEqual(frame.midX, 124, accuracy: 0.001)
        XCTAssertGreaterThan(frame.minY, 305)
    }

    func testLiveVisualFrameProducesCompactDefaultHUDAndEffect() throws {
        let visualPet = CGRect(
            x: 244 - (126 * 192 / 208) / 2,
            y: 749,
            width: 126 * 192 / 208,
            height: 126
        )

        let hud = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: visualPet,
                displays: [display],
                scale: 1.14,
                offset: .zero
            )
        )
        let effect = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: visualPet,
                displays: [display]
            )
        )

        XCTAssertEqual(hud.width, 239.4, accuracy: 0.001)
        XCTAssertEqual(hud.midX, 244, accuracy: 0.001)
        XCTAssertEqual(hud.minY, 339, accuracy: 0.001)
        XCTAssertEqual(
            effect.width,
            visualPet.width * 1.36 * 2,
            accuracy: 0.001
        )
        XCTAssertEqual(effect.height, 277.2, accuracy: 0.001)
        XCTAssertEqual(effect.midX, 244, accuracy: 0.001)
    }

    func testTacticalHUDPreservesOffsetsAfterResize() throws {
        let small = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: CGRect(
                    x: 24,
                    y: 775,
                    width: 200,
                    height: 250
                ),
                displays: [display],
                scale: 0.8,
                offset: CGPoint(x: 17, y: -12)
            )
        )
        let large = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: CGRect(
                    x: 24,
                    y: 650,
                    width: 320,
                    height: 400
                ),
                displays: [display],
                scale: 0.8,
                offset: CGPoint(x: 17, y: -12)
            )
        )

        XCTAssertEqual(small.midX - 124, 17, accuracy: 0.001)
        XCTAssertEqual(large.midX - 184, 17, accuracy: 0.001)
        XCTAssertGreaterThan(large.width, small.width)
    }

    func testTacticalHUDClampsAtDisplayTopEdge() throws {
        let frame = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: CGRect(x: 100, y: 0, width: 200, height: 250),
                displays: [display],
                scale: 1,
                offset: .zero
            )
        )

        XCTAssertEqual(frame.maxY, display.appKitFrame.maxY)
    }

    func testEffectFrameClampsAtDisplayBottomEdge() throws {
        let frame = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: CGRect(x: 100, y: 900, width: 200, height: 250),
                displays: [display]
            )
        )

        XCTAssertEqual(frame.minY, display.appKitFrame.minY)
    }

    func testFramesUseDisplayContainingMostOfPet() throws {
        let secondary = DisplayDescriptor(
            cgBounds: CGRect(x: 1920, y: 0, width: 1440, height: 900),
            appKitFrame: CGRect(x: 1920, y: 0, width: 1440, height: 900)
        )
        let pet = CGRect(x: 2000, y: 500, width: 240, height: 250)

        let tactical = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: pet,
                displays: [display, secondary],
                scale: 1,
                offset: .zero
            )
        )
        let effect = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: pet,
                displays: [display, secondary]
            )
        )

        XCTAssertTrue(secondary.appKitFrame.contains(tactical))
        XCTAssertTrue(secondary.appKitFrame.contains(effect))
    }

    func testFramesFitWithinSmallDisplay() throws {
        let smallDisplay = DisplayDescriptor(
            cgBounds: CGRect(x: 0, y: 0, width: 300, height: 200),
            appKitFrame: CGRect(x: 0, y: 0, width: 300, height: 200)
        )
        let pet = CGRect(x: 50, y: 25, width: 200, height: 150)

        let tactical = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: pet,
                displays: [smallDisplay],
                scale: 1.6,
                offset: .zero
            )
        )
        let effect = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: pet,
                displays: [smallDisplay]
            )
        )

        XCTAssertTrue(smallDisplay.appKitFrame.contains(tactical))
        XCTAssertTrue(smallDisplay.appKitFrame.contains(effect))
    }

    func testVisualPetEffectsStayContainedAtEveryDisplayEdge() throws {
        let visualSize = CGSize(
            width: 126 * 192 / 208,
            height: 126
        )
        let edgePets: [(name: String, frame: CGRect)] = [
            (
                "left",
                CGRect(
                    x: 0,
                    y: 220,
                    width: visualSize.width,
                    height: visualSize.height
                )
            ),
            (
                "right",
                CGRect(
                    x: display.cgBounds.maxX - visualSize.width,
                    y: 220,
                    width: visualSize.width,
                    height: visualSize.height
                )
            ),
            (
                "top",
                CGRect(
                    x: 420,
                    y: 0,
                    width: visualSize.width,
                    height: visualSize.height
                )
            ),
            (
                "bottom",
                CGRect(
                    x: 420,
                    y: display.cgBounds.maxY - visualSize.height,
                    width: visualSize.width,
                    height: visualSize.height
                )
            ),
        ]

        for sample in edgePets {
            let panel = try XCTUnwrap(
                PanelGeometry.petEffectFrame(
                    pet: sample.frame,
                    displays: [display]
                )
            )
            let appKitPet = try XCTUnwrap(
                PanelGeometry.appKitPetFrame(
                    pet: sample.frame,
                    displays: [display]
                )
            )
            let layout = PetEffectLayout(
                panelFrame: panel,
                petFrame: appKitPet
            )
            let localBounds = CGRect(
                origin: .zero,
                size: layout.panelSize
            )
            let leftPanicFrame = layout.localPetFrame.offsetBy(
                dx: -layout.leftTravel,
                dy: -layout.panicBounce
            )
            let rightPanicFrame = layout.localPetFrame.offsetBy(
                dx: layout.rightTravel,
                dy: -layout.panicBounce
            )

            XCTAssertTrue(
                display.appKitFrame.contains(panel),
                sample.name
            )
            XCTAssertTrue(
                localBounds.contains(layout.localPetFrame),
                sample.name
            )
            XCTAssertTrue(
                localBounds.contains(layout.localEffectFrame),
                sample.name
            )
            XCTAssertTrue(
                localBounds.contains(leftPanicFrame),
                sample.name
            )
            XCTAssertTrue(
                localBounds.contains(rightPanicFrame),
                sample.name
            )
            for scale in [1.0, 2.0] {
                XCTAssertTrue(
                    localBounds.contains(
                        layout.criticalImageFrame(
                            imageSize: CGSize(width: 192, height: 208),
                            scale: scale
                        )
                    ),
                    "\(sample.name) scale=\(scale)"
                )
            }

            if sample.name == "left" {
                XCTAssertEqual(layout.leftTravel, 0, accuracy: 0.001)
                XCTAssertGreaterThan(layout.rightTravel, 0)
            }
            if sample.name == "right" {
                XCTAssertGreaterThan(layout.leftTravel, 0)
                XCTAssertEqual(layout.rightTravel, 0, accuracy: 0.001)
            }
            if sample.name == "top" {
                XCTAssertEqual(layout.panicBounce, 0, accuracy: 0.001)
            }
        }
    }

    func testSmallDisplayConstrainsScaleTwoCriticalArt() throws {
        let visualSize = CGSize(
            width: 126 * 192 / 208,
            height: 126
        )
        let smallDisplay = DisplayDescriptor(
            cgBounds: CGRect(x: 0, y: 0, width: 140, height: 140),
            appKitFrame: CGRect(x: 0, y: 0, width: 140, height: 140)
        )
        let pet = CGRect(
            x: (smallDisplay.cgBounds.width - visualSize.width) / 2,
            y: (smallDisplay.cgBounds.height - visualSize.height) / 2,
            width: visualSize.width,
            height: visualSize.height
        )
        let panel = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: pet,
                displays: [smallDisplay]
            )
        )
        let appKitPet = try XCTUnwrap(
            PanelGeometry.appKitPetFrame(
                pet: pet,
                displays: [smallDisplay]
            )
        )
        let layout = PetEffectLayout(
            panelFrame: panel,
            petFrame: appKitPet
        )
        let localBounds = CGRect(
            origin: .zero,
            size: layout.panelSize
        )
        let critical = layout.criticalImageFrame(
            imageSize: CGSize(width: 192, height: 208),
            scale: 2
        )

        XCTAssertEqual(panel, smallDisplay.appKitFrame)
        XCTAssertTrue(localBounds.contains(layout.localEffectFrame))
        XCTAssertTrue(localBounds.contains(critical))
        XCTAssertLessThanOrEqual(critical.width, panel.width)
        XCTAssertLessThanOrEqual(critical.height, panel.height)
    }

    func testFramesUseOriginalPetDisplayWhenDisplaysAreVerticallyStacked() throws {
        let upperDisplay = DisplayDescriptor(
            cgBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            appKitFrame: CGRect(x: 0, y: 900, width: 1920, height: 1080)
        )
        let lowerDisplay = DisplayDescriptor(
            cgBounds: CGRect(x: 0, y: 1080, width: 1920, height: 900),
            appKitFrame: CGRect(x: 0, y: 0, width: 1920, height: 900)
        )
        let pet = CGRect(x: 300, y: 1200, width: 240, height: 250)

        let tactical = try XCTUnwrap(
            PanelGeometry.tacticalHUDFrame(
                pet: pet,
                displays: [upperDisplay, lowerDisplay],
                scale: 1,
                offset: .zero
            )
        )
        let effect = try XCTUnwrap(
            PanelGeometry.petEffectFrame(
                pet: pet,
                displays: [upperDisplay, lowerDisplay]
            )
        )

        XCTAssertTrue(lowerDisplay.appKitFrame.contains(tactical))
        XCTAssertTrue(lowerDisplay.appKitFrame.contains(effect))
    }
}
