import CoreGraphics
import Foundation

public struct WindowDescriptor: Equatable, Sendable {
    public let owner: String
    public let name: String
    public let layer: Int
    public let bounds: CGRect
    public let ownerPID: Int
    public let windowID: Int

    public init(
        owner: String,
        name: String,
        layer: Int,
        bounds: CGRect,
        ownerPID: Int,
        windowID: Int
    ) {
        self.owner = owner
        self.name = name
        self.layer = layer
        self.bounds = bounds
        self.ownerPID = ownerPID
        self.windowID = windowID
    }
}

public enum PetWindowLocator {
    public static let exactWindowName =
        "Codex Pet Mascot Effect"

    public static func currentWindow() -> WindowDescriptor? {
        let options: CGWindowListOption = [
            .optionOnScreenOnly,
            .excludeDesktopElements,
        ]
        guard
            let rows = CGWindowListCopyWindowInfo(
                options,
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return nil
        }
        return select(from: rows.compactMap(descriptor(from:)))
    }

    public static func select(
        from windows: [WindowDescriptor]
    ) -> WindowDescriptor? {
        let exact = windows.filter {
            $0.owner == "ChatGPT" &&
                $0.name == exactWindowName
        }
        if exact.count == 1 {
            return exact[0]
        }
        if exact.count > 1 {
            return nil
        }

        let fallback = windows.filter {
            $0.owner == "ChatGPT" &&
                (2...3).contains($0.layer) &&
                (160...320).contains($0.bounds.width) &&
                (160...340).contains($0.bounds.height)
        }
        guard fallback.count == 1 else {
            return nil
        }
        return fallback[0]
    }

    private static func descriptor(
        from row: [String: Any]
    ) -> WindowDescriptor? {
        guard
            let owner = row[kCGWindowOwnerName as String] as? String,
            let boundsDictionary =
                row[kCGWindowBounds as String] as? [String: Any],
            let x = number(boundsDictionary["X"]),
            let y = number(boundsDictionary["Y"]),
            let width = number(boundsDictionary["Width"]),
            let height = number(boundsDictionary["Height"]),
            let layer = number(row[kCGWindowLayer as String]),
            let ownerPID = number(
                row[kCGWindowOwnerPID as String]
            ),
            let windowID = number(
                row[kCGWindowNumber as String]
            )
        else {
            return nil
        }

        return WindowDescriptor(
            owner: owner,
            name: row[kCGWindowName as String] as? String ?? "",
            layer: Int(layer),
            bounds: CGRect(
                x: x,
                y: y,
                width: width,
                height: height
            ),
            ownerPID: Int(ownerPID),
            windowID: Int(windowID)
        )
    }

    private static func number(
        _ value: Any?
    ) -> CGFloat? {
        if let number = value as? NSNumber {
            return CGFloat(number.doubleValue)
        }
        return nil
    }
}

