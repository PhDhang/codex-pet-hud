import Foundation

public struct PetPresenceTracker: Sendable {
    private let requiredAbsentObservations: Int
    private let requiredAbsentDuration: TimeInterval
    private var lastGeometry: PetVisualGeometry?
    private var hasConfirmedPresence = false
    private var absenceStartedAt: Date?
    private var absentObservationCount = 0

    public init(
        restoredGeometry: PetVisualGeometry? = nil,
        requiredAbsentObservations: Int = 3,
        requiredAbsentDuration: TimeInterval = 2
    ) {
        lastGeometry = restoredGeometry
        self.requiredAbsentObservations =
            requiredAbsentObservations
        self.requiredAbsentDuration =
            requiredAbsentDuration
    }

    public mutating func update(
        observation: PetWindowObservation,
        now: Date
    ) -> PetVisualGeometry? {
        let observedPID =
            observation.visualGeometry?.window.ownerPID ??
            observation.stablePresencePID ??
            observation.exactWindow?.ownerPID
        if
            let observedPID,
            let retainedPID = lastGeometry?.window.ownerPID,
            retainedPID != observedPID
        {
            lastGeometry = nil
        }

        if
            !observation.hasExactWindowAmbiguity,
            let candidate = observation.visualGeometry
        {
            let retainsShell =
                lastGeometry?.source == .shellDerived &&
                candidate.source == .mascotFallback
            if !retainsShell {
                lastGeometry = candidate
            }
        }
        if
            !observation.hasExactWindowAmbiguity &&
            (
                observation.visualGeometry != nil ||
                observation.hasStablePresence
            )
        {
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
            hasConfirmedPresence = false
            return nil
        }
        return lastGeometry
    }
}
