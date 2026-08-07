#!/usr/bin/env bash
# Fast Phase 0: doc links + company state + regression (no D001 soak / calibration / campaign audit).
#   ./tools/ci/run_fast_phase0.sh           # ~2–4 min
#   ./tools/ci/run_fast_phase0.sh --full    # same as run_all_combat_checks.sh
# Env: FP_SKIP_DOC_LINKS=1 skips the doc-links step (CI already ran it).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127

for arg in "$@"; do
	case "$arg" in
		--full|-Full) exec bash "$SCRIPT_DIR/run_all_combat_checks.sh" ;;
		--d001-light|-D001Light)
			fp_die "D001 light: use run_fast_phase0.ps1 -D001Light (no bash twin yet)" 2
			;;
		-h|--help)
			echo "Usage: $0 [--full]"
			echo "  default   doc links + company state + regression harness"
			echo "  --full    full Phase 0 (run_all_combat_checks.sh)"
			echo "Env: FP_SKIP_DOC_LINKS=1"
			exit 0
			;;
		*) fp_die "unknown arg '$arg' (try --help)" 2 ;;
	esac
done

SUMMARY="$ROOT/.phase0_fast.txt"
: >"$SUMMARY"
FAIL=0

echo "=== Fast Phase 0 (regression + company state) ==="
echo ""

if [[ "${FP_SKIP_DOC_LINKS:-0}" != "1" ]]; then
	echo "=== Doc link check ==="
	if bash "$SCRIPT_DIR/check_doc_links.sh"; then
		echo "DOC_LINKS: PASS" >>"$SUMMARY"
	else
		echo "DOC_LINKS: FAIL" >>"$SUMMARY"
		FAIL=1
	fi
	echo ""
else
	echo "=== Doc link check (skipped; FP_SKIP_DOC_LINKS=1) ==="
	echo "DOC_LINKS: SKIP" >>"$SUMMARY"
	echo ""
fi

if [[ $FAIL -eq 0 ]]; then
	echo "=== CompanyStateChecks ==="
	echo "=== Godot import warmup ==="
	fp_godot_import_warmup "$ROOT" || true
	# Company checks run right after this warmup; skip its internal re-import.
	export FP_SKIP_IMPORT_WARMUP=1
	set +e
	COMPANY_OUT="$(bash "$SCRIPT_DIR/run_company_state_checks.sh" 2>&1)"
	COMPANY_EXIT=$?
	set -e
	echo "$COMPANY_OUT"
	COMPANY_OK="$(echo "$COMPANY_OUT" | grep "FP_HARNESS_OK: CompanyStateChecks" | tail -1 || true)"
	if [[ $COMPANY_EXIT -ne 0 || -z "$COMPANY_OK" ]]; then
		echo "COMPANY_STATE: FAIL exit=$COMPANY_EXIT" >>"$SUMMARY"
		FAIL=1
	else
		echo "COMPANY_STATE: PASS" >>"$SUMMARY"
		echo "$COMPANY_OK" >>"$SUMMARY"
	fi
	echo ""
fi

if [[ $FAIL -eq 0 ]]; then
	echo "=== CombatRegressionHarness ==="
	REG_LOG="$ROOT/.phase0_fast_regression.txt"
	export FP_HARNESS_MODE=regression
	set +e
	"$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_all_combat_checks.gd 2>&1 | tee "$REG_LOG"
	REG_EXIT=${PIPESTATUS[0]}
	set -e
	unset FP_HARNESS_MODE
	if grep -q "FP_HARNESS_OK: CombatRegressionHarness" "$REG_LOG" 2>/dev/null; then
		echo "REGRESSION: PASS" >>"$SUMMARY"
		grep -m1 "FP_HARNESS_OK: CombatRegressionHarness" "$REG_LOG" >>"$SUMMARY" || true
	else
		echo "REGRESSION: FAIL exit=$REG_EXIT" >>"$SUMMARY"
		FAIL=1
	fi
	echo ""
fi

echo "ran_at=$(date '+%Y-%m-%d %H:%M:%S')" >>"$SUMMARY"
if [[ $FAIL -ne 0 ]]; then
	echo "FAST_PHASE0: FAIL" >>"$SUMMARY"
	echo "=== FAST_PHASE0: FAIL ==="
	echo "Summary: $SUMMARY"
	exit 1
fi

echo "FAST_PHASE0: PASS" >>"$SUMMARY"
echo "=== FAST_PHASE0: PASS ==="
echo ""
echo "Fast Phase 0 covers regression + company state."
echo "For full PHASE0: ./tools/ci/run_all_combat_checks.sh"
echo "Summary: $SUMMARY"
exit 0
