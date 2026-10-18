# Native floating pet compatibility (0.4.0 compatibility patches)

## Codex/ChatGPT 26.1013.40934 update

On 2026-10-18, the installed September patch still ran and the quota provider
was reachable, but it rejected the new live surface `(-571, -227, 1138, 2129)`.
The user confirmed that the pet itself remained visible. Read-only inspection
of the installed layout code established two single-display layouts:

| Layout | Surface width | Horizontal anchor offset from surface center | Visible vertical anchor |
| --- | ---: | ---: | --- |
| Plain pet (source-derived) | 1132 | +166 | Centered as before |
| Shared pet / Mini controls surface (pet geometry verified) | 1138 | +167 | Top aligned for a visible pet |

The drawing anchor stays 80x87. Side clearance is now 16 points. A plain
384-point viewport yields horizontal draw bounds [-692, +440]; the controls
viewport is 386 points and yields [-696, +442]. Damping 37.7, mass 1 and
stiffness 720 produce the same spring overscan factor as the prior build.
Height remains `2 * maxNativeDisplayHeight - 31`.

For the controls layout, native code centers the fixed draw anchor using
`round(visibleWidth/2)` but keeps its top at the visible pet's top. Therefore
the visible rect uses `x = surface.midX + 167 - round(width/2)` and
`y = surface.midY - 43.5`, with height `ceil(width * 208/192)`.
The live fixture with width 153 gives `(88, 794, 153, 166)`, matching the
application's saved anchor. A width-only patch would put the HUD 39.5 points
too high. Saved coordinates remain diagnostic evidence only, never runtime
inputs. No new settings, permissions, or state-file reads were introduced.

### Accepted shared-overlay compatibility limitation

The 1138-point surface is not, by itself, proof that the pet is visible.
The installed application uses the same drawing layout for a pet with controls
and for Mini-only presentation. Transient orbit previews and realtime selection
can suppress the pet without changing the persisted `avatar-overlay-pet-visible`
or `selected-avatar-id` preferences. A visible-pet anchor `(88, 794, 153, 166)`
and a Mini anchor `(0, 794, 330, 40)` can both produce the same surface
`(-571, -227, 1138, 2129)`.

Independent review identified this collision before installation. On 2026-10-18
the maintainer explicitly accepted restoring the quota HUD with this limitation:
the 1138 matcher tracks the shared pet / Mini overlay, not guaranteed pet-only
presentation. The HUD may remain visible over Mini. No selected-avatar-only gate
is claimed to solve this; no new private state or permissions are accessed.
This repository's current runtime renders quota bars and labels only, with no
pet replacement or pet animation. Existing owner, shape, open/visible-setting,
on-display-center and ambiguity gates remain in effect. A future strict pet-only
adapter would require a trustworthy current-presentation witness.

The native application now uses screen-sized containers on macOS with more
than one display. **This patch does not support that new multi-display mode.**
The October signatures require exactly one display; unknown containers hide
the HUD rather than being guessed from main-window or screen geometry.
Previously supported September signatures and legacy behavior are retained.

Eleven October regression tests compiled before implementation and produced
31 failed assertions; three negative safety tests already passed as expected.
They cover top alignment, odd/even widths, movement, the plain layout,
menu-bar-adjusted height, on-screen visual centers, unsupported multi-display
mode, ownership/title/layer/visibility gates, exact tolerance and ambiguity
across all four known native signatures and legacy evidence.

Verification on 2026-10-18:

- All 203 Swift tests and all eight Shell checks passed, including the added
  shared-Mini characterization test. Release build and signature verification
  passed. Independent review found no remaining issues under the explicitly
  accepted shared-overlay behavior.
- The installed release diagnostic exited 0 with `configuration=ok`,
  `pet=found`, `petWindow=found`, and `provider=reachable`.
- The restarted HUD exposed its layer-4 tactical window at `(56, 703, 217, 83)`,
  centered above the visual pet rect `(88, 794, 153, 166)`. A HUD-only capture
  confirmed HP, MP and all seven SP cells rendered; no desktop/chat/pet capture
  was used.
- The preceding HUD was preserved as a recoverable app backup. HUD configuration,
  Codex configuration, LaunchAgent plist and Codex `app.asar` hashes were unchanged.
- Movement/resizing are covered by geometry regression tests. Human drag-follow
  acceptance is pending; this record does not claim manual resize or Mini-mode
  visual acceptance.

## Codex/ChatGPT 26.917.51856 update

On 2026-09-23, the installed 26.901 compatibility patch still ran and the
quota provider was reachable, but `petWindow=missing` returned after updating
Codex. Redacted live window metadata was `(842, -645, 1128, 2129)`, layer 3,
owned by the verified `com.openai.codex` process. Open and visible settings
were true, and the configured pet width was 153.

Read-only inspection of the installed native layout code established that
horizontal animation overscan changed. The native pet still uses an 80x87
drawing anchor and a 384-point viewport; the usable tray width is 356.
With damping 18.85, mass 1 and stiffness 180, spring overscan rounds up to 16
points. The surface extends from -688 to +440 relative to the drawing
anchor's left edge, producing width 1128. Its pet-center offset from the
surface center is therefore `688 + 40 - 1128/2 = +164`, not the old -14.
The same geometry was evaluated for display widths 800, 1024, 1874, 1920
and 2560. The vertical contract remains `2 * maxNativeDisplayHeight - 31`.

The September adapter added these two exact signatures:

| Observed layout | Surface width | Pet center relative to surface center |
| --- | ---: | ---: |
| 26.901.31953 | 772 | -14 horizontally |
| 26.917.51856 | 1128 | +164 horizontally |

Both keep the existing one-point geometry tolerance. Unknown shapes still
fail closed; this is not a broad large-window fallback. Candidate uniqueness
is checked across both signatures, so simultaneous old/new containers are
ambiguous. Owner, PID, layer, title, open/visible settings, height, on-display
pet center and conflicting legacy evidence remain required checks.

For the live fixture, the new visual rect is `(1493.5, 336.5, 153, 166)`,
consistent within rounding with the application's saved anchor `(1493, 337)`.
Saved coordinates were used only as a diagnostic cross-check, never as a
runtime positioning source. Runtime settings reads and privacy boundaries
are unchanged.

Eight additional regression tests cover the new anchor, movement, resizing,
multi-display height, edge containment, redacted titles, strict matching and
mixed-signature ambiguity. Before the fix they produced 12 failed assertions;
the negative safety-gate test already passed as expected.

Verification on 2026-09-23:

- All 191 Swift tests and all eight Shell checks passed, including release
  build/signature verification and temporary-home installation checks.
- Independent read-only source review found no blocking issues.
- The installed release diagnostic exited 0 with `configuration=ok`,
  `pet=found`, `petWindow=found`, and `provider=reachable`.
- Live layer-4 HUD bounds were `(1461, 246, 217, 83)`, centered (within integer
  rounding) above the visual pet rect. A HUD-only capture confirmed HP, MP
  and all seven SP cells rendered; no desktop/chat/pet capture was used.
- The preceding HUD was kept as an app backup. HUD configuration, Codex
  configuration, LaunchAgent plist and Codex `app.asar` hashes were unchanged.
- Movement and resizing are regression-tested; manual drag acceptance is
  still pending for this app build.

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
Ordinary main windows do not meet these signatures. The October 1138-point
surface is shared with Mini / Quick Chat, so the geometry and persisted settings
gates alone do not prove current pet visibility; see the accepted limitation above.
Legacy matching remains available unchanged. Unsupported geometry or settings
syntax hides the native HUD rather than guessing.

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
