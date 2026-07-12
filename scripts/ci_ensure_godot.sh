#!/usr/bin/env bash
# CI: ensure Godot editor binary under $GODOT_DIR.
set -euo pipefail
GODOT_VERSION="${GODOT_VERSION:-4.7-stable}"
GODOT_BIN_NAME="${GODOT_BIN_NAME:-Godot_v4.7-stable_linux.x86_64}"
GODOT_DIR="${GODOT_DIR:-${RUNNER_TEMP:-/tmp}/godot}"
BIN="$GODOT_DIR/$GODOT_BIN_NAME"
[[ -x "$BIN" ]] && { echo "$BIN"; exit 0; }
mkdir -p "$GODOT_DIR"
ZIP="${TMPDIR:-/tmp}/godot-${GODOT_VERSION}.zip"
curl -fL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_BIN_NAME}.zip" -o "$ZIP"
file "$ZIP" | grep -qi 'zip archive'
unzip -o "$ZIP" -d "$GODOT_DIR"
chmod +x "$BIN"
test -x "$BIN"
echo "$BIN"
