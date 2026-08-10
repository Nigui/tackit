#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> building web editor bundle (TipTap)"
( cd editor && pnpm install --silent && pnpm build )

echo "==> building swift app"
swift build -c debug

echo "==> done. launch with: ./scripts/run.sh"
