import CoreGraphics

public struct TacticalHUDLayoutMetrics: Equatable, Sendable {
    public let horizontalPadding: CGFloat
    public let verticalPadding: CGFloat
    public let rowSpacing: CGFloat
    public let columnSpacing: CGFloat
    public let labelWidth: CGFloat
    public let flameWidth: CGFloat
    public let flameHeight: CGFloat
    public let flameSpacing: CGFloat
    public let hpBarHeight: CGFloat
    public let hpRowHeight: CGFloat
    public let statusRowHeight: CGFloat
    public let meterFontSize: CGFloat
    public let statusFontSize: CGFloat
    public let statusTracking: CGFloat
    public let cornerCut: CGFloat

    public init(frameSize: CGSize) {
        let fit = min(
            frameSize.width / 190,
            frameSize.height / 72
        )
        let progress = min(1, max(0, (fit - 0.65) / 0.35))

        horizontalPadding = Self.interpolate(5, 8, progress: progress)
        verticalPadding = Self.interpolate(2, 4, progress: progress)
        rowSpacing = Self.interpolate(1, 3, progress: progress)
        columnSpacing = Self.interpolate(3, 5, progress: progress)
        labelWidth = Self.interpolate(16, 22, progress: progress)
        flameWidth = Self.interpolate(9, 13, progress: progress)
        flameHeight = Self.interpolate(10, 16, progress: progress)
        flameSpacing = Self.interpolate(1.5, 3, progress: progress)
        hpBarHeight = Self.interpolate(6, 9, progress: progress)
        hpRowHeight = Self.interpolate(10, 12, progress: progress)
        statusRowHeight = Self.interpolate(9, 10, progress: progress)
        meterFontSize = Self.interpolate(8, 10, progress: progress)
        statusFontSize = Self.interpolate(7, 8, progress: progress)
        statusTracking = Self.interpolate(0.3, 0.8, progress: progress)
        cornerCut = Self.interpolate(5, 8, progress: progress)
    }

    public var trailingWidth: CGFloat {
        0
    }

    public var spRowWidth: CGFloat {
        horizontalPadding * 2 +
            labelWidth +
            columnSpacing +
            flameWidth * 7 +
            flameSpacing * 6
    }

    public var contentHeight: CGFloat {
        verticalPadding * 2 +
            hpRowHeight * 2 +
            flameHeight +
            statusRowHeight +
            rowSpacing * 3
    }

    private static func interpolate(
        _ compact: CGFloat,
        _ standard: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        compact + (standard - compact) * progress
    }
}
