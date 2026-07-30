# Final Vitality Review Fix Report

Date: 2026-07-30

## Status

All listed final whole-branch review findings are fixed and verified. The
installed runtime remains version `0.4.0`; no rendered pixels or checked-in
screenshot changed.

## Root Cause

`PetWindowLocator.select(from:)` already rejected more than one exact
`Codex Pet Mascot Effect` window by returning `nil`. The independent
`stablePresence(in:)` path reduced every exact mascot candidate to a
`Set<ownerPID>`, however. Two exact windows from one ChatGPT PID therefore
collapsed to one stable-presence PID.

The resulting `PetWindowObservation` carried:

- no selected exact window;
- no visual geometry;
- `hasStablePresence == true`;
- the retained geometry's same owner PID.

`PetPresenceTracker` treated that stable-presence bit as confirmation on every
sample, reset its absence timer indefinitely, and kept returning prior geometry.
`PetWindowDiagnosticStatus` created the same false positive from matching cached
geometry and could report `found`.

## Fix

- Added `PetWindowObservation.hasExactWindowAmbiguity`, defaulting to `false`
  for source compatibility with existing explicit observations.
- Made `PetWindowLocator.observe(from:)` preserve exact-window cardinality and
  set the ambiguity bit when more than one exact candidate exists.
- Made `PetPresenceTracker` refuse both candidate geometry and stable-presence
  confirmation while that ambiguity bit is set.
- Reused the existing absence path unchanged: live retained geometry survives
  the first two ambiguous observations, then expires on the third observation
  spanning at least two seconds.
- Preserved immediate diagnostic fail-closed behavior: a fresh diagnostic
  tracker has no confirmed live presence, so ambiguous exact windows resolve to
  `missing` even when matching cached geometry exists.
- Changed the published privacy procedure from line-printing `rg -n` to
  quiet `rg -q` detection with only `Release privacy scan failed.` on stderr
  and exit `1`.
- Extended release validation to scan `docs/privacy.md` for line-printing
  ripgrep flags and require the quiet generic-error procedure.
- Updated architecture wording to full sky-blue `MAX`.
- Updated the reusable skill to state that the current four-row HUD does not
  render the manifest display name.

## RED Evidence

### Initial API RED

Before source changes, the four focused test files failed to compile because
`PetWindowObservation` had no `hasExactWindowAmbiguity` member. The compiler
reported the missing member in locator, tracker, and diagnostic tests.

### Documentation RED

- `bash Tests/Shell/release-validation.bats` exited `1` with the fixed guard
  message `Forbidden-content scans must never print matched lines.`
- `bash Tests/Shell/skill-validation.bats` exited `1` because the required
  non-rendered manifest-name statement was absent.

### Controlled Old-Behavior Mutation

After GREEN, the old tracker presence condition was restored temporarily while
the explicit locator state remained. The four same-PID tests executed with:

- 4 tests;
- 3 expected failures;
- 1 locator-state pass.

The failures were exact:

- application HUD remained visible instead of hiding after grace;
- tracker returned retained shell geometry instead of `nil`;
- diagnostics returned `found` instead of `missing`.

Restoring the production condition returned all 4 tests to GREEN.

## GREEN Evidence

### Focused Suites

- Locator, tracker, application, and diagnostic Swift suites:
  60 tests, 0 failures.
- Same-PID targeted mutation-restoration suite:
  4 tests, 0 failures.
- `Tests/Shell/diagnostics.bats`: exit `0`.
- `Tests/Shell/release-validation.bats`: exit `0`.
- `Tests/Shell/skill-validation.bats`: exit `0`.

The focused suite retained passing coverage for:

- one exact mascot window;
- idle stable presence;
- shell-derived movement and resize;
- high-confidence geometry retention;
- normal three-observation/two-second absence expiry.

### Full Clean Gate

The gate began with `swift package clean` and ran once:

- all Swift tests: 144 tests, 0 failures;
- all shell suites: 8 of 8 passed;
- production release build: passed;
- strict deep codesign verification: passed;
- `git diff --check`: passed.

The eight shell suites were:

1. `build-app.bats`
2. `diagnostics.bats`
3. `install-cycle.bats`
4. `install-from-source.bats`
5. `main-actor.bats`
6. `release-validation.bats`
7. `skill-validation.bats`
8. `tactical-ui.bats`

The source-install shell suite also rebuilt and exercised the committed branch
baseline in its isolated clone, where 140 pre-fix Swift tests passed.

## Files

### Runtime

- `Sources/PetHUDCore/PetWindowLocator.swift`
- `Sources/PetHUDCore/PetPresenceTracker.swift`

### Regressions and Guards

- `Tests/PetHUDCoreTests/PetWindowLocatorTests.swift`
- `Tests/PetHUDCoreTests/PetPresenceTrackerTests.swift`
- `Tests/PetHUDCoreTests/ApplicationModelTests.swift`
- `Tests/PetHUDCoreTests/PetWindowDiagnosticStatusTests.swift`
- `Tests/Shell/release-validation.bats`
- `Tests/Shell/skill-validation.bats`

### Documentation

- `docs/privacy.md`
- `docs/architecture.md`
- `skills/codex-pet-hud/SKILL.md`
- `docs/superpowers/plans/2026-07-30-final-vitality-review-fixes.md`
- `.superpowers/sdd/final-vitality-review-fix-report.md`

## Install and Runtime State

- Built and installed `Codex Pet HUD.app` version `0.4.0`.
- Installed for the explicit pet path `$HOME/.codex/pets/yicha`.
- The prerequisite scan found two valid v2 pets; the explicit Yicha path
  removed pet-selection ambiguity.
- Installed strict codesign verification passed.
- Real installed HUD processes: `1`.
- Mock processes: `0`.
- Effect windows: `0`; the PID-bound HUD capture guard passed.
- LaunchAgent arguments contain only the installed real executable.
- Host-authorized redacted diagnostics exited `0` with:
  - `configuration=ok`
  - `pet=found`
  - `petWindow=found`
  - `provider=reachable`
  - `fiveHourStatus=max`
- The diagnostic JSON contained no token, account, email, cookie, credential,
  bearer, or API-key field/value.
- HUD-only capture succeeded at `240 × 86` with alpha. Direct inspection showed
  only the tactical four-row HUD.
- The capture was temporary; `docs/screenshots/tactical-hud.png` was not
  modified because the fix changes no visual pixels.

## Self-Review

- Confirmed ambiguity is represented at the locator boundary where exact
  cardinality is still available.
- Confirmed the tracker reuses the established grace state machine instead of
  adding a second timer or special expiry path.
- Confirmed cached geometry does not revive a cold ambiguous diagnostic.
- Confirmed single-window idle, movement, resize, and fallback behavior remain
  unchanged in passing tests.
- Confirmed the privacy procedure cannot print matched sensitive lines and its
  failure message contains no matched content.
- Confirmed the documentation now matches full sky-blue `MAX` and the visible
  four-row view.
- Confirmed no AppKit view, layout, asset, screenshot, version, provider, or
  cache format changed.
- Reviewed the complete diff for unrelated changes; none are included.

## Concerns

No release-blocking concern remains.

The selected Yicha directory still contains three pre-existing legacy
`hud-*` asset files from an older removed feature. Version `0.4.0` does not
reference or load them, the LaunchAgent has no effect arguments, and live
verification found zero effect windows. They were intentionally left untouched
because the current installer does not own or delete user pet files.

## Cosmetic Merge Follow-Up

The final reviewer approved merge with one whitespace-only Minor. The extra
blank line at EOF in the game vitality meter polish specification was removed;
no specification content, runtime behavior, visual output, or screenshot
changed.
