# Architecture

Codex Pet HUD is a Swift package with a pure domain library and a native AppKit
executable. It separates quota state from pet presence, so task-state changes
cannot hide an otherwise healthy HUD.

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

Quota refresh and window tracking are independent. A refresh failure cannot hide
the HUD, and a task-state window change cannot discard valid quota data.

1. `CodexAuth` decodes only provider-required token fields.
2. `WhamUsageClient` performs the read-only usage request.
3. `WhamUsageParser` normalizes the weekly window into `QuotaSnapshot`.
4. `SnapshotCache` preserves only normalized quota for stale rendering.
5. `ApplicationModel` produces quota, stale, offline, and auth states;
   `PetDistressState` produces normal, panic, or critical only from fresh data.
6. `HUDPresentationData` produces numeric HP and seven-flame SP data.
7. `TacticalHUDPanelController` and `PetEffectPanelController` render
   presentation data without receiving credentials or raw provider responses.

## Tactical State

HP bands are `>90%`, `51–90%`, `10–50%`, `4–9%`, and `≤3%`. Panic enters
at `4–9%` and exits at `≥10%`; critical enters at `≤3%` and exits only above
`5%`. Stale and missing quota never trigger effects. SP has seven three-layer
flames; lit count equals the elapsed seventh of the weekly reset window.

## Presence and Geometry

`PetWindowLocator` uses `Codex Pet Mascot Effect` for exact geometry. During
idle periods, `Codex Pet Composition Surface`, `Codex Pet Voice Controls
Backing`, and `Codex Pet Activity Stack Backing` confirm stable presence. A
title-redacted fallback requires matching ChatGPT owner, PID, layer, size, and
companion evidence.

Every exact observation updates `PetGeometryCache`. Cached geometry restores
only when stable presence exists and bounds intersect a current display.
`PetPresenceTracker` retains geometry through idle and resize transitions and
hides panels only after three absent observations spanning two seconds. It fails
closed when no safe current or cached geometry is available.

`PanelGeometry` centers the tactical HUD above the pet, then applies
`podScale`, `podOffsetX`, and `podOffsetY`. Both panels are transparent,
non-activating, mouse-transparent accessory windows across Spaces.

## Optional Per-Pet Effects

Effect assets remain optional inside the selected pet directory:

```text
<pet>/
  manifest.json
  spritesheet.png
  hud-effects.json          optional
  hud-panic.png             optional
  hud-critical.png          optional
```

Version-1 `hud-effects.json` supplies normalized eye/head anchors and optional
paths. `panic.spritesheet` may be omitted, using standard v2 running rows with
the supplied eye anchors. Missing critical art uses the v2 `failed` animation,
never a rotated neutral frame.

The loader rejects absolute or escaping paths, missing files, malformed metadata,
and invalid images. It falls back safely without hiding the HUD. Use
`hatch-pet` for custom critical art rather than replacing the original atlas.

## Accessibility and Lifecycle

No Accessibility or Screen Recording permission is required. The per-user
LaunchAgent refreshes quota no more often than every five minutes while the
main-run-loop window sampler follows movement and resize events.
