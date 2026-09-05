import AppKit
import CoreGraphics
import Foundation

public struct NativePetSettings: Equatable, Sendable {
    public let overlayOpen: Bool
    public let petVisible: Bool
    public let mascotWidth: CGFloat

    public init(overlayOpen: Bool, petVisible: Bool, mascotWidth: CGFloat) {
        self.overlayOpen = overlayOpen
        self.petVisible = petVisible
        self.mascotWidth = mascotWidth
    }

    public static func parse(globalState: Data, configTOML: String) -> Self? {
        struct OpenState: Decodable {
            let open: Bool
            enum CodingKeys: String, CodingKey {
                case open = "electron-avatar-overlay-open"
            }
        }
        guard let state = try? JSONDecoder().decode(OpenState.self, from: globalState) else {
            return nil
        }
        var width: CGFloat = 112
        var visible = true
        var desktop = false
        var topLevel = true
        var arrayDepth = 0
        var seen = Set<String>()
        // This is intentionally a narrow reader, not a general TOML parser.
        // Unsupported multiline syntax fails closed instead of reading a key
        // embedded in a string as a setting. No file content is logged.
        for raw in configTOML.components(separatedBy: .newlines) {
            let scanned = scanTOMLLine(raw)
            let line = scanned.text.trimmingCharacters(in: .whitespaces)
            if line.contains("\"\"\"") || line.contains("'''") { return nil }
            if arrayDepth > 0 {
                arrayDepth += scanned.arrayDelta
                guard arrayDepth >= 0 else { return nil }
                continue
            }
            if line.hasPrefix("[") {
                guard line.hasSuffix("]"), !line.contains("\\") else { return nil }
                let table = line.dropFirst().dropLast().trimmingCharacters(in: .whitespaces)
                desktop = ["desktop", "\"desktop\"", "'desktop'"].contains(table)
                topLevel = false
                continue
            }
            guard let separator = line.firstIndex(of: "=") else { continue }
            arrayDepth = scanned.arrayDelta
            guard arrayDepth >= 0 else { return nil }
            let rawKey = line[..<separator].trimmingCharacters(in: .whitespaces)
            if topLevel || desktop {
                guard !rawKey.contains("\\") else { return nil }
            }
            if topLevel {
                let compact = rawKey.filter { !$0.isWhitespace }
                for root in ["desktop", "\"desktop\"", "'desktop'"] {
                    if compact == root || compact.hasPrefix(root + ".") { return nil }
                }
            }
            guard desktop else { continue }
            guard let key = ["avatar-overlay-mascot-width-px", "avatar-overlay-pet-visible"].first(where: {
                [$0, "\"\($0)\"", "'\($0)'"].contains(rawKey)
            }) else { continue }
            guard seen.insert(key).inserted else { return nil }
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if key == "avatar-overlay-mascot-width-px" {
                guard let integer = Int(value), (80...224).contains(integer) else { return nil }
                width = CGFloat(integer)
            } else {
                guard ["true", "false"].contains(value) else { return nil }
                visible = value == "true"
            }
        }
        guard arrayDepth == 0 else { return nil }
        return Self(overlayOpen: state.open, petVisible: visible, mascotWidth: width)
    }

    private static func scanTOMLLine(_ raw: String) -> (text: String, arrayDelta: Int) {
        var text = ""
        var quote: Character?
        var escaped = false
        var arrayDelta = 0
        for character in raw {
            if let activeQuote = quote {
                text.append(character)
                if escaped {
                    escaped = false
                } else if activeQuote == "\"" && character == "\\" {
                    escaped = true
                } else if character == activeQuote {
                    quote = nil
                }
            } else {
                if character == "#" { break }
                text.append(character)
                if character == "\"" || character == "'" {
                    quote = character
                } else if character == "[" {
                    arrayDelta += 1
                } else if character == "]" {
                    arrayDelta -= 1
                }
            }
        }
        return (text, arrayDelta)
    }
}

public struct NativePetWindowContext: Sendable {
    @MainActor private static var settingsReader = NativePetSettingsReader()
    public let settings: NativePetSettings
    /// CG coordinates, excluding the top menu-bar inset but including the Dock.
    public let displays: [CGRect]
    public let verifiedOwnerPIDs: Set<Int>

    public init(settings: NativePetSettings, displays: [CGRect], verifiedOwnerPIDs: Set<Int>) {
        self.settings = settings
        self.displays = displays
        self.verifiedOwnerPIDs = verifiedOwnerPIDs
    }

    @MainActor
    static func current(for windows: [WindowDescriptor]) -> Self? {
        let home = ProcessInfo.processInfo.environment["CODEX_HOME"]
            .map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        guard let settings = settingsReader.load(codexHome: home) else { return nil }
        let pids = Set(windows.filter { $0.layer == 3 }.map(\.ownerPID)).filter {
            NSRunningApplication(processIdentifier: pid_t($0))?.bundleIdentifier == "com.openai.codex"
        }
        let displays = NSScreen.screens.compactMap { screen -> CGRect? in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let bounds = CGDisplayBounds(id.uint32Value)
            let topInset = screen.frame.maxY - screen.visibleFrame.maxY
            let leftInset = screen.visibleFrame.minX - screen.frame.minX
            return CGRect(x: bounds.minX + leftInset, y: bounds.minY + topInset,
                          width: screen.visibleFrame.width, height: bounds.height - topInset)
        }
        return Self(settings: settings, displays: displays, verifiedOwnerPIDs: pids)
    }
}
