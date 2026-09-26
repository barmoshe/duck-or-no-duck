#!/usr/bin/env bash
# Builds the web version (single-threaded, runs in iPhone Safari) into build/web/.
# The Godot 4.7.2 web export templates are fetched on first use (web files only are kept).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$HERE/../game"
OUT="$HERE/../build/web"
VER="4.7.2"
TPL_DIR="$HOME/.local/share/godot/export_templates/${VER}.stable"
[ "$(uname)" = "Darwin" ] && TPL_DIR="$HOME/Library/Application Support/Godot/export_templates/${VER}.stable"
CACHE="${DUCK_BUILD_CACHE:-$HOME/.cache/duck-build}"
log() { echo "[build_web] $*"; }

if [ ! -f "$TPL_DIR/web_nothreads_release.zip" ]; then
  log "downloading the Godot ${VER} export templates (web only are kept)"
  mkdir -p "$CACHE/tpl" "$TPL_DIR"
  curl -sSfL -C - --retry 3 -o "$CACHE/templates.tpz" "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_export_templates.tpz"
  unzip -o -q "$CACHE/templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$CACHE/tpl"
  cp "$CACHE"/tpl/templates/web_* "$CACHE"/tpl/templates/version.txt "$TPL_DIR/"
  rm -f "$CACHE/templates.tpz"
fi

rm -f "$OUT"/index.* 2>/dev/null || true
mkdir -p "$OUT"
"$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1 || true
log "exporting to $OUT"
"$HERE/godot.sh" --headless --path "$GAME" --export-release "Web" "$OUT/index.html" > "$OUT/../web-export.log" 2>&1 || true
[ -f "$OUT/index.html" ] && [ -f "$OUT/index.wasm" ] || { log "export failed, see build/web-export.log"; tail -20 "$OUT/../web-export.log"; exit 1; }
cp "$HERE/web/index.manifest.json" "$OUT/"
cp "$GAME/assets/icon/icon_180.png" "$OUT/index.180x180.png"
cp "$GAME/assets/icon/icon_512.png" "$OUT/index.512x512.png"
STAMP="$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo dev)"
git -C "$HERE" diff --quiet HEAD -- "$GAME" 2>/dev/null || STAMP="$STAMP+"
sed -i.bak "s|__DUCK_BUILD__|$STAMP|" "$OUT/index.html" && rm -f "$OUT/index.html.bak"
grep -q "duckBuild = '$STAMP'" "$OUT/index.html" || { log "build stamp missing from index.html"; exit 1; }
log "build stamp: $STAMP"
ls -la "$OUT" | awk 'NR>1 {printf "  %10s  %s\n", $5, $9}'
