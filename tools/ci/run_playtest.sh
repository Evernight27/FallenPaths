#!/usr/bin/env bash
# Playtest dispatcher (no Phase 0).
#
#   ./tools/ci/run_playtest.sh status|merge|revalidate|recover|after-append|full|exp0|rebuild [args]
#   Thin aliases: validate|append|preflight|closeout|restore  (same as standalone F5 scripts)
#
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
HERE="$(cd "$(dirname "$0")" && pwd)"
USAGE="status|merge|revalidate|recover|after-append|full|exp0|rebuild|validate|append|preflight|closeout|restore"
CMD="${1:-}"
[[ -n "$CMD" ]] || fp_die "Usage: $0 $USAGE …" 2
shift || true

print_plan() {
	local -a plan=("$@")
	local row track label path
	echo "Merge gaps: ${#plan[@]}"
	for row in "${plan[@]:-}"; do
		[[ -n "${row:-}" ]] || continue
		IFS='|' read -r track label path <<<"$row"
		echo "  [$track] $label <- $path"
	done
}

require_human_log() {
	local log
	log="$(f5_soak_log_path "$ROOT")"
	[[ -f "$log" ]] || fp_die "$1: FAIL (missing .f5_soak_in.txt)" "${2:-1}"
	f5_is_headless_capture_only "$log" && fp_die "$1: FAIL (headless capture — $0 recover --force-restore)" "${2:-1}"
}

# Thin aliases → existing F5 CLIs (compat; prefer these via run_playtest).
cmd_validate() { exec bash "$HERE/validate_f5_soak_log.sh" "$@"; }
cmd_append() { exec bash "$HERE/append_f5_soak_log.sh" "$@"; }
cmd_preflight() { exec bash "$HERE/preflight_f5_followup.sh" "$@"; }
cmd_closeout() { exec bash "$HERE/run_camp_f5_closeout.sh" "$@"; }
cmd_restore() { exec bash "$HERE/restore_f5_soak_log.sh" "$@"; }

cmd_status() {
	local refresh=0 show_gaps=0 quiet=0
	for arg in "$@"; do
		case "$arg" in
			--refresh) refresh=1 ;;
			--show-gaps) show_gaps=1 ;;
			--smoke-labels) ;;
			--quiet) quiet=1 ;;
		esac
	done
	echo "=== Playtest status ==="
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	require_human_log PLAYTEST_STATUS 2
	f5_ensure_validation_fresh "$ROOT" "$refresh" || fp_die "PLAYTEST_STATUS: FAIL (validate)"
	local val="$ROOT/.f5_soak_validation.txt"
	echo "human_signoff: $(f5_human_signoff_status "$(f5_soak_log_path "$ROOT")")"
	grep -q '^ok=true' "$val" 2>/dev/null || fp_die "PLAYTEST_STATUS: FAIL (ok=false)"
	f5_validation_fresh "$ROOT" || fp_die "PLAYTEST_STATUS: FAIL (stale — --refresh)"
	mapfile -t plan < <(f5_gap_merge_plan "$ROOT" "$val")
	if [[ $show_gaps -eq 1 || ${#plan[@]} -gt 0 ]]; then
		print_plan "${plan[@]}"
		[[ $show_gaps -eq 0 && ${#plan[@]} -gt 0 ]] && echo "Hint: $0 merge --dry-run"
	fi
	[[ ${#plan[@]} -eq 0 ]] && { echo "PLAYTEST_STATUS: PASS"; exit 0; }
	[[ $quiet -eq 0 ]] && echo "Hint: $0 merge"
	echo "PLAYTEST_STATUS: GAPS"
	exit 1
}

cmd_revalidate() {
	local human=0 skip_smokes=0 skip_closeout=0 exp0=0
	for arg in "$@"; do
		case "$arg" in
			--human-signoff) human=1 ;;
			--skip-smokes) skip_smokes=1 ;;
			--skip-closeout) skip_closeout=1 ;;
			--exp0-gate) exp0=1 ;;
		esac
	done
	echo "=== Playtest re-validate ==="
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	require_human_log PLAYTEST_REVALIDATE
	bash "$HERE/validate_f5_soak_log.sh" --quiet
	f5_validation_fresh "$ROOT" || fp_die "PLAYTEST_REVALIDATE: FAIL (validate)"
	if [[ $skip_smokes -eq 0 ]]; then
		bash "$HERE/validate_camp_optional_smokes.sh" --quiet
		f5_restore_human_paste_if_clobbered "$ROOT" || true
		f5_ensure_validation_fresh "$ROOT" || true
	fi
	[[ $skip_closeout -eq 1 ]] && { echo "PLAYTEST_REVALIDATE: PASS (skipped closeout)"; exit 0; }
	local closeout=(--skip-revalidate)
	[[ $human -eq 1 ]] && closeout+=(--human-signoff)
	bash "$HERE/run_camp_f5_closeout.sh" "${closeout[@]}"
	[[ $exp0 -eq 1 ]] && bash "$HERE/run_playtest.sh" exp0 --skip-closeout
	echo "PLAYTEST_REVALIDATE: PASS"
}

cmd_merge() {
	local dry=0 human=0 skip_rev=0
	for arg in "$@"; do
		case "$arg" in
			--dry-run) dry=1 ;;
			--human-signoff) human=1 ;;
			--skip-revalidate) skip_rev=1 ;;
		esac
	done
	echo "=== Playtest merge gaps ==="
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	require_human_log PLAYTEST_MERGE_GAPS
	f5_ensure_validation_fresh "$ROOT" || fp_die "PLAYTEST_MERGE_GAPS: FAIL (validate before merge)"
	mapfile -t plan < <(f5_gap_merge_plan "$ROOT" "$ROOT/.f5_soak_validation.txt")
	if [[ ${#plan[@]} -eq 0 ]]; then
		echo "PLAYTEST_MERGE_GAPS: no gaps"
		[[ $skip_rev -eq 1 || $dry -eq 1 ]] && exit 0
		local rev=()
		[[ $human -eq 1 ]] && rev+=(--human-signoff)
		exec bash "$HERE/run_playtest.sh" revalidate "${rev[@]}"
	fi
	print_plan "${plan[@]}"
	[[ $dry -eq 1 ]] && { echo "PLAYTEST_MERGE_GAPS: dry-run"; exit 0; }
	local row _t label path
	for row in "${plan[@]}"; do
		IFS='|' read -r _t label path <<<"$row"
		[[ -f "$path" ]] || fp_die "PLAYTEST_MERGE_GAPS: FAIL (missing $path)" 2
		bash "$HERE/append_f5_soak_log.sh" "$path" --label "$label" --skip-preflight \
			|| fp_die "PLAYTEST_MERGE_GAPS: FAIL (append $label)"
	done
	[[ $skip_rev -eq 1 ]] && { echo "PLAYTEST_MERGE_GAPS: PASS (skipped revalidate)"; exit 0; }
	local rev=()
	[[ $human -eq 1 ]] && rev+=(--human-signoff)
	bash "$HERE/run_playtest.sh" revalidate "${rev[@]}" || fp_die "PLAYTEST_MERGE_GAPS: FAIL (revalidate)"
	echo "PLAYTEST_MERGE_GAPS: PASS"
}

cmd_recover() {
	local dry=0 human=0 force=0
	for arg in "$@"; do
		case "$arg" in
			--dry-run) dry=1 ;;
			--human-signoff) human=1 ;;
			--force-restore) force=1 ;;
		esac
	done
	echo "=== Playtest recover ==="
	local log bak
	log="$(f5_soak_log_path "$ROOT")"
	bak="$(f5_soak_backup_path "$ROOT")"
	if ! f5_restore_human_paste_if_clobbered "$ROOT"; then
		if [[ -f "$log" ]] && f5_is_headless_capture_only "$log" && [[ -f "$bak" ]]; then
			[[ $force -eq 1 ]] || fp_die "PLAYTEST_RECOVER: FAIL (headless — use --force-restore)" 2
			[[ $dry -eq 0 ]] && f5_restore_human_paste "$ROOT"
			[[ $dry -eq 1 ]] && echo "Would restore from $bak"
		fi
	fi
	require_human_log PLAYTEST_RECOVER 2
	if [[ $dry -eq 1 ]]; then
		f5_ensure_validation_fresh "$ROOT" || true
		mapfile -t plan < <(f5_gap_merge_plan "$ROOT" "$ROOT/.f5_soak_validation.txt")
		print_plan "${plan[@]}"
		echo "PLAYTEST_RECOVER: dry-run"
		exit 0
	fi
	f5_ensure_validation_fresh "$ROOT" || true
	local merge=()
	[[ $human -eq 1 ]] && merge+=(--human-signoff)
	bash "$HERE/run_playtest.sh" merge "${merge[@]}"
	bash "$HERE/run_playtest.sh" status --quiet
}

cmd_after_append() {
	[[ $# -ge 1 ]] || fp_die "Usage: $0 after-append <chunk.txt> [--label name] [--human-signoff] [--skip-closeout]" 2
	local src label="" human=0 skip_close=0
	src="$(fp_abs "$1")"
	shift
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--label) shift; label="${1:-}" ;;
			--human-signoff) human=1 ;;
			--skip-closeout) skip_close=1 ;;
			*) fp_die "Unknown option: $1" 2 ;;
		esac
		shift || true
	done
	echo "=== Playtest after append ==="
	f5_restore_human_paste_if_clobbered "$ROOT" || true
	local append=("$src")
	[[ -n "$label" ]] && append+=(--label "$label")
	bash "$HERE/append_f5_soak_log.sh" "${append[@]}" || fp_die "PLAYTEST_AFTER_APPEND: FAIL (append)"
	local rev=(--skip-smokes)
	[[ $human -eq 1 ]] && rev+=(--human-signoff)
	[[ $skip_close -eq 1 ]] && rev+=(--skip-closeout)
	bash "$HERE/run_playtest.sh" revalidate "${rev[@]}" || fp_die "PLAYTEST_AFTER_APPEND: FAIL (revalidate)"
	echo "PLAYTEST_AFTER_APPEND: PASS"
}

cmd_full() {
	local dry=0 human=0 skip_exp0=0
	for arg in "$@"; do
		case "$arg" in
			--dry-run) dry=1 ;;
			--human-signoff) human=1 ;;
			--skip-exp0) skip_exp0=1 ;;
		esac
	done
	echo "=== Playtest full gate ==="
	local phase0="$ROOT/.phase0_combat_checks.txt"
	if ! { [[ -f "$phase0" ]] && grep -q '^PHASE0: PASS' "$phase0" && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$phase0"; }; then
		fp_die "PLAYTEST_FULL_GATE: FAIL (headless not green — ./tools/ci/run_all_combat_checks.sh)"
	fi
	if [[ $dry -eq 1 ]]; then
		f5_restore_human_paste_if_clobbered "$ROOT" || true
		f5_ensure_validation_fresh "$ROOT" || true
		mapfile -t plan < <(f5_gap_merge_plan "$ROOT" "$ROOT/.f5_soak_validation.txt")
		print_plan "${plan[@]}"
		exit 0
	fi
	bash "$HERE/run_playtest.sh" merge --skip-revalidate
	local rev=()
	[[ $human -eq 1 ]] && rev+=(--human-signoff)
	bash "$HERE/run_playtest.sh" revalidate "${rev[@]}"
	[[ $skip_exp0 -eq 1 ]] && exit 0
	bash "$HERE/run_playtest.sh" exp0 --skip-closeout
	echo "PLAYTEST_FULL_GATE: PASS"
}

cmd_exp0() {
	local skip_close=0
	[[ "${1:-}" == "--skip-closeout" ]] && skip_close=1
	local phase0="$ROOT/.phase0_combat_checks.txt"
	if ! { [[ -f "$phase0" ]] && grep -q '^PHASE0: PASS' "$phase0" && grep -q '^CAMPAIGN_SHIP_AUDIT: PASS' "$phase0"; }; then
		fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (run ./tools/ci/run_all_combat_checks.sh first)"
	fi
	echo "=== Exp-0.2 Playtest gate ==="
	bash "$HERE/validate_camp_optional_smokes.sh" || fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"
	[[ $skip_close -eq 1 ]] && { echo "EXP_0_2_PLAYTEST_GATE: PASS (smokes only)"; exit 0; }
	bash "$HERE/run_camp_f5_closeout.sh" --human-signoff --skip-revalidate \
		|| fp_die "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"
	echo "EXP_0_2_PLAYTEST_GATE: PASS"
}

cmd_rebuild() {
	local baseline skip_pf=0 human=0 dry=0
	baseline="$(fp_abs "${1:-followup.log}")"
	shift || true
	for arg in "$@"; do
		case "$arg" in
			--skip-preflight) skip_pf=1 ;;
			--human-signoff) human=1 ;;
			--dry-run) dry=1 ;;
		esac
	done
	[[ -f "$baseline" ]] || fp_die "REBUILD_F5_MAINTAINED: FAIL (missing $baseline)" 2
	echo "=== Rebuild maintained F5 paste ==="
	echo "Baseline: $baseline"
	[[ $dry -eq 1 ]] && { echo "  replace + merge gaps"; exit 0; }
	[[ $skip_pf -eq 1 ]] || bash "$HERE/preflight_f5_followup.sh" "$baseline"
	bash "$HERE/append_f5_soak_log.sh" "$baseline" --replace --label camp5_baseline --skip-preflight \
		|| fp_die "REBUILD_F5_MAINTAINED: FAIL (baseline)"
	local merge=()
	[[ $human -eq 1 ]] && merge+=(--human-signoff)
	bash "$HERE/run_playtest.sh" merge "${merge[@]}" || fp_die "REBUILD_F5_MAINTAINED: FAIL (merge)"
	echo "REBUILD_F5_MAINTAINED: PASS"
}

case "$CMD" in
	status) cmd_status "$@" ;;
	merge|merge-gaps) cmd_merge "$@" ;;
	revalidate) cmd_revalidate "$@" ;;
	recover) cmd_recover "$@" ;;
	after-append|after_append) cmd_after_append "$@" ;;
	full|full-gate) cmd_full "$@" ;;
	exp0|exp0-gate) cmd_exp0 "$@" ;;
	rebuild) cmd_rebuild "$@" ;;
	validate) cmd_validate "$@" ;;
	append) cmd_append "$@" ;;
	preflight) cmd_preflight "$@" ;;
	closeout) cmd_closeout "$@" ;;
	restore) cmd_restore "$@" ;;
	*) fp_die "Unknown command: $CMD ($USAGE)" 2 ;;
esac
