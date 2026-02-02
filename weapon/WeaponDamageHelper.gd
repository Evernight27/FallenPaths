class_name WeaponDamageHelper
extends RefCounted

# --- Option C: Kinetic energy (J) drives both damage and penetration ---

# Effective impact velocity (m/s). Uses attack.velocity_m_s if >= 0, else derived from intensity and archetype.velocity_factor.
static func get_effective_velocity_m_s(_weapon: RefCounted, attack_instance: RefCounted) -> float:
	var v = attack_instance.get("velocity_m_s")
	if v is float and v >= 0.0:
		return v
	var i = attack_instance.get("intensity")
	var intensity_val: float = i if i is float else 0.5
	# factor in [0.5, 1.0]: low intensity = slower strike, high = full speed
	var factor: float = 0.5 + 0.5 * intensity_val
	var arch = attack_instance.get("archetype")
	if arch is Dictionary and arch.has("velocity_factor"):
		var vf: float = float(arch.velocity_factor)
		factor *= clampf(vf, 0.1, 1.5)
	return WeaponConstants.VELOCITY_MIN_M_S + (WeaponConstants.VELOCITY_MAX_M_S - WeaponConstants.VELOCITY_MIN_M_S) * clampf(factor, 0.0, 1.0)


# Kinetic energy (J) at impact: KE = ½ * mass_kg * velocity_m_s².
static func compute_kinetic_energy_j(weapon: RefCounted, attack_instance: RefCounted) -> float:
	if weapon == null:
		return 0.0
	var m = weapon.get("mass")
	var mass_kg: float = float(m) if (m is float or m is int) else WeaponConstants.BASELINE_MASS_KG
	var v: float = get_effective_velocity_m_s(weapon, attack_instance)
	return 0.5 * mass_kg * v * v


# Pre-armor damage from KE: scale * sqrt(KE) * strength_mod * arm_mod * contact_damage_factor, clamped to [MIN, MAX].
# Contact factor: smaller contact (stab) -> more local damage; capped by CONTACT_DAMAGE_FACTOR_MAX.
static func compute_pre_armor_damage(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var strength_mod: float = strength / 10.0
	strength_mod = maxf(0.1, strength_mod)
	var raw: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke_j)) * strength_mod * arm_mod
	var contact_cm: float = _get_contact_width_for_damage(weapon, attack_instance)
	contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
	var contact_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT)
	contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
	raw *= contact_factor
	return clampf(raw, WeaponConstants.DAMAGE_KE_MIN, WeaponConstants.DAMAGE_KE_MAX)


# Penetration (mm RHA sharp, MPa blunt). Physics: sharp uses contact area (smaller = deeper);
# blunt uses impact pressure = scale * KE / area (MPa).
# Returns { penetration_sharp, penetration_blunt }.
static func compute_penetration(weapon: RefCounted, attack_instance: RefCounted, damage_type: String) -> Dictionary:
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var attack_type: String = attack_instance.get("attack_type")
	if attack_type == null or not (attack_type is String):
		attack_type = WeaponConstants.ATTACK_TYPE_CUT

	if damage_type == WeaponConstants.DAMAGE_TYPE_SHARP:
		# Sharp: pen = (KE / J_PER_MM_RHA) * (baseline / contact_width)^α — smaller contact penetrates more.
		var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
		contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
		var area_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_AREA_EXPONENT)
		var pen_mm_rha: float = (ke_j / WeaponConstants.J_PER_MM_RHA) * area_factor
		pen_mm_rha = minf(pen_mm_rha, WeaponConstants.PENETRATION_KE_CAP_MM_RHA)
		var pen_mpa_deflect: float = pen_mm_rha * ArmorConstants.RHA_TO_MPA
		return { "penetration_sharp": pen_mm_rha, "penetration_blunt": pen_mpa_deflect }
	else:
		# Blunt: impact pressure (MPa) = scale * KE / A_m² / 1e6. A = π*(d/2)², d in m.
		var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
		var d_m: float = contact_cm / 100.0 if contact_cm > 0 else 0.01
		var A_m2: float = PI * (d_m / 2.0) * (d_m / 2.0)
		A_m2 = maxf(A_m2, WeaponConstants.MIN_BLUNT_AREA_M2)
		var pressure_Pa: float = WeaponConstants.BLUNT_PRESSURE_SCALE * ke_j / A_m2
		var pen_mpa: float = pressure_Pa / 1e6
		return { "penetration_sharp": 0.0, "penetration_blunt": pen_mpa }


# Damage type for this attack (SHARP or BLUNT).
static func get_damage_type(weapon: RefCounted, attack_type: String) -> String:
	return weapon.get_damage_type(attack_type)


# Contact width (cm) for attack type; used for area-based penetration.
static func _get_contact_width_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon == null:
		return WeaponConstants.BASELINE_CONTACT_CM
	if weapon is Object and (weapon as Object).has_method("get_contact_width"):
		var ret = (weapon as Object).get_contact_width(attack_type)
		if ret is float or ret is int:
			return float(ret)
	return WeaponConstants.BASELINE_CONTACT_CM


# Contact width for damage factor: archetype override or weapon default.
static func _get_contact_width_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
	var arch = attack_instance.get("archetype")
	if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
		return float(arch.contact_override_cm)
	var at = attack_instance.get("attack_type")
	if at is String:
		return _get_contact_width_cm(weapon, at)
	return WeaponConstants.BASELINE_CONTACT_CM


# Cut ratio 0.0–1.0 for this move (rest blunt). From archetype or weapon blade_cut_ratio; blunt moves use archetype or 0.
# attack_type is move_id; use weapon.get_damage_type(move_id) to detect blunt.
static func get_cut_ratio(weapon: RefCounted, attack_type: String, archetype_dict: Dictionary) -> float:
	if archetype_dict.has("cut_ratio"):
		var cr = archetype_dict.cut_ratio
		if cr >= 0.0:
			return clampf(float(cr), 0.0, 1.0)
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_damage_type"):
		if (weapon as Object).get_damage_type(attack_type) == WeaponConstants.DAMAGE_TYPE_BLUNT:
			return 0.0
	if weapon != null and "blade_cut_ratio" in weapon:
		return clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
	return 0.75
