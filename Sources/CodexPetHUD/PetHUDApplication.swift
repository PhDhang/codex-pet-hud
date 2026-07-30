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
    private let mockSnapshot: QuotaSnapshot?
    private let tacticalHUDController =
        TacticalHUDPanelController()
    private let geometryCache: PetGeometryCache

    private var model = ApplicationModel(now: Date())
    private var geometryPersistence:
        PetGeometryPersistenceState
    private var presenceTracker: PetPresenceTracker
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
        let applicationSupport = home
            .appendingPathComponent(
                "Library/Application Support",
                isDirectory: true
            )
            .appendingPathComponent(
                "CodexPetHUD",
                isDirectory: true
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
            url: applicationSupport.appendingPathComponent(
                "snapshot.json"
            )
        )
        geometryCache = PetGeometryCache(
            url: applicationSupport.appendingPathComponent(
                "pet-geometry.json"
            )
        )
        let restored = try? geometryCache.load(
            intersecting: Self.currentDisplays().map(\.cgBounds)
        )?.geometry
        geometryPersistence = PetGeometryPersistenceState(
            persistedGeometry: restored
        )
        presenceTracker = PetPresenceTracker(
            restoredGeometry: restored
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
        self.mockSnapshot = mockSnapshot
    }

    func start() {
        if let mockSnapshot {
            render(
                model.reduce(.quotaLoaded(mockSnapshot))
            )
        } else if let cached = try? cache.load() {
            _ = model.reduce(.quotaLoaded(cached))
            render(model.reduce(.clockTick(Date())))
        }

        updatePetWindow()
        let windowTimer = Timer(
            timeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updatePetWindow()
            }
        }
        RunLoop.main.add(windowTimer, forMode: .common)
        self.windowTimer = windowTimer

        let freshnessTimer = Timer(
            timeInterval: 60,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }
                self.render(
                    self.model.reduce(.clockTick(Date()))
                )
            }
        }
        RunLoop.main.add(freshnessTimer, forMode: .common)
        self.freshnessTimer = freshnessTimer

        guard mockSnapshot == nil else {
            return
        }
        refreshQuota()
        let quotaTimer = Timer(
            timeInterval:
                configuration.refreshIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshQuota()
            }
        }
        RunLoop.main.add(quotaTimer, forMode: .common)
        self.quotaTimer = quotaTimer
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
        let now = Date()
        let observation =
            PetWindowLocator.currentObservation()
        if
            let visualGeometry = observation.visualGeometry,
            geometryPersistence.needsPersistence(visualGeometry),
            (try? geometryCache.save(
                visualGeometry,
                updatedAt: now
            )) == true
        {
            geometryPersistence.recordPersisted(visualGeometry)
        }
        let petGeometry = presenceTracker.update(
            observation: observation,
            now: now
        )
        render(
            model.reduce(
                .petWindowChanged(petGeometry?.window)
            )
        )
    }

    private func render(
        _ presentation: PanelPresentation
    ) {
        lastPresentation = presentation
        guard
            presentation.showHUD,
            let petWindow = presentation.petWindow
        else {
            tacticalHUDController.hide()
            return
        }

        let displays = Self.currentDisplays()
        guard
            let tacticalHUDFrame =
                PanelGeometry.tacticalHUDFrame(
                    pet: petWindow.bounds,
                    displays: displays,
                    scale: configuration.podScale,
                    offset: CGPoint(
                        x: configuration.podOffsetX,
                        y: configuration.podOffsetY
                    ),
                )
        else {
            tacticalHUDController.hide()
            return
        }

        let viewData = HUDPresentationData.make(
            manifest: manifest,
            state: presentation.hudState,
            now: Date()
        )

        tacticalHUDController.show(
            frame: tacticalHUDFrame,
            data: viewData
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
