# Five-Hour MP Meter Design

## Goal

Extend the tactical Codex Pet HUD with an MP meter for an optional five-hour
quota window while preserving the weekly HP meter, seven-flame SP reset
indicator, generic Codex v2 pet compatibility, and HUD-only behavior.

## Scope

- Add an MP row directly below HP.
- Keep HP mapped to the seven-day quota window.
- Map MP to a five-hour quota window only when the provider reports one.
- Show `MAX` when a successful provider response contains a valid weekly window
  but no five-hour window.
- Do not show a five-hour reset countdown.
- Do not create, replace, cover, or animate the pet in response to quota state.
- Preserve the existing pet-following, resizing, window-level, and idle-presence
  behavior.

## Quota Model

`QuotaSnapshot` gains an optional `fiveHour: QuotaWindow?` property alongside
the required weekly window.

The optional property keeps cached snapshots backward compatible: cache files
written before this feature omit `fiveHour` and decode it as `nil`.

The normalized model distinguishes three states:

1. A valid five-hour window is present, so MP shows its remaining percentage.
2. A valid weekly window is present but the five-hour window is absent, so MP
   shows `MAX`.
3. No trustworthy snapshot is available, so MP shows `--`.

The model never represents an absent five-hour limit as a synthetic 100%
window.

## Provider Parsing

The parser recognizes windows by `limit_window_seconds`:

- `604800` seconds is the weekly HP window.
- `18000` seconds is the five-hour MP window.

When both provider windows exist, the expected mapping is:

- `secondary_window` → weekly HP
- `primary_window` → five-hour MP

When only `primary_window` exists and its duration is `604800`, it remains a
valid weekly-only response and MP is `MAX`.

An unknown primary duration is ignored for MP when a valid weekly secondary
window exists. The parser still rejects responses without any valid weekly
window. Missing `limit_window_seconds` remains accepted only for the secondary
weekly window, preserving the current provider compatibility behavior.

## Presentation Data

`HUDPresentationData` gains:

- `mpText: String`
- `mpFraction: Double`
- `mpMode`, distinguishing percentage, unlimited, and unavailable states
- independent HP and MP danger levels used by the view

HP precision remains canonicalized to one decimal place rounded down. MP uses
the same precision and percentage formatting.

Presentation rules:

- Fresh or stale snapshot with five-hour data: show MP percentage and fraction.
- Fresh or stale snapshot without five-hour data: show a full MP bar with
  centered `MAX`.
- Offline or authentication-required state: show `--` and no filled MP value.
- Weekly HP continues to determine the bottom status label and existing weekly
  low/critical wording.

## HUD Layout

The tactical HUD becomes a four-row stack:

1. HP percentage meter
2. MP percentage or `MAX` meter
3. SP seven-flame reset progress
4. Status label

The width calculation and alignment remain unchanged. The base panel height and
layout metrics increase enough to fit the MP row at every supported
`podScale`. HP and MP share label, bar, and trailing-value geometry so the
meters remain visually aligned.

For unlimited MP:

- the bar is fully filled in orange;
- `MAX` is centered inside the bar;
- the trailing percentage field is empty.

For measured MP:

- the fill uses the five-hour remaining fraction;
- the percentage appears in the trailing field;
- no reset time appears anywhere in the MP row.

## Color and Motion

Normal colors:

- HP uses the existing weekly quota palette.
- MP uses orange.
- SP keeps its red/orange lit flames and blue/cyan unlit flames.

Each meter evaluates its own remaining percentage:

- above `9%`: no flashing;
- `4–9%`: slow autoreversing danger pulse;
- `0–3%`: faster, higher-contrast danger pulse.

HP pulses between its normal cyan/green appearance and red.

MP pulses between orange and an icy blue-white appearance.

When Reduce Motion is enabled, animation stops:

- dangerous HP is fixed at red;
- dangerous MP is fixed at icy blue-white.

The animations affect only the relevant meter. They never add pet windows,
images, overlays, replacement frames, or movement.

## Diagnostics and Privacy

The redacted diagnostic report gains:

- `fiveHourRemainingPercent`, present only when a five-hour window exists;
- a non-sensitive window-source/status field that distinguishes measured MP
  from unlimited MP.

Diagnostics continue to omit tokens, account identifiers, emails, cookies, and
raw provider payloads.

## Error Handling

- A valid weekly response remains usable if the five-hour window is absent or
  has an unknown duration.
- A response without a recognizable weekly window remains invalid.
- Cached weekly-only snapshots remain valid and present MP as `MAX`.
- Offline and authentication-required states never claim `MAX`, because the
  provider response was not successfully observed.
- Stale snapshots preserve the last known measured or unlimited MP state and
  retain the existing stale status label.

## Testing

Automated coverage will include:

- parsing a secondary weekly plus primary five-hour response;
- parsing a primary-only weekly response as unlimited MP;
- ignoring an unknown primary duration when secondary weekly data is valid;
- rejecting responses without a valid weekly window;
- decoding legacy cache files without `fiveHour`;
- round-tripping snapshots with five-hour data;
- MP `MAX`, percentage, offline, and authentication presentation;
- HP and MP danger thresholds at `9`, `4`, and `3` percent boundaries;
- four-row layout fit at compact, default, and expanded scales;
- source guards proving no pet-effect runtime or assets return;
- accessibility labels for measured, unlimited, and unavailable MP;
- Reduce Motion behavior and independent HP/MP animation values;
- signed build, installation, redacted diagnostics, and HUD-only visual
  captures on macOS.

## Release

The existing HUD stability changes and this MP feature will be reviewed
together, verified locally, installed for the selected pet, and then committed
and pushed to the current GitHub feature branch. The existing draft pull
request will be updated rather than replaced.
