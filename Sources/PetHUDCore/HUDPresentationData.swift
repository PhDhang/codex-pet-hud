import Foundation

public struct HUDPresentationData: Equatable, Sendable {
    public let petName: String
    public let statusLabel: String
    public let hpText: String
    public let hpFraction: Double
    public let spCellsLit: Int
    public let resetText: String
    public let band: HPBand?

    public static func make(
        petName: String,
        state: HUDState,
        now: Date
    ) -> HUDPresentationData {
        switch state {
        case let .quota(snapshot, band):
            return quotaData(
                petName: petName,
                snapshot: snapshot,
                band: band,
                statusLabel:
                    band == .critical
                    ? "EXHAUSTED"
                    : "CODEX · WEEKLY",
                now: now
            )
        case let .stale(snapshot):
            return quotaData(
                petName: petName,
                snapshot: snapshot,
                band: HUDState.band(
                    forRemainingPercent:
                        snapshot.weekly.remainingPercent
                ),
                statusLabel: "STALE",
                now: now
            )
        case .offline:
            return placeholder(
                petName: petName,
                statusLabel: "OFFLINE"
            )
        case .authenticationRequired:
            return placeholder(
                petName: petName,
                statusLabel: "SIGN IN"
            )
        }
    }

    private static func quotaData(
        petName: String,
        snapshot: QuotaSnapshot,
        band: HPBand,
        statusLabel: String,
        now: Date
    ) -> HUDPresentationData {
        let remainingPercent =
            snapshot.weekly.remainingPercent
        let secondsRemaining = max(
            0,
            snapshot.weekly.resetAt.timeIntervalSince(now)
        )
        return HUDPresentationData(
            petName: petName,
            statusLabel: statusLabel,
            hpText: "\(Int(remainingPercent.rounded()))%",
            hpFraction: remainingPercent / 100,
            spCellsLit: ResetProgress.cellsLit(
                secondsRemaining: secondsRemaining,
                windowDuration:
                    snapshot.weekly.windowDurationSeconds
            ),
            resetText: ResetProgress.countdown(
                secondsRemaining: secondsRemaining
            ),
            band: band
        )
    }

    private static func placeholder(
        petName: String,
        statusLabel: String
    ) -> HUDPresentationData {
        HUDPresentationData(
            petName: petName,
            statusLabel: statusLabel,
            hpText: "--",
            hpFraction: 0,
            spCellsLit: 0,
            resetText: "--",
            band: nil
        )
    }
}
