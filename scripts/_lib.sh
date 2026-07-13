#!/usr/bin/env bash
# Source-only bootstrap for scripts/*.sh.
# shellcheck shell=bash
_FP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_godot.sh
source "$_FP_LIB_DIR/_godot.sh"
# shellcheck source=f5_soak_log_helpers.sh
source "$_FP_LIB_DIR/f5_soak_log_helpers.sh"

fp_root() { fp_project_root; }
fp_die() { echo "$*" >&2; exit "${2:-1}"; }

fp_abs() {
	local p="$1"
	[[ "$p" == /* ]] && { echo "$p"; return; }
	echo "$(fp_root)/$p"
}
