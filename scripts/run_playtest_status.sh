#!/usr/bin/env bash
# Fast Playtest status (no Phase 0).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
REFRESH=0
SHOW_GAPS=0
QUIET=0
for arg in "$@"; do
	case "$arg" in
		--refresh) REFRESH=1 ;;
		--show-gaps) SHOW_GAPS=1 ;;
		--smoke-labels) ;; # labels printed with status
		--quiet) QUIET=1 ;;
	esac
done

echo "=== Playtest status ==="
f5_restore_human_paste_if_clobbered "$ROOT" || true
LOG="$(f5_soak_log_path "$ROOT")"
VAL="$ROOT/.f5_soak_validation.txt"
[[ -f "$LOG" ]] || fp_die "PLAYTEST_STATUS: FAIL (missing .f5_soak_in.txt)" 2
f5_is_headless_capture_only "$LOG" && fp_die "PLAYTEST_STATUS: FAIL (headless capture)" 2

f5_ensure_validation_fresh "$ROOT" "$REFRESH" || fp_die "PLAYTEST_STATUS: FAIL (validate)"
echo "human_signoff: $(f5_human_signoff_status "$LOG")"
grep -q '^ok=true' "$VAL" 2>/dev/null || fp_die "PLAYTEST_STATUS: FAIL (ok=false)"
f5_validation_fresh "$ROOT" || fp_die "PLAYTEST_STATUS: FAIL (stale — --refresh)"

mapfile -t PLAN < <(f5_gap_merge_plan "$ROOT" "$VAL")
if [[ $SHOW_GAPS -eq 1 || ${#PLAN[@]} -gt 0 ]]; then
	if [[ ${#PLAN[@]} -eq 0 ]]; then
		echo "Merge gaps: none"
	else
		echo "Merge gaps: ${#PLAN[@]}"
		for row in "${PLAN[@]}"; do
			IFS='|' read -r track label path <<<"$row"
			echo "  [$track] $label <- $path"
		done
		[[ $SHOW_GAPS -eq 0 ]] && echo "Hint: ./scripts/run_playtest_merge_gaps.sh --dry-run"
	fi
fi

if [[ ${#PLAN[@]} -eq 0 ]]; then
	echo "PLAYTEST_STATUS: PASS"
	exit 0
fi
[[ $QUIET -eq 0 ]] && echo "Hint: ./scripts/run_playtest_merge_gaps.sh"
echo "PLAYTEST_STATUS: GAPS"
exit 1
