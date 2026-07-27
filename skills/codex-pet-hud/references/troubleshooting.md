# Troubleshooting

## Diagnostic Exit Codes

| Code | Meaning | Recovery |
|---|---|---|
| 0 | Ready | No action |
| 2 | Invalid configuration or pet warning | Validate `~/.config/codex-pet-hud/config.json` and the selected `pet.json` |
| 3 | Authentication required | Open Codex, sign in, and confirm `${CODEX_HOME:-~/.codex}/auth.json` exists |
| 4 | Provider or network failure | Retry once; inspect only redacted stderr |
| 5 | Pet window not found | Open the Codex pet overlay and retry |

## Life Pod Does Not Follow

Run `--diagnose`. If `petWindow` is missing while the pet is visible, inspect
on-screen ChatGPT window metadata with Core Graphics. LaunchAgent may redact
window titles, so the fallback requires exactly one plausible empty-title
mascot containing a same-PID, layer-3, `20...32` point voice control. If titles
remain visible, update `PetWindowLocator.exactWindowName` only after confirming
the upstream name changed.

If the ring is visible but misaligned, adjust `podScale`, `podOffsetX`, and
`podOffsetY`, restart the LaunchAgent, then resize the pet again. The ring
should return within one polling interval after resize completes.

## Quota Is Offline

Confirm Codex itself can display usage. Do not copy tokens into logs or issue reports. A provider payload change should be repaired in `WhamUsageParser` with an invented fixture and a failing test first.

## Critical Clone Is Missing

The HP/SP life pod remains functional when sprite extraction fails. Confirm:

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
