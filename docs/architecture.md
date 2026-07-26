# Architecture

Codex Pet HUD is a small Swift package with a pure domain library and a native
AppKit executable.

## Data Flow

1. `CodexAuth` decodes only the token fields required by the provider.
2. `WhamUsageClient` performs a read-only request to the ChatGPT usage
   endpoint.
3. `WhamUsageParser` extracts the secondary weekly window into a normalized
   `QuotaSnapshot`.
4. `ApplicationModel` derives healthy, warning, low, critical, stale, offline,
   and authentication states.
5. `DungeonNameplateView` renders HP and SP without receiving credentials or
   raw provider data.
6. `SnapshotCache` stores only the normalized quota snapshot for graceful
   stale-state rendering.

## Window Attachment

`PetWindowLocator` reads the public CoreGraphics window list and prefers the
exact ChatGPT-owned `Codex Pet Mascot Effect` window. A conservative fallback
is accepted only when exactly one plausible candidate exists.

`PanelGeometry` converts CoreGraphics top-left coordinates to AppKit
coordinates, selects the display with the largest intersection, centers the
nameplate above the pet, and clamps it to the visible display.

The panels are transparent, click-through, accessory-level windows:

- The nameplate window sits above the pet with a configurable offset.
- The critical-effect window exactly overlays the pet bounds.
- Both windows hide when the pet window cannot be identified safely.

No Accessibility or Screen Recording permission is required.

## Pet Compatibility

The configured pet must use the Codex v2 manifest and an 8×11 spritesheet.
The critical effect extracts a neutral cell from that atlas, so the generic
HUD works with any valid v2 pet without modifying the original pet files.

## Process Lifecycle

The source installer creates a per-user LaunchAgent. The application refreshes
quota no more frequently than every five minutes and samples the pet window
frequently enough to follow movement without modifying the Codex process.
