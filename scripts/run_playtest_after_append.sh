#!/usr/bin/env bash
# Append F5 chunk then re-validate (no Phase 0).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ $# -ge 1 ]] || fp_die "Usage: $0 <chunk.txt> [--label name] [--human-signoff] [--skip-closeout]" 2
APPEND_FROM="$(fp_abs "$1")"
shift
LABEL=""
HUMAN_SIGNOFF=0
SKIP_CLOSEOUT=0
while [[ $# -gt 0 ]]; do
	case "$1" in
		--label) shift; LABEL="${1:-}" ;;
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--skip-closeout) SKIP_CLOSEOUT=1 ;;
		*) fp_die "Unknown option: $1" 2 ;;
	esac
	shift || true
done

echo "=== Playtest after append ==="
f5_restore_human_paste_if_clobbered "$(fp_root)" || true
APPEND_ARGS=("$APPEND_FROM")
[[ -n "$LABEL" ]] && APPEND_ARGS+=(--label "$LABEL")
bash "$SCRIPT_DIR/append_f5_soak_log.sh" "${APPEND_ARGS[@]}" \
	|| fp_die "PLAYTEST_AFTER_APPEND: FAIL (append)"

REV=(--skip-smokes)
[[ $HUMAN_SIGNOFF -eq 1 ]] && REV+=(--human-signoff)
[[ $SKIP_CLOSEOUT -eq 1 ]] && REV+=(--skip-closeout)
bash "$SCRIPT_DIR/run_playtest_revalidate.sh" "${REV[@]}" \
	|| fp_die "PLAYTEST_AFTER_APPEND: FAIL (revalidate)"
echo "PLAYTEST_AFTER_APPEND: PASS"
