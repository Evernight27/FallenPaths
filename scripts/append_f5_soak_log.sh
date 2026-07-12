#!/usr/bin/env bash
# Merge F5 Output into .f5_soak_in.txt and re-validate.
# Usage: ./scripts/append_f5_soak_log.sh chunk.txt [--label name] [--replace] [--preflight|--skip-preflight]
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SRC="${1:-}"
REPLACE=0
LABEL=""
PREFLIGHT=auto
shift || true
while [[ $# -gt 0 ]]; do
	case "$1" in
		--replace) REPLACE=1 ;;
		--preflight) PREFLIGHT=1 ;;
		--skip-preflight) PREFLIGHT=0 ;;
		--label) shift; LABEL="${1:-}" ;;
		*) fp_die "Unknown option: $1" 2 ;;
	esac
	shift || true
done
[[ -n "$SRC" ]] || fp_die "Usage: $0 path/to/chunk.txt [--label name] [--replace]" 1
SRC="$(fp_abs "$SRC")"
[[ -f "$SRC" ]] || fp_die "Source not found: $SRC" 2

do_pf=0
[[ "$PREFLIGHT" == "1" ]] && do_pf=1
[[ "$PREFLIGHT" == "auto" && "$LABEL" =~ camp5|camp_section ]] && do_pf=1
if [[ "$do_pf" -eq 1 ]]; then
	mode=full
	[[ "$LABEL" =~ camp5_step9 ]] && mode=step9
	echo "=== Preflight: $SRC ==="
	f5_preflight_log "$SRC" "$mode" || fp_die "Preflight FAIL — ./scripts/preflight_f5_followup.sh $SRC"
	echo "Preflight: PASS"
fi

f5_append_chunk "$ROOT" "$SRC" "$LABEL" "$REPLACE"
bash "$(dirname "$0")/validate_f5_soak_log.sh" --quiet "$(f5_soak_log_path "$ROOT")"
code=$?
if [[ "$code" -eq 0 && -n "$LABEL" ]] && f5_should_preserve "$ROOT"; then
	cp "$(f5_soak_log_path "$ROOT")" "$(f5_soak_backup_path "$ROOT")"
	echo "Updated backup -> $(f5_soak_backup_path "$ROOT")"
fi
exit "$code"
