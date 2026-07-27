import CoreGraphics
import XCTest
@testable import PetHUDCore

final class PetEffectLayoutTests: XCTestCase {
    func testUsesOriginalPetWidthForPanicTravel() {
        let layout = PetEffectLayout(
            panelFrame: CGRect(
                x: 0,
                y: 0,
                width: 200,
                height: 120
            ),
            petFrame: CGRect(
                x: 20,
                y: 10,
                width: 100,
                height: 100
            )
        )

        XCTAssertEqual(layout.travel, 18, accuracy: 0.001)
    }

    func testCapsPanicTravelAtTwentyEightPoints() {
        let layout = PetEffectLayout(
            panelFrame: CGRect(
                x: 0,
                y: 0,
                width: 500,
                height: 360
            ),
            petFrame: CGRect(
                x: 50,
                y: 20,
                width: 300,
                height: 320
            )
        )

        XCTAssertEqual(layout.travel, 28, accuracy: 0.001)
    }

    func testLiveVisualFrameControlsTravelAndSpriteBounds() {
        let visualWidth: CGFloat = 126 * 192 / 208
        let visualFrame = CGRect(
            x: 244 - visualWidth / 2,
            y: 205,
            width: visualWidth,
            height: 126
        )
        let travel = visualWidth * 0.18
        let panelFrame = CGRect(
            x: visualFrame.midX - visualWidth * 1.36 / 2,
            y: visualFrame.minY,
            width: visualWidth * 1.36,
            height: visualFrame.height * 1.10
        )

        let layout = PetEffectLayout(
            panelFrame: panelFrame,
            petFrame: visualFrame
        )

        XCTAssertEqual(layout.travel, travel, accuracy: 0.001)
        XCTAssertEqual(
            layout.localPetFrame.size,
            visualFrame.size
        )
        XCTAssertEqual(
            layout.localEffectFrame.width,
            visualWidth * 1.36,
            accuracy: 0.001
        )
    }

    func testClampedEdgePanelKeepsOriginalPetLocalCenter() {
        let layout = PetEffectLayout(
            panelFrame: CGRect(
                x: 592,
                y: 100,
                width: 328.05,
                height: 277.2
            ),
            petFrame: CGRect(
                x: 677,
                y: 100,
                width: 243,
                height: 252
            )
        )

        XCTAssertEqual(
            layout.localPetFrame.minX,
            85,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.localPetFrame.minY,
            25.2,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.localPetFrame.width,
            243,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.localPetFrame.height,
            252,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.localEffectFrame.minX,
            42.475,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.localPetFrame.midX,
            206.5,
            accuracy: 0.001
        )
        XCTAssertNotEqual(
            layout.localPetFrame.midX,
            layout.panelSize.width / 2
        )
    }

    func testConvertsAppKitPetFrameToTopLeftViewCoordinates() {
        let layout = PetEffectLayout(
            panelFrame: CGRect(
                x: 100,
                y: 500,
                width: 300,
                height: 280
            ),
            petFrame: CGRect(
                x: 120,
                y: 510,
                width: 200,
                height: 240
            )
        )

        XCTAssertEqual(
            layout.localPetFrame,
            CGRect(
                x: 20,
                y: 30,
                width: 200,
                height: 240
            )
        )
    }

    func testCustomPanicFramesTakePriorityAndMirrorLeft() {
        let movingRight = PetEffectFrameSelection.panic(
            customFrameCount: 8,
            movingRight: true
        )
        let movingLeft = PetEffectFrameSelection.panic(
            customFrameCount: 8,
            movingRight: false
        )

        XCTAssertEqual(movingRight, .custom(mirrored: false))
        XCTAssertFalse(movingRight.mirrorsSprite)
        XCTAssertFalse(movingRight.mirrorsEyeAnchors)
        XCTAssertEqual(movingLeft, .custom(mirrored: true))
        XCTAssertTrue(movingLeft.mirrorsSprite)
        XCTAssertTrue(movingLeft.mirrorsEyeAnchors)
    }

    func testPanicFallbackPreservesV2DirectionRows() {
        let movingRight = PetEffectFrameSelection.panic(
            customFrameCount: 0,
            movingRight: true
        )
        let movingLeft = PetEffectFrameSelection.panic(
            customFrameCount: 0,
            movingRight: false
        )

        XCTAssertEqual(movingRight, .runningRight)
        XCTAssertFalse(movingRight.mirrorsSprite)
        XCTAssertFalse(movingRight.mirrorsEyeAnchors)
        XCTAssertEqual(movingLeft, .runningLeft)
        XCTAssertFalse(movingLeft.mirrorsSprite)
        XCTAssertTrue(movingLeft.mirrorsEyeAnchors)
    }
}
