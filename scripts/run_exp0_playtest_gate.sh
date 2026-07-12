#!/usr/bin/env bash
# Exp-0.2 gate: optional smokes + human closeout (Phase 0 must already be green).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHASE0="$ROOT/.phase0_combat_checks.txt"
SKIP_CLOSEOUT=0
[[ "${1:-}" == "--skip-closeout" ]] && SKIP_CLOSEOUT=1

phase0_green() {
	[[ -f "$PHASE0" ]] && grep -q '^PHASE0: PASS' "$PHASE0" && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0"
}
phase0_green || fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (run ./scripts/run_all_combat_checks.sh first)"

echo "=== Exp-0.2 Playtest gate ==="
bash "$SCRIPT_DIR/validate_camp_optional_smokes.sh" || fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"
[[ $SKIP_CLOSEOUT -eq 1 ]] && { echo "EXP_0_2_PLAYTEST_GATE: PASS (smokes only)"; exit 0; }
bash "$SCRIPT_DIR/run_camp_f5_closeout.sh" --human-signoff --skip-revalidate \
	|| fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"
echo "EXP_0_2_PLAYTEST_GATE: PASS"
