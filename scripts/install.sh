#!/usr/bin/env bash
# One-line installer for people without Homebrew:
#   curl -fsSL https://raw.githubusercontent.com/Nigui/tackit/main/scripts/install.sh | bash
#
# Downloads the newest release DMG (incl. pre-releases), installs Tackit.app to
# /Applications, and removes the quarantine flag (current builds are unsigned).
set -euo pipefail

REPO="Nigui/tackit"
APP="Tackit.app"

echo "==> finding the latest Tackit release"
DMG_URL="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" \
  | grep -o "https://github.com/${REPO}/releases/download/[^\"]*/Tackit.dmg" \
  | head -1)"
if [ -z "${DMG_URL}" ]; then
  echo "no Tackit.dmg found in releases" >&2
  exit 1
fi
echo "    ${DMG_URL}"

tmp="$(mktemp -d)"
trap 'hdiutil detach "$tmp/mnt" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT

echo "==> downloading"
curl -fsSL "${DMG_URL}" -o "${tmp}/Tackit.dmg"

echo "==> installing to /Applications"
hdiutil attach "${tmp}/Tackit.dmg" -nobrowse -quiet -mountpoint "${tmp}/mnt"
rm -rf "/Applications/${APP}"
cp -R "${tmp}/mnt/${APP}" /Applications/
hdiutil detach "${tmp}/mnt" -quiet
xattr -dr com.apple.quarantine "/Applications/${APP}" 2>/dev/null || true

echo "==> done. Launch it:  open -a Tackit    (press ⌘⇧. to summon a note)"
