#!/usr/bin/env bash
# Grep followup F5 Output chunk before append.
# Usage: ./scripts/preflight_f5_followup.sh followup.log
#        ./scripts/preflight_f5_followup.sh step9.log --step9-only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-}"
STEP9=""
shift || true
while [[ $# -gt 0 ]]; do
	case "$1" in
		--step9-only) STEP9="-Step9Only" ;;
		*) echo "Unknown option: $1" >&2; exit 2 ;;
	esac
	shift || true
done
if [[ -z "$SRC" ]]; then
	echo "Usage: ./scripts/preflight_f5_followup.sh followup.log [--step9-only]" >&2
	exit 1
fi
if [[ "$SRC" != /* ]]; then SRC="$ROOT/$SRC"; fi
powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/preflight_f5_followup.ps1" "$SRC" $STEP9
exit $?
