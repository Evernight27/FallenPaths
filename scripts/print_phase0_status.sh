#!/usr/bin/env bash
# Summarize Phase 0 / F5 artifacts (no Godot). --quiet = EA sign-off lines only.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
QUIET=0
[[ "${1:-}" == "--quiet" || "${1:-}" == "-q" ]] && QUIET=1

PHASE0="$ROOT/.phase0_combat_checks.txt"
AUDIT="$ROOT/.campaign_ship_audit.txt"
F5_LOG="$(f5_soak_log_path "$ROOT")"
F5_VAL="$ROOT/.f5_soak_validation.txt"
PHASE0_OK=0
CAMPAIGN_OK=0
[[ -f "$PHASE0" ]] && grep -q '^PHASE0: PASS' "$PHASE0" && PHASE0_OK=1
[[ -f "$AUDIT" ]] && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$AUDIT" && CAMPAIGN_OK=1
[[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 0 ]] && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null && CAMPAIGN_OK=1

[[ $QUIET -eq 0 ]] && echo "Docs: docs/AGENTS_ENTRY.md | scripts/README.md"
if [[ $QUIET -eq 0 ]]; then
	[[ -f "$PHASE0" ]] && { echo "=== phase0 ==="; head -n 15 "$PHASE0"; echo ""; }
	[[ -f "$AUDIT" ]] && { echo "=== campaign_ship_audit ==="; head -n 12 "$AUDIT"; echo ""; }
	[[ -f "$ROOT/.d001_soak_out.txt" ]] && {
		echo "=== d001_soak ==="
		grep -E '^ok=|^\[ii2b\]|^\[ii5c\]|^\[ii7\]|^\[ii_envelop\]' "$ROOT/.d001_soak_out.txt" || true
		echo ""
	}
fi

echo "=== Post-Camp-5 status ==="
if [[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 1 ]]; then
	echo "Headless: GREEN"
else
	[[ $PHASE0_OK -eq 0 ]] && echo "Headless: PHASE0 not PASS"
	[[ $CAMPAIGN_OK -eq 0 ]] && echo "Headless: CAMPAIGN_SHIP_AUDIT not PASS"
fi

track_ok() { [[ -f "$F5_VAL" ]] && grep -q "^\[$1\] PASS" "$F5_VAL"; }
echo "=== F5 / Camp summary ==="
[[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 1 ]] && echo "headless: READY" || echo "headless: NOT READY"
if [[ -f "$F5_VAL" ]] && grep -q '^ok=true' "$F5_VAL" && track_ok wf_m3_turn_ready_form && track_ok wf_m3_grd_before_form; then
	echo "wf_m3_f5_paste: READY (validator)"
else
	echo "wf_m3_f5_paste: NOT READY"
fi
if track_ok camp_settlement_continue && track_ok camp_company_day; then
	echo "camp_section_8: READY"
else
	echo "camp_section_8: NOT READY"
fi
HUMAN="NOT READY"
[[ -f "$F5_LOG" ]] && HUMAN="$(f5_human_signoff_status "$F5_LOG")"
echo "human_f5_paste: $HUMAN"
f5_show_status_hint "$ROOT" || true
if [[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 1 ]] && track_ok wf_m3_turn_ready_form && track_ok camp_settlement_continue && [[ "$HUMAN" == "READY" ]]; then
	echo "overall: GREEN"
else
	echo "overall: check rows above"
fi
