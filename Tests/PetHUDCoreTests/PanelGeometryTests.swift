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
}
