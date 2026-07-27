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

    public var isExactMascotWindow: Bool {
        owner == "ChatGPT" &&
            name == PetWindowLocator.exactWindowName
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

        let voiceControls = windows.filter {
            $0.owner == "ChatGPT" &&
                $0.layer == 3 &&
                (20...32).contains($0.bounds.width) &&
                (20...32).contains($0.bounds.height)
        }
        let fallback = windows.filter { candidate in
            guard
                candidate.owner == "ChatGPT",
                candidate.name.isEmpty,
                candidate.layer == 2,
                (120...640).contains(candidate.bounds.width),
                (120...680).contains(candidate.bounds.height)
            else {
                return false
            }
            let aspectRatio =
                candidate.bounds.width /
                candidate.bounds.height
            guard
                (0.90...1.05).contains(aspectRatio)
            else {
                return false
            }
            return voiceControls.contains { control in
                control.ownerPID == candidate.ownerPID &&
                    candidate.bounds.contains(control.bounds)
            }
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
