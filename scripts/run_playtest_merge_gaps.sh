#!/usr/bin/env bash
# Merge known validator gaps into .f5_soak_in.txt (Playtest stream — no Phase 0).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=0
HUMAN_SIGNOFF=0
SKIP_REVALIDATE=0
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--skip-revalidate) SKIP_REVALIDATE=1 ;;
	esac
done
EXTRA=()
[[ $DRY_RUN -eq 1 ]] && EXTRA+=(-DryRun)
[[ $HUMAN_SIGNOFF -eq 1 ]] && EXTRA+=(-HumanSignOff)
[[ $SKIP_REVALIDATE -eq 1 ]] && EXTRA+=(-SkipRevalidate)
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run_playtest_merge_gaps.ps1" "${EXTRA[@]}"
exit $?
