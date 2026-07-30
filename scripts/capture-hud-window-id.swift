#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Darwin
import Foundation

let tacticalName = "Codex Pet HUD Tactical"
let effectName = "Codex Pet HUD Pet Effect"
let bundleIdentifier = "com.codex-pet-hud.app"

struct CaptureWindow: Codable {
    let name: String
    let onScreen: Bool
    let windowID: UInt32
    let ownerPID: Int
}

struct CaptureInput: Codable {
    let runningPIDs: [Int]
    let windows: [CaptureWindow]
}

func failClosed() -> Never {
    exit(5)
}

func selectWindowID(
    from input: CaptureInput
) -> UInt32? {
    guard
        input.runningPIDs.count == 1,
        let expectedPID = input.runningPIDs.first
    else {
        return nil
    }
    let tacticalWindows = input.windows.filter {
        $0.onScreen && $0.name == tacticalName
    }
    let effectWindows = input.windows.filter {
        $0.onScreen && $0.name == effectName
    }
    guard
        tacticalWindows.count == 1,
        effectWindows.isEmpty,
        tacticalWindows[0].ownerPID == expectedPID
    else {
        return nil
    }
    return tacticalWindows[0].windowID
}

func liveInput() -> CaptureInput {
    let runningPIDs = NSRunningApplication
        .runningApplications(withBundleIdentifier: bundleIdentifier)
        .filter { !$0.isTerminated }
        .map { Int($0.processIdentifier) }
    let rows = CGWindowListCopyWindowInfo(
        .optionAll,
        kCGNullWindowID
    ) as? [[String: Any]] ?? []
    let windows = rows.compactMap {
        row -> CaptureWindow? in
        guard
            let name =
                row[kCGWindowName as String] as? String,
            let onScreen =
                row[kCGWindowIsOnscreen as String]
                    as? NSNumber,
            let windowID =
                row[kCGWindowNumber as String] as? NSNumber,
            let ownerPID =
                row[kCGWindowOwnerPID as String] as? NSNumber
        else {
            return nil
        }
        return CaptureWindow(
            name: name,
            onScreen: onScreen.boolValue,
            windowID: windowID.uint32Value,
            ownerPID: ownerPID.intValue
        )
    }
    return CaptureInput(
        runningPIDs: runningPIDs,
        windows: windows
    )
}

func input() -> CaptureInput {
    let arguments = Array(
        CommandLine.arguments.dropFirst()
    )
    guard !arguments.isEmpty else {
        return liveInput()
    }
    guard
        arguments.count == 2,
        arguments[0] == "--fixture"
    else {
        failClosed()
    }
    do {
        return try JSONDecoder().decode(
            CaptureInput.self,
            from: Data(
                contentsOf: URL(
                    fileURLWithPath: arguments[1]
                )
            )
        )
    } catch {
        failClosed()
    }
}

guard let windowID = selectWindowID(from: input()) else {
    failClosed()
}
print(windowID)
