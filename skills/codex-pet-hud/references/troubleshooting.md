# Troubleshooting

## Diagnostic Exit Codes

| Code | Meaning | Recovery |
|---|---|---|
| 0 | Ready | No action |
| 2 | Invalid configuration or pet warning | Validate `~/.config/codex-pet-hud/config.json` and the selected `pet.json` |
| 3 | Authentication required | Open Codex, sign in, and confirm `${CODEX_HOME:-~/.codex}/auth.json` exists |
| 4 | Provider or network failure | Retry once; inspect only redacted stderr |
| 5 | Pet window not found | Open the Codex pet overlay and retry |

## HUD Does Not Follow

Run `--diagnose`. If `petWindow` is missing while the pet is visible, inspect on-screen ChatGPT window names with Core Graphics. Update only `PetWindowLocator.exactWindowName` after confirming the upstream name changed.

## Quota Is Offline

Confirm Codex itself can display usage. Do not copy tokens into logs or issue reports. A provider payload change should be repaired in `WhamUsageParser` with an invented fixture and a failing test first.

## Critical Clone Is Missing

The HP/SP nameplate remains functional when sprite extraction fails. Confirm:

- `spriteVersionNumber` is `2`.
- The spritesheet exists inside the pet directory.
- Atlas dimensions are divisible by 8 columns and 11 rows.

Use `hatch-pet` to repair invalid pet assets.

## Safe Reinstall

Run:

```bash
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
```

The installer backs up an existing configuration before replacement.
