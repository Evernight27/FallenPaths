extends SceneTree

## Headless probe: current-state KE + pre-armor cut/blunt for each weapon template at several
## intensities and commitments. Run with:
##   Godot --headless --path . -s res://tools/combat_tuning/probe_physics.gd
## Output mirrors the real-combat damage chain (AttackResolver) but skips stamina/closing/windup.

const _Weapon := preload("res://resources/weapons/Weapon.gd")
const _WeaponDamageHelper := preload("res://resources/weapons/WeaponDamageHelper.gd")
const _AttackInstance := preload("res://resources/weapons/AttackInstance.gd")
const _ImpactVelocityModel := preload("res://resources/weapons/ImpactVelocityModel.gd")

const WEAPONS := ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
const MOVES := {"SWORD": "oberhau", "AXE": "diagonal_chop", "MACE": "overhead_strike", "DAGGER": "quick_thrust", "SPEAR": "spear_thrust"}
const INTENSITIES := [0.4, 0.6, 0.8, 1.0]
const COMMITS := [0.4, 0.6, 0.8, 1.0]


func _init() -> void:
	var _WeaponConstants := load("res://resources/weapons/WeaponConstants.gd")
	var out := PackedStringArray()
	out.append("PROBE_PHYSICS current-state DAMAGE_KE_SCALE=%.1f" % float(_WeaponConstants.DAMAGE_KE_SCALE))
	out.append("weapon,move,intensity,commit,v_m_s,KE_J,pre_cut,pre_blunt")
	for wid in WEAPONS:
		var weapon = _Weapon.create_from_definition(wid)
		var move: String = MOVES[wid]
		var arch: Dictionary = {}
		var md: Variant = _WeaponConstants.get_move(move) if _WeaponConstants.has_method("get_move") else null
		if md is Dictionary:
			arch = md.get("archetype", {}) if md.get("archetype") is Dictionary else {}
		for intensity in INTENSITIES:
			for commit in COMMITS:
				var eff_i: float = _WeaponDamageHelper.effective_intensity_for_delivery(intensity, commit)
				var v_base: float = _WeaponDamageHelper.velocity_m_s_from_intensity(eff_i, arch, weapon, move)
				var ai = _AttackInstance.new(move, intensity)
				ai.archetype = arch
				ai.delivery_commit_fraction = commit
				ai.velocity_m_s = v_base
				var ke_j: float = _WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
				var pre_cut: float = _WeaponDamageHelper.compute_pre_armor_cut(weapon, ai, 100.0, 1.0)
				var pre_blunt: float = _WeaponDamageHelper.compute_blunt_slip_pre_armor(
					weapon, ai, 100.0, 1.0, 1.0, 21.0, 1.0
				)
				out.append("%s,%s,%.1f,%.1f,%.2f,%.1f,%.2f,%.2f" % [wid, move, intensity, commit, v_base, ke_j, pre_cut, pre_blunt])
	for line in out:
		print(line)
	quit(0)
