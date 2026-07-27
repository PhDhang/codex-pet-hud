# Tactical Dual-Bar HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ring life pod with an idle-persistent tactical HP/SP HUD, add panic and critical pet effects, and package the macOS app plus reusable Skill as v0.3.0-rc.1.

**Architecture:** Separate exact pet geometry from stable pet presence, retain and persist the last safe geometry, and feed it into two click-through AppKit panels: a tactical HUD and a pet-effect overlay. Keep state, geometry, asset validation, and cache behavior in `PetHUDCore`; keep SwiftUI rendering and AppKit lifecycle integration in `CodexPetHUD`.

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, CoreGraphics, ImageIO, XCTest, Bash test scripts, macOS 14.

## Global Constraints

- Target macOS 14 and Codex v2 `8×11` pet atlases only.
- Do not request Accessibility or Screen Recording permissions.
- Keep all panels non-activating, mouse-transparent, and visible across Spaces.
- Keep `podScale`, `podOffsetX`, and `podOffsetY` configuration compatibility.
- HP bands are `>90`, `51–90`, `10–50`, `4–9`, and `≤3` percent remaining.
- Panic motion is a `2.4s` left/right shuttle with at most `min(petWidth × 0.18, 28pt)` travel per side and `4pt` vertical bounce.
- Critical state enters at `≤3%` and exits only above `5%`.
- Stale or missing quota data never drives panic or critical effects.
- SP always uses seven rounded three-layer flames: red/orange/yellow when lit and blue/cyan/ice-blue when unlit.
- Per-pet effect paths must remain inside the selected pet directory.
- Missing or invalid effect assets must degrade safely without hiding the HUD.
- Preserve credentials locally and never log tokens, account IDs, emails, cookies, raw provider responses, or unrelated window contents.

## Planned File Map

### Core State and Data

- Create `Sources/PetHUDCore/PetDistressState.swift` for panic/critical transition rules.
- Modify `Sources/PetHUDCore/ApplicationModel.swift` to expose one `PetDistressState`.
- Modify `Sources/PetHUDCore/HUDPresentationData.swift` for tactical labels and stale behavior.
- Modify `Sources/PetHUDCore/ResetProgress.swift` for exact seven-flame day progression.

### Presence and Geometry

- Modify `Sources/PetHUDCore/PetWindowLocator.swift` to emit exact geometry plus stable presence.
- Replace `Sources/PetHUDCore/PetWindowTracker.swift` with `Sources/PetHUDCore/PetPresenceTracker.swift`.
- Create `Sources/PetHUDCore/PetGeometryCache.swift` for atomic last-known geometry persistence.
- Modify `Sources/PetHUDCore/PanelGeometry.swift` for tactical HUD and expanded effect frames.

### Pet Assets

- Create `Sources/PetHUDCore/PetEffectManifest.swift` for optional per-pet metadata.
- Modify `Sources/PetHUDCore/PetAtlas.swift` for arbitrary rows, cells, and horizontal strips.
- Create `Sources/CodexPetHUD/PetEffectAssets.swift` to assemble custom and fallback render assets.

### Rendering

- Create `Sources/CodexPetHUD/TacticalHUDView.swift`, then remove the ring view during coordinator integration.
- Create `Sources/CodexPetHUD/FlameCellView.swift` for the approved nested flame.
- Create `Sources/CodexPetHUD/TacticalHUDPanelController.swift`, then remove the ring controller during coordinator integration.
- Create `Sources/CodexPetHUD/PetEffectView.swift`, then remove the old critical view during coordinator integration.
- Create `Sources/CodexPetHUD/PetEffectPanelController.swift`, then remove the old critical controller during coordinator integration.
- Modify `Sources/CodexPetHUD/PetHUDApplication.swift` and `Sources/CodexPetHUD/Diagnostics.swift` for integration.

### Packaging

- Add `Examples/yicha/hud-critical.png` and `Examples/yicha/hud-effects.json`.
- Update `README.md`, `CHANGELOG.md`, `docs/architecture.md`, `docs/privacy.md`, `Resources/Info.plist`, and screenshots.
- Update `skills/codex-pet-hud/` workflow and troubleshooting guidance.
- Update shell validation for v0.3.0-rc.1 and the committed design/plan documents.

---

### Task 1: Distress State and Seven-Flame Semantics

**Files:**
- Create: `Sources/PetHUDCore/PetDistressState.swift`
- Modify: `Sources/PetHUDCore/HUDState.swift`
- Modify: `Sources/PetHUDCore/ApplicationModel.swift`
- Modify: `Sources/PetHUDCore/HUDPresentationData.swift`
- Modify: `Sources/PetHUDCore/ResetProgress.swift`
- Test: `Tests/PetHUDCoreTests/ApplicationModelTests.swift`
- Test: `Tests/PetHUDCoreTests/HUDStateTests.swift`
- Test: `Tests/PetHUDCoreTests/HUDPresentationDataTests.swift`
- Test: `Tests/PetHUDCoreTests/ResetProgressTests.swift`

**Interfaces:**
- Produces: `PetDistressState.evaluate(hudState:previous:) -> PetDistressState`
- Produces: `PanelPresentation.showHUD: Bool`
- Produces: `PanelPresentation.distressState: PetDistressState`
- Preserves: `HUDPresentationData.spCellsLit: Int`

- [ ] **Step 1: Write failing distress-transition tests**

Replace the threshold test in `Tests/PetHUDCoreTests/HUDStateTests.swift` with:

```swift
func testThresholdsUseApprovedInclusiveBoundaries() {
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 91),
        .healthy
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 90),
        .normal
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 51),
        .normal
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 50),
        .warning
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 10),
        .warning
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 9),
        .low
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 4),
        .low
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 3),
        .critical
    )
    XCTAssertEqual(
        HUDState.band(forRemainingPercent: 0),
        .critical
    )
}
```

Add these cases to `Tests/PetHUDCoreTests/ApplicationModelTests.swift`:

```swift
func testLowQuotaShowsPanicEffect() {
    var model = ApplicationModel()
    _ = model.reduce(.petWindowChanged(petWindow))

    let presentation = model.reduce(
        .quotaLoaded(snapshot(remaining: 8))
    )

    XCTAssertTrue(presentation.showHUD)
    XCTAssertEqual(presentation.distressState, .panic)
}

func testCriticalStateUsesFivePercentRecoveryHysteresis() {
    var model = ApplicationModel()
    _ = model.reduce(.petWindowChanged(petWindow))
    _ = model.reduce(.quotaLoaded(snapshot(remaining: 2)))

    XCTAssertEqual(
        model.reduce(.quotaLoaded(snapshot(remaining: 5)))
            .distressState,
        .critical
    )
    XCTAssertEqual(
        model.reduce(.quotaLoaded(snapshot(remaining: 6)))
            .distressState,
        .panic
    )
}

func testStaleQuotaClearsDistressEffectButKeepsHUD() {
    let now = Date(timeIntervalSince1970: 20_000)
    var model = ApplicationModel(now: now)
    _ = model.reduce(.petWindowChanged(petWindow))
    _ = model.reduce(
        .quotaLoaded(
            QuotaSnapshot(
                weekly: QuotaWindow(
                    usedPercent: 98,
                    resetAt:
                        now.addingTimeInterval(172_800),
                    windowDurationSeconds: 604_800
                ),
                fetchedAt: now
            )
        )
    )

    let presentation = model.reduce(
        .clockTick(now.addingTimeInterval(301))
    )

    XCTAssertTrue(presentation.showHUD)
    XCTAssertEqual(presentation.distressState, .normal)
    guard case .stale = presentation.hudState else {
        return XCTFail("Expected stale HUD state")
    }
}
```

- [ ] **Step 2: Write failing seven-flame boundary tests**

Replace fraction-only expectations in `Tests/PetHUDCoreTests/ResetProgressTests.swift` with:

```swift
func testSevenDayResetUsesElapsedWholeDays() {
    let day: TimeInterval = 86_400
    XCTAssertEqual(
        ResetProgress.cellsLit(
            secondsRemaining: 7 * day,
            windowDuration: 7 * day
        ),
        0
    )
    XCTAssertEqual(
        ResetProgress.cellsLit(
            secondsRemaining: 5 * day,
            windowDuration: 7 * day
        ),
        2
    )
    XCTAssertEqual(
        ResetProgress.cellsLit(
            secondsRemaining: 2 * day,
            windowDuration: 7 * day
        ),
        5
    )
    XCTAssertEqual(
        ResetProgress.cellsLit(
            secondsRemaining: 0,
            windowDuration: 7 * day
        ),
        7
    )
}
```

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.HUDStateTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.ApplicationModelTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.ResetProgressTests
```

Expected: compilation fails because `showHUD`, `distressState`, and `PetDistressState` do not exist; reset-count expectations fail under the fractional formula.

- [ ] **Step 4: Implement the distress evaluator and presentation contract**

Update `HUDState.band`:

```swift
switch value {
case ...3:
    return .critical
case ..<10:
    return .low
case ...50:
    return .warning
case ...90:
    return .normal
default:
    return .healthy
}
```

Create `Sources/PetHUDCore/PetDistressState.swift`:

```swift
import Foundation

public enum PetDistressState:
    String,
    Codable,
    Equatable,
    Sendable
{
    case normal
    case panic
    case critical

    public static func evaluate(
        hudState: HUDState,
        previous: PetDistressState
    ) -> PetDistressState {
        guard case let .quota(snapshot, _) = hudState else {
            return .normal
        }
        let remaining = snapshot.weekly.remainingPercent
        if remaining <= 3 {
            return .critical
        }
        if previous == .critical, remaining <= 5 {
            return .critical
        }
        if remaining < 10 {
            return .panic
        }
        return .normal
    }
}
```

Change `PanelPresentation` in `Sources/PetHUDCore/ApplicationModel.swift` to:

```swift
public struct PanelPresentation: Equatable, Sendable {
    public let showHUD: Bool
    public let distressState: PetDistressState
    public let hudState: HUDState
    public let petWindow: WindowDescriptor?
}
```

Store `private var distressState = PetDistressState.normal` in `ApplicationModel`, update it after each event with:

```swift
distressState = PetDistressState.evaluate(
    hudState: hudState,
    previous: distressState
)
```

Return:

```swift
return PanelPresentation(
    showHUD: petWindow != nil,
    distressState: distressState,
    hudState: hudState,
    petWindow: petWindow
)
```

- [ ] **Step 5: Implement exact SP day progression and tactical labels**

Replace `ResetProgress.cellsLit` with:

```swift
public static func cellsLit(
    secondsRemaining: TimeInterval,
    windowDuration: TimeInterval
) -> Int {
    guard windowDuration > 0 else {
        return 0
    }
    let secondsPerCell = windowDuration / 7
    let clampedRemaining = min(
        windowDuration,
        max(0, secondsRemaining)
    )
    let remainingCells = Int(
        ceil(clampedRemaining / secondsPerCell)
    )
    return min(7, max(0, 7 - remainingCells))
}
```

Update `HUDPresentationData.make` status labels:

```swift
let statusLabel: String
switch band {
case .critical:
    statusLabel = "EXHAUSTED · SIGNAL CRITICAL"
case .low:
    statusLabel = "PANIC · QUOTA LOW"
default:
    statusLabel = "CODEX · WEEKLY"
}
```

Keep stale numeric values and their band color, but do not derive distress state from `.stale`.

- [ ] **Step 6: Run focused and full core tests**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.HUDStateTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.ApplicationModelTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.HUDPresentationDataTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.ResetProgressTests
swift test --disable-sandbox
```

Expected: all tests pass.

- [ ] **Step 7: Commit the state-machine slice**

```bash
git add \
  Sources/PetHUDCore/PetDistressState.swift \
  Sources/PetHUDCore/HUDState.swift \
  Sources/PetHUDCore/ApplicationModel.swift \
  Sources/PetHUDCore/HUDPresentationData.swift \
  Sources/PetHUDCore/ResetProgress.swift \
  Tests/PetHUDCoreTests/ApplicationModelTests.swift \
  Tests/PetHUDCoreTests/HUDStateTests.swift \
  Tests/PetHUDCoreTests/HUDPresentationDataTests.swift \
  Tests/PetHUDCoreTests/ResetProgressTests.swift
git commit -m "feat: add pet distress state machine"
```

---

### Task 2: Stable Pet Presence Tracking

**Files:**
- Modify: `Sources/PetHUDCore/PetWindowLocator.swift`
- Delete: `Sources/PetHUDCore/PetWindowTracker.swift`
- Create: `Sources/PetHUDCore/PetPresenceTracker.swift`
- Modify: `Tests/PetHUDCoreTests/PetWindowLocatorTests.swift`
- Delete: `Tests/PetHUDCoreTests/PetWindowTrackerTests.swift`
- Create: `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`

**Interfaces:**
- Produces: `PetWindowObservation(exactWindow:hasStablePresence:)`
- Produces: `PetWindowLocator.currentObservation() -> PetWindowObservation`
- Produces: `PetPresenceTracker.update(observation:now:) -> WindowDescriptor?`
- Consumes later: an optional restored `WindowDescriptor` supplied by the geometry cache.

- [ ] **Step 1: Write failing locator observation tests**

Add:

```swift
func testIdleShellReportsPresenceWithoutExactGeometry() {
    let observation = PetWindowLocator.observe(
        from: [
            descriptor(
                name: "Codex Pet Composition Surface",
                layer: 3,
                width: 768,
                height: 912,
                id: 80
            ),
            descriptor(
                name: "Codex Pet Voice Controls Backing",
                layer: 3,
                width: 24,
                height: 24,
                id: 81
            ),
        ]
    )

    XCTAssertNil(observation.exactWindow)
    XCTAssertTrue(observation.hasStablePresence)
}

func testUnrelatedChatGPTWindowDoesNotReportPetPresence() {
    let observation = PetWindowLocator.observe(
        from: [
            descriptor(
                name: "ChatGPT",
                layer: 0,
                width: 1200,
                height: 800,
                id: 82
            ),
        ]
    )

    XCTAssertNil(observation.exactWindow)
    XCTAssertFalse(observation.hasStablePresence)
}

func testTitleRedactedIdleShellNeedsCompanionCluster() {
    let observation = PetWindowLocator.observe(
        from: [
            descriptor(
                name: "",
                layer: 3,
                width: 768,
                height: 912,
                id: 83
            ),
            descriptor(
                name: "",
                layer: 3,
                width: 24,
                height: 24,
                id: 84
            ),
            descriptor(
                name: "",
                layer: 3,
                width: 345,
                height: 54,
                id: 85
            ),
        ]
    )

    XCTAssertNil(observation.exactWindow)
    XCTAssertTrue(observation.hasStablePresence)
}
```

Use one local `descriptor(name:layer:width:height:id:)` helper so all test windows use the same owner and PID.

- [ ] **Step 2: Write failing tracker sequence tests**

Create `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift` with:

```swift
func testRetainsGeometryWhileIdleShellRemainsPresent() {
    var tracker = PetPresenceTracker()
    let start = Date(timeIntervalSince1970: 100)
    let exact = exactWindow(id: 10)

    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: exact,
                hasStablePresence: true
            ),
            now: start
        ),
        exact
    )
    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: nil,
                hasStablePresence: true
            ),
            now: start.addingTimeInterval(60)
        ),
        exact
    )
}

func testRequiresThreeMissingObservationsAcrossTwoSeconds() {
    var tracker = PetPresenceTracker()
    let start = Date(timeIntervalSince1970: 100)
    let exact = exactWindow(id: 10)
    _ = tracker.update(
        observation: .init(
            exactWindow: exact,
            hasStablePresence: true
        ),
        now: start
    )

    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: nil,
                hasStablePresence: false
            ),
            now: start.addingTimeInterval(0.5)
        ),
        exact
    )
    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: nil,
                hasStablePresence: false
            ),
            now: start.addingTimeInterval(1.5)
        ),
        exact
    )
    XCTAssertNil(
        tracker.update(
            observation: .init(
                exactWindow: nil,
                hasStablePresence: false
            ),
            now: start.addingTimeInterval(2.5)
        )
    )
}
```

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetWindowLocatorTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetPresenceTrackerTests
```

Expected: compilation fails because observation and presence-tracker APIs do not exist.

- [ ] **Step 4: Implement window observations**

Add to `Sources/PetHUDCore/PetWindowLocator.swift`:

```swift
public struct PetWindowObservation: Equatable, Sendable {
    public let exactWindow: WindowDescriptor?
    public let hasStablePresence: Bool

    public init(
        exactWindow: WindowDescriptor?,
        hasStablePresence: Bool
    ) {
        self.exactWindow = exactWindow
        self.hasStablePresence = hasStablePresence
    }
}
```

Expose:

```swift
public static func currentObservation()
    -> PetWindowObservation

public static func observe(
    from windows: [WindowDescriptor]
) -> PetWindowObservation
```

Keep the existing exact and conservative title-redacted mascot selection. Set stable presence when at least one ChatGPT-owned window has one of these names:

```swift
private static let stableWindowNames: Set<String> = [
    "Codex Pet Composition Surface",
    "Codex Pet Voice Controls Backing",
    "Codex Pet Activity Stack Backing",
]
```

An exact mascot match also implies stable presence. Multiple stable shell windows are allowed; ambiguous exact mascot candidates still produce `exactWindow == nil`.

For title-redacted LaunchAgent windows, report stable presence only when one
ChatGPT PID contains all three conservative layer-3 signatures:

```swift
let hasVoiceControl =
    (20...32).contains(window.bounds.width) &&
    (20...32).contains(window.bounds.height)
let hasCompositionSurface =
    (480...1_200).contains(window.bounds.width) &&
    (480...1_400).contains(window.bounds.height)
let hasActivityStack =
    (180...500).contains(window.bounds.width) &&
    (30...90).contains(window.bounds.height)
```

Require empty titles, layer `3`, the same owner PID, and all three signatures.
Reject partial or cross-PID clusters.

- [ ] **Step 5: Implement the presence tracker**

Create `Sources/PetHUDCore/PetPresenceTracker.swift`:

```swift
import Foundation

public struct PetPresenceTracker: Sendable {
    private let requiredAbsentObservations: Int
    private let requiredAbsentDuration: TimeInterval
    private var lastGeometry: WindowDescriptor?
    private var absenceStartedAt: Date?
    private var absentObservationCount = 0

    public init(
        restoredWindow: WindowDescriptor? = nil,
        requiredAbsentObservations: Int = 3,
        requiredAbsentDuration: TimeInterval = 2
    ) {
        lastGeometry = restoredWindow
        self.requiredAbsentObservations =
            requiredAbsentObservations
        self.requiredAbsentDuration =
            requiredAbsentDuration
    }

    public mutating func update(
        observation: PetWindowObservation,
        now: Date
    ) -> WindowDescriptor? {
        if let exact = observation.exactWindow {
            lastGeometry = exact
        }
        if observation.hasStablePresence {
            absenceStartedAt = nil
            absentObservationCount = 0
            return lastGeometry
        }

        if absenceStartedAt == nil {
            absenceStartedAt = now
        }
        absentObservationCount += 1
        let duration = now.timeIntervalSince(
            absenceStartedAt ?? now
        )
        if absentObservationCount >=
            requiredAbsentObservations,
            duration >= requiredAbsentDuration
        {
            absenceStartedAt = nil
            absentObservationCount = 0
            lastGeometry = nil
            return nil
        }
        return lastGeometry
    }
}
```

- [ ] **Step 6: Remove old tracker files and run tests**

Delete:

```text
Sources/PetHUDCore/PetWindowTracker.swift
Tests/PetHUDCoreTests/PetWindowTrackerTests.swift
```

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetWindowLocatorTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetPresenceTrackerTests
swift test --disable-sandbox
```

Expected: all tests pass.

- [ ] **Step 7: Commit stable presence tracking**

```bash
git add \
  Sources/PetHUDCore/PetWindowLocator.swift \
  Sources/PetHUDCore/PetPresenceTracker.swift \
  Tests/PetHUDCoreTests/PetWindowLocatorTests.swift \
  Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift
git add -u \
  Sources/PetHUDCore/PetWindowTracker.swift \
  Tests/PetHUDCoreTests/PetWindowTrackerTests.swift
git commit -m "fix: retain pet geometry while idle"
```

---

### Task 3: Persistent Last-Known Geometry

**Files:**
- Create: `Sources/PetHUDCore/PetGeometryCache.swift`
- Modify: `Sources/PetHUDCore/PetWindowLocator.swift`
- Modify: `Sources/PetHUDCore/PetPresenceTracker.swift`
- Create: `Tests/PetHUDCoreTests/PetGeometryCacheTests.swift`
- Modify: `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`

**Interfaces:**
- Produces: `PetGeometryRecord(window:updatedAt:)`
- Produces: `PetGeometryCache.load() throws -> PetGeometryRecord?`
- Produces: `PetGeometryCache.save(_:) throws`
- Consumes: `PetPresenceTracker(restoredWindow:)`

- [ ] **Step 1: Write failing cache round-trip and cold-start tests**

Create `Tests/PetHUDCoreTests/PetGeometryCacheTests.swift`:

```swift
func testRoundTripsGeometryWithOwnerOnlyPermissions() throws {
    try withTemporaryDirectory { directory in
        let url = directory.appendingPathComponent(
            "pet-geometry.json"
        )
        let cache = PetGeometryCache(url: url)
        let record = PetGeometryRecord(
            window: exactWindow(id: 42),
            updatedAt: Date(timeIntervalSince1970: 123)
        )

        try cache.save(record)

        XCTAssertEqual(try cache.load(), record)
        let attributes =
            try FileManager.default.attributesOfItem(
                atPath: url.path
            )
        let mode = try XCTUnwrap(
            attributes[.posixPermissions] as? NSNumber
        )
        XCTAssertEqual(mode.intValue & 0o777, 0o600)
    }
}
```

Add to `PetPresenceTrackerTests`:

```swift
func testRestoredGeometryAppearsOnlyWithStablePresence() {
    let restored = exactWindow(id: 77)
    var tracker = PetPresenceTracker(
        restoredWindow: restored
    )
    let now = Date(timeIntervalSince1970: 100)

    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: nil,
                hasStablePresence: true
            ),
            now: now
        ),
        restored
    )
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetGeometryCacheTests
```

Expected: compilation fails because cache types do not exist.

- [ ] **Step 3: Make window descriptors codable**

Change the declaration in `PetWindowLocator.swift` to:

```swift
public struct WindowDescriptor:
    Codable,
    Equatable,
    Sendable
{
```

No custom encoder is needed because `CGRect` is Codable on the macOS deployment target.

- [ ] **Step 4: Implement the atomic geometry cache**

Create `Sources/PetHUDCore/PetGeometryCache.swift`:

```swift
import Darwin
import Foundation

public struct PetGeometryRecord:
    Codable,
    Equatable,
    Sendable
{
    public let window: WindowDescriptor
    public let updatedAt: Date

    public init(
        window: WindowDescriptor,
        updatedAt: Date
    ) {
        self.window = window
        self.updatedAt = updatedAt
    }
}

public struct PetGeometryCache: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> PetGeometryRecord? {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }
        return try JSONDecoder().decode(
            PetGeometryRecord.self,
            from: Data(contentsOf: url)
        )
    }

    public func save(_ record: PetGeometryRecord) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(record).write(
            to: url,
            options: .atomic
        )
        guard chmod(url.path, S_IRUSR | S_IWUSR) == 0 else {
            throw CocoaError(.fileWriteNoPermission)
        }
    }
}
```

- [ ] **Step 5: Run cache and tracker tests**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetGeometryCacheTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetPresenceTrackerTests
swift test --disable-sandbox
```

Expected: all tests pass.

- [ ] **Step 6: Commit geometry persistence**

```bash
git add \
  Sources/PetHUDCore/PetGeometryCache.swift \
  Sources/PetHUDCore/PetWindowLocator.swift \
  Sources/PetHUDCore/PetPresenceTracker.swift \
  Tests/PetHUDCoreTests/PetGeometryCacheTests.swift \
  Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift
git commit -m "feat: persist last pet geometry"
```

---

### Task 4: Safe Effect Metadata and Atlas Access

**Files:**
- Create: `Sources/PetHUDCore/PetEffectManifest.swift`
- Modify: `Sources/PetHUDCore/PetAtlas.swift`
- Create: `Tests/PetHUDCoreTests/PetEffectManifestTests.swift`
- Modify: `Tests/PetHUDCoreTests/PetAtlasTests.swift`

**Interfaces:**
- Produces: `PetEffectManifest.load(directory:) throws -> PetEffectManifest?`
- Produces: `PetAtlasRow.runningRight`, `.runningLeft`, and `.failed`
- Produces: `PetAtlas.image(url:) throws -> CGImage`
- Produces: `PetAtlas.rowImages(manifest:row:) throws -> [CGImage]`
- Produces: `PetAtlas.stripImages(url:columns:) throws -> [CGImage]`

- [ ] **Step 1: Write failing safe-path and metadata tests**

Create `Tests/PetHUDCoreTests/PetEffectManifestTests.swift` with:

```swift
func testLoadsCriticalMetadataInsidePetDirectory() throws {
    try withTemporaryDirectory { directory in
        try Data([0x89]).write(
            to: directory.appendingPathComponent(
                "hud-critical.png"
            )
        )
        try """
        {
          "version": 1,
          "panic": {
            "leftEye": [0.42, 0.31],
            "rightEye": [0.58, 0.31],
            "eyeScale": 1.0
          },
          "critical": {
            "image": "hud-critical.png",
            "headAnchor": [0.72, 0.30],
            "scale": 1.0
          }
        }
        """.write(
            to: directory.appendingPathComponent(
                "hud-effects.json"
            ),
            atomically: true,
            encoding: .utf8
        )

        let manifest = try XCTUnwrap(
            PetEffectManifest.load(directory: directory)
        )

        XCTAssertEqual(
            manifest.panic?.leftEye,
            NormalizedPoint(x: 0.42, y: 0.31)
        )
        XCTAssertEqual(
            manifest.critical?.headAnchor,
            NormalizedPoint(x: 0.72, y: 0.30)
        )
    }
}

func testRejectsCriticalPathOutsidePetDirectory() throws {
    try withTemporaryDirectory { directory in
        try """
        {
          "version": 1,
          "critical": {
            "image": "../outside.png",
            "headAnchor": [0.5, 0.3],
            "scale": 1.0
          }
        }
        """.write(
            to: directory.appendingPathComponent(
                "hud-effects.json"
            ),
            atomically: true,
            encoding: .utf8
        )

        XCTAssertThrowsError(
            try PetEffectManifest.load(directory: directory)
        ) {
            XCTAssertEqual(
                $0 as? PetEffectManifestError,
                .unsafeAssetPath
            )
        }
    }
}
```

- [ ] **Step 2: Write failing atlas row tests**

Add to `Tests/PetHUDCoreTests/PetAtlasTests.swift`:

```swift
func testExtractsAllRunningRightFrames() throws {
    try withTemporaryDirectory { directory in
        let manifest = try writeManifestAndAtlas(
            directory: directory
        )

        let frames = try PetAtlas.rowImages(
            manifest: manifest,
            row: .runningRight
        )

        XCTAssertEqual(frames.count, 8)
        XCTAssertEqual(frames[0].width, 192)
        XCTAssertEqual(frames[0].height, 208)
    }
}
```

Reuse the existing atlas-writing helper rather than creating a second image fixture format.

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetEffectManifestTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetAtlasTests
```

Expected: compilation fails because effect metadata and generalized atlas APIs do not exist.

- [ ] **Step 4: Implement clamped metadata**

Create `Sources/PetHUDCore/PetEffectManifest.swift` with these public types:

```swift
public struct NormalizedPoint:
    Codable,
    Equatable,
    Sendable
{
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = min(1, max(0, x))
        self.y = min(1, max(0, y))
    }
}

public struct PanicEffectDescriptor:
    Equatable,
    Sendable
{
    public let spritesheetURL: URL?
    public let columns: Int
    public let framesPerSecond: Double
    public let leftEye: NormalizedPoint
    public let rightEye: NormalizedPoint
    public let eyeScale: Double
}

public struct CriticalEffectDescriptor:
    Equatable,
    Sendable
{
    public let imageURL: URL
    public let headAnchor: NormalizedPoint
    public let scale: Double
}
```

Decode two-number arrays into `NormalizedPoint`, clamp columns to `1...16`, FPS to `1...24`, eye scale to `0.5...2`, and critical scale to `0.5...2`. Return `nil` when `hud-effects.json` is missing. Throw `.invalidManifest`, `.unsupportedVersion`, `.unsafeAssetPath`, or `.missingAsset` for malformed files.

- [ ] **Step 5: Generalize atlas and strip extraction**

Add:

```swift
public enum PetAtlasRow: Int, Sendable {
    case idle = 0
    case runningRight = 1
    case runningLeft = 2
    case failed = 5
}
```

Refactor `PetAtlas` around one private image loader and expose:

```swift
public static func image(
    url: URL
) throws -> CGImage

public static func image(
    manifest: PetManifest,
    row: PetAtlasRow,
    column: Int
) throws -> CGImage

public static func rowImages(
    manifest: PetManifest,
    row: PetAtlasRow
) throws -> [CGImage]

public static func stripImages(
    url: URL,
    columns: Int
) throws -> [CGImage]
```

Validate the v2 atlas as exactly eight columns by eleven rows, reject columns outside `0..<8`, and require horizontal strips to divide evenly by `columns`.

- [ ] **Step 6: Run asset tests and the full suite**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetEffectManifestTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetAtlasTests
swift test --disable-sandbox
```

Expected: all tests pass.

- [ ] **Step 7: Commit safe asset loading**

```bash
git add \
  Sources/PetHUDCore/PetEffectManifest.swift \
  Sources/PetHUDCore/PetAtlas.swift \
  Tests/PetHUDCoreTests/PetEffectManifestTests.swift \
  Tests/PetHUDCoreTests/PetAtlasTests.swift
git commit -m "feat: load per-pet hud effects safely"
```

---

### Task 5: Tactical HUD and Effect Geometry

**Files:**
- Modify: `Sources/PetHUDCore/AppConfiguration.swift`
- Modify: `Sources/PetHUDCore/PanelGeometry.swift`
- Modify: `Tests/PetHUDCoreTests/AppConfigurationTests.swift`
- Modify: `Tests/PetHUDCoreTests/PanelGeometryTests.swift`

**Interfaces:**
- Produces: `PanelGeometry.tacticalHUDFrame(pet:displays:scale:offset:)`
- Produces: `PanelGeometry.petEffectFrame(pet:displays:)`
- Preserves: `podScale`, `podOffsetX`, and `podOffsetY`.

- [ ] **Step 1: Write failing tactical geometry tests**

Replace ring-specific tests in `PanelGeometryTests.swift` with:

```swift
func testTacticalHUDScalesAbovePetCenter() throws {
    let pet = CGRect(x: 24, y: 775, width: 200, height: 250)

    let frame = try XCTUnwrap(
        PanelGeometry.tacticalHUDFrame(
            pet: pet,
            displays: [display],
            scale: 1,
            offset: .zero
        )
    )

    XCTAssertEqual(frame.width, 210, accuracy: 0.001)
    XCTAssertEqual(frame.height, 58, accuracy: 0.001)
    XCTAssertEqual(frame.midX, 124, accuracy: 0.001)
    XCTAssertGreaterThan(frame.minY, 305)
}

func testTacticalHUDPreservesOffsetsAfterResize() throws {
    let small = try XCTUnwrap(
        PanelGeometry.tacticalHUDFrame(
            pet: CGRect(
                x: 24,
                y: 775,
                width: 200,
                height: 250
            ),
            displays: [display],
            scale: 0.8,
            offset: CGPoint(x: 17, y: -12)
        )
    )
    let large = try XCTUnwrap(
        PanelGeometry.tacticalHUDFrame(
            pet: CGRect(
                x: 24,
                y: 650,
                width: 320,
                height: 400
            ),
            displays: [display],
            scale: 0.8,
            offset: CGPoint(x: 17, y: -12)
        )
    )

    XCTAssertEqual(small.midX - 124, 17, accuracy: 0.001)
    XCTAssertEqual(large.midX - 184, 17, accuracy: 0.001)
    XCTAssertGreaterThan(large.width, small.width)
}
```

- [ ] **Step 2: Write failing configuration tests for smaller HUD scaling**

Add:

```swift
func testPodScaleAllowsCompactTacticalHUD() throws {
    let configuration = try loadConfiguration(
        """
        { "podScale": 0.65 }
        """
    )

    XCTAssertEqual(configuration.podScale, 0.65)
}
```

Keep the existing default at `1.14`.

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PanelGeometryTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.AppConfigurationTests
```

Expected: compilation fails because tactical geometry APIs do not exist and `podScale` is clamped to `1.0`.

- [ ] **Step 4: Implement tactical and effect frames**

Add to `PanelGeometry`:

```swift
public static func tacticalHUDFrame(
    pet: CGRect,
    displays: [DisplayDescriptor],
    scale: CGFloat,
    offset: CGPoint
) -> CGRect? {
    guard let appKitPet = appKitPetFrame(
        pet: pet,
        displays: displays
    ) else {
        return nil
    }
    let width = min(
        360,
        max(210, appKitPet.width * 1.05)
    ) * scale
    let height = 58 * scale
    let gap = max(8, appKitPet.height * 0.04)
    let frame = CGRect(
        x: appKitPet.midX - width / 2 + offset.x,
        y: appKitPet.maxY + gap + offset.y,
        width: width,
        height: height
    )
    return clamp(frame, to: displayContaining(appKitPet))
}

public static func petEffectFrame(
    pet: CGRect,
    displays: [DisplayDescriptor]
) -> CGRect? {
    guard let appKitPet = appKitPetFrame(
        pet: pet,
        displays: displays
    ) else {
        return nil
    }
    let travel = min(appKitPet.width * 0.18, 28)
    let width = max(
        appKitPet.width * 1.35,
        appKitPet.width + travel * 2
    )
    let height = appKitPet.height * 1.10
    let frame = CGRect(
        x: appKitPet.midX - width / 2,
        y: appKitPet.minY,
        width: width,
        height: height
    )
    return clamp(frame, to: displayContaining(appKitPet))
}
```

Keep display selection private, but split it into `displayContaining(_:)` and `clamp(_:to:)` helpers so tests cover top-edge, bottom-edge, and multi-display frames.

- [ ] **Step 5: Expand the configuration clamp**

Change `podScale` loading to:

```swift
podScale: min(
    1.6,
    max(
        0.65,
        document.podScale ?? defaults.podScale
    )
)
```

Keep installer output at `1.14`; compact values are validated by `AppConfigurationTests` when users edit the installed configuration.

- [ ] **Step 6: Run core and installer tests**

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PanelGeometryTests
swift test --disable-sandbox \
  --filter PetHUDCoreTests.AppConfigurationTests
CODEX_PET_HUD_TESTING=1 \
  bash Tests/Shell/install-cycle.bats
```

Expected: all tests pass.

- [ ] **Step 7: Commit geometry and configuration**

```bash
git add \
  Sources/PetHUDCore/AppConfiguration.swift \
  Sources/PetHUDCore/PanelGeometry.swift \
  Tests/PetHUDCoreTests/AppConfigurationTests.swift \
  Tests/PetHUDCoreTests/PanelGeometryTests.swift
git commit -m "feat: anchor tactical hud above pet"
```

---

### Task 6: Tactical Dual-Bar SwiftUI Panel

**Files:**
- Create: `Sources/CodexPetHUD/FlameCellView.swift`
- Create: `Sources/CodexPetHUD/TacticalHUDView.swift`
- Create: `Sources/CodexPetHUD/TacticalHUDPanelController.swift`
- Modify: `scripts/capture-hud.sh`
- Create: `Tests/Shell/tactical-ui.bats`

**Interfaces:**
- Consumes: `HUDPresentationData`
- Produces: `TacticalHUDPanelController.show(frame:data:)`
- Produces: AppKit window title `Codex Pet HUD Tactical`

- [ ] **Step 1: Add a shell contract for the renamed panel**

Create `Tests/Shell/tactical-ui.bats`:

```bash
#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
test -f "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'Codex Pet HUD Tactical' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'struct FlameCellView' \
  "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
grep -F 'ForEach(0..<7' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
```

- [ ] **Step 2: Run the shell contract and verify failure**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
```

Expected: FAIL because tactical files do not exist.

- [ ] **Step 3: Implement the nested flame**

Create `FlameCellView.swift` with:

```swift
import SwiftUI

struct FlameCellView: View {
    let isLit: Bool
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var flicker = false

    var body: some View {
        ZStack {
            FlameShape()
                .fill(isLit ? outerLit : outerUnlit)
            FlameShape()
                .fill(isLit ? middleLit : middleUnlit)
                .scaleEffect(0.68, anchor: .bottom)
            FlameShape()
                .fill(isLit ? innerLit : innerUnlit)
                .scaleEffect(0.40, anchor: .bottom)
        }
        .opacity(isLit ? 1 : 0.58)
        .shadow(
            color: isLit
                ? Color.red.opacity(0.72)
                : Color.blue.opacity(0.42),
            radius: isLit ? 6 : 3
        )
        .scaleEffect(
            x: 1,
            y:
                isLit && flicker && !reduceMotion
                ? 1.04
                : 0.96,
            anchor: .bottom
        )
        .onAppear {
            flicker = true
        }
        .animation(
            reduceMotion || !isLit
                ? nil
                : .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
            value: flicker
        )
        .accessibilityLabel(
            isLit ? "SP elapsed" : "SP remaining"
        )
    }

    private let outerLit =
        Color(red: 1.00, green: 0.20, blue: 0.30)
    private let middleLit =
        Color(red: 1.00, green: 0.54, blue: 0.17)
    private let innerLit =
        Color(red: 1.00, green: 0.91, blue: 0.42)
    private let outerUnlit =
        Color(red: 0.18, green: 0.42, blue: 1.00)
    private let middleUnlit =
        Color(red: 0.16, green: 0.77, blue: 1.00)
    private let innerUnlit =
        Color(red: 0.79, green: 0.97, blue: 1.00)
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: 0.53, y: 0.02),
            CGPoint(x: 0.60, y: 0.20),
            CGPoint(x: 0.62, y: 0.40),
            CGPoint(x: 0.77, y: 0.28),
            CGPoint(x: 0.95, y: 0.58),
            CGPoint(x: 0.86, y: 0.86),
            CGPoint(x: 0.50, y: 0.99),
            CGPoint(x: 0.14, y: 0.86),
            CGPoint(x: 0.05, y: 0.58),
            CGPoint(x: 0.30, y: 0.20),
            CGPoint(x: 0.36, y: 0.47),
        ]
        var path = Path()
        path.move(
            to: CGPoint(
                x: rect.width * points[0].x,
                y: rect.height * points[0].y
            )
        )
        for point in points.dropFirst() {
            path.addCurve(
                to: CGPoint(
                    x: rect.width * point.x,
                    y: rect.height * point.y
                ),
                control1: CGPoint(
                    x: rect.midX,
                    y: rect.height * point.y
                ),
                control2: CGPoint(
                    x: rect.width * point.x,
                    y: rect.height * point.y
                )
            )
        }
        path.closeSubpath()
        return path
    }
}
```

During visual QA, adjust only Bézier control points and the three approved color layers; do not return to the polygon flame.

- [ ] **Step 4: Implement the tactical two-row view**

Create `TacticalHUDView.swift` with one angular background and two rows:

```swift
struct TacticalHUDView: View {
    let data: HUDPresentationData
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        VStack(spacing: 6) {
            meterRow(
                label: "HP",
                trailing: data.hpText
            ) {
                GeometryReader { geometry in
                    Capsule()
                        .fill(Color.black.opacity(0.72))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(hpColor)
                                .frame(
                                    width:
                                        geometry.size.width *
                                        data.hpFraction
                                )
                        }
                }
                .frame(height: 9)
            }
            meterRow(
                label: "SP",
                trailing: data.resetText.uppercased()
            ) {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        FlameCellView(
                            isLit: index < data.spCellsLit
                        )
                        .frame(width: 15, height: 19)
                    }
                }
            }
            if data.band == .critical {
                Text("EXHAUSTED · SIGNAL CRITICAL")
                    .font(
                        .system(
                            size: 8,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(1.4)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(tacticalBackground)
        .allowsHitTesting(false)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.8),
            value: data.spCellsLit
        )
    }
}
```

Implement `meterRow`, `tacticalBackground`, and `hpColor` in the same file. Use emerald, green, amber, red, bright red, and gray values from the approved design.

Use these exact helpers:

```swift
private func meterRow<Content: View>(
    label: String,
    trailing: String,
    @ViewBuilder content: () -> Content
) -> some View {
    HStack(spacing: 7) {
        Text(label)
            .frame(width: 26, alignment: .leading)
            .foregroundStyle(
                data.band == .critical
                    ? Color.red
                    : Color.cyan
            )
        content()
            .frame(maxWidth: .infinity)
        Text(trailing)
            .frame(width: 42, alignment: .trailing)
            .foregroundStyle(Color.white)
    }
    .font(
        .system(
            size: 10,
            weight: .black,
            design: .monospaced
        )
    )
}

private var tacticalBackground: some View {
    TacticalPanelShape(cut: 8)
        .fill(
            Color.black.opacity(
                data.band == .critical ? 0.88 : 0.78
            )
        )
        .overlay {
            TacticalPanelShape(cut: 8)
                .stroke(
                    data.band == .critical
                        ? Color.red
                        : Color.cyan.opacity(0.78),
                    lineWidth: 1
                )
        }
}

private var hpColor: Color {
    switch data.band {
    case .healthy:
        Color(red: 0.26, green: 0.93, blue: 0.60)
    case .normal:
        Color(red: 0.45, green: 0.85, blue: 0.36)
    case .warning:
        Color(red: 1.00, green: 0.71, blue: 0.23)
    case .low:
        Color(red: 1.00, green: 0.24, blue: 0.31)
    case .critical:
        Color(red: 1.00, green: 0.12, blue: 0.22)
    case nil:
        Color.gray
    }
}

private struct TacticalPanelShape: Shape {
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: cut, y: 0))
        path.addLine(
            to: CGPoint(x: rect.maxX - cut, y: 0)
        )
        path.addLine(
            to: CGPoint(x: rect.maxX, y: cut)
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY - cut
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX - cut,
                y: rect.maxY
            )
        )
        path.addLine(
            to: CGPoint(x: cut, y: rect.maxY)
        )
        path.addLine(
            to: CGPoint(x: 0, y: rect.maxY - cut)
        )
        path.addLine(to: CGPoint(x: 0, y: cut))
        path.closeSubpath()
        return path
    }
}
```

- [ ] **Step 5: Implement the panel controller and capture title**

Create `TacticalHUDPanelController.swift` using the existing `ClickThroughPanel` class and this title:

```swift
panel.title = "Codex Pet HUD Tactical"
```

Expose:

```swift
func show(
    frame: CGRect,
    data: HUDPresentationData
)

func hide()
```

Update `scripts/capture-hud.sh` to search for `Codex Pet HUD Tactical` and `Codex Pet HUD Pet Effect`.

- [ ] **Step 6: Verify the new UI alongside the current coordinator**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
swift build --disable-sandbox
```

Expected: shell contract and Swift build pass. Keep the ring files temporarily so the current coordinator remains buildable until Task 8 switches controllers atomically.

- [ ] **Step 7: Commit the tactical UI slice**

```bash
git add \
  Sources/CodexPetHUD/FlameCellView.swift \
  Sources/CodexPetHUD/TacticalHUDView.swift \
  Sources/CodexPetHUD/TacticalHUDPanelController.swift \
  scripts/capture-hud.sh \
  Tests/Shell/tactical-ui.bats
git commit -m "feat: render tactical hp and flame sp bars"
```

---

### Task 7: Panic and Critical Pet Effects

**Files:**
- Create: `Sources/CodexPetHUD/PetEffectAssets.swift`
- Create: `Sources/CodexPetHUD/PetEffectView.swift`
- Create: `Sources/CodexPetHUD/PetEffectPanelController.swift`
- Modify: `Tests/Shell/tactical-ui.bats`

**Interfaces:**
- Consumes: `PetEffectManifest`, `PetAtlas.rowImages`, and `PetDistressState`
- Produces: `PetEffectAssets.load(manifest:)`
- Produces: `PetEffectPanelController.show(frame:state:assets:)`

- [ ] **Step 1: Extend the shell contract for the unified effect panel**

Append:

```bash
test -f "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
test -f "$ROOT/Sources/CodexPetHUD/PetEffectAssets.swift"
test -f "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'Codex Pet HUD Pet Effect' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
if grep -F 'Text("🌀")' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Pet replacement must not paste spiral emoji over sprite eyes.\n' >&2
  exit 1
fi
```

- [ ] **Step 2: Run the shell contract and verify failure**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
```

Expected: FAIL because unified effect files do not exist.

- [ ] **Step 3: Implement fallback asset assembly**

Create `PetEffectAssets.swift`:

```swift
import CoreGraphics
import PetHUDCore

struct PetEffectAssets {
    let panicFramesRight: [CGImage]
    let panicFramesLeft: [CGImage]
    let panicCustomFrames: [CGImage]?
    let criticalImage: CGImage?
    let failedFrames: [CGImage]
    let leftEye: NormalizedPoint
    let rightEye: NormalizedPoint
    let eyeScale: Double
    let headAnchor: NormalizedPoint
    let criticalScale: Double

    static func load(
        manifest: PetManifest
    ) -> PetEffectAssets? {
        guard
            let right = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .runningRight
            ),
            let left = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .runningLeft
            ),
            let failed = try? PetAtlas.rowImages(
                manifest: manifest,
                row: .failed
            )
        else {
            return nil
        }
        let metadata =
            (try? PetEffectManifest.load(
                directory: manifest.directoryURL
            )) ?? nil
        let panic = metadata?.panic
        let critical = metadata?.critical
        return PetEffectAssets(
            panicFramesRight: right,
            panicFramesLeft: left,
            panicCustomFrames: panic?.spritesheetURL.flatMap {
                try? PetAtlas.stripImages(
                    url: $0,
                    columns: panic?.columns ?? 8
                )
            },
            criticalImage: critical.flatMap {
                try? PetAtlas.image(url: $0.imageURL)
            },
            failedFrames: failed,
            leftEye: panic?.leftEye ??
                NormalizedPoint(x: 0.42, y: 0.31),
            rightEye: panic?.rightEye ??
                NormalizedPoint(x: 0.58, y: 0.31),
            eyeScale: panic?.eyeScale ?? 1,
            headAnchor: critical?.headAnchor ??
                NormalizedPoint(x: 0.5, y: 0.30),
            criticalScale: critical?.scale ?? 1
        )
    }
}
```

Add `PetAtlas.image(url:)` as the same validated ImageIO loader used internally by atlas and strip extraction.

- [ ] **Step 4: Implement compact panic animation**

In `PetEffectView.swift`, use `TimelineView(.animation)` and compute:

```swift
let duration = 2.4
let progress =
    timeline.date.timeIntervalSinceReferenceDate
        .truncatingRemainder(dividingBy: duration) /
    duration
let movingRight = progress < 0.5
let local = movingRight ? progress * 2 : (progress - 0.5) * 2
let eased = 0.5 - cos(local * .pi) / 2
let travel = min(geometry.size.width * 0.18, 28)
let x = movingRight
    ? -travel + eased * travel * 2
    : travel - eased * travel * 2
let bounce = -abs(sin(local * .pi * 2)) * 4
```

Choose a running frame from the direction-specific array and render it upright.
Generic pets use a non-facial aura and no procedural eye overlay. Custom strips
carry integrated eye art and are mirrored for left travel.

The panic backdrop is a subtle red-tinted rounded field with enough opacity to prevent the native pet underneath from reading as a duplicate, but it must not become a solid black rectangle.

- [ ] **Step 5: Implement critical art and fallback animation**

For `.critical`:

- Render `criticalImage` when present.
- Otherwise animate the v2 failed row.
- Never rotate the image.
- Keep custom critical art as one replacement sprite.
- Add only the generic non-facial aura when custom art is absent.
- Add two birds and two sparkles around the calibrated head anchor for both
  custom and generic replacements.
- Keep orbit glyph boxes inside the effect panel at display edges and critical
  scale `2`.
- Under Reduce Motion, freeze the replacement frame and four orbit glyphs at
  separated positions.

Expose:

```swift
struct PetEffectView: View {
    let state: PetDistressState
    let assets: PetEffectAssets
}
```

- [ ] **Step 6: Implement the unified panel controller**

Create `PetEffectPanelController.swift` with:

```swift
panel.title = "Codex Pet HUD Pet Effect"
```

Expose:

```swift
func show(
    frame: CGRect,
    state: PetDistressState,
    assets: PetEffectAssets
)

func hide()
```

- [ ] **Step 7: Verify source contracts**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
```

Expected: PASS.

- [ ] **Step 8: Commit pet effects**

```bash
git add \
  Sources/CodexPetHUD/PetEffectAssets.swift \
  Sources/CodexPetHUD/PetEffectView.swift \
  Sources/CodexPetHUD/PetEffectPanelController.swift \
  Sources/PetHUDCore/PetAtlas.swift \
  Tests/Shell/tactical-ui.bats
git commit -m "feat: add panic and prone pet effects"
```

---

### Task 8: Coordinator, Cache, and Diagnostic Integration

**Files:**
- Modify: `Sources/CodexPetHUD/PetHUDApplication.swift`
- Modify: `Sources/CodexPetHUD/Diagnostics.swift`
- Delete: `Sources/CodexPetHUD/LifePodView.swift`
- Delete: `Sources/CodexPetHUD/LifePodPanelController.swift`
- Delete: `Sources/CodexPetHUD/CriticalEffectView.swift`
- Delete: `Sources/CodexPetHUD/CriticalPanelController.swift`
- Modify: `Tests/Shell/main-actor.bats`
- Modify: `Tests/PetHUDCoreTests/ApplicationModelTests.swift`

**Interfaces:**
- Consumes: `PetWindowLocator.currentObservation()`
- Consumes: `PetPresenceTracker`, `PetGeometryCache`, and both new panel controllers.
- Produces: idle-persistent render behavior in the running macOS app.

- [ ] **Step 1: Add a model test for retained geometry input**

Add:

```swift
func testSameGeometryKeepsHUDVisibleAcrossQuotaTicks() {
    var model = ApplicationModel()
    _ = model.reduce(.petWindowChanged(petWindow))
    _ = model.reduce(.quotaLoaded(snapshot(remaining: 93)))

    let presentation = model.reduce(
        .clockTick(
            Date(timeIntervalSince1970: 10_060)
        )
    )

    XCTAssertTrue(presentation.showHUD)
    XCTAssertEqual(presentation.petWindow, petWindow)
}
```

- [ ] **Step 2: Refactor coordinator fields and cache setup**

Replace old controller/tracker fields with:

```swift
private let tacticalHUDController =
    TacticalHUDPanelController()
private let petEffectController =
    PetEffectPanelController()
private let geometryCache: PetGeometryCache
private let effectAssets: PetEffectAssets?
private var presenceTracker: PetPresenceTracker
```

Use:

```swift
let applicationSupport = home
    .appendingPathComponent(
        "Library/Application Support",
        isDirectory: true
    )
    .appendingPathComponent(
        "CodexPetHUD",
        isDirectory: true
    )
geometryCache = PetGeometryCache(
    url: applicationSupport.appendingPathComponent(
        "pet-geometry.json"
    )
)
let cachedWindow = try? geometryCache.load()?.window
let restored = cachedWindow.flatMap { window in
    PanelGeometry.appKitPetFrame(
        pet: window.bounds,
        displays: Self.currentDisplays()
    ) == nil
        ? nil
        : window
}
presenceTracker = PetPresenceTracker(
    restoredWindow: restored
)
effectAssets = manifest.flatMap(
    PetEffectAssets.load(manifest:)
)
```

- [ ] **Step 3: Replace polling with observation-aware tracking**

Implement:

```swift
private func updatePetWindow() {
    let now = Date()
    let observation =
        PetWindowLocator.currentObservation()
    if let exact = observation.exactWindow {
        try? geometryCache.save(
            PetGeometryRecord(
                window: exact,
                updatedAt: now
            )
        )
    }
    let petWindow = presenceTracker.update(
        observation: observation,
        now: now
    )
    render(
        model.reduce(.petWindowChanged(petWindow))
    )
}
```

Keep the `0.25s` timer in `.common` run-loop mode.

- [ ] **Step 4: Render tactical and effect panels**

Replace the ring render branch with:

```swift
guard
    presentation.showHUD,
    let petWindow = presentation.petWindow
else {
    tacticalHUDController.hide()
    petEffectController.hide()
    return
}
```

Compute `tacticalHUDFrame` and show the tactical panel unconditionally while geometry is valid. Show the effect panel only when `distressState != .normal`, `effectAssets != nil`, and `petEffectFrame` succeeds. Otherwise hide only the effect panel.

- [ ] **Step 5: Make idle diagnostics presence-aware**

Change diagnostics to:

```swift
let observation = PetWindowLocator.currentObservation()
let petWindowStatus =
    observation.exactWindow != nil ||
    observation.hasStablePresence
    ? "found"
    : "missing"
```

Keep the existing JSON key and exit-code contract so installed Skill workflows remain compatible.

- [ ] **Step 6: Update source-level shell assertions**

In `Tests/Shell/main-actor.bats`, keep the requirement for exactly three `.common` timers and add:

```bash
grep -F 'PetWindowLocator.currentObservation()' "$SOURCE"
grep -F 'PetPresenceTracker' "$SOURCE"
grep -F 'PetGeometryCache' "$SOURCE"
```

- [ ] **Step 7: Remove superseded ring and critical components**

Delete:

```text
Sources/CodexPetHUD/LifePodView.swift
Sources/CodexPetHUD/LifePodPanelController.swift
Sources/CodexPetHUD/CriticalEffectView.swift
Sources/CodexPetHUD/CriticalPanelController.swift
```

The coordinator must reference only `TacticalHUDPanelController` and `PetEffectPanelController` before these files are removed.

- [ ] **Step 8: Run full tests and build**

Run:

```bash
swift test --disable-sandbox
swift build --disable-sandbox
bash Tests/Shell/main-actor.bats
```

Expected: all Swift tests pass, the executable builds, and source-level timer checks pass.

- [ ] **Step 9: Commit application integration**

```bash
git add \
  Sources/CodexPetHUD/PetHUDApplication.swift \
  Sources/CodexPetHUD/Diagnostics.swift \
  Tests/Shell/main-actor.bats \
  Tests/PetHUDCoreTests/ApplicationModelTests.swift
git add -u \
  Sources/CodexPetHUD/LifePodView.swift \
  Sources/CodexPetHUD/LifePodPanelController.swift \
  Sources/CodexPetHUD/CriticalEffectView.swift \
  Sources/CodexPetHUD/CriticalPanelController.swift
git commit -m "feat: integrate idle persistent tactical hud"
```

---

### Task 9: Generate and Package Yicha Critical Art

**Files:**
- Create: `Examples/yicha/hud-critical.png`
- Create: `Examples/yicha/hud-effects.json`
- Modify: `docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md`

**Interfaces:**
- Consumes: Yicha's installed `spritesheet.webp` as canonical identity reference.
- Produces: one transparent prone image plus normalized panic-eye and critical-head anchors.

- [ ] **Step 1: Load required visual skills and inspect canonical art**

Before generation, load and follow:

```text
hatch-pet
imagegen
```

Inspect:

```text
${CODEX_HOME:-$HOME/.codex}/pets/yicha/spritesheet.webp
```

Confirm the v2 running-left and running-right rows use open red eyes. This allows panic to reuse standard running frames and limits custom generation to critical prone art.

- [ ] **Step 2: Generate the critical source**

Use the Yicha atlas and neutral cell as image references with this authoritative prompt:

```text
Create one coherent horizontal strip of eight Codex pet HUD critical-pose
sprites for Yicha, preserving her white hair, red eyes, white robe, red neck
ribbon, chibi pixel-art identity, palette, proportions, and line weight. In
every frame she lies flat on the ground with both arms and both legs spread into
a clearly readable Chinese “大” silhouette. Her face remains visible toward the
viewer. Her eyelids are open and both eyes show anime dizziness spirals. Vary
only tiny breathing, hair settling, and expression timing across the eight
frames. Do not bake birds, sparkles, text, a floor shadow, scenery, or detached
effects into the sprite; the runtime adds the approved orbit separately. No
standing pose, rotated upright sprite, or closed eyes.
Eight evenly spaced full-body frames on one flat chroma-key green background
with generous safe padding and no visible guides.
```

Select one output only after checking identity, the “大” silhouette, open spiral eyes, and absence of detached effects.

- [ ] **Step 3: Remove the chroma background and verify transparency**

Call `codex_app.load_workspace_dependencies` and assign the returned bundled
Python executable to `PY`. Set stable local paths:

```bash
RUN_DIR=/private/tmp/codex-pet-hud-yicha-critical
HATCH_SKILL="${CODEX_HOME:-$HOME/.codex}/skills/hatch-pet"
mkdir -p \
  "$RUN_DIR/decoded" \
  "$RUN_DIR/frames" \
  "$RUN_DIR/qa"
```

Copy the exact selected imagegen output to
`/private/tmp/codex-pet-hud-yicha-critical/decoded/failed.png`, extract it
through the hatch-pet deterministic frame tooling, and select the cleanest
centered frame:

```bash
"$PY" \
  "$HATCH_SKILL/scripts/extract_strip_frames.py" \
  --decoded-dir "$RUN_DIR/decoded" \
  --output-dir "$RUN_DIR/frames" \
  --states failed \
  --chroma-key '#00FF00' \
  --method stable-slots

"$PY" \
  "$HATCH_SKILL/scripts/inspect_frames.py" \
  --frames-root "$RUN_DIR/frames" \
  --json-out "$RUN_DIR/qa/critical-frames.json" \
  --states failed \
  --allow-stable-slots
```

Copy the approved transparent frame to:

```text
Examples/yicha/hud-critical.png
```

Use `view_image` on the final PNG over both light and dark backgrounds.

- [ ] **Step 4: Add calibrated Yicha metadata**

Create `Examples/yicha/hud-effects.json`:

```json
{
  "version": 1,
  "panic": {
    "leftEye": [0.42, 0.31],
    "rightEye": [0.58, 0.31],
    "eyeScale": 0.88
  },
  "critical": {
    "image": "hud-critical.png",
    "headAnchor": [0.72, 0.30],
    "scale": 1.0
  }
}
```

Adjust only the normalized anchors and scales after live visual QA.

- [ ] **Step 5: Clarify the design document's optional panic strip**

Update the asset-contract paragraph to state that `panic.spritesheet` is
optional. Generic pets use standard directional running frames with a
non-facial aura and no procedural eye overlay. A custom strip carries integrated
eye art and may omit legacy eye anchors.

- [ ] **Step 6: Validate the example through core loaders**

Add a fixture-based test in `PetEffectManifestTests.swift` that copies `Examples/yicha/hud-effects.json` and `hud-critical.png` into a temporary pet directory, then loads the descriptor and image.

Run:

```bash
swift test --disable-sandbox \
  --filter PetHUDCoreTests.PetEffectManifestTests
```

Expected: PASS.

- [ ] **Step 7: Commit Yicha effect assets**

```bash
git add \
  Examples/yicha/hud-critical.png \
  Examples/yicha/hud-effects.json \
  docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md \
  Tests/PetHUDCoreTests/PetEffectManifestTests.swift
git commit -m "feat: add Yicha critical hud artwork"
```

---

### Task 10: Skill, Documentation, and Release Metadata

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/architecture.md`
- Modify: `docs/privacy.md`
- Create: `docs/screenshots/tactical-hud.png`
- Create: `docs/screenshots/tactical-hud-panic.png`
- Create: `docs/screenshots/tactical-hud-critical.png`
- Modify: `Resources/Info.plist`
- Modify: `skills/codex-pet-hud/SKILL.md`
- Modify: `skills/codex-pet-hud/references/troubleshooting.md`
- Modify: `Tests/Shell/release-validation.bats`
- Modify: `Tests/Shell/skill-validation.bats`

**Interfaces:**
- Produces: reusable Skill instructions for idle tracking, tactical alignment, panic, critical art, and Yicha example installation.
- Produces: v0.3.0-rc.1 release metadata.

- [ ] **Step 1: Update failing release and Skill expectations**

Change `release-validation.bats` to require:

```bash
test -s \
  docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md
test -s \
  docs/superpowers/plans/2026-07-27-tactical-dual-bar-hud.md
grep -F 'Version 0.3.0-rc.1' README.md
grep -F 'tactical dual-bar HUD' CHANGELOG.md
```

Remove the obsolete `test ! -e docs/superpowers` assertion.

Extend `skill-validation.bats`:

```bash
for keyword in tactical flame panic idle critical; do
  grep -i "$keyword" "$SKILL/SKILL.md" >/dev/null
done
```

- [ ] **Step 2: Run validation scripts and verify failure**

Run:

```bash
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: FAIL until docs and Skill text are updated.

- [ ] **Step 3: Update version and changelog**

Set:

```xml
<key>CFBundleShortVersionString</key>
<string>0.3.0</string>
<key>CFBundleVersion</key>
<string>3</string>
```

Add `0.3.0-rc.1` to `CHANGELOG.md` with:

- Tactical HP and seven-flame SP bars.
- Stable idle presence tracking and geometry persistence.
- Compact spiral-eye panic state.
- Custom prone critical art and generic fallback.
- Smaller `podScale` support.

- [ ] **Step 4: Rewrite user and architecture docs**

Update `README.md` to:

- Replace all ring terminology and screenshots.
- Document HP thresholds and seven flame semantics.
- Document `podScale` range `0.65...1.6`.
- Document idle persistence and geometry cache.
- Document copying `Examples/yicha/hud-critical.png` and `hud-effects.json` into a Yicha pet directory.
- Keep diagnostic, install, uninstall, and privacy commands.

Update `docs/architecture.md` with the exact data flow from the design spec. Update `docs/privacy.md` to note that geometry cache contains window bounds, PID, window ID, and timestamp only.

- [ ] **Step 5: Update the reusable Skill**

Rewrite `skills/codex-pet-hud/SKILL.md` so the workflow:

1. Validates a macOS 14 host and one selected v2 pet.
2. Runs Swift and shell tests before installation.
3. Diagnoses stable presence when the task is idle.
4. Verifies movement and resizing while no task is active.
5. Explains tactical alignment settings.
6. Uses `hatch-pet` for custom critical art.
7. Copies optional effect assets only after path and image validation.

Update troubleshooting with exact idle-presence titles and the two-second/three-observation close threshold.

- [ ] **Step 6: Capture final screenshots**

Build and launch fixture modes:

```bash
scripts/build-app.sh
"dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock Fixtures/healthy.json
"dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock Fixtures/low.json
"dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock Fixtures/critical.json
```

Capture each state with `scripts/capture-hud.sh`, crop only surrounding desktop whitespace, and save to the three tactical screenshot paths. Do not include tokens, account identity, unrelated windows, or local filesystem paths.

- [ ] **Step 7: Run release and Skill validation**

Run:

```bash
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: PASS.

- [ ] **Step 8: Commit docs and release metadata**

```bash
git add \
  README.md \
  CHANGELOG.md \
  docs/architecture.md \
  docs/privacy.md \
  docs/screenshots/tactical-hud.png \
  docs/screenshots/tactical-hud-panic.png \
  docs/screenshots/tactical-hud-critical.png \
  Resources/Info.plist \
  skills/codex-pet-hud/SKILL.md \
  skills/codex-pet-hud/references/troubleshooting.md \
  Tests/Shell/release-validation.bats \
  Tests/Shell/skill-validation.bats
git commit -m "docs: prepare tactical hud release"
```

---

### Task 11: Full Verification, Local Installation, and Release

**Files:**
- Verify all tracked files.
- Install to: `$HOME/Applications/Codex Pet HUD.app`
- Install Yicha assets to: `${CODEX_HOME:-$HOME/.codex}/pets/yicha/`
- Install Skill to: `${CODEX_HOME:-$HOME/.codex}/skills/codex-pet-hud/`

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: tested local macOS installation and GitHub v0.3.0-rc.1 release.

- [ ] **Step 1: Run the complete automated suite**

Run:

```bash
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
```

Expected: every Swift and shell test passes.

- [ ] **Step 2: Build and verify the signed app bundle**

Run:

```bash
scripts/build-app.sh
codesign --verify --deep --strict \
  "dist/Codex Pet HUD.app"
/usr/libexec/PlistBuddy \
  -c 'Print :CFBundleShortVersionString' \
  "dist/Codex Pet HUD.app/Contents/Info.plist"
```

Expected: codesign succeeds and version prints `0.3.0`.

- [ ] **Step 3: Install Yicha assets and the app**

After obtaining filesystem approval for the pet and application directories:

```bash
cp Examples/yicha/hud-critical.png \
  "${CODEX_HOME:-$HOME/.codex}/pets/yicha/hud-critical.png"
cp Examples/yicha/hud-effects.json \
  "${CODEX_HOME:-$HOME/.codex}/pets/yicha/hud-effects.json"
scripts/install.sh \
  --pet-path "${CODEX_HOME:-$HOME/.codex}/pets/yicha"
```

Expected: app, LaunchAgent, configuration, and Yicha effect files exist.

- [ ] **Step 4: Install the updated local Skill**

After obtaining filesystem approval:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
/usr/bin/ditto \
  skills/codex-pet-hud \
  "${CODEX_HOME:-$HOME/.codex}/skills/codex-pet-hud"
```

Run `skill-validation.bats` against the repository copy before and after installation.

- [ ] **Step 5: Perform live idle, movement, and resize QA**

Use a healthy fixture or real quota:

1. Leave Codex with no active task for two minutes; HUD remains visible.
2. Move Yicha at least five times while idle; HUD never disappears.
3. Resize Yicha small, default, and large; HUD remains centered above it.
4. Move Yicha across displays; HUD remains visible and clamped on-screen.
5. Close the pet; HUD and effect panels disappear after at least two seconds.

Record results in the task log without adding machine-specific paths to release files.

- [ ] **Step 6: Perform panic and critical QA**

Run low and critical fixtures one at a time:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock Fixtures/low.json
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock Fixtures/critical.json
```

Confirm:

- `8%`: small-amplitude left/right running with integrated spiral-eye art.
- `2%`: prone “大” replacement pose with visible spiral eyes.
- Reduce Motion: static replacement frame and flames; no shuttle translation.
- Healthy state removes the effect overlay and leaves only the tactical HUD.

- [ ] **Step 7: Verify diagnostics and privacy**

Run:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --diagnose
scan_pattern='/Users/[A-Za-z0-9._-]+/|Bearer[[:space:]]+eyJ[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9_-]{20,}'
release_content=()
while IFS= read -r tracked_file; do
  if [ "$tracked_file" != "Tests/Shell/release-validation.bats" ]; then
    release_content+=("$tracked_file")
  fi
done < <(git ls-files)
rg -n "$scan_pattern" "${release_content[@]}"
```

Expected: diagnostics report `configuration=ok`, `pet=found`, `petWindow=found`, and `provider=reachable`; credential/path scan returns no matches.

- [ ] **Step 8: Review branch and publish v0.3.0-rc.1**

Run:

```bash
git status --short
git log --oneline --decorate -12
git diff origin/main...HEAD --stat
```

Require a clean worktree and reviewed commits. Then push the branch, open a draft pull request, and create the `v0.3.0-rc.1` release only after CI passes and the user confirms the final screenshots.
