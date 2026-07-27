import Foundation

public struct PetWindowTracker: Sendable {
    private let graceInterval: TimeInterval
    private var lastExactWindow: WindowDescriptor?
    private var lastExactSeenAt: Date?

    public init(
        graceInterval: TimeInterval = 1.5
    ) {
        self.graceInterval = graceInterval
    }

    public mutating func update(
        observed: WindowDescriptor?,
        now: Date
    ) -> WindowDescriptor? {
        if let observed {
            if observed.isExactMascotWindow {
                lastExactWindow = observed
                lastExactSeenAt = now
            }
            return observed
        }

        guard
            let lastExactWindow,
            let lastExactSeenAt,
            now.timeIntervalSince(lastExactSeenAt) <=
                graceInterval
        else {
            self.lastExactWindow = nil
            self.lastExactSeenAt = nil
            return nil
        }
        return lastExactWindow
    }
}
