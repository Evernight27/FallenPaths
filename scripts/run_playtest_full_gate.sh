#!/usr/bin/env bash
# Full Playtest closeout (no Phase 0): merge gaps + revalidate + optional Exp-0.2 smokes gate.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRA=()
for arg in "$@"; do
	case "$arg" in
		--dry-run) EXTRA+=(-DryRun) ;;
		--human-signoff) EXTRA+=(-HumanSignOff) ;;
		--skip-exp0) EXTRA+=(-SkipExp0) ;;
	esac
done
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run_playtest_full_gate.ps1" "${EXTRA[@]}"
exit $?
