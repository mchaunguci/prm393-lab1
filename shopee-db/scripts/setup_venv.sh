#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$ROOT/../.." && pwd)"
TARGET="$ROOT/pydeps"
TMP="$PROJECT/.tmp"
CACHE="$PROJECT/.pip-cache"
BROWSERS="$PROJECT/.playwright-browsers"
REQ="$ROOT/requirements.txt"

mkdir -p "$TARGET" "$TMP" "$CACHE" "$BROWSERS"
export TMPDIR="$TMP" PIP_CACHE_DIR="$CACHE" PLAYWRIGHT_BROWSERS_PATH="$BROWSERS"
export PYTHONPATH="$TARGET:$ROOT"

echo "Cài dependencies vào $TARGET ..."
pip3 install --target "$TARGET" --no-cache-dir -r "$REQ"

echo ""
echo "Cài Chromium cho Playwright ..."
python3 -m playwright install chromium

echo ""
echo "✓ Sẵn sàng. Chạy API:"
echo "  ./start_api.sh"
