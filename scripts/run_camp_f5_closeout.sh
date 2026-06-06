#!/usr/bin/env bash
# Camp-5 F5 close-out: validate .f5_soak_in.txt (if present) + EA sign-off summary.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
F5_LOG="$ROOT/.f5_soak_in.txt"
F5_VAL="$ROOT/.f5_soak_validation.txt"

show_optional_camp_tracks() {
	local val="$1"
	[[ -f "$val" ]] || return
	echo "Camp §8 extended (optional validator tracks):"
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
	local row step id
	for row in "${rows[@]}"; do
		step="${row%%|*}"
		id="${row##*|}"
		if grep -q "^\[$id\] PASS" "$val" 2>/dev/null; then
			echo "  [OK] step $step [$id]"
		else
			echo "  [--] step $step [$id] - merge separate F5 runs or docs/f5_soak_log.camp_full.example.txt smoke"
		fi
	done
	echo "  step 10 Party triage: open Party menu once (grep party_triage_open) or optional [camp_party_triage] PASS"
}

if [[ -f "$F5_LOG" ]]; then
	bash "$ROOT/scripts/validate_f5_soak_log.sh" || true
fi
bash "$ROOT/scripts/print_phase0_status.sh" | tail -n 30
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
	if [[ $mopup_opt -eq 0 ]]; then
		echo "NOTE: optional camp_mopup_strike_finish not PASS (rout-only wins OK for settlement)"
	fi
	show_optional_camp_tracks "$F5_VAL"
	exit 0
fi
echo "=== Camp-5 close-out blocked ==="
[[ $headless -eq 0 ]] && echo "  headless: run ./scripts/run_all_combat_checks.sh -> PHASE0 + CAMPAIGN_SHIP_AUDIT PASS"
[[ ! -f "$F5_LOG" ]] && echo "  f5_log: missing .f5_soak_in.txt (paste full F5 Output after Camp playtest)"
[[ -f "$F5_LOG" && $wfm3 -eq 0 ]] && echo "  wf_m3: run validate_f5_soak_log.sh; need wf_m3_turn_ready_form + wf_m3_grd_before_form PASS"
[[ -f "$F5_LOG" && $camp_settle -eq 0 ]] && echo "  camp: need settlement_continue or contract_victory pay= in log -> [camp_settlement_continue] PASS"
[[ -f "$F5_LOG" && $camp_settle -eq 1 && $camp_day -eq 0 ]] && echo "  camp: need company_day_advanced after settlement (end day or camp rest)"
[[ -f "$F5_LOG" && $soak_end -eq 0 ]] && echo "  hint: log missing soak_fight_end (merge combat Output with world markers)"
show_optional_camp_tracks "$F5_VAL"
exit 1
