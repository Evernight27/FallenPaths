#!/usr/bin/env bash
# CI helper: ensure Godot editor binary exists under $GODOT_DIR (default: ${RUNNER_TEMP:-/tmp}/godot).
# Env: GODOT_VERSION (default 4.7-stable), GODOT_BIN_NAME (default Godot_v4.7-stable_linux.x86_64).
set -euo pipefail
GODOT_VERSION="${GODOT_VERSION:-4.7-stable}"
GODOT_BIN_NAME="${GODOT_BIN_NAME:-Godot_v4.7-stable_linux.x86_64}"
GODOT_DIR="${GODOT_DIR:-${RUNNER_TEMP:-/tmp}/godot}"
BIN="$GODOT_DIR/$GODOT_BIN_NAME"
if [[ -x "$BIN" ]]; then
	echo "$BIN"
	exit 0
fi
mkdir -p "$GODOT_DIR"
ZIP="${TMPDIR:-/tmp}/godot-${GODOT_VERSION}.zip"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_BIN_NAME}.zip"
curl -fL "$URL" -o "$ZIP"
file "$ZIP" | grep -qi 'zip archive'
unzip -o "$ZIP" -d "$GODOT_DIR"
chmod +x "$BIN"
test -x "$BIN"
echo "$BIN"
