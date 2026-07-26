import AppKit
import Foundation
import PetHUDCore

@MainActor
final class PetHUDApplicationDelegate:
    NSObject,
    NSApplicationDelegate
{
    private let mockSnapshot: QuotaSnapshot?
    private var coordinator: PetHUDCoordinator?

    init(mockSnapshot: QuotaSnapshot?) {
        self.mockSnapshot = mockSnapshot
    }

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        do {
            coordinator = try PetHUDCoordinator(
                mockSnapshot: mockSnapshot
            )
            coordinator?.start()
        } catch {
            fputs(
                Redaction.sanitize(
                    "Codex Pet HUD failed to start: \(error)\n"
                ),
                stderr
            )
            NSApplication.shared.terminate(nil)
        }
    }
}

@MainActor
final class PetHUDCoordinator {
    private let configuration: AppConfiguration
    private let provider: WhamUsageClient
    private let cache: SnapshotCache
    private let manifest: PetManifest?
    private let neutralImage: CGImage?
    private let mockSnapshot: QuotaSnapshot?
    private let nameplateController =
        NameplatePanelController()
    private let criticalController =
        CriticalPanelController()

    private var model = ApplicationModel(now: Date())
    private var windowTimer: Timer?
    private var freshnessTimer: Timer?
    private var quotaTimer: Timer?
    private var lastPresentation: PanelPresentation?

    init(mockSnapshot: QuotaSnapshot?) throws {
        let home = FileManager.default
            .homeDirectoryForCurrentUser
        let configURL = home
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent(
                "codex-pet-hud",
                isDirectory: true
            )
            .appendingPathComponent("config.json")
        configuration = try AppConfiguration.load(
            url: configURL,
            homeDirectory: home
        )

        let codexHome: URL
        if let configuredHome =
            ProcessInfo.processInfo.environment["CODEX_HOME"]
        {
            codexHome = URL(fileURLWithPath: configuredHome)
        } else {
            codexHome = home.appendingPathComponent(
                ".codex",
                isDirectory: true
            )
        }
        provider = WhamUsageClient(
            authURL: codexHome.appendingPathComponent(
                "auth.json"
            )
        )
        cache = SnapshotCache(
            url: home
                .appendingPathComponent(
                    "Library/Application Support",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "CodexPetHUD",
                    isDirectory: true
                )
                .appendingPathComponent("snapshot.json")
        )

        let configuredPetURL = configuration.petPath.map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
        manifest = try PetDiscovery.discover(
            configuredPath: configuredPetURL,
            petsRoot: codexHome.appendingPathComponent(
                "pets",
                isDirectory: true
            )
        )
        neutralImage = manifest.flatMap {
            try? PetAtlas.neutralImage(manifest: $0)
        }
        self.mockSnapshot = mockSnapshot
    }

    func start() {
        if let mockSnapshot {
            render(
                model.reduce(.quotaLoaded(mockSnapshot))
            )
        } else if let cached = try? cache.load() {
            render(model.reduce(.quotaLoaded(cached)))
        }

        updatePetWindow()
        windowTimer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePetWindow()
            }
        }
        freshnessTimer = Timer.scheduledTimer(
            withTimeInterval: 60,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }
                self.render(
                    self.model.reduce(.clockTick(Date()))
                )
            }
        }

        guard mockSnapshot == nil else {
            return
        }
        refreshQuota()
        quotaTimer = Timer.scheduledTimer(
            withTimeInterval:
                configuration.refreshIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshQuota()
            }
        }
    }

    private func refreshQuota() {
        Task {
            do {
                let snapshot = try await provider.fetch()
                try? cache.save(snapshot)
                render(model.reduce(.quotaLoaded(snapshot)))
            } catch let error as QuotaProviderError {
                render(model.reduce(.quotaFailed(error)))
                fputs(
                    Redaction.sanitize(
                        "Codex Pet HUD quota refresh failed: \(error)\n"
                    ),
                    stderr
                )
            } catch {
                render(model.reduce(.quotaFailed(.unavailable)))
                fputs(
                    "Codex Pet HUD quota refresh failed: unavailable.\n",
                    stderr
                )
            }
        }
    }

    private func updatePetWindow() {
        let presentation = model.reduce(
            .petWindowChanged(
                PetWindowLocator.currentWindow()
            )
        )
        render(presentation)
    }

    private func render(
        _ presentation: PanelPresentation
    ) {
        lastPresentation = presentation
        guard
            presentation.showNameplate,
            let petWindow = presentation.petWindow
        else {
            nameplateController.hide()
            criticalController.hide()
            return
        }

        let displays = Self.currentDisplays()
        guard
            let nameplateFrame =
                PanelGeometry.nameplateFrame(
                    pet: petWindow.bounds,
                    displays: displays,
                    nameplateSize: CGSize(
                        width: 280,
                        height: 92
                    ),
                    offset: configuration.nameplateOffset
                )
        else {
            nameplateController.hide()
            criticalController.hide()
            return
        }

        let viewData = HUDPresentationData.make(
            petName: manifest?.displayName ?? "CODEX PET",
            state: presentation.hudState,
            now: Date()
        )
        nameplateController.show(
            frame: nameplateFrame,
            data: viewData
        )

        guard
            presentation.showCriticalEffect,
            let criticalFrame =
                PanelGeometry.criticalFrame(
                    pet: petWindow.bounds,
                    displays: displays
                )
        else {
            criticalController.hide()
            return
        }
        criticalController.show(
            frame: criticalFrame,
            petImage: neutralImage
        )
    }

    private static func currentDisplays()
        -> [DisplayDescriptor]
    {
        NSScreen.screens.compactMap { screen in
            guard
                let displayNumber =
                    screen.deviceDescription[
                        NSDeviceDescriptionKey("NSScreenNumber")
                    ] as? NSNumber
            else {
                return nil
            }
            let displayID = CGDirectDisplayID(
                displayNumber.uint32Value
            )
            return DisplayDescriptor(
                cgBounds: CGDisplayBounds(displayID),
                appKitFrame: screen.frame
            )
        }
    }
}
