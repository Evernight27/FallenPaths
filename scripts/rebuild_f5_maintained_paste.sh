#!/usr/bin/env bash
# Rebuild maintained human F5 paste from baseline + optional-smoke gap fill.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASELINE="$(fp_abs "${1:-followup.log}")"
shift || true
SKIP_PREFLIGHT=0
HUMAN_SIGNOFF=0
DRY_RUN=0
for arg in "$@"; do
	case "$arg" in
		--skip-preflight) SKIP_PREFLIGHT=1 ;;
		--human-signoff) HUMAN_SIGNOFF=1 ;;
		--dry-run) DRY_RUN=1 ;;
	esac
done
[[ -f "$BASELINE" ]] || fp_die "REBUILD_F5_MAINTAINED: FAIL (missing $BASELINE)" 2

echo "=== Rebuild maintained F5 paste ==="
echo "Baseline: $BASELINE"
if [[ $DRY_RUN -eq 1 ]]; then
	echo "  [camp5_baseline] <- $BASELINE (replace)"
	echo "  then: ./scripts/run_playtest_merge_gaps.sh"
	exit 0
fi

[[ $SKIP_PREFLIGHT -eq 1 ]] || bash "$SCRIPT_DIR/preflight_f5_followup.sh" "$BASELINE"
bash "$SCRIPT_DIR/append_f5_soak_log.sh" "$BASELINE" --replace --label camp5_baseline --skip-preflight \
	|| fp_die "REBUILD_F5_MAINTAINED: FAIL (baseline)"
MERGE=()
[[ $HUMAN_SIGNOFF -eq 1 ]] && MERGE+=(--human-signoff)
bash "$SCRIPT_DIR/run_playtest_merge_gaps.sh" "${MERGE[@]}" \
	|| fp_die "REBUILD_F5_MAINTAINED: FAIL (merge/revalidate)"
echo "REBUILD_F5_MAINTAINED: PASS"
