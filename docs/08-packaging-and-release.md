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

## CI release checklist

The `release.yml` workflow degrades gracefully: a tag with **no** signing secrets
publishes an **unsigned pre-release**; once the secrets exist it publishes a
**signed + notarized** release. Steps, in order:

### 1. Put the repo on GitHub (one-time)

> Do the "Tackit" trademark spot-check and confirm you want it public first.

```sh
git remote add origin git@github.com:OWNER/tackit.git
git push -u origin main
```

### 2. Signing secrets (one-time — needs an Apple Developer Program membership)

1. Create a **Developer ID Application** certificate (Xcode → Settings → Accounts →
   your team → Manage Certificates → + → Developer ID Application).
2. Export it **with its private key** from Keychain Access as `Certificates.p12`, then:
   ```sh
   base64 -i Certificates.p12 | pbcopy      # → paste into the MACOS_CERT_P12 secret
   ```
3. Create an **app-specific password** at appleid.apple.com → Sign-In & Security.
4. In GitHub → Settings → Secrets and variables → Actions, add:
   `MACOS_CERT_P12`, `MACOS_CERT_PASSWORD`, `MACOS_KEYCHAIN_PASSWORD`,
   `SIGN_IDENTITY` (`Developer ID Application: Name (TEAMID)`), `APPLE_ID`,
   `APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`.

### 3. Cut a release

```sh
git tag v0.0.1
git push origin v0.0.1
```

The workflow builds, (signs + notarizes when secrets are set), and publishes the
DMG to a GitHub release. Then update `packaging/tackit.rb` (`OWNER/REPO`, version,
DMG `sha256`) in your Homebrew tap.

### Unsigned pre-release right now

Push a tag **without** the signing secrets → the workflow publishes an unsigned
`Tackit.dmg` marked as a pre-release, so you can exercise the whole pipeline and
share a test build before enrolling. (Testers open it via right-click → Open.)

## Deferred to a later pass

- Sparkle auto-update (appcast + EdDSA) — cask would gain `auto_updates true`.
- XCUITest end-to-end + the <300 ms first-keystroke latency gate in CI.
