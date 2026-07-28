import Foundation

public enum HPPrecision {
    public static func canonical(
        _ remainingPercent: Double
    ) -> Double {
        canonical(
            Decimal(remainingPercent)
        )
    }

    public static func remainingPercent(
        fromUsedPercent usedPercent: Double
    ) -> Double {
        canonical(
            Decimal(100) - Decimal(usedPercent)
        )
    }

    private static func canonical(
        _ remainingPercent: Decimal
    ) -> Double {
        var clamped = min(
            Decimal(100),
            max(Decimal(0), remainingPercent)
        )
        var canonical = Decimal()
        NSDecimalRound(
            &canonical,
            &clamped,
            1,
            .down
        )
        return NSDecimalNumber(
            decimal: canonical
        ).doubleValue
    }
}

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
        HPPrecision.remainingPercent(
            fromUsedPercent: usedPercent
        )
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
