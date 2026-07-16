#!/usr/bin/env bash
# F5 Camp closeout: validate (unless --skip-revalidate) + status; --human-signoff requires real paste.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

OPTIONAL_HINTS=(
	"camp_field_care_action|map Party -> bandage/pressure"
	"camp_paid_loss|lose paid contract -> company_run_end contract_failed"
	"camp_tutorial_soft_loss|lose tutorial -> tutorial_failed reload=false"
	"camp_wage_warn|End day low gold -> company_wages"
	"camp_desertion|End day broke -> desertion summary"
	"camp_mopup_strike_finish|win via rout mop-up strikes"
	"camp_party_triage|Party on map -> party_triage_open"
	"camp_medical_exit|Finish medical treatment"
)

show_optional() {
	local val="$1" row id hint
	[[ -f "$val" ]] || return 0
	echo "Camp §8 optional tracks:"
	for row in "${OPTIONAL_HINTS[@]}"; do
		id="${row%%|*}"; hint="${row#*|}"
		if grep -q "^\[$id\] PASS" "$val" 2>/dev/null; then
			echo "  [OK] $id"
		elif grep -q "^\[$id\] OPTIONAL_MISS" "$val" 2>/dev/null; then
			echo "  [opt] $id — $hint"
		else
			echo "  [--] $id — $hint"
		fi
	done
}

if [[ -f "$F5_LOG" && $SKIP_REVALIDATE -eq 0 ]]; then
	if ! f5_validation_fresh "$ROOT"; then
		bash "$SCRIPT_DIR/validate_f5_soak_log.sh" --quiet || true
	fi
fi
[[ -f "$F5_LOG" ]] && f5_show_status_hint "$ROOT"
bash "$SCRIPT_DIR/print_phase0_status.sh" --quiet

PHASE0="$ROOT/.phase0_combat_checks.txt"
headless=0; wfm3=0; camp_settle=0; camp_day=0
grep -q '^PHASE0: PASS' "$PHASE0" 2>/dev/null && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$PHASE0" 2>/dev/null && headless=1
grep -q '^ok=true' "$F5_VAL" 2>/dev/null && grep -q '^\[wf_m3_turn_ready_form\] PASS' "$F5_VAL" 2>/dev/null \
	&& grep -q '^\[wf_m3_grd_before_form\] PASS' "$F5_VAL" 2>/dev/null && wfm3=1
grep -q '^\[camp_settlement_continue\] PASS' "$F5_VAL" 2>/dev/null && camp_settle=1
grep -q '^\[camp_company_day\] PASS' "$F5_VAL" 2>/dev/null && camp_day=1

if [[ $headless -eq 1 && $wfm3 -eq 1 && $camp_settle -eq 1 && $camp_day -eq 1 ]]; then
	human="$(f5_human_signoff_status "$F5_LOG")"
	show_optional "$F5_VAL"
	f5_exp02_optional_tracks_pass "$F5_VAL" && echo "Exp-0.2 optional tracks: PASS" \
		|| echo "Exp-0.2 optional tracks: incomplete"
	echo ""; echo "=== Close-out ==="
	echo "automated_minimum: PASS"
	echo "human_signoff: $human"
	[[ $HUMAN_SIGNOFF -eq 1 && "$human" != "READY" ]] && fp_die "=== Camp-5 human sign-off blocked ==="
	exit 0
fi

echo "=== F5 Camp status: not ready ==="
[[ $headless -eq 0 ]] && echo "  headless: ./tools/ci/run_all_combat_checks.sh"
[[ ! -f "$F5_LOG" ]] && echo "  f5_log: missing .f5_soak_in.txt"
[[ -f "$F5_LOG" && $wfm3 -eq 0 ]] && echo "  wf_m3: need validator PASS tracks"
[[ -f "$F5_LOG" && $camp_settle -eq 0 ]] && echo "  camp: need settlement_continue"
[[ -f "$F5_LOG" && $camp_settle -eq 1 && $camp_day -eq 0 ]] && echo "  camp: need company_day_advanced"
show_optional "$F5_VAL"
exit 1
