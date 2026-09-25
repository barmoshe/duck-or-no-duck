#!/usr/bin/env bash
# Builds the web version and stages it in public/, the folder the Vercel project serves
# (git-linked, no build step on Vercel: the network here can't reach the Vercel API, and
# Vercel can't run Godot, so the exported files are committed like Wandcraft's).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/build_web.sh"
DIST="$HERE/../public"
mkdir -p "$DIST"
cp "$HERE/../build/web/"index.* "$DIST/"
cp "$HERE/web/vercel.json" "$DIST/vercel.json"
echo "[publish] staged in public/:"; ls -la "$DIST" | awk 'NR>1 {printf "  %10s  %s\n", $5, $9}'
