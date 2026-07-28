import Foundation

public enum ApplicationEvent: Sendable {
    case petWindowChanged(WindowDescriptor?)
    case quotaLoaded(QuotaSnapshot)
    case quotaFailed(QuotaProviderError)
    case clockTick(Date)
}

public struct PanelPresentation: Equatable, Sendable {
    public let showHUD: Bool
    public let hudState: HUDState
    public let petWindow: WindowDescriptor?
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

        return PanelPresentation(
            showHUD: petWindow != nil,
            hudState: hudState,
            petWindow: petWindow
        )
    }
}
