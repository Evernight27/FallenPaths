#!/usr/bin/env bash
# Merge validator gaps into .f5_soak_in.txt (no Phase 0).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

echo "=== Playtest merge gaps ==="
f5_restore_human_paste_if_clobbered "$ROOT" || true
LOG="$(f5_soak_log_path "$ROOT")"
[[ -f "$LOG" ]] || fp_die "PLAYTEST_MERGE_GAPS: FAIL (missing .f5_soak_in.txt)"
f5_is_headless_capture_only "$LOG" && fp_die "PLAYTEST_MERGE_GAPS: FAIL (headless capture)"

f5_ensure_validation_fresh "$ROOT" || fp_die "PLAYTEST_MERGE_GAPS: FAIL (validate before merge)"
VAL="$ROOT/.f5_soak_validation.txt"
mapfile -t PLAN < <(f5_gap_merge_plan "$ROOT" "$VAL")
if [[ ${#PLAN[@]} -eq 0 ]]; then
	echo "PLAYTEST_MERGE_GAPS: no gaps"
	[[ $SKIP_REVALIDATE -eq 1 || $DRY_RUN -eq 1 ]] && exit 0
	REV=()
	[[ $HUMAN_SIGNOFF -eq 1 ]] && REV+=(--human-signoff)
	exec bash "$SCRIPT_DIR/run_playtest_revalidate.sh" "${REV[@]}"
fi

echo "Gaps found: ${#PLAN[@]}"
for row in "${PLAN[@]}"; do
	IFS='|' read -r track label path <<<"$row"
	echo "  [$track] $label <- $path"
done
[[ $DRY_RUN -eq 1 ]] && { echo "PLAYTEST_MERGE_GAPS: dry-run"; exit 0; }

for row in "${PLAN[@]}"; do
	IFS='|' read -r _track label path <<<"$row"
	[[ -f "$path" ]] || fp_die "PLAYTEST_MERGE_GAPS: FAIL (missing $path)" 2
	bash "$SCRIPT_DIR/append_f5_soak_log.sh" "$path" --label "$label" --skip-preflight \
		|| fp_die "PLAYTEST_MERGE_GAPS: FAIL (append $label)"
done

[[ $SKIP_REVALIDATE -eq 1 ]] && { echo "PLAYTEST_MERGE_GAPS: PASS (skipped revalidate)"; exit 0; }
REV=()
[[ $HUMAN_SIGNOFF -eq 1 ]] && REV+=(--human-signoff)
bash "$SCRIPT_DIR/run_playtest_revalidate.sh" "${REV[@]}" \
	|| fp_die "PLAYTEST_MERGE_GAPS: FAIL (post-merge revalidate)"
echo "PLAYTEST_MERGE_GAPS: PASS"
