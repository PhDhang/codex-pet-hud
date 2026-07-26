import Foundation

public struct QuotaWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double
    public let resetAt: Date
    public let windowDurationSeconds: TimeInterval

    public init(
        usedPercent: Double,
        resetAt: Date,
        windowDurationSeconds: TimeInterval
    ) {
        self.usedPercent = min(100, max(0, usedPercent))
        self.resetAt = resetAt
        self.windowDurationSeconds = windowDurationSeconds
    }

    public var remainingPercent: Double {
        min(100, max(0, 100 - usedPercent))
    }
}

public struct QuotaSnapshot: Codable, Equatable, Sendable {
    public let weekly: QuotaWindow
    public let fetchedAt: Date

    public init(weekly: QuotaWindow, fetchedAt: Date) {
        self.weekly = weekly
        self.fetchedAt = fetchedAt
    }
}

public enum QuotaProviderError: Error, Equatable, Sendable {
    case authenticationRequired
    case invalidResponse
    case invalidPayload
    case httpStatus(Int)
    case unavailable
}

extension QuotaProviderError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .authenticationRequired:
            return "Codex authentication is required."
        case .invalidResponse:
            return "The quota provider returned an invalid response."
        case .invalidPayload:
            return "The quota provider returned an unsupported payload."
        case let .httpStatus(status):
            return "The quota provider returned HTTP \(status)."
        case .unavailable:
            return "The quota provider is unavailable."
        }
    }
}

