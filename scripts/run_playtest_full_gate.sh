#!/usr/bin/env bash
# Full Playtest closeout (no Phase 0): merge gaps + revalidate + optional Exp-0.2.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
HUMAN_SIGNOFF=0
SKIP_EXP0=0
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--skip-exp0) SKIP_EXP0=1 ;;
	esac
done

echo "=== Playtest full gate ==="
PHASE0="$ROOT/.phase0_combat_checks.txt"
if ! { [[ -f "$PHASE0" ]] && grep -q '^PHASE0: PASS' "$PHASE0" && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0"; }; then
	fp_die "PLAYTEST_FULL_GATE: FAIL (headless not green — ./scripts/run_all_combat_checks.sh)"
fi

if [[ $DRY_RUN -eq 1 ]]; then
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	f5_ensure_validation_fresh "$ROOT" || true
	mapfile -t PLAN < <(f5_gap_merge_plan "$ROOT" "$ROOT/.f5_soak_validation.txt")
	echo "Merge plan: ${#PLAN[@]} append(s)"
	for row in "${PLAN[@]:-}"; do
		[[ -n "${row:-}" ]] || continue
		IFS='|' read -r track label path <<<"$row"
		echo "  [$track] $label <- $path"
	done
	exit 0
fi

bash "$SCRIPT_DIR/run_playtest_merge_gaps.sh" --skip-revalidate
REV=()
[[ $HUMAN_SIGNOFF -eq 1 ]] && REV+=(--human-signoff)
bash "$SCRIPT_DIR/run_playtest_revalidate.sh" "${REV[@]}"
[[ $SKIP_EXP0 -eq 1 ]] && exit 0
bash "$SCRIPT_DIR/run_exp0_playtest_gate.sh" --skip-closeout
echo "PLAYTEST_FULL_GATE: PASS"
