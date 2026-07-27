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

    func testCenteredVisualPetKeepsFullTravelAndYichaScaleOneCenter() {
        let visualSize = CGSize(
            width: 126 * 192 / 208,
            height: 126
        )
        let baseEffectSize = CGSize(
            width: visualSize.width * 1.36,
            height: visualSize.height * 1.10
        )
        let panelFrame = CGRect(
            x: 200,
            y: 100,
            width: baseEffectSize.width * 2,
            height: baseEffectSize.height * 2
        )
        let petFrame = CGRect(
            x: panelFrame.midX - visualSize.width / 2,
            y: panelFrame.midY - visualSize.height / 2,
            width: visualSize.width,
            height: visualSize.height
        )
        let layout = PetEffectLayout(
            panelFrame: panelFrame,
            petFrame: petFrame
        )
        let scaleOne = layout.criticalImageFrame(
            imageSize: CGSize(width: 192, height: 208),
            scale: 1
        )
        let scaleTwo = layout.criticalImageFrame(
            imageSize: CGSize(width: 192, height: 208),
            scale: 2
        )

        XCTAssertEqual(
            layout.leftTravel,
            layout.travel,
            accuracy: 0.001
        )
        XCTAssertEqual(
            layout.rightTravel,
            layout.travel,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleOne.midX,
            layout.localPetFrame.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleOne.midY,
            layout.localPetFrame.midY,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleTwo.width,
            scaleOne.width * 2,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleTwo.height,
            scaleOne.height * 2,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleTwo.midX,
            layout.localPetFrame.midX,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleTwo.midY,
            layout.localPetFrame.midY,
            accuracy: 0.001
        )
        XCTAssertEqual(
            scaleOne.height,
            visualSize.height * 1.10,
            accuracy: 0.001
        )
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
            0,
            accuracy: 0.001
        )
        XCTAssertTrue(
            CGRect(
                origin: .zero,
                size: layout.panelSize
            ).contains(layout.localEffectFrame)
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

    func testPanicFrameIndexUsesEightFPSBoundaries() {
        let samples: [(TimeInterval, Int)] = [
            (0, 0),
            (0.124_999, 0),
            (0.125, 1),
            (0.249_999, 1),
            (0.250, 2),
            (0.999_999, 7),
            (1.0, 0),
            (1.125, 1),
        ]

        for (elapsedTime, expectedIndex) in samples {
            XCTAssertEqual(
                PetEffectAnimation.frameIndex(
                    elapsedTime: elapsedTime,
                    framesPerSecond: 8,
                    frameCount: 8,
                    reduceMotion: false
                ),
                expectedIndex,
                "elapsedTime=\(elapsedTime)"
            )
        }
    }

    func testPanicFrameIndexDoesNotResetWithShuttleLoop() {
        XCTAssertEqual(
            PetEffectAnimation.frameIndex(
                elapsedTime: 1.2,
                framesPerSecond: 8,
                frameCount: 8,
                reduceMotion: false
            ),
            1
        )
        XCTAssertEqual(
            PetEffectAnimation.frameIndex(
                elapsedTime: 2.4,
                framesPerSecond: 8,
                frameCount: 8,
                reduceMotion: false
            ),
            3
        )
    }

    func testReduceMotionFreezesPanicFrameZero() {
        XCTAssertEqual(
            PetEffectAnimation.frameIndex(
                elapsedTime: 17.875,
                framesPerSecond: 24,
                frameCount: 8,
                reduceMotion: true
            ),
            0
        )
    }
}
