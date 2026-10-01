#!/usr/bin/env bash
# Local / CI lint gate: shellcheck + gdlint + gdformat --check.
# Install gdtoolkit: pip install 'gdtoolkit==4.*'  (or use a venv).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== shellcheck ==="
shellcheck --rcfile=tools/ci/.shellcheckrc -x tools/ci/*.sh

echo "=== gdlint ==="
if ! command -v gdlint >/dev/null 2>&1; then
    echo "gdlint not found; pip install 'gdtoolkit==4.*'" >&2
    exit 127
fi
gdlint .

echo "=== gdformat --check ==="
if ! command -v gdformat >/dev/null 2>&1; then
    echo "gdformat not found; pip install 'gdtoolkit==4.*'" >&2
    exit 127
fi
gdformat --check .

echo "=== production vs combat_tuning quarantine ==="
# Uses grep (POSIX, always present) rather than rg: a missing rg used to make this
# check exit 127 and silently pass. Doc/line comments may legitimately mention the
# path; only real code references (preload/load/const paths) break the quarantine.
_quarantine_hits="$(grep -rnE --include='*.gd' \
    'tools/combat_tuning|res://tools/combat_tuning' combat world core ui \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
if [ -n "$_quarantine_hits" ]; then
    echo "FAIL: production packages must not reference tools/combat_tuning" >&2
    printf '%s\n' "$_quarantine_hits" >&2
    exit 1
fi
echo "OK: no production preload of combat_tuning"

echo "=== LINT: PASS ==="
