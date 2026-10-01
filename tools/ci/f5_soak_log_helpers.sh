#!/usr/bin/env bash
# Shared F5 paste helpers — source from tools/ci/*.sh (do not execute).
# shellcheck shell=bash

f5_soak_log_path() { echo "$1/.f5_soak_in.txt"; }
f5_soak_backup_path() { echo "$1/.f5_soak_in.f5_backup.txt"; }
f5_camp_smokes_batch_path() { echo "$1/.f5_camp_smokes_batch.txt"; }
f5_append_separator() {
    local label="${1:-}"
    [[ -n "$label" ]] && echo "--- f5_soak_append: $label ---" || echo "--- f5_soak_append ---"
}

f5_mtime() {
    local f="$1"
    [[ -f "$f" ]] || { echo 0; return; }
    if stat -c %Y "$f" >/dev/null 2>&1; then stat -c %Y "$f"
    elif stat -f %m "$f" >/dev/null 2>&1; then stat -f %m "$f"
    else echo 0
    fi
}

f5_validation_report_stamp() { f5_mtime "${1:-}"; }

f5_is_example_smoke() {
    local log="$1"
    [[ -f "$log" ]] || return 1
    head -n8 "$log" | grep -qE '^# (Merged Camp|Minimal Camp).*sample|^# .*not one real session|^# .*Copy smoke:' && return 0
    return 1
}

f5_is_headless_capture_only() {
    local log="$1"
    [[ -f "$log" ]] || return 1
    grep -qE '^FP_WORLD:' "$log" 2>/dev/null && return 1
    grep -qE '^--- f5_soak_append' "$log" 2>/dev/null && return 1
    grep -q '^FP_SESSION_BEGIN: headless d001 capture' "$log" 2>/dev/null
}

f5_looks_human_paste() {
    local log="$1" size gauges
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

f5_has_step9_append() {
    [[ -f "$1" ]] && grep -qE '^--- f5_soak_append: camp5_step9' "$1" 2>/dev/null
}

f5_should_preserve() {
    local root="$1" log
    log="$(f5_soak_log_path "$root")"
    [[ -f "$log" ]] || return 1
    f5_is_example_smoke "$log" && return 1
    f5_is_headless_capture_only "$log" && return 1
    grep -qE '^FP_WORLD:|^--- f5_soak_append' "$log" 2>/dev/null && return 0
    f5_looks_human_paste "$log"
}

f5_backup_human_paste() {
    local root="$1" log bak src_len bak_len
    log="$(f5_soak_log_path "$root")"
    bak="$(f5_soak_backup_path "$root")"
    f5_should_preserve "$root" || return 1
    [[ -f "$bak" ]] && f5_is_example_smoke "$log" && return 1
    if [[ -f "$bak" ]] && f5_should_preserve "$bak"; then
        src_len=$(wc -c <"$log" | tr -d ' ')
        bak_len=$(wc -c <"$bak" | tr -d ' ')
        if f5_has_step9_append "$bak" && ! f5_has_step9_append "$log" && [[ "$src_len" -le "$bak_len" ]]; then
            echo "Keeping step-9 backup ($bak_len bytes) — current paste ($src_len bytes) missing camp5_step9 append"
            return 0
        fi
    fi
    cp "$log" "$bak"
    echo "Backed up F5 paste -> $bak"
}

f5_restore_human_paste() {
    local root="$1" log bak
    log="$(f5_soak_log_path "$root")"
    bak="$(f5_soak_backup_path "$root")"
    [[ -f "$bak" ]] || return 1
    cp "$bak" "$log"
    echo "Restored F5 paste from $bak"
}

# Restore backup when live paste is headless D001 capture.
f5_restore_human_paste_if_clobbered() {
    local root="$1" log bak
    log="$(f5_soak_log_path "$root")"
    bak="$(f5_soak_backup_path "$root")"
    [[ -f "$log" ]] && f5_is_headless_capture_only "$log" || return 1
    [[ -f "$bak" ]] || return 1
    f5_is_example_smoke "$bak" && return 1
    f5_restore_human_paste "$root"
}

f5_is_fatal_error_hint_line() {
    local line="$1"
    [[ "$line" =~ ^(FP_COMBAT:[[:space:]]*)?soak_(guide|session_plan|validate_hint|coverage)[[:space:]] ]] && return 0
    [[ "$line" =~ grep[[:space:]]+(FP_ERROR|SCRIPT) ]] && return 0
    [[ "$line" =~ ^FP_SESSION_(BEGIN|END): ]] && return 0
    return 1
}

f5_has_fatal_errors() {
    local log="$1" line
    [[ -f "$log" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        f5_is_fatal_error_hint_line "$line" && continue
        [[ "$line" =~ ^(FP_ERROR:|SCRIPT[[:space:]]ERROR:|ERROR:|SHADER[[:space:]]ERROR:) ]] && return 0
    done <"$log"
    return 1
}

f5_human_signoff_status() {
    local log="$1"
    [[ -f "$log" ]] || { echo "NOT READY"; return; }
    f5_looks_human_paste "$log" && { echo "READY"; return; }
    f5_is_example_smoke "$log" && { echo "SMOKE ONLY"; return; }
    f5_is_headless_capture_only "$log" && { echo "NOT READY (headless capture)"; return; }
    echo "NOT READY"
}

f5_show_status_hint() {
    local root="$1" log
    log="$(f5_soak_log_path "$root")"
    [[ -f "$log" ]] || return 0
    if f5_is_example_smoke "$log"; then
        echo "NOTE: .f5_soak_in.txt is docs example smoke - paste real F5 Output"
    elif f5_is_headless_capture_only "$log"; then
        echo "NOTE: .f5_soak_in.txt is headless D001 capture - ./tools/ci/restore_f5_soak_log.sh"
    elif f5_has_fatal_errors "$log"; then
        echo "NOTE: FP_ERROR or SCRIPT_ERROR in .f5_soak_in.txt"
    fi
}

f5_validator_track_status() {
    local val="$1" id="$2" line
    [[ -f "$val" ]] || { echo "missing"; return; }
    line="$(grep -E "^\[$id\] " "$val" 2>/dev/null | tail -n1 || true)"
    [[ -n "$line" ]] || { echo "missing"; return; }
    [[ "$line" == *"] PASS"* ]] && { echo "pass"; return; }
    [[ "$line" == *"] OPTIONAL_MISS"* ]] && { echo "optional_miss"; return; }
    [[ "$line" == *"] FAIL"* ]] && { echo "fail"; return; }
    echo "missing"
}

f5_exp02_optional_track_ids() {
    echo "camp_field_care_action camp_paid_loss camp_wage_warn camp_desertion camp_party_triage"
}

f5_exp02_optional_tracks_pass() {
    local val="$1" id
    local -a ids=(camp_field_care_action camp_paid_loss camp_wage_warn camp_desertion camp_party_triage)
    [[ -f "$val" ]] || return 1
    for id in "${ids[@]}"; do
        [[ "$(f5_validator_track_status "$val" "$id")" == "pass" ]] || return 1
    done
}

f5_validation_fresh() {
    local root="$1" log val
    log="$(f5_soak_log_path "$root")"
    val="$root/.f5_soak_validation.txt"
    [[ -f "$log" && -f "$val" ]] || return 1
    grep -q '^ok=true' "$val" 2>/dev/null || return 1
    grep -q '^--- END FP_F5_SOAK_VALIDATION ---' "$val" 2>/dev/null || return 1
    [[ "$(f5_mtime "$val")" -ge "$(f5_mtime "$log")" ]]
}

f5_wait_validation_report() {
    local val="${1:-}" not_before="${2:-0}" deadline=$((SECONDS + 45)) stamp
    [[ -n "$val" ]] || return 1
    while ((SECONDS < deadline)); do
        if [[ -f "$val" ]]; then
            stamp="$(f5_mtime "$val")"
            if [[ "$stamp" -gt "$not_before" ]] && grep -q '^--- END FP_F5_SOAK_VALIDATION ---' "$val" 2>/dev/null; then
                return 0
            fi
        fi
        sleep 0.05
    done
    return 1
}

f5_wait_camp_smokes_batch() {
    local batch="${1:-}" not_before="${2:-0}" deadline=$((SECONDS + 90)) stamp
    [[ -n "$batch" ]] || return 1
    while ((SECONDS < deadline)); do
        if [[ -f "$batch" ]]; then
            stamp="$(f5_mtime "$batch")"
            if [[ "$stamp" -gt "$not_before" ]] && grep -q '^--- END FP_F5_CAMP_SMOKES_BATCH ---' "$batch" 2>/dev/null; then
                return 0
            fi
        fi
        sleep 0.05
    done
    return 1
}

f5_stop_stuck_godot() { pkill -f "Godot" 2>/dev/null || true; }

f5_invoke_camp_smokes_batch() {
    local root="$1" godot batch code
    # Prefer already-loaded fp_godot_bin from _lib.sh / _godot.sh.
    if ! declare -F fp_godot_bin >/dev/null 2>&1; then
        # shellcheck source=_godot.sh
        source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_godot.sh"
    fi
    godot="$(fp_godot_bin)" || return 127
    batch="$(f5_camp_smokes_batch_path "$root")"
    rm -f "$batch"
    fp_godot_import_warmup "$root" || true
    export FP_HARNESS_MODE=f5_validate_camp_smokes
    fp_godot_run "$(fp_timeout_seconds)" "$godot" --headless --path "$root" -s res://tools/ci/run_all_combat_checks.gd
    code=$?
    unset FP_HARNESS_MODE
    [[ -f "$batch" ]] && grep -q '^--- END FP_F5_CAMP_SMOKES_BATCH ---' "$batch" 2>/dev/null && return "$code"
    [[ "$code" -ne 0 ]] && return "$code"
    return 2
}

f5_show_validation_track_summary() {
    local val="$1" include_meta="${2:-0}"
    [[ -f "$val" ]] || return 0
    [[ "$include_meta" -eq 1 ]] && grep -E '^(ok=|profiles=)' "$val" 2>/dev/null || true
    grep -E '^\[(camp_|wf_m3_)' "$val" 2>/dev/null || true
}

# Re-run validate_f5_soak_log.sh when report is missing/stale.
f5_ensure_validation_fresh() {
    local root="$1" force="${2:-0}" scripts
    scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ "$force" -eq 0 ]] && f5_validation_fresh "$root"; then
        return 0
    fi
    bash "$tools/ci/validate_f5_soak_log.sh" --quiet || return $?
    f5_validation_fresh "$root"
}

# Alias used by playtest revalidate.
f5_revalidate_human_paste() { f5_ensure_validation_fresh "$1" 1; }

# Append chunk into .f5_soak_in.txt (replace or labeled separator).
f5_append_chunk() {
    local root="$1" src="$2" label="${3:-}" replace="${4:-0}" dest sep
    dest="$(f5_soak_log_path "$root")"
    [[ -f "$src" ]] || return 2
    if [[ "$replace" -eq 1 || ! -f "$dest" ]]; then
        cp "$src" "$dest"
        echo "Wrote $dest ($(wc -c <"$dest" | tr -d ' ') bytes)"
    else
        sep="$(f5_append_separator "$label")"
        { printf '\n%s\n' "$sep"; cat "$src"; [[ "$(tail -c1 "$src")" == $'\n' ]] || printf '\n'; } >>"$dest"
        echo "Appended to $dest ($(wc -c <"$dest" | tr -d ' ') bytes)"
        [[ -n "$label" ]] && echo "Append label: $label"
    fi
}

# Preflight patterns: label#regex#required(0|1)
f5_preflight_patterns() {
    if [[ "${1:-}" == "step9" ]]; then
        cat <<'EOF'
tutorial soft loss#company_run_end reason=tutorial_failed.*reload=false#0
wage warn#FP_WORLD: company_wages: gold=#0
desertion#desertion summary=#0
EOF
    else
        cat <<'EOF'
field care action#FP_WORLD: field_care (bandage|pressure) part=#1
party triage#FP_WORLD: party_triage_open living=#1
paid loss#company_run_end reason=contract_failed.*reload=true#1
desertion or wage#desertion summary=|FP_WORLD: company_wages: gold=#0
EOF
    fi
}

f5_preflight_log() {
    local log="$1" mode="${2:-full}" label pat req hits=0 miss=0
    [[ -f "$log" ]] || return 2
    f5_has_fatal_errors "$log" && return 1
    while IFS='#' read -r label pat req; do
        [[ -n "$label" ]] || continue
        if grep -qE "$pat" "$log" 2>/dev/null; then
            echo "  [OK] $label"
            hits=$((hits + 1))
        elif [[ "$req" == "1" ]]; then
            echo "  [MISS] $label (required)"
            miss=$((miss + 1))
        else
            echo "  [opt] $label (optional)"
        fi
    done < <(f5_preflight_patterns "$mode")
    if [[ "$mode" == "step9" ]]; then
        [[ "$hits" -ge 1 ]]
    else
        [[ "$miss" -eq 0 ]]
    fi
}

# Gap merge rows: track|label|relpath (smoke files for non-pass tracks).
f5_gap_merge_rows() {
    cat <<'EOF'
camp_mopup_strike_finish|camp_mopup_smoke|docs/camp_optional_step_smokes/step3e_mopup.txt
camp_field_care_action|camp_field_care_smoke|docs/camp_optional_step_smokes/step4_field_care_action.txt
camp_paid_loss|camp_paid_loss_smoke|docs/camp_optional_step_smokes/step8_paid_loss.txt
camp_tutorial_soft_loss|camp_tutorial_soft_smoke|docs/camp_optional_step_smokes/step8_tutorial_soft.txt
camp_wage_warn|camp_wage_warn_smoke|docs/camp_optional_step_smokes/step9_wage_warn.txt
camp_desertion|camp_desertion_smoke|docs/camp_optional_step_smokes/step9_desertion.txt
camp_party_triage|camp_party_triage_smoke|docs/camp_optional_step_smokes/step10_party_triage.txt
camp_medical_exit|camp_medical_exit_smoke|docs/camp_optional_step_smokes/medical_exit.txt
EOF
}

# Print plan lines track|label|abspath for missing/fail tracks.
f5_gap_merge_plan() {
    local root="$1" val="$2" track label rel st
    while IFS='|' read -r track label rel; do
        [[ -n "$track" ]] || continue
        st="$(f5_validator_track_status "$val" "$track")"
        [[ "$st" == "pass" ]] && continue
        echo "$track|$label|$root/$rel"
    done < <(f5_gap_merge_rows)
}

phase0_summary_commit() {
    local root="$1"
    local final tmp line
    final="$root/.phase0_combat_checks.txt"
    tmp="$final.tmp"
    shift
    : >"$tmp"
    for line in "$@"; do
        echo "$line" >>"$tmp"
    done
    mv -f "$tmp" "$final"
}
