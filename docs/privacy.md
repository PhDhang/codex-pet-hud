# Privacy

Codex Pet HUD is designed around a narrow, local credential boundary.

## Data Read

- The configured Codex v2 pet manifest and spritesheet.
- The local Codex authentication document, decoded only for the access token
  and optional account identifier required by the quota request.
- The public macOS window list for geometry and window-title matching.
- The HUD configuration and normalized snapshot cache.

## Network Request

The app makes a read-only HTTPS `GET` request to the ChatGPT usage endpoint at
the configured refresh interval. It does not submit prompts, modify account
data, or send pet artwork.

## Data Stored

- Configuration is stored with user-only file permissions.
- The cache contains only fetched time, remaining percentage, reset time, and
  reset-window duration.
- Credentials, account identifiers, email addresses, cookies, and raw
  provider responses are never written to the cache or logs.

## Data Not Accessed

The app does not read browser cookies, browser profiles, macOS Keychain,
conversation content, source repositories, prompts, or unrelated Codex state.
It does not request Accessibility, Screen Recording, camera, microphone, or
location permission.

## Diagnostics

Diagnostics emit fixed status labels and normalized quota values. The
redaction layer removes credential-shaped strings, email addresses, and
account identifiers before error text is printed.
