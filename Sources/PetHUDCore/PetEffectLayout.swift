import CoreGraphics
import Foundation

public struct PetEffectLayout: Equatable, Sendable {
    public static let maximumCriticalScale: CGFloat = 2

    public let panelSize: CGSize
    public let localPetFrame: CGRect
    public let localEffectFrame: CGRect
    public let nativePetCoverFrame: CGRect
    public let travel: CGFloat
    public let leftTravel: CGFloat
    public let rightTravel: CGFloat
    public let panicBounce: CGFloat

    public init(
        panelFrame: CGRect,
        petFrame: CGRect
    ) {
        let panelBounds = CGRect(
            origin: .zero,
            size: panelFrame.size
        )
        let localPetFrame = Self.localFrame(
            petFrame,
            in: panelFrame
        )
        let travel = min(petFrame.width * 0.18, 28)

        panelSize = panelFrame.size
        self.localPetFrame = localPetFrame
        self.travel = travel
        let desiredCoverFrame = CGRect(
            x: localPetFrame.midX - petFrame.width * 1.10 / 2,
            y: localPetFrame.midY - petFrame.height * 1.08 / 2,
            width: petFrame.width * 1.10,
            height: petFrame.height * 1.08
        )
        let clippedCoverFrame = desiredCoverFrame
            .intersection(panelBounds)
        nativePetCoverFrame =
            clippedCoverFrame.isNull
                ? .zero
                : clippedCoverFrame
        leftTravel = min(
            travel,
            max(0, localPetFrame.minX)
        )
        rightTravel = min(
            travel,
            max(0, panelBounds.maxX - localPetFrame.maxX)
        )
        panicBounce = min(
            4,
            max(0, localPetFrame.minY)
        )

        let effectWidth = max(
            petFrame.width * 1.35,
            petFrame.width + travel * 2
        )
        let desiredEffectFrame = CGRect(
            x: localPetFrame.midX - effectWidth / 2,
            y:
                localPetFrame.midY -
                petFrame.height * 1.10 / 2,
            width: effectWidth,
            height: petFrame.height * 1.10
        )
        localEffectFrame = Self.containedFrame(
            desiredEffectFrame,
            in: panelBounds
        )
    }

    public func criticalImageFrame(
        imageSize: CGSize,
        scale: Double,
        availableFrame: CGRect? = nil
    ) -> CGRect {
        let baseFrame = availableFrame ?? localEffectFrame
        let fittedSize = Self.aspectFitSize(
            imageSize,
            in: baseFrame.size
        )
        let acceptedScale = min(
            Self.maximumCriticalScale,
            max(0.5, CGFloat(scale))
        )
        let desiredSize = CGSize(
            width: fittedSize.width * acceptedScale,
            height: fittedSize.height * acceptedScale
        )
        let panelBounds = CGRect(
            origin: .zero,
            size: panelSize
        )
        let center = CGPoint(
            x: localPetFrame.midX,
            y: localPetFrame.midY
        )
        let centeredBounds = CGSize(
            width: max(
                0,
                2 * min(
                    center.x - panelBounds.minX,
                    panelBounds.maxX - center.x
                )
            ),
            height: max(
                0,
                2 * min(
                    center.y - panelBounds.minY,
                    panelBounds.maxY - center.y
                )
            )
        )
        let containmentScale = min(
            1,
            centeredBounds.width / desiredSize.width,
            centeredBounds.height / desiredSize.height
        )
        let containedSize = CGSize(
            width: desiredSize.width * containmentScale,
            height: desiredSize.height * containmentScale
        )
        return CGRect(
            x: center.x - containedSize.width / 2,
            y: center.y - containedSize.height / 2,
            width: containedSize.width,
            height: containedSize.height
        )
    }

    private static func localFrame(
        _ frame: CGRect,
        in panelFrame: CGRect
    ) -> CGRect {
        CGRect(
            x: frame.minX - panelFrame.minX,
            y: panelFrame.maxY - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }

    private static func containedFrame(
        _ frame: CGRect,
        in bounds: CGRect
    ) -> CGRect {
        let width = min(frame.width, bounds.width)
        let height = min(frame.height, bounds.height)
        return CGRect(
            x: min(
                max(frame.minX, bounds.minX),
                bounds.maxX - width
            ),
            y: min(
                max(frame.minY, bounds.minY),
                bounds.maxY - height
            ),
            width: width,
            height: height
        )
    }

    private static func aspectFitSize(
        _ size: CGSize,
        in bounds: CGSize
    ) -> CGSize {
        let scale = min(
            bounds.width / size.width,
            bounds.height / size.height
        )
        return CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
}

public struct CriticalOrbitLayout: Equatable, Sendable {
    public let center: CGPoint
    public let birdGlyphSize: CGFloat
    public let sparkleGlyphSize: CGFloat
    public let birdRadii: CGSize
    public let sparkleRadii: CGSize

    public init(
        panelSize: CGSize,
        imageFrame: CGRect,
        headAnchor: NormalizedPoint
    ) {
        let center = CGPoint(
            x:
                imageFrame.minX +
                imageFrame.width * CGFloat(headAnchor.x),
            y:
                imageFrame.minY +
                imageFrame.height * CGFloat(headAnchor.y)
        )
        let desiredBirdRadii = CGSize(
            width: min(imageFrame.width * 0.20, 44),
            height: min(imageFrame.height * 0.12, 24)
        )
        let desiredSparkleRadii = CGSize(
            width: desiredBirdRadii.width * 0.72,
            height: desiredBirdRadii.height * 0.72
        )
        let birdGlyphSize = Self.containedGlyphSize(
            desired: 22,
            center: center,
            panelSize: panelSize
        )
        let sparkleGlyphSize = Self.containedGlyphSize(
            desired: 18,
            center: center,
            panelSize: panelSize
        )

        self.center = center
        self.birdGlyphSize = birdGlyphSize
        self.sparkleGlyphSize = sparkleGlyphSize
        birdRadii = Self.containedRadii(
            desired: desiredBirdRadii,
            glyphSize: birdGlyphSize,
            center: center,
            panelSize: panelSize
        )
        sparkleRadii = Self.containedRadii(
            desired: desiredSparkleRadii,
            glyphSize: sparkleGlyphSize,
            center: center,
            panelSize: panelSize
        )
    }

    public func birdPosition(
        index: Int,
        phase: Double
    ) -> CGPoint {
        position(
            phase: phase + Double(index) * .pi,
            radii: birdRadii
        )
    }

    public func sparklePosition(
        index: Int,
        phase: Double
    ) -> CGPoint {
        position(
            phase:
                phase +
                .pi / 2 +
                Double(index) * .pi,
            radii: sparkleRadii
        )
    }

    private func position(
        phase: Double,
        radii: CGSize
    ) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(phase)) * radii.width,
            y: center.y + CGFloat(sin(phase)) * radii.height
        )
    }

    private static func containedGlyphSize(
        desired: CGFloat,
        center: CGPoint,
        panelSize: CGSize
    ) -> CGFloat {
        let clearance = min(
            center.x,
            panelSize.width - center.x,
            center.y,
            panelSize.height - center.y
        )
        return min(desired, max(0, clearance * 2))
    }

    private static func containedRadii(
        desired: CGSize,
        glyphSize: CGFloat,
        center: CGPoint,
        panelSize: CGSize
    ) -> CGSize {
        let glyphInset = glyphSize / 2
        let availableWidth = max(
            0,
            min(
                center.x,
                panelSize.width - center.x
            ) - glyphInset
        )
        let availableHeight = max(
            0,
            min(
                center.y,
                panelSize.height - center.y
            ) - glyphInset
        )
        return CGSize(
            width: min(desired.width, availableWidth),
            height: min(desired.height, availableHeight)
        )
    }
}

public enum PetEffectFrameSelection:
    Equatable,
    Sendable
{
    case custom(mirrored: Bool)
    case runningRight
    case runningLeft

    public static func panic(
        customFrameCount: Int,
        movingRight: Bool
    ) -> PetEffectFrameSelection {
        if customFrameCount > 0 {
            return .custom(mirrored: !movingRight)
        }
        return movingRight ? .runningRight : .runningLeft
    }

    public var mirrorsSprite: Bool {
        switch self {
        case let .custom(mirrored):
            mirrored
        case .runningRight, .runningLeft:
            false
        }
    }

    public var mirrorsEyeAnchors: Bool {
        switch self {
        case let .custom(mirrored):
            mirrored
        case .runningRight:
            false
        case .runningLeft:
            true
        }
    }
}

public enum PetEffectAnimation {
    public static let criticalOrbitDuration: TimeInterval = 3

    public static func frameIndex(
        elapsedTime: TimeInterval,
        framesPerSecond: Double,
        frameCount: Int,
        reduceMotion: Bool
    ) -> Int {
        guard
            !reduceMotion,
            framesPerSecond > 0,
            frameCount > 0
        else {
            return 0
        }
        let elapsed = max(0, elapsedTime)
        return Int(elapsed * framesPerSecond) % frameCount
    }

    public static func orbitPhase(
        elapsedTime: TimeInterval,
        reduceMotion: Bool
    ) -> Double {
        guard !reduceMotion else {
            return 0
        }
        let progress =
            max(0, elapsedTime)
                .truncatingRemainder(
                    dividingBy: criticalOrbitDuration
                ) /
            criticalOrbitDuration
        return progress * .pi * 2
    }
}
