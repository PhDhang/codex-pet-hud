# Security Policy

## Supported Versions

Security fixes are applied to the latest release.

## Reporting

Please report security issues privately through GitHub Security Advisories.
Do not open a public issue containing credentials, local account identifiers,
raw provider responses, or diagnostic logs that have not been reviewed.

## Credential Boundary

Codex Pet HUD reads only the minimum local fields needed to make a quota
request. Credentials are kept in memory, are never written to the snapshot
cache, and are redacted from diagnostics. The project does not inspect browser
profiles, cookies, Keychain items, or unrelated Codex files.

The application is ad-hoc signed when built from source. Review the source and
build scripts before installation.
