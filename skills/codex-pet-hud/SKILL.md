---
name: codex-pet-hud
description: Use when a macOS Codex v2 pet needs a live quota HUD, HP/SP bars, weekly usage and reset status, critical low-quota effects, source installation, repair, diagnostics, or safe removal.
---

# Codex Pet HUD

## Overview

Install and verify the source-built macOS companion that anchors a Dungeon Nameplate to the live Codex pet. Keep credentials local, fail closed on ambiguous windows, and prove linkage with redacted diagnostics.

## Safety Rules

- Read `${CODEX_HOME:-$HOME/.codex}/auth.json` only through the app.
- Never print tokens, account IDs, emails, cookies, or raw provider responses.
- Never read browser cookies or request Accessibility or Screen Recording.
- Attach only to `Codex Pet Mascot Effect`; hide on ambiguity.
- Build and test before installing.

## Workflow

1. Run `scripts/check-prerequisites.sh`.
2. If it reports more than one v2 pet, ask the user to select one exact pet directory.
3. Resolve the repository source:
   - Inside the project repository, use its root directly.
   - From an installed Skill, use the bundled public repository by default.
   - Honor `CODEX_PET_HUD_REPO_URL` or `--repo` when the user supplies a fork.
4. Run repository tests:

```bash
swift test --disable-sandbox
```

5. Build and install from the repository:

```bash
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
```

6. For remote source installation:

```bash
skills/codex-pet-hud/scripts/install-from-source.sh \
  --ref main \
  --pet-path "$PET_PATH"
```

7. Verify without exposing credentials:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --diagnose
```

Require `configuration=ok`, `pet=found`, `petWindow=found`, and `provider=reachable`. Exit code `5` means the Codex pet overlay is closed; open it and retry.

8. Confirm visible linkage: the nameplate must remain centered above the pet after moving the pet. Use a fixture when live quota is unavailable:

```bash
"$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
  --mock "$SOURCE_ROOT/Fixtures/critical.json"
```

## Pet Art

Use the existing v2 atlas for the universal critical clone. For a custom downed animation or a new pet, **REQUIRED SUB-SKILL:** Use `hatch-pet`; do not generate imagery in this Skill.

## Repair and Rollback

- Rebuild after upstream Codex window or usage-payload changes.
- Read `references/troubleshooting.md` only when diagnostics or installation fails.
- Remove app and LaunchAgent while retaining settings:

```bash
scripts/uninstall.sh
```

- Remove settings too:

```bash
scripts/uninstall.sh --purge
```

## Bundled Tools

- `scripts/check-prerequisites.sh`: inspect macOS, Swift, auth presence, and v2 pets without secrets.
- `scripts/install-from-source.sh`: clone, test, build, install, and diagnose a pinned source ref.
- `references/troubleshooting.md`: exit codes and targeted recovery steps.
