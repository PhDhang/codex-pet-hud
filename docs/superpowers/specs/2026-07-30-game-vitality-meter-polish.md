# Game Vitality Meter Polish

## Goal

Polish the tactical HUD so HP and MP read like classic action-RPG vitality
meters while remaining compact, private, accessible, and independent from the
native pet.

## Palette

- HP uses a saturated blood-red gradient:
  - shadow: `#680B18`
  - body: `#C51F35`
  - highlight: `#FF5268`
- MP uses a saturated sky-blue gradient:
  - shadow: `#0758A8`
  - body: `#179DFF`
  - highlight: `#77D9FF`
- Danger pulses preserve each meter's identity:
  - HP: blood red ↔ white
  - MP: sky blue ↔ white

These colors reference the familiar health/mana language of action RPGs
without copying another game's assets or exact interface.

## Meter Motion

- A normally measured meter below `100%` carries one soft highlight band from
  left to right.
- The band uses the meter's own palette at `10–20%` opacity, equivalent to
  `80–90%` transparency.
- The highlight is clipped to the filled portion of the capsule.
- The loop is linear, quiet, and decorative rather than a progress indicator.
- `MAX`, exactly `100%`, unavailable data, and Reduce Motion are completely
  static.
- Danger states disable the flowing highlight:
  - canonical `4–9%`: base color ↔ white at `0.9s`
  - canonical `0–3%`: base color ↔ white at `0.45s` with the existing stronger
    critical intensity
- Reduce Motion disables both flowing and pulsing. Dangerous HP remains solid
  bright blood red and dangerous MP remains solid bright sky blue, with the
  existing HUD contrast and labels carrying the warning.

## SP Flames

- Lit SP flames render at `110%` of the unlit flame scale.
- Existing flicker may rise slightly above that base but must retain its bottom
  anchor and respect Reduce Motion.
- The seven-cell row and weekly reset meaning remain unchanged.

## State Matrix

| State | HP | MP | Flow | Pulse |
|---|---|---|---|---|
| Measured below 100%, safe | blood-red gradient | sky-blue gradient | yes | no |
| Exactly 100% | blood-red gradient | sky-blue gradient | no | no |
| Five-hour unavailable after weekly success | normal HP behavior | full sky-blue `MAX` | no on MP | no on MP |
| Canonical 4–9% | red ↔ white | blue ↔ white | no | slow |
| Canonical 0–3% | red ↔ white | blue ↔ white | no | fast + stronger |
| Reduce Motion | static | static | no | no |
| Offline/authentication required | static placeholder | static placeholder | no | no |

HP and MP evaluate these states independently.

## Privacy and Compatibility

- No new windows, pet images, pet animations, or pet replacement behavior.
- No five-hour reset countdown.
- HUD captures remain PID-bound and window-only.
- Existing level-4 ordering, render cache, movement, resize, idle presence, and
  macOS 14 support remain unchanged.

