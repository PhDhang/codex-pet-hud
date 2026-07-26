import AppKit
import Foundation
import PetHUDCore

@main
struct CodexPetHUDMain {
    @MainActor
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.contains("--diagnose") {
            runCommand {
                await Diagnostics.run(includeQuota: true)
            }
        }
        if arguments.contains("--once") {
            runCommand {
                await Diagnostics.runOnce()
            }
        }
        if arguments.contains("--executor-check") {
            runExecutorCheck()
        }

        let mockSnapshot = loadMockSnapshot(arguments: arguments)
        let application = NSApplication.shared
        let delegate = PetHUDApplicationDelegate(
            mockSnapshot: mockSnapshot
        )
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }

    private static func runCommand(
        _ command: @escaping @Sendable () async -> Int32
    ) -> Never {
        Task.detached {
            exit(await command())
        }
        dispatchMain()
    }

    private static func runExecutorCheck() -> Never {
        Task.detached {
            await MainActor.run {
                print("executor=ok")
                fflush(stdout)
                exit(0)
            }
        }
        dispatchMain()
    }

    private static func loadMockSnapshot(
        arguments: [String]
    ) -> QuotaSnapshot? {
        guard
            let index = arguments.firstIndex(of: "--mock"),
            arguments.indices.contains(index + 1)
        else {
            return nil
        }
        let url = URL(
            fileURLWithPath: arguments[index + 1]
        )
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? WhamUsageParser.parse(
            data: data,
            fetchedAt: Date()
        )
    }
}
