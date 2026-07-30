import Foundation
import PetHUDCore

enum Diagnostics {
    private struct Report: Codable {
        let configuration: String
        let pet: String
        let petWindow: String
        let provider: String
        let weeklyRemainingPercent: Int?
        let fiveHourRemainingPercent: Int?
        let fiveHourStatus: String
    }

    static func run(
        includeQuota: Bool
    ) async -> Int32 {
        let context = loadContext()
        let observation = PetWindowLocator.currentObservation()
        let petWindowStatus =
            observation.exactWindow != nil ||
            observation.hasStablePresence
            ? "found"
            : "missing"
        var providerStatus = includeQuota ? "unavailable" : "skipped"
        var remaining: Int?
        var fiveHourRemaining: Int?
        var fiveHourStatus = includeQuota ? "unavailable" : "skipped"

        if includeQuota {
            do {
                let snapshot = try await context.provider.fetch()
                providerStatus = "reachable"
                remaining = Int(
                    snapshot.weekly.remainingPercent.rounded()
                )
                if let fiveHour = snapshot.fiveHour {
                    fiveHourRemaining = Int(
                        fiveHour.remainingPercent.rounded()
                    )
                    fiveHourStatus = "measured"
                } else {
                    fiveHourStatus = "max"
                }
            } catch let error as QuotaProviderError {
                providerStatus =
                    error == .authenticationRequired
                    ? "authentication-required"
                    : "unavailable"
            } catch {
                providerStatus = "unavailable"
            }
        }

        let report = Report(
            configuration: context.configurationStatus,
            pet: context.petStatus,
            petWindow: petWindowStatus,
            provider: providerStatus,
            weeklyRemainingPercent: remaining,
            fiveHourRemainingPercent: fiveHourRemaining,
            fiveHourStatus: fiveHourStatus
        )
        write(report)

        if context.configurationStatus != "ok" {
            return 2
        }
        if providerStatus == "authentication-required" {
            return 3
        }
        if includeQuota && providerStatus != "reachable" {
            return 4
        }
        if petWindowStatus == "missing" {
            return 5
        }
        return 0
    }

    static func runOnce() async -> Int32 {
        await run(includeQuota: true)
    }

    private static func loadContext() -> (
        provider: WhamUsageClient,
        configurationStatus: String,
        petStatus: String
    ) {
        let home = FileManager.default
            .homeDirectoryForCurrentUser
        let codexHome = ProcessInfo.processInfo
            .environment["CODEX_HOME"]
            .map { URL(fileURLWithPath: $0) }
            ?? home.appendingPathComponent(
                ".codex",
                isDirectory: true
            )
        let configURL = home
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent(
                "codex-pet-hud",
                isDirectory: true
            )
            .appendingPathComponent("config.json")
        let configuration: AppConfiguration?
        do {
            configuration = try AppConfiguration.load(
                url: configURL,
                homeDirectory: home
            )
        } catch {
            configuration = nil
        }
        let pet = try? PetDiscovery.discover(
            configuredPath: configuration?.petPath.map {
                URL(fileURLWithPath: $0)
            },
            petsRoot: codexHome.appendingPathComponent(
                "pets",
                isDirectory: true
            )
        )
        return (
            WhamUsageClient(
                authURL: codexHome.appendingPathComponent(
                    "auth.json"
                )
            ),
            configuration == nil ? "invalid" : "ok",
            pet == nil ? "missing-or-ambiguous" : "found"
        )
    }

    private static func write(
        _ report: Report
    ) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(report) else {
            return
        }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
