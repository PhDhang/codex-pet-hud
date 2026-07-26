import Foundation

public enum ResetProgress {
    public static func cellsLit(
        secondsRemaining: TimeInterval,
        windowDuration: TimeInterval
    ) -> Int {
        guard windowDuration > 0 else {
            return 0
        }

        let remainingFraction = min(
            1,
            max(0, secondsRemaining / windowDuration)
        )
        let elapsedFraction = 1 - remainingFraction
        return min(7, max(0, Int(floor(elapsedFraction * 7))))
    }

    public static func countdown(
        secondsRemaining: TimeInterval
    ) -> String {
        let clamped = max(0, secondsRemaining)
        if clamped >= 86_400 {
            return "\(Int(ceil(clamped / 86_400)))d"
        }
        if clamped >= 3_600 {
            return "\(Int(ceil(clamped / 3_600)))h"
        }
        return "\(Int(ceil(clamped / 60)))m"
    }
}
