#!/usr/bin/env bash
# Fast Playtest status (no Phase 0) — reads .f5_soak_validation.txt; --refresh runs Godot validator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRA=()
for arg in "$@"; do
	case "$arg" in
		--refresh) EXTRA+=(-Refresh) ;;
		--show-gaps) EXTRA+=(-ShowGaps) ;;
		--smoke-labels) EXTRA+=(-SmokeLabels) ;;
		--quiet) EXTRA+=(-Quiet) ;;
	esac
done
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run_playtest_status.ps1" "${EXTRA[@]}"
exit $?
