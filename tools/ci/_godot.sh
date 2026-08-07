# Source from tools/ci/*.sh — do not execute directly.
# shellcheck shell=bash
fp_project_root() {
	# tools/ci → repo root (two levels up). Prefer locating project.godot when nested differently.
	local here root
	here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	root="$(cd "$here/../.." && pwd)"
	if [[ -f "$root/project.godot" ]]; then
		echo "$root"
		return 0
	fi
	(cd "$here/.." && pwd)
}

# Godot 4.x resolution (cross-platform):
#   1. $GODOT
#   2. godot4 / godot on PATH
#   3. Steam "Godot Engine" under common library roots (Fedora/Linux)
#   4. Flathub org.godotengine.Godot via tools/ci/godot_via_flatpak.sh
#   5. macOS app bundle
#   6. E:\Godot_v4.7-stable_win64.exe (Windows teammates / WSL)
fp_godot_bin() {
	if [[ -n "${GODOT:-}" ]]; then
		echo "$GODOT"
		return 0
	fi
	local c
	for c in godot4 godot; do
		if command -v "$c" >/dev/null 2>&1; then
			command -v "$c"
			return 0
		fi
	done
	local steam_root d cand
	for steam_root in \
		"${HOME}/.local/share/Steam/steamapps/common" \
		"${HOME}/.steam/steam/steamapps/common" \
		"${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common"
	do
		[[ -d "$steam_root" ]] || continue
		for d in "$steam_root"/Godot*; do
			[[ -d "$d" ]] || continue
			for cand in "$d"/Godot* "$d"/godot*; do
				[[ -f "$cand" && -x "$cand" ]] || continue
				echo "$cand"
				return 0
			done
		done
	done
	local shim
	shim="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/godot_via_flatpak.sh"
	if [[ -x "$shim" ]] && command -v flatpak >/dev/null 2>&1 \
		&& flatpak info org.godotengine.Godot >/dev/null 2>&1; then
		echo "$shim"
		return 0
	fi
	if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
		echo "/Applications/Godot.app/Contents/MacOS/Godot"
		return 0
	fi
	if [[ -x "E:/Godot_v4.7-stable_win64.exe" ]]; then
		echo "E:/Godot_v4.7-stable_win64.exe"
		return 0
	fi
	if [[ -x "E:\\Godot_v4.7-stable_win64.exe" ]]; then
		echo "E:\\Godot_v4.7-stable_win64.exe"
		return 0
	fi
	return 1
}

fp_godot_import_warmup() {
	local root="$1"
	# Callers that already ran `--import` once (full/fast phase0 gate) skip the
	# redundant re-import + settle sleep; each warmup costs ~7s import + 2s sleep.
	if [[ "${FP_SKIP_IMPORT_WARMUP:-0}" == "1" ]]; then
		return 0
	fi
	local godot
	godot="$(fp_godot_bin)" || return 1
	"$godot" --headless --path "$root" --import >/dev/null 2>&1 || true
	sleep 2
}
