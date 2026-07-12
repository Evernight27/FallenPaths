#!/usr/bin/env bash
# Source-only shared bootstrap for scripts/*.sh (do not execute).
# shellcheck shell=bash
_FP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_godot.sh
source "$_FP_LIB_DIR/_godot.sh"
# shellcheck source=f5_soak_log_helpers.sh
source "$_FP_LIB_DIR/f5_soak_log_helpers.sh"

fp_root() { fp_project_root; }

fp_die() { echo "$*" >&2; exit "${2:-1}"; }

# Resolve path relative to repo root unless absolute.
fp_abs() {
	local p="$1" root
	root="$(fp_root)"
	[[ "$p" == /* ]] && { echo "$p"; return; }
	echo "$root/$p"
}

# Prefer pwsh, then powershell (Windows / Wine). Returns 0 if found.
fp_pwsh() {
	if command -v pwsh >/dev/null 2>&1; then
		echo pwsh
		return 0
	fi
	if command -v powershell >/dev/null 2>&1; then
		echo powershell
		return 0
	fi
	return 1
}

# Invoke a sibling .ps1 when native bash path is unavailable.
fp_invoke_ps1() {
	local script="$1"
	shift
	local exe
	exe="$(fp_pwsh)" || fp_die "Need pwsh/powershell for $script (or use the .sh twin)" 127
	"$exe" -NoProfile -ExecutionPolicy Bypass -File "$_FP_LIB_DIR/$script" "$@"
}
