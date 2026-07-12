#!/usr/bin/env bash
# Summarize Phase 0 / campaign ship artifacts + post-Camp-5 F5 status (no Godot).
# Pass --quiet for EA sign-off summary only (used by run_camp_f5_closeout.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$ROOT/scripts/f5_soak_log_helpers.sh"
QUIET=0
for arg in "$@"; do
	case "$arg" in
		--quiet|-q) QUIET=1 ;;
	esac
done

echo "Docs: docs/AGENTS_ENTRY.md | docs/SHIP_PLAN.md#camp-playtest-acceptance (F5 §8) | scripts/README.md"
echo "Streams: Combat (Phase 0 + Camp-3.4 tail) | Playtest F5 §8 / Q1/Q2 | Expand after Camp-5"
if [[ $QUIET -eq 0 ]]; then
	echo ""
fi

PHASE0="$ROOT/.phase0_combat_checks.txt"
AUDIT="$ROOT/.campaign_ship_audit.txt"
HARNESS="$ROOT/.harness_out.txt"
PHASE0_OK=0
CAMPAIGN_OK=0
[[ -f "$PHASE0" ]] && grep -q '^PHASE0: PASS' "$PHASE0" && PHASE0_OK=1
if [[ -f "$AUDIT" ]] && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$AUDIT"; then
	CAMPAIGN_OK=1
elif [[ $PHASE0_OK -eq 1 ]] && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0"; then
	CAMPAIGN_OK=1
fi

if [[ $QUIET -eq 0 ]]; then
	if [[ -f "$PHASE0" ]]; then
		echo "=== phase0 (first 15 lines) ==="
		head -n 15 "$PHASE0"
		echo ""
	fi
	if [[ -f "$HARNESS" ]]; then
		LINE="$(grep "FP_HARNESS_OK: CompanyStateChecks" "$HARNESS" | tail -1 || true)"
		if [[ -n "$LINE" ]]; then
			echo "=== company_state_checks (last harness) ==="
			echo "$LINE"
			echo ""
		fi
	fi
	if [[ -f "$AUDIT" ]]; then
		echo "=== campaign_ship_audit ==="
		head -n 12 "$AUDIT"
		echo ""
	fi
	SOAK="$ROOT/.d001_soak_out.txt"
	if [[ -f "$SOAK" ]]; then
		echo "=== d001_soak (grep ok / ii5c / ii7) ==="
		grep -E '^ok=|^\[ii2b\]|^\[ii5c\]|^\[ii7\]|^\[ii_envelop\]|form_wrath_' "$SOAK" || true
		echo ""
	fi
fi

echo "=== Post-Camp-5 status (Camp-5 EA ☑ 2026-06-07) ==="
if [[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 1 ]]; then
	echo "Headless: GREEN (PHASE0 + CAMPAIGN_SHIP_AUDIT)"
else
	[[ $PHASE0_OK -eq 0 ]] && echo "Headless: PHASE0 not PASS — run ./scripts/run_all_combat_checks.sh"
	[[ $CAMPAIGN_OK -eq 0 ]] && echo "Headless: CAMPAIGN_SHIP_AUDIT not PASS — run ./scripts/run_campaign_ship_audit.sh"
fi

F5_LOG="$ROOT/.f5_soak_in.txt"
F5_VAL="$ROOT/.f5_soak_validation.txt"
if [[ -f "$F5_LOG" ]]; then
	echo ""
	echo "=== F5 paste (.f5_soak_in.txt) ==="
	if f5_is_headless_capture_only "$F5_LOG"; then
		echo "NOTE: headless D001 capture only — paste F5 Output or: ./scripts/restore_f5_soak_log.sh"
	elif f5_is_example_smoke "$F5_LOG"; then
		echo "NOTE: docs example smoke — not Camp-5 human sign-off (paste real F5 Output)"
	fi
	if [[ -f "$F5_VAL" ]]; then
		if grep -q '^ok=true' "$F5_VAL" \
			&& grep -q '^\[wf_m3_turn_ready_form\] PASS' "$F5_VAL" \
			&& grep -q '^\[wf_m3_grd_before_form\] PASS' "$F5_VAL"; then
			echo "WF-M3 validator: GREEN (wf_m3_turn_ready_form + wf_m3_grd_before_form PASS)"
		elif grep -q '^ok=true' "$F5_VAL"; then
			echo "F5 validator: ok=true (WF-M3 tracks missing or fail)"
		else
			echo "WARN: F5 validator not ok=true — run ./scripts/validate_f5_soak_log.sh"
		fi
		if grep -qE '^FP_WORLD: (settlement_continue|contract_victory pay=|company_day_advanced|field_care:|company_run_end reason=)' "$F5_LOG"; then
			echo "Camp section 8 markers in log:"
			show_camp_track() {
				local label="$1" id="$2"
				local st
				st="$(f5_validator_track_status "$F5_VAL" "$id")"
				case "$st" in
					pass) echo "  [OK] $label (validator)" ;;
					optional_miss) echo "  [opt] $label (OPTIONAL_MISS — not Camp-5 blocker)" ;;
					*) echo "  [--] $label (not in validation report)" ;;
				esac
			}
			show_camp_track "settlement_continue" "camp_settlement_continue"
			show_camp_track "company_day_advanced" "camp_company_day"
			show_camp_track "field_care hint" "camp_field_care"
			show_camp_track "field_care action (step 4)" "camp_field_care_action"
			show_camp_track "paid loss (step 8)" "camp_paid_loss"
			show_camp_track "tutorial soft loss (step 8)" "camp_tutorial_soft_loss"
			show_camp_track "wage warn (step 9)" "camp_wage_warn"
			show_camp_track "desertion (step 9)" "camp_desertion"
			show_camp_track "company_run_end (any)" "camp_run_end"
			show_camp_track "mopup_strike_finish (optional 3e)" "camp_mopup_strike_finish"
			show_camp_track "party triage (step 10)" "camp_party_triage"
			if ! grep -q 'soak_fight_end winner=' "$F5_LOG" 2>/dev/null; then
				echo "  [hint] log missing soak_fight_end — merge combat Output with world markers"
			fi
		else
			echo "Camp section 8: no campaign markers in log yet (combat-only paste ok for WF-M3)"
		fi
	else
		echo "WARN: no .f5_soak_validation.txt — run ./scripts/validate_f5_soak_log.sh"
	fi
else
	echo "F5 paste: .f5_soak_in.txt missing (optional until Camp section 8 playtest)"
fi

if [[ $QUIET -eq 0 ]]; then
	echo "Human F5: main.tscn dev_soak_encounter empty -> ./scripts/run_q_feel.sh Camp"
	echo ""
fi
echo "=== F5 / Camp status summary ==="
EA_HEADLESS=0
EA_WFM3=0
EA_CAMP=0
[[ $PHASE0_OK -eq 1 && $CAMPAIGN_OK -eq 1 ]] && EA_HEADLESS=1
if [[ -f "$F5_VAL" ]] && grep -q '^ok=true' "$F5_VAL" \
	&& grep -q '^\[wf_m3_turn_ready_form\] PASS' "$F5_VAL" \
	&& grep -q '^\[wf_m3_grd_before_form\] PASS' "$F5_VAL"; then
	EA_WFM3=1
fi
if [[ -f "$F5_VAL" ]] && grep -q '^\[camp_settlement_continue\] PASS' "$F5_VAL" \
	&& grep -q '^\[camp_company_day\] PASS' "$F5_VAL"; then
	EA_CAMP=1
fi
[[ $EA_HEADLESS -eq 1 ]] && echo "headless: READY" || echo "headless: NOT READY"
[[ $EA_WFM3 -eq 1 ]] && echo "wf_m3_f5_paste: READY (validator)" || echo "wf_m3_f5_paste: NOT READY"
[[ $EA_CAMP -eq 1 ]] && echo "camp_section_8: READY (settlement + day markers)" || echo "camp_section_8: NOT READY - need full Camp loop in log"
F5_HUMAN="NOT READY"
[[ -f "$F5_LOG" ]] && F5_HUMAN="$(f5_human_signoff_status "$F5_LOG")"
case "$F5_HUMAN" in
	READY) echo "human_f5_paste: READY (Camp-5 baseline — re-run --human-signoff after new F5 append)" ;;
	"SMOKE ONLY") echo "human_f5_paste: SMOKE ONLY (docs example - paste real F5 Output)" ;;
	"NOT READY (headless capture)") echo "human_f5_paste: NOT READY (headless capture - restore_f5_soak_log.sh)" ;;
	*) echo "human_f5_paste: NOT READY" ;;
esac
BAK="$(f5_soak_backup_path "$ROOT")"
if [[ -f "$BAK" && "$F5_HUMAN" != "READY" ]]; then
	echo "Hint: human backup at .f5_soak_in.f5_backup.txt — ./scripts/restore_f5_soak_log.sh"
fi
if [[ $EA_HEADLESS -eq 1 && $EA_WFM3 -eq 1 && $EA_CAMP -eq 1 && "$F5_HUMAN" == "READY" ]]; then
	echo "overall: GREEN (headless + human F5 baseline)"
elif [[ $EA_HEADLESS -eq 1 && $EA_WFM3 -eq 1 && $EA_CAMP -eq 1 && "$F5_HUMAN" == "SMOKE ONLY" ]]; then
	echo "overall: SMOKE ONLY (docs example — restore backup or paste real F5)"
else
	echo "overall: check rows above (Phase 0 gate is primary)"
fi
if [[ $QUIET -eq 0 ]]; then
	echo "Smoke: cp docs/f5_soak_log.camp_wf.example.txt .f5_soak_in.txt && ./scripts/validate_f5_soak_log.sh"
	echo "Full optional tracks smoke: cp docs/f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
	echo "Camp-5 ☑ 2026-06-07 — F5 on demand; prompts: scripts/agent_prompts/README.md"
fi
echo ""
