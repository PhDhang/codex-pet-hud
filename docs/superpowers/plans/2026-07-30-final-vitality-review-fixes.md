# Final Vitality Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fail closed when multiple exact mascot windows share one PID, publish a non-disclosing privacy scan, and align final vitality documentation.

**Architecture:** `PetWindowObservation` will carry explicit exact-window ambiguity alongside the selected exact window. `PetPresenceTracker` will treat that ambiguity as an absent observation, preserving the existing three-observation/two-second grace period before clearing retained geometry; diagnostics will remain immediately fail-closed because their fresh tracker has no confirmed live presence. Documentation guards will validate quiet privacy scans and the final four-row HUD claims.

**Tech Stack:** Swift 6.2, XCTest, Bash, AppKit/CoreGraphics, ripgrep, macOS codesigning.

## Global Constraints

- Preserve single-window idle, movement, resize, level-4 ordering, and render-cache behavior.
- Keep version `0.4.0`.
- Do not change screenshot pixels or files unless rendering changes.
- Keep diagnostics redacted and HUD capture PID-bound and window-only.
- Finish with one commit named `fix: address final vitality review`.

---

### Task 1: Capture Presence Ambiguity RED

**Files:**
- Modify: `Tests/PetHUDCoreTests/PetWindowLocatorTests.swift`
- Modify: `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`
- Modify: `Tests/PetHUDCoreTests/ApplicationModelTests.swift`
- Modify: `Tests/PetHUDCoreTests/PetWindowDiagnosticStatusTests.swift`

**Interfaces:**
- Consumes: `PetWindowLocator.observe(from:)`, `PetPresenceTracker.update(observation:now:)`, `ApplicationModel.reduce(_:)`, and `PetWindowDiagnosticStatus.resolve(...)`.
- Produces: Regression coverage requiring explicit ambiguity, grace-period expiry, hidden application presentation, and diagnostic `missing`.

- [ ] **Step 1: Add locator regression**

Add a same-PID duplicate exact-window fixture and assert:

```swift
XCTAssertNil(observation.exactWindow)
XCTAssertNil(observation.visualGeometry)
XCTAssertTrue(observation.hasExactWindowAmbiguity)
```

- [ ] **Step 2: Add tracker expiry regression**

Confirm one healthy shell geometry, feed the same ambiguous observation at `+0.5s`, `+1.5s`, and `+2.5s`, then assert geometry is retained for the first two observations and cleared on the third.

- [ ] **Step 3: Add application regression**

Route locator observations through a tracker and `ApplicationModel`; assert the HUD remains visible during grace and hides after the third ambiguous observation spanning two seconds.

- [ ] **Step 4: Add diagnostic regression**

Resolve a same-PID duplicate exact-window observation with matching cached geometry and assert `.missing`.

- [ ] **Step 5: Verify RED**

Run:

```bash
swift test --filter 'PetWindowLocatorTests|PetPresenceTrackerTests|ApplicationModelTests|PetWindowDiagnosticStatusTests'
```

Expected: compilation failure because `hasExactWindowAmbiguity` does not exist, proving the observation model lacks the required state.

### Task 2: Capture Privacy and Documentation RED

**Files:**
- Modify: `Tests/Shell/release-validation.bats`
- Modify: `Tests/Shell/skill-validation.bats`

**Interfaces:**
- Consumes: Published Markdown under `docs/` and `skills/codex-pet-hud/`.
- Produces: Guards against line-printing scans, orange `MAX`, and visible manifest-name claims.

- [ ] **Step 1: Extend privacy procedure guard**

Include `docs/privacy.md` in `line_printing_scan_pattern` enforcement and require the published procedure to use `rg -q`, a generic error, and an explicit nonzero exit.

- [ ] **Step 2: Add architecture guard**

Require `full sky-blue \`MAX\`` and reject `orange \`MAX\`` in `docs/architecture.md`.

- [ ] **Step 3: Add skill guard**

Require the skill to state that the current four-row HUD does not render the manifest display name and reject the old visible-name claim.

- [ ] **Step 4: Verify RED**

Run:

```bash
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
```

Expected: release validation rejects `docs/privacy.md`; skill validation rejects the current visible-name claim.

### Task 3: Implement Minimal Root-Cause Fix

**Files:**
- Modify: `Sources/PetHUDCore/PetWindowLocator.swift`
- Modify: `Sources/PetHUDCore/PetPresenceTracker.swift`
- Modify: `docs/privacy.md`
- Modify: `docs/architecture.md`
- Modify: `skills/codex-pet-hud/SKILL.md`

**Interfaces:**
- Consumes: Existing exact-window filtering and existing absence grace state.
- Produces: `PetWindowObservation.hasExactWindowAmbiguity: Bool`.

- [ ] **Step 1: Expose exact ambiguity**

Add a defaulted observation property:

```swift
public let hasExactWindowAmbiguity: Bool
```

Compute exact candidates once in `observe(from:)`, set the selected exact window only when the count is one, and set ambiguity when the count exceeds one.

- [ ] **Step 2: Route ambiguity through absence**

Only accept `visualGeometry` or `hasStablePresence` as confirmed presence when `hasExactWindowAmbiguity` is false. Leave the existing PID mismatch and grace-period state machine unchanged.

- [ ] **Step 3: Publish quiet privacy scan**

Replace line-printing search with:

```bash
if rg -q "$scan_pattern" "${release_content[@]}"; then
  printf 'Release privacy scan failed.\n' >&2
  exit 1
fi
```

- [ ] **Step 4: Align final docs**

Describe unlimited MP as full sky-blue `MAX`; state that standard manifest metadata selects the pet but the current four-row HUD does not render its name.

- [ ] **Step 5: Verify GREEN**

Run focused locator, tracker, application, diagnostic, release, and skill suites and require zero failures.

### Task 4: Validate, Install, and Report

**Files:**
- Create: `.superpowers/sdd/final-vitality-review-fix-report.md`

**Interfaces:**
- Consumes: Complete source and documentation changes.
- Produces: Clean release evidence, installed `0.4.0`, live runtime verification, and final commit.

- [ ] **Step 1: Run one clean gate**

Run all Swift tests, all eight shell suites, production build, strict codesign verification, and `git diff --check`.

- [ ] **Step 2: Reinstall current version**

Install `0.4.0` for `$HOME/.codex/pets/yicha`.

- [ ] **Step 3: Verify live runtime**

Require one running HUD process, zero mock processes, zero effect windows, healthy host-authorized redacted diagnostics, and a successful HUD-only capture.

- [ ] **Step 4: Preserve screenshot**

Do not modify the checked-in screenshot because this fix changes no rendered pixels.

- [ ] **Step 5: Write report**

Record root cause, RED/GREEN outputs, files, test counts, install/runtime state, self-review, and concerns in the required report.

- [ ] **Step 6: Commit once**

```bash
git add Sources Tests docs skills .superpowers/sdd/final-vitality-review-fix-report.md
git commit -m "fix: address final vitality review"
```
