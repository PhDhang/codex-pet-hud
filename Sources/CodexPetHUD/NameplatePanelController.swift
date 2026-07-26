import AppKit
import PetHUDCore
import SwiftUI

@MainActor
final class NameplatePanelController {
    private let panel: NSPanel
    private let hostingView: NSHostingView<DungeonNameplateView>

    init() {
        let initial = HUDPresentationData.make(
            petName: "CODEX PET",
            state: .offline,
            now: Date()
        )
        hostingView = NSHostingView(
            rootView: DungeonNameplateView(data: initial)
        )
        panel = ClickThroughPanel(
            contentRect: CGRect(
                origin: .zero,
                size: CGSize(width: 280, height: 92)
            )
        )
        panel.title = "Codex Pet HUD Nameplate"
        panel.contentView = hostingView
    }

    func show(
        frame: CGRect,
        data: HUDPresentationData
    ) {
        hostingView.rootView = DungeonNameplateView(
            data: data
        )
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
            .stationary,
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

