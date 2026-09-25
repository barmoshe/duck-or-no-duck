#!/usr/bin/env bash
# Headless tests: logic checks plus bot-played runs (game/tests/sim_test.gd).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/godot.sh" --headless --path "$HERE/../game" --import >/dev/null 2>&1
OUT="$(timeout 900 "$HERE/godot.sh" --headless --path "$HERE/../game" -- --test 2>&1)"
echo "$OUT" | grep -vE "^\s*$" | grep -v "^Godot Engine"
if echo "$OUT" | grep -qE "SCRIPT ERROR|Parse Error|Invalid call|Invalid access"; then echo "TESTS: script errors"; exit 1; fi
echo "$OUT" | grep -q "TESTS: PASS"
