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
        XCTAssertEqual(frame.height, 75, accuracy: 0.001)
        XCTAssertEqual(frame.midX, 124, accuracy: 0.001)
        XCTAssertGreaterThan(frame.minY, 305)
    }

    func testLiveVisualFrameProducesCompactDefaultHUD() throws {
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
        XCTAssertEqual(hud.width, 239.4, accuracy: 0.001)
        XCTAssertEqual(hud.height, 85.5, accuracy: 0.001)
        XCTAssertEqual(hud.midX, 244, accuracy: 0.001)
        XCTAssertEqual(hud.minY, 339, accuracy: 0.001)
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

    func testTacticalHUDUsesDisplayContainingMostOfPet() throws {
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
        XCTAssertTrue(secondary.appKitFrame.contains(tactical))
    }

    func testTacticalHUDFitsWithinSmallDisplay() throws {
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
        XCTAssertTrue(smallDisplay.appKitFrame.contains(tactical))
    }

    func testTacticalHUDUsesOriginalPetDisplayWhenDisplaysAreVerticallyStacked() throws {
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
        XCTAssertTrue(lowerDisplay.appKitFrame.contains(tactical))
    }
}
