#!/usr/bin/env bash
# Camp-1.1–1.8 headless company loop checks (Campaign stream; required in Phase 0).
# Exit: grep FP_HARNESS_OK (Godot process exit code is unreliable on some hosts).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_godot.sh
source "$SCRIPT_DIR/_godot.sh"
ROOT="$(fp_project_root)"
GODOT_BIN="$(fp_godot_bin)" || {
	echo "run_company_state_checks.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
}
set +e
OUT="$("$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_company_state_checks.gd 2>&1)"
EXIT_CODE=$?
set -e
echo "$OUT"
if echo "$OUT" | grep -q "FP_HARNESS_OK: CompanyStateChecks"; then
	exit 0
fi
exit 1
