#!/usr/bin/env bash
# Restore human F5 paste from .f5_soak_in.f5_backup.txt and re-validate.
set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ROOT="$(fp_root)"
BAK="$(f5_soak_backup_path "$ROOT")"
[[ -f "$BAK" ]] || fp_die "No backup at $BAK" 1
f5_is_example_smoke "$BAK" && echo "WARN: backup is docs example smoke" >&2
f5_restore_human_paste "$ROOT"
exec bash "$(dirname "$0")/validate_f5_soak_log.sh"
