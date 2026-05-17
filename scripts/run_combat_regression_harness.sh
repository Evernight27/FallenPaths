#!/usr/bin/env bash
# Headless combat regression — do not pipe stdout to grep (see AGENTS.md).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${GODOT:-}" ]]; then
	GODOT_BIN="$GODOT"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
	GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
else
	echo "run_combat_regression_harness.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
fi
exec "$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_combat_regression_harness.gd
