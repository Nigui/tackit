#!/usr/bin/env bash
# Build packaging/AppIcon.icns from packaging/AppIcon.png (1024×1024).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="packaging/AppIcon.png"
if [ ! -f "$SRC" ]; then
  echo "==> $SRC missing — generating a placeholder"
  swift scripts/make-icon-placeholder.swift "$SRC"
fi

ICONSET="packaging/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$SRC" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o packaging/AppIcon.icns
rm -rf "$ICONSET"
echo "==> wrote packaging/AppIcon.icns"
