#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$ROOT/../.." && pwd)"

export PYTHONPATH="$ROOT/pydeps:$ROOT"
export TMPDIR="$PROJECT/.tmp"
export PLAYWRIGHT_BROWSERS_PATH="$PROJECT/.playwright-browsers"

mkdir -p "$TMPDIR"

if [[ ! -d "$ROOT/pydeps" ]]; then
  echo "Chưa cài dependencies. Chạy: ./setup_venv.sh"
  exit 1
fi

echo "Shopee Crawl API → http://127.0.0.1:8765"
echo "  Health:  GET /health"
echo "  Search:  GET /api/search?keyword=rtx5090&limit=60"
echo ""

exec python3 "$ROOT/search_api.py"
