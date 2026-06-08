#!/usr/bin/env bash
# Exp-0.2 Playtest gate — optional Camp §8 smokes + human paste closeout (no full Phase 0 re-run).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
PHASE0="$ROOT/.phase0_combat_checks.txt"
PHASE0_STAMP="$ROOT/.phase0_playtest_gate_stamp.txt"
SKIP_CLOSEOUT=0
[[ "${1:-}" == "--skip-closeout" ]] && SKIP_CLOSEOUT=1

phase0_green() {
	[[ -f "$PHASE0" ]] \
		&& grep -q '^PHASE0: PASS' "$PHASE0" 2>/dev/null \
		&& grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null
}

if ! phase0_green; then
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (headless not green - run ./scripts/run_all_combat_checks.sh first)"
	exit 1
fi
cp "$PHASE0" "$PHASE0_STAMP"

echo "=== Exp-0.2 Playtest gate ==="
"$SCRIPT_DIR/validate_camp_optional_smokes.sh" || {
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"
	exit 1
}

if [[ $SKIP_CLOSEOUT -eq 1 ]]; then
	echo "EXP_0_2_PLAYTEST_GATE: PASS (smokes only; skipped closeout)"
	exit 0
fi

if [[ -f "$PHASE0_STAMP" ]] && ! phase0_green; then
	cp "$PHASE0_STAMP" "$PHASE0"
fi

"$SCRIPT_DIR/run_camp_f5_closeout.sh" --human-signoff --skip-revalidate || {
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"
	exit 1
}
echo "EXP_0_2_PLAYTEST_GATE: PASS"
exit 0
