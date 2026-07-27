#!/bin/bash

set -euo pipefail

OUTPUT="${1:?usage: capture-hud.sh OUTPUT}"
RECT="$(
  swift -e '
    import CoreGraphics
    import Foundation

    let rows = CGWindowListCopyWindowInfo(
      .optionAll,
      kCGNullWindowID
    ) as? [[String: Any]] ?? []
    let tacticalName = "Codex Pet HUD Tactical"
    let effectName = "Codex Pet HUD Pet Effect"
    func visibleRects(named expectedName: String) -> [CGRect] {
      rows.compactMap { row -> CGRect? in
        let name = row[kCGWindowName as String] as? String ?? ""
        guard name == expectedName else {
          return nil
        }
        let onScreen =
          (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ??
          false
        guard
          onScreen,
          let dictionary =
            row[kCGWindowBounds as String] as? [String: Any]
        else {
          return nil
        }
        return CGRect(
          dictionaryRepresentation:
            dictionary as CFDictionary
        )
      }
    }
    let tacticalRects = visibleRects(named: tacticalName)
    let effectRects = visibleRects(named: effectName)
    guard tacticalRects.count == 1 else {
      exit(5)
    }
    guard effectRects.count <= 1 else {
      exit(5)
    }
    let rects = tacticalRects + effectRects
    let union = rects.dropFirst().reduce(rects[0]) {
      $0.union($1)
    }
    let capture = union.insetBy(dx: -12, dy: -12)
    print(
      "\(Int(floor(capture.minX)))," +
      "\(Int(floor(capture.minY)))," +
      "\(Int(ceil(capture.width)))," +
      "\(Int(ceil(capture.height)))"
    )
  '
)"

mkdir -p "$(dirname "$OUTPUT")"
screencapture -x -R"$RECT" "$OUTPUT"
