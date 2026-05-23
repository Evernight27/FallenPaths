#!/usr/bin/env bash
# Phase 0 gate (default) or partial harness when FP_HARNESS_MODE is set (regression|d001|sanity|calibration|medical).
# Optional: --validate-f5
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_godot.sh
source "$SCRIPT_DIR/_godot.sh"
ROOT="$(fp_project_root)"
GODOT_BIN="$(fp_godot_bin)" || {
	echo "run_all_combat_checks.sh: set GODOT to your Godot 4 binary" >&2
	exit 127
}

VALIDATE_F5=0
ARGS=()
for arg in "$@"; do
	case "$arg" in
		--validate-f5) VALIDATE_F5=1 ;;
		*) ARGS+=("$arg") ;;
	esac
done

MODE="${FP_HARNESS_MODE:-all}"
if [[ ${#ARGS[@]} -gt 0 ]]; then
	MODE="${ARGS[0]}"
fi

if [[ "$MODE" != "all" ]]; then
	case "$MODE" in
		regression|d001|sanity|calibration|medical) ;;
		*)
			echo "run_all_combat_checks.sh: unknown mode '$MODE' (regression|d001|sanity|calibration|medical|all)" >&2
			exit 2
			;;
	esac
	LOG_NAME=".harness_out.txt"
	OK_GREP="FP_HARNESS_OK: CombatRegressionHarness"
	case "$MODE" in
		d001) LOG_NAME=".d001_soak_out.txt"; OK_GREP="FP_HARNESS_OK: CombatD001SoakRunner" ;;
		sanity) LOG_NAME=".d001_soak_sanity_out.txt"; OK_GREP="FP_HARNESS_OK: CombatD001SoakSanity" ;;
		calibration) LOG_NAME=".calibration_audit.txt"; OK_GREP="FP_HARNESS_OK: CombatCalibrationAudit" ;;
		medical) LOG_NAME=".medical_phase_harness_out.txt"; OK_GREP="FP_HARNESS_OK: MedicalPhaseHarness" ;;
	esac
	export FP_HARNESS_MODE="$MODE"
	LOG="$ROOT/$LOG_NAME"
	echo "=== FP_HARNESS_MODE=$MODE ==="
	set +e
	"$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_all_combat_checks.gd 2>&1 | tee "$LOG"
	EXIT_CODE=${PIPESTATUS[0]}
	set -e
	unset FP_HARNESS_MODE
	if grep -q "$OK_GREP" "$LOG" 2>/dev/null; then
		exit 0
	fi
	exit "$EXIT_CODE"
fi

unset FP_HARNESS_MODE 2>/dev/null || true
SUMMARY_PATH="$ROOT/.phase0_combat_checks.txt"
D001_REPORT="$ROOT/.d001_soak_out.txt"

echo "=== Doc link check ==="
if [[ -f "$ROOT/scripts/check_doc_links.sh" ]]; then
	bash "$ROOT/scripts/check_doc_links.sh" || exit $?
elif command -v pwsh >/dev/null 2>&1; then
	pwsh -NoProfile -File "$ROOT/scripts/check_doc_links.ps1" || exit $?
else
	echo "DOC_LINKS: skip (no check_doc_links.sh / pwsh)"
fi
echo ""

echo "=== AllCombatChecks (regression + D-001 + calibration) ==="
set +e
OUT="$("$GODOT_BIN" --headless --path "$ROOT" -s res://scripts/run_all_combat_checks.gd 2>&1)"
EXIT_CODE=$?
set -e
echo "$OUT"
: >"$SUMMARY_PATH"
echo "$OUT" | grep -E '^FP_HARNESS_(OK|SUMMARY|FAIL):' >>"$SUMMARY_PATH" || true
if [[ $EXIT_CODE -ne 0 ]]; then
	echo "EXIT=$EXIT_CODE" >>"$SUMMARY_PATH"
	exit "$EXIT_CODE"
fi
if [[ -f "$D001_REPORT" ]]; then
	OK_LINE="$(grep -m1 '^ok=' "$D001_REPORT" || true)"
	if [[ -n "$OK_LINE" ]]; then
		echo "D001_REPORT: $OK_LINE" >>"$SUMMARY_PATH"
	fi
fi
SIGNOFF_PATH="$ROOT/.d001_headless_signoff.txt"
if [[ -f "$SIGNOFF_PATH" ]]; then
	SIGN_LINE="$(grep -m1 '^ok=' "$SIGNOFF_PATH" || true)"
	if [[ -n "$SIGN_LINE" ]]; then
		echo "HEADLESS_SIGNOFF: $SIGN_LINE" >>"$SUMMARY_PATH"
	fi
fi
CAL_PATH="$ROOT/.calibration_audit.txt"
if [[ -f "$CAL_PATH" ]]; then
	CAL_LINE="$(grep -m1 '^ok=' "$CAL_PATH" || true)"
	if [[ -n "$CAL_LINE" ]]; then
		echo "CALIBRATION_AUDIT: $CAL_LINE" >>"$SUMMARY_PATH"
	fi
	GATE_LINE="$(grep -m1 '^production_headless_gate=' "$CAL_PATH" || true)"
	if [[ -n "$GATE_LINE" ]]; then
		echo "RESEARCH: $GATE_LINE" >>"$SUMMARY_PATH"
	fi
	SUMMARY_LINE="$(grep -m1 '^research_verdict_summary ' "$CAL_PATH" || true)"
	if [[ -n "$SUMMARY_LINE" ]]; then
		echo "RESEARCH: $SUMMARY_LINE" >>"$SUMMARY_PATH"
	fi
	GATE_COUNT="$(grep -m1 '^research_harness_gate_count=' "$CAL_PATH" || true)"
	if [[ -n "$GATE_COUNT" ]]; then
		echo "RESEARCH: $GATE_COUNT" >>"$SUMMARY_PATH"
	fi
fi
ARTIFACT_FAIL=0
if ! echo "$OUT" | grep -q "FP_HARNESS_OK: AllCombatChecks"; then
	if [[ $EXIT_CODE -eq 0 ]] \
		&& [[ -f "$D001_REPORT" ]] && grep -q "^ok=true" "$D001_REPORT" \
		&& [[ -f "$SIGNOFF_PATH" ]] && grep -q "^ok=true" "$SIGNOFF_PATH" \
		&& [[ -f "$CAL_PATH" ]] && grep -q "^ok=true" "$CAL_PATH"; then
		echo "FP_HARNESS_NOTE: AllCombatChecks ok via artifacts (stdout tag missing)" >>"$SUMMARY_PATH"
	else
		echo "PHASE0: FAIL missing FP_HARNESS_OK: AllCombatChecks" >>"$SUMMARY_PATH"
		ARTIFACT_FAIL=1
	fi
fi
if [[ ! -f "$D001_REPORT" ]] || ! grep -q "^ok=true" "$D001_REPORT"; then
	echo "PHASE0: FAIL D001_REPORT not ok=true" >>"$SUMMARY_PATH"
	ARTIFACT_FAIL=1
fi
if [[ ! -f "$SIGNOFF_PATH" ]] || ! grep -q "^ok=true" "$SIGNOFF_PATH"; then
	echo "PHASE0: FAIL HEADLESS_SIGNOFF not ok=true" >>"$SUMMARY_PATH"
	ARTIFACT_FAIL=1
fi
if [[ ! -f "$CAL_PATH" ]] || ! grep -q "^ok=true" "$CAL_PATH"; then
	echo "PHASE0: FAIL CALIBRATION_AUDIT not ok=true" >>"$SUMMARY_PATH"
	ARTIFACT_FAIL=1
fi
if [[ $ARTIFACT_FAIL -ne 0 ]]; then
	echo "ran_at=$(date '+%Y-%m-%d %H:%M:%s')" >>"$SUMMARY_PATH"
	echo ""
	echo "=== PHASE0 FAIL (artifact check) ==="
	exit 1
fi
{
	echo "PHASE0: PASS"
	echo "ran_at=$(date '+%Y-%m-%d %H:%M:%s')"
} >>"$SUMMARY_PATH"
echo ""
echo "=== PHASE0 PASS ==="
echo "Summary: $SUMMARY_PATH"
if [[ $VALIDATE_F5 -eq 1 ]]; then
	bash "$ROOT/scripts/validate_f5_soak_log.sh" || exit $?
fi
exit 0
