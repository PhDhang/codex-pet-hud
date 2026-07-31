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

Run `--diagnose`. Exact geometry comes from the native mascot window, but idle
presence also accepts:

- `Codex Pet Composition Surface`
- `Codex Pet Voice Controls Backing`
- `Codex Pet Activity Stack Backing`

When LaunchAgent redacts titles, require same-PID layer-3 companion evidence:
a voice backing with width 20...32 and height 6...80, composition surface, and
activity stack. The voice backing can animate between compact and expanded
sizes. Do not loosen the match when multiple candidates exist.

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

## Low-Quota HUD Label Is Unexpected

Fresh `4–9%` quota shows `PANIC · QUOTA LOW`; fresh `≤3%` quota shows
`EXHAUSTED · SIGNAL CRITICAL`. These are HUD-only label and color changes and
never change the native pet. Confirm:

- `spriteVersionNumber` is `2`.
- The selected `pet.json` is a valid standard v2 manifest.
- `--diagnose` reports a found pet window and reachable provider.
- The rendered snapshot age is fresh (`≤300s`), rather than `STALE` or `OFFLINE`.

Do not modify files in the selected pet directory to change low-quota status.

## Safe Reinstall

```bash
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
```

The installer backs up existing configuration before replacement.
