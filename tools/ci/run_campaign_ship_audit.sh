#!/usr/bin/env bash
# Camp ship audit: company checks (unless --tail-only) + Q tracks + ii7/ii_envelop from D001.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127
TAIL_ONLY=0
FAIL=0
AUDIT="$ROOT/.campaign_ship_audit.txt"
[[ "${1:-}" == "--tail-only" ]] && TAIL_ONLY=1
: >"$AUDIT"

echo "=== Campaign ship audit ==="
if [[ $TAIL_ONLY -eq 0 ]]; then
    set +e; bash "$SCRIPT_DIR/run_company_state_checks.sh"; code=$?; set -e
    if [[ $code -eq 0 ]]; then
        echo "COMPANY_STATE: PASS" >>"$AUDIT"
    else
        echo "COMPANY_STATE: FAIL" >>"$AUDIT"
        FAIL=1
    fi
else
    echo "COMPANY_STATE: SKIP (Phase 0 already ran)" >>"$AUDIT"
fi

set +e; fp_godot_run "$(fp_timeout_seconds)" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_q_track_audits.gd; code=$?; set -e
if [[ $code -eq 0 ]]; then
    echo "Q_TRACK: PASS" >>"$AUDIT"
else
    echo "Q_TRACK: FAIL" >>"$AUDIT"
    FAIL=1
fi

SOAK="$ROOT/.d001_soak_out.txt"
check_soak() {
    local tag="$1" pat="$2"
    if [[ -f "$SOAK" ]] && grep -qE "$pat" "$SOAK"; then
        echo "PASS: $tag"; echo "$tag: PASS" >>"$AUDIT"
    else
        echo "FAIL: $tag missing in .d001_soak_out.txt"; echo "$tag: FAIL" >>"$AUDIT"; FAIL=1
    fi
}
check_soak II7_MEDICAL '\[ii7\] pass=true'
check_soak II_ENVELOP '\[ii_envelop\] pass=true'
if [[ -f "$SOAK" ]] && grep -q '\[ii_envelop\] pass=true' "$SOAK"; then
    if grep -q 'ii_envelop_mopup: PASS' "$SOAK"; then
        echo "PASS: ii_envelop_mopup"; echo "II_ENVELOP_MOPUP: PASS" >>"$AUDIT"
    else
        echo "FAIL: ii_envelop_mopup"; echo "II_ENVELOP_MOPUP: FAIL" >>"$AUDIT"; FAIL=1
    fi
fi

if [[ $TAIL_ONLY -eq 0 ]]; then
    PHASE0="$ROOT/.phase0_combat_checks.txt"
    if [[ -f "$PHASE0" ]] && grep -q '^PHASE0: PASS' "$PHASE0"; then
        echo "PHASE0: PASS" >>"$AUDIT"
    else
        echo "PHASE0: FAIL" >>"$AUDIT"; FAIL=1
    fi
else
    echo "PHASE0: SKIP (caller verified)" >>"$AUDIT"
fi

echo "ran_at=$(date '+%Y-%m-%d %H:%M:%S')" >>"$AUDIT"
if [[ $FAIL -ne 0 ]]; then
    echo "CAMPAIGN_SHIP_AUDIT: FAIL" >>"$AUDIT"
    echo "=== CAMPAIGN_SHIP_AUDIT: FAIL ==="
    exit 1
fi
echo "CAMPAIGN_SHIP_AUDIT: PASS (headless)" >>"$AUDIT"
echo "=== CAMPAIGN_SHIP_AUDIT: PASS (headless) ==="
