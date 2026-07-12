#!/usr/bin/env bash
# Safe Playtest re-validate (no Phase 0).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
[[ -f "$LOG" ]] || fp_die "PLAYTEST_REVALIDATE: FAIL (missing .f5_soak_in.txt)"
f5_is_headless_capture_only "$LOG" && fp_die "PLAYTEST_REVALIDATE: FAIL (headless capture — ./scripts/restore_f5_soak_log.sh)"

bash "$SCRIPT_DIR/validate_f5_soak_log.sh" --quiet
f5_validation_fresh "$ROOT" || fp_die "PLAYTEST_REVALIDATE: FAIL (validate_f5_soak_log)"

if [[ $SKIP_SMOKES -eq 0 ]]; then
	bash "$SCRIPT_DIR/validate_camp_optional_smokes.sh" --quiet
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	f5_ensure_validation_fresh "$ROOT" || true
fi

[[ $SKIP_CLOSEOUT -eq 1 ]] && { echo "PLAYTEST_REVALIDATE: PASS (skipped closeout)"; exit 0; }

CLOSEOUT=(--skip-revalidate)
[[ $HUMAN_SIGNOFF -eq 1 ]] && CLOSEOUT+=(--human-signoff)
bash "$SCRIPT_DIR/run_camp_f5_closeout.sh" "${CLOSEOUT[@]}"
if [[ $EXP0_GATE -eq 1 ]]; then
	bash "$SCRIPT_DIR/run_exp0_playtest_gate.sh" --skip-closeout \
		|| fp_die "PLAYTEST_REVALIDATE: FAIL (Exp-0.2 gate smokes)"
fi
echo "PLAYTEST_REVALIDATE: PASS"
