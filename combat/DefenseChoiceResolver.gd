class_name DefenseChoiceResolver
extends RefCounted

## Given attack params and defender state, chooses parry vs dodge and computes parry capacity/timing.
## Pure function: returns a dict of computed values; caller handles resolution and mutation.

const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _PathResolver := preload("res://combat/AttackPathResolver.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Returns dict with: defense, can_parry_in_time, parry_p_a, parry_c_d, parry_time_to_react,
## parry_readiness, parry_off_balance, late_parry, is_block_parry, m_a_parry, m_d_parry,
## s_atk_parry, s_d_parry, dodge_chance, dodge_eval_part, effective_redirect
static func choose_defense(
	pa: Dictionary,
	atk: Dictionary,
	tgt: Dictionary,
	targetable: Array,
	attack_type: String,
	archetype: Dictionary,
	velocity_override: float
) -> Dictionary:
	var result: Dictionary = {
		"defense": "dodge",
		"can_parry_in_time": false,
		"parry_p_a": 0.0,
		"parry_c_d": 0.0,
		"parry_time_to_react": 0.0,
		"parry_readiness": 0.0,
		"parry_off_balance": false,
		"late_parry": false,
		"is_block_parry": false,
		"m_a_parry": 0.0,
		"m_d_parry": 0.0,
		"m_a_velocity": 0.0,
		"s_atk_parry": 100.0,
		"s_d_parry": 100.0,
		"dodge_chance": 0.0,
		"dodge_eval_part": "",
		"effective_redirect": 2.5
	}
	result.dodge_eval_part = BodyPartConstants.get_weighted_random_part(targetable) if not targetable.is_empty() else ""

	var dodge_chance: float = _EntityAccess.get_dodge_chance(tgt)
	result.dodge_chance = dodge_chance

	var already_used_defense: bool = pa.get("passive_parry_attempted", false)
	if already_used_defense or tgt.state == CombatConstants.STATE_WIND_UP or tgt.state == CombatConstants.STATE_MEDICAL_WIND_UP:
		result.effective_redirect = _get_effective_redirect(tgt)
		return result

	var wind_up_duration: float = pa.get("wind_up_duration", 0.5)
	var effective_wind_up: float = wind_up_duration * (1.0 - CombatConstants.COMMITMENT_FRACTION)
	var can_parry_in_time: bool = false
	var parry_p_a: float = 0.0
	var parry_c_d: float = 0.0
	var parry_time_to_react: float = 0.0
	var parry_capacity_mult: float = 0.0
	var parry_readiness: float = 0.0
	var parry_off_balance: bool = false
	var late_parry: bool = false

	if tgt.node != null and tgt.node.has_method("get_passive_parry_reaction_time") and _EntityAccess.has_weapon(tgt):
		var def_weapon = _EntityAccess.get_weapon(tgt)
		if def_weapon != null and effective_wind_up > 0.0:
			var atk_weapon = _EntityAccess.get_weapon(atk)
			var reaction_time: float = tgt.node.get_passive_parry_reaction_time()
			if reaction_time < effective_wind_up and atk_weapon != null:
				can_parry_in_time = true
				var move_def: Dictionary = WeaponConstants.get_move(attack_type)
				var contact_type: String = str(move_def.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
				var m_a_striking: float = float(atk_weapon.get_striking_part_mass_kg(contact_type)) if atk_weapon.has_method("has_parts") and atk_weapon.has_parts() else float(atk_weapon.mass)
				var attack_instance = AttackInstance.new(attack_type, pa.get("intensity", 0.5))
				attack_instance.archetype = archetype
				attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
				var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
				parry_time_to_react = effective_wind_up - reaction_time
				var parry_progress: float = 1.0 - clampf(parry_time_to_react / maxf(0.001, effective_wind_up), 0.0, 1.0)
				parry_p_a = m_a_striking * v_intent * CombatTiming.velocity_curve_factor(parry_progress)
				var c_d_full: float = _compute_parry_c_d(def_weapon, tgt, contact_type)
				parry_capacity_mult = _get_parry_capacity_mult(def_weapon, tgt, parry_time_to_react)
				parry_c_d = c_d_full
				parry_readiness = _PassiveParry.get_passive_parry_readiness(tgt)
				parry_off_balance = _PassiveParry.is_off_balance(tgt)
				parry_c_d *= parry_capacity_mult * parry_readiness
				if parry_off_balance:
					parry_c_d *= CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
				parry_c_d *= _parry_bonus_if_active(tgt)
				# Guard zone: parry bonus when target_part == guard_zone, penalty when unguarded (feint D).
				parry_c_d *= _guard_zone_modifier(pa, tgt, targetable, attack_type)
				# BP2: angle-based alignment — parry capacity ∝ cos(θ). Use blade position at parry contact, not arc end.
				# Arc tracking: weapon angle at parry_progress = where blade will be when defender meets it.
				var align_ctx: Dictionary = {}
				var arc_start: float = pa.get("arc_start_deg", 0.0)
				var arc_end: float = pa.get("arc_end_deg", pa.get("attack_angle_deg", -999.0))
				if arc_end >= -900.0:
					var attack_angle_at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, parry_progress)
					var def_mass: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
					var wobble: Dictionary = {"parry_readiness": parry_readiness, "defender_mass_kg": def_mass}
					align_ctx = {"attack_angle_deg": attack_angle_at_contact, "guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt, wobble)}
				var _al: float = _get_line_alignment(attack_type, tgt, pa.get("effective_attack_line", ""), align_ctx)
				parry_c_d *= _get_contact_geometry(_al, def_weapon)
				# Stamina: non-linear fatigue curve — parry capacity scales with stamina_factor
				var st_ratio: float = clampf(tgt.get("stamina", CombatConstants.STAMINA_MAX) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
				parry_c_d *= lerpf(CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(st_ratio))
				if CombatConstants.COMBAT_DEBUG:
					var dbg_tgt: String = tgt.node.name if tgt.get("node") != null else "id:%d" % tgt.get("id", -1)
					CombatDebug.log("parry_align %s guard=%s atk=%s align=%.2f" % [dbg_tgt, tgt.get("guard_line", "high"), move_def.get("attack_line", "high"), _al])
				var cal_suffix: String = ""
				if not align_ctx.is_empty():
					cal_suffix = " atk_deg=%.0f guard_deg=%.0f" % [align_ctx.get("attack_angle_deg", 0.0), align_ctx.get("guard_angle_deg", 0.0)]
				CombatDebug.calibration_log("parry_pre atk_line=%s guard=%s align=%.3f parry_c_d=%.2f%s" % [WeaponConstants.get_move(attack_type).get("attack_line", "high"), tgt.get("guard_line", "high"), _al, parry_c_d, cal_suffix])
			elif atk_weapon != null:
				# Late parry: reflexive/partial contact when "too late"
				can_parry_in_time = true
				late_parry = true
				var move_def_late: Dictionary = WeaponConstants.get_move(attack_type)
				var contact_type_late: String = str(move_def_late.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
				var m_a_striking_late: float = float(atk_weapon.get_striking_part_mass_kg(contact_type_late)) if atk_weapon.has_method("has_parts") and atk_weapon.has_parts() else float(atk_weapon.mass)
				var attack_instance = AttackInstance.new(attack_type, pa.get("intensity", 0.5))
				attack_instance.archetype = archetype
				attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
				var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
				parry_p_a = m_a_striking_late * v_intent * CombatTiming.velocity_curve_factor(1.0)
				parry_time_to_react = 0.0
				parry_c_d = _compute_parry_c_d(def_weapon, tgt, contact_type_late)
				parry_c_d *= CombatConstants.PARRY_LATE_CAPACITY_FLOOR
				# Attack arc: large span = blade moved far; harder to catch late.
				var arc_span: float = pa.get("arc_span_deg", 0.0)
				if arc_span > CombatConstants.ARC_SPAN_LATE_PARRY_THRESHOLD_DEG:
					var span_factor: float = clampf((arc_span - CombatConstants.ARC_SPAN_LATE_PARRY_THRESHOLD_DEG) / 90.0, 0.0, 1.0)
					parry_c_d *= 1.0 - CombatConstants.ARC_SPAN_LATE_PARRY_PENALTY_MAX * span_factor
				parry_readiness = _PassiveParry.get_passive_parry_readiness(tgt)
				parry_off_balance = _PassiveParry.is_off_balance(tgt)
				if parry_off_balance:
					parry_c_d *= CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
				parry_c_d *= _parry_bonus_if_active(tgt)
				# Guard zone: parry bonus when target_part == guard_zone, penalty when unguarded (feint D).
				parry_c_d *= _guard_zone_modifier(pa, tgt, targetable, attack_type)
				# BP2: angle-based alignment for late parry. Arc at progress 1.0 = impact (blade at arc_end).
				var align_ctx_late: Dictionary = {}
				var arc_start_late: float = pa.get("arc_start_deg", 0.0)
				var arc_end_late: float = pa.get("arc_end_deg", pa.get("attack_angle_deg", -999.0))
				if arc_end_late >= -900.0:
					var attack_angle_at_impact: float = CombatConstants.get_arc_angle_at_progress(arc_start_late, arc_end_late, 1.0)
					var def_mass_late: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
					var wobble_late: Dictionary = {"parry_readiness": parry_readiness, "defender_mass_kg": def_mass_late}
					align_ctx_late = {"attack_angle_deg": attack_angle_at_impact, "guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt, wobble_late)}
				var _al: float = _get_line_alignment(attack_type, tgt, pa.get("effective_attack_line", ""), align_ctx_late)
				parry_c_d *= _get_contact_geometry(_al, def_weapon)
				# Stamina: non-linear fatigue curve — parry capacity scales with stamina_factor
				var st_ratio_late: float = clampf(tgt.get("stamina", CombatConstants.STAMINA_MAX) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
				parry_c_d *= lerpf(CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(st_ratio_late))
				if CombatConstants.COMBAT_DEBUG:
					CombatDebug.log("parry_align late %s align=%.2f" % [tgt.get("guard_line", "high"), _al])

	result.can_parry_in_time = can_parry_in_time
	result.parry_p_a = parry_p_a
	result.parry_c_d = parry_c_d
	result.parry_time_to_react = parry_time_to_react
	result.parry_readiness = parry_readiness
	result.parry_off_balance = parry_off_balance
	result.late_parry = late_parry

	var parry_cfg: Dictionary = _PassiveParry.get_parry_config()
	# Bidirectional strong/weak: attacker weak exposure + defender forte (blade only). Shaft/haft use leverage in contact_geometry.
	# Contact quality: delayed/slow parries couldn't get weapon into optimal position — contact happens further out (weak). Scale strong/weak by intercept ability.
	if can_parry_in_time:
		var atk_w_arch = _EntityAccess.get_weapon(atk)
		var def_w_arch = _EntityAccess.get_weapon(tgt)
		var _def_w: Variant = def_w_arch if def_w_arch != null else _EntityAccess.get_weapon(tgt)
		var contact_quality: float = CombatConstants.PARRY_LATE_CAPACITY_FLOOR if late_parry else (_get_parry_capacity_mult(_def_w, tgt, parry_time_to_react) if _def_w != null else 0.5)
		if atk_w_arch != null and atk_w_arch.has_method("get_archetype_id"):
			var arch_id: String = atk_w_arch.get_archetype_id(attack_type)
			var pct: String = def_w_arch.get_parry_contact_type() if def_w_arch != null and def_w_arch.has_method("get_parry_contact_type") else "blade"
			# Blade-on-blade: archetype weak exposure + defender forte matter. Shaft/haft: leverage only — no blade weak to catch.
			var full_strong_mod: float = parry_cfg.get("strong_contact_by_arch", {}).get(arch_id, 1.0) if pct == "blade" else 1.0
			if pct == "blade":
				var weak_exp: float = float(CombatConstants.WEAK_EXPOSURE_BY_ARCH.get(arch_id, 0.5))
				var strong_frac: float = def_w_arch.get_parry_strong_fraction() if def_w_arch.has_method("get_parry_strong_fraction") else 0.25
				full_strong_mod *= 1.0 + CombatConstants.DEFENDER_STRONG_BONUS * strong_frac * weak_exp
			var strong_mod: float = lerpf(1.0, full_strong_mod, contact_quality)
			result.parry_c_d = parry_c_d * strong_mod
		else:
			result.parry_c_d = parry_c_d

	# Mass/strength for block check (total mass for both); m_a_velocity for partial parry v_reduced (striking mass when parts).
	var m_a_parry: float = 0.0
	var m_d_parry: float = 0.0
	var m_a_velocity: float = 0.0
	var s_atk_parry: float = 100.0
	var s_d_parry: float = 100.0
	if can_parry_in_time:
		var atk_w: Variant = _EntityAccess.get_weapon(atk)
		var def_w: Variant = _EntityAccess.get_weapon(tgt)
		if atk_w != null and def_w != null:
			m_a_parry = float(atk_w.mass) if (atk_w.get("mass") is float or atk_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
			m_d_parry = float(def_w.mass) if (def_w.get("mass") is float or def_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
			var move_def_mass: Dictionary = WeaponConstants.get_move(attack_type)
			var ct_mass: String = str(move_def_mass.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
			m_a_velocity = float(atk_w.get_striking_part_mass_kg(ct_mass)) if atk_w.has_method("has_parts") and atk_w.has_parts() else float(atk_w.mass)
		s_atk_parry = float(atk.stats.get("strength", 100))
		s_d_parry = float(tgt.stats.get("strength", 100))
	result.m_a_parry = m_a_parry
	result.m_d_parry = m_d_parry
	result.m_a_velocity = m_a_velocity
	result.s_atk_parry = s_atk_parry
	result.s_d_parry = s_d_parry

	var block_mass_t: float = parry_cfg.get("block_mass_threshold", 0.9)
	var block_str_t: float = parry_cfg.get("block_str_threshold", 0.95)
	var effective_redirect: float = _get_effective_redirect(tgt)
	result.effective_redirect = effective_redirect
	result.is_block_parry = m_d_parry >= m_a_parry * block_mass_t and s_d_parry >= s_atk_parry * block_str_t
	var block_viable: bool = can_parry_in_time and result.parry_p_a <= result.parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO
	var desperate_parry: bool = can_parry_in_time and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD
	var redirect_viable: bool = can_parry_in_time and (result.parry_p_a <= result.parry_c_d * effective_redirect or desperate_parry)
	var def_has_weapon: bool = _EntityAccess.has_weapon(tgt)

	var choose_parry: bool = false
	if not def_has_weapon:
		choose_parry = false
	elif desperate_parry:
		choose_parry = true
	elif not can_parry_in_time:
		choose_parry = false
	elif can_parry_in_time and def_has_weapon:
		var part_mod: float = _EntityAccess.get_part_dodge_modifier(tgt, result.dodge_eval_part)
		var effective_dodge_chance: float = dodge_chance * part_mod
		var full_dodge_prob: float = effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD
		var partial_dodge_avg_ratio: float = (CombatConstants.DODGE_PARTIAL_RATIO_MIN + 1.0) * 0.5
		var E_dodge: float = (1.0 - effective_dodge_chance) * 1.0 + effective_dodge_chance * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD) * partial_dodge_avg_ratio
		var parry_full: bool = result.is_block_parry and result.parry_c_d >= (result.parry_p_a * CombatConstants.PARRY_DEFLECT_THRESHOLD)
		var r_bonus: float = parry_cfg.get("redirect_bonus", 0.18)
		var r_scale: float = parry_cfg.get("redirect_skill_scale", 0.35)
		var redirect_skill: float = clampf((float(tgt.stats.get("agility", 100)) + float(tgt.stats.get("perception", 100))) / 200.0, 0.5, 1.5)
		var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
		if attack_type == WeaponConstants.ATTACK_TYPE_STAB:
			redirect_mult *= 1.0 + parry_cfg.get("redirect_thrust_bonus", 0.22)
		elif attack_type == WeaponConstants.ATTACK_TYPE_BLUNT:
			redirect_mult *= 1.0 - parry_cfg.get("redirect_blunt_penalty", 0.12)
		if not result.is_block_parry and m_a_parry > 0.001 and m_d_parry < m_a_parry:
			var mass_bonus: float = parry_cfg.get("mass_disparity_bonus", 0.18) * (1.0 - m_d_parry / m_a_parry)
			redirect_mult *= 1.0 + mass_bonus
		var parry_remaining_est: float = 1.0
		if not parry_full and result.parry_p_a > 0.001:
			parry_remaining_est = clampf(maxf(0.0, result.parry_p_a - result.parry_c_d * redirect_mult) / result.parry_p_a, 0.0, 1.0)
		var glancing_exp: float = parry_cfg.get("glancing_exponent", 0.5)
		var E_parry: float = 0.0 if parry_full else pow(parry_remaining_est, glancing_exp)
		var dodge_better: bool = E_dodge < E_parry
		var clean_dodge_likely: bool = full_dodge_prob >= CombatConstants.PARRY_PREFER_DODGE_FULL_THRESHOLD
		choose_parry = late_parry or ((block_viable or redirect_viable) and not dodge_better and not clean_dodge_likely)
	result.defense = "parry" if choose_parry else "dodge"
	return result

static func _get_effective_redirect(tgt: Dictionary) -> float:
	var pcfg: Dictionary = _PassiveParry.get_parry_config()
	var redirect_attempt: float = pcfg.get("redirect_attempt_ratio", 2.5)
	var agi_scale: float = pcfg.get("redirect_attempt_agility_scale", 0.5)
	var agi_d_attempt: float = float(tgt.stats.get("agility", 100))
	return redirect_attempt * (0.75 + agi_scale * clampf(agi_d_attempt / 100.0, 0.0, 1.5))

static func _compute_parry_c_d(def_weapon, tgt: Dictionary, contact_type: String = "") -> float:
	var m_parry_part: float = float(def_weapon.get_parry_part_mass_kg()) if def_weapon.has_method("has_parts") and def_weapon.has_parts() else float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
	var m_total: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
	# Full weapon mass matters: inertia and geometry. Blend parry-part (contact) with total (leverage).
	var m_d: float = lerpf(m_parry_part, m_total, CombatConstants.PARRY_INERTIA_BLEND) if def_weapon.has_method("has_parts") and def_weapon.has_parts() else m_total
	var s_d: float = float(tgt.stats.get("strength", 100))
	var c_d_full: float = m_d * PassiveParryContext.get_parry_speed_m_s(def_weapon) * (s_d / CombatConstants.PARRY_STRENGTH_NORM)
	var agi_d: float = float(tgt.stats.get("agility", 100))
	c_d_full *= clampf(agi_d / 100.0, 0.7, 1.3)
	var def_perf: float = _EntityAccess.get_performance_modifier(tgt)
	c_d_full *= maxf(CombatConstants.PERF_MOD_MIN, def_perf)
	var arm_mod: float = 1.0
	if tgt.node.has_method("get_attack_damage_modifier"):
		arm_mod = tgt.node.get_attack_damage_modifier()
	c_d_full *= maxf(0.1, arm_mod)
	if def_weapon.has_method("get_parry_contact_type") and def_weapon.has_parts():
		var pct: String = def_weapon.get_parry_contact_type()
		c_d_full *= CombatConstants.PARRY_CONTACT_MODIFIERS.get(pct, 1.0)
	if not contact_type.is_empty() and "weapon_type" in def_weapon:
		var def_type: String = str(def_weapon.weapon_type).to_upper()
		var mod_dict: Variant = CombatConstants.PARRY_DEF_VS_ATK_MOD.get(def_type, {})
		if mod_dict is Dictionary:
			var mult: float = float(mod_dict.get(contact_type, 1.0))
			c_d_full *= mult
	return c_d_full

## Unified contact geometry: alignment × leverage. Blade gets alignment only (leverage=1); shaft/haft get alignment × leverage factor.
## Merges angular (attack vs guard) and linear (where along shaft contact happens) into one multiplier.
static func _get_contact_geometry(alignment: float, def_weapon) -> float:
	var leverage: float = _get_leverage_factor(def_weapon, alignment)
	return alignment * leverage

## Leverage factor: where along shaft/haft the blow lands. Good alignment = defender controlled contact = strong (near hands).
## Poor alignment = contact could be weak (far from hands). Blade/handle: 1.0 (uniform).
static func _get_leverage_factor(def_weapon, alignment: float) -> float:
	if not def_weapon.has_method("has_parts") or not def_weapon.has_parts():
		return 1.0
	var pct: String = def_weapon.get_parry_contact_type() if def_weapon.has_method("get_parry_contact_type") else "blade"
	if pct != "shaft" and pct != "haft":
		return 1.0
	var len_cm: float = def_weapon.get_parry_part_length_cm() if def_weapon.has_method("get_parry_part_length_cm") else 0.0
	if len_cm < CombatConstants.PARRY_LEVERAGE_LONG_PART_CM:
		return 1.0
	return lerpf(CombatConstants.PARRY_LEVERAGE_FLOOR, 1.0, alignment)

static func _get_parry_capacity_mult(def_weapon, tgt: Dictionary, parry_time_to_react: float) -> float:
	var m_d: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
	var s_d: float = float(tgt.stats.get("strength", 100))
	var speed_f: float = clampf(float(def_weapon.get("parry_speed_factor", 1.0)), 0.5, 1.5)
	var blade_movement_s: float = (CombatConstants.PARRY_BLADE_MOVEMENT_S * clampf(m_d * CombatConstants.PARRY_STRENGTH_NORM / maxf(s_d, 1.0), CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MIN, CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MAX)) / speed_f
	var effective_parry_time: float = maxf(0.0, parry_time_to_react - blade_movement_s)
	return clampf(effective_parry_time / CombatConstants.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)

static func _parry_bonus_if_active(tgt: Dictionary) -> float:
	var now_s: float = Time.get_ticks_msec() / 1000.0
	if tgt.get("parry_bonus_until", -1.0) > now_s:
		return 1.1
	return 1.0

static func _get_line_alignment(attack_type: String, tgt: Dictionary, effective_attack_line_override: String = "", alignment_context: Dictionary = {}) -> float:
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var attack_line: String = effective_attack_line_override if not effective_attack_line_override.is_empty() else move_def.get("attack_line", "high")
	return CombatConstants.get_line_alignment_with_deflect(attack_line, tgt, alignment_context)

## Guard zone modifier: bonus when defender guards the hit part, penalty when unguarded (feint D).
static func _guard_zone_modifier(pa: Dictionary, tgt: Dictionary, targetable: Array, attack_type: String) -> float:
	var guard_zone: String = str(tgt.get("guard_zone", "head"))
	if guard_zone.is_empty():
		return 1.0
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var attack_line: String = move_def.get("attack_line", "high")
	var guard_line: String = tgt.get("guard_line", "high")
	var intended: String = str(pa.get("target_part", ""))
	var expected_part: String = _PathResolver.resolve_hit_part(attack_line, guard_line, targetable, {}, intended, tgt)
	if expected_part.is_empty():
		return 1.0
	if expected_part == guard_zone:
		return CombatConstants.GUARD_ZONE_BONUS
	return CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
