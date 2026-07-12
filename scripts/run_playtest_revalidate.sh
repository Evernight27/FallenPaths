#!/usr/bin/env bash
# Safe Playtest re-validate (no Phase 0) — human paste + optional smokes + closeout.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
HUMAN_SIGNOFF=0
SKIP_SMOKES=0
SKIP_CLOSEOUT=0
EXP0_GATE=0
for arg in "$@"; do
	case "$arg" in
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--skip-smokes) SKIP_SMOKES=1 ;;
		--skip-closeout) SKIP_CLOSEOUT=1 ;;
		--exp0-gate) EXP0_GATE=1 ;;
	esac
done

echo "=== Playtest re-validate (no Phase 0) ==="
f5_restore_human_paste_if_clobbered "$ROOT" || true
LOG="$(f5_soak_log_path "$ROOT")"
if [[ ! -f "$LOG" ]]; then
	echo "PLAYTEST_REVALIDATE: FAIL (missing .f5_soak_in.txt)"
	exit 1
fi
if f5_is_headless_capture_only "$LOG"; then
	echo "PLAYTEST_REVALIDATE: FAIL (headless D001 capture - run ./scripts/restore_f5_soak_log.sh)"
	exit 1
fi

bash "$SCRIPT_DIR/validate_f5_soak_log.sh" --quiet
if ! f5_validation_fresh "$ROOT"; then
	echo "PLAYTEST_REVALIDATE: FAIL (validate_f5_soak_log)"
	exit 1
fi

if [[ $SKIP_SMOKES -eq 0 ]]; then
	bash "$SCRIPT_DIR/validate_camp_optional_smokes.sh" --quiet
fi
f5_restore_human_paste_if_clobbered "$ROOT" || true
if ! f5_validation_fresh "$ROOT"; then
	bash "$SCRIPT_DIR/validate_f5_soak_log.sh" --quiet || true
fi
if [[ $SKIP_SMOKES -eq 0 ]] && ! f5_validation_fresh "$ROOT"; then
	f5_revalidate_human_paste "$ROOT" || true
fi

if [[ $SKIP_CLOSEOUT -eq 1 ]]; then
	echo "PLAYTEST_REVALIDATE: PASS (skipped closeout)"
	exit 0
fi

CLOSEOUT_ARGS=(--skip-revalidate)
[[ $HUMAN_SIGNOFF -eq 1 ]] && CLOSEOUT_ARGS+=(--human-signoff)
bash "$SCRIPT_DIR/run_camp_f5_closeout.sh" "${CLOSEOUT_ARGS[@]}"
if [[ $EXP0_GATE -eq 1 ]]; then
	bash "$SCRIPT_DIR/run_exp0_playtest_gate.sh" --skip-closeout || {
		echo "PLAYTEST_REVALIDATE: FAIL (Exp-0.2 gate smokes)"
		exit 1
	}
fi
echo "PLAYTEST_REVALIDATE: PASS"
exit 0
