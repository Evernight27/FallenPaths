#!/usr/bin/env bash
# Headless validator regression for docs/camp_optional_step_smokes/*.txt (Playtest stream).
# One Godot session validates all smokes + human paste (.f5_soak_validation.txt).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SMOKE_DIR="$ROOT/docs/camp_optional_step_smokes"
REPORT="$ROOT/.f5_soak_validation.txt"
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

# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
BATCH="$(f5_camp_smokes_batch_path "$ROOT")"

if [[ ! -d "$SMOKE_DIR" ]]; then
	echo "Smoke dir missing: $SMOKE_DIR" >&2
	exit 2
fi

echo "=== Camp optional step smokes (CombatF5SoakLogValidator) ==="
if ! f5_invoke_camp_smokes_batch "$ROOT"; then
	echo "CAMP_OPTIONAL_SMOKES: FAIL (batch report timeout)"
	exit 2
fi

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
	if [[ $QUIET -eq 0 ]]; then
		echo ""
		echo "--- $file -> [$track] ---"
	fi
	line="$(grep -E "^\[$file\] " "$BATCH" 2>/dev/null | tail -n 1 || true)"
	if [[ $QUIET -eq 0 && -n "$line" ]]; then
		echo "  $line"
	fi
	if [[ -n "$line" && "$line" == *" PASS" ]]; then
		passed=$((passed + 1))
		[[ $QUIET -eq 0 ]] && echo "  [OK] $file [$track]"
	else
		detail="${line:-missing batch row}"
		failures+=("$file: $detail")
		[[ $QUIET -eq 0 ]] && echo "  [FAIL] $file ($detail)"
	fi
done

if [[ -f "$ROOT/.f5_soak_in.txt" ]]; then
	if [[ $QUIET -eq 0 ]]; then
		echo ""
		echo "--- human paste validation (.f5_soak_in.txt) ---"
	fi
	if [[ ! -f "$REPORT" ]]; then
		echo "WARN: human paste validation report missing after batch"
	elif ! grep -q '^ok=true' "$REPORT" 2>/dev/null; then
		echo "WARN: human paste re-validation ok=false - run ./scripts/validate_f5_soak_log.sh"
	elif [[ "$(f5_validator_track_status "$REPORT" camp_settlement_continue)" != "pass" ]]; then
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
