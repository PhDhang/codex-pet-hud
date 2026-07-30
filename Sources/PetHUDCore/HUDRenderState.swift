import CoreGraphics

public struct HUDRenderState: Sendable {
    private var data: HUDPresentationData?
    private var frameSize: CGSize?

    public init() {}

    public mutating func shouldRefreshContent(
        data: HUDPresentationData,
        frameSize: CGSize
    ) -> Bool {
        guard self.data != data || self.frameSize != frameSize else {
            return false
        }
        self.data = data
        self.frameSize = frameSize
        return true
    }
}
