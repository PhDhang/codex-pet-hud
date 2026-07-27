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

    func testLifePodScalesAroundPetCenter() throws {
        let pet = CGRect(x: 24, y: 775, width: 200, height: 250)

        let frame = try XCTUnwrap(
            PanelGeometry.lifePodFrame(
                pet: pet,
                displays: [display],
                scale: 1.2,
                offset: .zero
            )
        )

        XCTAssertEqual(frame.size, CGSize(width: 240, height: 300))
        XCTAssertEqual(frame.midX, 124, accuracy: 0.001)
        XCTAssertEqual(frame.midY, 180, accuracy: 0.001)
    }

    func testLifePodAppliesOffsetsWithoutBreakingScale() throws {
        let pet = CGRect(x: 24, y: 775, width: 200, height: 250)

        let frame = try XCTUnwrap(
            PanelGeometry.lifePodFrame(
                pet: pet,
                displays: [display],
                scale: 1.14,
                offset: CGPoint(x: 17, y: -23)
            )
        )

        XCTAssertEqual(frame.midX, 141, accuracy: 0.001)
        XCTAssertEqual(frame.midY, 157, accuracy: 0.001)
        XCTAssertEqual(frame.size.width, 228, accuracy: 0.001)
        XCTAssertEqual(frame.size.height, 285, accuracy: 0.001)
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
