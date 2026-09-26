#!/usr/bin/env bash
# Parses every script by booting the game headless for a few frames; prints script errors.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# timeout(1) is GNU coreutils: gtimeout on macOS with coreutils, else run without a limit
TO=(); for t in timeout gtimeout; do command -v $t >/dev/null 2>&1 && { TO=($t 120); break; }; done
"$HERE/godot.sh" --headless --path "$HERE/../game" --import >/dev/null 2>&1
${TO[@]+"${TO[@]}"} "$HERE/godot.sh" --headless --path "$HERE/../game" --quit-after "${1:-120}" 2>&1 | grep -E -A2 "SCRIPT ERROR|Parse Error|ERROR:" | grep -v "^--$" | head -40
