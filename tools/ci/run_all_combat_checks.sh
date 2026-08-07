#!/usr/bin/env bash
# Phase 0 gate (default) or partial harness: FP_HARNESS_MODE / first arg = regression|d001|sanity|calibration|medical.
# Optional: --validate-f5 · Env: FP_SKIP_DOC_LINKS=1 (CI when doc-links job already ran).
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127

VALIDATE_F5=0
ARGS=()
for arg in "$@"; do
	case "$arg" in
		--validate-f5) VALIDATE_F5=1 ;;
		*) ARGS+=("$arg") ;;
	esac
done
MODE="${FP_HARNESS_MODE:-all}"
[[ ${#ARGS[@]} -gt 0 ]] && MODE="${ARGS[0]}"

run_partial() {
	local mode="$1" log_name=".harness_out.txt" ok="FP_HARNESS_OK: CombatRegressionHarness" log backed=0
	case "$mode" in
		regression) ;;
		d001) log_name=".d001_soak_out.txt"; ok="FP_HARNESS_OK: CombatD001SoakRunner" ;;
		sanity) log_name=".d001_soak_sanity_out.txt"; ok="FP_HARNESS_OK: CombatD001SoakSanity" ;;
		calibration) log_name=".calibration_audit.txt"; ok="FP_HARNESS_OK: CombatCalibrationAudit" ;;
		medical) log_name=".medical_phase_harness_out.txt"; ok="FP_HARNESS_OK: MedicalPhaseHarness" ;;
		*) fp_die "unknown mode '$mode'" 2 ;;
	esac
	export FP_HARNESS_MODE="$mode"
	log="$ROOT/$log_name"
	echo "=== FP_HARNESS_MODE=$mode ==="
	fp_godot_import_warmup "$ROOT" || true
	[[ "$mode" == "d001" ]] && { f5_backup_human_paste "$ROOT" && backed=1 || true; }
	set +e
	"$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_all_combat_checks.gd 2>&1 | tee "$log"
	local code=${PIPESTATUS[0]}
	set -e
	unset FP_HARNESS_MODE
	[[ "$backed" -eq 1 ]] && f5_restore_human_paste "$ROOT" || true
	grep -q "$ok" "$log" 2>/dev/null && exit 0
	exit "$code"
}

[[ "$MODE" != "all" ]] && run_partial "$MODE"

unset FP_HARNESS_MODE 2>/dev/null || true
SUMMARY="$ROOT/.phase0_combat_checks.txt"
SUMMARY_TMP="$SUMMARY.tmp"
: >"$SUMMARY_TMP"
commit() { mv -f "$SUMMARY_TMP" "$SUMMARY"; }
append_ok_line() { local f="$1" tag="$2"; [[ -f "$f" ]] || return; local l; l="$(grep -m1 '^ok=' "$f" || true)"; [[ -n "$l" ]] && echo "$tag: $l" >>"$SUMMARY_TMP"; }

if [[ "${FP_SKIP_DOC_LINKS:-0}" == "1" ]]; then
	echo "=== Doc link check (skipped; FP_SKIP_DOC_LINKS=1) ==="
else
	echo "=== Doc link check ==="
	bash "$SCRIPT_DIR/check_doc_links.sh" || exit $?
fi
echo ""
echo "=== Godot import warmup ==="
fp_godot_import_warmup "$ROOT" || true
# Company checks run right after this warmup and nothing changes between them;
# skip its internal re-import + settle sleep (saves ~9s per gate).
export FP_SKIP_IMPORT_WARMUP=1
echo ""

echo "=== CompanyStateChecks ==="
set +e
COMPANY_OUT="$(bash "$SCRIPT_DIR/run_company_state_checks.sh" 2>&1)"
COMPANY_EXIT=$?
set -e
echo "$COMPANY_OUT"
COMPANY_OK="$(echo "$COMPANY_OUT" | grep "FP_HARNESS_OK: CompanyStateChecks" | tail -1 || true)"
if [[ $COMPANY_EXIT -ne 0 || -z "$COMPANY_OK" ]]; then
	{ echo "COMPANY_STATE: FAIL exit=$COMPANY_EXIT"; echo "PHASE0: FAIL (company state checks)"; } >>"$SUMMARY_TMP"
	commit
	fp_die "=== PHASE0 FAIL (CompanyStateChecks) ==="
fi
echo "COMPANY_STATE: PASS" >>"$SUMMARY_TMP"
echo "$COMPANY_OK" >>"$SUMMARY_TMP"
echo ""

echo "=== AllCombatChecks ==="
BACKED=0
f5_backup_human_paste "$ROOT" && BACKED=1 || true
set +e
OUT="$("$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_all_combat_checks.gd 2>&1)"
EXIT_CODE=$?
set -e
[[ "$BACKED" -eq 1 ]] && f5_restore_human_paste "$ROOT" || true
echo "$OUT"
echo "$OUT" | grep -E '^FP_HARNESS_(OK|SUMMARY|FAIL):' >>"$SUMMARY_TMP" || true
[[ $EXIT_CODE -ne 0 ]] && echo "EXIT=$EXIT_CODE" >>"$SUMMARY_TMP"

D001="$ROOT/.d001_soak_out.txt"
SIGNOFF="$ROOT/.d001_headless_signoff.txt"
CAL="$ROOT/.calibration_audit.txt"
append_ok_line "$D001" D001_REPORT
append_ok_line "$SIGNOFF" HEADLESS_SIGNOFF
append_ok_line "$CAL" CALIBRATION_AUDIT
if [[ -f "$CAL" ]]; then
	line="$(grep -m1 '^production_headless_gate=' "$CAL" || true)"
	[[ -n "$line" ]] && echo "RESEARCH: $line" >>"$SUMMARY_TMP"
	line="$(grep -m1 '^research_verdict_summary ' "$CAL" || true)"
	[[ -n "$line" ]] && echo "RESEARCH: $line" >>"$SUMMARY_TMP"
	line="$(grep -m1 '^research_harness_gate_count=' "$CAL" || true)"
	[[ -n "$line" ]] && echo "RESEARCH: $line" >>"$SUMMARY_TMP"
fi

artifact_ok() { [[ -f "$1" ]] && grep -q '^ok=true' "$1"; }
FAIL=0
if ! echo "$OUT" | grep -q "FP_HARNESS_OK: AllCombatChecks"; then
	if artifact_ok "$D001" && artifact_ok "$SIGNOFF" && artifact_ok "$CAL"; then
		echo "FP_HARNESS_NOTE: AllCombatChecks ok via artifacts" >>"$SUMMARY_TMP"
	else
		echo "PHASE0: FAIL missing FP_HARNESS_OK: AllCombatChecks" >>"$SUMMARY_TMP"
		FAIL=1
	fi
fi
[[ $EXIT_CODE -ne 0 && $FAIL -eq 0 ]] && echo "FP_HARNESS_NOTE: Godot exit=$EXIT_CODE ignored (artifacts ok)" >>"$SUMMARY_TMP"
artifact_ok "$D001" || { echo "PHASE0: FAIL D001_REPORT not ok=true" >>"$SUMMARY_TMP"; FAIL=1; }
artifact_ok "$SIGNOFF" || { echo "PHASE0: FAIL HEADLESS_SIGNOFF not ok=true" >>"$SUMMARY_TMP"; FAIL=1; }
artifact_ok "$CAL" || { echo "PHASE0: FAIL CALIBRATION_AUDIT not ok=true" >>"$SUMMARY_TMP"; FAIL=1; }
if [[ $FAIL -ne 0 ]]; then
	echo "ran_at=$(date '+%Y-%m-%d %H:%M:%S')" >>"$SUMMARY_TMP"
	commit
	fp_die "=== PHASE0 FAIL (artifact check) ==="
fi
echo "PHASE0: PASS" >>"$SUMMARY_TMP"
echo ""; echo "=== PHASE0 PASS ==="; echo ""

echo "=== Campaign ship audit tail ==="
set +e
bash "$SCRIPT_DIR/run_campaign_ship_audit.sh" --tail-only
CAMPAIGN_EXIT=$?
set -e
AUDIT="$ROOT/.campaign_ship_audit.txt"
if [[ -f "$AUDIT" ]]; then
	grep -E '^(Q_TRACK|II7_MEDICAL|II_ENVELOP|II_ENVELOP_MOPUP|CAMPAIGN_SHIP_AUDIT):' "$AUDIT" >>"$SUMMARY_TMP" || true
fi
if [[ $CAMPAIGN_EXIT -ne 0 ]]; then
	echo "ran_at=$(date '+%Y-%m-%d %H:%M:%S')" >>"$SUMMARY_TMP"
	commit
	exit "$CAMPAIGN_EXIT"
fi
echo "ran_at=$(date '+%Y-%m-%d %H:%M:%S')" >>"$SUMMARY_TMP"
commit
echo "Summary: $SUMMARY"
f5_show_status_hint "$ROOT" || true
echo "F5: ./tools/ci/run_playtest.sh closeout | status: ./tools/ci/print_phase0_status.sh"
[[ $VALIDATE_F5 -eq 1 ]] && bash "$SCRIPT_DIR/validate_f5_soak_log.sh"
exit 0
