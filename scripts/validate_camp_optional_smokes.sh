#!/usr/bin/env bash
# Headless validator regression for docs/camp_optional_step_smokes/*.txt (Playtest stream).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SMOKE_DIR="$ROOT/docs/camp_optional_step_smokes"
REPORT="$ROOT/.f5_soak_validation.txt"
VALIDATE="$SCRIPT_DIR/validate_f5_soak_log.sh"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

declare -a FILES=(
	step3e_mopup.txt:camp_mopup_strike_finish
	step4_field_care_action.txt:camp_field_care_action
	step8_paid_loss.txt:camp_paid_loss
	step8_tutorial_soft.txt:camp_tutorial_soft_loss
	step9_wage_warn.txt:camp_wage_warn
	step9_desertion.txt:camp_desertion
	step10_party_triage.txt:camp_party_triage
	medical_exit.txt:camp_medical_exit
)

track_status() {
	local track="$1"
	if [[ ! -f "$REPORT" ]]; then
		echo "missing"
		return
	fi
	if ! grep -q '^--- END FP_F5_SOAK_VALIDATION ---' "$REPORT" 2>/dev/null; then
		echo "missing"
		return
	fi
	local line
	line="$(grep -E "^\[${track}\] " "$REPORT" | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		echo "missing"
	elif [[ "$line" == *"] PASS"* ]]; then
		echo "pass"
	elif [[ "$line" == *"] OPTIONAL_MISS"* ]]; then
		echo "optional_miss"
	elif [[ "$line" == *"] FAIL"* ]]; then
		echo "fail"
	else
		echo "missing"
	fi
}

# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"

echo "=== Camp optional step smokes (CombatF5SoakLogValidator) ==="
passed=0
failures=()

for entry in "${FILES[@]}"; do
	file="${entry%%:*}"
	track="${entry#*:}"
	path="$SMOKE_DIR/$file"
	if [[ ! -f "$path" ]]; then
		failures+=("$file: missing file")
		[[ $QUIET -eq 0 ]] && echo "  [FAIL] $file - file not found"
		continue
	fi
	stamp="$(f5_validation_report_stamp "$REPORT")"
	if [[ $QUIET -eq 1 ]]; then
		"$VALIDATE" --quiet "$path" || true
	else
		echo ""
		echo "--- $file -> [$track] ---"
		"$VALIDATE" --quiet "$path" || true
	fi
	if ! f5_wait_validation_report "$REPORT" "$stamp"; then
		failures+=("$file: validation report timeout")
		[[ $QUIET -eq 0 ]] && echo "  [FAIL] $file (validation report timeout)"
		continue
	fi
	if [[ $QUIET -eq 0 ]]; then
		line="$(grep -E "^\[$track\] " "$REPORT" 2>/dev/null | tail -n 1 || true)"
		[[ -n "$line" ]] && echo "  $line"
	fi
	ok_line=0
	grep -q "^ok=true" "$REPORT" 2>/dev/null && ok_line=1
	status="$(track_status "$track")"
	if [[ $ok_line -eq 1 && "$status" == "pass" ]]; then
		passed=$((passed + 1))
		[[ $QUIET -eq 0 ]] && echo "  [OK] $file [$track]"
	else
		failures+=("$file: ok=$ok_line track=$status")
		[[ $QUIET -eq 0 ]] && echo "  [FAIL] $file (ok=$ok_line track=$status)"
	fi
done

if [[ -f "$ROOT/.f5_soak_in.txt" ]]; then
	human_stamp="$(f5_validation_report_stamp "$REPORT")"
	if [[ $QUIET -eq 1 ]]; then
		"$VALIDATE" --quiet "$ROOT/.f5_soak_in.txt" || true
	else
		echo ""
		echo "--- restore human paste validation (.f5_soak_in.txt) ---"
		"$VALIDATE" --quiet "$ROOT/.f5_soak_in.txt" || true
	fi
	if ! f5_wait_validation_report "$REPORT" "$human_stamp"; then
		echo "WARN: human paste re-validation report timeout"
	elif ! grep -q '^ok=true' "$REPORT" 2>/dev/null; then
		echo "WARN: human paste re-validation ok=false - run ./scripts/validate_f5_soak_log.sh"
	elif [[ "$(track_status camp_settlement_continue)" != "pass" ]]; then
		echo "WARN: human paste camp_settlement_continue not PASS after smoke batch"
	else
		[[ $QUIET -eq 0 ]] && f5_show_validation_track_summary "$REPORT" 1 | tail -n 8
	fi
	if grep -q '^ok=true' "$REPORT" 2>/dev/null; then
		if f5_exp02_optional_tracks_pass "$REPORT"; then
		echo "EXP_0_2_OPTIONAL: PASS (steps 4, 8 paid loss, 9 wage/desertion, 10 triage)"
		else
			echo "EXP_0_2_OPTIONAL: FAIL (human paste missing one or more Exp-0.2 optional tracks)"
			failures+=("human paste: Exp-0.2 optional tracks incomplete")
		fi
	fi
fi

echo ""
echo "=== Camp optional smokes summary ==="
echo "passed: $passed / ${#FILES[@]}"
if ((${#failures[@]} > 0)); then
	for f in "${failures[@]}"; do
		echo "  FAIL: $f"
	done
	exit 1
fi
echo "CAMP_OPTIONAL_SMOKES: PASS"
exit 0
