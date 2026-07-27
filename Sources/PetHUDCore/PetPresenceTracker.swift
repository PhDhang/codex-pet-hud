import Foundation

public struct PetPresenceTracker: Sendable {
    private let requiredAbsentObservations: Int
    private let requiredAbsentDuration: TimeInterval
    private var lastGeometry: WindowDescriptor?
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
            absenceStartedAt = nil
            absentObservationCount = 0
            return lastGeometry
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
    private var presenceTracker = PetPresenceTracker()

    public init() {}

    public mutating func update(
        observed: WindowDescriptor?,
        now: Date
    ) -> WindowDescriptor? {
        presenceTracker.update(
            observation: PetWindowObservation(
                exactWindow: observed,
                hasStablePresence: observed != nil
            ),
            now: now
        )
    }
}
