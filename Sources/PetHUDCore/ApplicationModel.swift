import Foundation

public enum ApplicationEvent: Sendable {
    case petWindowChanged(WindowDescriptor?)
    case quotaLoaded(QuotaSnapshot)
    case quotaFailed(QuotaProviderError)
    case clockTick(Date)
}

public struct PanelPresentation: Equatable, Sendable {
    public let showHUD: Bool
    public let distressState: PetDistressState
    public let hudState: HUDState
    public let petWindow: WindowDescriptor?

    public var showNameplate: Bool {
        showHUD
    }

    public var showCriticalEffect: Bool {
        distressState == .critical
    }

    public init(
        showHUD: Bool,
        distressState: PetDistressState,
        hudState: HUDState,
        petWindow: WindowDescriptor?
    ) {
        self.showHUD = showHUD
        self.distressState = distressState
        self.hudState = hudState
        self.petWindow = petWindow
    }
}

public struct ApplicationModel: Sendable {
    private var petWindow: WindowDescriptor?
    private var snapshot: QuotaSnapshot?
    private var hudState: HUDState
    private var distressState = PetDistressState.normal
    private var now: Date

    public init(
        now: Date = .distantPast
    ) {
        petWindow = nil
        snapshot = nil
        hudState = .offline
        self.now = now
    }

    @discardableResult
    public mutating func reduce(
        _ event: ApplicationEvent
    ) -> PanelPresentation {
        switch event {
        case let .petWindowChanged(window):
            petWindow = window
        case let .quotaLoaded(snapshot):
            self.snapshot = snapshot
            now = max(now, snapshot.fetchedAt)
            hudState = HUDState.evaluate(
                snapshot: snapshot,
                now: now
            )
        case let .quotaFailed(error):
            if error == .authenticationRequired {
                hudState = .authenticationRequired
            } else {
                hudState = HUDState.evaluate(
                    snapshot: snapshot,
                    now: now
                )
            }
        case let .clockTick(date):
            now = date
            hudState = HUDState.evaluate(
                snapshot: snapshot,
                now: now
            )
        }

        distressState = PetDistressState.evaluate(
            hudState: hudState,
            previous: distressState
        )
        return PanelPresentation(
            showHUD: petWindow != nil,
            distressState: distressState,
            hudState: hudState,
            petWindow: petWindow
        )
    }
}
