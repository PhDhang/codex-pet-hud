import Foundation

public enum ApplicationEvent: Sendable {
    case petWindowChanged(WindowDescriptor?)
    case quotaLoaded(QuotaSnapshot)
    case quotaFailed(QuotaProviderError)
    case clockTick(Date)
}

public struct PanelPresentation: Equatable, Sendable {
    public let showNameplate: Bool
    public let showCriticalEffect: Bool
    public let hudState: HUDState
    public let petWindow: WindowDescriptor?

    public init(
        showNameplate: Bool,
        showCriticalEffect: Bool,
        hudState: HUDState,
        petWindow: WindowDescriptor?
    ) {
        self.showNameplate = showNameplate
        self.showCriticalEffect = showCriticalEffect
        self.hudState = hudState
        self.petWindow = petWindow
    }
}

public struct ApplicationModel: Sendable {
    private var petWindow: WindowDescriptor?
    private var snapshot: QuotaSnapshot?
    private var hudState: HUDState
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
            now = snapshot.fetchedAt
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

        let isCritical: Bool
        if case let .quota(_, band) = hudState {
            isCritical = band == .critical
        } else {
            isCritical = false
        }
        let hasPet = petWindow != nil
        return PanelPresentation(
            showNameplate: hasPet,
            showCriticalEffect: hasPet && isCritical,
            hudState: hudState,
            petWindow: petWindow
        )
    }
}
