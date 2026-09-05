import CoreGraphics

/// Compatibility with the native floating pet container in ChatGPT 26.901.
/// It replaced the named mascot/voice/composition windows used by older builds.
enum NativePetWindowLocator {
    static func observe(from windows: [WindowDescriptor], context: NativePetWindowContext) -> PetWindowObservation {
        let missing = PetWindowObservation(exactWindow: nil, hasStablePresence: false)
        let settings = context.settings
        guard settings.overlayOpen, settings.petVisible,
              settings.mascotWidth.isFinite, (80...224).contains(settings.mascotWidth),
              let maximumHeight = context.displays.map(\.height).max(), maximumHeight > 0
        else { return missing }

        // The native drawing anchor is always 80 x ceil(80 * 208/192) = 87,
        // independent of the visible pet size. The overscan surface has 28pt
        // padding above/below a full display-height allowance in each direction.
        // Its 384pt viewport + horizontal animation allowance produces 772pt.
        // The right-only 28pt padding puts the pet center 14pt left of its center.
        // Do not generalize this to arbitrary large floating windows.
        let expectedHeight = 2 * maximumHeight + 56 - 87
        let candidates = windows.filter { window in
            context.verifiedOwnerPIDs.contains(window.ownerPID) &&
                ["ChatGPT", "Codex"].contains(window.owner) &&
                ["ChatGPT", "Codex", ""].contains(window.name) &&
                window.layer == 3 &&
                abs(window.bounds.width - 772) <= 1 &&
                abs(window.bounds.height - expectedHeight) <= 1
        }
        guard candidates.count == 1, let container = candidates.first else {
            return PetWindowObservation(exactWindow: nil, hasStablePresence: false,
                                        hasExactWindowAmbiguity: candidates.count > 1)
        }
        let width = settings.mascotWidth
        let height = ceil(width / PetWindowLocator.v2CellAspectRatio)
        let center = CGPoint(x: container.bounds.midX - 14, y: container.bounds.midY)
        guard context.displays.contains(where: { $0.width >= 800 && $0.contains(center) }) else {
            return missing
        }
        let visual = WindowDescriptor(owner: container.owner, name: container.name, layer: container.layer,
                                      bounds: CGRect(x: center.x - width / 2, y: center.y - height / 2,
                                                     width: width, height: height),
                                      ownerPID: container.ownerPID, windowID: container.windowID)
        return PetWindowObservation(exactWindow: container,
                                    visualGeometry: PetVisualGeometry(window: visual, source: .nativeContainer),
                                    hasStablePresence: true, stablePresencePID: container.ownerPID)
    }
}
