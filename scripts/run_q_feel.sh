#!/usr/bin/env bash
# F5 feel checklist (no Godot). Usage: ./scripts/run_q_feel.sh Camp|Q1|Q2
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRACK="${1:-}"

case "$TRACK" in
	Camp)
		bash "$ROOT/scripts/print_phase0_status.sh"
		echo ""
		echo "=== Track Camp: EA campaign F5 (SHIP_PLAN section 8) ==="
		echo ""
		echo "Prereq: headless GREEN above (or run ./scripts/run_all_combat_checks.sh)"
		echo ""
		echo "1. main.tscn Inspector: dev_soak_encounter EMPTY (campaign mode, no cyan soak tile)"
		echo "2. F5 -> note HUD gold / med / tools / roster"
		echo "3. Green tutorial tile -> win -> settlement -> Continue (grep settlement_continue in Output)"
		echo "4. Untreated bleed: tutorial blocks move until first win; Party field pressure (free) then bandage (-1 med)"
		echo "5. Camp rest (Party, all dressed): -1 med, 600s x3 heal, +1 day + wages; or End day on tile 0,0 (wages only)"
		echo "6. Hybrid day: 5 overworld steps also tick wages if you skipped camp rest"
		echo "7. Second paid contract -> renown scales pay"
	echo "8. Lose PAID contract -> run-end + reload (grep company_run_end reason=contract_failed reload=true)"
	echo "   Lose tutorial -> soft resume (grep company_run_end reason=tutorial_failed reload=false) + marker respawn"
		echo "9. Low gold -> wage warn, low mood -> desertion risk at day end"
		echo "10. Party menu -> triage lines match last fight"
		echo "11. Medical-phase fight -> Stack medical / self_medical on gauge (optional feel)"
		echo "12. WF-M3 footing: during sword fights grep turn_ready_gauge - Step -> Grd/Atk -> Form; diagram guard before form (docs/LIVE_PATHS.md#wf-m3-f5-playtest)"
		echo "13. Optional III-4: dev_soak_encounter=ii_envelop -> validate_f5_soak_log.ps1"
	echo "14. Paste F5 Output -> .f5_soak_in.txt (or ./scripts/append_f5_soak_log.sh) - re-run this script to scan markers"
		echo ""
		LOG="$ROOT/.f5_soak_in.txt"
		if [[ -f "$LOG" ]]; then
			echo "=== .f5_soak_in.txt (Camp section 8 markers) ==="
			scan_marker() {
				local label="$1" pat="$2"
				if grep -qF "$pat" "$LOG"; then
					echo "  [OK] $label"
					grep -m1 -F "$pat" "$LOG" | sed 's/^/        /'
				else
					echo "  [--] $label (not in log yet)"
				fi
			}
			scan_marker "settlement_continue (step 3)" "settlement_continue"
			scan_marker "field_care hint (step 4)" "field_care:"
			scan_marker "field_care bandage (step 4 action)" "field_care bandage"
			scan_marker "company_day_advanced (step 5-6)" "company_day_advanced"
			scan_marker "paid loss reload (step 8)" "company_run_end reason=contract_failed"
			scan_marker "tutorial soft resume (step 8)" "company_run_end reason=tutorial_failed"
			scan_marker "wage warn (step 9)" "company_wages: gold="
			scan_marker "desertion (step 9)" "desertion summary="
			scan_marker "party triage open (step 10)" "party_triage_open"
			scan_marker "turn_ready_gauge (WF-M3 step 12)" "turn_ready_gauge"
			scan_marker "form suffix on gauge (WF-M3)" "Form "
			scan_marker "form_switch AI auto-switch (optional WF-M3)" "form_switch id="
			camp_ok=0
			for pat in settlement_continue "contract_victory pay=" company_day_advanced; do
				grep -qF "$pat" "$LOG" && camp_ok=$((camp_ok + 1)) || true
			done
			echo ""
			echo "Camp core markers: $camp_ok / 3 (settlement + day advance for EA close-out)"
			if grep -q "turn_ready_gauge" "$LOG"; then
				echo ""
				echo "=== turn_ready_gauge samples (WF-M3 - check Step -> Grd/Atk -> Form) ==="
				grep -m3 "turn_ready_gauge" "$LOG" | sed 's/^/  /'
			fi
			if [[ -x "$ROOT/scripts/validate_f5_soak_log.sh" ]]; then
				echo ""
				echo "=== WF-M3 / Camp F5 validator ==="
				bash "$ROOT/scripts/validate_f5_soak_log.sh" "$LOG" 2>&1 | tail -n 25
				REPORT="$ROOT/.f5_soak_validation.txt"
				if [[ -f "$REPORT" ]]; then
					grep -E '^\[wf_m3_|^\[camp_|^ok=|^profiles=' "$REPORT" || true
				fi
			fi
			echo ""
		else
			echo "[.f5_soak_in.txt] missing - paste F5 Output after playtest to auto-scan markers"
			echo ""
		fi
		echo "Sign-off: tick Camp-3.4 human + Camp-5 in docs/SHIP_PLAN.md (WF-M3 step 12 + sign-off line in LIVE_PATHS#wf-m3-f5-playtest)"
		echo "Docs: docs/SHIP_PLAN.md#camp-playtest-acceptance"
		;;
	Q1)
		echo "=== Track Q1: research_feel duel ==="
		echo "Headless: ./scripts/run_q_audit.ps1 -Track Q1"
		echo "F5: dev_soak_encounter=ii2b, dev_research_feel=ON — see docs/LIVE_PATHS.md#track-q1--research-feel-duel"
		;;
	Q2)
		echo "=== Track Q2: ii2b bind / riposte / flurry feel ==="
		echo "Headless: ./scripts/run_q_audit.ps1 -Track Q2"
		echo "F5: dev_soak_encounter=ii2b — grep parry_partial, parry_stats, hit_resolve reason="
		;;
	*)
		echo "Usage: ./scripts/run_q_feel.sh Camp|Q1|Q2"
		exit 1
		;;
esac
