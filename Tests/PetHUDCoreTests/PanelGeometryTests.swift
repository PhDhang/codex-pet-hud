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

    func testCentersNameplateAbovePet() throws {
        let pet = CGRect(x: 24, y: 775, width: 243, height: 252)

        let frame = try XCTUnwrap(
            PanelGeometry.nameplateFrame(
                pet: pet,
                displays: [display],
                nameplateSize: CGSize(width: 280, height: 92),
                offset: 10
            )
        )

        XCTAssertEqual(frame.origin.x, 5.5, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, 315, accuracy: 0.001)
        XCTAssertEqual(frame.size, CGSize(width: 280, height: 92))
    }

    func testNameplateClampsInsideDisplay() throws {
        let pet = CGRect(x: 0, y: 1, width: 180, height: 180)

        let frame = try XCTUnwrap(
            PanelGeometry.nameplateFrame(
                pet: pet,
                displays: [display],
                nameplateSize: CGSize(width: 280, height: 92),
                offset: 10
            )
        )

        XCTAssertGreaterThanOrEqual(frame.minX, display.appKitFrame.minX)
        XCTAssertLessThanOrEqual(frame.maxX, display.appKitFrame.maxX)
        XCTAssertLessThanOrEqual(frame.maxY, display.appKitFrame.maxY)
    }

    func testChoosesDisplayWithLargestIntersection() throws {
        let secondary = DisplayDescriptor(
            cgBounds: CGRect(x: 1920, y: 0, width: 1440, height: 900),
            appKitFrame: CGRect(x: 1920, y: 0, width: 1440, height: 900)
        )
        let pet = CGRect(x: 2000, y: 500, width: 240, height: 250)

        let frame = try XCTUnwrap(
            PanelGeometry.appKitPetFrame(
                pet: pet,
                displays: [display, secondary]
            )
        )

        XCTAssertEqual(frame, CGRect(x: 2000, y: 150, width: 240, height: 250))
    }
}
