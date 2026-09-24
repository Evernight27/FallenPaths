class_name AttackResolver
extends RefCounted

## Strike resolve pipeline: path, alignment, **`DefenseChoiceResolver.choose_defense`**, damage apply dispatch.
## Footing: PA stamp at resolve if **`effective_attack_line`** differs from wind-up (diagonal **C** roll); exchange end
## **`clear_on_exchange_end`** both sides. LIVE_PATHS **`#wf-tier-44-pa`**.

## Debug logging — delegates to `CombatDebug.log` which gates on `combat_debug_active`.


## Multiplier applied to sharp/blunt penetration for oblique incidence (parry/deflect or misaligned guard).
## When `velocity_override` < 0, intensity-derived speed is used and this factor stays **1** (no oblique scaling here).
## Parry branch wins when `parry_remaining_ratio` < 1 (partial contact already encodes obliquity). Otherwise misaligned
## guard uses the alignment scale against `PARRY_PENETRATION_ANGLE_MIN`.
static func penetration_oblique_angle_factor(
	velocity_override: float, parry_remaining_ratio: float, alignment: float
) -> float:
	if velocity_override < 0.0:
		return 1.0
	if parry_remaining_ratio < 1.0:
		return lerpf(1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, 1.0 - parry_remaining_ratio)
	if alignment < 1.0:
		return lerpf(
			1.0,
			CombatConstants.PARRY_PENETRATION_ANGLE_MIN,
			(1.0 - alignment) * CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
		)
	return 1.0


## Returns { "result_dict": Dictionary, "outcome": String, "recovery_duration": float }.
## Also updates tgt.stats (body_cutting, body_blunt, etc.) and tgt.alive/tgt.state if target died.
## `wind_up_factor` — optional multiplier from CombatTiming.wind_up_factor(); applied after velocity/KE but before
## armor penetration to model HEMA energy curve: shorter wind-ups deliver less strike energy regardless of intensity.


static func compute_and_apply_damage(
	manager: Node,
	attacker_id: int,
	target_id: int,
	atk: Dictionary,
	tgt: Dictionary,
	part: String,
	intensity: float,
	attack_type: String,
	archetype: Dictionary,
	velocity_override: float,
	recovery_mult: float,
	perf_mod: float,
	_power: float = -1.0,
	_follow_through: float = -1.0,
	parry_remaining_ratio: float = 1.0,
	afterblow_damage_mult: float = 1.0,
	alignment: float = 1.0,
	strike_mods: Dictionary = {},
	strike_physics_ctx: Dictionary = {},
	wind_up_factor_override: float = -1.0,
	measure_ratio: float = 1.0
) -> Dictionary:
	var sm: Dictionary = strike_mods
	var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
	var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
	var atk_stats := CombatantEntityAccess.stats_dict(atk)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
	var blunt_contact_cm: float = -1.0
	var blunt_coupling_contact_cm: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0
	var strike_ke_j: float = -1.0
	var attack_perf: Dictionary = {}
	var tgt_n: Node = CombatantEntityAccess.scene_node(tgt)
	if tgt_n == null:
		CombatDebug.log("compute_and_apply_damage %s->%s target scene node freed, skip" % [atk_name, tgt_name])
		return {"action": "skip", "target_id": target_id, "recovery_duration": 0.0}

	var weapon = CombatantEntityAccess.get_weapon(atk)

	if CombatantEntityAccess.weapon_has_attack_types(weapon):
		var commit_frac: float = strike_physics_ctx.get(DataKeys.ARCHETYPE_WEAPON_EXTENSION_COMMIT_FRACTION, -1.0)
		if commit_frac < 0.0:
			commit_frac = CombatWeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move(attack_type))
		var delivery_intensity: float = WeaponDamageHelper.effective_intensity_for_delivery(intensity, commit_frac)
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		attack_instance.delivery_commit_fraction = commit_frac
		attack_instance.strike_momentum_mult = sm.get(DataKeys.ATK_STRIKE_MOMENTUM_MULT, 1.0)
		# Swing mechanics (TOPIC 8): training changes HOW the blow is produced. Same combined weapon+form tier
		# as aim -> near-specific transfer; velocity economy + strike-mass coupling + fatigue resilience below.
		# Untracked fighters (flag-off / enemies) resolve neutral: economy 1.0, fatigue hold 0.0.
		var atk_ent: CoreEntity = CombatantEntityAccess.scene_entity(atk)
		var swing_tier: float = EntityProficiency.swing_proficiency_tier(
			atk_ent, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk)
		)
		var swing_econ: float = EntityProficiency.swing_velocity_economy(swing_tier)
		var swing_hold: float = (
			EntityProficiency.swing_skill_hold(swing_tier)
			if EntityProficiency.is_swing_proficiency_tracked(atk_ent)
			else 0.0
		)
		attack_instance.strike_mass_mult = EntityProficiency.strike_mass_coupling(swing_tier)
		var v_base: float = (
			velocity_override
			if velocity_override >= 0.0
			else WeaponDamageHelper.velocity_m_s_from_intensity(delivery_intensity, archetype, weapon, attack_type)
		)
		attack_instance.velocity_m_s = v_base
		var closing_speed_mult: float = StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
		attack_instance.velocity_m_s *= closing_speed_mult
		# Blade-velocity transfer economy: green fighters lose nominal intensity to bad body mechanics before
		# the blade starts. Flows into v² KE, momentum/penetration, and blunt impact like a real slow strike.
		attack_instance.velocity_m_s *= swing_econ
		var atk_st_ratio_w: float = CombatantEntityAccess.stamina_ratio(atk)
		# Muscle fatigue → strike velocity degradation (HIGH #10 biomechanics audit).
		# ATP-PCr depletion reduces rate of force development before max strength fails.
		var exhaustion_s: float = atk.get(CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION, 0.0) if CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION in atk else 0.0
		var fatigue_vel: float = CombatConstantsStamina.fatigue_velocity_mult(atk_st_ratio_w, exhaustion_s, swing_hold)
		var power_m: float = CombatExhaustion.power_mult_for_combatant(atk)
		attack_instance.velocity_m_s *= fatigue_vel * power_m
		if afterblow_damage_mult < 1.0:
			attack_instance.velocity_m_s *= sqrt(maxf(0.04, afterblow_damage_mult))
		var wuf: float = (
			wind_up_factor_override
			if wind_up_factor_override > 0.0
			else CombatTiming.wind_up_factor(pa.get(DataKeys.PA_WIND_UP_DURATION, CombatTiming.WIND_UP_FACTOR_OPTIMAL_S))
		)
		attack_instance.velocity_m_s = ImpactVelocityModel.clamp_velocity_m_s(attack_instance.velocity_m_s)
		var arm_mod: float = CombatantEntityAccess.get_attack_damage_modifier(atk)
		var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, part)
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		# Physics: deflected cut presents flat/slap; edge doesn't bite. Shift cut|'blunt on partial parry.
		var move_contact: String = CombatantEntityAccess.weapon_contact_type(weapon, attack_type)
		if move_contact == WeaponConstants.ATTACK_TYPE_CUT and velocity_override >= 0.0 and parry_remaining_ratio < 1.0:
			var shift_const: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT
			var redirect_shift: float = shift_const * (1.0 - parry_remaining_ratio)
			cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect_shift)
		var atk_str: float = float(
			atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
		)
		pre_cut = WeaponDamageHelper.compute_pre_armor_cut(weapon, attack_instance, atk_str, arm_mod) * cut_ratio * wuf
		pre_blunt = WeaponDamageHelper.compute_blunt_slip_pre_armor(
			weapon, attack_instance, atk_str, arm_mod, cut_ratio, target_mass, sm.get(DataKeys.ATK_BLUNT_DAMAGE_MULT, 1.0)
		) * wuf
		pre_cut *= sm.get(DataKeys.ATK_MOD_CUT_DAMAGE_MULT, 1.0)
		# Engagement angle: a clean rear/flank strike lands on an unguarded side and hits harder.
		var engagement_dmg_mult: float = StrikePhysics.engagement_damage_multiplier(tgt)
		pre_cut *= engagement_dmg_mult
		pre_blunt *= engagement_dmg_mult
		pre_armor = pre_cut + pre_blunt
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(
			weapon, attack_instance, WeaponConstants.DAMAGE_TYPE_SHARP
		)
		pen_sharp = pen_sharp_dict.get(DataKeys.ATK_PENETRATION_SHARP, -1.0)
		var blunt_opts: Dictionary = {}
		var armor_rha: float = CombatArmorDoctrine.get_effective_rha_with_degradation(tgt, part)
		if armor_rha > 0.0:
			blunt_opts[DataKeys.BLUNT_OPT_ARMOR_RESISTANCE_RHA_MM] = armor_rha
		blunt_opts[DataKeys.BLUNT_OPT_PEN_SHARP_MM] = pen_sharp
		blunt_opts[DataKeys.BLUNT_OPT_TARGET_EFFECTIVE_MASS_KG] = target_mass
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(
			weapon, attack_instance, WeaponConstants.DAMAGE_TYPE_BLUNT, blunt_opts
		)
		pen_blunt_momentum_per_area = pen_blunt_dict.get(DataKeys.ATK_PENETRATION_BLUNT_MPA, -1.0)
		blunt_contact_cm = pen_blunt_dict.get(DataKeys.ATK_BLUNT_CONTACT_CM, -1.0)
		blunt_coupling_contact_cm = pen_blunt_dict.get(DataKeys.ATK_BLUNT_COUPLING_CONTACT_CM, -1.0)
		# Angle (deflection): oblique impact = less penetration (armor research).
		var angle_factor: float = penetration_oblique_angle_factor(velocity_override, parry_remaining_ratio, alignment)
		if angle_factor < 1.0:
			if pen_sharp >= 0.0:
				pen_sharp *= angle_factor
			if pen_blunt_momentum_per_area >= 0.0:
				pen_blunt_momentum_per_area *= angle_factor
		if pen_sharp >= 0.0:
			pen_sharp *= sm.get(DataKeys.ATK_MOD_SHARP_PENETRATION_MULT, 1.0)
		if pen_blunt_momentum_per_area >= 0.0:
			pen_blunt_momentum_per_area *= sm.get(DataKeys.ATK_BLUNT_MOMENTUM_PA_MULT, 1.0)
		strike_ke_j = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		attack_perf = {
			"str": atk_str,
			"arm": arm_mod,
			"fat": fatigue_vel,
			"pow": power_m,
			"wuf": wuf,
			"close": closing_speed_mult,
			"eng": engagement_dmg_mult,
			"stm": atk_st_ratio_w,
			"exh": exhaustion_s,
			"swing": swing_econ,
			"intensity": intensity,
			"ke_j": strike_ke_j,
			"v_final": attack_instance.velocity_m_s,
			"v_base": v_base,
		}
		CombatDebug.log(
			(
				"dmg %s->%s part=%s pre_armor=%.1f cut=%.1f blunt=%.1f pen=%.2f ke_j=%.1f v_final=%.2f v_base=%.2f ovr=%.1f i=%.2f st=%.2f pwr=%.2f exh=%.2f w=%s wuf=%.2f wdur=%.2f"
				% [
					atk_name,
					tgt_name,
					part,
					pre_armor,
					pre_cut,
					pre_blunt,
					pen_sharp,
					strike_ke_j,
					attack_instance.velocity_m_s,
					v_base,
					velocity_override,
					intensity,
					fatigue_vel,
					power_m,
					CombatantEntityAccess.exhaustion_float(atk),
					str(weapon.weapon_type if weapon != null and "weapon_type" in weapon else "?"),
					wuf,
					float(pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)),
				]
			)
		)
	else:
		var mod: float = CombatantEntityAccess.get_attack_damage_modifier(atk)
		pre_armor = WeaponDamageHelper.unarmed_base_pre_armor(
			float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)), mod
		)
		# Swing mechanics (TOPIC 8) also apply to unarmed blows: green fighters throw less efficient strikes.
		# No strike-mass coupling here — fist mass is a constant inside the pinned unarmed_base_pre_armor.
		var atk_ent_u: CoreEntity = CombatantEntityAccess.scene_entity(atk)
		var swing_tier_u: float = EntityProficiency.swing_proficiency_tier(
			atk_ent_u, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk)
		)
		pre_armor *= EntityProficiency.swing_velocity_economy(swing_tier_u)
		if parry_remaining_ratio < 1.0:
			var ctrl_mapped := 1.0 - parry_remaining_ratio
			var damage_reduction_factor := ctrl_mapped * CombatConstantsParry.PARRY_UNARMED_MAX_DAMAGE_REDUCTION
			pre_armor *= (1.0 - clampf(damage_reduction_factor, 0.0, 1.0))
		var unarmed_wind_up_dur: float = pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0)
		var unarmed_wuf: float = CombatTiming.wind_up_factor(unarmed_wind_up_dur) if unarmed_wind_up_dur > 0.0 else 1.0
		var atk_st_ratio_u: float = CombatantEntityAccess.stamina_ratio(atk)
		var exh_s_u: float = atk.get(CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION, 0.0) if CombatConstantsStamina.COMBATANT_KEY_EXHAUSTION in atk else 0.0
		var fatigue_vel_u: float = CombatConstantsStamina.fatigue_velocity_mult(
			atk_st_ratio_u,
			exh_s_u,
			EntityProficiency.swing_skill_hold(swing_tier_u)
			if EntityProficiency.is_swing_proficiency_tracked(atk_ent_u)
			else 0.0
		)
		var power_m: float = CombatExhaustion.power_mult_for_combatant(atk)
		var afterblow_u: float = sqrt(maxf(0.04, afterblow_damage_mult))
		var closing_u: float = StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
		var engagement_dmg_u: float = StrikePhysics.engagement_damage_multiplier(tgt)
		pre_armor *= closing_u * fatigue_vel_u * power_m * afterblow_u * engagement_dmg_u
		if unarmed_wuf < 1.0:
			pre_armor *= unarmed_wuf
		pre_blunt = pre_armor
		pre_cut = 0.0
		CombatDebug.log("dmg %s->%s unarmed pre_armor=%.1f" % [atk_name, tgt_name, pre_armor])

	# Stance modifier (defensive f - 0.85, aggressive f - 1.2, etc.) — commitment, not raw speed.
	var stance_dmg_mult: float = CombatWeaponForm.mod(
		CombatantEntityAccess.form_str(atk), "damage", weapon
	)
	pre_cut *= stance_dmg_mult
	pre_blunt *= stance_dmg_mult
	# HEMA commitment quality: a compromised attacker (off-balance, out of measure, an over-extended
	# cut, or inside a longer-armed defender's reach) lands the blow with less force. These sub-1.0
	# penalties are accumulated into a shared + cut-only product and floored below, so a fully-
	# compromised strike never degenerates to a trivial chip — symmetric with HIT_CHANCE_MIN_CAP on
	# the accuracy side. Positional bonuses (angular, bind follow-through, form-switch) stay unclamped.
	var commit_quality_shared: float = 1.0
	var commit_quality_cut: float = 1.0
	# HEMA: an off-balance attacker strikes from a compromised center — weight transfer through the
	# weapon is reduced. Symmetric with the defensive parry-capacity penalty. Penalty fades as the
	# attacker re-establishes balance (proportional to off-balance depth).
	if PassiveParryContext.is_off_balance(atk):
		commit_quality_shared *= PassiveParryContext.off_balance_penalty_mult(atk, CombatConstants.OFF_BALANCE_ATTACK_DMG_MULT)
	# HEMA B3: voiding outside an opponent's strong side leaves their bracing misaligned to the line
	# you take — the voider's strike against the voided target lands with a modest positional bonus.
	# Scoped to the specific voided opponent (a third combatant on the other side is not affected).
	var ang_clock: float = CombatantEntityAccess.combat_clock_float(manager)
	if CombatBindPressure.has_angular_advantage_over(atk, CombatantEntityAccess.id_int(tgt), ang_clock):
		var ang_mult: float = CombatConstants.ANGULAR_ADVANTAGE_DMG_MULT
		pre_cut *= ang_mult
		pre_blunt *= ang_mult
	# HEMA: holding an active bind means you control the opponent's line and contact — a trapped
	# blade and braced give you a small edge on the follow-through strike while the bind is live.
	if CombatBindPressure.is_in_bind(atk, ang_clock) and CombatantEntityAccess.id_int(tgt) == CombatBindPressure.get_bind_partner_id(atk):
		var bind_follow_mult: float = CombatBindPressure.follow_through_dmg_mult(atk, ang_clock)
		if bind_follow_mult > 1.0:
			pre_cut *= bind_follow_mult
			pre_blunt *= bind_follow_mult
	# HEMA: a target mid-guard-change has a blade in transit — the counter into the transition
	# lands on an unguarded line. The defender's parry/dodge are already penalised by the transition;
	# this is the corresponding attack-side payoff.
	if CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_FORM_SWITCH:
		var fsw_vuln_mult: float = CombatConstantsEncounter.FORM_SWITCH_VULNERABILITY_DMG_MULT
		pre_cut *= fsw_vuln_mult
		pre_blunt *= fsw_vuln_mult
	# HEMA: distance governs delivered force, not just accuracy. A strike out of measure (over-extended
	# or short of reach) arrives with less body mass and follow-through behind it. Complements the
	# measure-ratio hit-chance penalty in resolve_attack: distance governs both whether a blow lands AND
	# how hard it lands. Milder floor (0.80) than the over-reach hit-chance floor (0.55): even an
	# over-extended blade still cuts if it connects, it just lacks full commitment.
	if CombatConstants.is_feature_measure_damage_commit_enabled() and measure_ratio != 1.0:
		var measure_dmg_mult: float = 1.0
		if measure_ratio > 1.0 and CombatantEntityAccess.has_weapon(tgt):
			measure_dmg_mult = lerp(1.0, CombatConstants.MEASURE_DMG_OVER_REACH_FLOOR, clampf((measure_ratio - 1.0) * CombatConstants.MEASURE_PENALTY_RAMP_PER_UNIT, 0.0, 1.0))
		elif measure_ratio < 1.0:
			var under_t: float = clampf((1.0 - measure_ratio) / maxf(0.001, 1.0 - CombatConstants.STRIKE_MEASURE_RATIO_MIN), 0.0, 1.0)
			measure_dmg_mult = lerp(1.0, CombatConstants.MEASURE_DMG_UNDER_REACH_FLOOR, under_t)
		commit_quality_shared *= measure_dmg_mult
		# HEMA: a cut needs an arc; past the limit of measure the arc is truncated and the
		# blade can't run through the target, so an over-extended cut lands softer than an
		# over-extended thrust (a point weapon keeps its edge out to full measure). Applies
		# on top of the contact-type-agnostic measure_dmg_mult, to pre_cut only.
		if measure_ratio > 1.0 and WeaponConstants.contact_type_for_move_id(attack_type) == WeaponConstants.ATTACK_TYPE_CUT:
			var cut_or_t: float = clampf((measure_ratio - 1.0) * CombatConstants.MEASURE_PENALTY_RAMP_PER_UNIT, 0.0, 1.0)
			commit_quality_cut *= lerp(1.0, CombatConstants.MEASURE_DMG_CUT_OVER_REACH_FLOOR, cut_or_t)
	# HEMA reach priority: if the defender's weapon reaches further relative to the pair distance than the
	# attacker's, the attacker is inside the defender's natural measure — they must get through a longer,
	# braced blade to land, so the blow arrives with less clean commit. This is a RELATIONAL penalty
	# (defender ratio vs attacker ratio), independent of the attacker's own self-measure, so it fires even
	# at measure_ratio == 1.0. Close-range same-weapon fights (both ratios ~equal) get no penalty: only a
	# genuine reach gap is punished. Milder floor (0.88) than the self-measure floors.
	if CombatConstants.is_feature_measure_damage_commit_enabled() and CombatantEntityAccess.has_weapon(tgt):
		var eff_dist_m: float = pa.get(DataKeys.PA_EFFECTIVE_PAIR_EFF_DIST, 0.0)
		if eff_dist_m >= 0.01:
			var def_weapon: Variant = CombatantEntityAccess.get_weapon(tgt)
			var def_ratio: float = CombatStrikeStamping.strike_measure_ratio_for_weapon_eff_dist(def_weapon, eff_dist_m)
			var reach_gap: float = def_ratio - measure_ratio
			if reach_gap > 0.0:
				var reach_dmg_mult: float = lerp(1.0, CombatConstants.MEASURE_DMG_DEFENDER_REACH_FLOOR, clampf(reach_gap * CombatConstants.MEASURE_PENALTY_RAMP_PER_UNIT, 0.0, 1.0))
				commit_quality_shared *= reach_dmg_mult
	# Apply the committed-attack quality floor so a fully-compromised strike never collapses to a
	# trivial chip (symmetric with HIT_CHANCE_MIN_CAP on the accuracy side). Bonuses stay unclamped.
	var commit_total_cut: float = maxf(commit_quality_shared * commit_quality_cut, CombatConstants.ATTACK_COMMIT_QUALITY_FLOOR)
	var commit_total_blunt: float = maxf(commit_quality_shared, CombatConstants.ATTACK_COMMIT_QUALITY_FLOOR)
	pre_cut *= commit_total_cut
	pre_blunt *= commit_total_blunt
	pre_armor = pre_cut + pre_blunt

	var health_before_cut: float = tgt_n.body_cutting.get(part, 0.0)
	var health_before_blunt: float = tgt_n.body_blunt.get(part, 0.0)
	var health_before_bone: float = tgt_n.bone_health.get(part, 0.0) if tgt_n.get(DataKeys.BONE_HEALTH) else 0.0

	var dmg_extras: Dictionary = {}
	if strike_ke_j >= 0.0:
		dmg_extras[DataKeys.RESULT_STRIKE_KE_J] = strike_ke_j
	var hit_sub: String = strike_physics_ctx.get(DataKeys.STRIKE_CTX_HIT_SUB_REGION, "").strip_edges()
	if not hit_sub.is_empty():
		dmg_extras[DataKeys.RESULT_HIT_SUB_REGION] = hit_sub
	if strike_physics_ctx.has(DataKeys.STRIKE_CTX_HIT_SUB_REGION_SEED):
		dmg_extras[DataKeys.RESULT_HIT_SUB_REGION_SEED] = int(strike_physics_ctx[DataKeys.STRIKE_CTX_HIT_SUB_REGION_SEED])
	var wt: String = str(weapon.weapon_type).to_upper() if weapon != null and "weapon_type" in weapon else ""
	if not wt.is_empty():
		dmg_extras["weapon_type"] = wt
	var eff_atk_line: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
	if not eff_atk_line.is_empty():
		dmg_extras["attack_line"] = eff_atk_line
	# Weapon's TRUE (uncapped) contact face, for the rigid-plate area-coupling term. Rides in
	# extras so the armor math sees the mace's full head (coupling 1.0) rather than the capped
	# pressure-face (2.5 cm) — see ArmorPiece.blunt_transmission_math coupling.
	if blunt_coupling_contact_cm >= 0.0:
		dmg_extras[DataKeys.ATK_BLUNT_COUPLING_CONTACT_CM] = blunt_coupling_contact_cm
	var take_result: Dictionary = tgt_n.take_damage_split(
		pre_cut, pre_blunt, part, pen_sharp, pen_blunt_momentum_per_area, blunt_contact_cm, dmg_extras
	)

	var final_cut: float = take_result.get(DataKeys.RESULT_FINAL_CUT, 0.0)
	var final_blunt: float = take_result.get(DataKeys.RESULT_FINAL_BLUNT, 0.0)
	var final_bone: float = take_result.get(DataKeys.RESULT_FINAL_BONE, 0.0)
	# total_physical: authoritative chip for UI/logs. dmg: int rounded for compact compat.
	var total_physical: float = final_cut + final_blunt + final_bone
	# Minimum physical damage floor: ensure at least 1.0 before rounding, preventing
	# contact hits from being rounded to zero HP when tissue_mod / armor absorption reduces the value.
	const PHYSICAL_DAMAGE_MIN_FLOOR := 1.0
	var actual_dmg: int = int(roundf(total_physical))
	var tissue_dmg: float = final_cut + final_blunt
	var outcome: String = "hit"
	var glancing_severity: float = -1.0
	if total_physical > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		if tissue_dmg < maxf(total_physical * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR):
			outcome = "glancing"
			var ratio_denom: float = maxf(total_physical * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR)
			glancing_severity = clampf(tissue_dmg / maxf(ratio_denom, 0.001), 0.0, 1.0)

	# Minimum physical damage floor for contact hits: prevents rounding to zero.
	var _floor_threshold: float = PHYSICAL_DAMAGE_MIN_FLOOR if outcome == "hit" else PHYSICAL_DAMAGE_MIN_FLOOR * CombatConstants.GLANCING_DAMAGE_FLOOR_RATIO
	if total_physical < _floor_threshold and outcome in ["hit", "glancing"]:
		total_physical = _floor_threshold
		actual_dmg = int(roundf(total_physical))

	# Detect when armor/tissue reduced damage to a value that rounds to zero — mark as negligible unless floors apply below.
	var rounded_zero_chip: bool = actual_dmg == 0 and total_physical > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS
	if rounded_zero_chip and outcome == "hit":
		outcome = "negligible"

	# Low-KE band enforcement: strikes below combat-realistic minimum (35J) that are fully unparried receive
	# a double-floor to ensure they never round to zero damage. Partially-parried weak strikes get the single
	# floor above, ensuring parried strikes always do <= unparried ones at equivalent KE. Glancing strikes below
	# 35J already received the 0.5 glancing floor — no additional enforcement needed (glancing by definition is reduced).
	if strike_ke_j > 0.0 and strike_ke_j < CombatDesignAnchors.COMBAT_REALISTIC_KE_J_MIN:
		if parry_remaining_ratio >= 1.0:
			var low_ke_floor: float = PHYSICAL_DAMAGE_MIN_FLOOR * 2.0
			if total_physical < low_ke_floor:
				total_physical = maxf(total_physical, low_ke_floor)
				actual_dmg = int(roundf(total_physical))
				# If outcome was "negligible" due to rounding but KE band says otherwise, upgrade to glancing.
				if outcome == "negligible":
					outcome = "glancing"
					glancing_severity = clampf(tissue_dmg / maxf(low_ke_floor * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR), 0.0, 1.0)

	var tgt_entity: Node = CombatantEntityAccess.get_health_entity_from_node(manager, tgt_n)
	if tgt_entity == null:
		tgt_entity = tgt_n
	CombatantStatsSync.sync_from_entity(tgt_entity, CombatantEntityAccess.stats_dict_for_mutation(tgt))

	var health_after_cut: float = tgt_entity.body_cutting.get(part, 0.0)
	var health_after_blunt: float = tgt_entity.body_blunt.get(part, 0.0)
	var health_after_bone: float = tgt_entity.bone_health.get(part, 0.0) if tgt_entity.get(DataKeys.BONE_HEALTH) else 0.0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (all damage avoided)"
	elif outcome == "glancing":
		outcome_note = (
												"glancing (tissue_dmg %.2f < total_phys*%.2f=%.2f; total_phys=%.1f)"
			% [
				tissue_dmg,
				CombatConstants.GLANCING_DAMAGE_RATIO,
				total_physical * CombatConstants.GLANCING_DAMAGE_RATIO,
				total_physical
			]
		)
	elif outcome == "negligible":
		outcome_note = "negligible (contact; phys %.4f rounds to 0 HP)" % total_physical
	elif rounded_zero_chip:
		outcome_note = "%s | sub-threshold chip (phys %.4f rounds to 0)" % [outcome_note, total_physical]

	var total_disp: String = str(actual_dmg)
	if rounded_zero_chip:
		total_disp = "0 (~%.3f phys)" % total_physical
	elif absf(total_physical - float(actual_dmg)) > 0.01:
		total_disp = "%d (phys %.3f)" % [actual_dmg, total_physical]

	if CombatConstants.combat_debug_active():
		var depth_extra: String = ""
		if (
			CombatantEntityAccess.rank_int(atk) > 0
			and CombatMeleeRankTargeting.melee_pair_rank_allowed(manager, atk, tgt)
		):
			var cls: float = StrikePhysics.closing_speed_multiplier(manager, atk, tgt, strike_physics_ctx)
			var lane_lbl: String = strike_physics_ctx.get(DataKeys.PA_DEPTH_POLEARM_LANE, "")
			if lane_lbl.is_empty():
				lane_lbl = "-"
			depth_extra = (
																" | depth_polearm rank=%d lane=%s closing_spd=%.3f tgt_angle=%s"
				% [CombatantEntityAccess.rank_int(atk), lane_lbl, cls, str(tgt.get(DataKeys.PA_ENGAGEMENT_ANGLE, "?"))]
			)
		var hit_line: String = (
												"[Combat] %s (%s) -> %s (%s) %s | cut=%.2f blunt=%.2f bone=%.2f | total=%s | outcome: %s%s"
			% [
				atk_name,
				CombatantEntityAccess.side_str(atk),
				tgt_name,
				CombatantEntityAccess.side_str(tgt),
				part,
				final_cut,
				final_blunt,
				final_bone,
				total_disp,
				outcome_note,
				depth_extra
			]
		)
		if CombatConstants.COMBAT_DEBUG_CALIBRATION:
			CombatDebug.combat_session(hit_line)

	var result_dict: Dictionary = {
		"dmg": actual_dmg,
		"total_physical": total_physical,
		"died": false,
		"part": part,
		"damage_type": "SPLIT",
		"health_before_cut": health_before_cut,
		"health_after_cut": health_after_cut,
		"health_before_blunt": health_before_blunt,
		"health_after_blunt": health_after_blunt,
		"health_before_bone": health_before_bone,
		"health_after_bone": health_after_bone,
		"final_cut": final_cut,
		"final_blunt": final_blunt,
		"final_bone": final_bone,
		"outcome": outcome,
		# Armor sharp|'blunt conversion; unrelated to outcome "deflected" (no net physical chip).
		"was_deflected": take_result.get(DataKeys.ATTACK_WAS_DEFLECTED, false),
		"was_glancing": outcome == "glancing",
		"was_negligible": outcome == "negligible",
		"strike_ke_j": strike_ke_j,
		"mechanical_post_armor": take_result.get(DataKeys.RESULT_MECHANICAL_POST_ARMOR, 0.0),
		"mech_trauma_mult": take_result.get("mech_trauma_mult", 1.0),
		"mech_subregion_mult": take_result.get("mech_subregion_mult", 1.0),
		"rounded_zero_chip": rounded_zero_chip,
		"tissue_dmg": tissue_dmg,
		"pre_armor": pre_armor,
		"attack_perf": attack_perf,
	}
	result_dict[DataKeys.RESULT_DAMAGE_RESOLVE_NOTE] = CombatLogFormatter.damage_resolve_note(result_dict)
	result_dict[DataKeys.RESULT_HEALTH_BEFORE] = int(roundf(health_before_cut + health_before_blunt))
	result_dict[DataKeys.RESULT_HEALTH_AFTER] = int(roundf(health_after_cut + health_after_blunt))
	# Headless harness only: `CombatRegressionHarness` sets meta on the manager before `compute_and_apply_damage`.
	if manager != null and bool(manager.get_meta("_harness_expose_penetration_applied", false)):
		result_dict[DataKeys.RESULT_PENETRATION_SHARP_APPLIED] = pen_sharp
		result_dict[DataKeys.RESULT_PENETRATION_BLUNT_MPA_APPLIED] = pen_blunt_momentum_per_area
	if manager != null and bool(manager.get_meta("_harness_expose_damage_kinematics", false)):
		result_dict[DataKeys.RESULT_STRIKE_KE_J_APPLIED] = strike_ke_j
		result_dict[DataKeys.RESULT_BLUNT_CONTACT_CM_APPLIED] = blunt_contact_cm
		result_dict[DataKeys.RESULT_PRE_CUT_APPLIED] = pre_cut
		result_dict[DataKeys.RESULT_PRE_BLUNT_APPLIED] = pre_blunt

	if CombatantEntityAccess.is_dead(tgt):
		tgt.alive = false
		CombatFootwork.clear_on_death(tgt)
		tgt.state = CombatConstants.STATE_DEAD
		CombatStateHandlers.cancel_events_for_dead_combatant(manager, tgt)
		result_dict[DataKeys.RESULT_DIED] = true
		var death_reason: String = CombatantEntityAccess.get_death_reason(tgt)
		result_dict["death_reason"] = death_reason
		# F5: `hit_resolve` + combat log carry strike outcome; skip redundant DEATH line.
		# Tuning duel defers the line to `action_resolved` so the killing strike's HEMA line prints first.
		var defer_death_log: bool = manager != null and bool(manager.get_meta("_tuning_defer_death_log", false))
		if not (OperationalLog.is_play_session_active() and CombatConstants.combat_hit_summary_active()) and not defer_death_log:
			# Compact stable token on the always-on line; verbose numeric reason is calibration-only.
			var dr: String = death_reason.to_lower()
			var death_token: String = "BLEED_OUT" if dr.begins_with("blood_loss") else ("VITAL_DESTROYED" if (dr.begins_with("vital_part_destroyed") or dr.begins_with("vital_part_zero")) else "OTHER")
			if CombatDebug.dc_trace_active():
				CombatDebug.combat_session("DEATH %s -- %s" % [tgt_name, death_reason])
			else:
				CombatDebug.combat_session("DEATH %s -- %s" % [tgt_name, death_token])

	var rec_dur: float = CombatTiming.recovery_duration(
		intensity,
		outcome,
		recovery_mult,
		perf_mod,
		atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE),
		glancing_severity
	)
	# Tactical breathing / pacing offset: deliberate wind-up beyond optimal reduces post-strike recovery.
	## Models HEMA principle of taking time between actions to breathe and reset rather than rushing.
	var attacker_wind_up_s: float = float(pa.get(DataKeys.PA_WIND_UP_DURATION, 0.0))
	if attacker_wind_up_s > CombatTiming.WIND_UP_FACTOR_OPTIMAL_S:
		rec_dur = CombatTiming.apply_tactical_breathing_offset(attacker_wind_up_s, rec_dur)
	return {"result_dict": result_dict, "outcome": outcome, "recovery_duration": rec_dur}


## Full attack resolution: miss, dodge, parry (deflect/partial), or hit.
## Manager must have: _get_by_id, STATE_*; timing uses CombatTiming.
## _get_passive_parry_readiness, _is_off_balance, MISS_CHANCE_BASE, HIT_CHANCE_*, COMMITMENT_FRACTION, PARRY_*, etc.
## Returns { "action": String, "target_id": int, "result_dict": {}, "recovery_duration": float, "outcome": String }.
## Weighted roll for diagonal C: pick attack_line from weights dict (line -> weight).
static func _weighted_roll_attack_line(weights: Dictionary) -> String:
	var total: float = 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return "high"
	var r: float = randf() * total
	for line in weights:
		r -= float(weights[line])
		if r <= 0.0:
			return line
	return weights.keys()[0] if not weights.is_empty() else "high"


## For parry_partial, mutates atk.pending_attack["velocity_m_s"] and defense sets **`parry_clash_context`** on the
## result dict; **`AttackResultApplier`** emits **`action_resolved`** then re-enters **`_execute_attack`** for
## follow-through.
## Follow-through re-resolve keeps first-contact **`attack_angle_deg`** / **`arc_end_deg`** / **`arc_span_deg`** /
## **`effective_attack_line`** when **`passive_parry_attempted`** is already set (see
## **`stamp_resolve_angle_geometry_on_pa`**).
static func stamp_resolve_angle_geometry_on_pa(
	pa: Dictionary, atk: Dictionary, atk_line_base: String, move_def_pre: Dictionary, arc_start_deg: float
) -> void:
	if pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		pa[DataKeys.PA_POSITION_ANGLE_OFFSET_DEG] = CombatFootwork.get_attacker_offset_deg(atk)
		return
	var var_ctx: Dictionary = {}
	var_ctx[DataKeys.VAR_CTX_STAMINA_RATIO] = CombatantEntityAccess.stamina_ratio(atk)
	# Store off-balance depth (0.0-1.0) so angle variance fades proportionally as the attacker
	# re-establishes balance. A bool here would keep the full +35% scatter for the whole window.
	var_ctx[DataKeys.VAR_CTX_OFF_BALANCE] = PassiveParryContext.off_balance_depth(atk)
	var atk_weapon = CombatantEntityAccess.get_weapon(atk)
	var_ctx[DataKeys.VAR_CTX_WEAPON_MASS_KG] = (
		float(atk_weapon.mass)
		if atk_weapon != null and (atk_weapon.get(DataKeys.WEAPON_MASS) is float or atk_weapon.get(DataKeys.WEAPON_MASS) is int)
		else CombatConstants.ANGLE_VARIANCE_MASS_REFERENCE_KG
	)
	pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG] = CombatConstants.get_attack_angle_deg(atk_line_base, true, move_def_pre, var_ctx)
	pa[DataKeys.PA_ARC_END_DEG] = pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG]
	pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG] = CombatFootwork.apply_offset_to_angle_deg(pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG], atk)
	pa[DataKeys.PA_POSITION_ANGLE_OFFSET_DEG] = CombatFootwork.get_attacker_offset_deg(atk)
	pa[DataKeys.PA_ARC_SPAN_DEG] = CombatConstants.angle_diff_deg(arc_start_deg, pa[DataKeys.ATTACK_ATTACK_ANGLE_DEG])


## Representative swing kinetic energy (J) for a committed swing, from the swing's intensity-derived
## velocity and the weapon's strike mass. Used to scale the attacker's own off-balance on a whiff: a
## heavier/faster swing over-extends the body more than a light probe. Intentionally omits the
## closing-speed/fatigue/economy modifiers the hit path layers on — for a bounded whiff penalty the
## base swing energy is a clean, monotonic proxy. Returns -1.0 when no KE is derivable so the impulse
## multiplier stays neutral (never fabricates a discount or extension).
static func _swing_kinetic_energy_j(weapon, intensity: float, archetype: Dictionary, move_id: String) -> float:
	if weapon == null:
		return -1.0
	var wi: RefCounted = AttackInstance.new(move_id, intensity)
	wi.archetype = archetype
	wi.velocity_m_s = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, archetype, weapon, move_id)
	return WeaponDamageHelper.compute_kinetic_energy_j(weapon, wi)


static func resolve_attack(manager: Node, attacker_id: int) -> Dictionary:
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
	if pa.is_empty():
		return {"action": "skip", "target_id": -1, "recovery_duration": 0.0}
	var target_id: int = pa.target_id
	var intensity: float = pa.intensity
	var attack_type: String = pa.get(DataKeys.ATTACK_ATTACK_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
	var archetype: Dictionary = CombatantEntityAccess.nested_dictionary_read(pa, "archetype")
	var velocity_override: float = pa.get(DataKeys.ATTACK_VELOCITY_M_S, -1.0)
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or not CombatantEntityAccess.alive_bool(tgt):
		return {"action": "skip", "target_id": target_id, "recovery_duration": 0.0}
	var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
	var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
	var atk_stats := CombatantEntityAccess.stats_dict(atk)
	CombatDebug.log("attack %s -> %s %s" % [atk_name, tgt_name, attack_type])

	var recovery_mult: float = archetype.get(DataKeys.ATK_MOD_RECOVERY_MULTIPLIER, 1.0)
	var atk_perf_mod: float = CombatantEntityAccess.get_performance_modifier(atk)
	if CombatantEntityAccess.get_attacking_arm(atk).is_empty():
		var rec_dur_skip: float = CombatTiming.recovery_duration(
			intensity,
			"hit",
			recovery_mult,
			atk_perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		# Fires every time a fighter with a destroyed arm resolves an attack (potentially many times per fight).
		# The INCAPACITATED/cowering lines already announce the arm loss once; gate the repeat behind calibration.
		if CombatDebug.dc_trace_active():
			CombatDebug.combat_session(
				(
					"%s has no functional arm; skips attack. intensity=%.2f => recovery=%.2fs"
					% [atk_name, intensity, rec_dur_skip]
				)
			)
		return {"action": "skip", "target_id": target_id, "recovery_duration": rec_dur_skip}

	var targetable: Array = CombatantEntityAccess.get_targetable_parts(tgt)
	if targetable.is_empty():
		return {"action": "defeated", "target_id": target_id}
	CombatStrikeStamping.stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)
	var n_targetable_before: int = targetable.size()
	targetable = CombatDepthPolearm.depth_polearm_targetable_parts_filter(manager, atk, targetable, pa)
	if (
		CombatDebug.flow_verbose_enabled()
		and pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false)
		and targetable.size() < n_targetable_before
	):
		var dens_log: String = str(pa.get(DataKeys.STRIKE_CTX_ZONE_GEOMETRY_ATK_DENSITY, "normal"))
		CombatDebug.flow_log(
			(
																"depth_polearm_resolve_parts atk=%d tgt=%d dens=%s parts=%s"
				% [attacker_id, target_id, dens_log, str(targetable)]
			),
			"depth_polearm_resolve:%d:%d" % [attacker_id, target_id]
		)
	if targetable.is_empty():
		return {"action": "defeated", "target_id": target_id}

	var atk_wep: Variant = CombatantEntityAccess.get_weapon(atk)
	if (
		CombatantEntityAccess.weapon_has_attack_types(atk_wep)
		and not CombatMeleeListing.can_melee_threaten(manager, atk, tgt, pa)
	):
		TacticalCombat.record_invalid_melee_resolve_blocked(manager)
		var rec_geom: float = CombatTiming.recovery_duration(
			intensity,
			"miss",
			recovery_mult,
			atk_perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		CombatDebug.log("abort resolve: can_melee_threaten false atk=%d tgt=%d" % [attacker_id, target_id])
		return {"action": "skip", "target_id": target_id, "recovery_duration": rec_geom}

	# G1: stamp strike realism (measure ratio + move contact type) BEFORE the miss roll so the
	# overextension penalty (measure_ratio > 1.0) actually degrades hit chance. Pair eff dist was
	# stamped above by stamp_attack_pair_geometry_on_dict.
	CombatStrikeStamping.stamp_strike_realism_on_pa(manager, atk, tgt, pa, atk_wep, attack_type)

	var perf_mod: float = CombatantEntityAccess.get_hit_chance_performance_modifier(atk)
	# Apply cumulative pain degradation — sustained multi-region pain causes progressive cognitive decline.
	if not atk.is_empty():
		var node: Node = CombatantEntityAccess.scene_node(atk)
		if node != null and node.has_method("_get_vital_parts"):
			var pain_deg: float = EntityPainConsciousness.get_cumulative_pain_degradation(node)
			# Cumulative pain degrades hit chance by up to 15% at maximum sustained pain.
			perf_mod *= maxf(CombatConstants.PERF_MOD_MIN, 1.0 - pain_deg * CombatConstants.PAIN_HIT_CHANCE_DEGRADATION_MAX)
	var perception_factor: float = clampf(
		float(atk_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE)) / 100.0,
		CombatConstants.HIT_CHANCE_PERCEPTION_MIN,
		CombatConstants.HIT_CHANCE_PERCEPTION_MAX
	)
	var melee_skill_factor: float = clampf(
		CombatantEntityAccess.melee_skill_value(atk) / 100.0,
		CombatConstants.MELEE_SKILL_HIT_FACTOR_MIN,
		CombatConstants.MELEE_SKILL_HIT_FACTOR_MAX
	)
	var measure_ratio: float = pa.get(DataKeys.PA_STRIKE_MEASURE_RATIO, 1.0)
	# Over-extension (ratio > 1.0): attacker's weapon is longer than the gap — over-committed, poor
	# follow-through angle. No penalty against unarmed defenders: reach vs unopposed space should not hurt.
	var measure_hit_mult: float = 1.0
	if measure_ratio > 1.0 and CombatantEntityAccess.has_weapon(tgt):
		measure_hit_mult = lerp(1.0, CombatConstants.MEASURE_HIT_CHANCE_FLOOR, clampf((measure_ratio - 1.0) * CombatConstants.MEASURE_PENALTY_RAMP_PER_UNIT, 0.0, 1.0))
	elif measure_ratio < 1.0:
		# Under-reach (out of measure): target lies beyond the attacker's natural reach — a "half-step"
		# strike that cannot generate full speed or clean angle. Milder than over-extension (0.80 vs 0.55
		# floor) because under-reach is recoverable by committing harder. No weapon gate: this is the
		# attacker's own reach vs distance, independent of target armament.
		var under_t: float = clampf((1.0 - measure_ratio) / maxf(0.001, 1.0 - CombatConstants.STRIKE_MEASURE_RATIO_MIN), 0.0, 1.0)
		measure_hit_mult = lerp(1.0, CombatConstants.MEASURE_UNDER_REACH_HIT_CHANCE_FLOOR, under_t)
	var move_def_atk: Dictionary = WeaponConstants.get_move(attack_type)
	# G2: resolve the final effective attack line BEFORE the miss roll so the shared guard alignment
	# source uses the same line that DefenseChoiceResolver parry will use. Diagonal C rolls a line
	# weighted by the defender's guard; the miss roll must not see a pre-roll default.
	var atk_line_base: String = move_def_atk.get(DataKeys.PA_ATTACK_LINE, "high")
	if (
		not pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
		and CombatConstants.DIAGONAL_WEIGHTS.has(attack_type)
	):
		var guard_line_def: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
		var weights: Variant = CombatConstants.DIAGONAL_WEIGHTS[attack_type].get(guard_line_def, {})
		if weights is Dictionary and not weights.is_empty():
			atk_line_base = _weighted_roll_attack_line(weights)
		pa[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk_line_base
	elif not pa.has(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE):
		pa[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk_line_base
	# Guard alignment modifier: stamped on pa so DefenseChoiceResolver parry shares the same source (G2).
	# Note: alignment affects parry resolution via _get_contact_geometry — it does not degrade base hit chance.
	# An attack aimed at a held guard doesn't miss more often; the defender intercepts it with a parry instead.
	var eff_atk_line: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, atk_line_base)
	var guard_align: float = CombatConstants.get_line_alignment_with_deflect(eff_atk_line, tgt, {})
	pa[DataKeys.PA_GUARD_ALIGNMENT] = guard_align
	# Proximity-weighted hit chance — close-range exchanges have higher blade engagement rates (40-60% clean hits).
	var distance_band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
	var dist_hit_mult: float = 1.0
	if distance_band == "close":
		dist_hit_mult = CombatConstants.CLOSE_RANGE_HIT_MULT
	elif distance_band == "mid":
		dist_hit_mult = CombatConstants.MID_RANGE_HIT_MULT
	var off_bal_mult: float = PassiveParryContext.off_balance_penalty_mult(atk, CombatConstants.OFF_BALANCE_HIT_CHANCE_MULT)
	# Mirror: a wobbly target is a looser, slower-to-recover one — the attacker's clean-hit rate rises
	# with the target's off-balance depth. Neutral when the target is settled (D001).
	var tgt_off_bal_mult: float = PassiveParryContext.off_balance_penalty_mult(tgt, CombatConstants.OFF_BALANCE_TARGET_HIT_CHANCE_MULT)
	var effective_hit_chance: float = (1.0 - CombatConstants.MISS_CHANCE_BASE) * perf_mod * perception_factor * melee_skill_factor * measure_hit_mult * dist_hit_mult * off_bal_mult * tgt_off_bal_mult
	effective_hit_chance = maxf(effective_hit_chance, CombatConstants.HIT_CHANCE_MIN_CAP)
	var miss_chance: float = 1.0 - effective_hit_chance
	var miss_roll: float = randf()
	if miss_roll < miss_chance:
		CombatDebug.log("miss %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])
		var rec_dur: float = CombatTiming.recovery_duration(
			intensity,
			"miss",
			recovery_mult,
			perf_mod,
			atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
		)
		var miss_ke_j: float = _swing_kinetic_energy_j(atk_wep, intensity, archetype, attack_type)
		return {"action": "miss", "target_id": target_id, "recovery_duration": rec_dur, DataKeys.RESULT_STRIKE_KE_J: miss_ke_j}
	CombatDebug.log("hit_roll %s->%s roll=%.3f" % [atk_name, tgt_name, miss_roll])

	# Angle-based: store attack_angle_deg for continuous trajectory (deflection, alignment, damage).
	# (Diagonal C effective line was resolved before the miss roll above.)
	var arc_start: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, CombatConstants.line_to_angle(atk_line_base))
	# Diagonal C may roll a different line than wind-up; keep step offset aligned with resolve line.
	if not pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		CombatFootwork.apply_attack_step_on_windup(atk, atk_line_base, target_id, manager)
	stamp_resolve_angle_geometry_on_pa(pa, atk, atk_line_base, move_def_atk, arc_start)

	var zone_mult: float = ZoneOfControl.get_engagement_parry_multiplier(manager, attacker_id, target_id)
	pa[DataKeys.PA_ZONE_ENGAGEMENT_PARRY_MULT] = zone_mult
	if zone_mult <= CombatConstants.REAR_PARRY_MOD + 0.001:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "rear"
	elif zone_mult <= CombatConstants.FLANK_PARRY_MOD + 0.001:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "flank"
	else:
		tgt[DataKeys.PA_ENGAGEMENT_ANGLE] = "front"

	# Tier 3.1 persistent facing: a flank/rear resolve leaves the defender turned toward the threat
	# for a beat. Stamp a decaying facing-turn window that piles on when already turned (capped);
	# front-on resolves (incl. D001) never stamp.
	if CombatConstants.is_feature_persistent_facing_enabled():
		var ft_angle: String = str(tgt[DataKeys.PA_ENGAGEMENT_ANGLE])
		PassiveParryContext.apply_facing_turn(tgt, ft_angle)

	TacticalCombat.stamp_surround_threat_on_pa(manager, tgt, pa)
	pa[DataKeys.PA_TACTICAL_AMBUSH_MULT] = TacticalCombat.ambush_defense_multiplier(manager, tgt)
	CombatIncomingParryChoice.stamp_parry_choice_on_pa(manager, pa, target_id, attacker_id)

	var dc: Dictionary = DefenseChoiceResolver.choose_defense(
		pa, atk, tgt, targetable, attack_type, archetype, velocity_override, manager
	)
	var defense_choice: String = dc.defense
	var can_parry_in_time: bool = dc.can_parry_in_time
	var parry_p_a: float = dc.parry_p_a
	var parry_c_d: float = dc.parry_c_d
	var parry_readiness: float = dc.parry_readiness
	var late_parry: bool = dc.late_parry
	var is_block_parry: bool = dc.is_block_parry
	var dodge_chance: float = dc.dodge_chance
	var effective_redirect: float = dc.effective_redirect
	var def_has_weapon: bool = CombatantEntityAccess.has_weapon(tgt)
	if not def_has_weapon:
		CombatDebug.log("defense %s unarmed -> %s" % [tgt_name, defense_choice])
	elif not can_parry_in_time:
		CombatDebug.log("defense %s no parry time -> %s" % [tgt_name, defense_choice])
	else:
		var parry_reason: String = "parry" if defense_choice == "parry" else "dodge"
		if late_parry:
			parry_reason = "parry (late/reflex)"
		elif (
			defense_choice == "parry"
			and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD
			and not (is_block_parry and parry_p_a <= parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO)
			and parry_p_a > parry_c_d * effective_redirect
		):
			parry_reason = "parry (desperate, dodge=%.2f)" % dodge_chance
		elif defense_choice == "dodge" and def_has_weapon:
			parry_reason = "dodge (expected better or clean avoid likely)"
		CombatDebug.log(
			(
																"defense %s -> %s block=%s p_a=%.1f c_d=%.1f"
				% [tgt_name, parry_reason, is_block_parry, parry_p_a, parry_c_d]
			)
		)

	var defense_result = DefenseResolutionHandler.resolve(
		pa,
		atk,
		tgt,
		dc,
		targetable,
		attack_type,
		intensity,
		archetype,
		velocity_override,
		recovery_mult,
		perf_mod,
		target_id,
		atk_name,
		tgt_name
	)
	if defense_result != null:
		return defense_result

	var power: float = pa.get(DataKeys.ATTACK_POWER, -1.0)
	var follow_through: float = pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, -1.0)
	var parry_remaining_ratio: float = pa.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
	var afterblow_damage_mult: float = pa.get(DataKeys.ATTACK_AFTERBLOW_DAMAGE_MULT, 1.0)
	var dmg_velocity_override: float = pa.get(DataKeys.ATTACK_VELOCITY_M_S, velocity_override)
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var atk_line: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high"))
	var guard_line: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
	var atk_angle: float = pa.get(DataKeys.ATTACK_ATTACK_ANGLE_DEG, CombatConstants.line_to_angle(atk_line))
	var wobble_hit: Dictionary = {}
	if pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false):
		var def_weapon_hit = CombatantEntityAccess.get_weapon(tgt)
		wobble_hit = CombatantEntityAccess.parry_wobble_context(def_weapon_hit, parry_readiness)
	var guard_angle: float = CombatFootwork.guard_angle_deg(tgt, wobble_hit)
	var align_ctx: Dictionary = {"attack_angle_deg": atk_angle, "guard_angle_deg": guard_angle}
	var hit_alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx, wobble_hit)
	var part: String = pa.get(DataKeys.ATTACK_PARTIAL_DODGE_PART, "")
	var intended_part: String = pa.get(DataKeys.ATTACK_TARGET_PART, "")
	var aim_reachable: bool = false
	if part.is_empty():
		# Path + guard intercept; defender_ctx and intended_part refine hit distribution. Angle-based trajectory.
		var defender_ctx: Dictionary = {
			"state": CombatantEntityAccess.state_str(tgt),
			"recovery_cause": CombatConstants.normalize_recovery_cause(tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "")),
			"passive_parry_attempted": pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
		}
		part = AttackPathResolver.resolve_hit_part(
			atk_line,
			guard_line,
			targetable,
			defender_ctx,
			intended_part,
			tgt,
			align_ctx,
			atk,
			move_def,
			pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true),
			attack_type
		)
		# Diagnostic flag: whether the aimed part sat inside the intercept segment at
		# resolve time. When false, the defender's guard/first-contact parts stood in the
		# blade path before the aim — a physical block, not a targeting error. Reuses the
		# same alignment + targetable the resolver used so the flag matches reality.
		if not intended_part.is_empty():
			var aim_alignment: float = CombatConstants.get_line_alignment_with_deflect(
				atk_line, tgt, align_ctx
			)
			var aim_segment: Array = AttackPathResolver.path_segment_for_strike(
				atk_line, guard_line, targetable, aim_alignment, align_ctx
			)
			aim_reachable = aim_segment.has(intended_part)
			if aim_reachable:
				# An interposing guard arm earlier in the path means the blade meets the
				# guard first — a physical block, not a targeting error. The segment
				# preserves path order, so a lower index for the arm is "before the aim".
				var interpose: Dictionary = CombatGuardLines.arm_interpose_eval(
					atk_line, guard_line, aim_alignment, targetable
				)
				var interpose_arm: String = str(interpose.get(DataKeys.INTERPOSE_ARM, ""))
				if interpose_arm != "" and aim_segment.has(interpose_arm):
					if aim_segment.find(interpose_arm) < aim_segment.find(intended_part):
						aim_reachable = false
		if part.is_empty():
			part = BodyPartConstants.get_weighted_random_part(targetable)
	atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
	atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
	atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
	atk[DataKeys.PA_GAUGE_ATK_PRE] = pa.get(DataKeys.PA_GAUGE_ATK_PRE, 0.0)
	atk[DataKeys.PA_GAUGE_DEF_PRE] = pa.get(DataKeys.PA_GAUGE_DEF_PRE, 0.0)
	var strike_mods: Dictionary = {}
	if atk_wep != null:
		strike_mods = StrikeRealismProfile.compute_strike_modifiers(
			manager, atk, tgt, atk_wep, attack_type, intensity, archetype, hit_alignment, parry_remaining_ratio, pa
		)
	var path_intercept_idx: int = AttackPathResolver.path_intercept_max_index(
		atk_line, guard_line, hit_alignment, align_ctx
	)
	var hit_sub_region: String = CombatHitSubRegion.resolve_sub_region(
		part, atk_line, guard_line, align_ctx, attack_type, path_intercept_idx
	)
	var strike_phys_ctx: Dictionary = {
		"tactical_ambush_mult": pa.get(DataKeys.PA_TACTICAL_AMBUSH_MULT, 1.0),
		"attack_type": attack_type,
		DataKeys.PA_DEPTH_POLEARM_ATTACK: pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false),
		"depth_polearm_lane_type": pa.get(DataKeys.PA_DEPTH_POLEARM_LANE, ""),
		DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW: pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true),
		"weapon_extension_commit_fraction": CombatWeaponPosition._commit_fraction_for_weapon_extension(pa),
		"hit_sub_region": hit_sub_region,
		"hit_sub_region_seed": target_id * CombatConstantsAttackPath.HIT_SUB_REGION_SEED_MULTIPLIER + attacker_id,
	}
	AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa)
	CombatFootwork.clear_on_exchange_end(atk)
	CombatFootwork.clear_on_exchange_end(tgt)
	# Wind-up energy must be captured before pending_attack is cleared: the resolver reads it only via
	# `wind_up_factor_override`, otherwise an empty pa yields wind_up_factor(-1)=0 and zeroes strike velocity.
	var wind_up_factor_resolve: float = CombatTiming.wind_up_factor(pa.get(DataKeys.PA_WIND_UP_DURATION, -1.0))
	atk.pending_attack = {}
	var res: Dictionary = compute_and_apply_damage(
		manager,
		attacker_id,
		target_id,
		atk,
		tgt,
		part,
		intensity,
		attack_type,
		archetype,
		dmg_velocity_override,
		recovery_mult,
		perf_mod,
		power,
		follow_through,
		parry_remaining_ratio,
		afterblow_damage_mult,
		hit_alignment,
		strike_mods,
		strike_phys_ctx,
		wind_up_factor_resolve,
		measure_ratio
	)
	var rd_out: Dictionary = res.result_dict
	rd_out[DataKeys.RESULT_TARGET_PART] = intended_part
	if not intended_part.is_empty():
		rd_out[DataKeys.RESULT_AIM_REACHABLE] = aim_reachable
		rd_out[DataKeys.RESULT_HIT_ALIGNMENT] = hit_alignment
	rd_out[DataKeys.RESULT_MOVE_ID] = attack_type
	rd_out[DataKeys.RESULT_ATTACK_TYPE] = attack_type
	if str(rd_out.get(DataKeys.WD_KINEMATIC_DELIVERY, "")).is_empty() and not archetype.is_empty():
		var delivery: String = WeaponDamageHelper.kinematic_delivery(archetype, attack_type)
		if not delivery.is_empty():
			rd_out[DataKeys.RESULT_KINEMATIC_DELIVERY] = delivery
	var ent_aim: CoreEntity = CombatantEntityAccess.scene_entity(atk)
	if ent_aim != null:
		rd_out[DataKeys.AIM_PROT_TIER] = EntityProficiency.combined_aim_prof_tier(
			ent_aim, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk)
		)
		rd_out[DataKeys.PROF_OCC_MULT] = EntityProficiency.proficiency_occurrence_mult(
			ent_aim, CombatantEntityAccess.weapon_type_id(atk), CombatantEntityAccess.form_str(atk), attack_type
		)
	var strike_dmg: float = float(rd_out.get(DataKeys.RESULT_DMG, rd_out.get("dmg", 0.0)))
	_record_close_quarters_exchange(atk, tgt, strike_dmg)
	return {
		"action": "hit",
		"target_id": target_id,
		"result_dict": rd_out,
		"recovery_duration": res.recovery_duration,
		"outcome": res.outcome,
		"intensity": intensity
	}


## Check if repeated low-damage exchanges between close-quarters combatants should escalate to grappling/clinch.
## Historical basis: Fiore's dagger treatises show that blade clashes at close range quickly transition to
## body grabs and throws — real fights don't sustain 50+ exchanges of minor cuts when fighters are within
## arm-reach of each other. This implements "close quarters engagement escalation" (CQEE).
static func check_close_quarters_grapple_escalation(
	manager: Node,
	attacker_id: int,
	target_id: int,
	strike_damage: float,
	outcome: String
) -> Dictionary:
	if outcome not in ["hit", "glancing"]:
		return {}
	var dmg_val: float = strike_damage if strike_damage > 0.0 else float(strike_damage)

	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
	if atk.is_empty() or tgt.is_empty():
		return {}

	var atk_weapon_type: String = CombatantEntityAccess.weapon_type_id(atk)
	var grapple_max_dmg: float = CombatConstants.CLOSE_QUARTERS_GRAPPLE_MAX_DAMAGE_FOR_TRIGGER
	if atk_weapon_type == "DAGGER":
		grapple_max_dmg = 18.0
	if dmg_val >= grapple_max_dmg:
		return {}

	var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
	if band != CombatConstants.DISTANCE_CLOSE:
		return {}

	var now: float = CombatTiming.now_seconds()

	# Check cooldown — don't trigger grapple more than once per cooldown period.
	var atk_grap_cooldown: float = atk.get(DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN, -1.0)
	if atk_grap_cooldown > 0.0 and now < atk_grap_cooldown:
		return {}

	# Count recent exchanges between this pair (both directions).
	var exchange_count: int = _get_close_quarters_exchange_count(atk, tgt)
	var avg_damage: float = _get_close_quarters_avg_damage(atk, tgt)

	# Blade-bind escalation: if either combatant has "hard" bind pressure from parry binds, reduce strike threshold.
	var clk: float = now
	var atk_bind_state: String = CombatBindPressure.get_bind_state(atk, clk)
	var tgt_bind_state: String = CombatBindPressure.get_bind_state(tgt, clk)
	var bind_escalation: bool = (atk_bind_state == "hard" or tgt_bind_state == "hard")

	if exchange_count >= CombatConstants.CLOSE_QUARTERS_GRAPPLE_TRIGGER_STRIKE_COUNT and avg_damage <= grapple_max_dmg:
		# Trigger grappling resolution — record the escalation.
		atk[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
		tgt[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
		return {
			"outcome": "close_quarters_grapple",
			"exchange_count": exchange_count,
			"avg_damage": avg_damage,
		}

	if bind_escalation and exchange_count >= 2 and avg_damage <= grapple_max_dmg:
		atk[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
		tgt[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
		return {
			"outcome": "close_quarters_grapple",
			"exchange_count": exchange_count,
			"avg_damage": avg_damage,
			"bind_escalation": true,
		}

	return {}


static func _get_close_quarters_exchange_count(atk: Dictionary, tgt: Dictionary) -> int:
	var pair_key: String = _make_pair_key(atk, tgt)
	var exchanges: Variant = atk.get(DataKeys.CLOSE_QUARTERS_EXCHANGES, {})
	if exchanges is Dictionary and exchanges.has(pair_key):
		return int(exchanges.get("count", 0))
	return 0


static func _get_close_quarters_avg_damage(atk: Dictionary, tgt: Dictionary) -> float:
	var pair_key: String = _make_pair_key(atk, tgt)
	var exchanges: Variant = atk.get(DataKeys.CLOSE_QUARTERS_EXCHANGES, {})
	if exchanges is Dictionary and exchanges.has(pair_key):
		var data: Variant = exchanges[pair_key]
		if data is Dictionary:
			return data.get("avg_damage", 99.0)
	return 99.0


static func _record_close_quarters_exchange(atk: Dictionary, tgt: Dictionary, damage: float) -> void:
	var pair_key: String = _make_pair_key(atk, tgt)
	if not atk.has(DataKeys.CLOSE_QUARTERS_EXCHANGES):
		atk[DataKeys.CLOSE_QUARTERS_EXCHANGES] = {}
	var exchanges: Dictionary = atk[DataKeys.CLOSE_QUARTERS_EXCHANGES]

	if not exchanges.has(pair_key):
		exchanges[pair_key] = {"count": 0, "total_damage": 0.0, "avg_damage": 99.0}
	var data: Dictionary = exchanges[pair_key]
	data["count"] = int(data.get("count", 0)) + 1
	data["total_damage"] = float(data.get("total_damage", 0.0)) + damage
	if data["count"] > 0:
		data["avg_damage"] = data["total_damage"] / data["count"]


static func _make_pair_key(atk: Dictionary, tgt: Dictionary) -> String:
	var id_a: int = CombatantEntityAccess.id_int(atk)
	var id_b: int = CombatantEntityAccess.id_int(tgt)
	if id_a < id_b:
		return "%d-%d" % [id_a, id_b]
	return "%d-%d" % [id_b, id_a]
