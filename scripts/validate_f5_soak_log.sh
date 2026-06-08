#!/usr/bin/env bash
# Validate .f5_soak_in.txt (headless capture or pasted F5 Output).
# Usage: ./scripts/validate_f5_soak_log.sh [--quiet] [path/to/log]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_godot.sh
source "$SCRIPT_DIR/_godot.sh"
# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
ROOT="$(fp_project_root)"
GODOT_BIN="$(fp_godot_bin)" || {
	echo "validate_f5_soak_log.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
}
QUIET=0
while [[ $# -gt 0 ]]; do
	case "$1" in
		--quiet|-q) QUIET=1; shift ;;
		*) break ;;
	esac
done
LOG_PATH="${1:-}"
INPUT_DEFAULT="$ROOT/.f5_soak_in.txt"
REPORT_PATH="$ROOT/.f5_soak_validation.txt"
if [[ -n "$LOG_PATH" ]]; then
	if [[ "$LOG_PATH" != /* ]]; then
		LOG_PATH="$ROOT/$LOG_PATH"
	fi
	if [[ ! -f "$LOG_PATH" ]]; then
		echo "Log file not found: $LOG_PATH" >&2
		exit 2
	fi
elif [[ ! -f "$INPUT_DEFAULT" ]]; then
	echo "No log at $INPUT_DEFAULT"
	echo "Run ./scripts/run_all_combat_checks.sh first, or paste F5 Output into .f5_soak_in.txt"
	echo "Smoke (no F5): cp docs/f5_soak_log.camp_wf.example.txt .f5_soak_in.txt"
	echo "Full optional camp tracks: cp docs/f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
	exit 2
fi
[[ $QUIET -eq 0 ]] && echo "=== CombatF5SoakLogValidator ==="
REPORT_STAMP="$(f5_validation_report_stamp "$REPORT_PATH")"
set +e
export FP_HARNESS_MODE=f5_validate
GODOT_ARGS=()
if [[ -n "$LOG_PATH" ]]; then
	export FP_F5_VALIDATE_LOG="$LOG_PATH"
	GODOT_ARGS=(-- "$LOG_PATH")
	[[ $QUIET -eq 0 ]] && echo "Validating: $LOG_PATH"
elif [[ -f "$INPUT_DEFAULT" ]]; then
	export FP_F5_VALIDATE_LOG="$INPUT_DEFAULT"
	GODOT_ARGS=(-- "$INPUT_DEFAULT")
	[[ $QUIET -eq 0 ]] && echo "Validating: $INPUT_DEFAULT"
fi
if [[ $QUIET -eq 1 ]]; then
	"$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_all_combat_checks.gd "${GODOT_ARGS[@]}" >/dev/null 2>&1
else
	"$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_all_combat_checks.gd "${GODOT_ARGS[@]}"
fi
EXIT_CODE=$?
set -e
unset FP_HARNESS_MODE FP_F5_VALIDATE_LOG
if ! f5_wait_validation_report "$REPORT_PATH" "$REPORT_STAMP"; then
	[[ $QUIET -eq 0 ]] && echo "WARN: validation report missing or incomplete after Godot run"
	EXIT_CODE=1
fi
if [[ $QUIET -eq 0 && -f "$REPORT_PATH" ]]; then
	echo ""
	echo "--- Report: $REPORT_PATH ---"
	cat "$REPORT_PATH"
	echo ""
	echo "--- Camp / WF-M3 track summary ---"
	if grep -E '^\[(camp_|wf_m3_)' "$REPORT_PATH" 2>/dev/null; then
		:
	else
		echo "(no camp_ or wf_m3_ tracks - combat-only paste or missing turn_ready_gauge / settlement markers)"
	fi
	LOG_HINT="${LOG_PATH:-$INPUT_DEFAULT}"
	f5_show_status_hint "$ROOT" || true
	if f5_has_fatal_errors "$LOG_HINT"; then
		echo "NOTE: FP_ERROR or SCRIPT_ERROR in log - fix before F5 validator merge"
	fi
fi
exit "$EXIT_CODE"
