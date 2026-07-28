# Architecture

Codex Pet HUD is a Swift package with a pure domain library and a native AppKit
executable. It separates quota state from pet presence, so task-state changes
cannot hide an otherwise healthy HUD.

## Data Flow

```text
Window observations ──> PetPresenceTracker ──> retained pet geometry
Usage source ─────────> SnapshotCache ───────> HUD state evaluator
Pet manifest ─────────> pet display name

retained geometry + HUD state + pet display name
                  └──> presentation model
                        └──> TacticalHUDPanelController
                              └──> Tactical HUD panel
```

Quota refresh and window tracking are independent. A refresh failure cannot hide
the HUD, and a task-state window change cannot discard valid quota data.

1. `CodexAuth` decodes only provider-required token fields.
2. `WhamUsageClient` performs the read-only usage request.
3. `WhamUsageParser` normalizes the weekly window into `QuotaSnapshot`.
4. `SnapshotCache` preserves only normalized quota for stale rendering.
5. `ApplicationModel` produces quota, stale, offline, and auth states.
6. `HUDPresentationData` produces numeric HP and seven-flame SP data.
7. `TacticalHUDPanelController` renders the one tactical HUD window without
   receiving credentials or raw provider responses.

## Tactical State

HP bands are `>90%`, `51–90%`, `10–50%`, `4–9%`, and `≤3%`. Fresh `4–9%`
shows the red `PANIC · QUOTA LOW` HUD label, and fresh `≤3%` shows the bright
red `EXHAUSTED · SIGNAL CRITICAL` label. The labels and colors are HUD-only;
they never change the native pet. SP has seven three-layer flames; lit count
equals the elapsed seventh of the weekly reset window.

## Presence and Geometry

`PetWindowLocator` uses the native mascot window for exact geometry. During idle
periods, `Codex Pet Composition Surface`, `Codex Pet Voice Controls
Backing`, and `Codex Pet Activity Stack Backing` confirm stable presence. A
title-redacted fallback requires exactly one complete matching ChatGPT owner,
PID, layer, size, and companion cluster; multiple complete PID clusters fail
closed.

Only high-confidence shell-derived geometry is cached.
Mascot fallback geometry is transient and is never persisted.
Cached geometry restores only when stable presence identifies the matching PID
and bounds intersect a current display.
`PetPresenceTracker` retains geometry through idle and resize transitions and
hides panels only after three absent observations spanning two seconds. It fails
closed when no safe current or cached geometry is available.

`PanelGeometry` centers the tactical HUD above the pet, then applies
`podScale`, `podOffsetX`, and `podOffsetY`. The tactical panel is transparent,
non-activating, and mouse-transparent across Spaces.

## Pet Compatibility

Pet compatibility requires only standard v2 `pet.json` metadata. `PetManifest`
validates the v2 manifest and exposes its display name to the tactical HUD; the
native pet stays responsible for its own rendering.

## Accessibility and Lifecycle

No Accessibility or Screen Recording permission is required. The per-user
LaunchAgent refreshes quota no more often than every five minutes while the
main-run-loop window sampler follows movement and resize events.
