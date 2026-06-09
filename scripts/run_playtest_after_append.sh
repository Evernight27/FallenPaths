#!/usr/bin/env bash
# Append F5 chunk then safe re-validate (Playtest stream — no Phase 0).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <chunk.txt> [append args passed to PowerShell]" >&2
	echo "  e.g. $0 followup.log --label camp_append --human-signoff" >&2
	exit 2
fi
APPEND_FROM="$1"
shift
powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/run_playtest_after_append.ps1" -AppendFrom "$APPEND_FROM" "$@"
exit $?
