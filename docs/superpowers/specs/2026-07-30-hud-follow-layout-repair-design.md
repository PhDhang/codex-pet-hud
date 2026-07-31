# HUD Follow and Compact Layout Repair Design

## Goal

Repair live HUD tracking while the Codex pet is dragged, move HP and measured
MP percentages into the center of their bars, remove the visible SP reset-time
suffix, and resize the panel so every row uses its available space without
looking sparse.

## Scope

- Keep the existing macOS 14 companion architecture and 0.25-second pet-window
  observation cadence.
- Keep weekly HP, optional five-hour MP, seven-cell SP, danger animations,
  Reduce Motion behavior, redacted diagnostics, and HUD-only privacy boundaries.
- Do not add pet replacement artwork, pet animations, a five-hour countdown, or
  any new provider data.
- Preserve the existing `podScale`, `podOffsetX`, and `podOffsetY` configuration
  controls.

## Root Cause

`PetWindowLocator` normally returns high-confidence shell-derived geometry. While
the pet is being dragged or its shell is reconstructed, the locator can
temporarily return moving mascot-fallback geometry. `PetPresenceTracker`
currently refuses to replace a retained shell-derived position with any
mascot-fallback position. That safety rule protects a restored idle position,
but it also freezes a live HUD at the last shell-derived frame during movement.

The repair must distinguish a cold restored cache from geometry observed during
the current process:

- Cold restored shell geometry remains hidden until stable pet presence is
  confirmed and is not displaced by a single fallback observation.
- Once live presence and live geometry have been confirmed, a same-PID fallback
  observation may update the retained position so the HUD follows dragging.
- A returning shell-derived observation immediately regains authority.
- PID mismatch and exact-window ambiguity continue to fail closed.

## Approaches Considered

### 1. Always accept fallback geometry

This gives the fastest movement response, but a cold restored position could be
replaced by a lower-confidence unrelated frame before live presence is fully
established.

### 2. Never accept fallback after shell geometry

This is the current behavior. It is conservative during idle reconstruction but
causes the reported frozen-HUD bug while dragging.

### 3. Accept fallback only after live confirmation

This is the selected approach. Track whether retained geometry came only from
disk or has been confirmed by the current process. Use same-PID fallback
geometry for movement only after live confirmation, then prefer shell-derived
geometry as soon as it returns.

## HUD Layout

The HUD remains a four-row tactical panel:

1. HP row
2. MP row
3. SP row
4. status row

### HP

- Keep the `HP` label at the left.
- Remove the separate right-side percentage column.
- Render the weekly percentage centered inside the blood-red bar.
- Preserve fractional labels such as `69.5%` and placeholders such as `--`.
- Keep exact `100%` static and centered.

### MP

- Keep the `MP` label at the left.
- Remove the separate right-side measured percentage column.
- Render measured five-hour percentages centered at the same location currently
  used by `MAX`.
- Keep `MAX` centered for the unlimited state.
- Render `--` centered for unavailable states.

### SP

- Keep the `SP` label at the left.
- Remove the visible reset-time suffix such as `6D`.
- Center the seven flames across all space remaining after the label.
- Keep the reset time in the accessibility value so information is not lost to
  assistive technology.

### Panel Size

- Remove the fixed trailing-value width from layout calculations.
- Reduce the standard panel width while keeping the bars readable and all seven
  enlarged flames comfortably spaced.
- Reduce unused horizontal space rather than making the bars artificially long.
- Keep the current four-row height unless metric tests show clipping; any height
  reduction must preserve the existing row spacing and flame scale.
- Continue scaling the panel with pet size and `podScale`, and keep screen-edge
  clamping unchanged.

## Data Flow

1. The 0.25-second timer obtains a `PetWindowObservation`.
2. `PetPresenceTracker` classifies retained geometry as cold-restored or
   live-confirmed.
3. Same-PID live fallback geometry updates the current pet frame during
   dragging.
4. `ApplicationModel` emits the updated `PanelPresentation`.
5. `PanelGeometry` calculates a compact frame centered above the current pet
   frame.
6. `TacticalHUDPanelController` moves the panel without replacing SwiftUI
   content unless data or frame size changed.
7. `TacticalHUDView` centers HP/MP text inside each meter and lays out SP without
   a visible reset suffix.

## Error Handling and Safety

- Exact-window ambiguity hides the HUD after the existing absence grace period.
- Cross-PID observations clear retained geometry.
- Cold restored geometry does not become visible without stable presence.
- No diagnostic output includes window titles, coordinates, credentials,
  provider payloads, account identifiers, or personal paths.
- The change does not request Accessibility or Screen Recording permission.

## Testing

### Unit tests

- A shell-derived live position followed by a same-PID moving fallback updates
  to the fallback position.
- Cold restored shell geometry still survives an initial fallback observation.
- Cross-PID and exact-window ambiguity behavior remains fail closed.
- Panel geometry uses the new compact base width and continues following pet
  center, resize, offsets, multiple displays, and screen-edge clamping.
- Layout metrics fit centered HP/MP text and seven flames without a trailing
  column.

### Structural UI tests

- HP and MP pass their display text as `centeredText`.
- HP/MP rows no longer render a trailing percentage.
- SP no longer renders `resetText` visibly.
- SP accessibility still includes the reset time.

### Full validation

- Run all Swift tests and every `Tests/Shell/*.bats` suite.
- Build and verify the signed production app.
- Install against `$HOME/.codex/pets/yicha`.
- With no active task, drag and resize the pet and confirm the HUD follows at
  the 0.25-second cadence without disappearing.
- Check measured MP, `MAX`, unavailable, low, critical, exact 100%, and Reduce
  Motion states for clipping and centered labels.
- Capture only the HUD window for the updated repository screenshot.

## Acceptance Criteria

- Moving the pet moves the HUD continuously instead of leaving it at the old
  position.
- HP percentage is centered inside the HP bar.
- Measured MP percentage occupies the same centered position as `MAX`.
- No visible SP reset suffix such as `6D` remains.
- The compact panel has no unused right-side value column and looks visually
  filled at default `podScale: 1.14`.
- Existing security, privacy, ambiguity, idle-presence, danger-animation, and
  Reduce Motion guarantees remain intact.
