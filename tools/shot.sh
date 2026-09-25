#!/usr/bin/env bash
# Screenshot a scene under Xvfb (software GL):  tools/shot.sh out.png [scene] [frames] [WxH]
#   scenes: title run night boss final levelup poi pause end
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(realpath -m "$1")"; SCENE="${2:-title}"; FRAMES="${3:-120}"; RES="${4:-1280x590}"
W="${RES%x*}"; H="${RES#*x}"
xvfb-run -a -s "-screen 0 ${W}x${H}x24" "$HERE/godot.sh" --path "$HERE/../game" --rendering-driver opengl3 \
  --resolution "${W}x${H}" -- --shot="$OUT" --scene="$SCENE" --frames="$FRAMES" 2>&1 | grep -E "shot saved|ERROR|SCRIPT" | head -20
