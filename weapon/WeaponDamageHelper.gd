class_name WeaponDamageHelper
extends RefCounted

const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")

# --- Option C: Kinetic energy (J) drives both damage and penetration ---
# Impact speed: Tier A defaults + Tier B geometry + Tier C weapon.impact_velocity_bands; see ImpactVelocityModel.gd.

static func move_id_from_attack_instance(attack_instance: RefCounted) -> String:
	var v: Variant = attack_instance.get("attack_type")
	return str(v) if v is String else ""


static func _attack_float_or_default(attack_instance: RefCounted, prop: String, default_val: float) -> float:
	if attack_instance == null:
		return default_val
	var v: Variant = attack_instance.get(prop)
	if v is float or v is int:
		return float(v)
	return default_val


## Mass (kg) participating in impact speed for KE / momentum (striking part when known; aligns with parry p_a).
static func strike_mass_kg(weapon: RefCounted, attack_instance: RefCounted) -> float:
	if weapon == null:
		return 0.35
	var move_id: String = move_id_from_attack_instance(attack_instance)
	var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
	if weapon.has_method("get_striking_part_mass_kg"):
		return maxf(0.02, float(weapon.get_striking_part_mass_kg(ct)))
	var m: Variant = weapon.get("mass")
	return float(m) if (m is float or m is int) else WeaponConstants.BASELINE_MASS_KG


# Single place for intensity -> m/s. Factor in [0.5, 1.0]; archetype.velocity_factor scales it; band from weapon + move.
static func velocity_m_s_from_intensity(intensity: float, archetype: Dictionary, weapon: RefCounted = null, move_id: String = "") -> float:
	var int0: float = clampf(intensity, 0.0, 1.0)
	var curve: float = 1.0
	if archetype is Dictionary and archetype.has("velocity_intensity_curve"):
		curve = clampf(float(archetype.velocity_intensity_curve), 0.55, 1.5)
	var intensity_val: float = pow(int0, curve)
	var factor: float = 0.5 + 0.5 * intensity_val
	if archetype is Dictionary and archetype.has("velocity_factor"):
		var vf: float = float(archetype.velocity_factor)
		factor *= clampf(vf, 0.1, 1.5)
	var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
	var band: Vector2 = _ImpactVelocityModel.resolve_band_m_s(weapon, ct)
	return band.x + (band.y - band.x) * clampf(factor, 0.0, 1.0)


# Effective impact velocity (m/s). Prefer attack.velocity_m_s if set (e.g. after partial parry); else derive from intensity.
static func get_effective_velocity_m_s(weapon: RefCounted, attack_instance: RefCounted) -> float:
	var v = attack_instance.get("velocity_m_s")
	if v is float and v >= 0.0:
		return v
	var i = attack_instance.get("intensity")
	var arch = attack_instance.get("archetype")
	var move_id: String = move_id_from_attack_instance(attack_instance)
	return velocity_m_s_from_intensity(i if i is float else 0.5, arch if arch is Dictionary else {}, weapon, move_id)


# Kinetic energy (J) at impact: KE = ½ * strike_mass * velocity² (strike mass matches parry striking mass).
static func compute_kinetic_energy_j(weapon: RefCounted, attack_instance: RefCounted) -> float:
	if weapon == null:
		return 0.0
	var mass_kg: float = strike_mass_kg(weapon, attack_instance)
	var v: float = get_effective_velocity_m_s(weapon, attack_instance)
	var e_mult: float = _attack_float_or_default(attack_instance, "strike_energy_mult", 1.0)
	return 0.5 * mass_kg * v * v * maxf(0.05, e_mult)


# Pre-armor CUT (sharp) from KE and effective edge: scale * sqrt(KE) * strength_mod * arm_mod * contact_factor(effective sharp), clamped.
static func compute_pre_armor_cut(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var strength_mod: float = maxf(0.1, float(strength) / 100.0)
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
# Uses blunt contact (head_diameter for blunt, max(blade, BLUNT_CUT_MIN) for cut slap, point for thrust).
static func compute_pre_armor_blunt(weapon: RefCounted, attack_instance: RefCounted, strength: int, arm_mod: float) -> float:
	if weapon == null:
		return 0.0
	var mass_kg: float = strike_mass_kg(weapon, attack_instance)
	var v: float = get_effective_velocity_m_s(weapon, attack_instance)
	var p_mult: float = _attack_float_or_default(attack_instance, "strike_momentum_mult", 1.0)
	var momentum: float = mass_kg * v * maxf(0.05, p_mult)
	var strength_mod: float = maxf(0.1, float(strength) / 100.0)
	var raw: float = WeaponConstants.DAMAGE_MOMENTUM_SCALE * momentum * strength_mod * arm_mod
	var contact_cm: float = _get_blunt_contact_for_damage(weapon, attack_instance)
	contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
	var contact_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_DAMAGE_EXPONENT)
	contact_factor = minf(contact_factor, WeaponConstants.CONTACT_DAMAGE_FACTOR_MAX)
	raw *= contact_factor
	return clampf(raw, WeaponConstants.BLUNT_DAMAGE_MIN, WeaponConstants.BLUNT_DAMAGE_MAX)


# Penetration: sharp (mm RHA from contact area); blunt uses momentum_per_area for cushion.
# SHARP returns { penetration_sharp }. BLUNT returns { penetration_blunt_momentum_per_area, blunt_contact_cm }.
# opts: optional { "armor_resistance_rha_mm": float, "pen_sharp_mm": float } — when both provided for thrusts, use energy-based contact.
static func compute_penetration(weapon: RefCounted, attack_instance: RefCounted, damage_type: String, opts: Dictionary = {}) -> Dictionary:
	var armor_resistance_rha_mm: float = float(opts.get("armor_resistance_rha_mm", -1.0)) if opts is Dictionary else -1.0
	var pen_sharp_mm: float = float(opts.get("pen_sharp_mm", -1.0)) if opts is Dictionary else -1.0
	var ke_j: float = compute_kinetic_energy_j(weapon, attack_instance)
	var attack_type: String = attack_instance.get("attack_type")
	if attack_type == null or not (attack_type is String):
		attack_type = WeaponConstants.ATTACK_TYPE_CUT

	if damage_type == WeaponConstants.DAMAGE_TYPE_SHARP:
		# Sharp: Williams nonlinear — pen = (KE/J_BASE)^exp * area_factor. E ∝ t^1.67 → pen ∝ KE^0.6.
		var contact_cm: float = _get_effective_sharp_contact_cm(weapon, attack_type)
		contact_cm = maxf(contact_cm, WeaponConstants.MIN_CONTACT_WIDTH_CM)
		var area_factor: float = pow(WeaponConstants.BASELINE_CONTACT_CM / contact_cm, WeaponConstants.CONTACT_AREA_EXPONENT)
		var pen_mm_rha: float = pow(ke_j / WeaponConstants.J_PER_MM_BASE, WeaponConstants.PENETRATION_EXPONENT) * area_factor
		pen_mm_rha = minf(pen_mm_rha, WeaponConstants.PENETRATION_KE_CAP_MM_RHA)
		return { "penetration_sharp": pen_mm_rha }
	else:
		# Blunt: transmission-only. Returns momentum_per_area and contact_cm for area coupling.
		var contact_cm: float = _get_blunt_contact_for_penetration(weapon, attack_instance, armor_resistance_rha_mm, pen_sharp_mm)
		var momentum_per_area: float = _compute_blunt_momentum_per_area_with_contact(weapon, attack_instance, contact_cm)
		return { "penetration_blunt_momentum_per_area": momentum_per_area, "blunt_contact_cm": contact_cm }


# Blunt contact width (cm) for area-dependent transmission. Public for armor coupling.
static func get_blunt_contact_cm(weapon: RefCounted, attack_instance: RefCounted) -> float:
	if weapon == null:
		return -1.0
	var attack_type: String = attack_instance.get("attack_type")
	if attack_type == null or not (attack_type is String):
		attack_type = WeaponConstants.ATTACK_TYPE_CUT
	return _get_blunt_contact_cm(weapon, attack_type)


# Blunt contact for penetration: energy-based when armor_resistance_rha_mm and pen_sharp_mm provided (thrusts).
# depth_factor = clamp(pen/armor, 0, 1); effective = point + (head - point) * depth_factor.
static func _get_blunt_contact_for_penetration(weapon: RefCounted, attack_instance: RefCounted, armor_resistance_rha_mm: float = -1.0, pen_sharp_mm: float = -1.0) -> float:
	var attack_type: String = attack_instance.get("attack_type")
	if attack_type == null or not (attack_type is String):
		attack_type = WeaponConstants.ATTACK_TYPE_CUT
	var contact_pen: String = WeaponConstants.contact_type_for_move_id(attack_type)
	if contact_pen == WeaponConstants.ATTACK_TYPE_STAB and armor_resistance_rha_mm >= 0.0 and pen_sharp_mm >= 0.0 and weapon != null:
		var pw = weapon.get("point_width")
		var point: float = float(pw) if (pw is float or pw is int) else WeaponConstants.MIN_CONTACT_WIDTH_CM
		if point <= 0.0:
			point = WeaponConstants.MIN_CONTACT_WIDTH_CM
		var hw = weapon.get("thrust_head_width")
		var head: float = float(hw) if (hw is float or hw is int) else point
		if head <= 0.0:
			head = point
		var armor_rha: float = maxf(armor_resistance_rha_mm, 0.1)
		var depth_factor: float = clampf(pen_sharp_mm / armor_rha, 0.0, 1.0)
		return point + (head - point) * depth_factor
	return _get_blunt_contact_cm(weapon, attack_type)


# Blunt cushion: momentum per area (kg·m/s)/m². Used by armor for transmission absorption.
static func compute_blunt_momentum_per_area(weapon: RefCounted, attack_instance: RefCounted) -> float:
	var contact_cm: float = get_blunt_contact_cm(weapon, attack_instance)
	return _compute_blunt_momentum_per_area_with_contact(weapon, attack_instance, contact_cm) if contact_cm > 0 else -1.0


static func _compute_blunt_momentum_per_area_with_contact(weapon: RefCounted, attack_instance: RefCounted, contact_cm: float) -> float:
	if weapon == null or contact_cm <= 0.0:
		return -1.0
	var d_m: float = contact_cm / 100.0 if contact_cm > 0 else 0.01
	var A_m2: float = PI * (d_m / 2.0) * (d_m / 2.0)
	A_m2 = maxf(A_m2, WeaponConstants.MIN_BLUNT_AREA_M2)
	var mass_kg: float = strike_mass_kg(weapon, attack_instance)
	var v: float = get_effective_velocity_m_s(weapon, attack_instance)
	var p_mult: float = _attack_float_or_default(attack_instance, "strike_momentum_mult", 1.0)
	var momentum: float = mass_kg * v * maxf(0.05, p_mult)
	return momentum / A_m2 if A_m2 > 0 else 0.0


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
	if weapon != null:
		push_warning("[WeaponDamageHelper] Weapon lacks get_contact_width; using BASELINE_CONTACT_CM. Ensure weapon is Weapon instance from create_from_definition.")
	return WeaponConstants.BASELINE_CONTACT_CM


# Sharp-component contact (cm): point, blade, or edge/flange. Uses weapon get_sharp_contact_cm (blade_width, point_width, edge_width).
static func _get_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_sharp_contact_cm"):
		var ret = (weapon as Object).get_sharp_contact_cm(attack_type)
		if ret is float or ret is int:
			return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
	if weapon != null:
		push_warning("[WeaponDamageHelper] Weapon lacks get_sharp_contact_cm; using fallback. Ensure weapon is Weapon instance.")
	return maxf(_get_contact_width_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Effective sharp contact (cm): geometric sharp contact / sharpness factor. Sharper = smaller = higher penetration.
static func _get_effective_sharp_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_effective_sharp_contact_cm"):
		var ret = (weapon as Object).get_effective_sharp_contact_cm(attack_type)
		if ret is float or ret is int:
			return maxf(float(ret), WeaponConstants.MIN_CONTACT_WIDTH_CM)
	return maxf(_get_sharp_contact_cm(weapon, attack_type), WeaponConstants.MIN_CONTACT_WIDTH_CM)


# Blunt-component contact (cm): head, shaft, or slap (cut uses BLUNT_CUT_MIN). Used for blunt damage and penetration.
static func _get_blunt_contact_cm(weapon: RefCounted, attack_type: String) -> float:
	if weapon != null and weapon is Object and (weapon as Object).has_method("get_blunt_contact_cm"):
		var ret = (weapon as Object).get_blunt_contact_cm(attack_type)
		if ret is float or ret is int:
			return float(ret)
	if weapon != null:
		push_warning("[WeaponDamageHelper] Weapon lacks get_blunt_contact_cm; using fallback. Ensure weapon is Weapon instance from create_from_definition.")
	var contact_cm: float = _get_contact_width_cm(weapon, attack_type)
	var contact_fallback: String = WeaponConstants.contact_type_for_move_id(attack_type)
	if contact_fallback == WeaponConstants.ATTACK_TYPE_CUT:
		contact_cm = maxf(contact_cm, WeaponConstants.BLUNT_CUT_MIN_CONTACT_CM)
	return contact_cm


# Blunt contact for damage: archetype override or weapon get_blunt_contact_cm (uses actual blade_width, point_width, head_diameter).
static func _get_blunt_contact_for_damage(weapon: RefCounted, attack_instance: RefCounted) -> float:
	var arch = attack_instance.get("archetype")
	if arch is Dictionary and arch.get("contact_override_cm", -1.0) >= 0.0:
		return float(arch.contact_override_cm)
	var at = attack_instance.get("attack_type")
	if at is String:
		return _get_blunt_contact_cm(weapon, at)
	push_warning("[WeaponDamageHelper] attack_instance missing attack_type; using BASELINE_CONTACT_CM for blunt.")
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
