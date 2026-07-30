import Foundation

public enum WhamUsageParser {
    private static let weeklyDuration: TimeInterval = 604_800
    private static let fiveHourDuration: TimeInterval = 18_000

    private struct Response: Decodable {
        struct RateLimit: Decodable {
            struct Window: Decodable {
                let usedPercent: Double
                let resetAt: TimeInterval
                let limitWindowSeconds: TimeInterval?

                enum CodingKeys: String, CodingKey {
                    case usedPercent = "used_percent"
                    case resetAt = "reset_at"
                    case limitWindowSeconds = "limit_window_seconds"
                }
            }

            let primaryWindow: Window?
            let secondaryWindow: Window?

            enum CodingKeys: String, CodingKey {
                case primaryWindow = "primary_window"
                case secondaryWindow = "secondary_window"
            }
        }

        let rateLimit: RateLimit

        enum CodingKeys: String, CodingKey {
            case rateLimit = "rate_limit"
        }
    }

    public static func parse(
        data: Data,
        fetchedAt: Date
    ) throws -> QuotaSnapshot {
        do {
            let response = try JSONDecoder().decode(
                Response.self,
                from: data
            )
            let secondary = response.rateLimit.secondaryWindow
            let primary = response.rateLimit.primaryWindow

            let weeklySource: Response.RateLimit.Window?
            if let secondary,
               secondary.limitWindowSeconds == nil ||
                   secondary.limitWindowSeconds == weeklyDuration
            {
                weeklySource = secondary
            } else if primary?.limitWindowSeconds == weeklyDuration {
                weeklySource = primary
            } else {
                weeklySource = nil
            }

            guard let weeklySource else {
                throw QuotaProviderError.invalidPayload
            }

            let fiveHourSource =
                primary?.limitWindowSeconds == fiveHourDuration
                ? primary
                : nil

            return QuotaSnapshot(
                weekly: normalizedWindow(
                    weeklySource,
                    defaultDuration: weeklyDuration
                ),
                fiveHour: fiveHourSource.map {
                    normalizedWindow(
                        $0,
                        defaultDuration: fiveHourDuration
                    )
                },
                fetchedAt: fetchedAt
            )
        } catch {
            throw QuotaProviderError.invalidPayload
        }
    }

    private static func normalizedWindow(
        _ window: Response.RateLimit.Window,
        defaultDuration: TimeInterval
    ) -> QuotaWindow {
        QuotaWindow(
            usedPercent: window.usedPercent,
            resetAt: Date(timeIntervalSince1970: window.resetAt),
            windowDurationSeconds:
                window.limitWindowSeconds ?? defaultDuration
        )
    }
}
