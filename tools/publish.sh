#!/usr/bin/env bash
# Builds the web version and stages it in public/, the folder GitHub Pages serves
# (.github/workflows/pages.yml uploads it on every push to main that touches public/).
# Pages can't run Godot, so the exported files are committed.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/build_web.sh"
DIST="$HERE/../public"
mkdir -p "$DIST"
cp "$HERE/../build/web/"index.* "$DIST/"
echo "[publish] staged in public/:"; ls -la "$DIST" | awk 'NR>1 {printf "  %10s  %s\n", $5, $9}'
