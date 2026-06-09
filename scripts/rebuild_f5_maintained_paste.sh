#!/usr/bin/env bash
# Rebuild maintained human F5 paste from followup.log + standard append plan.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASELINE="${1:-followup.log}"
EXTRA=()
shift || true
for arg in "$@"; do
	case "$arg" in
		--skip-preflight) EXTRA+=(-SkipPreflight) ;;
		--human-signoff) EXTRA+=(-HumanSignOff) ;;
		--dry-run) EXTRA+=(-DryRun) ;;
	esac
done
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/rebuild_f5_maintained_paste.ps1" -BaselineFrom "$BASELINE" "${EXTRA[@]}"
exit $?
