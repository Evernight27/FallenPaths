#!/usr/bin/env bash
# Merge F5 Output into .f5_soak_in.txt and re-validate.
# Usage: ./scripts/append_f5_soak_log.sh path/to/chunk.txt [--label name] [--replace]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="${1:-}"
REPLACE=""
LABEL=""
PREFLIGHT=""
shift || true
while [[ $# -gt 0 ]]; do
	case "$1" in
		--replace) REPLACE="--replace" ;;
		--preflight) PREFLIGHT="-Preflight" ;;
		--skip-preflight) PREFLIGHT="-SkipPreflight" ;;
		--label)
			shift
			LABEL="${1:-}"
			;;
		*) echo "Unknown option: $1" >&2; exit 2 ;;
	esac
	shift || true
done
if [[ -z "$SRC" ]]; then
	echo "Usage: ./scripts/append_f5_soak_log.sh path/to/chunk.txt [--label name] [--replace]" >&2
	exit 1
fi
if [[ "$SRC" != /* ]]; then
	SRC="$ROOT/$SRC"
fi
EXTRA=(-AppendFrom "$SRC")
[[ -n "$REPLACE" ]] && EXTRA+=(-Replace)
[[ -n "$LABEL" ]] && EXTRA+=(-Label "$LABEL")
[[ -n "$PREFLIGHT" ]] && EXTRA+=($PREFLIGHT)
powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/append_f5_soak_log.ps1" "${EXTRA[@]}"
exit $?
