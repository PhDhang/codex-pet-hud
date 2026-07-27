# Changelog

All notable changes to this project are documented here.

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
