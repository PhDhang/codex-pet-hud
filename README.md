# Codex Pet HUD

Codex Pet HUD is a macOS 14 companion for one selected Codex v2 pet. It keeps a
compact tactical dual-bar HUD above the pet, including when Codex has no active
task. HP shows weekly quota remaining; seven SP flames show reset progress.

![Healthy tactical HUD](docs/screenshots/tactical-hud.png)

## Tactical HUD

Snapshots whose age is `≤300s` are fresh and show the raw weekly HP percentage,
using one decimal only for non-integral values. Bands are `>90%` emerald,
`51–90%` green, `10–50%` amber, `4–9%`
red, and `≤3%` bright red. At an age of `>300s` and `≤1800s`, the last values
remain with `STALE`.
At an age of `>1800s`, the HUD is `OFFLINE` with `--` values.

SP always has seven rounded three-layer flames. Lit flames are
red/orange/yellow; unlit flames are blue/cyan/ice-blue. Each flame represents
one elapsed seventh of the weekly reset window, from zero lit at a new window to
seven at reset.

For fresh `4–9%` quota, the HUD shows `PANIC · QUOTA LOW` in red. For fresh
`≤3%` quota, it shows `EXHAUSTED · SIGNAL CRITICAL` in bright red. These are
HUD-only label and color changes: the HUD never changes the native pet.

## Idle Presence and Alignment

Exact mascot observations refresh pet geometry. Stable Codex companion windows
keep the HUD present while the task is idle. Title-redacted presence requires one
complete same-PID companion cluster and fails closed when multiple complete
clusters exist. The local geometry cache retains only high-confidence
shell-derived bounds, PID, window ID, and timestamp; mascot fallback geometry is
transient. Cached geometry restores only for matching stable presence on a
connected display. Both panels hide only after three missing observations
spanning at least two seconds.

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
minutes and X/Y offsets are `-300...300`. The legacy
`criticalThresholdPercent` setting is retained for compatibility, but tactical
behavior remains fixed at `≤3%` for `EXHAUSTED · SIGNAL CRITICAL`.

## Pet Compatibility

Any Codex v2 pet with standard `pet.json` metadata is supported. The HUD uses
the manifest display name and positions its one tactical window above the native
pet; no repository asset or per-pet extension is required.

Automated coverage creates two distinct valid v2 manifests that contain only
standard `pet.json` metadata and a `spritesheetPath`. It verifies that each
manifest display name follows the same HUD data path used by the app at `8%`
(`PANIC · QUOTA LOW`) and `2%` (`EXHAUSTED · SIGNAL CRITICAL`), without effect
metadata or assets.

Live desktop validation is available for every locally discoverable pet. This
machine currently exposes only the installed `一茬` manifest at
`$HOME/.codex/pets/yicha/pet.json`; no additional default pet assets are
discoverable in `/Applications/ChatGPT.app` or
`$HOME/Library/Application Support`. There are therefore no other local
manifests to check with the diagnose/mock-visual workflow.

## Skill, Uninstall, and Privacy

Copy `skills/codex-pet-hud` into the Codex skills directory. To use a fork:

```bash
export CODEX_PET_HUD_REPO_URL="https://github.com/PhDhang/codex-pet-hud.git"
```

Keep configuration while uninstalling:

```bash
scripts/uninstall.sh
```

Without `--purge`, configuration, caches, and logs remain.

Remove the app, LaunchAgent, logs, and settings:

```bash
scripts/uninstall.sh --purge
```

`--purge` also removes the quota snapshot and geometry cache from
`Library/Application Support/CodexPetHUD`.

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
