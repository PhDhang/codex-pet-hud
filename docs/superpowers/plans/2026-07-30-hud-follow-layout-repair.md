# HUD Follow and Compact Layout Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the tactical HUD follow live pet dragging, center HP and MP values inside their bars, remove the visible SP reset suffix, and compact the panel without clipping.

**Architecture:** Preserve the existing locator, presence tracker, model, panel controller, and SwiftUI view boundaries. Add one live-geometry confidence bit to `PetPresenceTracker`, then remove the trailing-value column from layout metrics and render all meter text through `QuotaMeterFillView.centeredText`. Keep provider data, privacy behavior, window ambiguity handling, and configuration unchanged.

**Tech Stack:** Swift 6.2, AppKit, SwiftUI, Core Graphics, XCTest, Bash structural tests, macOS 14.

## Global Constraints

- Keep the existing 0.25-second pet-window observation cadence.
- Keep `podScale` clamped to `0.65...1.6` and preserve `podOffsetX` and `podOffsetY`.
- Keep exact-window ambiguity and cross-PID observations fail closed.
- Keep cold restored geometry hidden until stable presence and protected from fallback replacement.
- Keep HP blood-red, MP sky-blue, danger pulse, meter flow, SP flame, and Reduce Motion behavior unchanged.
- Keep the HUD four rows: HP, MP, SP, status.
- Keep weekly reset time in accessibility but do not render it visibly.
- Do not add pet effects, provider fields, permissions, credentials, or screen-rectangle capture.
- Keep version `0.4.0` build `4`; this repair remains part of the open unreleased PR.

---

### Task 1: Track Live Fallback Geometry During Dragging

**Files:**
- Modify: `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`
- Modify: `Sources/PetHUDCore/PetPresenceTracker.swift`

**Interfaces:**
- Consumes: `PetWindowObservation.visualGeometry`, `PetVisualGeometry.source`, `WindowDescriptor.ownerPID`, and the existing absence grace policy.
- Produces: `PetPresenceTracker.update(observation:now:) -> PetVisualGeometry?` that accepts same-PID fallback movement only after geometry has been confirmed in the current process.

- [ ] **Step 1: Replace the old frozen-fallback expectation with a movement regression test**

In `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`, replace
`testShellThenFallbackRetainsHighConfidenceGeometry` with:

```swift
func testLiveShellThenFallbackTracksMovingPet() {
    var tracker = PetPresenceTracker()
    let shell = shellGeometry(
        id: 11,
        bounds: CGRect(x: 180, y: 749, width: 116, height: 126)
    )
    let fallback = PetVisualGeometry(
        window: fallbackWindow(id: 12, x: 300),
        source: .mascotFallback
    )
    let start = Date(timeIntervalSince1970: 100)

    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: exactWindow(id: 10),
                visualGeometry: shell,
                hasStablePresence: true
            ),
            now: start
        ),
        shell
    )
    XCTAssertEqual(
        tracker.update(
            observation: .init(
                exactWindow: fallback.window,
                visualGeometry: fallback,
                hasStablePresence: true
            ),
            now: start.addingTimeInterval(0.25)
        ),
        fallback
    )
}
```

Update `testRepeatedFallbackGeometryDoesNotEnterAbsence` so each loop iteration
expects the current `fallback` instead of the initial shell geometry:

```swift
XCTAssertEqual(
    tracker.update(
        observation: .init(
            exactWindow: fallback.window,
            visualGeometry: fallback,
            hasStablePresence: false
        ),
        now: start.addingTimeInterval(offset)
    ),
    fallback
)
```

Keep `testRestoredShellGeometrySurvivesColdFallback` unchanged; it protects the
cold-cache boundary.

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```bash
swift test --disable-sandbox \
  --filter PetPresenceTrackerTests.testLiveShellThenFallbackTracksMovingPet
```

Expected: FAIL because the tracker returns the old shell geometry instead of the
moving fallback geometry.

- [ ] **Step 3: Add explicit live-geometry confidence**

In `Sources/PetHUDCore/PetPresenceTracker.swift`, add:

```swift
private var hasLiveGeometry = false
```

When an observed PID differs from the retained PID, clear both retained geometry
and confidence:

```swift
if
    let observedPID,
    let retainedPID = lastGeometry?.window.ownerPID,
    retainedPID != observedPID
{
    lastGeometry = nil
    hasLiveGeometry = false
}
```

Replace the current `retainsShell` block with:

```swift
if
    !observation.hasExactWindowAmbiguity,
    let candidate = observation.visualGeometry
{
    let protectsColdRestore =
        !hasLiveGeometry &&
        lastGeometry?.source == .shellDerived &&
        candidate.source == .mascotFallback
    if !protectsColdRestore {
        lastGeometry = candidate
        hasLiveGeometry = true
    }
}
```

When the absence grace expires, clear confidence with the retained geometry:

```swift
lastGeometry = nil
hasLiveGeometry = false
hasConfirmedPresence = false
```

- [ ] **Step 4: Run tracker and application-model tests and verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter PetPresenceTrackerTests
swift test --disable-sandbox --filter ApplicationModelTests
```

Expected: all selected tests pass, including cold restored geometry, PID
mismatch, ambiguity expiry, live fallback movement, and shell recovery.

- [ ] **Step 5: Commit the movement repair**

```bash
git add \
  Sources/PetHUDCore/PetPresenceTracker.swift \
  Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift
git commit -m "fix: follow live pet fallback geometry"
```

---

### Task 2: Compact the Panel and Remove Trailing-Column Metrics

**Files:**
- Modify: `Tests/PetHUDCoreTests/PanelGeometryTests.swift`
- Modify: `Tests/PetHUDCoreTests/TacticalHUDLayoutMetricsTests.swift`
- Modify: `Sources/PetHUDCore/PanelGeometry.swift`
- Modify: `Sources/PetHUDCore/TacticalHUDLayoutMetrics.swift`

**Interfaces:**
- Consumes: pet Core Graphics bounds, display descriptors, `podScale`, offsets, and the four-row layout.
- Produces: a base tactical frame of `190 × 72` points before `podScale`, a maximum unscaled width of `320`, and metrics without `trailingWidth`.

- [ ] **Step 1: Write compact geometry expectations**

In `Tests/PetHUDCoreTests/PanelGeometryTests.swift`, update
`testTacticalHUDScalesAbovePetCenter`:

```swift
XCTAssertEqual(frame.width, 190, accuracy: 0.001)
XCTAssertEqual(frame.height, 72, accuracy: 0.001)
XCTAssertEqual(frame.midX, 124, accuracy: 0.001)
XCTAssertGreaterThan(frame.minY, 305)
```

Update `testLiveVisualFrameProducesCompactDefaultHUD`:

```swift
XCTAssertEqual(hud.width, 216.6, accuracy: 0.001)
XCTAssertEqual(hud.height, 82.08, accuracy: 0.001)
XCTAssertEqual(hud.midX, 244, accuracy: 0.001)
XCTAssertEqual(hud.minY, 339, accuracy: 0.001)
```

Add:

```swift
func testLargePetUsesCompactMaximumHUDWidth() throws {
    let frame = try XCTUnwrap(
        PanelGeometry.tacticalHUDFrame(
            pet: CGRect(x: 200, y: 400, width: 500, height: 520),
            displays: [display],
            scale: 1,
            offset: .zero
        )
    )

    XCTAssertEqual(frame.width, 320, accuracy: 0.001)
    XCTAssertEqual(frame.height, 72, accuracy: 0.001)
    XCTAssertEqual(frame.midX, 450, accuracy: 0.001)
}
```

- [ ] **Step 2: Write compact layout-metric expectations**

In `Tests/PetHUDCoreTests/TacticalHUDLayoutMetricsTests.swift`, use
`CGSize(width: 190, height: 72)` for standard metrics and
`CGSize(width: 123.5, height: 46.8)` for compact metrics.

Replace the trailing-label test with:

```swift
func testCompactPanelProvidesReadableCenteredMeterWidth() {
    let frameSize = CGSize(width: 123.5, height: 46.8)
    let metrics = TacticalHUDLayoutMetrics(frameSize: frameSize)
    let meterWidth =
        frameSize.width -
        metrics.horizontalPadding * 2 -
        metrics.labelWidth -
        metrics.columnSpacing

    XCTAssertGreaterThanOrEqual(meterWidth, 88)
    XCTAssertLessThanOrEqual(metrics.spRowWidth, frameSize.width)
}
```

Update expanded comparison to initialize standard metrics with `190 × 72`.
Remove every assertion that references `trailingWidth`.

- [ ] **Step 3: Run geometry and layout tests and verify RED**

Run:

```bash
swift test --disable-sandbox --filter PanelGeometryTests
swift test --disable-sandbox --filter TacticalHUDLayoutMetricsTests
```

Expected: FAIL because the implementation still uses `210 × 75`, a `360`-point
maximum, and a trailing-value metric.

- [ ] **Step 4: Implement compact panel geometry**

In `Sources/PetHUDCore/PanelGeometry.swift`, change the tactical dimensions:

```swift
let width = min(
    320,
    max(190, appKitPet.width * 1.05)
) * scale
let height = 72 * scale
```

Keep centering, gap, offset, display selection, and clamping unchanged.

- [ ] **Step 5: Remove the trailing column from layout metrics**

In `Sources/PetHUDCore/TacticalHUDLayoutMetrics.swift`:

- Delete `public let trailingWidth: CGFloat`.
- Change the fit reference to:

```swift
let fit = min(
    frameSize.width / 190,
    frameSize.height / 72
)
```

- Delete the `trailingWidth` interpolation assignment.
- Change `spRowWidth` to:

```swift
public var spRowWidth: CGFloat {
    horizontalPadding * 2 +
        labelWidth +
        columnSpacing +
        flameWidth * 7 +
        flameSpacing * 6
}
```

Keep typography, flame sizes, row heights, and motion dimensions unchanged.

- [ ] **Step 6: Run geometry and layout tests and verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter PanelGeometryTests
swift test --disable-sandbox --filter TacticalHUDLayoutMetricsTests
```

Expected: both suites pass at compact, standard, large-pet, multi-display, edge,
offset, and resize sizes.

- [ ] **Step 7: Commit the compact geometry**

```bash
git add \
  Sources/PetHUDCore/PanelGeometry.swift \
  Sources/PetHUDCore/TacticalHUDLayoutMetrics.swift \
  Tests/PetHUDCoreTests/PanelGeometryTests.swift \
  Tests/PetHUDCoreTests/TacticalHUDLayoutMetricsTests.swift
git commit -m "feat: compact tactical HUD geometry"
```

---

### Task 3: Center HP and MP Values and Hide SP Reset Text

**Files:**
- Modify: `Tests/Shell/tactical-ui.bats`
- Modify: `Sources/CodexPetHUD/TacticalHUDView.swift`

**Interfaces:**
- Consumes: `HUDPresentationData.hpText`, `mpText`, `mpMode`, `resetText`, meter fractions, danger levels, and layout metrics.
- Produces: HP and MP text centered through `QuotaMeterFillView.centeredText`, no visible trailing column, and SP reset time retained only in accessibility.

- [ ] **Step 1: Change structural UI tests first**

In `Tests/Shell/tactical-ui.bats`, replace the old conditional-MP centered-text
checks with:

```bash
grep -F 'centeredText: data.hpText' "$HUD_VIEW"
grep -F 'centeredText: data.mpText' "$HUD_VIEW"
```

Add:

```bash
if grep -Fq 'trailing:' "$HUD_VIEW"; then
  printf 'Meter rows must not reserve a trailing value column.\n' >&2
  exit 1
fi
if grep -Fq 'data.resetText.uppercased()' "$HUD_VIEW"; then
  printf 'SP reset time must not render visibly.\n' >&2
  exit 1
fi
grep -F '.frame(maxWidth: .infinity, alignment: .center)' "$HUD_VIEW"
grep -F '.accessibilityValue(accessibilityValue)' "$HUD_VIEW"
```

Keep:

```bash
grep -F 'of 7 elapsed; reset in' "$HUD_VIEW"
grep -F 'accessibilityValue: spAccessibilityValue' "$HUD_VIEW"
```

Delete the obsolete check for:

```text
.accessibilityValue(accessibilityValue ?? trailing)
```

- [ ] **Step 2: Run the structural test and verify RED**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
```

Expected: FAIL because HP has no centered text, MP centers only `MAX`, SP renders
`resetText`, and `meterRow` still contains a trailing column.

- [ ] **Step 3: Center HP and MP text inside their meters**

In `Sources/CodexPetHUD/TacticalHUDView.swift`, change the HP call to:

```swift
meterRow(
    label: "HP",
    rowHeight: metrics.hpRowHeight,
    accessibilityValue: data.hpText
) {
    QuotaMeterFillView(
        fraction: data.hpFraction,
        palette: Self.hpPalette,
        mode:
            data.band == nil
            ? .unavailable
            : .measured,
        dangerLevel: data.hpDangerLevel,
        centeredText: data.hpText
    )
    .frame(height: metrics.hpBarHeight)
}
```

Change the MP call to:

```swift
meterRow(
    label: "MP",
    rowHeight: metrics.hpRowHeight,
    accessibilityValue: mpAccessibilityValue
) {
    QuotaMeterFillView(
        fraction: data.mpFraction,
        palette: Self.mpPalette,
        mode: data.mpMode,
        dangerLevel: data.mpDangerLevel,
        centeredText: data.mpText
    )
    .frame(height: metrics.hpBarHeight)
}
```

This uses the same location for measured percentages, `MAX`, and `--`.

- [ ] **Step 4: Remove visible SP reset text and fill the row**

Change the SP call to:

```swift
meterRow(
    label: "SP",
    rowHeight: metrics.flameHeight,
    accessibilityValue: spAccessibilityValue
) {
    HStack(spacing: metrics.flameSpacing) {
        ForEach(0..<7, id: \.self) { index in
            FlameCellView(
                isLit: index < data.spCellsLit
            )
            .frame(
                width: metrics.flameWidth,
                height: metrics.flameHeight
            )
            .accessibilityHidden(true)
        }
    }
    .frame(
        maxWidth: .infinity,
        alignment: .center
    )
    .frame(height: metrics.flameHeight)
}
```

Replace `meterRow` with a no-trailing-column signature:

```swift
private func meterRow<Content: View>(
    label: String,
    rowHeight: CGFloat,
    accessibilityValue: String,
    @ViewBuilder content: () -> Content
) -> some View {
    let metrics = TacticalHUDLayoutMetrics(
        frameSize: frameSize
    )
    return HStack(spacing: metrics.columnSpacing) {
        Text(label)
            .frame(width: metrics.labelWidth, alignment: .leading)
            .foregroundStyle(tacticalAccentColor)
        content()
            .frame(maxWidth: .infinity)
    }
    .font(
        .system(
            size: metrics.meterFontSize,
            weight: .black,
            design: .monospaced
        )
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(label)
    .accessibilityValue(accessibilityValue)
    .frame(height: rowHeight)
}
```

- [ ] **Step 5: Run focused UI and presentation tests and verify GREEN**

Run:

```bash
bash Tests/Shell/tactical-ui.bats
swift test --disable-sandbox --filter HUDPresentationDataTests
swift test --disable-sandbox --filter QuotaMeterMotionPolicyTests
```

Expected: all pass; provider-derived text and motion policies remain unchanged
while visual placement changes.

- [ ] **Step 6: Commit the centered-meter UI**

```bash
git add \
  Sources/CodexPetHUD/TacticalHUDView.swift \
  Tests/Shell/tactical-ui.bats
git commit -m "feat: center HUD meter values"
```

---

### Task 4: Update User Guidance and Release Contracts

**Files:**
- Modify: `Tests/Shell/release-validation.bats`
- Modify: `Tests/Shell/skill-validation.bats`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/architecture.md`
- Modify: `skills/codex-pet-hud/SKILL.md`

**Interfaces:**
- Consumes: the approved HUD behavior and existing privacy language.
- Produces: active documentation and release checks that describe live fallback tracking, centered HP/MP labels, compact sizing, and accessibility-only SP reset time.

- [ ] **Step 1: Add failing documentation assertions**

In `Tests/Shell/release-validation.bats`, add:

```bash
grep -F \
  'HP and MP values are centered inside their bars.' \
  README.md
grep -F \
  'The weekly reset countdown remains available to accessibility tools but is not shown visually.' \
  README.md
grep -F \
  'Live same-PID fallback geometry follows dragging after current-process geometry confirmation.' \
  docs/architecture.md
```

In `Tests/Shell/skill-validation.bats`, add:

```bash
grep -F \
  'HP and MP values are centered inside the bars.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F \
  'SP reset time is accessibility-only and has no visible suffix.' \
  "$SKILL/SKILL.md" >/dev/null
```

- [ ] **Step 2: Run documentation checks and verify RED**

Run:

```bash
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: FAIL because the new release language is not present yet.

- [ ] **Step 3: Update active documentation**

In `README.md`:

- Add `HP and MP values are centered inside their bars.` after the palette
  description.
- Add `The weekly reset countdown remains available to accessibility tools but is not shown visually.` after the SP paragraph.
- Update idle linkage to state that current-process-confirmed same-PID fallback
  geometry follows movement while restored geometry remains protected.
- Describe the default HUD as `190 × 72` points before `podScale`.

In `docs/architecture.md`, document:

```text
Live same-PID fallback geometry follows dragging after current-process geometry confirmation.
```

Explain that restored shell geometry does not gain live confidence until a
current-process geometry observation is accepted.

In `skills/codex-pet-hud/SKILL.md`, add:

```text
HP and MP values are centered inside the bars.
SP reset time is accessibility-only and has no visible suffix.
```

Keep the movement-and-resize validation step and all privacy rules.

In `CHANGELOG.md`, add unreleased `Fixed` and `Changed` bullets:

```markdown
- HUD positioning now follows same-PID fallback geometry during live pet dragging
  without weakening cold-cache or ambiguity protection.
- HP and measured MP values now render inside their bars, SP no longer shows a
  visible reset suffix, and the default panel uses a denser `190 × 72` layout.
```

- [ ] **Step 4: Run documentation checks and verify GREEN**

Run:

```bash
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: both pass and the privacy scan remains quiet.

- [ ] **Step 5: Commit documentation**

```bash
git add \
  README.md \
  CHANGELOG.md \
  docs/architecture.md \
  skills/codex-pet-hud/SKILL.md \
  Tests/Shell/release-validation.bats \
  Tests/Shell/skill-validation.bats
git commit -m "docs: describe compact following HUD"
```

---

### Task 5: Verify, Install, Capture, and Publish the Repair

**Files:**
- Replace: `docs/screenshots/tactical-hud.png`
- No additional source changes expected.

**Interfaces:**
- Consumes: all implementation commits, `/Users/hang_macmini/.codex/pets/yicha`, the installed LaunchAgent, the HUD-only capture script, origin `PhDhang/codex-pet-hud`, and draft PR `#2`.
- Produces: a verified installed app, private HUD-only visual evidence, pushed branch, and updated draft PR.

- [ ] **Step 1: Run complete automated verification**

Run:

```bash
git diff --check
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
scripts/build-app.sh
codesign --verify --deep --strict "dist/Codex Pet HUD.app"
```

Expected: every Swift and shell test passes, production build succeeds, and
strict signature verification exits `0`.

- [ ] **Step 2: Install the checked build**

Run:

```bash
scripts/install.sh --pet-path "/Users/hang_macmini/.codex/pets/yicha"
sleep 3
"/Users/hang_macmini/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --diagnose
```

Expected host-authorized diagnostic fields:

```json
{
  "configuration": "ok",
  "pet": "found",
  "petWindow": "found",
  "provider": "reachable"
}
```

`fiveHourStatus` may be `measured` or `max`; do not print raw provider data.

- [ ] **Step 3: Verify live movement and resize**

With no active Codex task:

1. Record the pet and tactical HUD window centers from public Core Graphics
   metadata without printing titles, absolute coordinates, or other windows.
2. Drag the pet a short distance and resize it once.
3. Confirm the HUD center delta matches the pet center delta within one
   0.25-second sample and remains above the pet.
4. Confirm the HUD stays visible after the drag, resize, and idle reconstruction.
5. Confirm no pet-effect window exists.

Expected: movement uses current fallback geometry instead of the last shell
frame; shell-derived geometry resumes when available.

- [ ] **Step 4: Verify visual states**

Check the installed live state and controlled `--mock` runs using
`Fixtures/wham-usage-five-hour.json` plus temporary low and critical payloads.
Confirm:

- HP percentage is centered in the red bar.
- measured MP percentage uses the same centered position as `MAX`.
- unavailable HP/MP show centered `--`.
- exact `100%` and `MAX` remain static.
- low and critical pulse behavior and Reduce Motion remain unchanged.
- SP shows seven centered flames and no visible day/hour suffix.
- default `podScale: 1.14` produces a filled, balanced `216.6 × 82.08` window.

- [ ] **Step 5: Capture only the tactical HUD**

Run:

```bash
scripts/capture-hud.sh docs/screenshots/tactical-hud.png
sips -g pixelWidth -g pixelHeight docs/screenshots/tactical-hud.png
```

Inspect the RGBA image and confirm it contains only the tactical HUD window,
centered HP/MP text, centered SP flames, no SP reset suffix, no desktop, and no
other application content.

Commit the screenshot:

```bash
git add docs/screenshots/tactical-hud.png
git commit -m "docs: refresh compact HUD screenshot"
```

- [ ] **Step 6: Request final code review**

Invoke `requesting-code-review` with the merge base and current HEAD. Address
only Critical and Important findings through additional failing tests and focused
fix commits, then rerun Step 1.

- [ ] **Step 7: Push without force**

Run:

```bash
git status --short
git log --oneline origin/feature/tactical-dual-bar-hud..HEAD
git push -u origin feature/tactical-dual-bar-hud
```

Expected: clean working tree and a normal fast-forward push.

- [ ] **Step 8: Update draft PR `#2`**

Use the connected GitHub app to keep PR `#2` open and draft. Update its summary
with:

```markdown
- follow live same-PID fallback geometry while the pet is dragged
- center HP and measured MP values inside their bars
- remove the visible SP reset suffix while retaining accessibility detail
- compact the default tactical frame to 190 × 72 points before podScale
```

Update verification with the final Swift test count, all eight shell suites,
signed build, live movement/resize result, and HUD-window-only screenshot.

- [ ] **Step 9: Verify the published state**

Run:

```bash
git status -sb
git rev-parse HEAD
git rev-parse origin/feature/tactical-dual-bar-hud
```

Use the GitHub app to confirm PR `#2` is open, draft, targets `main`, and its
`head_sha` equals local `HEAD`.

Expected: local and remote SHAs match, the PR remains unmerged, and the worktree
is preserved for review feedback.

