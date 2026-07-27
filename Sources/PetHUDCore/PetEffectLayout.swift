import CoreGraphics

public struct PetEffectLayout: Equatable, Sendable {
    public let panelSize: CGSize
    public let localPetFrame: CGRect
    public let localEffectFrame: CGRect
    public let travel: CGFloat

    public init(
        panelFrame: CGRect,
        petFrame: CGRect
    ) {
        panelSize = panelFrame.size
        travel = min(petFrame.width * 0.18, 28)
        localPetFrame = Self.localFrame(
            petFrame,
            in: panelFrame
        )
        let effectWidth = max(
            petFrame.width * 1.35,
            petFrame.width + travel * 2
        )
        let effectFrame = CGRect(
            x: petFrame.midX - effectWidth / 2,
            y: petFrame.minY,
            width: effectWidth,
            height: petFrame.height * 1.10
        )
        localEffectFrame = Self.localFrame(
            effectFrame,
            in: panelFrame
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
}
