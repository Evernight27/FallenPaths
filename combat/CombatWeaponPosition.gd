class_name CombatWeaponPosition
extends RefCounted

## Defender blade reach for passive parry capacity (near body vs extended). See **`TACTICAL_FORMATIONS_FF4`** Part 4b.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")


## True when the combatant's weapon is in a guard/near-body posture (full parry capacity).
static func is_weapon_near_body(combatant: Dictionary) -> bool:
	if combatant.is_empty():
		return true
	var st: String = _EntityAccess.state_str(combatant)
	if st == CombatConstants.STATE_WAITING:
		return true
	if st == CombatConstants.STATE_WIND_UP:
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(combatant, "pending_attack")
		if pa.is_empty():
			return true
		var wind_up: float = float(pa.get("wind_up_duration", combatant.get("state_duration", 0.5)))
		if wind_up <= 0.001:
			return true
		var timer: float = float(combatant.get("state_timer", 0.0))
		var commit_frac: float = _commit_fraction_for_weapon_extension(pa)
		if timer >= wind_up * commit_frac:
			return false
		return true
	if st == CombatConstants.STATE_RECOVERING:
		var cause: String = str(combatant.get("recovery_cause", ""))
		if cause == "parry_deflect" or cause == "parry_partial":
			return true
		if cause.begins_with("parry"):
			return true
		var last_move: String = str(combatant.get("last_move_id", "")).strip_edges()
		if last_move.is_empty():
			return true
		return false
	return true


static func commit_fraction_from_move_def(move_def: Dictionary) -> float:
	if move_def.is_empty():
		return CombatConstants.WEAPON_EXTENDED_COMMIT_FRACTION
	var from_move: float = float(move_def.get("weapon_extension_commit_fraction", -1.0))
	if from_move >= 0.0:
		return clampf(from_move, 0.0, 1.0)
	var contact_type: String = str(move_def.get("contact_type", "")).strip_edges()
	var arch_id: String = str(move_def.get("archetype_id", "")).strip_edges()
	if contact_type == _WeaponConstants.ATTACK_TYPE_STAB:
		return CombatConstants.WEAPON_COMMIT_FRACTION_STAB
	if contact_type == _WeaponConstants.ATTACK_TYPE_BLUNT:
		return CombatConstants.WEAPON_COMMIT_FRACTION_BLUNT
	if arch_id == _WeaponConstants.ARCHETYPE_OVERHEAD:
		return CombatConstants.WEAPON_COMMIT_FRACTION_OVERHEAD
	if arch_id == _WeaponConstants.ARCHETYPE_QUICK_SLASH:
		return CombatConstants.WEAPON_COMMIT_FRACTION_QUICK
	if contact_type == _WeaponConstants.ATTACK_TYPE_CUT:
		return CombatConstants.WEAPON_COMMIT_FRACTION_CUT
	return CombatConstants.WEAPON_EXTENDED_COMMIT_FRACTION


static func _commit_fraction_for_weapon_extension(pa: Dictionary) -> float:
	if pa.has("weapon_extension_commit_fraction"):
		return clampf(float(pa["weapon_extension_commit_fraction"]), 0.0, 1.0)
	var mid: String = str(pa.get("attack_type", "")).strip_edges()
	if not mid.is_empty():
		return commit_fraction_from_move_def(_WeaponConstants.get_move(mid))
	return CombatConstants.WEAPON_EXTENDED_COMMIT_FRACTION


## Multiplier on defender **`parry_c_d`** when the blade is extended (recovering from own attack, etc.).
static func parry_capacity_mult_for_defender(defender: Dictionary) -> float:
	if is_weapon_near_body(defender):
		return 1.0
	return CombatConstants.WEAPON_EXTENDED_PARRY_MULT


## Multiplier on defender **`parry_c_d`** when the incoming attacker has committed (wind-up past commit point).
static func incoming_attack_parry_c_d_mult(attacker: Dictionary) -> float:
	if attacker.is_empty() or is_weapon_near_body(attacker):
		return 1.0
	return CombatConstants.WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT
