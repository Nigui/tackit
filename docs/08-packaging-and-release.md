# Packaging & release

Tackit ships as a Developer-ID-signed, notarized `.dmg`, installable via a
Homebrew cask. We assemble the `.app` from the SwiftPM build (no `.xcodeproj`);
`codesign` + `notarytool` work directly on that bundle.

## Artifacts

- `packaging/Info.plist` — bundle id `app.tackit.mac`, `LSUIElement` (menu-bar agent), icon, category.
- `packaging/Tackit.entitlements` — hardened runtime, **not** sandboxed (global hotkey + note-store file access).
- `packaging/AppIcon.png` / `AppIcon.icns` — **placeholder** icon; replace `AppIcon.png` with real 1024×1024 branding and rerun `scripts/make-icon.sh`.
- `packaging/tackit.rb` — Homebrew cask template.
- `scripts/make-icon.sh` — `AppIcon.png` → `AppIcon.icns` (generates a placeholder if the PNG is missing).
- `scripts/package.sh` — build + assemble + (sign) + `.dmg` + (notarize + staple).

## Local build (unsigned)

```sh
./scripts/package.sh
# → dist/Tackit.app + dist/Tackit.dmg (unsigned; Gatekeeper blocks on other Macs)
```

## Signed + notarized build

One-time: a **Developer ID Application** certificate in your keychain, and an
app-specific password for notarization.

```sh
# store notary credentials once (creates a reusable keychain profile)
xcrun notarytool store-credentials tackit-notary \
  --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-pw"

SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE=tackit-notary \
./scripts/package.sh
```

The script prints the DMG `sha256`.

## Release via CI

Push a `vX.Y.Z` tag → `.github/workflows/release.yml` builds, signs, notarizes,
and creates a GitHub release with the DMG. It needs these repo secrets:
`MACOS_CERT_P12` (base64 .p12), `MACOS_CERT_PASSWORD`, `MACOS_KEYCHAIN_PASSWORD`,
`SIGN_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`.

## Homebrew cask

Copy `packaging/tackit.rb` into a tap repo, set `OWNER/REPO`, bump `version`, and
paste the DMG `sha256`. Then `brew install --cask tackit`.

## Deferred to a later pass

- Sparkle auto-update (appcast + EdDSA) — cask would gain `auto_updates true`.
- XCUITest end-to-end + the <300 ms first-keystroke latency gate in CI.
