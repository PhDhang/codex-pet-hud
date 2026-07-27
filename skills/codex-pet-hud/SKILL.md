---
name: codex-pet-hud
description: Use when a macOS 14 Codex v2 pet needs a live tactical quota HUD, idle-presence diagnostics, HP/SP bars, panic or critical effects, source installation, repair, or safe removal.
---

# Codex Pet HUD

## Overview

Install and verify the macOS companion that centers a tactical HP and seven-flame
SP HUD above one selected Codex v2 pet. Keep credentials local, fail closed on
ambiguous windows or assets, and use redacted diagnostics.

## Safety Rules

- Read `${CODEX_HOME:-$HOME/.codex}/auth.json` only through the app.
- Never print tokens, account IDs, emails, cookies, or raw provider responses.
- Never read browser cookies or request Accessibility or Screen Recording.
- Select exactly one v2 pet; do not guess when checks find multiple candidates.
- Prefer `Codex Pet Mascot Effect`. With title-redacted LaunchAgent windows,
  require same PID companion evidence including a layer-3 `20...32` point voice
  control; hide on ambiguity.
- Build and test before installing or copying assets.

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
`provider=reachable`. Exit `5` means the pet overlay is closed. Stable presence
keeps the tactical HUD visible while the task is idle.

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

## HP, Flame, Panic, and Critical States

HP is weekly quota. Seven SP flame cells show elapsed reset progress: lit
red/orange/yellow, unlit blue/cyan/ice-blue. Fresh `4–9%` quota replaces the pet
with a compact panic run. Fresh `≤3%` quota replaces the pet with critical art,
which clears only above `5%`. These states are not HUD content. Stale or missing
data never enables panic or critical effects.

## Optional Pet Effects

- Generic fallback: standard directional running frames, non-facial aura, no procedural eye overlay.
- Custom strip: integrated eye art; legacy eye anchors may be omitted.

Yicha ships the custom strip; the runtime mirrors its right-running frames for
left travel. For custom panic, critical art, or a new pet, **REQUIRED
SUB-SKILL:** Use `hatch-pet`; do not generate, rotate, or composite facial
artwork in this Skill.

Copy optional effects only after confirming the selected pet directory and example files exist:

```bash
test -d "$PET_PATH"
test -f Examples/yicha/hud-panic.png
test -f Examples/yicha/hud-critical.png
test -f Examples/yicha/hud-effects.json
cp -n Examples/yicha/hud-panic.png "$PET_PATH/hud-panic.png" ||
  test -e "$PET_PATH/hud-panic.png"
cp -n Examples/yicha/hud-critical.png "$PET_PATH/hud-critical.png" ||
  test -e "$PET_PATH/hud-critical.png"
cp -n Examples/yicha/hud-effects.json "$PET_PATH/hud-effects.json" ||
  test -e "$PET_PATH/hud-effects.json"
cmp -s Examples/yicha/hud-panic.png "$PET_PATH/hud-panic.png" ||
  { printf 'Existing hud-panic.png differs; left unchanged.\n' >&2; exit 1; }
cmp -s Examples/yicha/hud-critical.png "$PET_PATH/hud-critical.png" ||
  { printf 'Existing hud-critical.png differs; left unchanged.\n' >&2; exit 1; }
cmp -s Examples/yicha/hud-effects.json "$PET_PATH/hud-effects.json" ||
  { printf 'Existing hud-effects.json differs; left unchanged.\n' >&2; exit 1; }
```

Yicha is an example only. `hud-effects.json` must keep relative asset paths
inside the selected pet directory; malformed metadata, missing images, and unsafe
paths fall back safely without hiding the HUD. Repository fixture tests validate
Yicha's eight `192x208` RGBA panic cells, alpha, and connected components. These
shell checks do not validate arbitrary images or manifests; the app validates
loaded effect assets. `cp -n` refuses to overwrite existing installed assets,
and `cmp -s` reports a different pre-existing asset without replacing it.

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
