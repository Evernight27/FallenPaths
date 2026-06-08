#!/usr/bin/env bash
# Exp-0.2 Playtest gate — optional Camp §8 smokes + human paste closeout (no full Phase 0 re-run).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
PHASE0="$ROOT/.phase0_combat_checks.txt"
SKIP_CLOSEOUT=0
[[ "${1:-}" == "--skip-closeout" ]] && SKIP_CLOSEOUT=1

if [[ ! -f "$PHASE0" ]] || ! grep -q '^PHASE0: PASS' "$PHASE0" 2>/dev/null \
	|| ! grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null; then
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (headless not green - run ./scripts/run_all_combat_checks.sh first)"
	exit 1
fi

echo "=== Exp-0.2 Playtest gate ==="
"$SCRIPT_DIR/validate_camp_optional_smokes.sh" || {
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"
	exit 1
}

if [[ $SKIP_CLOSEOUT -eq 1 ]]; then
	echo "EXP_0_2_PLAYTEST_GATE: PASS (smokes only; skipped closeout)"
	exit 0
fi

if [[ ! -f "$PHASE0" ]] || ! grep -q '^PHASE0: PASS' "$PHASE0" 2>/dev/null \
	|| ! grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null; then
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (headless no longer green before closeout - run ./scripts/run_all_combat_checks.sh)"
	exit 1
fi

"$SCRIPT_DIR/run_camp_f5_closeout.sh" --human-signoff || {
	echo "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"
	exit 1
}
echo "EXP_0_2_PLAYTEST_GATE: PASS"
exit 0
