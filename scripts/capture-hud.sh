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
    let names = Set([
      "Codex Pet HUD Tactical",
      "Codex Pet HUD Pet Effect",
    ])
    let rects = rows.compactMap { row -> CGRect? in
      let name = row[kCGWindowName as String] as? String ?? ""
      let onScreen =
        (row[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ??
        false
      guard
        names.contains(name),
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
    guard rects.count == names.count else {
      exit(5)
    }
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
