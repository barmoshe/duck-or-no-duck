#!/usr/bin/env bash
# Plays the web build headless as a landscape iPhone (tools/web/webtest.mjs).
#   tools/webtest.sh            test build/web (from tools/build_web.sh)
#   tools/webtest.sh <url>      test a deployed copy
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ $# -gt 0 ]; then exec node "$HERE/web/webtest.mjs" "$1"; fi
WEB="$HERE/../build/web"
[ -f "$WEB/index.html" ] || { echo "[webtest] no build: run tools/build_web.sh first" >&2; exit 1; }
PORT="${WEBTEST_PORT:-8791}"
python3 -m http.server "$PORT" --directory "$WEB" >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true' EXIT
sleep 1
node "$HERE/web/webtest.mjs" "http://localhost:$PORT/index.html"
