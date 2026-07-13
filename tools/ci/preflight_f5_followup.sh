#!/usr/bin/env bash
# Grep followup F5 Output before append.
# Usage: ./tools/ci/preflight_f5_followup.sh followup.log [--step9-only]
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
SRC="${1:-}"
MODE=full
shift || true
while [[ $# -gt 0 ]]; do
	case "$1" in
		--step9-only) MODE=step9 ;;
		*) fp_die "Unknown option: $1" 2 ;;
	esac
	shift || true
done
[[ -n "$SRC" ]] || fp_die "Usage: $0 followup.log [--step9-only]" 1
SRC="$(fp_abs "$SRC")"
[[ -f "$SRC" ]] || fp_die "Log not found: $SRC" 2
echo "=== Preflight: $SRC ==="
if f5_preflight_log "$SRC" "$MODE"; then
	echo ""
	echo "Preflight: PASS"
	if [[ "$MODE" == "step9" ]]; then
		echo "  ./tools/ci/append_f5_soak_log.sh $SRC --label camp5_step9"
	else
		echo "  ./tools/ci/append_f5_soak_log.sh $SRC --label camp5_optional"
	fi
	exit 0
fi
echo ""
if f5_has_fatal_errors "$SRC"; then
	echo "Preflight: FAIL — remove FP_ERROR / SCRIPT_ERROR before append"
else
	echo "Preflight: FAIL — missing required markers"
fi
exit 1
