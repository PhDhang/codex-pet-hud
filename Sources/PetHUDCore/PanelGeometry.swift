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
