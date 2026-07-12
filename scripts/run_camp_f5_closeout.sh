#!/usr/bin/env bash
# F5 Camp status (Camp-5 EA ☑ 2026-06-07): validate .f5_soak_in.txt (if present) + status summary.
# Pass --human-signoff to require a real F5 paste (not docs example smoke) for re-validation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$ROOT/scripts/f5_soak_log_helpers.sh"
F5_LOG="$(f5_soak_log_path "$ROOT")"
F5_VAL="$ROOT/.f5_soak_validation.txt"
HUMAN_SIGNOFF=0
SKIP_REVALIDATE=0
for arg in "$@"; do
	case "$arg" in
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--skip-revalidate) SKIP_REVALIDATE=1 ;;
	esac
done

camp_optional_hint() {
	case "$1" in
	camp_field_care_action) echo "map Party -> bandage/pressure (FP_WORLD field_care bandage part=)" ;;
	camp_paid_loss) echo "lose paid contract -> company_run_end reason=contract_failed reload=true" ;;
	camp_tutorial_soft_loss) echo "lose tutorial 2v2 -> reason=tutorial_failed reload=false" ;;
	camp_wage_warn) echo "End day with low gold -> company_wages: gold=" ;;
	camp_desertion) echo "keep End day while broke -> desertion summary=" ;;
	camp_mopup_strike_finish) echo "win via rout mop-up strikes (Escort/Border)" ;;
	camp_party_triage) echo "open Party on map -> party_triage_open living=" ;;
	camp_medical_exit) echo "Finish medical treatment on tutorial or messy fight" ;;
	*) echo "" ;;
	esac
}

show_optional_camp_tracks() {
	local val="$1"
	[[ -f "$val" ]] || return
	echo "Camp section 8 extended (optional validator tracks):"
	local rows=(
		"4 field care action|camp_field_care_action"
		"8 paid loss|camp_paid_loss"
		"8 tutorial soft|camp_tutorial_soft_loss"
		"9 wage warn|camp_wage_warn"
		"9 desertion|camp_desertion"
		"3e mop-up|camp_mopup_strike_finish"
		"10 party triage|camp_party_triage"
		"medical exit|camp_medical_exit"
	)
	local row step id hint
	for row in "${rows[@]}"; do
		step="${row%%|*}"
		id="${row##*|}"
		if grep -q "^\[$id\] PASS" "$val" 2>/dev/null; then
			echo "  [OK] step $step [$id]"
		elif grep -q "^\[$id\] OPTIONAL_MISS" "$val" 2>/dev/null; then
			echo "  [opt] step $step [$id] (OPTIONAL_MISS in validator)"
			hint="$(camp_optional_hint "$id")"
			[[ -n "$hint" ]] && echo "       -> $hint"
		else
			echo "  [--] step $step [$id]"
			hint="$(camp_optional_hint "$id")"
			[[ -n "$hint" ]] && echo "       -> $hint"
		fi
	done
}

if [[ -f "$F5_LOG" ]]; then
	if [[ $SKIP_REVALIDATE -eq 0 ]] && ! f5_validation_fresh "$ROOT"; then
		bash "$ROOT/scripts/validate_f5_soak_log.sh" --quiet || true
	fi
	f5_show_status_hint "$ROOT"
fi
bash "$ROOT/scripts/print_phase0_status.sh" --quiet
PHASE0="$ROOT/.phase0_combat_checks.txt"
headless=0; wfm3=0; camp_settle=0; camp_day=0; mopup_opt=0; soak_end=0
grep -q '^PHASE0: PASS' "$PHASE0" 2>/dev/null && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null && headless=1
grep -q '^ok=true' "$F5_VAL" 2>/dev/null && grep -q '^\[wf_m3_turn_ready_form\] PASS' "$F5_VAL" 2>/dev/null \
	&& grep -q '^\[wf_m3_grd_before_form\] PASS' "$F5_VAL" 2>/dev/null && wfm3=1
grep -q '^\[camp_settlement_continue\] PASS' "$F5_VAL" 2>/dev/null && camp_settle=1
grep -q '^\[camp_company_day\] PASS' "$F5_VAL" 2>/dev/null && camp_day=1
grep -q '^\[camp_mopup_strike_finish\] PASS' "$F5_VAL" 2>/dev/null && mopup_opt=1
grep -q 'soak_fight_end winner=' "$F5_LOG" 2>/dev/null && soak_end=1

if [[ $headless -eq 1 && $wfm3 -eq 1 && $camp_settle -eq 1 && $camp_day -eq 1 ]]; then
	human_status="$(f5_human_signoff_status "$F5_LOG")"
	[[ $mopup_opt -eq 0 ]] && echo "NOTE: optional camp_mopup_strike_finish not PASS (rout-only wins OK for settlement)"
	show_optional_camp_tracks "$F5_VAL"
	if f5_exp02_optional_tracks_pass "$F5_VAL"; then
		echo "Exp-0.2 optional tracks (steps 4, 8 paid, 9, 10): PASS"
	elif [[ -f "$F5_LOG" ]]; then
		echo "Exp-0.2 optional tracks: incomplete (see optional table above)"
	fi
	echo ""
	echo "=== Close-out summary ==="
	echo "automated_minimum: PASS (headless + wf_m3 + camp settlement/day)"
	case "$human_status" in
		READY) echo "human_signoff: READY (real F5 paste - tick SHIP_PLAN after glance)" ;;
		"SMOKE ONLY") echo "human_signoff: SMOKE ONLY (docs example - paste real F5 Output for Camp-5)" ;;
		"NOT READY (headless capture)") echo "human_signoff: NOT READY (headless capture - restore ./scripts/restore_f5_soak_log.sh)" ;;
		*) echo "human_signoff: NOT READY (need F5 editor Output merged into .f5_soak_in.txt)" ;;
	esac
	if [[ $HUMAN_SIGNOFF -eq 1 && "$human_status" != "READY" ]]; then
		echo ""
		echo "=== Camp-5 human sign-off blocked ==="
		[[ "$human_status" == "SMOKE ONLY" ]] && echo "  f5_log: docs example smoke - run F5 playtest and append followup.log"
		[[ "$human_status" == "NOT READY (headless capture)" ]] && echo "  f5_log: headless capture - restore ./scripts/restore_f5_soak_log.sh"
		[[ "$human_status" != "SMOKE ONLY" && "$human_status" != "NOT READY (headless capture)" ]] && echo "  f5_log: paste full Godot Output or append with ./scripts/append_f5_soak_log.sh"
		echo "  preflight: ./scripts/preflight_f5_followup.sh followup.log"
		exit 1
	fi
	exit 0
fi
echo "=== F5 Camp status: not ready ==="
[[ $headless -eq 0 ]] && echo "  headless: run ./scripts/run_all_combat_checks.sh -> PHASE0 + CAMPAIGN_SHIP_AUDIT PASS"
[[ ! -f "$F5_LOG" ]] && echo "  f5_log: missing .f5_soak_in.txt (paste full F5 Output after Camp playtest)"
[[ -f "$F5_LOG" && $wfm3 -eq 0 ]] && echo "  wf_m3: run validate_f5_soak_log.sh; need wf_m3_turn_ready_form + wf_m3_grd_before_form PASS"
if [[ -f "$F5_LOG" && $camp_settle -eq 0 ]]; then
	if f5_is_headless_capture_only "$F5_LOG"; then
		echo "  f5_log: headless capture only - restore ./scripts/restore_f5_soak_log.sh"
	else
		echo "  camp: need settlement_continue -> [camp_settlement_continue] PASS"
	fi
fi
[[ -f "$F5_LOG" && $camp_settle -eq 1 && $camp_day -eq 0 ]] && echo "  camp: need company_day_advanced after settlement"
[[ -f "$F5_LOG" && $soak_end -eq 0 ]] && echo "  hint: log missing soak_fight_end (merge combat Output with world markers)"
show_optional_camp_tracks "$F5_VAL"
exit 1
