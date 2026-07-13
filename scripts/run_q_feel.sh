#!/usr/bin/env bash
# F5 feel checklist (no Godot). Usage: ./scripts/run_q_feel.sh Camp|Q1|Q2
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRACK="${1:-}"

case "$TRACK" in
	Camp)
		LOG="$(f5_soak_log_path "$ROOT")"
		VAL="$ROOT/.f5_soak_validation.txt"
		[[ -f "$LOG" ]] && { bash "$SCRIPT_DIR/validate_f5_soak_log.sh" --quiet "$LOG" || true; }
		bash "$SCRIPT_DIR/print_phase0_status.sh"
		cat <<'EOF'

=== Track Camp (SHIP_PLAN §8) ===
1. main.tscn: dev_soak_encounter EMPTY
2. F5 → note HUD gold / med / roster
3. Tutorial win → settlement Continue (settlement_continue)
4. Party field pressure then bandage
5. Camp rest or End day (wages)
6. Paid contract → renown pay scale
7. Lose paid → company_run_end contract_failed; tutorial soft → tutorial_failed
8. Wage warn / desertion at day end
9. Party triage lines
10. WF-M3: turn_ready_gauge Step → Grd/Atk → Form
11. Paste Output → .f5_soak_in.txt (append_f5_soak_log.sh)

EOF
		if [[ -f "$LOG" ]]; then
			echo "=== .f5_soak_in.txt markers ==="
			for row in \
				"settlement_continue|settlement_continue" \
				"field_care|field_care:" \
				"company_day|company_day_advanced" \
				"paid loss|company_run_end reason=contract_failed" \
				"tutorial soft|company_run_end reason=tutorial_failed" \
				"wages|company_wages: gold=" \
				"desertion|desertion summary=" \
				"triage|party_triage_open" \
				"gauge|turn_ready_gauge"
			do
				label="${row%%|*}"; pat="${row#*|}"
				if grep -qF "$pat" "$LOG"; then echo "  [OK] $label"
				else echo "  [--] $label"; fi
			done
			[[ -f "$VAL" ]] && grep -E '^\[wf_m3_|^\[camp_|^ok=' "$VAL" || true
		else
			echo "[.f5_soak_in.txt] missing — paste after playtest"
		fi
		;;
	Q1)
		echo "=== Q1 research_feel ==="
		echo "Headless: ./scripts/run_q_audit.ps1 -Track Q1"
		echo "F5: dev_soak_encounter=ii2b, dev_research_feel=ON"
		;;
	Q2)
		echo "=== Q2 bind / riposte ==="
		echo "Headless: ./scripts/run_q_audit.ps1 -Track Q2"
		echo "F5: dev_soak_encounter=ii2b — grep parry_partial / hit_resolve"
		;;
	*)
		fp_die "Usage: $0 Camp|Q1|Q2" 1
		;;
esac
