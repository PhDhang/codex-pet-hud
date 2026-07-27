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

    public static func lifePodFrame(
        pet: CGRect,
        displays: [DisplayDescriptor],
        scale: CGFloat,
        offset: CGPoint
    ) -> CGRect? {
        guard
            let appKitPet = appKitPetFrame(
                pet: pet,
                displays: displays
            )
        else {
            return nil
        }

        let size = CGSize(
            width: appKitPet.width * scale,
            height: appKitPet.height * scale
        )
        return CGRect(
            x: appKitPet.midX - size.width / 2 + offset.x,
            y: appKitPet.midY - size.height / 2 + offset.y,
            width: size.width,
            height: size.height
        )
    }

    public static func criticalFrame(
        pet: CGRect,
        displays: [DisplayDescriptor]
    ) -> CGRect? {
        appKitPetFrame(pet: pet, displays: displays)
    }

    public static func tacticalHUDFrame(
        pet: CGRect,
        displays: [DisplayDescriptor],
        scale: CGFloat,
        offset: CGPoint
    ) -> CGRect? {
        guard let appKitPet = appKitPetFrame(
            pet: pet,
            displays: displays
        ) else {
            return nil
        }

        let width = min(
            360,
            max(210, appKitPet.width * 1.05)
        ) * scale
        let height = 58 * scale
        let gap = max(8, appKitPet.height * 0.04)
        let frame = CGRect(
            x: appKitPet.midX - width / 2 + offset.x,
            y: appKitPet.maxY + gap + offset.y,
            width: width,
            height: height
        )
        return clamp(
            frame,
            to: displayContaining(appKitPet, displays: displays)
        )
    }

    public static func petEffectFrame(
        pet: CGRect,
        displays: [DisplayDescriptor]
    ) -> CGRect? {
        guard let appKitPet = appKitPetFrame(
            pet: pet,
            displays: displays
        ) else {
            return nil
        }

        let travel = min(appKitPet.width * 0.18, 28)
        let width = max(
            appKitPet.width * 1.35,
            appKitPet.width + travel * 2
        )
        let height = appKitPet.height * 1.10
        let frame = CGRect(
            x: appKitPet.midX - width / 2,
            y: appKitPet.minY,
            width: width,
            height: height
        )
        return clamp(
            frame,
            to: displayContaining(appKitPet, displays: displays)
        )
    }

    private static func displayContaining(
        _ rect: CGRect,
        displays: [DisplayDescriptor]
    ) -> CGRect? {
        guard let display = display(
            containingMostOf: rect,
            from: displays
        ) else {
            return nil
        }
        return display.appKitFrame
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
