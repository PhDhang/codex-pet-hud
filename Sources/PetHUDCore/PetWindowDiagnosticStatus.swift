import Foundation

public enum PetWindowDiagnosticStatus:
    String,
    Equatable,
    Sendable
{
    case found
    case missing

    public static func resolve(
        observation: PetWindowObservation,
        cachedGeometry: PetVisualGeometry?,
        now: Date
    ) -> PetWindowDiagnosticStatus {
        var tracker = PetPresenceTracker(
            restoredGeometry: cachedGeometry
        )
        return tracker.update(
            observation: observation,
            now: now
        ) == nil ? .missing : .found
    }
}
