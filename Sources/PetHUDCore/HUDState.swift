import Foundation

public enum HPBand: String, Codable, Equatable, Sendable {
    case healthy
    case normal
    case warning
    case low
    case critical
}

public enum HUDState: Equatable, Sendable {
    case quota(snapshot: QuotaSnapshot, band: HPBand)
    case stale(snapshot: QuotaSnapshot)
    case offline
    case authenticationRequired

    public static func band(
        forRemainingPercent value: Double
    ) -> HPBand {
        switch HPPrecision.canonical(value) {
        case ...3:
            return .critical
        case ..<10:
            return .low
        case ...50:
            return .warning
        case ...90:
            return .normal
        default:
            return .healthy
        }
    }

    public static func evaluate(
        snapshot: QuotaSnapshot?,
        now: Date
    ) -> HUDState {
        guard let snapshot else {
            return .offline
        }

        let age = now.timeIntervalSince(snapshot.fetchedAt)
        if age > 1_800 {
            return .offline
        }
        if age > 300 {
            return .stale(snapshot: snapshot)
        }

        return .quota(
            snapshot: snapshot,
            band: band(
                forRemainingPercent: snapshot.weekly.remainingPercent
            )
        )
    }
}
