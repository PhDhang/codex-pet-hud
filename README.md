# Codex Pet HUD

Codex Pet HUD is a macOS 14 companion for one selected Codex v2 pet. It keeps a
compact tactical dual-bar HUD above the pet, including when Codex has no active
task. HP shows weekly quota remaining; seven SP flames show reset progress.

![Healthy tactical HUD](docs/screenshots/tactical-hud.png)

| Panic | Critical |
| --- | --- |
| ![Panic pet effect](docs/screenshots/tactical-hud-panic.png) | ![Critical pet effect](docs/screenshots/tactical-hud-critical.png) |

## Tactical HUD

Fresh or cached HP always shows the rounded weekly percentage. Bands are
`>90%` emerald, `51–90%` green, `10–50%` amber, `4–9%` red, and `≤3%`
bright red. Cached data shows `STALE` and never drives effects.

SP always has seven rounded three-layer flames. Lit flames are
red/orange/yellow; unlit flames are blue/cyan/ice-blue. Each flame represents
one elapsed seventh of the weekly reset window, from zero lit at a new window to
seven at reset.

Fresh `4–9%` HP enables a compact spiral-eye panic run. Fresh `≤3%` HP enables
the prone critical state, which clears only above `5%`. Missing or invalid
effect assets use generic v2 fallbacks without hiding the tactical HUD.

## Idle Presence and Alignment

Exact mascot observations refresh pet geometry. Stable Codex companion windows
keep the HUD present while the task is idle. The local geometry cache retains
only last-safe bounds, PID, window ID, and timestamp; it restores geometry only
when the pet remains present on a connected display. Both panels hide only after
three missing observations spanning at least two seconds.

The HUD centers above the pet. `podScale`, `podOffsetX`, and `podOffsetY`
remain compatible; `podScale` is clamped to `0.65...1.6`. Positive X moves
right and positive Y moves up.

## Install From Source

```bash
git clone https://github.com/PhDhang/codex-pet-hud.git
cd codex-pet-hud
swift test --disable-sandbox
scripts/build-app.sh
scripts/install.sh --pet-path "$HOME/.codex/pets/YOUR_PET"
```

Run a redacted diagnostic check:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" --diagnose
```

The installer writes private configuration and a per-user LaunchAgent. Settings
live at `$HOME/.config/codex-pet-hud/config.json`; refresh is at least five
minutes, critical threshold is `0...10%`, and X/Y offsets are `-300...300`.

## Optional Per-Pet Effects

Generic v2 fallback effects need no extra files. Yicha is only an example; copy
its checked effect image and manifest into the selected Yicha directory:

```bash
cp Examples/yicha/hud-critical.png "$HOME/.codex/pets/yicha/hud-critical.png"
cp Examples/yicha/hud-effects.json "$HOME/.codex/pets/yicha/hud-effects.json"
```

`hud-effects.json` may reference only regular image files relative to the pet
directory. Invalid paths, metadata, and images are rejected safely. Use
`hatch-pet` to create custom prone critical art; do not modify the original
spritesheet.

## Skill, Uninstall, and Privacy

Copy `skills/codex-pet-hud` into the Codex skills directory. To use a fork:

```bash
export CODEX_PET_HUD_REPO_URL="https://github.com/PhDhang/codex-pet-hud.git"
```

Keep configuration while uninstalling:

```bash
scripts/uninstall.sh
```

Remove the app, LaunchAgent, logs, and settings:

```bash
scripts/uninstall.sh --purge
```

The app makes one read-only quota request and never logs credentials, account
IDs, emails, cookies, or raw provider responses. It uses public window metadata
only and requests neither Accessibility nor Screen Recording. See
`docs/privacy.md` for the full boundary and release scan command.

## Development

```bash
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
```

See `docs/architecture.md` for component boundaries and data flow.

## Status

Version 0.3.0-rc.1 targets macOS 14 and newer. This is an independent community
project, not an official OpenAI product. Quota and window metadata can change.

## License

MIT
