#!/bin/bash

set -euo pipefail

OUTPUT="${1:?usage: capture-hud.sh OUTPUT}"
WINDOW_ID="$(
  swift -e '
    import CoreGraphics
    import Foundation

    let rows = CGWindowListCopyWindowInfo(
      .optionAll,
      kCGNullWindowID
    ) as? [[String: Any]] ?? []
    let tacticalName = "Codex Pet HUD Tactical"
    let effectName = "Codex Pet HUD Pet Effect"
    func visibleWindowIDs(named expectedName: String) -> [UInt32] {
      rows.compactMap { row -> UInt32? in
        let name = row[kCGWindowName as String] as? String ?? ""
        guard name == expectedName else {
          return nil
        }
        let onScreen =
          (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ??
          false
        guard
          onScreen,
          let windowNumber =
            row[kCGWindowNumber as String] as? NSNumber
        else {
          return nil
        }
        return windowNumber.uint32Value
      }
    }
    let tacticalWindowIDs = visibleWindowIDs(named: tacticalName)
    let effectWindowIDs = visibleWindowIDs(named: effectName)
    guard tacticalWindowIDs.count == 1 else {
      exit(5)
    }
    guard effectWindowIDs.isEmpty else {
      exit(5)
    }
    print(tacticalWindowIDs[0])
  '
)"

mkdir -p "$(dirname "$OUTPUT")"
screencapture -x -o -l "$WINDOW_ID" "$OUTPUT"
