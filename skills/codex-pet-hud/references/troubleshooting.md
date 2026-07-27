# Troubleshooting

## Diagnostic Exit Codes

| Code | Meaning | Recovery |
|---|---|---|
| 0 | Ready | No action |
| 2 | Invalid configuration or pet warning | Validate `~/.config/codex-pet-hud/config.json` and the selected `pet.json` |
| 3 | Authentication required | Open Codex, sign in, and confirm `${CODEX_HOME:-~/.codex}/auth.json` exists |
| 4 | Provider or network failure | Retry once; inspect only redacted stderr |
| 5 | Pet window not found | Open the Codex pet overlay and retry |

## Tactical HUD Does Not Follow While Idle

Run `--diagnose`. Exact geometry comes from `Codex Pet Mascot Effect`, but
idle presence also accepts:

- `Codex Pet Composition Surface`
- `Codex Pet Voice Controls Backing`
- `Codex Pet Activity Stack Backing`

When LaunchAgent redacts titles, require same-PID layer-3 companion evidence:
a `20...32` point voice control, composition surface, and activity stack. Do
not loosen the match when multiple candidates exist.

The tactical HUD remains visible while stable presence is observed and hides only
after three consecutive missing observations spanning at least two seconds. If it
stays visible after closure, wait two seconds and retry `--diagnose`. If it
disappears while idle, confirm these titles or the title-redacted companion set
before changing locator rules.

If alignment is wrong, adjust `podScale`, `podOffsetX`, and `podOffsetY`,
restart the LaunchAgent, then move and resize while idle. The HUD should return
within one polling interval.

## Quota Is Offline

Confirm Codex can display usage. Do not copy tokens into logs or issue reports.
Repair provider parsing with an invented fixture and a failing test first.

## Panic or Critical Effect Is Missing

The tactical HUD remains functional when optional effects fail. Confirm:

- `spriteVersionNumber` is `2`.
- The spritesheet exists in the selected pet directory and is 8 columns by 11 rows.
- `hud-effects.json` uses only relative files inside that directory.
- The critical asset is a regular, readable image file.

Malformed or unsafe metadata falls back to standard v2 running rows for panic and
the v2 failed animation for critical. Use `hatch-pet` for custom prone art; never
rotate a standing sprite.

## Safe Reinstall

```bash
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
```

The installer backs up existing configuration before replacement.
