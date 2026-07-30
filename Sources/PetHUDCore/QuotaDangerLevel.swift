import Foundation

public enum QuotaDangerLevel:
    String,
    Codable,
    Equatable,
    Sendable
{
    case none
    case low
    case critical

    public static func evaluate(
        _ remainingPercent: Double
    ) -> QuotaDangerLevel {
        switch HPPrecision.canonical(remainingPercent) {
        case ...3:
            return .critical
        case ..<10:
            return .low
        default:
            return .none
        }
    }
}
