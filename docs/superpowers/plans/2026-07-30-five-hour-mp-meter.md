# Five-Hour MP Meter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional five-hour MP meter below weekly HP, display `MAX` when the limit is absent, animate independent HP/MP danger states only inside the HUD, and publish the tested macOS release to the existing GitHub branch and draft pull request.

**Architecture:** Normalize provider windows into a required weekly `QuotaWindow` and optional five-hour `QuotaWindow`, persist that normalized snapshot, and derive all HP/MP/SP display state in `HUDPresentationData`. Keep SwiftUI animation isolated in a reusable quota-meter view, preserve the native pet unchanged, and retain the existing high-confidence pet-window tracker and level-4 HUD panel.

**Tech Stack:** Swift 6.2, Swift Package Manager, Foundation, AppKit, SwiftUI, CoreGraphics, XCTest, Bash, macOS 14 LaunchAgent, Git, GitHub.

## Global Constraints

- macOS deployment target remains `14.0`.
- The weekly window duration is exactly `604800` seconds.
- The five-hour window duration is exactly `18000` seconds.
- A missing five-hour window after a successful weekly response displays `MAX`; it is never represented as a synthetic 100% quota window.
- MP never displays a reset countdown.
- HP and MP evaluate danger independently.
- `4–9%` uses a slow autoreversing danger pulse.
- `0–3%` uses a faster, higher-contrast danger pulse.
- Reduce Motion disables pulse animation and fixes each dangerous meter at its danger color.
- Quota state never creates, replaces, covers, or animates the native pet.
- The app never prints credentials, account identifiers, emails, cookies, or raw provider payloads.
- HUD captures include only the HUD window and never expose other desktop windows.
- Preserve the current level-4 HUD ordering, root-view refresh cache, pet movement, resize, and idle-presence behavior.

---

### Task 1: Commit the HUD Stability Baseline

**Files:**
- Modify: `Sources/CodexPetHUD/TacticalHUDPanelController.swift`
- Create: `Sources/PetHUDCore/HUDRenderState.swift`
- Modify: `Tests/Shell/tactical-ui.bats`
- Create: `Tests/PetHUDCoreTests/HUDRenderStateTests.swift`

**Interfaces:**
- Consumes: `HUDPresentationData`, `CGRect`, and the current `TacticalHUDPanelController.show(frame:data:)` call path.
- Produces: `HUDRenderState.shouldRefreshContent(data:frameSize:) -> Bool` and a level-4 panel that sizes before replacing its SwiftUI root view.

- [ ] **Step 1: Review the existing focused regression**

Confirm `HUDRenderStateTests.testDuplicateRequestDoesNotRefreshContent` asserts that the first request refreshes content and an identical second request does not.

- [ ] **Step 2: Run the focused regression and shell guards**

Run:

```bash
swift test --disable-sandbox --filter HUDRenderStateTests
bash Tests/Shell/tactical-ui.bats
```

Expected: both commands exit `0`; the Swift test reports zero failures and the shell guard confirms sizing order plus `NSWindow.Level.floating.rawValue + 1`.

- [ ] **Step 3: Inspect the exact baseline diff**

Run:

```bash
git diff --check
git diff -- Sources/CodexPetHUD/TacticalHUDPanelController.swift Sources/PetHUDCore/HUDRenderState.swift Tests/Shell/tactical-ui.bats Tests/PetHUDCoreTests/HUDRenderStateTests.swift
```

Expected: no whitespace errors; the diff contains no pet-effect source, credential access, or unrelated refactor.

- [ ] **Step 4: Commit the baseline**

Run:

```bash
git add Sources/CodexPetHUD/TacticalHUDPanelController.swift Sources/PetHUDCore/HUDRenderState.swift Tests/Shell/tactical-ui.bats Tests/PetHUDCoreTests/HUDRenderStateTests.swift
git commit -m "fix: keep tactical HUD content visible"
```

Expected: one commit containing only the four listed files.

---

### Task 2: Normalize Weekly and Five-Hour Windows

**Files:**
- Create: `Fixtures/wham-usage-five-hour.json`
- Modify: `Sources/PetHUDCore/QuotaModels.swift`
- Modify: `Sources/PetHUDCore/WhamUsageParser.swift`
- Modify: `Tests/PetHUDCoreTests/WhamUsageParserTests.swift`
- Modify: `Tests/PetHUDCoreTests/SnapshotCacheTests.swift`
- Modify: `Tests/PetHUDCoreTests/WhamUsageClientTests.swift`

**Interfaces:**
- Consumes: provider `primary_window`, `secondary_window`, `used_percent`, `reset_at`, and `limit_window_seconds`.
- Produces: `QuotaSnapshot.init(weekly:fiveHour:fetchedAt:)`, `QuotaSnapshot.fiveHour: QuotaWindow?`, and parser output that requires a weekly window while treating five-hour data as optional.

- [ ] **Step 1: Add the dual-window fixture**

Create `Fixtures/wham-usage-five-hour.json` with:

```json
{
  "rate_limit": {
    "primary_window": {
      "used_percent": 36.5,
      "reset_at": 1785402000,
      "limit_window_seconds": 18000
    },
    "secondary_window": {
      "used_percent": 18,
      "reset_at": 1785904104,
      "limit_window_seconds": 604800
    }
  }
}
```

- [ ] **Step 2: Write failing parser and cache tests**

Add these behaviors:

```swift
func testParsesWeeklyAndFiveHourWindows() throws {
    let data = try fixture(named: "wham-usage-five-hour.json")
    let snapshot = try WhamUsageParser.parse(
        data: data,
        fetchedAt: .distantPast
    )

    XCTAssertEqual(snapshot.weekly.remainingPercent, 82)
    XCTAssertEqual(snapshot.weekly.windowDurationSeconds, 604_800)
    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 63.5)
    XCTAssertEqual(snapshot.fiveHour?.windowDurationSeconds, 18_000)
}

func testPrimaryWeeklyResponseHasNoFiveHourWindow() throws {
    let data = try fixture(named: "wham-usage-primary-weekly.json")
    let snapshot = try WhamUsageParser.parse(
        data: data,
        fetchedAt: .distantPast
    )

    XCTAssertNil(snapshot.fiveHour)
}

func testIgnoresUnknownPrimaryWhenSecondaryIsWeekly() throws {
    let data = Data(
        """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 20,
              "reset_at": 1785091200,
              "limit_window_seconds": 3600
            },
            "secondary_window": {
              "used_percent": 18,
              "reset_at": 1785904104,
              "limit_window_seconds": 604800
            }
          }
        }
        """.utf8
    )
    let snapshot = try WhamUsageParser.parse(
        data: data,
        fetchedAt: .distantPast
    )

    XCTAssertEqual(snapshot.weekly.remainingPercent, 82)
    XCTAssertNil(snapshot.fiveHour)
}
```

Add a cache test that decodes this legacy JSON and asserts `fiveHour == nil`:

```swift
let legacy = Data(
    """
    {
      "weekly": {
        "usedPercent": 18,
        "resetAt": -978307200,
        "windowDurationSeconds": 604800
      },
      "fetchedAt": -978307200
    }
    """.utf8
)
try legacy.write(to: url)
let loaded = try XCTUnwrap(cache.load())
XCTAssertNil(loaded.fiveHour)
```

Extend the round-trip test with a five-hour window and assert the loaded snapshot equals the saved snapshot.

- [ ] **Step 3: Run tests to verify RED**

Run:

```bash
swift test --disable-sandbox --filter WhamUsageParserTests
swift test --disable-sandbox --filter SnapshotCacheTests
```

Expected: compilation fails because `QuotaSnapshot` has no `fiveHour` property and initializer argument.

- [ ] **Step 4: Add the optional normalized window**

Update `QuotaSnapshot` to:

```swift
public struct QuotaSnapshot: Codable, Equatable, Sendable {
    public let weekly: QuotaWindow
    public let fiveHour: QuotaWindow?
    public let fetchedAt: Date

    public init(
        weekly: QuotaWindow,
        fiveHour: QuotaWindow? = nil,
        fetchedAt: Date
    ) {
        self.weekly = weekly
        self.fiveHour = fiveHour
        self.fetchedAt = fetchedAt
    }
}
```

- [ ] **Step 5: Implement duration-based parsing**

Add private duration constants and normalized conversion:

```swift
private static let weeklyDuration: TimeInterval = 604_800
private static let fiveHourDuration: TimeInterval = 18_000

private static func normalizedWindow(
    _ window: Response.RateLimit.Window,
    defaultDuration: TimeInterval
) -> QuotaWindow {
    QuotaWindow(
        usedPercent: window.usedPercent,
        resetAt: Date(timeIntervalSince1970: window.resetAt),
        windowDurationSeconds:
            window.limitWindowSeconds ?? defaultDuration
    )
}
```

Select windows with:

```swift
let secondary = response.rateLimit.secondaryWindow
let primary = response.rateLimit.primaryWindow

let weeklySource: Response.RateLimit.Window?
if let secondary,
   secondary.limitWindowSeconds == nil ||
       secondary.limitWindowSeconds == weeklyDuration
{
    weeklySource = secondary
} else if primary?.limitWindowSeconds == weeklyDuration {
    weeklySource = primary
} else {
    weeklySource = nil
}

guard let weeklySource else {
    throw QuotaProviderError.invalidPayload
}

let fiveHourSource =
    primary?.limitWindowSeconds == fiveHourDuration
    ? primary
    : nil

return QuotaSnapshot(
    weekly: normalizedWindow(
        weeklySource,
        defaultDuration: weeklyDuration
    ),
    fiveHour: fiveHourSource.map {
        normalizedWindow(
            $0,
            defaultDuration: fiveHourDuration
        )
    },
    fetchedAt: fetchedAt
)
```

Keep the outer catch mapping malformed payloads to `.invalidPayload`.

- [ ] **Step 6: Extend the client assertion**

In `WhamUsageClientTests`, use `wham-usage-five-hour.json` and assert:

```swift
XCTAssertEqual(snapshot.weekly.remainingPercent, 82)
XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 63.5)
```

- [ ] **Step 7: Run model tests to verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter WhamUsageParserTests
swift test --disable-sandbox --filter SnapshotCacheTests
swift test --disable-sandbox --filter WhamUsageClientTests
```

Expected: all selected suites pass with zero failures.

- [ ] **Step 8: Commit normalized quota support**

Run:

```bash
git add Fixtures/wham-usage-five-hour.json Sources/PetHUDCore/QuotaModels.swift Sources/PetHUDCore/WhamUsageParser.swift Tests/PetHUDCoreTests/WhamUsageParserTests.swift Tests/PetHUDCoreTests/SnapshotCacheTests.swift Tests/PetHUDCoreTests/WhamUsageClientTests.swift
git commit -m "feat: normalize optional five-hour quota"
```

---

### Task 3: Derive MP Presentation and Independent Danger Levels

**Files:**
- Create: `Sources/PetHUDCore/QuotaDangerLevel.swift`
- Modify: `Sources/PetHUDCore/HUDPresentationData.swift`
- Create: `Tests/PetHUDCoreTests/QuotaDangerLevelTests.swift`
- Modify: `Tests/PetHUDCoreTests/HUDPresentationDataTests.swift`

**Interfaces:**
- Consumes: `QuotaSnapshot.weekly`, `QuotaSnapshot.fiveHour`, `HUDState`, and `HPPrecision`.
- Produces: `QuotaDangerLevel`, `MPPresentationMode`, `HUDPresentationData.mpText`, `mpFraction`, `mpMode`, `hpDangerLevel`, and `mpDangerLevel`.

- [ ] **Step 1: Write danger-boundary tests**

Create:

```swift
import XCTest
@testable import PetHUDCore

final class QuotaDangerLevelTests: XCTestCase {
    func testCanonicalDangerBoundaries() {
        XCTAssertEqual(QuotaDangerLevel.evaluate(10), .none)
        XCTAssertEqual(QuotaDangerLevel.evaluate(9.99), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(4), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(3.99), .low)
        XCTAssertEqual(QuotaDangerLevel.evaluate(3), .critical)
        XCTAssertEqual(QuotaDangerLevel.evaluate(0), .critical)
    }
}
```

- [ ] **Step 2: Write MP presentation tests**

Add tests that build:

```swift
let measured = QuotaSnapshot(
    weekly: QuotaWindow(
        usedPercent: 18,
        resetAt: now.addingTimeInterval(172_800),
        windowDurationSeconds: 604_800
    ),
    fiveHour: QuotaWindow(
        usedPercent: 36.5,
        resetAt: now.addingTimeInterval(7_200),
        windowDurationSeconds: 18_000
    ),
    fetchedAt: now
)
```

Assert:

```swift
XCTAssertEqual(data.mpText, "63.5%")
XCTAssertEqual(data.mpFraction, 0.635, accuracy: 0.000_001)
XCTAssertEqual(data.mpMode, .measured)
XCTAssertEqual(data.mpDangerLevel, .none)
```

For a weekly-only snapshot assert:

```swift
XCTAssertEqual(data.mpText, "MAX")
XCTAssertEqual(data.mpFraction, 1)
XCTAssertEqual(data.mpMode, .unlimited)
XCTAssertEqual(data.mpDangerLevel, .none)
```

For `.offline` and `.authenticationRequired` assert:

```swift
XCTAssertEqual(data.mpText, "--")
XCTAssertEqual(data.mpFraction, 0)
XCTAssertEqual(data.mpMode, .unavailable)
```

Add measured MP samples at `9`, `4`, and `3` percent and assert `.low`, `.low`, and `.critical`.

- [ ] **Step 3: Run tests to verify RED**

Run:

```bash
swift test --disable-sandbox --filter QuotaDangerLevelTests
swift test --disable-sandbox --filter HUDPresentationDataTests
```

Expected: compilation fails because the new danger and MP presentation APIs do not exist.

- [ ] **Step 4: Implement the pure danger type**

Create:

```swift
import Foundation

public enum QuotaDangerLevel:
    String,
    Codable,
    Equatable,
    Sendable
{
    case none
    case low
    case critical

    public static func evaluate(
        _ remainingPercent: Double
    ) -> QuotaDangerLevel {
        switch HPPrecision.canonical(remainingPercent) {
        case ...3:
            return .critical
        case ..<10:
            return .low
        default:
            return .none
        }
    }
}
```

- [ ] **Step 5: Extend presentation data**

Add:

```swift
public enum MPPresentationMode:
    String,
    Codable,
    Equatable,
    Sendable
{
    case measured
    case unlimited
    case unavailable
}
```

Add these stored properties:

```swift
public let mpText: String
public let mpFraction: Double
public let mpMode: MPPresentationMode
public let hpDangerLevel: QuotaDangerLevel
public let mpDangerLevel: QuotaDangerLevel
```

In quota and stale presentation, derive:

```swift
let mp: (
    text: String,
    fraction: Double,
    mode: MPPresentationMode,
    danger: QuotaDangerLevel
)
if let fiveHour = snapshot.fiveHour {
    let remaining = HPPrecision.canonical(
        fiveHour.remainingPercent
    )
    mp = (
        hpText(for: remaining),
        remaining / 100,
        .measured,
        QuotaDangerLevel.evaluate(remaining)
    )
} else {
    mp = ("MAX", 1, .unlimited, .none)
}
```

Set HP danger with:

```swift
hpDangerLevel: QuotaDangerLevel.evaluate(remainingPercent)
```

Set placeholder MP values to `"--"`, `0`, `.unavailable`, and `.none`.

- [ ] **Step 6: Run presentation tests to verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter QuotaDangerLevelTests
swift test --disable-sandbox --filter HUDPresentationDataTests
swift test --disable-sandbox --filter ApplicationModelTests
```

Expected: all selected suites pass with zero failures and existing weekly labels remain unchanged.

- [ ] **Step 7: Commit MP presentation**

Run:

```bash
git add Sources/PetHUDCore/QuotaDangerLevel.swift Sources/PetHUDCore/HUDPresentationData.swift Tests/PetHUDCoreTests/QuotaDangerLevelTests.swift Tests/PetHUDCoreTests/HUDPresentationDataTests.swift
git commit -m "feat: derive MP meter presentation"
```

---

### Task 4: Render HP, MP, and SP in the Tactical HUD

**Files:**
- Create: `Sources/CodexPetHUD/QuotaMeterFillView.swift`
- Modify: `Sources/CodexPetHUD/TacticalHUDView.swift`
- Modify: `Sources/PetHUDCore/PanelGeometry.swift`
- Modify: `Sources/PetHUDCore/TacticalHUDLayoutMetrics.swift`
- Modify: `Tests/PetHUDCoreTests/PanelGeometryTests.swift`
- Modify: `Tests/PetHUDCoreTests/TacticalHUDLayoutMetricsTests.swift`
- Modify: `Tests/Shell/tactical-ui.bats`

**Interfaces:**
- Consumes: `HUDPresentationData`, `QuotaDangerLevel`, `MPPresentationMode`, `podScale`, and Reduce Motion.
- Produces: a four-row HP/MP/SP/status panel, `QuotaMeterFillView`, a `75 * scale` panel height, slow `0.9s` and critical `0.45s` pulses, and static danger colors under Reduce Motion.

- [ ] **Step 1: Write failing geometry and layout tests**

Change standard and compact sizes to:

```swift
CGSize(width: 210, height: 75)
CGSize(width: 136.5, height: 48.75)
```

Assert:

```swift
XCTLessThanOrEqual(metrics.contentHeight, 75)
XCTLessThanOrEqual(compact.contentHeight, 48.75)
XCTEqual(frame.height, 75, accuracy: 0.001)
```

Update every panel-height expectation that currently assumes `58 * scale` to `75 * scale`.

- [ ] **Step 2: Add failing source guards for MP and motion**

Extend `Tests/Shell/tactical-ui.bats` with:

```bash
grep -F 'label: "MP"' "$HUD_VIEW"
grep -F 'data.mpText' "$HUD_VIEW"
grep -F 'data.mpFraction' "$HUD_VIEW"
grep -F 'data.mpDangerLevel' "$HUD_VIEW"
grep -F 'data.mpMode == .unlimited' "$HUD_VIEW"
grep -F 'accessibilityReduceMotion' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
grep -F 'duration: 0.9' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
grep -F 'duration: 0.45' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
```

Keep the existing pet-effect rejection checks unchanged.

- [ ] **Step 3: Run layout tests to verify RED**

Run:

```bash
swift test --disable-sandbox --filter PanelGeometryTests
swift test --disable-sandbox --filter TacticalHUDLayoutMetricsTests
bash Tests/Shell/tactical-ui.bats
```

Expected: geometry assertions fail at the old 58-point height and source guards fail because MP and `QuotaMeterFillView` do not exist.

- [ ] **Step 4: Increase panel and metric height**

In `PanelGeometry.tacticalHUDFrame`, set:

```swift
let height = 75 * scale
```

In `TacticalHUDLayoutMetrics`, calculate fit with:

```swift
frameSize.height / 75
```

Calculate content height with two meter rows and three row gaps:

```swift
public var contentHeight: CGFloat {
    verticalPadding * 2 +
        hpRowHeight * 2 +
        flameHeight +
        statusRowHeight +
        rowSpacing * 3
}
```

- [ ] **Step 5: Create the reusable animated fill**

Create `QuotaMeterFillView`:

```swift
import PetHUDCore
import SwiftUI

struct QuotaMeterFillView: View {
    let fraction: Double
    let baseColor: Color
    let dangerColor: Color
    let dangerLevel: QuotaDangerLevel
    let centeredText: String?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var showsDangerColor = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.72))
                Capsule()
                    .fill(displayColor)
                    .frame(
                        width:
                            geometry.size.width *
                            min(1, max(0, fraction))
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                if let centeredText {
                    Text(centeredText)
                        .font(
                            .system(
                                size: 8,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(Color.white)
                }
            }
        }
        .onAppear {
            restartPulse()
        }
        .onChange(of: dangerLevel) {
            restartPulse()
        }
        .onChange(of: reduceMotion) {
            restartPulse()
        }
        .animation(
            dangerAnimation,
            value: showsDangerColor
        )
    }

    private var displayColor: Color {
        guard dangerLevel != .none else {
            return baseColor
        }
        if reduceMotion {
            return dangerColor
        }
        return showsDangerColor ? dangerColor : baseColor
    }

    private var dangerAnimation: Animation? {
        guard !reduceMotion else {
            return nil
        }
        switch dangerLevel {
        case .none:
            return nil
        case .low:
            return .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
        case .critical:
            return .easeInOut(duration: 0.45)
                .repeatForever(autoreverses: true)
        }
    }

    private func restartPulse() {
        showsDangerColor = false
        guard dangerLevel != .none else {
            return
        }
        if reduceMotion {
            showsDangerColor = true
            return
        }
        withAnimation(dangerAnimation) {
            showsDangerColor = true
        }
    }
}
```

The black capsule is the track, fill width is clamped to `0...1`, and optional
text is centered inside the bar.

- [ ] **Step 6: Add the MP row**

Render HP with:

```swift
QuotaMeterFillView(
    fraction: data.hpFraction,
    baseColor: hpBaseColor,
    dangerColor: .red,
    dangerLevel: data.hpDangerLevel,
    centeredText: nil
)
```

For `.low` and `.critical`, `hpBaseColor` must return the cyan-green value
`Color(red: 0.26, green: 0.93, blue: 0.60)` so the pulse visibly alternates
between cyan-green and red. Keep the existing healthy, normal, and warning
colors for non-danger states.

Insert MP directly below HP:

```swift
meterRow(
    label: "MP",
    trailing:
        data.mpMode == .unlimited ? "" : data.mpText,
    rowHeight: metrics.hpRowHeight,
    accessibilityValue: mpAccessibilityValue
) {
    QuotaMeterFillView(
        fraction: data.mpFraction,
        baseColor: Color(
            red: 1,
            green: 0.52,
            blue: 0.12
        ),
        dangerColor: Color(
            red: 0.78,
            green: 0.93,
            blue: 1
        ),
        dangerLevel: data.mpDangerLevel,
        centeredText:
            data.mpMode == .unlimited ? "MAX" : nil
    )
}
```

Return accessibility values:

```swift
private var mpAccessibilityValue: String {
    switch data.mpMode {
    case .measured:
        return data.mpText
    case .unlimited:
        return "Maximum; no five-hour limit"
    case .unavailable:
        return "Unavailable"
    }
}
```

Keep SP unchanged and do not add any five-hour reset text.

- [ ] **Step 7: Run UI and layout tests to verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter PanelGeometryTests
swift test --disable-sandbox --filter TacticalHUDLayoutMetricsTests
swift test --disable-sandbox --filter HUDPresentationDataTests
bash Tests/Shell/tactical-ui.bats
```

Expected: all selected tests pass and the source guard finds MP, Reduce Motion, both pulse durations, and no pet-effect behavior.

- [ ] **Step 8: Commit the four-row HUD**

Run:

```bash
git add Sources/CodexPetHUD/QuotaMeterFillView.swift Sources/CodexPetHUD/TacticalHUDView.swift Sources/PetHUDCore/PanelGeometry.swift Sources/PetHUDCore/TacticalHUDLayoutMetrics.swift Tests/PetHUDCoreTests/PanelGeometryTests.swift Tests/PetHUDCoreTests/TacticalHUDLayoutMetricsTests.swift Tests/Shell/tactical-ui.bats
git commit -m "feat: add animated MP meter"
```

---

### Task 5: Add Redacted Diagnostics, Private Capture, and Release Documentation

**Files:**
- Modify: `Sources/CodexPetHUD/Diagnostics.swift`
- Modify: `scripts/capture-hud.sh`
- Modify: `Tests/Shell/tactical-ui.bats`
- Modify: `Tests/Shell/release-validation.bats`
- Modify: `Tests/Shell/skill-validation.bats`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/architecture.md`
- Modify: `skills/codex-pet-hud/SKILL.md`
- Modify: `Resources/Info.plist`

**Interfaces:**
- Consumes: normalized `QuotaSnapshot`, the single titled HUD window, and current release metadata.
- Produces: `fiveHourRemainingPercent`, `fiveHourStatus`, HUD-window-only screenshots, MP documentation, and version `0.4.0` build `4`.

- [ ] **Step 1: Add failing release guards**

Extend shell tests to require:

```bash
grep -F 'fiveHourRemainingPercent' \
  "$ROOT/Sources/CodexPetHUD/Diagnostics.swift"
grep -F 'fiveHourStatus' \
  "$ROOT/Sources/CodexPetHUD/Diagnostics.swift"
grep -F 'screencapture -x -o -l' \
  "$ROOT/scripts/capture-hud.sh"
grep -F '<string>0.4.0</string>' "$ROOT/Resources/Info.plist"
grep -F '<string>4</string>' "$ROOT/Resources/Info.plist"
grep -F 'MP' "$ROOT/README.md"
grep -F '0.4.0' "$ROOT/CHANGELOG.md"
grep -F 'five-hour' "$ROOT/docs/architecture.md"
```

Retain the privacy scan that rejects credential names and raw response logging.

- [ ] **Step 2: Run shell tests to verify RED**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: at least one guard fails because diagnostics, capture behavior, documentation, and version metadata are not updated.

- [ ] **Step 3: Extend redacted diagnostics**

Add report fields:

```swift
let fiveHourRemainingPercent: Int?
let fiveHourStatus: String
```

Initialize status as `"unavailable"` or `"skipped"`. After a successful fetch:

```swift
if let fiveHour = snapshot.fiveHour {
    fiveHourRemaining = Int(
        fiveHour.remainingPercent.rounded()
    )
    fiveHourStatus = "measured"
} else {
    fiveHourRemaining = nil
    fiveHourStatus = "max"
}
```

Do not add reset time, raw payload, token, account, or email fields.

- [ ] **Step 4: Make screenshots window-only**

Update `capture-hud.sh` to resolve exactly one on-screen window ID named `Codex Pet HUD Tactical`, continue rejecting any pet-effect window, and run:

```bash
screencapture -x -o -l "$WINDOW_ID" "$OUTPUT"
```

Do not capture a screen rectangle. This ensures translucent HUD screenshots cannot reveal underlying desktop content.

- [ ] **Step 5: Update product and skill documentation**

Document:

- HP as the weekly percentage.
- MP as measured five-hour percentage or orange `MAX`.
- SP as weekly reset progress only.
- independent `4–9%` and `0–3%` meter pulses.
- fixed danger colors under Reduce Motion.
- no pet animation or replacement.
- diagnostic `fiveHourStatus` values.
- window-only screenshot privacy.

Update architecture data flow from “numeric HP and seven-flame SP data” to “HP, optional MP, and seven-flame SP data”.

Add a `0.4.0` changelog entry covering optional five-hour monitoring, `MAX`,
independent HUD pulses, Reduce Motion, private HUD-window capture, and the
absence of pet effects.

- [ ] **Step 6: Bump release metadata**

Set:

```xml
<key>CFBundleShortVersionString</key>
<string>0.4.0</string>
<key>CFBundleVersion</key>
<string>4</string>
```

Update README status to `Version 0.4.0`.

- [ ] **Step 7: Run shell tests to verify GREEN**

Run:

```bash
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
```

Expected: every shell test exits `0`, privacy guards find no secret output path, and capture guards require a single HUD window ID.

- [ ] **Step 8: Commit diagnostics and release docs**

Run:

```bash
git add Sources/CodexPetHUD/Diagnostics.swift scripts/capture-hud.sh Tests/Shell/tactical-ui.bats Tests/Shell/release-validation.bats Tests/Shell/skill-validation.bats README.md CHANGELOG.md docs/architecture.md skills/codex-pet-hud/SKILL.md Resources/Info.plist
git commit -m "docs: prepare MP meter release"
```

---

### Task 6: Audit, Install, and Visually Verify the macOS Release

**Files:**
- Update if review requires: files changed in Tasks 1–5
- Generate: `docs/screenshots/tactical-hud.png`

**Interfaces:**
- Consumes: the complete feature branch, local `一茬` pet, signed app build, LaunchAgent, and HUD-only capture tool.
- Produces: zero-failure automated verification, reviewer approval, installed version `0.4.0`, measured and `MAX` visual evidence, and a final screenshot containing no desktop content.

- [ ] **Step 1: Run full automated verification**

Run:

```bash
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
scripts/build-app.sh
codesign --verify --deep --strict "dist/Codex Pet HUD.app"
```

Expected: all Swift tests and shell tests pass, the production app builds, and code-sign verification exits `0`.

- [ ] **Step 2: Request an independent code review**

Use `requesting-code-review` with:

```text
DESCRIPTION: Optional five-hour MP quota normalization, MAX fallback, independent HP/MP danger pulses, four-row HUD layout, redacted diagnostics, private HUD-only capture, and existing HUD visibility stability fixes.
PLAN_OR_REQUIREMENTS: docs/superpowers/specs/2026-07-30-five-hour-mp-meter-design.md and docs/superpowers/plans/2026-07-30-five-hour-mp-meter.md
BASE_SHA: 2f1983039027d180163e92f2939b56637105b5b5
HEAD_SHA: output of git rev-parse HEAD after Tasks 1–5
```

Expected: reviewer reports no Critical or Important issues. Fix every valid Critical or Important issue with a failing regression test, rerun the affected suite, and commit with `fix: address MP meter review`.

- [ ] **Step 3: Install the signed app**

Run:

```bash
scripts/install.sh --pet-path "$HOME/.codex/pets/yicha"
sleep 3
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" --diagnose
```

Expected current live output:

```json
{
  "configuration": "ok",
  "pet": "found",
  "petWindow": "found",
  "provider": "reachable",
  "fiveHourStatus": "max"
}
```

`fiveHourRemainingPercent` is omitted in `max` mode. The weekly percentage and
reset time may vary and are not hard-coded.

- [ ] **Step 4: Verify the current unlimited-MP HUD**

Run:

```bash
scripts/capture-hud.sh "$TMPDIR/codex-pet-hud-max.png"
```

Inspect the image and confirm:

- HP shows the current weekly percentage.
- MP is a full orange bar with centered `MAX`.
- SP retains seven flame cells and weekly reset text.
- the panel follows the pet and remains above the ChatGPT composition layer.
- no desktop text, app window, or work content appears behind the HUD.

- [ ] **Step 5: Verify measured and danger states with mock fixtures**

Launch a single mock HUD using `Fixtures/wham-usage-five-hour.json`, capture only its HUD window, and confirm MP shows `63.5%` with an orange fill.

Create temporary mock payloads under `$TMPDIR` for:

```json
{
  "rate_limit": {
    "primary_window": {
      "used_percent": 92,
      "reset_at": 1785402000,
      "limit_window_seconds": 18000
    },
    "secondary_window": {
      "used_percent": 8,
      "reset_at": 1785904104,
      "limit_window_seconds": 604800
    }
  }
}
```

and:

```json
{
  "rate_limit": {
    "primary_window": {
      "used_percent": 98,
      "reset_at": 1785402000,
      "limit_window_seconds": 18000
    },
    "secondary_window": {
      "used_percent": 98,
      "reset_at": 1785904104,
      "limit_window_seconds": 604800
    }
  }
}
```

Confirm:

- at `8%`, HP pulses green/red and MP pulses orange/icy blue-white slowly;
- at `2%`, both pulses are faster and higher contrast;
- no second pet image, effect window, or native pet movement appears;
- Reduce Motion freezes HP at red and MP at icy blue-white.

- [ ] **Step 6: Publish the private HUD screenshot**

Capture the installed `MAX` state directly from the HUD window:

```bash
scripts/capture-hud.sh docs/screenshots/tactical-hud.png
sips -g pixelWidth -g pixelHeight docs/screenshots/tactical-hud.png
git add docs/screenshots/tactical-hud.png
git commit -m "docs: update tactical HUD screenshot"
```

Expected: the image dimensions match the HUD window only and the screenshot contains no desktop background.

- [ ] **Step 7: Run final verification after visual assets**

Run:

```bash
git diff --check
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
scripts/build-app.sh
codesign --verify --deep --strict "dist/Codex Pet HUD.app"
git status --short
```

Expected: all tests pass, build and signature pass, and `git status --short` is empty.

---

### Task 7: Publish the Reviewed Branch to GitHub

**Files:**
- No source changes expected.
- Update existing GitHub draft pull request `#1`.

**Interfaces:**
- Consumes: clean branch `feature/tactical-dual-bar-hud`, verified commits, origin `https://github.com/PhDhang/codex-pet-hud.git`, and draft PR `#1`.
- Produces: pushed branch and updated draft PR describing MP behavior, privacy boundaries, tests, and macOS verification.

- [ ] **Step 1: Read the GitHub publishing skill**

Invoke `github:yeet` and follow its scope-confirmation, commit, push, and draft-PR requirements. Do not force-push and do not merge the pull request.

- [ ] **Step 2: Confirm the outgoing commit range**

Run:

```bash
git status --short
git log --oneline origin/feature/tactical-dual-bar-hud..HEAD
git diff --stat origin/feature/tactical-dual-bar-hud...HEAD
```

Expected: clean working tree and only the HUD stability, MP feature, diagnostics, tests, documentation, and screenshot commits.

- [ ] **Step 3: Push the feature branch**

Run:

```bash
git push -u origin feature/tactical-dual-bar-hud
```

Expected: push succeeds without force and the local branch tracks the remote feature branch.

- [ ] **Step 4: Update draft pull request `#1`**

Set the title to:

```text
feat: add tactical HP, MP, and SP quota HUD
```

Update the body with:

```markdown
## Summary

- add optional five-hour MP monitoring with an orange MAX fallback
- add independent HP and MP low/critical HUD pulses with Reduce Motion support
- preserve weekly SP flames, native pet rendering, resize tracking, and idle visibility
- keep diagnostics redacted and screenshots restricted to the HUD window

## Verification

- Swift package test suite passes
- every Tests/Shell script passes
- signed macOS 14 release build verifies
- live diagnosis finds configuration, pet, pet window, and provider
- MAX, measured, low, critical, resize, movement, idle, and Reduce Motion states visually checked
```

Keep the pull request in draft state.

- [ ] **Step 5: Verify the published state**

Use the connected GitHub app to confirm:

- PR `#1` is open and draft.
- head branch is `feature/tactical-dual-bar-hud`.
- the latest local HEAD SHA matches the remote head SHA.
- the title and body contain HP, MP, SP, MAX, Reduce Motion, and privacy verification.

Expected: the repository and draft pull request expose the complete reviewed release without merging it.
