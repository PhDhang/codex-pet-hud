# HUD-Only Pet Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all low-quota pet animation/replacement behavior while retaining tactical HP/SP HUD statuses for every valid Codex v2 pet.

**Architecture:** `ApplicationModel` remains the single source of HUD visibility and quota state, but no longer derives a pet distress state. `PetHUDCoordinator` owns only the tactical HUD panel; quota bands control HUD colors and labels (`PANIC` / `EXHAUSTED`) without loading assets or creating a second pet window. Pet compatibility remains limited to the standard v2 manifest fields used by the HUD, so no per-pet effect metadata is required.

**Tech Stack:** Swift 6.2, AppKit, SwiftUI, XCTest, Bash shell contracts, macOS 14.

## Global Constraints

- Preserve tactical HP/SP HUD visibility, colors, and labels for normal, `4–9%`, and `≤3%` fresh quota.
- `PANIC` and `EXHAUSTED` are HUD labels only; no quota state may alter, cover, replace, or animate the native pet.
- Delete the runtime and test-only pet-effect pipeline, including optional `hud-effects.json`, panic strips, critical art, and the auxiliary effect window.
- Keep generic Codex v2 pet support based on `pet.json`; do not add pet-specific branches or dependencies.
- Keep stale/offline/sign-in behavior unchanged.
- Do not modify installed user pet files under `$HOME/.codex/pets`.

---

### Task 1: Remove the Pet-Effect Runtime

**Files:**
- Modify: `Sources/PetHUDCore/ApplicationModel.swift`
- Modify: `Sources/CodexPetHUD/PetHUDApplication.swift`
- Modify: `Sources/PetHUDCore/PanelGeometry.swift`
- Modify: `Tests/PetHUDCoreTests/ApplicationModelTests.swift`
- Modify: `Tests/PetHUDCoreTests/HUDPresentationDataTests.swift`
- Modify: `Tests/PetHUDCoreTests/PanelGeometryTests.swift`
- Modify: `Tests/Shell/tactical-ui.bats`
- Modify: `Tests/Shell/main-actor.bats`
- Delete: `Sources/PetHUDCore/PetDistressState.swift`
- Delete: `Sources/PetHUDCore/PetEffectManifest.swift`
- Delete: `Sources/PetHUDCore/PetEffectLayout.swift`
- Delete: `Sources/PetHUDCore/PetAtlas.swift`
- Delete: `Sources/CodexPetHUD/PetEffectAssets.swift`
- Delete: `Sources/CodexPetHUD/PetEffectPanelController.swift`
- Delete: `Sources/CodexPetHUD/PetEffectView.swift`
- Delete: `Tests/PetHUDCoreTests/PetEffectManifestTests.swift`
- Delete: `Tests/PetHUDCoreTests/PetEffectLayoutTests.swift`
- Delete: `Tests/PetHUDCoreTests/PetAtlasTests.swift`

**Interfaces:**
- Consumes: `HUDState`, `PanelGeometry.tacticalHUDFrame`, and `HUDPresentationData.make(petName:state:now:)`.
- Produces: `PanelPresentation(showHUD:hudState:petWindow:)`, with no pet-effect or distress-state API.

- [ ] **Step 1: Write the failing removal and behavior tests**

Replace effect assertions in `Tests/Shell/tactical-ui.bats` with a source-ownership contract:

```bash
for removed in \
  PetEffectAssets.swift \
  PetEffectPanelController.swift \
  PetEffectView.swift
do
  test ! -e "$ROOT/Sources/CodexPetHUD/$removed"
done

if rg -n 'PetEffect|PetDistressState|distressState|effectAssets' \
  "$ROOT/Sources"; then
  printf 'HUD runtime still contains pet-effect behavior.\n' >&2
  exit 1
fi
```

In `ApplicationModelTests`, replace critical/panic distress assertions with state assertions:

```swift
func testCriticalQuotaShowsHUDWithCriticalBand() {
    var model = ApplicationModel()
    _ = model.reduce(.petWindowChanged(petWindow))

    let presentation = model.reduce(.quotaLoaded(snapshot(remaining: 2)))

    XCTAssertTrue(presentation.showHUD)
    XCTAssertEqual(
        presentation.hudState,
        .quota(snapshot: snapshot(remaining: 2), band: .critical)
    )
}
```

In `HUDPresentationDataTests`, retain label coverage but remove every `PetDistressState` assertion. Remove effect geometry tests and replace them with the existing tactical-frame containment coverage.

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `bash Tests/Shell/tactical-ui.bats && swift test --filter ApplicationModelTests && swift test --filter HUDPresentationDataTests`

Expected: the shell contract fails because the pet-effect files and runtime references still exist. The Swift tests compile after test edits and establish the retained low/critical HUD behavior.

- [ ] **Step 3: Remove the effect pipeline with the minimal HUD-only implementation**

Make `PanelPresentation` contain only:

```swift
public let showHUD: Bool
public let hudState: HUDState
public let petWindow: WindowDescriptor?
```

Remove `distressState`, `showCriticalEffect`, its model storage, and its reducer evaluation. In `PetHUDCoordinator`, retain only `TacticalHUDPanelController`; delete the effect controller, effect-asset loading, effect hide calls, and the conditional effect `show` block. Remove `PanelGeometry.petEffectFrame`, `lifePodFrame`, and `criticalFrame` once no caller remains.

Delete the listed effect sources and their dedicated tests. Keep `HUDPresentationData` label selection by `HPBand`, so low quota still renders `PANIC · QUOTA LOW` and critical quota still renders `EXHAUSTED · SIGNAL CRITICAL`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `bash Tests/Shell/tactical-ui.bats && bash Tests/Shell/main-actor.bats && swift test --filter ApplicationModelTests && swift test --filter HUDPresentationDataTests && swift test --filter PanelGeometryTests`

Expected: exit status `0`; low and critical quota tests preserve HUD state/labels, and no pet-effect runtime source remains.

- [ ] **Step 5: Commit the runtime removal**

```bash
git add Sources Tests
git commit -m "refactor: make low quota HUD-only"
```

### Task 2: Remove Effect Assets and Update Active Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/architecture.md`
- Modify: `skills/codex-pet-hud/SKILL.md`
- Modify: `skills/codex-pet-hud/references/troubleshooting.md`
- Modify: `scripts/capture-hud.sh`
- Modify: `Tests/Shell/skill-validation.bats`
- Modify: `Tests/Shell/release-validation.bats`
- Delete: `Examples/yicha/hud-effects.json`
- Delete: `Examples/yicha/hud-panic.png`
- Delete: `Examples/yicha/hud-critical.png`
- Delete: `docs/screenshots/tactical-hud-panic.png`

**Interfaces:**
- Consumes: the HUD-only runtime delivered by Task 1 and the standard `pet.json` v2 contract.
- Produces: documentation and capture tooling that refer to exactly one tactical HUD window and no optional pet-effect artifacts.

- [ ] **Step 1: Write failing documentation and capture contracts**

Update `Tests/Shell/tactical-ui.bats` to require a tactical-only capture script:

```bash
grep -F 'let tacticalName = "Codex Pet HUD Tactical"' \
  "$ROOT/scripts/capture-hud.sh"
if rg -n 'Pet Effect|effectRects|hud-effects|hud-panic|hud-critical' \
  "$ROOT/scripts/capture-hud.sh" "$ROOT/README.md" \
  "$ROOT/docs/architecture.md" "$ROOT/skills/codex-pet-hud"; then
  printf 'Active HUD documentation still describes pet effects.\n' >&2
  exit 1
fi
```

Update skill and release validation to assert HUD-only wording, for example:

```bash
grep -F 'never changes the native pet' "$SKILL/SKILL.md"
grep -F 'HUD-only' README.md
test ! -e Examples/yicha/hud-effects.json
test ! -e Examples/yicha/hud-panic.png
test ! -e Examples/yicha/hud-critical.png
```

- [ ] **Step 2: Run the focused shell tests and verify RED**

Run: `bash Tests/Shell/tactical-ui.bats && bash Tests/Shell/skill-validation.bats && bash Tests/Shell/release-validation.bats`

Expected: failure because active docs, capture tooling, and checked effect assets still reference the removed feature.

- [ ] **Step 3: Update documentation, validation, and checked assets**

Rewrite product documentation to state that fresh `4–9%` and `≤3%` change only HUD label/color while the native pet remains untouched. Replace the architecture graph with a single `TacticalHUDPanelController` output and describe pet compatibility as a v2 `pet.json` manifest plus name display. Make `capture-hud.sh` capture the single tactical HUD rectangle only.

Remove the optional effect section/copy commands from README and the skill. Delete the three checked Yicha effect assets and obsolete panic screenshot. Add a `Removed` changelog entry for pet replacements and effect assets; keep old plan/spec files as historical records rather than altering their recorded design.

- [ ] **Step 4: Run focused shell tests and verify GREEN**

Run: `bash Tests/Shell/tactical-ui.bats && bash Tests/Shell/skill-validation.bats && bash Tests/Shell/release-validation.bats`

Expected: exit status `0`; active documentation and assets expose no pet-effect feature and screenshot capture reads one window.

- [ ] **Step 5: Commit the documentation cleanup**

```bash
git add README.md CHANGELOG.md docs skills scripts Tests Examples
git commit -m "docs: document HUD-only pet compatibility"
```

### Task 3: Add Generic v2 Compatibility Coverage and Run Live Checks

**Files:**
- Modify: `Sources/PetHUDCore/HUDPresentationData.swift`
- Modify: `Sources/CodexPetHUD/PetHUDApplication.swift`
- Modify: `Tests/PetHUDCoreTests/PetManifestTests.swift`
- Modify: `README.md`
- Modify: `docs/superpowers/plans/2026-07-28-hud-only-pet-compatibility.md`

**Interfaces:**
- Consumes: `PetManifest.load(directory:)` and `HUDPresentationData.make(petName:state:now:)`.
- Produces: `HUDPresentationData.make(manifest:state:now:)`, which maps the selected v2 pet manifest to its HUD display name, plus a regression test proving multiple standard v2 manifests feed low and critical HUD labels without effect metadata.

- [ ] **Step 1: Write the failing multi-pet compatibility test**

Add a test that creates two different valid v2 `pet.json` directories with only `spritesheetPath` and no `hud-effects.json`; for each loaded `PetManifest`, call the new manifest-based HUD factory for low and critical quota:

```swift
for pet in pets {
    let manifest = try PetManifest.load(directory: pet.directory)
    let low = HUDPresentationData.make(
        manifest: manifest,
        state: .quota(snapshot: snapshot(remaining: 8), band: .low),
        now: now
    )
    XCTAssertEqual(low.petName, pet.displayName)
    XCTAssertEqual(low.statusLabel, "PANIC · QUOTA LOW")
}
```

Repeat the assertion at `2%` for `EXHAUSTED · SIGNAL CRITICAL`. The test must not create or load any effect asset.

- [ ] **Step 2: Run the compatibility test and verify RED**

Run: `swift test --filter PetManifestTests/testV2PetsRenderLowAndCriticalHUDWithoutEffectMetadata`

Expected: compile failure because `HUDPresentationData.make(manifest:state:now:)` does not yet exist.

- [ ] **Step 3: Add the manifest-based HUD factory and record actual live availability**

Implement the smallest overload:

```swift
public static func make(
    manifest: PetManifest?,
    state: HUDState,
    now: Date
) -> HUDPresentationData {
    make(
        petName: manifest?.displayName ?? "CODEX PET",
        state: state,
        now: now
    )
}
```

Use it from `PetHUDCoordinator.render` so the app and regression test share the same manifest-to-name path. Keep the test entirely on the standard v2 manifest contract. Update README test notes to distinguish automated generic-v2 compatibility coverage from live desktop validation. Record that the local machine exposes only the installed `一茬` pet; do not claim a live test of default pets whose assets are not installed or discoverable in the ChatGPT bundle.

- [ ] **Step 4: Run the compatibility, full test, build, and live check commands**

Run:

```bash
swift test
bash Tests/Shell/*.bats
scripts/build-app.sh
find "$HOME/.codex/pets" -mindepth 2 -maxdepth 2 -name pet.json -print
find /Applications/ChatGPT.app -type f \
  \( -name pet.json -o -iname '*sprite*.webp' -o -iname '*sprite*.png' \) -print
```

Expected: all automated checks exit `0`. The two discovery commands document exactly which pets can receive a live desktop verification; run the application’s existing diagnose/mock-visual workflow for every discovered valid v2 pet.

- [ ] **Step 5: Commit the compatibility evidence**

```bash
git add Sources/PetHUDCore/HUDPresentationData.swift \
  Sources/CodexPetHUD/PetHUDApplication.swift \
  Tests/PetHUDCoreTests/PetManifestTests.swift README.md \
  docs/superpowers/plans/2026-07-28-hud-only-pet-compatibility.md
git commit -m "test: cover HUD-only v2 pet compatibility"
```

## Self-Review

- **Spec coverage:** Task 1 removes all 4–9% and ≤3% pet actions while preserving low/critical HUD labels. Task 2 removes optional effect assets, docs, capture logic, and validation contracts. Task 3 tests multiple metadata-free v2 pets and records the live-pet availability limit.
- **Placeholder scan:** No task contains TODO/TBD text or unspecified commands; each implementation change has concrete files, expected API, and exact verification command.
- **Type consistency:** `PanelPresentation` is consistently reduced to `showHUD`, `hudState`, and `petWindow`; all remaining low/critical display logic flows through `HUDState` and `HUDPresentationData`.
