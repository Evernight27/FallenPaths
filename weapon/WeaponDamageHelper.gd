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


# Pre-armor CUT (sharp) from KE and effective edge: scale * sqrt(KE) * strength_mod * arm_mod * contact_factor(effective sharp), clamped.
static func compute_pre_armor_cut(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var strength_mod: float = maxf(0.1, float(strength) / 10.0)
	var raw: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke_j)) * strength_mod * arm_mod
	var at: String = attack_instance.get("attack_type")
	if at == null or not (at is String):
		at = WeaponConstants.ATTACK_TYPE_CUT
	var contact_cm: float = _get_effective_sharp_contact_cm(weapon, at)
	contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
	var contact_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT)
	contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
	raw *= contact_factor
	return clampf(raw, WeaponConstants.DAMAGE_KE_MIN, WeaponConstants.DAMAGE_KE_MAX)


# Pre-armor BLUNT from momentum: scale * (mass * velocity) * strength_mod * arm_mod * contact_factor, clamped.
static func compute_pre_armor_blunt(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	if weapon == null:
		return 0.0
	var m = weapon.get("mass")
	var mass_kg: float = float(m) if (m is float or m is int) else WeaponConstants.BASELINE_MASS_KG
	var v: float = get_effective_velocity_m_s(weapon, attack_instance)
	var momentum: float = mass_kg * v
	var strength_mod: float = maxf(0.1, float(strength) / 10.0)
	var raw: float = WeaponConstants.DAMAGE_MOMENTUM_SCALE * momentum * strength_mod * arm_mod
	var contact_cm: float = _get_contact_width_for_damage(weapon, attack_instance)
	contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
	var contact_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT)
	contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
	raw *= contact_factor
	return clampf(raw, WeaponConstants.BLUNT_DAMAGE_MIN, WeaponConstants.BLUNT_DAMAGE_MAX)


# Pre-armor damage (legacy): cut from KE+edge * cut_ratio + blunt from momentum * (1-cut_ratio). Use compute_pre_armor_cut/blunt directly for physics split.
static func compute_pre_armor_damage(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	var cut: float = compute_pre_armor_cut(weapon, attack_instance, strength, arm_mod)
	var blunt: float = compute_pre_armor_blunt(weapon, attack_instance, strength, arm_mod)
	var at: String = attack_instance.get("attack_type")
	if at == null or not (at is String):
		at = WeaponConstants.ATTACK_TYPE_CUT
	var arch: Dictionary = attack_instance.get("archetype")
	if arch == null:
		arch = {}
	var cr: float = get_cut_ratio(weapon, at, arch)
	return cut * cr + blunt * (1.0 - cr)


# Penetration (mm RHA sharp, MPa blunt). Physics: sharp uses contact area (smaller = deeper);
# blunt uses impact pressure = scale * KE / area (MPa).
# Returns { penetration_sharp, penetration_blunt }.
static func compute_penetration(weapon: RefCounted, attack_instance: RefCounted, damage_type: String) -> Dictionary:
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var attack_type: String = attack_instance.get("attack_type")
	if attack_type == null or not (attack_type is String):
		attack_type = WeaponConstants.ATTACK_TYPE_CUT

	if damage_type == WeaponConstants.DAMAGE_TYPE_SHARP:
		# Sharp: pen = (KE / J_PER_MM_RHA) * (baseline / contact)^α. Contact = effective sharp (sharpness reduces effective width).
		var contact_cm: float = _get_effective_sharp_contact_cm(weapon, attack_type)
		contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
		var area_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_AREA_EXPONENT)
		var pen_mm_rha: float = (ke_j / WeaponConstants.J_PER_MM_RHA) * area_factor
		pen_mm_rha = minf(pen_mm_rha, WeaponConstants.PENETRATION_KE_CAP_MM_RHA)
		var pen_mpa_deflect: float = pen_mm_rha * ArmorConstants.RHA_TO_MPA
		return { "penetration_sharp": pen_mm_rha, "penetration_blunt": pen_mpa_deflect }
	else:
		# Blunt: rigid check = pressure (KE/area) MPa; cushion uses momentum/area (kg·m/s)/m² for Option B.
		var contact_cm: float = _get_blunt_contact_cm(weapon, attack_type)
		var d_m: float = contact_cm / 100.0 if contact_cm > 0 else 0.01
		var A_m2: float = PI * (d_m / 2.0) * (d_m / 2.0)
		A_m2 = maxf(A_m2, WeaponConstants.MIN_BLUNT_AREA_M2)
		var pressure_Pa: float = WeaponConstants.BLUNT_PRESSURE_SCALE * ke_j / A_m2
		var pen_mpa: float = pressure_Pa / 1e6
		var m = weapon.get("mass")
		var mass_kg: float = float(m) if (m is float or m is int) else WeaponConstants.BASELINE_MASS_KG
		var v: float = get_effective_velocity_m_s(weapon, attack_instance)
		var momentum: float = mass_kg * v
		var momentum_per_area: float = momentum / A_m2 if A_m2 > 0 else 0.0
		return { "penetration_sharp": 0.0, "penetration_blunt": pen_mpa, "penetration_blunt_momentum_per_area": momentum_per_area }


# Damage type for this attack (SHARP or BLUNT).
static func get_damage_type(weapon: RefCounted, attack_type: String) -> String:
	return weapon.get_damage_type(attack_type)


# Contact width (cm) for attack type; used for area-based penetration and pre-armor damage.
static func _get_contact_width_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon == null:
		return WeaponConstants.BASELINE_CONTACT_CM
	if weapon is Object and (weapon as Object).has_method("get_contact_width"):
		var ret = (weapon as Object).get_contact_width(attack_type)
		if ret is float or ret is int:
			return float(ret)
	return WeaponConstants.BASELINE_CONTACT_CM


# Sharp-component contact (cm): point, blade, or edge/flange. Used when effective sharp not available.
static func _get_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_sharp_contact_cm"):
		var ret = (weapon as Object).get_sharp_contact_cm(attack_type)
		if ret is float or ret is int:
			return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
	return maxf(_get_contact_width_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Effective sharp contact (cm): geometric sharp contact / sharpness factor. Sharper = smaller = higher penetration.
static func _get_effective_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_effective_sharp_contact_cm"):
		var ret = (weapon as Object).get_effective_sharp_contact_cm(attack_type)
		if ret is float or ret is int:
			return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
	return maxf(_get_sharp_contact_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Blunt-component contact (cm): head, shaft, or slap (cut uses BLUNT_CUT_MIN). Used for blunt penetration only.
static func _get_blunt_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_blunt_contact_cm"):
		var ret = (weapon as Object).get_blunt_contact_cm(attack_type)
		if ret is float or ret is int:
			return float(ret)
	var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
	if attack_type == WeaponConstants.ATTACK_TYPE_CUT:
		contact_cm = maxf(contact_cm, WeaponConstants.BLUNT_CUT_MIN_CONTACT_CM)
	return contact_cm


# Contact width for damage factor: archetype override or weapon default.
static func _get_contact_width_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
	var arch = attack_instance.get("archetype")
	if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
		return float(arch.contact_override_cm)
	var at = attack_instance.get("attack_type")
	if at is String:
		return _get_contact_width_cm(weapon, at)
	return WeaponConstants.BASELINE_CONTACT_CM


# Cut ratio 0.0–1.0 for this move (rest blunt). From archetype or weapon blade_cut_ratio.
# No weapon has 0% cutting: even maces can break skin (flanges/ridges); floor is MIN_CUT_RATIO.
static func get_cut_ratio(weapon: RefCounted, attack_type: String, archetype_dict: Dictionary) -> float:
	var cr: float = 0.75
	if archetype_dict.has("cut_ratio") and float(archetype_dict.cut_ratio) >= 0.0:
		cr = clampf(float(archetype_dict.cut_ratio), 0.0, 1.0)
	elif weapon != null and weapon is Object and (weapon as Object).has_method("get_damage_type"):
		if (weapon as Object).get_damage_type(attack_type) == WeaponConstants.DAMAGE_TYPE_BLUNT:
			cr = 0.0
		elif "blade_cut_ratio" in weapon:
			cr = clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
	elif weapon != null and "blade_cut_ratio" in weapon:
		cr = clampf(float(weapon.blade_cut_ratio), 0.0, 1.0)
	return maxf(cr, WeaponConstants.MIN_CUT_RATIO)
