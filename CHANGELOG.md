# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Fixed

- Restore the HP/MP/SP HUD for the native floating pet container in
  Codex/ChatGPT 26.901.31953. Verify the owning application, live geometry and
  pet visibility; preserve legacy matching and fail-closed ambiguity handling.
- Read pet settings without mistaking quoted `#` characters or unrelated nested
  TOML arrays for comments or table headers. Cache only selected settings and
  retry transient read failures without changing Codex configuration.
- HUD positioning now follows same-PID fallback geometry during live pet dragging
  without weakening cold-cache or ambiguity protection.

### Changed

- HP and measured MP values now render inside their bars, SP no longer shows a
  visible reset suffix, and the default panel uses a denser `190 × 72` layout.

## [0.4.0] - 2026-07-30

### Added

- Optional five-hour MP monitoring with a full sky-blue `MAX` fallback when the
  provider does not report that window.
- Independent low and critical HP/MP pulses, with fixed danger colors under
  Reduce Motion.
- HUD-window-only screenshot capture that rejects pet-effect windows and never
  captures desktop content beneath the translucent panel.

### Changed

- HP now uses a blood-red RPG gradient and MP uses a sky-blue gradient, with a
  clipped same-color highlight flow only for safe measured values below `100%`.
- Low and critical HP/MP states pulse their identity color to white at `0.9s`
  and `0.45s`; Reduce Motion leaves a static bright identity color.
- Lit SP flames now use a `1.10` base scale while retaining bottom-anchored,
  Reduce Motion-aware flicker.
- Redacted diagnostics now report rounded weekly and optional five-hour
  remaining percentages plus five-hour measurement status, without reset times
  or provider payloads.
- The tactical HUD remains bars-only: no pet effects, animation, or replacement.

## [0.3.0-rc.1] - 2026-07-27

### Removed

- Low-quota pet replacements; fresh `4–9%` and `≤3%` now update only tactical
  HUD labels and colors.
- Optional per-pet effect manifests and checked Yicha effect assets.

### Added

- Tactical HP and seven-flame SP bars in a compact tactical dual-bar HUD.
- Stable idle presence tracking and persisted safe geometry for task-free pet states.

### Changed

- Smaller `podScale` support, clamped to `0.65...1.6`.

## [0.2.0-rc.1] - 2026-07-27

### Added

- Proportional ring life pod with an HP arc and seven lower-arc SP cells.
- Configurable `podScale`, `podOffsetX`, and `podOffsetY` alignment controls.

### Fixed

- Pet resizing no longer leaves the HUD hidden after mascot-window reconstruction.
- Polling now remains active in AppKit resize and event-tracking modes.

## [0.1.0] - 2026-07-27

### Added

- Native macOS Dungeon Nameplate attached to the Codex pet.
- Weekly-quota HP bar with numeric remaining percentage.
- Seven-cell reset-cycle SP bar.
- Critical low-quota pet effect at a configurable threshold.
- Read-only local Codex authentication and normalized snapshot cache.
- Safe exact-window matching, multi-display geometry, and stale states.
- Source build, LaunchAgent install, uninstall, diagnostics, and Codex Skill.
- Unit, packaging, installation, Skill, and release validation tests.
