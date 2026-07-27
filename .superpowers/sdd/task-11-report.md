# Task 11 Final-Review Verification Report

Verification completed: 2026-07-27 19:32 CST

## Scope and Safety

- Branch: `feature/tactical-dual-bar-hud`
- Final-review base:
  `cc1e987e72aded50d55a3c23fb9088ea41a94288`
- Final re-review base:
  `f958958705397ddd3c69543d46208f7718b54644`
- Live alignment blocker base:
  `23565bc6029452b91e2bde2af5a0301be07f874d`
- Verified implementation HEAD:
  `3d3bf2758baf8d7906e943457d41ed4ebffbc32f`
- No persistent app, LaunchAgent, pet asset, or Skill installation occurred.
- Install and uninstall tests used temporary isolated `HOME` directories.
- No GUI application was launched.
- No branch push, pull request, tag, release, or publication occurred.

## Separate Commits

1. `ace0fc4ab19fe44bff6de374d59e80e6de1510e9`
   `fix: preserve fractional hp labels`
2. `d35ec925baec1e468e95db4007e11df32f91a446`
   `fix: bind retained geometry to presence pid`
3. `1b89e73258d549dff4a8811b3e4dc2f4c1f20bca`
   `fix: contain pet effects at display edges`
4. `e8d512d2089ae7015e5048914e3b0800e9d13b91`
   `fix: make pet effect optional in hud capture`
5. `7ad615c34c59720389f9565ca5b1bd1458100725`
   `docs: remove obsolete critical screenshot`
6. `6823e312ee8ab2459ee82937da0a641365826a62`
   `fix: canonicalize visible hp precision`
7. `c02223948479c6cd55cd1c0cf7a84ad08eabf200`
   `fix: fail closed on ambiguous presence pids`
8. `68d524b4f7f5b489d3e11609ac2faff9c730027f`
   `fix: keep critical art centered at edges`
9. `e1d97cdfdbd56ed2b3b855c11b8c7a440ef66249`
   `fix: model contained native pet cover`
10. `1f7f264b4d6ba559e057280ece26aa27755a2cf9`
    `fix: require companion evidence for shell presence`
11. `3d3bf2758baf8d7906e943457d41ed4ebffbc32f`
    `fix: center shell-sized effects on mascot`
12. `155dccae7e58cab5bbe70726310c5507ded7f39d`
    `fix: raise pet replacement above mascot`
13. `a8e5756c247e80565df45a13f3bb7caf23549050`
    `test: enforce injected click-through panel level`
14. `220af232950505c5026a0a92e5a486ced760eabe`
    `test: prevent click-through panel level resets`
15. `2252534e456b78e3269bf4f8952a1d98cbe89770`
    `test: count click-through panel level assignments`

## Strict TDD Evidence

### Canonical HP

- RED: ordinary one-decimal rounding moved `9.96` into the `10.0` band and
  allowed `99.96` to display as `100.0`.
- GREEN: one canonical HP value clamps to `0...100`, floors toward zero to a
  tenth, and drives bands, hysteresis, fill, and labels. Integral canonical
  values omit the decimal; fractional values use one decimal.
- Coverage spans floating values around `3`, `4`, `9`, `10`, `50`, `51`,
  `90`, `91`, and `100`, plus critical recovery hysteresis and compact
  five-character label capacity.
- Evidence:
  `.superpowers/sdd/final-rereview-artifacts/red-hp.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-hp.log`

### Stable Presence PID

- RED: exact mascot, named shell, named composition, and title-redacted
  signals could independently return early and hide cross-signal PID
  ambiguity.
- GREEN: one candidate PID set spans exact mascot, named companion, and
  complete redacted-cluster signals. Exactly one PID qualifies; multiple
  named, exact, mixed named/redacted, or redacted candidates fail closed and
  cannot revive retained or restored geometry.
- Final P1 RED: a lone generic layer-3 `Codex` shell independently qualified
  as stable presence and revived matching restored geometry. Shell-derived
  geometry could also use a PID different from the qualifying companion.
- Final P1 GREEN: the visual shell is geometry corroboration only. A lone
  shell reports no stable PID and cannot revive cache; shell-derived geometry
  requires the unique qualifying companion PID. Exact mascot and valid named
  companion behavior remains stable.
- Evidence:
  `.superpowers/sdd/final-rereview-artifacts/red-presence.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-presence.log`,
  `.superpowers/sdd/final-rereview-artifacts/red-lone-shell.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-lone-shell.log`

### Live Mascot-Centered Shell Geometry

- Live 8% evidence showed the exact mascot at
  `x30 y643 249x259`, center `(154.5, 772.5)`, while the qualifying
  layer-3 `Codex` shell was `x0 y709 384x126`, center `(192, 772)`.
  Using the shell midpoint placed the native pet and replacement side by
  side.
- RED: the exact live offset, the prior live fixture, movement/resize, and
  persisted cache bounds all reported the shell midpoint instead of the
  exact mascot midpoint. The focused run executed `37` tests with `9`
  expected assertion failures. Shell-derived size/source assertions and
  mascot fallback behavior remained correct.
- GREEN: shell height remains the visual-size authority and PID
  corroboration. The exact mascot midpoint is the visual X/Y authority.
  The live frame is `126 * 192 / 208` by `126`, centered at
  `(154.5, 772.5)`, remains `.shellDerived`, follows mascot movement and
  resize, and persists those corrected bounds to the geometry cache.
- Evidence:
  `.superpowers/sdd/live-alignment-artifacts/red-focused.log`,
  `.superpowers/sdd/live-alignment-artifacts/green-focused-refactor.log`

### Effect Containment

- RED: contained scale-2 critical art translated away from the pet at all
  four display edges; the native cover had no modeled envelope and emitted an
  external shadow.
- GREEN: critical art shrinks symmetrically around the unchanged pet center.
  The explicit `1.10x1.08` native cover envelope intersects the panel only
  where display clamping makes the full envelope impossible, still covering
  every onscreen native-pet pixel. Cover output is clipped with no shadow.
- Coverage includes:
  - visual pet `116.3x126`
  - left, right, top, and bottom display edges
  - asymmetric available left and right panic travel
  - custom critical scales `1` and `2`
  - `140x140` small display
  - horizontally and vertically arranged displays
  - centered Yicha critical scales `1` and `2`
  - exact-one-character cover shell contract
- Evidence:
  `.superpowers/sdd/final-rereview-artifacts/red-critical.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-critical.log`,
  `.superpowers/sdd/final-rereview-artifacts/red-cover-swift.log`,
  `.superpowers/sdd/final-rereview-artifacts/red-cover-shell.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-cover-swift.log`,
  `.superpowers/sdd/final-rereview-artifacts/green-cover-shell.log`

### Capture Contract

- RED: capture required both tactical and effect panel titles, rejecting a
  healthy tactical-only state.
- GREEN: exactly one tactical panel is required; zero-or-one visible effect
  panel is optionally unioned for low and critical states.
- Evidence:
  `.superpowers/sdd/final-review-artifacts/red-capture-shell.log`,
  `.superpowers/sdd/final-review-artifacts/green-capture-shell.log`

### Release Documentation

- RED: release validation found the obsolete critical screenshot reference
  and lacked explicit shell-only cache semantics.
- GREEN:
  - obsolete `docs/screenshots/tactical-hud-critical.png` removed
  - README uses tracked `Examples/yicha/hud-critical.png`
  - live panic and critical recapture documented as pending before release
  - architecture states only shell-derived geometry is cached
  - mascot fallback geometry is explicitly transient
- Evidence:
  `.superpowers/sdd/final-review-artifacts/red-docs-release.log`,
  `.superpowers/sdd/final-review-artifacts/green-docs-release.log`

## Complete Verification

### Swift

Command:

```bash
swift test --disable-sandbox
```

Result:

- `141` tests
- `0` failures
- Exit `0`
- Evidence:
  `.superpowers/sdd/live-alignment-artifacts/full-swift-final.log`

### Shell

Every suite passed:

| Suite | Result |
| --- | --- |
| `Tests/Shell/build-app.bats` | PASS |
| `Tests/Shell/install-cycle.bats` | PASS |
| `Tests/Shell/install-from-source.bats` | PASS |
| `Tests/Shell/main-actor.bats` | PASS |
| `Tests/Shell/release-validation.bats` | PASS |
| `Tests/Shell/skill-validation.bats` | PASS |
| `Tests/Shell/tactical-ui.bats` | PASS |

Evidence:
`.superpowers/sdd/live-alignment-artifacts/all-shell-final-summary.txt`

### Signed Build and Install Cycle

- `codesign --verify --deep --strict --verbose=4`: exit `0`
- Signature: ad hoc, arm64
- Identifier: `com.codex-pet-hud.app`
- CDHash: `194ab0893ecc0a42a750e3a47f34c369565a6b3c`
- `CFBundleShortVersionString`: `0.3.0`
- `CFBundleVersion`: `3`
- Binary SHA-256:
  `566ede8c728e1e6823afe6cd6c82d705b5888788d045a4682d6e5aca8e173737`
- Isolated install, ordinary uninstall, and purge uninstall passed.
- Evidence:
  `.superpowers/sdd/live-alignment-artifacts/final-exact-head-gates.log`,
  `.superpowers/sdd/live-alignment-artifacts/final-shell-install-cycle.log`

### Final Gates

- Release scan: exit `0`
- Working-tree `git diff --check`: exit `0`
- Base-to-HEAD diff check: exit `0`
- Final working tree: clean

## Remaining Concern

- Live healthy, panic, and critical screenshots still require recapture from
  the running app before release. This run intentionally did not fabricate a
  screenshot, launch the GUI, persist an installation, or publish anything.

## Final Live Z-Order Fix

Verification completed: 2026-07-27 19:40 CST

### Supplied Live Evidence and Root Cause

- The supplied effect-only capture renders exactly one custom panic pet.
- The supplied native-only capture renders the original ChatGPT mascot.
- Their union renders both because the replacement effect panel was at
  `.floating`, below the ChatGPT Mascot window.

The root cause was a shared `ClickThroughPanel` initializer that assigned
`.floating` unconditionally to both the tactical HUD and pet-effect panels.

### Fix and Preserved Behavior

- `ClickThroughPanel` now accepts an explicit public `NSWindow.Level`.
- `PetEffectPanelController` requests `.statusBar`, placing the replacement
  above the native mascot without private APIs or extra permissions.
- `TacticalHUDPanelController` explicitly retains `.floating`.
- The existing `.nonactivatingPanel`, `ignoresMouseEvents = true`,
  `.canJoinAllSpaces`, `.fullScreenAuxiliary`, and non-key/non-main behavior
  remain unchanged.

### Strict TDD Evidence

- RED: `bash Tests/Shell/tactical-ui.bats` exited `1` after adding a source
  contract requiring `level: .statusBar` in the effect controller and
  `level: .floating` in the tactical controller. The effect assertion was
  absent before the implementation.
- GREEN: the same focused shell contract exited `0` after the smallest change:
  parameterize the shared initializer, pass `.statusBar` to the effect, and
  pass `.floating` explicitly to tactical HUD.

### Verification at Implementation Commit

- `swift test --disable-sandbox`: `141` tests, `0` failures, exit `0`.
- Every `Tests/Shell/*.bats` suite: exit `0`, including source contracts,
  signed build, and isolated install/uninstall cycles.
- `scripts/build-app.sh` produced an ad-hoc signed bundle and its strict
  `codesign` verification succeeded; no persistent installation occurred.
- `git diff --check` and the base-to-change diff check against
  `305c256c688197c0b53d3f5ce9b00df585d04a57` exited `0` before commit.
- No GUI application, persistent install, publish, branch push, pull request,
  tag, or release was performed for this fix.

## Reviewer Follow-Up: Initializer-Level Window Contract

Verification completed: 2026-07-27 19:45 CST

The original z-order contract checked only the effect and tactical call-site
arguments. It could not detect an initializer that ignored the injected level
or reset it later.

- The shell contract now extracts the `ClickThroughPanel` initializer body,
  requires `self.level = level`, and rejects hard-coded `.floating` or
  `.statusBar` assignment inside that initializer.
- RED (ignored injection): temporarily replacing `self.level = level` with
  `self.level = .floating` made `bash Tests/Shell/tactical-ui.bats` exit `1`
  at the injected-assignment contract.
- RED (post-assignment reset): temporarily adding `self.level = .floating`
  after the injected assignment made the same command exit `1` with
  `Click-through panel must not reset its injected window level.`
- GREEN: restoring the single injected assignment made the focused tactical
  shell contract exit `0`.
- `swift test --disable-sandbox`: `141` tests, `0` failures, exit `0`.
- All seven `Tests/Shell/*.bats` suites completed with exit `0`, including
  signed build and isolated install-cycle validation.
- `git diff --check` passed before the test commit.

## Reviewer Follow-Up: Qualified Level Reset Bypass

Verification completed: 2026-07-27 19:49 CST

The prior reset check matched only `level = .` syntax, so a qualified RHS such
as `NSWindow.Level.floating` could bypass it.

- The source contract extracts the `ClickThroughPanel` initializer, collects
  every assignment whose target ends in `level`, requires exactly one such
  assignment, then normalizes it and requires `self.level = level`.
- RED: adding `self.level = .floating` after the injected assignment made
  `bash Tests/Shell/tactical-ui.bats` exit `1` with the exactly-once failure.
- RED: replacing that mutation with `self.level = NSWindow.Level.floating`
  produced the same exactly-once failure.
- GREEN: restoring only `self.level = level` made the focused tactical shell
  contract exit `0`.
- All seven `Tests/Shell/*.bats` suites passed, including the isolated source
  install suite and its `141` Swift tests; `git diff --check` passed before
  the test commit.

## Reviewer Follow-Up: Same-Line Assignment Bypass

Verification completed: 2026-07-27 19:52 CST

The previous structural check counted matching lines, allowing two assignments
on one semicolon-separated line to appear as one assignment.

- The contract now uses `grep -o` to count every `(self.)?level =` token in
  the extracted initializer, requiring exactly one occurrence. A Perl
  extraction removes whitespace and requires the sole assignment to equal
  `self.level=level`.
- RED: separate-line `self.level = .floating` and
  `self.level = NSWindow.Level.floating` resets each fail the token count.
- RED: `self.level = level; self.level = NSWindow.Level.floating` on one line
  also fails the token count.
- GREEN: restoring only `self.level = level` makes the focused tactical shell
  contract exit `0`.
- All seven `Tests/Shell/*.bats` suites passed, including signed build,
  temporary-home install cycle, and the isolated source-install suite with
  `141` Swift tests; `git diff --check` passed before the test commit.
