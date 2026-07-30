# Privacy

Codex Pet HUD is designed around a narrow, local credential boundary.

## Data Read

- The configured Codex v2 pet manifest and spritesheet.
- The local Codex authentication document, decoded only for the access token
  and optional account identifier required by the quota request.
- The public macOS window list for geometry and title matching.
- HUD configuration, normalized snapshot cache, and local geometry cache.

## Network Request

The app makes a read-only HTTPS `GET` request to the ChatGPT usage endpoint at
the configured refresh interval. It does not submit prompts, modify account
data, or send pet artwork.

## Data Stored

- Configuration has user-only file permissions.
- The snapshot cache contains fetched time, remaining percentage, reset time,
  and reset-window duration only.
- The geometry cache contains window bounds, PID, window ID, and timestamp only.
- Credentials, account identifiers, email addresses, cookies, and raw provider
  responses are never written to caches or logs.

## Data Not Accessed

The app does not read browser cookies, browser profiles, macOS Keychain,
conversation content, source repositories, prompts, or unrelated Codex state.
It does not request Accessibility, Screen Recording, camera, microphone, or
location permission.

## Diagnostics and Release Checks

Diagnostics emit fixed status labels and normalized quota values. The redaction
layer removes credential-shaped strings, email addresses, and account identifiers
before error text is printed. Before publishing, scan release files:

```bash
scan_pattern='/Users/[A-Za-z0-9._-]+/|Bearer[[:space:]]+eyJ[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9_-]{20,}'
release_content=()
while IFS= read -r tracked_file; do
  if [ "$tracked_file" != "Tests/Shell/release-validation.bats" ]; then
    release_content+=("$tracked_file")
  fi
done < <(git ls-files)
if rg -q "$scan_pattern" "${release_content[@]}"; then
  printf 'Release privacy scan failed.\n' >&2
  exit 1
fi
```
