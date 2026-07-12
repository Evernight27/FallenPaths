#!/usr/bin/env bash
# Camp ship audit (bash): headless proxies for SHIP_PLAN section 8 + Camp-3.4 / Camp-5 gates.
#   ./scripts/run_campaign_ship_audit.sh
#   ./scripts/run_campaign_ship_audit.sh --tail-only
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_godot.sh
source "$SCRIPT_DIR/_godot.sh"
ROOT="$(fp_project_root)"
GODOT_BIN="$(fp_godot_bin)" || {
	echo "run_campaign_ship_audit.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
}
TAIL_ONLY=0
FAIL=0
AUDIT_PATH="$ROOT/.campaign_ship_audit.txt"

for arg in "$@"; do
	case "$arg" in
		--tail-only) TAIL_ONLY=1 ;;
	esac
done

: >"$AUDIT_PATH"

echo "=== Campaign ship audit (headless) ==="
echo ""

if [[ $TAIL_ONLY -eq 0 ]]; then
	echo "=== CompanyStateChecks (SHIP_PLAN section 8 steps 1-10 proxies) ==="
	set +e
	bash "$ROOT/scripts/run_company_state_checks.sh"
	COMPANY_EXIT=$?
	set -e
	if [[ $COMPANY_EXIT -ne 0 ]]; then
		echo "COMPANY_STATE: FAIL" >>"$AUDIT_PATH"
		FAIL=1
	else
		echo "COMPANY_STATE: PASS" >>"$AUDIT_PATH"
	fi
	echo ""
else
	echo "COMPANY_STATE: SKIP (Phase 0 already ran)" >>"$AUDIT_PATH"
fi

echo "=== Q track audits (Camp-3.4 ii7 + Q1/Q2 proxies) ==="
set +e
"$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_q_track_audits.gd
Q_EXIT=$?
set -e
if [[ $Q_EXIT -ne 0 ]]; then
	echo "Q_TRACK: FAIL" >>"$AUDIT_PATH"
	FAIL=1
else
	echo "Q_TRACK: PASS" >>"$AUDIT_PATH"
fi
echo ""

SOAK="$ROOT/.d001_soak_out.txt"
II7=0
II_ENVELOP=0
II_ENVELOP_MOPUP=0
if [[ -f "$SOAK" ]]; then
	if grep -q '\[ii7\] pass=true' "$SOAK"; then
		II7=1
	fi
	if grep -q '\[ii_envelop\] pass=true' "$SOAK"; then
		II_ENVELOP=1
	fi
	if grep -q 'ii_envelop_mopup: PASS' "$SOAK"; then
		II_ENVELOP_MOPUP=1
	fi
fi
if [[ $II7 -eq 1 ]]; then
	echo "PASS: [ii7] medical smoke (headless)"
	echo "II7_MEDICAL: PASS" >>"$AUDIT_PATH"
else
	echo "FAIL: [ii7] pass=true missing in .d001_soak_out.txt - run ./scripts/run_all_combat_checks.sh"
	echo "II7_MEDICAL: FAIL" >>"$AUDIT_PATH"
	FAIL=1
fi
if [[ $II_ENVELOP -eq 1 ]]; then
	echo "PASS: [ii_envelop] 7v3 wing engagement smoke (headless)"
	echo "II_ENVELOP: PASS" >>"$AUDIT_PATH"
else
	echo "FAIL: [ii_envelop] pass=true missing in .d001_soak_out.txt - run ./scripts/run_all_combat_checks.sh"
	echo "II_ENVELOP: FAIL" >>"$AUDIT_PATH"
	FAIL=1
fi
if [[ $II_ENVELOP -eq 1 && $II_ENVELOP_MOPUP -eq 0 ]]; then
	echo "FAIL: ii_envelop_mopup: PASS missing under [ii_envelop] in .d001_soak_out.txt - run ./scripts/run_all_combat_checks.sh"
	echo "II_ENVELOP_MOPUP: FAIL" >>"$AUDIT_PATH"
	FAIL=1
elif [[ $II_ENVELOP_MOPUP -eq 1 ]]; then
	echo "PASS: ii_envelop_mopup check under [ii_envelop] (3e attrition smoke)"
	echo "II_ENVELOP_MOPUP: PASS" >>"$AUDIT_PATH"
fi

if [[ $TAIL_ONLY -eq 0 ]]; then
	PHASE0="$ROOT/.phase0_combat_checks.txt"
	if [[ ! -f "$PHASE0" ]]; then
		echo "WARN: .phase0_combat_checks.txt missing - run ./scripts/run_all_combat_checks.sh for full PHASE0"
	elif ! grep -q '^PHASE0: PASS' "$PHASE0"; then
		echo "WARN: PHASE0 not PASS in .phase0_combat_checks.txt"
		echo "PHASE0: FAIL" >>"$AUDIT_PATH"
		FAIL=1
	else
		echo "PASS: PHASE0 summary on disk"
		echo "PHASE0: PASS" >>"$AUDIT_PATH"
	fi
else
	echo "PHASE0: SKIP (caller verified)" >>"$AUDIT_PATH"
fi

echo ""
echo "=== Human F5 (on demand; Camp-5 EA ☑ 2026-06-07) ==="
echo "  Status: ./scripts/print_phase0_status.sh (headless green vs human F5 reminder)"
echo "  F5 main.tscn: dev_soak_encounter empty - tutorial + paid contracts; Party pressure -> bandage -> Camp rest (+1 day)"
echo "  F5 status: ./scripts/run_camp_f5_closeout.sh (headless + wf_m3 + camp settlement/day minimum)"
echo "  Optional III-4 F5: dev_soak_encounter=ii_envelop -> validate_f5_soak_log.sh (wing + mop-up tail: mop_up=true rotate_suppress=true)"
echo "  Optional feel: ./scripts/run_q_feel.ps1 -Track Camp | Q1 | Q2"
echo "  Medical phase Stack labels: spot-check once in F5 after a fight with medical phase"
echo ""

echo "ran_at=$(date '+%Y-%m-%d %H:%M:%s')" >>"$AUDIT_PATH"
if [[ $FAIL -ne 0 ]] || [[ $II7 -eq 0 ]] || [[ $II_ENVELOP -eq 0 ]]; then
	echo "CAMPAIGN_SHIP_AUDIT: FAIL" >>"$AUDIT_PATH"
	echo "=== CAMPAIGN_SHIP_AUDIT: FAIL ==="
	exit 1
fi
echo "CAMPAIGN_SHIP_AUDIT: PASS (headless)" >>"$AUDIT_PATH"
echo "=== CAMPAIGN_SHIP_AUDIT: PASS (headless) ==="
exit 0
