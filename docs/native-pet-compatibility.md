# Native floating pet compatibility (0.4.0 compatibility patch)

## Observed failure

ChatGPT 26.901.31953 (bundle `com.openai.codex`) exposes the awake pet as a
single layer-3 `ChatGPT` window, not the legacy named mascot and companion set.
A redacted live fixture was `(-163, -390, 772, 2129)` on a 1920x1080 screen.
The installed 0.4.0 reported `petWindow=missing` while the pet was visibly awake.

Inspection of the installed application's native overlay layout established:

- The drawing anchor remains 80x87 regardless of visible pet size.
- A 384-point viewport with animation overscan produces a 772-point-wide surface.
- Height is twice the largest native display height plus 56 minus 87.
  Native display height excludes the top menu-bar inset, but includes the Dock.
- Asymmetric right padding puts the visible pet center 14 points left of the
  container center. The visible sprite uses the configured width and 192:208 ratio.

With pet width 97, the fixture gives a visual rect `(160.5, 621.5, 97, 106)`,
consistent within rounding with the app's saved anchor `(160, 622)`.
Saved coordinates are evidence only: the HUD follows the live window, not this
anchor or an old geometry cache.

## Safety gates

Require the actual running `com.openai.codex` process, allowed title (or redacted
title), layer 3, this exact container signature, an on-display pet center,
explicit open state, visible-pet setting and a valid width in 80...224.
Multiple native containers or conflicting legacy pet evidence fail closed.
Quick Chat and ordinary main windows do not meet the signature. Legacy matching
remains available unchanged. Unsupported geometry or settings syntax hides the
native HUD rather than guessing.

The settings reader understands simple `[desktop]` scalar entries only;
multiline TOML strings, duplicate pet keys and malformed pet values fail closed.
This is a deliberately bounded compatibility adapter, not a general TOML parser.
Future window-layout changes may need another fixture and adapter update.

Native geometry is never written into the legacy shell cache. Fresh verified
native geometry can replace a stale cache from another PID. Existing absence
grace (three observations spanning two seconds) still applies after closure.

## Verification

- Red phase: 13 regression tests compiled and exposed 11 assertions failing
  before compatibility behavior was implemented.
- First green phase: all 13 regression tests passed; local debug `--diagnose`
  changed from exit 5 / `missing` to exit 0 / `found` with provider reachable.
- Additional tests cover legacy/native ambiguity, closing, and settings reload.
- Final suite on 2026-09-05: 183 Swift tests, zero failures. All eight Shell
  checks passed; build, diagnostic and main-actor checks were rerun after review.
- Independent read-only source review found and verified fixes for mixed legacy
  ambiguity, unsupported TOML defaults and read-cache retry behavior. Final
  review reported no outstanding findings.
- A final live check caught quoted `#` in an unrelated plugin table; quote-aware
  comment scanning and skipping unrelated nested arrays now have regression tests.
- Installed release diagnostic: exit 0, `configuration=ok`, `pet=found`,
  `petWindow=found`, `provider=reachable`.
- The running HUD exposes its own layer-4 tactical window at `(163,647,217,83)`,
  centered above the native pet container `(-100,-274,772,2129)`.
- HUD configuration, LaunchAgent plist and ChatGPT `app.asar` SHA-256 hashes
  matched before/after the local acceptance installation. Only the HUD app was
  replaced and its existing service restarted; the previous app was backed up.
- The HUD-only window capture was visually checked: HP, MP and all seven SP
  cells render correctly. No desktop/chat/pet capture was used.
- Local acceptance on 2026-09-05 confirmed both HUD display and dragging follow.
  Resizing is covered by regression tests; manual resize acceptance is not claimed.

No Codex app modification, rollback, Accessibility, or Screen Recording is used.
The patch preserves the 0.4.0 HP/MP/SP view; only window location changes.
