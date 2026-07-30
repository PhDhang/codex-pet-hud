import Foundation

public struct QuotaMeterMotionPolicy: Equatable, Sendable {
    public let allowsFlow: Bool
    public let pulseDuration: TimeInterval?

    public static func evaluate(
        mode: MPPresentationMode,
        fraction: Double,
        dangerLevel: QuotaDangerLevel,
        reduceMotion: Bool
    ) -> QuotaMeterMotionPolicy {
        guard !reduceMotion else {
            return QuotaMeterMotionPolicy(
                allowsFlow: false,
                pulseDuration: nil
            )
        }

        switch mode {
        case .unlimited, .unavailable:
            return QuotaMeterMotionPolicy(
                allowsFlow: false,
                pulseDuration: nil
            )
        case .measured:
            switch dangerLevel {
            case .none:
                return QuotaMeterMotionPolicy(
                    allowsFlow: fraction < 1,
                    pulseDuration: nil
                )
            case .low:
                return QuotaMeterMotionPolicy(
                    allowsFlow: false,
                    pulseDuration: 0.9
                )
            case .critical:
                return QuotaMeterMotionPolicy(
                    allowsFlow: false,
                    pulseDuration: 0.45
                )
            }
        }
    }
}
