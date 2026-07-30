import Foundation
import PetHUDCore

enum Diagnostics {
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
        var snapshot: QuotaSnapshot?

        if includeQuota {
            do {
                snapshot = try await context.provider.fetch()
                providerStatus = "reachable"
            } catch let error as QuotaProviderError {
                providerStatus =
                    error == .authenticationRequired
                    ? "authentication-required"
                    : "unavailable"
            } catch {
                providerStatus = "unavailable"
            }
        }

        let report = RedactedDiagnosticReport(
            configuration: context.configurationStatus,
            pet: context.petStatus,
            petWindow: petWindowStatus,
            provider: providerStatus,
            snapshot: snapshot,
            includeQuota: includeQuota
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
        _ report: RedactedDiagnosticReport
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
