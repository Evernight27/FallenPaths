#!/usr/bin/env bash
# Flathub Godot launcher (selected by _godot.sh when available).
set -euo pipefail
exec flatpak run org.godotengine.Godot "$@"
