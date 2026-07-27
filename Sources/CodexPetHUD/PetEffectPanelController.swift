import AppKit
import PetHUDCore
import SwiftUI

@MainActor
final class PetEffectPanelController {
    private let panel: NSPanel
    private let hostingView: NSHostingView<AnyView>

    init() {
        hostingView = NSHostingView(
            rootView: AnyView(EmptyView())
        )
        panel = ClickThroughPanel(
            contentRect: CGRect(
                x: 0,
                y: 0,
                width: 1,
                height: 1
            )
        )
        panel.title = "Codex Pet HUD Pet Effect"
        panel.contentView = hostingView
    }

    func show(
        frame: CGRect,
        petFrame: CGRect,
        state: PetDistressState,
        assets: PetEffectAssets
    ) {
        guard state != .normal else {
            hide()
            return
        }
        hostingView.rootView = AnyView(
            PetEffectView(
                state: state,
                assets: assets,
                layout: PetEffectLayout(
                    panelFrame: frame,
                    petFrame: petFrame
                )
            )
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}
