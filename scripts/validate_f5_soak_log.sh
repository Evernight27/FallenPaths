#!/usr/bin/env bash
# Validate .f5_soak_in.txt (headless capture or pasted F5 Output).
# Usage: ./scripts/validate_f5_soak_log.sh [path/to/log]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_godot.sh
source "$SCRIPT_DIR/_godot.sh"
ROOT="$(fp_project_root)"
GODOT_BIN="$(fp_godot_bin)" || {
	echo "validate_f5_soak_log.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
}
LOG_PATH="${1:-}"
INPUT_DEFAULT="$ROOT/.f5_soak_in.txt"
REPORT_PATH="$ROOT/.f5_soak_validation.txt"
EXTRA=()
if [[ -n "$LOG_PATH" ]]; then
	if [[ "$LOG_PATH" != /* ]]; then
		LOG_PATH="$ROOT/$LOG_PATH"
	fi
	if [[ ! -f "$LOG_PATH" ]]; then
		echo "Log file not found: $LOG_PATH" >&2
		exit 2
	fi
	EXTRA=(-- "$LOG_PATH")
elif [[ ! -f "$INPUT_DEFAULT" ]]; then
	echo "No log at $INPUT_DEFAULT"
	echo "Run ./scripts/run_all_combat_checks.sh first, or paste F5 Output into .f5_soak_in.txt"
	echo "Smoke (no F5): cp docs/f5_soak_log.example.txt .f5_soak_in.txt"
	exit 2
fi
echo "=== CombatF5SoakLogValidator ==="
set +e
"$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_f5_soak_log_validator.gd "${EXTRA[@]}"
EXIT_CODE=$?
set -e
if [[ -f "$REPORT_PATH" ]]; then
	echo ""
	echo "--- Report: $REPORT_PATH ---"
	cat "$REPORT_PATH"
fi
exit "$EXIT_CODE"
