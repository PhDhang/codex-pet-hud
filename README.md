# Codex Pet HUD

Codex Pet HUD is a native macOS companion for Codex v2 pets. It follows the
live pet window and renders a compact Dungeon Nameplate with weekly quota and
reset-cycle status.

![Dungeon Nameplate showing weekly HP and reset SP](docs/screenshots/dungeon-nameplate.png)

## Features

- **HP bar:** shows remaining weekly Codex quota as a percentage.
- **Quota colors:** emerald above 90%, amber through the middle range, and red
  below 10%.
- **SP bar:** seven cells visualize progress toward the weekly reset. Seven
  days remaining starts empty; two days remaining lights five cells.
- **Critical state:** at 3% remaining or less, a darkened pet clone, stars, and
  circling birds indicate an exhausted character.
- **Live attachment:** tracks the exact `Codex Pet Mascot Effect` window and
  hides safely if the match is missing or ambiguous.
- **Local-first:** reads Codex authentication locally, sends one read-only
  quota request, and never reads browser cookies.
- **Reusable Skill:** includes a Codex Skill for prerequisite checks, source
  installation, diagnostics, repair, and removal.

### Critical State

| Exhausted nameplate | Downed pet effect |
| --- | --- |
| ![Exhausted HP nameplate](docs/screenshots/dungeon-critical-nameplate.png) | ![Downed pet with circling birds](docs/screenshots/dungeon-critical-effect.png) |

## Requirements

- macOS 14 or newer
- Codex desktop with a visible v2 pet
- Swift 6.2 or newer from Xcode Command Line Tools
- A signed-in Codex session

## Install From Source

```bash
git clone https://github.com/PhDhang/codex-pet-hud.git
cd codex-pet-hud
swift test --disable-sandbox
scripts/build-app.sh
scripts/install.sh --pet-path "$HOME/.codex/pets/YOUR_PET"
```

The installer copies the application to
`$HOME/Applications/Codex Pet HUD.app`, writes a private configuration file,
and installs a per-user LaunchAgent.

Run a redacted health check:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" --diagnose
```

## Configuration

Settings live at `$HOME/.config/codex-pet-hud/config.json`:

```json
{
  "petPath": "~/.codex/pets/YOUR_PET",
  "refreshIntervalSeconds": 300,
  "criticalThresholdPercent": 3,
  "nameplateOffset": 10,
  "launchAtLogin": true
}
```

Refresh intervals shorter than five minutes are clamped. Critical thresholds
are limited to 0–10%, and the vertical offset is limited to ±100 points.

## Install The Skill

Copy `skills/codex-pet-hud` into your Codex skills directory. The Skill can
check prerequisites and install from this repository. To use a fork instead,
set:

```bash
export CODEX_PET_HUD_REPO_URL="https://github.com/PhDhang/codex-pet-hud.git"
```

Then ask Codex to install or diagnose Codex Pet HUD for a v2 pet.

## Uninstall

Keep configuration:

```bash
scripts/uninstall.sh
```

Remove the app, LaunchAgent, logs, and configuration:

```bash
scripts/uninstall.sh --purge
```

## Development

```bash
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  bash "$test_script"
done
```

See `docs/architecture.md` for component boundaries and `docs/privacy.md` for
the data-flow and credential policy.

## Status

Version 0.1.0 targets macOS only. This is an independent community project,
not an official OpenAI product. The quota endpoint and Codex pet window title
are implementation details that may change.

## License

MIT
