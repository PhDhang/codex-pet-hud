import Foundation

public enum Redaction {
    private static let patterns: [
        (expression: NSRegularExpression, replacement: String)
    ] = [
        (
            try! NSRegularExpression(
                pattern: #"(?i)Bearer\s+[A-Za-z0-9._~+/=-]+"#
            ),
            "Bearer [REDACTED]"
        ),
        (
            try! NSRegularExpression(
                pattern:
                    #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
                options: [.caseInsensitive]
            ),
            "[REDACTED]"
        ),
        (
            try! NSRegularExpression(
                pattern:
                    #"(?i)(account[_-]?id\s*[:=]\s*)[A-Za-z0-9._-]+"#
            ),
            "$1[REDACTED]"
        ),
    ]

    public static func sanitize(
        _ text: String
    ) -> String {
        patterns.reduce(text) { current, pattern in
            pattern.expression.stringByReplacingMatches(
                in: current,
                range: NSRange(
                    current.startIndex...,
                    in: current
                ),
                withTemplate: pattern.replacement
            )
        }
    }
}
