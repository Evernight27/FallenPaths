#!/usr/bin/env bash
# Source from scripts/*.sh — do not execute directly.
fp_project_root() {
	(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
}

fp_godot_bin() {
	if [[ -n "${GODOT:-}" ]]; then
		echo "$GODOT"
		return 0
	fi
	if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
		echo "/Applications/Godot.app/Contents/MacOS/Godot"
		return 0
	fi
	if [[ -x "e:/Godot_v4.6-stable_win64.exe" ]]; then
		echo "e:/Godot_v4.6-stable_win64.exe"
		return 0
	fi
	return 1
}

fp_godot_import_warmup() {
	local root="$1"
	local godot
	godot="$(fp_godot_bin)" || return 1
	"$godot" --headless --path "$root" --import >/dev/null 2>&1 || true
	sleep 2
}
