#!/usr/bin/env bash
# Parses every script by booting the game headless for a few frames; prints script errors.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/godot.sh" --headless --path "$HERE/../game" --import >/dev/null 2>&1
timeout 120 "$HERE/godot.sh" --headless --path "$HERE/../game" --quit-after "${1:-120}" 2>&1 | grep -E -A2 "SCRIPT ERROR|Parse Error|ERROR:" | grep -v "^--$" | head -40
