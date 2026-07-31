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

        return appKitPetFrame(pet: pet, on: display)
    }

    private static func appKitPetFrame(
        pet: CGRect,
        on display: DisplayDescriptor
    ) -> CGRect {
        let localX = pet.minX - display.cgBounds.minX
        let localY = pet.minY - display.cgBounds.minY
        return CGRect(
            x: display.appKitFrame.minX + localX,
            y: display.appKitFrame.maxY - localY - pet.height,
            width: pet.width,
            height: pet.height
        )
    }

    public static func tacticalHUDFrame(
        pet: CGRect,
        displays: [DisplayDescriptor],
        scale: CGFloat,
        offset: CGPoint
    ) -> CGRect? {
        guard let display = display(
            containingMostOf: pet,
            from: displays
        ) else {
            return nil
        }
        let appKitPet = appKitPetFrame(pet: pet, on: display)

        let width = min(
            320,
            max(190, appKitPet.width * 1.05)
        ) * scale
        let height = 72 * scale
        let gap = max(8, appKitPet.height * 0.04)
        let frame = CGRect(
            x: appKitPet.midX - width / 2 + offset.x,
            y: appKitPet.maxY + gap + offset.y,
            width: width,
            height: height
        )
        return clamp(frame, to: display.appKitFrame)
    }

    private static func clamp(
        _ frame: CGRect,
        to display: CGRect?
    ) -> CGRect? {
        guard let display else {
            return nil
        }

        let width = min(frame.width, display.width)
        let height = min(frame.height, display.height)
        return CGRect(
            x: min(
                max(frame.minX, display.minX),
                display.maxX - width
            ),
            y: min(
                max(frame.minY, display.minY),
                display.maxY - height
            ),
            width: width,
            height: height
        )
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

}

private extension CGRect {
    var area: CGFloat {
        guard !isNull else {
            return 0
        }
        return max(0, width) * max(0, height)
    }
}
