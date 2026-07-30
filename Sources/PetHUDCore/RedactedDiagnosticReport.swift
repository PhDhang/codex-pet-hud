public struct RedactedDiagnosticReport: Encodable, Sendable {
    private let configuration: String
    private let pet: String
    private let petWindow: String
    private let provider: String
    private let weeklyRemainingPercent: Int?
    private let fiveHourRemainingPercent: Int?
    private let fiveHourStatus: String

    public init(
        configuration: String,
        pet: String,
        petWindow: String,
        provider: String,
        snapshot: QuotaSnapshot?,
        includeQuota: Bool
    ) {
        self.configuration = configuration
        self.pet = pet
        self.petWindow = petWindow
        self.provider = provider

        guard
            includeQuota,
            provider == "reachable",
            let snapshot
        else {
            weeklyRemainingPercent = nil
            fiveHourRemainingPercent = nil
            fiveHourStatus = includeQuota
                ? "unavailable"
                : "skipped"
            return
        }

        weeklyRemainingPercent = Int(
            snapshot.weekly.remainingPercent.rounded()
        )
        if let fiveHour = snapshot.fiveHour {
            fiveHourRemainingPercent = Int(
                fiveHour.remainingPercent.rounded()
            )
            fiveHourStatus = "measured"
        } else {
            fiveHourRemainingPercent = nil
            fiveHourStatus = "max"
        }
    }
}
