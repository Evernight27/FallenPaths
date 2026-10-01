#!/usr/bin/env bash
# Headless camp optional-step smoke batch (Playtest).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SMOKE_DIR="$ROOT/docs/camp_optional_step_smokes"
REPORT="$ROOT/.f5_soak_validation.txt"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

FILES=(
    step3e_mopup.txt:camp_mopup_strike_finish
    step4_field_care_action.txt:camp_field_care_action
    step8_paid_loss.txt:camp_paid_loss
    step8_tutorial_soft.txt:camp_tutorial_soft_loss
    step9_wage_warn.txt:camp_wage_warn
    step9_desertion.txt:camp_desertion
    step10_party_triage.txt:camp_party_triage
    medical_exit.txt:camp_medical_exit
)

[[ -d "$SMOKE_DIR" ]] || fp_die "Smoke dir missing: $SMOKE_DIR" 2
BATCH="$(f5_camp_smokes_batch_path "$ROOT")"
echo "=== Camp optional step smokes ==="
f5_invoke_camp_smokes_batch "$ROOT" || fp_die "CAMP_OPTIONAL_SMOKES: FAIL (batch)" 2

passed=0
failures=()
for entry in "${FILES[@]}"; do
    file="${entry%%:*}"; track="${entry#*:}"
    path="$SMOKE_DIR/$file"
    if [[ ! -f "$path" ]]; then
        failures+=("$file: missing"); continue
    fi
    line="$(grep -E "^\[$file\] " "$BATCH" 2>/dev/null | tail -n1 || true)"
    [[ $QUIET -eq 0 ]] && echo "--- $file -> [$track] ---" && [[ -n "$line" ]] && echo "  $line"
    if [[ -n "$line" && "$line" == *" PASS" ]]; then
        passed=$((passed + 1))
        [[ $QUIET -eq 0 ]] && echo "  [OK] $file"
    else
        failures+=("$file: ${line:-missing batch row}")
        [[ $QUIET -eq 0 ]] && echo "  [FAIL] $file"
    fi
done

if [[ -f "$(f5_soak_log_path "$ROOT")" && -f "$REPORT" ]]; then
    if grep -q '^ok=true' "$REPORT" 2>/dev/null; then
        if f5_exp02_optional_tracks_pass "$REPORT"; then
            echo "EXP_0_2_OPTIONAL: PASS"
        else
            echo "EXP_0_2_OPTIONAL: FAIL"
            failures+=("human paste: Exp-0.2 tracks incomplete")
        fi
    fi
fi

echo "passed: $passed / ${#FILES[@]}"
if ((${#failures[@]} > 0)); then
    printf '  FAIL: %s\n' "${failures[@]}"
    exit 1
fi
echo "CAMP_OPTIONAL_SMOKES: PASS"
