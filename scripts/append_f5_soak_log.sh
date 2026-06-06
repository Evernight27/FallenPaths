#!/usr/bin/env bash
# Merge F5 Output into .f5_soak_in.txt and re-validate.
# Usage: ./scripts/append_f5_soak_log.sh path/to/chunk.txt [--replace]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="${1:-}"
REPLACE=""
[[ "${2:-}" == "--replace" ]] && REPLACE="--replace"
if [[ -z "$SRC" ]]; then
	echo "Usage: ./scripts/append_f5_soak_log.sh path/to/chunk.txt [--replace]" >&2
	exit 1
fi
if [[ "$SRC" != /* ]]; then
	SRC="$ROOT/$SRC"
fi
EXTRA=(-AppendFrom "$SRC")
[[ -n "$REPLACE" ]] && EXTRA+=(-Replace)
powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/validate_f5_soak_log.ps1" "${EXTRA[@]}"
exit $?
