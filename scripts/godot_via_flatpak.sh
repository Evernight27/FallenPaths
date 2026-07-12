#!/usr/bin/env bash
# Thin launcher when Godot is installed via Flathub (common on Fedora).
# Used only when fp_godot_bin selects this path — Windows teammates use Invoke-GodotHeadless.ps1.
set -euo pipefail
exec flatpak run org.godotengine.Godot "$@"
