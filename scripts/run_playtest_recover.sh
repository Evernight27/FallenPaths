#!/usr/bin/env bash
# Recover human F5 paste after Phase 0 clobber + merge gaps (no Phase 0).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
HUMAN_SIGNOFF=0
FORCE_RESTORE=0
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--force-restore) FORCE_RESTORE=1 ;;
	esac
done

echo "=== Playtest recover ==="
LOG="$(f5_soak_log_path "$ROOT")"
BAK="$(f5_soak_backup_path "$ROOT")"
if ! f5_restore_human_paste_if_clobbered "$ROOT"; then
	if [[ -f "$LOG" ]] && f5_is_headless_capture_only "$LOG" && [[ -f "$BAK" ]]; then
		if [[ $FORCE_RESTORE -eq 1 ]]; then
			[[ $DRY_RUN -eq 0 ]] && f5_restore_human_paste "$ROOT"
			[[ $DRY_RUN -eq 1 ]] && echo "Would restore from $BAK"
		else
			fp_die "PLAYTEST_RECOVER: FAIL (headless capture — use --force-restore)" 2
		fi
	fi
fi
[[ -f "$LOG" ]] || fp_die "PLAYTEST_RECOVER: FAIL (missing .f5_soak_in.txt)" 2
f5_is_headless_capture_only "$LOG" && fp_die "PLAYTEST_RECOVER: FAIL (still headless)" 2

if [[ $DRY_RUN -eq 1 ]]; then
	f5_ensure_validation_fresh "$ROOT" || true
	mapfile -t PLAN < <(f5_gap_merge_plan "$ROOT" "$ROOT/.f5_soak_validation.txt")
	echo "Merge gaps: ${#PLAN[@]}"
	for row in "${PLAN[@]:-}"; do
		[[ -n "$row" ]] || continue
		IFS='|' read -r track label path <<<"$row"
		echo "  [$track] $label <- $path"
	done
	echo "PLAYTEST_RECOVER: dry-run"
	exit 0
fi

f5_ensure_validation_fresh "$ROOT" || true
MERGE=()
[[ $HUMAN_SIGNOFF -eq 1 ]] && MERGE+=(--human-signoff)
bash "$SCRIPT_DIR/run_playtest_merge_gaps.sh" "${MERGE[@]}"
bash "$SCRIPT_DIR/run_playtest_status.sh" --quiet
