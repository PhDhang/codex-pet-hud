import AppKit
import PetHUDCore
import SwiftUI

@MainActor
final class LifePodPanelController {
    private let panel: NSPanel
    private let hostingView: NSHostingView<LifePodView>

    init() {
        let initial = HUDPresentationData.make(
            petName: "CODEX PET",
            state: .offline,
            now: Date()
        )
        hostingView = NSHostingView(
            rootView: LifePodView(data: initial)
        )
        panel = ClickThroughPanel(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: 1,
                height: 1
            )
        )
        panel.title = "Codex Pet HUD Life Pod"
        panel.contentView = hostingView
    }

    func show(
        frame: CGRect,
        data: HUDPresentationData
    ) {
        hostingView.rootView = LifePodView(data: data)
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

@MainActor
final class ClickThroughPanel: NSPanel {
    init(contentRect: CGRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
        ]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
