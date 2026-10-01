#!/usr/bin/env bash
# Camp-1 + XCamp company loop checks. Exit 0 iff stdout contains FP_HARNESS_OK.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
GODOT_BIN="$(fp_godot_bin)" || fp_die "set GODOT to your Godot 4 binary" 127
fp_godot_import_warmup "$ROOT" || true
set +e
OUT="$(fp_godot_run "$(fp_timeout_seconds)" "$GODOT_BIN" --headless --path "$ROOT" -s res://tools/ci/run_company_state_checks.gd 2>&1)"
set -e
echo "$OUT"
echo "$OUT" | grep -q "FP_HARNESS_OK: CompanyStateChecks"
