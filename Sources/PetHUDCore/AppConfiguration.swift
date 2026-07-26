import Foundation

public enum AppConfigurationError: Error, Equatable, Sendable {
    case invalidConfiguration(String)
}

extension AppConfigurationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .invalidConfiguration(path):
            return "Invalid configuration at \(path)."
        }
    }
}

public struct AppConfiguration: Codable, Equatable, Sendable {
    public var petPath: String?
    public var refreshIntervalSeconds: TimeInterval
    public var criticalThresholdPercent: Double
    public var nameplateOffset: Double
    public var launchAtLogin: Bool

    public static let defaults = AppConfiguration(
        petPath: nil,
        refreshIntervalSeconds: 300,
        criticalThresholdPercent: 3,
        nameplateOffset: 10,
        launchAtLogin: true
    )

    private struct Document: Decodable {
        let petPath: String?
        let refreshIntervalSeconds: TimeInterval?
        let criticalThresholdPercent: Double?
        let nameplateOffset: Double?
        let launchAtLogin: Bool?
    }

    public static func load(
        url: URL,
        homeDirectory: URL
    ) throws -> AppConfiguration {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return .defaults
        }

        let document: Document
        do {
            document = try JSONDecoder().decode(
                Document.self,
                from: Data(contentsOf: url)
            )
        } catch {
            throw AppConfigurationError.invalidConfiguration(
                url.path
            )
        }

        return AppConfiguration(
            petPath: expand(
                document.petPath,
                homeDirectory: homeDirectory
            ),
            refreshIntervalSeconds: max(
                300,
                document.refreshIntervalSeconds ??
                    defaults.refreshIntervalSeconds
            ),
            criticalThresholdPercent: min(
                10,
                max(
                    0,
                    document.criticalThresholdPercent ??
                        defaults.criticalThresholdPercent
                )
            ),
            nameplateOffset: min(
                100,
                max(
                    -100,
                    document.nameplateOffset ??
                        defaults.nameplateOffset
                )
            ),
            launchAtLogin:
                document.launchAtLogin ?? defaults.launchAtLogin
        )
    }

    private static func expand(
        _ path: String?,
        homeDirectory: URL
    ) -> String? {
        guard let path else {
            return nil
        }
        if path == "~" {
            return homeDirectory.path
        }
        if path.hasPrefix("~/") {
            return homeDirectory
                .appendingPathComponent(String(path.dropFirst(2)))
                .standardizedFileURL
                .path
        }
        return URL(fileURLWithPath: path)
            .standardizedFileURL
            .path
    }
}

