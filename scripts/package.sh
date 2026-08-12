#!/usr/bin/env bash
# Build a release Tackit.app and Tackit.dmg. Signs + notarizes when credentials
# are provided, otherwise produces an unsigned build for local testing.
#
#   SIGN_IDENTITY   "Developer ID Application: Your Name (TEAMID)"   (optional)
#   NOTARY_PROFILE  keychain profile from `notarytool store-credentials` (optional)
#
# Examples:
#   ./scripts/package.sh                        # unsigned local build
#   SIGN_IDENTITY="Developer ID Application: …" NOTARY_PROFILE=tackit ./scripts/package.sh
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Tackit"
APP="dist/${APP_NAME}.app"
DMG="dist/${APP_NAME}.dmg"

echo "==> editor bundle"
if [ ! -f Sources/TackitApp/Resources/editor/bundle.js ]; then
  ( cd editor && pnpm install --silent && pnpm build )
fi

echo "==> app icon"
[ -f packaging/AppIcon.icns ] || ./scripts/make-icon.sh

echo "==> swift build (release)"
swift build -c release
BIN="$(swift build -c release --show-bin-path)"

echo "==> assemble ${APP}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/tackit" "$APP/Contents/MacOS/tackit"
if [ -d "$BIN/Tackit_TackitApp.bundle" ]; then
  cp -R "$BIN/Tackit_TackitApp.bundle" "$APP/Contents/MacOS/"
  cp -R "$BIN/Tackit_TackitApp.bundle" "$APP/Contents/Resources/"
fi
cp packaging/Info.plist "$APP/Contents/Info.plist"
cp packaging/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  echo "==> codesign (Developer ID, hardened runtime)"
  codesign --force --options runtime --timestamp \
    --entitlements packaging/Tackit.entitlements \
    --sign "$SIGN_IDENTITY" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
else
  echo "==> SIGN_IDENTITY not set — UNSIGNED build (Gatekeeper will block on other Macs)"
fi

echo "==> build ${DMG}"
mkdir -p dist
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

if [ -n "${SIGN_IDENTITY:-}" ] && [ -n "${NOTARY_PROFILE:-}" ]; then
  echo "==> notarize + staple"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  xcrun stapler staple "$DMG"
  echo "==> notarized + stapled"
else
  echo "==> skipping notarization (need SIGN_IDENTITY + NOTARY_PROFILE)"
fi

SHA="$(shasum -a 256 "$DMG" | awk '{print $1}')"
echo "==> done: $DMG"
echo "    sha256: $SHA"
