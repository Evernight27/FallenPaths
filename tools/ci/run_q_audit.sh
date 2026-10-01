#!/usr/bin/env bash
# Headless Q track audits (Camp-3.4 proxies; no F5 sign-off).
#   ./tools/ci/run_q_audit.sh Track|Q1|Q2
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127
TRACK="${1:-}"
case "$TRACK" in
    Track|Q1|Q2) ;;
    *) fp_die "Usage: $0 Track|Q1|Q2" 2 ;;
esac

echo "=== Q track audit ($TRACK) ==="
set +e
fp_godot_run "$(fp_timeout_seconds)" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_q_track_audits.gd
code=$?
set -e
[[ $code -eq 0 ]] || exit "$code"

Q_TRACK="$ROOT/.q_track_audits.txt"
[[ -f "$Q_TRACK" ]] || fp_die "Missing .q_track_audits.txt after Q track run"

extract_section() {
    local header="$1"
    awk -v hdr="$header" '
        $0 ~ hdr { p=1; print; next }
        p && /^\[Q/ { exit }
        p { print }
    ' "$Q_TRACK"
}

case "$TRACK" in
    Track)
        cat "$Q_TRACK"
        if grep -q 'BOUNDARY_FAIL' "$Q_TRACK"; then
            exit 1
        fi
        exit 0
        ;;
    Q1)
        mapfile -t section < <(extract_section '^\[Q1 ')
        [[ ${#section[@]} -gt 0 ]] || fp_die "Q1 section missing in .q_track_audits.txt"
        printf '%s\n' "${section[@]}" | tee "$ROOT/.q1_research_feel_audit.txt"
        if printf '%s\n' "${section[@]}" | grep -q 'BOUNDARY_FAIL'; then
            exit 1
        fi
        exit 0
        ;;
    Q2)
        mapfile -t section < <(extract_section '^\[Q2 ')
        [[ ${#section[@]} -gt 0 ]] || fp_die "Q2 section missing in .q_track_audits.txt"
        printf '%s\n' "${section[@]}" | tee "$ROOT/.q2_ii2b_feel_audit.txt"
        if printf '%s\n' "${section[@]}" | grep -q 'BOUNDARY_FAIL'; then
            exit 1
        fi
        exit 0
        ;;
esac
