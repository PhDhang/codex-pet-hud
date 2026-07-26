import Foundation

public enum WhamUsageParser {
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
            let weekly: Response.RateLimit.Window
            if let secondaryWindow = response.rateLimit.secondaryWindow {
                weekly = secondaryWindow
            } else if
                let primaryWindow = response.rateLimit.primaryWindow,
                primaryWindow.limitWindowSeconds == 604_800
            {
                weekly = primaryWindow
            } else {
                throw QuotaProviderError.invalidPayload
            }
            return QuotaSnapshot(
                weekly: QuotaWindow(
                    usedPercent: weekly.usedPercent,
                    resetAt: Date(timeIntervalSince1970: weekly.resetAt),
                    windowDurationSeconds:
                        weekly.limitWindowSeconds ?? 604_800
                ),
                fetchedAt: fetchedAt
            )
        } catch {
            throw QuotaProviderError.invalidPayload
        }
    }
}
