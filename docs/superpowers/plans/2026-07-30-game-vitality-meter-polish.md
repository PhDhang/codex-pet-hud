# Game Vitality Meter Polish Implementation Plan

> **Spec:** `docs/superpowers/specs/2026-07-30-game-vitality-meter-polish.md`

## Global Constraints

- HP uses the specified blood-red gradient.
- MP uses the specified sky-blue gradient.
- Normal measured values below `100%` use a same-palette highlight at
  `10–20%` opacity moving left to right.
- `MAX`, exactly `100%`, unavailable values, danger states, and Reduce Motion
  never show the flowing highlight.
- HP danger is blood red ↔ white; MP danger is sky blue ↔ white.
- Canonical `4–9%` remains a `0.9s` autoreversing pulse.
- Canonical `0–3%` remains a `0.45s` stronger autoreversing pulse.
- Reduce Motion disables all meter motion.
- Lit SP flames have a `1.10` base scale.
- HP and MP remain independent.
- No pet effects, replacement, extra windows, five-hour countdown, secrets,
  raw payloads, or non-HUD screen capture.
- Preserve macOS 14, level-4 ordering, render caching, movement, resize, and
  idle presence.

### Task 1: Add a Testable Meter Motion Policy

**Files:**
- Create: `Sources/PetHUDCore/QuotaMeterMotionPolicy.swift`
- Create: `Tests/PetHUDCoreTests/QuotaMeterMotionPolicyTests.swift`

- [ ] Add failing tests for safe measured flow, exact `100%`, `MAX`,
  unavailable, low, critical, and Reduce Motion.
- [ ] Verify RED with:

```bash
swift test --disable-sandbox --filter QuotaMeterMotionPolicyTests
```

- [ ] Implement a pure policy that returns whether flow is allowed and the
  pulse duration for the current state.
- [ ] Verify GREEN with the focused suite.
- [ ] Commit:

```bash
git commit -m "feat: define vitality meter motion policy"
```

### Task 2: Render RPG Colors, Flow, and Enlarged Flames

**Files:**
- Modify: `Sources/CodexPetHUD/QuotaMeterFillView.swift`
- Modify: `Sources/CodexPetHUD/TacticalHUDView.swift`
- Modify: `Sources/CodexPetHUD/FlameCellView.swift`
- Modify: `Tests/Shell/tactical-ui.bats`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `skills/codex-pet-hud/SKILL.md`

- [ ] Add failing source guards for blood-red and sky-blue palette tokens,
  same-palette flow, clipping, static `MAX`/`100%`, danger flow suppression,
  Reduce Motion suppression, red↔white and blue↔white danger, and `1.10` lit
  flame scale.
- [ ] Verify RED:

```bash
bash Tests/Shell/tactical-ui.bats
```

- [ ] Refactor `QuotaMeterFillView` to accept a gradient palette, render a
  clipped moving highlight only when the pure policy permits it, and retain
  the robust explicit pulse cancellation lifecycle.
- [ ] Update HP to blood red and MP to sky blue. Keep `MAX` centered.
- [ ] Make dangerous HP/MP pulse to white with existing slow/critical timing.
- [ ] Make lit flames `1.10` scale while preserving flicker and Reduce Motion.
- [ ] Update product and reusable-skill documentation.
- [ ] Verify:

```bash
swift test --disable-sandbox --filter QuotaMeterMotionPolicyTests
swift test --disable-sandbox --filter HUDPresentationDataTests
bash Tests/Shell/tactical-ui.bats
bash Tests/Shell/release-validation.bats
bash Tests/Shell/skill-validation.bats
swift build --disable-sandbox
git diff --check
```

- [ ] Commit:

```bash
git commit -m "feat: polish HP MP and SP visuals"
```

### Task 3: Reinstall, Visually Verify, and Replace the Screenshot

**Files:**
- Replace: `docs/screenshots/tactical-hud.png`

- [ ] Run all Swift and shell tests, production build, and strict codesign.
- [ ] Install version `0.4.0` for
  `$HOME/.codex/pets/yicha`.
- [ ] Verify real `MAX`, measured MP, safe flowing HP/MP, exact `100%` static,
  low and critical white pulses, Reduce Motion static behavior, SP `110%`
  scale, movement, resize, and idle persistence.
- [ ] Use only `scripts/capture-hud.sh`; inspect the HUD-only output and confirm
  no desktop or other app content is present.
- [ ] Replace and commit the screenshot:

```bash
git commit -m "docs: refresh vitality HUD screenshot"
```

- [ ] Restore the real LaunchAgent/provider state and confirm one real process,
  zero mock processes, healthy redacted diagnostics, and a clean worktree.
- [ ] Request a whole-branch review and fix all Critical/Important findings.
- [ ] Push the feature branch and update draft PR `#1`; do not merge.
