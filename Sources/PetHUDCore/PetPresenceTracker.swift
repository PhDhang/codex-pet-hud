import Foundation

public struct PetPresenceTracker: Sendable {
    private let requiredAbsentObservations: Int
    private let requiredAbsentDuration: TimeInterval
    private var lastGeometry: WindowDescriptor?
    private var hasConfirmedPresence = false
    private var absenceStartedAt: Date?
    private var absentObservationCount = 0

    public init(
        restoredWindow: WindowDescriptor? = nil,
        requiredAbsentObservations: Int = 3,
        requiredAbsentDuration: TimeInterval = 2
    ) {
        lastGeometry = restoredWindow
        self.requiredAbsentObservations =
            requiredAbsentObservations
        self.requiredAbsentDuration =
            requiredAbsentDuration
    }

    public mutating func update(
        observation: PetWindowObservation,
        now: Date
    ) -> WindowDescriptor? {
        if let exact = observation.exactWindow {
            lastGeometry = exact
        }
        if observation.hasStablePresence {
            hasConfirmedPresence = true
            absenceStartedAt = nil
            absentObservationCount = 0
            return lastGeometry
        }

        guard hasConfirmedPresence else {
            return nil
        }

        if absenceStartedAt == nil {
            absenceStartedAt = now
        }
        absentObservationCount += 1
        let duration = now.timeIntervalSince(
            absenceStartedAt ?? now
        )
        if absentObservationCount >=
            requiredAbsentObservations,
            duration >= requiredAbsentDuration
        {
            absenceStartedAt = nil
            absentObservationCount = 0
            lastGeometry = nil
            return nil
        }
        return lastGeometry
    }
}

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
