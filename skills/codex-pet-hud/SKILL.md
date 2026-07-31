---
name: codex-pet-hud
description: Use when a macOS 14 Codex v2 pet needs a live tactical quota HUD, idle-presence diagnostics, HP/MP/SP bars, source installation, repair, or safe removal.
---

# Codex Pet HUD

## Overview

Install and verify the macOS companion that centers a tactical HP, MP, and
seven-flame SP HUD above one selected Codex v2 pet with standard `pet.json`
metadata. Keep credentials local, fail closed on ambiguous windows or pets, and
use redacted diagnostics.

## Safety Rules

- Read `${CODEX_HOME:-$HOME/.codex}/auth.json` only through the app.
- Never print tokens, account IDs, emails, cookies, or raw provider responses.
- Never read browser cookies or request Accessibility or Screen Recording.
- Select exactly one v2 pet; do not guess when checks find multiple candidates.
- Prefer the native mascot window. With title-redacted LaunchAgent windows,
  require same PID companion evidence including a layer-3 voice backing with
  width 20...32 and height 6...80; accept compact and expanded backing while it
  animates, and hide on ambiguity.
- Build and test before installing.

## Workflow

1. Require macOS 14 and validate prerequisites:

```bash
scripts/check-prerequisites.sh
```

If more than one v2 pet is reported, ask the user to choose one exact pet
directory. Resolve source from the project root, bundled public repository,
`CODEX_PET_HUD_REPO_URL`, or an explicit `--repo` fork.

2. For a local repository checkout, run Swift and shell tests before
installation:

```bash
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
```

3. Build and install the checked repository:

```bash
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
```

For remote source installation, the installer clones and checks out the source
first, runs the same Swift and non-recursive shell checks, then builds and
installs only when those checks pass:

```bash
skills/codex-pet-hud/scripts/install-from-source.sh --ref main --pet-path "$PET_PATH"
```

4. Diagnose without exposing credentials:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" --diagnose
```

Require `configuration=ok`, `pet=found`, `petWindow=found`, and
`provider=reachable`. `fiveHourStatus` is `measured`, `max`, `unavailable`, or
`skipped`; it never includes a reset time or provider payload. Exit `5` means
the pet overlay is closed. Stable presence keeps the tactical HUD visible while
the task is idle.

5. Verify idle linkage: with no active task, move and resize the pet. The tactical
HUD stays centered and follows movement, then recovers after mascot reconstruction.
It hides only after three absent observations spanning at least two seconds.

## Tactical Alignment

Edit `~/.config/codex-pet-hud/config.json`, then restart the LaunchAgent:

- `podScale`: tactical HUD size, `0.65...1.6`; use `0.90` compact, `1.14`
  default, or `1.35` roomy.
- `podOffsetX`: `-300...300` points; positive moves right.
- `podOffsetY`: `-300...300` points; positive moves up.

```bash
launchctl kickstart -k gui/$(id -u)/com.codex-pet-hud.agent
```

Missing keys use defaults; legacy `nameplateOffset` does not move the tactical HUD.

## HP, MP, Flame, and Low-Quota States

HP is weekly quota with a blood-red gradient. MP is the measured five-hour percentage or sky-blue `MAX`.
HP and MP values are centered inside the bars.
SP reset time is accessibility-only and has no visible suffix.
Safe measured values below `100%` carry a subtle same-color flow.
Exactly `100%`, `MAX`, unavailable data, danger states, and Reduce Motion have
no meter flow. Danger pulses HP or MP independently to white at `0.9s` or `0.45s`.
Reduce Motion leaves bright identity colors static instead of pulsing to white.
Seven SP flame cells show weekly reset progress: lit red/orange/yellow, unlit
blue/cyan/ice-blue. Lit SP flames use a `1.10` base scale with bottom-anchored
flicker that stops under Reduce Motion.
Fresh `4–9%` quota changes the HUD to the red `PANIC · QUOTA LOW` label. Fresh
`≤3%` quota changes it to the bright-red `EXHAUSTED · SIGNAL CRITICAL` label.
These are HUD-only label and color changes. The HUD never changes the native pet:
there is no pet animation or replacement. Stale and missing data retain their
normal HUD state without changing the native pet.

For screenshots, use `scripts/capture-hud.sh OUTPUT`. It resolves exactly one
on-screen tactical window and captures that window ID only. This window-only screenshot rejects any pet-effect window and never captures a rectangle of the
desktop or windows beneath the translucent HUD.

## Pet Compatibility

The HUD requires only standard v2 `pet.json` metadata. The current four-row HUD does not render the manifest display name.
It leaves the native rendering untouched. Do not add repository files to the
selected pet directory.

## Repair and Rollback

- Read `references/troubleshooting.md` only when diagnostics, idle presence, or
  installation fails.
- Keep settings while removing the app and LaunchAgent:

```bash
scripts/uninstall.sh
```

- Remove settings too:

```bash
scripts/uninstall.sh --purge
```

`--purge` also removes the quota snapshot, geometry cache, and app logs.

## Bundled Tools

- `scripts/check-prerequisites.sh`: inspect macOS, Swift, auth presence, and v2 pets.
- `scripts/install-from-source.sh`: clone, test, build, install, and diagnose a ref.
- `references/troubleshooting.md`: exit codes and targeted recovery steps.
