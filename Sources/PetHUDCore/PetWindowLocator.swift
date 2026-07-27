import CoreGraphics
import Foundation

public struct WindowDescriptor:
    Codable,
    Equatable,
    Sendable
{
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

public enum PetVisualGeometrySource:
    String,
    Codable,
    Equatable,
    Sendable
{
    case shellDerived
    case mascotFallback
}

public struct PetVisualGeometry:
    Equatable,
    Sendable
{
    public let window: WindowDescriptor
    public let source: PetVisualGeometrySource

    public init(
        window: WindowDescriptor,
        source: PetVisualGeometrySource
    ) {
        self.window = window
        self.source = source
    }
}

public struct PetWindowObservation: Equatable, Sendable {
    public let exactWindow: WindowDescriptor?
    public let visualGeometry: PetVisualGeometry?
    public let hasStablePresence: Bool
    public let stablePresencePID: Int?

    public var visualWindow: WindowDescriptor? {
        visualGeometry?.window
    }

    public init(
        exactWindow: WindowDescriptor?,
        visualGeometry: PetVisualGeometry? = nil,
        hasStablePresence: Bool,
        stablePresencePID: Int? = nil
    ) {
        self.exactWindow = exactWindow
        self.visualGeometry = visualGeometry
        self.hasStablePresence = hasStablePresence
        self.stablePresencePID = stablePresencePID
    }
}

public enum PetWindowLocator {
    public static let exactWindowName =
        "Codex Pet Mascot Effect"
    public static let visualWindowName = "Codex"
    public static let v2CellAspectRatio: CGFloat =
        192.0 / 208.0
    public static let mascotFallbackHeightScale: CGFloat =
        0.5

    private static let stableWindowNames: Set<String> = [
        "Codex Pet Composition Surface",
        "Codex Pet Voice Controls Backing",
        "Codex Pet Activity Stack Backing",
    ]

    public static func currentWindow() -> WindowDescriptor? {
        currentObservation().visualWindow
    }

    public static func currentObservation() -> PetWindowObservation {
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
            return PetWindowObservation(
                exactWindow: nil,
                hasStablePresence: false
            )
        }
        return observe(from: rows.compactMap(descriptor(from:)))
    }

    public static func observe(
        from windows: [WindowDescriptor]
    ) -> PetWindowObservation {
        let exactWindow = select(from: windows)
        let stablePresence = stablePresence(
            in: windows
        )
        return PetWindowObservation(
            exactWindow: exactWindow,
            visualGeometry: exactWindow.map {
                visualWindow(
                    for: $0,
                    in: windows,
                    stablePresencePID:
                        stablePresence.ownerPID
                ) ?? mascotFallbackGeometry(for: $0)
            },
            hasStablePresence: stablePresence.isPresent,
            stablePresencePID: stablePresence.ownerPID
        )
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

    private static func visualWindow(
        for mascotWindow: WindowDescriptor,
        in windows: [WindowDescriptor],
        stablePresencePID: Int?
    ) -> PetVisualGeometry? {
        guard
            let stablePresencePID,
            stablePresencePID == mascotWindow.ownerPID
        else {
            return nil
        }
        let candidates = windows.filter { candidate in
            guard
                candidate.owner == "ChatGPT",
                candidate.name == visualWindowName,
                candidate.layer == 3,
                candidate.ownerPID == stablePresencePID,
                (80...640).contains(candidate.bounds.width),
                (60...680).contains(candidate.bounds.height),
                candidate.bounds.intersects(mascotWindow.bounds),
                mascotWindow.bounds.contains(
                    CGPoint(
                        x: candidate.bounds.midX,
                        y: candidate.bounds.midY
                    )
                )
            else {
                return false
            }
            let visualWidth =
                candidate.bounds.height * v2CellAspectRatio
            return visualWidth <= candidate.bounds.width
        }
        guard candidates.count == 1 else {
            return nil
        }

        let shell = candidates[0]
        let visualWidth =
            shell.bounds.height * v2CellAspectRatio
        return PetVisualGeometry(
            window: WindowDescriptor(
                owner: shell.owner,
                name: shell.name,
                layer: shell.layer,
                bounds: CGRect(
                    x: shell.bounds.midX - visualWidth / 2,
                    y: shell.bounds.minY,
                    width: visualWidth,
                    height: shell.bounds.height
                ),
                ownerPID: shell.ownerPID,
                windowID: shell.windowID
            ),
            source: .shellDerived
        )
    }

    private static func mascotFallbackGeometry(
        for mascotWindow: WindowDescriptor
    ) -> PetVisualGeometry {
        let visualHeight =
            mascotWindow.bounds.height *
            mascotFallbackHeightScale
        let visualWidth =
            visualHeight * v2CellAspectRatio
        return PetVisualGeometry(
            window: WindowDescriptor(
                owner: mascotWindow.owner,
                name: mascotWindow.name,
                layer: mascotWindow.layer,
                bounds: CGRect(
                    x:
                        mascotWindow.bounds.midX -
                        visualWidth / 2,
                    y:
                        mascotWindow.bounds.midY -
                        visualHeight / 2,
                    width: visualWidth,
                    height: visualHeight
                ),
                ownerPID: mascotWindow.ownerPID,
                windowID: mascotWindow.windowID
            ),
            source: .mascotFallback
        )
    }

    private static func stablePresence(
        in windows: [WindowDescriptor]
    ) -> (isPresent: Bool, ownerPID: Int?) {
        var candidatePIDs = Set(
            windows
                .filter(\.isExactMascotWindow)
                .map(\.ownerPID)
        )
        candidatePIDs.formUnion(
            windows
                .filter(isNamedCompanionWindow)
                .map(\.ownerPID)
        )
        candidatePIDs.formUnion(
            titleRedactedIdleShellPIDs(in: windows)
        )
        guard candidatePIDs.count == 1,
              let ownerPID = candidatePIDs.first
        else {
            return (false, nil)
        }
        return (true, ownerPID)
    }

    private static func titleRedactedIdleShellPIDs(
        in windows: [WindowDescriptor]
    ) -> Set<Int> {
        let candidates = windows.filter {
            $0.owner == "ChatGPT" &&
                $0.name.isEmpty &&
                $0.layer == 3
        }
        let windowsByPID = Dictionary(grouping: candidates) {
            $0.ownerPID
        }
        return Set(windowsByPID.compactMap {
            entry -> Int? in
            let (ownerPID, windows) = entry
            guard
                windows.contains(where: isVoiceControl) &&
                windows.contains(where: isCompositionSurface) &&
                windows.contains(where: isActivityStack)
            else {
                return nil
            }
            return ownerPID
        })
    }

    private static func isNamedCompanionWindow(
        _ window: WindowDescriptor
    ) -> Bool {
        window.owner == "ChatGPT" &&
            stableWindowNames.contains(window.name)
    }

    private static func isVoiceControl(
        _ window: WindowDescriptor
    ) -> Bool {
        (20...32).contains(window.bounds.width) &&
            (20...32).contains(window.bounds.height)
    }

    private static func isCompositionSurface(
        _ window: WindowDescriptor
    ) -> Bool {
        (480...1_200).contains(window.bounds.width) &&
            (480...1_400).contains(window.bounds.height)
    }

    private static func isActivityStack(
        _ window: WindowDescriptor
    ) -> Bool {
        (180...500).contains(window.bounds.width) &&
            (30...90).contains(window.bounds.height)
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
