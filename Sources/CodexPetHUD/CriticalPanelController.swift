import AppKit
import SwiftUI

@MainActor
final class CriticalPanelController {
    private let panel: NSPanel
    private let hostingView:
        NSHostingView<CriticalEffectView>

    init() {
        hostingView = NSHostingView(
            rootView: CriticalEffectView(petImage: nil)
        )
        panel = ClickThroughPanel(
            contentRect: CGRect(
                origin: .zero,
                size: CGSize(width: 243, height: 252)
            )
        )
        panel.title = "Codex Pet HUD Critical Effect"
        panel.contentView = hostingView
    }

    func show(
        frame: CGRect,
        petImage: CGImage?
    ) {
        hostingView.rootView = CriticalEffectView(
            petImage: petImage
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

