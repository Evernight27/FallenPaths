#!/usr/bin/env bash
# Validate .f5_soak_in.txt (or path). Usage: ./tools/ci/validate_f5_soak_log.sh [--quiet] [log]
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127
QUIET=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --quiet|-q) QUIET=1; shift ;;
        *) break ;;
    esac
done
LOG_PATH="${1:-}"
DEFAULT="$(f5_soak_log_path "$ROOT")"
REPORT="$ROOT/.f5_soak_validation.txt"

if [[ -n "$LOG_PATH" ]]; then
    LOG_PATH="$(fp_abs "$LOG_PATH")"
    [[ -f "$LOG_PATH" ]] || fp_die "Log not found: $LOG_PATH" 2
elif [[ ! -f "$DEFAULT" ]]; then
    echo "No log at $DEFAULT — paste F5 Output or: cp docs/f5_soak_log.camp_wf.example.txt .f5_soak_in.txt"
    exit 2
fi

TARGET="${LOG_PATH:-$DEFAULT}"
[[ $QUIET -eq 0 ]] && echo "=== CombatF5SoakLogValidator ===" && echo "Validating: $TARGET"
STAMP="$(f5_validation_report_stamp "$REPORT")"
export FP_HARNESS_MODE=f5_validate FP_F5_VALIDATE_LOG="$TARGET"
set +e
if [[ $QUIET -eq 1 ]]; then
    fp_godot_run "$(fp_timeout_seconds)" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_all_combat_checks.gd -- "$TARGET" >/dev/null 2>&1
else
    fp_godot_run "$(fp_timeout_seconds)" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_all_combat_checks.gd -- "$TARGET"
fi
CODE=$?
set -e
unset FP_HARNESS_MODE FP_F5_VALIDATE_LOG
f5_wait_validation_report "$REPORT" "$STAMP" || CODE=1
if [[ $QUIET -eq 0 && -f "$REPORT" ]]; then
    echo ""; echo "--- Report: $REPORT ---"; cat "$REPORT"; echo ""
    echo "--- Camp / WF-M3 tracks ---"
    grep -E '^\[(camp_|wf_m3_)' "$REPORT" 2>/dev/null || echo "(none)"
    f5_show_status_hint "$ROOT" || true
fi
exit "$CODE"
