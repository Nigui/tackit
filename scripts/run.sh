#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f Sources/TackitApp/Resources/editor/bundle.js ]; then
  echo "==> web bundle missing; building TipTap bundle"
  ( cd editor && pnpm install --silent && pnpm build ) \
    || echo "==> WARN: web build failed (network?). Using fallback contenteditable editor."
fi

echo "==> swift build"
swift build -c debug
BIN="$(swift build -c debug --show-bin-path)"

APP="build/Tackit.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/tackit" "$APP/Contents/MacOS/tackit"
if [ -d "$BIN/Tackit_TackitApp.bundle" ]; then
  cp -R "$BIN/Tackit_TackitApp.bundle" "$APP/Contents/MacOS/"
  cp -R "$BIN/Tackit_TackitApp.bundle" "$APP/Contents/Resources/"
fi
cp packaging/Info.plist "$APP/Contents/Info.plist"

echo "==> stopping any running Tackit instance"
killall tackit 2>/dev/null || true
for _ in $(seq 1 20); do
  pgrep -x tackit >/dev/null || break
  sleep 0.1
done

echo "==> launching Tackit.app (menu-bar agent; press Cmd+Shift+. to open a sticky)"
echo "==> watch numbers:  log stream --predicate 'eventMessage CONTAINS \"[Tackit]\"' --style compact"
open -n "$APP"
