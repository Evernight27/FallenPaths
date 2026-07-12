#!/usr/bin/env bash
# Restore human F5 paste from .f5_soak_in.f5_backup.txt.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=f5_soak_log_helpers.sh
source "$SCRIPT_DIR/f5_soak_log_helpers.sh"
BAK="$(f5_soak_backup_path "$ROOT")"
if [[ ! -f "$BAK" ]]; then
	echo "No backup at $BAK" >&2
	echo "Backup is created when Phase 0 runs while .f5_soak_in.txt has FP_WORLD: lines or append chunks." >&2
	exit 1
fi
if f5_is_example_smoke "$BAK"; then
	echo "WARN: backup is docs example smoke, not a real F5 paste" >&2
fi
f5_restore_human_paste "$ROOT"
powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/validate_f5_soak_log.ps1"
exit $?
