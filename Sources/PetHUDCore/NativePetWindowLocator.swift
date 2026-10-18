import CoreGraphics

/// Exact native overlay signatures, not a general floating-window matcher.
/// October controls share a surface with Mini; persisted pet visibility cannot
/// distinguish every transient presentation. This documented compatibility mode
/// may keep the quota-only HUD visible over Mini, without modifying the pet.
enum NativePetWindowLocator {
    // 26.901: asymmetric right padding. 26.917: expanded horizontal animation
    // overscan, with the fixed 80pt drawing anchor 688pt from the left edge.
    // Its center is 688 + 40 - 1128/2 = 164pt right of the surface center.
    private struct Signature {
        let width: CGFloat
        let centerOffsetX: CGFloat
        var topAligned = false
        var singleDisplayOnly = false
    }

    private static let signatures: [Signature] = [
        Signature(width: 772, centerOffsetX: -14),
        Signature(width: 1128, centerOffsetX: 164),
        // 26.1013: 16pt side clearance; 384pt plain / 386pt controls viewport.
        // With controls, the fixed draw anchor shares the visible pet's top.
        // On multiple displays this build uses screen-sized containers instead;
        // those cannot safely identify a pet, so do not infer their geometry.
        Signature(width: 1132, centerOffsetX: 166, singleDisplayOnly: true),
        Signature(width: 1138, centerOffsetX: 167, topAligned: true, singleDisplayOnly: true),
    ]

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
        // All supported overscan layouts keep this vertical contract. Horizontal
        // overscan and visible-anchor alignment are paired in the signatures.
        let expectedHeight = 2 * maximumHeight + 56 - 87
        let candidates = windows.compactMap { window -> (window: WindowDescriptor, signature: Signature)? in
            guard context.verifiedOwnerPIDs.contains(window.ownerPID),
                ["ChatGPT", "Codex"].contains(window.owner) &&
                ["ChatGPT", "Codex", ""].contains(window.name) &&
                window.layer == 3 &&
                abs(window.bounds.height - expectedHeight) <= 1,
                let signature = signatures.first(where: { abs(window.bounds.width - $0.width) <= 1 }),
                !signature.singleDisplayOnly || context.displays.count == 1
            else { return nil }
            return (window, signature)
        }
        guard candidates.count == 1, let candidate = candidates.first else {
            return PetWindowObservation(exactWindow: nil, hasStablePresence: false,
                                        hasExactWindowAmbiguity: candidates.count > 1)
        }
        let container = candidate.window
        let width = settings.mascotWidth
        let height = ceil(width / PetWindowLocator.v2CellAspectRatio)
        let anchorX = container.bounds.midX + candidate.signature.centerOffsetX
        let bounds: CGRect
        if candidate.signature.topAligned {
            // Native controls layout uses round(petWidth/2) when centering the
            // fixed 80x87 draw anchor and keeps its y equal to the pet's top.
            bounds = CGRect(x: anchorX - (width / 2).rounded(),
                            y: container.bounds.midY - 87 / 2,
                            width: width, height: height)
        } else {
            bounds = CGRect(x: anchorX - width / 2, y: container.bounds.midY - height / 2,
                            width: width, height: height)
        }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        guard context.displays.contains(where: { $0.width >= 800 && $0.contains(center) }) else {
            return missing
        }
        let visual = WindowDescriptor(owner: container.owner, name: container.name, layer: container.layer,
                                      bounds: bounds,
                                      ownerPID: container.ownerPID, windowID: container.windowID)
        return PetWindowObservation(exactWindow: container,
                                    visualGeometry: PetVisualGeometry(window: visual, source: .nativeContainer),
                                    hasStablePresence: true, stablePresencePID: container.ownerPID)
    }
}
