import Foundation

public struct PetPresenceTracker: Sendable {
    private struct FallbackIdentity: Equatable, Sendable {
        let ownerPID: Int
        let windowID: Int
    }

    private let requiredAbsentObservations: Int
    private let requiredAbsentDuration: TimeInterval
    private var lastGeometry: PetVisualGeometry?
    private var hasLiveGeometry = false
    private var hasConfirmedPresence = false
    private var absenceStartedAt: Date?
    private var absentObservationCount = 0
    private var pendingFallbackIdentity: FallbackIdentity?
    private var fallbackBlockedPID: Int?

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
        let candidate = observation.visualGeometry
        let isUnambiguousFallback =
            !observation.hasExactWindowAmbiguity &&
            candidate?.source == .mascotFallback
        let observedPID =
            candidate?.window.ownerPID ??
            observation.stablePresencePID ??
            observation.exactWindow?.ownerPID
        if
            let observedPID,
            let retainedPID = lastGeometry?.window.ownerPID,
            retainedPID != observedPID
        {
            lastGeometry = nil
            hasLiveGeometry = false
            pendingFallbackIdentity = nil
            if candidate?.source != .shellDerived {
                fallbackBlockedPID = observedPID
                return nil
            }
        }

        if !isUnambiguousFallback {
            pendingFallbackIdentity = nil
        }
        if
            !observation.hasExactWindowAmbiguity,
            let candidate
        {
            if candidate.source == .shellDerived {
                lastGeometry = candidate
                hasLiveGeometry = true
                pendingFallbackIdentity = nil
                fallbackBlockedPID = nil
            } else if fallbackBlockedPID != nil {
                fallbackBlockedPID = candidate.window.ownerPID
            } else {
                let protectsColdRestore =
                    !hasLiveGeometry &&
                    lastGeometry?.source == .shellDerived
                if protectsColdRestore {
                    let identity = FallbackIdentity(
                        ownerPID: candidate.window.ownerPID,
                        windowID: candidate.window.windowID
                    )
                    if pendingFallbackIdentity == identity {
                        lastGeometry = candidate
                        hasLiveGeometry = true
                        pendingFallbackIdentity = nil
                    } else {
                        pendingFallbackIdentity = identity
                    }
                } else {
                    lastGeometry = candidate
                    hasLiveGeometry = true
                    pendingFallbackIdentity = nil
                }
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
            hasLiveGeometry = false
            hasConfirmedPresence = false
            pendingFallbackIdentity = nil
            fallbackBlockedPID = nil
            return nil
        }
        return lastGeometry
    }
}
