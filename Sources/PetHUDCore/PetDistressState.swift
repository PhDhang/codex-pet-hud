import Foundation

public enum PetDistressState:
    String,
    Codable,
    Equatable,
    Sendable
{
    case normal
    case panic
    case critical

    public static func evaluate(
        hudState: HUDState,
        previous: PetDistressState
    ) -> PetDistressState {
        guard case let .quota(snapshot, _) = hudState else {
            return .normal
        }
        let remaining = HPPrecision.canonical(
            snapshot.weekly.remainingPercent
        )
        if remaining <= 3 {
            return .critical
        }
        if previous == .critical, remaining <= 5 {
            return .critical
        }
        if remaining < 10 {
            return .panic
        }
        return .normal
    }
}
