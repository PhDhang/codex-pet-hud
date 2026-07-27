# Tactical Dual-Bar HUD and Pet Distress States

**Date:** 2026-07-27  
**Target:** macOS, `codex-pet-hud` v0.3.0-rc.1  
**Status:** Design approved in visual review; awaiting document review

## Summary

Replace the ring life-pod HUD with a compact tactical dual-bar HUD that remains visible whenever the Codex pet is enabled, including periods with no active task. The HUD tracks weekly quota as HP and time until quota reset as seven flame-shaped SP cells.

Low quota adds two pet distress states:

- `4–9%`: a compact left/right panic run with open spiral eyes.
- `≤3%`: a custom spread-eagle prone replacement with integrated spiral eyes.

The implementation remains generic for Codex v2 pets while supporting optional per-pet effect assets. Yicha receives the first custom panic and critical assets.

## Goals

- Keep the HUD visible while the pet is idle.
- Preserve the HUD position through pet movement and resizing.
- Scale the HUD proportionally to the pet while retaining user adjustments.
- Display weekly quota remaining as a precise HP percentage.
- Display reset progress as seven flame-shaped SP cells.
- Add readable, animated low and critical pet states.
- Support Yicha-specific art without making the app Yicha-only.
- Package the behavior as a reusable Skill and macOS release.

## Non-Goals

- Replacing Codex's native pet renderer.
- Modifying Codex application binaries or internal files.
- Supporting non-v2 pets in the first release.
- Shipping Windows, Linux, or mobile implementations in this release.
- Treating missing or stale usage data as exhausted quota.

## Approved Visual Direction

### Tactical HUD

The HUD is a compact, angular tactical panel above the pet:

- Two horizontal rows labeled `HP` and `SP`.
- Dark translucent background with a thin cyan border.
- HP value shown numerically at the right edge.
- SP reset time shown as a day label at the right edge.
- Full brightness in both active and idle task states.
- Critical state changes the panel border, glow, and status label to red.

### HP Colors

| Remaining | Band | Color | Pet Effect |
| --- | --- | --- | --- |
| `>90%` | healthy | emerald | none |
| `51–90%` | normal | green | none |
| `10–50%` | warning | amber | none |
| `4–9%` | low | red | panic run |
| `≤3%` | critical | bright red | prone critical pose |

The exact percentage is always visible when fresh or cached data exists.

### SP Flames

SP uses seven rounded, nested flame silhouettes matching the familiar `🔥` shape:

- Lit: red outer flame, orange middle flame, yellow core.
- Unlit: blue outer flame, cyan middle flame, ice-blue core.
- Unlit flames are semi-transparent but preserve the same three-layer shape.
- Lit flames use a subtle heat flicker unless Reduce Motion is enabled.

The lit count represents elapsed days in the seven-day quota cycle:

| Time Until Reset | Lit Flames |
| --- | --- |
| 7 days | 0 |
| 5 days | 2 |
| 2 days | 5 |
| reset reached | 7, then return to 0 after fresh quota data |

The calculation is:

```text
remainingDays = clamp(ceil((resetAt - now) / 1 day), 0, 7)
litFlames = 7 - remainingDays
```

## Pet State Machine

### Normal

- Used for HP `≥10%`.
- Native pet remains unobstructed.
- Only the tactical HUD is shown.

### Panic

- Enter when a non-expired quota snapshot reports HP in `4–9%`.
- Exit to normal at `≥10%`.
- Transition immediately to critical at `≤3%`.
- Run a compact left/right shuttle loop.
- Use open anime dizzy eyes whose red/crimson spirals replace the original
  pupils inside the sprite pixels.
- Use actual v2 running-left and running-right animation families; never rotate a standing sprite.

Motion limits:

- Horizontal travel per side: `min(petWidth × 0.18, 28pt)`.
- Vertical turn bounce: at most `4pt`.
- Loop duration: approximately `2.4s`.
- Turn at each endpoint by switching animation family, not by rotating the full image.

Generic v2 pets use standard directional running frames plus a non-facial aura
and no procedural eye overlay. A custom panic strip carries integrated eye art
and may omit legacy eye anchors. Yicha ships eight right-running frames; the
runtime mirrors the strip for left travel.

### Critical

- Enter when a non-expired quota snapshot reports HP at `≤3%`.
- Remain critical until HP is greater than `5%` to prevent state flicker.
- After leaving critical:
  - `6–9%` becomes panic.
  - `≥10%` becomes normal.
- Replace the current rotated neutral sprite effect.

Yicha's critical art must:

- Lie on the ground with limbs spread in a readable “大” silhouette.
- Keep the face visible toward the viewer.
- Show open anime-style spiral eyes.
- Avoid using a rotated standing or closed-eye frame.
- Avoid baked-in birds, sparkles, shadows, scenery, or text.

Custom critical art remains a single replacement sprite. Generic critical
fallbacks use the v2 failed animation with a non-facial aura.

### Unknown or Stale Data

- Never enter panic or critical solely because data is missing.
- If a valid cached snapshot exists, display it with a `STALE` indicator.
- If no valid value exists, show HP as `--`.
- Stale snapshots do not drive distress effects; return the pet effect to normal while retaining the stale numeric display.
- Keep the pet in its normal state until a non-expired value is available.
- Continue showing SP only when a trustworthy reset timestamp exists.

## Pet Presence and Window Tracking

The current bug occurs because the exact `Codex Pet Mascot Effect` window can disappear when no task is active. The tracker retains geometry for only a short grace period, after which the HUD hides.

The new tracker separates two signals.

### Exact Geometry Signal

Use the exact mascot window to update:

- Pet bounds.
- Pet scale.
- Pet movement.
- Display assignment.

Every valid exact observation updates the in-memory geometry and an atomic on-disk last-known geometry cache.

### Stable Presence Signal

Use conservative Codex-owned pet shell windows to establish that the pet remains enabled:

- `Codex Pet Composition Surface`
- `Codex Pet Voice Controls Backing`
- `Codex Pet Activity Stack Backing`
- Equivalent title-redacted LaunchAgent windows only when owner, layer, size, and companion-window evidence all match.

The stable signal confirms presence but does not replace exact geometry unless a high-confidence mapping is available.

### Retention Rules

- While stable presence exists, retain the last exact pet geometry indefinitely.
- Task start or end does not affect HUD visibility.
- Movement or resizing immediately replaces retained geometry and persists it.
- On launch, restore cached geometry only when a stable presence signal exists and the cached frame intersects a current display.
- Hide all HUD/effect panels only after stable presence is absent for at least three consecutive observations spanning two seconds.
- Keep cached geometry for the next valid launch but mark it inactive while the pet is closed.
- If presence exists but no safe current or cached geometry exists, fail closed rather than place the HUD randomly.

## Geometry and User Adjustment

The tactical HUD is anchored to the horizontal center above the pet.

Base sizing:

```text
baseWidth = clamp(petWidth × 1.05, 210pt, 360pt)
baseHeight = 58pt
gap = max(8pt, petHeight × 0.04)
```

The existing `podScale`, `podOffsetX`, and `podOffsetY` configuration fields remain compatible:

- `podScale` scales the tactical HUD around the pet center.
- Offsets apply after automatic proportional layout.
- Resizing the pet recalculates the automatic base layout without resetting offsets.
- All configuration values remain clamped to safe ranges.

The effect panel is derived from pet bounds and uses the same display clipping logic. It must remain aligned during movement, resizing, display changes, and task transitions.

## Asset Contract

Per-pet effect assets are optional and live inside the pet directory.

```text
<pet>/
  manifest.json
  spritesheet.png
  hud-effects.json          optional
  hud-panic.png             optional
  hud-critical.png          optional
```

`hud-effects.json` version 1:

```json
{
  "version": 1,
  "panic": {
    "spritesheet": "hud-panic.png",
    "columns": 8,
    "framesPerSecond": 8
  },
  "critical": {
    "image": "hud-critical.png",
    "headAnchor": [0.72, 0.30],
    "scale": 1.0
  }
}
```

`panic.spritesheet` is optional. When omitted, the app uses the standard v2
running-right and running-left rows with a non-facial aura and no procedural eye
overlay. When present, the strip itself owns integrated facial artwork.

Rules:

- Paths must resolve inside the pet directory.
- Invalid paths, dimensions, values, or JSON must not crash the app.
- Coordinates are normalized to asset bounds and clamped to `[0, 1]`.
- Scale and frame-rate values use conservative bounds.
- Missing panic art falls back to standard v2 running rows.
- Missing critical art falls back to the v2 `failed` animation family, never a rotated neutral frame.
- Panic and critical remain pet-state replacements outside the tactical bars.

## Rendering Components

Replace the ring-specific components with:

- `TacticalHUDView`
- `TacticalHUDPanelController`
- `FlameCellView`
- `PetEffectView`
- `PetEffectPanelController`

Core additions:

- `PetPresenceTracker`
- `PetGeometryCache`
- `PetEffectManifest`
- `PetEffectAssetLoader`
- `PetDistressState`
- Generalized `PetAtlas.image(row:column:)`

The tactical HUD and pet effect remain separate non-activating, mouse-transparent floating panels.

## Data Flow

```text
Window observations ──> PetPresenceTracker ──> retained pet geometry
Usage source ─────────> SnapshotCache ───────> HUD state evaluator
Pet manifest ─────────> Effect asset loader ─> panic/critical resources

retained geometry + HUD state + assets
                  └──> presentation model
                        ├──> TacticalHUD panel
                        └──> PetEffect panel
```

Quota refresh and window tracking remain independent. A quota refresh failure cannot hide the HUD, and a task-state window change cannot discard valid quota data.

## Error Handling

- Preserve the last good quota snapshot when a refresh fails.
- Mark cached data stale without treating it as zero.
- Ignore malformed per-pet effect metadata and use safe fallbacks.
- Reject asset paths outside the pet directory.
- Reject atlas cells or custom images with invalid dimensions.
- Clamp geometry to a visible display.
- Avoid flashing panels during short-lived window enumeration gaps.
- Log diagnostics without tokens, authorization headers, or unrelated window contents.

## Accessibility

When Reduce Motion is enabled:

- Stop flame flicker.
- Freeze the custom panic strip on one integrated-eye frame.
- Stop shuttle translation.
- Keep critical replacement art static.

The color states retain labels and percentages so state is not communicated by color alone.

## Test Strategy

### Unit Tests

- HP band boundaries at `91`, `90`, `51`, `50`, `10`, `9`, `4`, `3`, and `0`.
- Critical hysteresis through `3 → 4 → 5 → 6`.
- Panic transitions through `10 → 9 → 4 → 3`.
- SP flame counts for reset timestamps from 7 to 0 days.
- Stale and missing data never trigger distress states.
- Effect manifest decoding, clamping, and path containment.
- Atlas arbitrary-cell extraction and fallback selection.
- Tactical HUD geometry across multiple pet sizes and offsets.
- Geometry-cache display validation.

### Tracker Sequence Tests

- Active mascot → idle shell only: HUD remains visible.
- Idle shell → active mascot: geometry refreshes without flicker.
- Pet movement: HUD follows every exact geometry update.
- Pet resize: HUD rescales and preserves offsets.
- Temporary missing observations: HUD remains stable.
- Pet closed: HUD hides after the absence threshold.
- Cold launch with valid cached geometry and stable presence: HUD appears.
- Cold launch without safe geometry: no randomly placed HUD.

### Visual QA

- Yicha at small, default, and large pet sizes.
- Tactical HUD at healthy, warning, panic, critical, stale, and unknown states.
- Seven flame counts from 0 through 7.
- Panic loop at normal speed and Reduce Motion.
- Critical prone art at normal display scale and Retina scale.
- Movement and resize while no Codex task is active.
- Multiple-display placement and display removal.

### Live Acceptance

1. Start with an idle pet and confirm the HUD stays visible for at least two minutes.
2. Move the idle pet repeatedly and confirm the HUD never disappears.
3. Resize the pet and confirm HUD size and distance remain proportional.
4. Simulate `8%` and verify compact shuttle motion with open spiral eyes.
5. Simulate `2%` and verify the custom prone replacement pose.
6. Restore healthy data and verify the native pet returns without stale overlays.
7. Disable the pet and confirm all HUD windows close.

## Packaging and Release

- Upgrade the reusable `codex-pet-hud` Skill documentation and scripts.
- Add Yicha effect assets and metadata to the installed pet.
- Preserve compatibility with current configuration files.
- Build and sign/package the macOS app using the existing project workflow.
- Install locally for live QA.
- Publish the implementation and Skill to GitHub as `v0.3.0-rc.1` only after tests and visual QA pass.

## Acceptance Criteria

- HUD no longer disappears solely because there is no active task.
- HUD follows pet movement and resizing without losing alignment.
- HP and seven flame-shaped SP indicators match the approved thresholds and colors.
- Panic state uses small-amplitude left/right running with open spiral eyes.
- Critical state uses newly drawn prone art, not a rotated standing frame.
- Missing data never falsely exhausts the pet.
- Yicha-specific assets load safely while other v2 pets receive functional fallbacks.
- Automated tests and live macOS QA cover idle, movement, resize, panic, critical, and close behavior.
