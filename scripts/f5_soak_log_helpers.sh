#!/usr/bin/env bash
# Shared F5 paste backup/restore (source from run_all_combat_checks.sh only).
f5_soak_log_path() { echo "$1/.f5_soak_in.txt"; }
f5_soak_backup_path() { echo "$1/.f5_soak_in.f5_backup.txt"; }

f5_should_preserve() {
	local root="$1"
	local log
	log="$(f5_soak_log_path "$root")"
	[[ -f "$log" ]] || return 1
	f5_is_example_smoke "$log" && return 1
	f5_is_headless_capture_only "$log" && return 1
	grep -qE '^FP_WORLD:' "$log" 2>/dev/null && return 0
	grep -qE '^--- f5_soak_append' "$log" 2>/dev/null && return 0
	f5_looks_human_paste "$log" && return 0
	return 1
}

f5_has_step9_append() {
	local log="$1"
	[[ -f "$log" ]] && grep -qE '^--- f5_soak_append: camp5_step9' "$log" 2>/dev/null
}

f5_backup_human_paste() {
	local root="$1"
	local log bak src_len bak_len
	log="$(f5_soak_log_path "$root")"
	bak="$(f5_soak_backup_path "$root")"
	if ! f5_should_preserve "$root"; then
		return 1
	fi
	if [[ -f "$bak" ]] && f5_is_example_smoke "$log"; then
		return 1
	fi
	if [[ -f "$bak" ]] && f5_should_preserve "$bak"; then
		src_len=$(wc -c <"$log" | tr -d ' ')
		bak_len=$(wc -c <"$bak" | tr -d ' ')
		if f5_has_step9_append "$bak" && ! f5_has_step9_append "$log" && [[ "$src_len" -le "$bak_len" ]]; then
			echo "Keeping step-9 backup ($bak_len bytes) — current paste ($src_len bytes) missing camp5_step9 append"
			return 0
		fi
	fi
	cp "$log" "$bak"
	echo "Backed up F5 paste -> $bak (Phase 0 overwrites .f5_soak_in.txt with headless D001 capture)"
	return 0
}

f5_restore_human_paste() {
	local root="$1"
	local log bak
	log="$(f5_soak_log_path "$root")"
	bak="$(f5_soak_backup_path "$root")"
	if [[ -f "$bak" ]]; then
		cp "$bak" "$log"
		echo "Restored F5 paste from $bak"
		return 0
	fi
	return 1
}

f5_is_fatal_error_hint_line() {
	local line="$1"
	[[ "$line" =~ ^(FP_COMBAT:[[:space:]]*)?soak_guide[[:space:]] ]] && return 0
	[[ "$line" =~ ^(FP_COMBAT:[[:space:]]*)?soak_session_plan[[:space:]] ]] && return 0
	[[ "$line" =~ ^(FP_COMBAT:[[:space:]]*)?soak_validate_hint[[:space:]] ]] && return 0
	[[ "$line" =~ ^(FP_COMBAT:[[:space:]]*)?soak_coverage[[:space:]] ]] && return 0
	[[ "$line" =~ grep[[:space:]]+(FP_ERROR|SCRIPT) ]] && return 0
	[[ "$line" =~ ^FP_SESSION_BEGIN: ]] && return 0
	[[ "$line" =~ ^FP_SESSION_END: ]] && return 0
	return 1
}

f5_has_fatal_errors() {
	local log="$1"
	[[ -f "$log" ]] || return 1
	local line
	while IFS= read -r line || [[ -n "$line" ]]; do
		if f5_is_fatal_error_hint_line "$line"; then
			continue
		fi
		if [[ "$line" =~ ^FP_ERROR: ]] \
			|| [[ "$line" =~ ^SCRIPT[[:space:]]ERROR: ]] \
			|| [[ "$line" =~ ^ERROR: ]] \
			|| [[ "$line" =~ ^SHADER[[:space:]]ERROR: ]]; then
			return 0
		fi
	done < "$log"
	return 1
}

f5_exp02_optional_track_ids() {
	echo "camp_field_care_action camp_paid_loss camp_wage_warn camp_desertion camp_party_triage"
}

f5_exp02_optional_tracks_pass() {
	local val="$1" id status
	[[ -f "$val" ]] || return 1
	for id in $(f5_exp02_optional_track_ids); do
		status="$(f5_validator_track_status "$val" "$id")"
		[[ "$status" == "pass" ]] || return 1
	done
	return 0
}

f5_human_signoff_status() {
	local log="$1"
	[[ -f "$log" ]] || { echo "NOT READY"; return; }
	if f5_looks_human_paste "$log"; then echo "READY"; return; fi
	if f5_is_example_smoke "$log"; then echo "SMOKE ONLY"; return; fi
	if f5_is_headless_capture_only "$log"; then echo "NOT READY (headless capture)"; return; fi
	echo "NOT READY"
}

f5_show_status_hint() {
	local root="$1"
	local log
	log="$(f5_soak_log_path "$root")"
	[[ -f "$log" ]] || return
	if f5_is_example_smoke "$log"; then
		echo "NOTE: .f5_soak_in.txt is docs example smoke - not Camp-5 human sign-off (paste real F5 Output)"
	elif f5_is_headless_capture_only "$log"; then
		echo "NOTE: .f5_soak_in.txt is headless D001 capture - paste F5 Output or: ./scripts/restore_f5_soak_log.sh"
	elif f5_has_fatal_errors "$log"; then
		echo "NOTE: FP_ERROR or SCRIPT_ERROR in .f5_soak_in.txt - fix before F5 validator merge"
	fi
}

f5_is_example_smoke() {
	local log="$1"
	[[ -f "$log" ]] || return 1
	head -n8 "$log" | grep -qE '^# (Merged Camp|Minimal Camp).*sample' && return 0
	head -n8 "$log" | grep -q 'not one real session' && return 0
	head -n8 "$log" | grep -q 'Copy smoke:' && return 0
	return 1
}

f5_is_headless_capture_only() {
	local log="$1"
	[[ -f "$log" ]] || return 1
	grep -qE '^FP_WORLD:' "$log" 2>/dev/null && return 1
	grep -qE '^--- f5_soak_append' "$log" 2>/dev/null && return 1
	grep -q '^FP_SESSION_BEGIN: headless d001 capture' "$log" 2>/dev/null
}

f5_validator_track_status() {
	local val="$1" id="$2"
	[[ -f "$val" ]] || { echo "missing"; return; }
	local line
	line="$(grep -E "^\[$id\] " "$val" 2>/dev/null | tail -n1 || true)"
	[[ -n "$line" ]] || { echo "missing"; return; }
	[[ "$line" == *"] PASS"* ]] && { echo "pass"; return; }
	[[ "$line" == *"] OPTIONAL_MISS"* ]] && { echo "optional_miss"; return; }
	[[ "$line" == *"] FAIL"* ]] && { echo "fail"; return; }
	echo "missing"
}

f5_validation_report_stamp() {
	local val="${1:-}"
	[[ -f "$val" ]] || { echo "0"; return; }
	# mtime seconds (portable enough for batch smoke waits)
	if stat -c %Y "$val" >/dev/null 2>&1; then
		stat -c %Y "$val"
	elif stat -f %m "$val" >/dev/null 2>&1; then
		stat -f %m "$val"
	else
		echo "0"
	fi
}

f5_wait_validation_report() {
	local val="${1:-}"
	local not_before="${2:-0}"
	local deadline=$((SECONDS + 15))
	local stamp
	[[ -n "$val" ]] || return 1
	while (( SECONDS < deadline )); do
		if [[ -f "$val" ]]; then
			stamp="$(f5_validation_report_stamp "$val")"
			if [[ "$stamp" -gt "$not_before" ]] && grep -q '^--- END FP_F5_SOAK_VALIDATION ---' "$val" 2>/dev/null; then
				return 0
			fi
		fi
		sleep 0.05
	done
	return 1
}

f5_show_validation_track_summary() {
	local val="$1"
	local include_meta="${2:-0}"
	[[ -f "$val" ]] || return 0
	if [[ "$include_meta" -eq 1 ]]; then
		grep -E '^(ok=|profiles=)' "$val" 2>/dev/null || true
	fi
	grep -E '^\[(camp_|wf_m3_)' "$val" 2>/dev/null || true
}

f5_looks_human_paste() {
	local log="$1"
	local size gauges
	[[ -f "$log" ]] || return 1
	f5_is_example_smoke "$log" && return 1
	f5_is_headless_capture_only "$log" && return 1
	size=$(wc -c <"$log" | tr -d ' ')
	[[ "$size" -gt 50000 ]] && return 0
	gauges=$(grep -cE '(^FP_COMBAT: )?turn_ready_gauge ' "$log" 2>/dev/null || true)
	[[ "${gauges:-0}" -ge 10 ]] && return 0
	grep -qE '^FP_WORLD:' "$log" 2>/dev/null \
		&& grep -q '^FP_SESSION_BEGIN:' "$log" 2>/dev/null \
		&& ! grep -q '^FP_SESSION_BEGIN: headless d001 capture' "$log" 2>/dev/null && return 0
	grep -qE '^--- f5_soak_append' "$log" 2>/dev/null \
		&& grep -qE '^FP_WORLD:' "$log" 2>/dev/null \
		&& [[ "${gauges:-0}" -ge 1 ]] && return 0
	return 1
}
