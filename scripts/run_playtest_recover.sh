#!/usr/bin/env bash
# Recover human F5 paste after Phase 0 clobber + merge validator gaps (no Phase 0).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRA=()
for arg in "$@"; do
	case "$arg" in
		--dry-run) EXTRA+=(-DryRun) ;;
		--human-signoff) EXTRA+=(-HumanSignOff) ;;
		--force-restore) EXTRA+=(-ForceRestore) ;;
	esac
done
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run_playtest_recover.ps1" "${EXTRA[@]}"
exit $?
