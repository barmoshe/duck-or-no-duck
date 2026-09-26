#!/usr/bin/env bash
# Headless tests: logic checks plus bot-played runs (game/tests/sim_test.gd).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# timeout(1) is GNU coreutils: gtimeout on macOS with coreutils, else run without a limit
TO=(); for t in timeout gtimeout; do command -v $t >/dev/null 2>&1 && { TO=($t 900); break; }; done
"$HERE/godot.sh" --headless --path "$HERE/../game" --import >/dev/null 2>&1
OUT="$(${TO[@]+"${TO[@]}"} "$HERE/godot.sh" --headless --path "$HERE/../game" -- --test 2>&1)"
echo "$OUT" | grep -vE "^\s*$" | grep -v "^Godot Engine"
if echo "$OUT" | grep -qE "SCRIPT ERROR|Parse Error|Invalid call|Invalid access"; then echo "TESTS: script errors"; exit 1; fi
echo "$OUT" | grep -q "TESTS: PASS"
