import CoreGraphics

public struct DisplayDescriptor: Equatable, Sendable {
    public let cgBounds: CGRect
    public let appKitFrame: CGRect

    public init(
        cgBounds: CGRect,
        appKitFrame: CGRect
    ) {
        self.cgBounds = cgBounds
        self.appKitFrame = appKitFrame
    }
}

public enum PanelGeometry {
    public static func appKitPetFrame(
        pet: CGRect,
        displays: [DisplayDescriptor]
    ) -> CGRect? {
        guard let display = display(
            containingMostOf: pet,
            from: displays
        ) else {
            return nil
        }

        let localX = pet.minX - display.cgBounds.minX
        let localY = pet.minY - display.cgBounds.minY
        return CGRect(
            x: display.appKitFrame.minX + localX,
            y: display.appKitFrame.maxY - localY - pet.height,
            width: pet.width,
            height: pet.height
        )
    }

    public static func nameplateFrame(
        pet: CGRect,
        displays: [DisplayDescriptor],
        nameplateSize: CGSize,
        offset: CGFloat
    ) -> CGRect? {
        guard
            let display = display(
                containingMostOf: pet,
                from: displays
            ),
            let appKitPet = appKitPetFrame(
                pet: pet,
                displays: [display]
            )
        else {
            return nil
        }

        let proposed = CGRect(
            x: appKitPet.midX - nameplateSize.width / 2,
            y: appKitPet.maxY + offset,
            width: nameplateSize.width,
            height: nameplateSize.height
        )
        return clamp(proposed, inside: display.appKitFrame)
    }

    public static func criticalFrame(
        pet: CGRect,
        displays: [DisplayDescriptor]
    ) -> CGRect? {
        appKitPetFrame(pet: pet, displays: displays)
    }

    private static func display(
        containingMostOf rect: CGRect,
        from displays: [DisplayDescriptor]
    ) -> DisplayDescriptor? {
        displays
            .map { display in
                (
                    display,
                    display.cgBounds.intersection(rect).area
                )
            }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?
            .0
    }

    private static func clamp(
        _ rect: CGRect,
        inside bounds: CGRect
    ) -> CGRect {
        let x = min(
            max(rect.minX, bounds.minX),
            max(bounds.minX, bounds.maxX - rect.width)
        )
        let y = min(
            max(rect.minY, bounds.minY),
            max(bounds.minY, bounds.maxY - rect.height)
        )
        return CGRect(
            origin: CGPoint(x: x, y: y),
            size: rect.size
        )
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull else {
            return 0
        }
        return max(0, width) * max(0, height)
    }
}
