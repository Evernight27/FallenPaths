class_name CombatRegressionHarnessKinematicTail
extends RefCounted

## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"


static func run(failures: PackedStringArray) -> void:
	_run_kinematic_delivery_line_to_angle_unknown_line_returns_zero(failures)
	_run_kinematic_delivery_guard_wobble_heavy_mass_increases_spread(failures)
	_run_kinematic_delivery_strike_momentum_mult_integration_pre_blunt_not_pen(failures)
	_run_kinematic_delivery_low_striker_stamina_lowers_strike_ke(failures)
	_run_kinematic_delivery_get_attack_path_all_line_pairs_nonempty(failures)
	_run_kinematic_delivery_near_full_parry_respects_min_cut_ratio_floor(failures)
	_run_kinematic_delivery_discrete_line_alignment_matches_with_deflect_no_angles(failures)
	_run_kinematic_delivery_mixed_archetype_integration_ke_matches_helper(failures)
	_run_kinematic_delivery_angle_diff_symmetry_and_zero(failures)
	_run_kinematic_delivery_closing_speed_engagement_angle_scales_strike_ke(failures)
	_run_kinematic_delivery_armored_chest_reduces_tissue_and_reports_mech_post_armor(failures)
	_run_kinematic_delivery_unarmed_pre_blunt_matches_helper(failures)
	_run_kinematic_delivery_unarmed_partial_parry_scales_pre_blunt(failures)
	_run_kinematic_delivery_depth_polearm_thrust_ctx_scales_strike_ke(failures)
	_run_kinematic_delivery_tactical_ambush_mult_scales_strike_ke(failures)
	_run_kinematic_delivery_gambeson_and_cuirass_chest_both_below_bare(failures)
	_run_kinematic_delivery_depth_polearm_allows_low_false_no_closing_boost(failures)


static func _run_kinematic_delivery_line_to_angle_unknown_line_returns_zero(
	failures: PackedStringArray
) -> void:
	if absf(CombatConstants.line_to_angle("__invalid__")) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"kin_line_to_angle: unknown line want 0 got %.4f"
			% CombatConstants.line_to_angle("__invalid__")
		)


static func _run_kinematic_delivery_guard_wobble_heavy_mass_increases_spread(
	failures: PackedStringArray
) -> void:
	var defender: Dictionary = {"guard_line": "high"}
	var ctx_low: Dictionary = {"parry_readiness": 0.0, "defender_mass_kg": 0.5}
	var ctx_heavy: Dictionary = {"parry_readiness": 0.0, "defender_mass_kg": 2.5}
	seed(44006)
	var light: float = CombatConstants.get_guard_angle_deg(defender, ctx_low)
	seed(44006)
	var heavy: float = CombatConstants.get_guard_angle_deg(defender, ctx_heavy)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if CombatConstants.angle_diff_deg(heavy, light) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_wobble_mass: heavy mass should shift angle vs light (light=%.4f heavy=%.4f)"
			% [light, heavy]
		)


static func _kin_striker_stamina_strike_ke_sample(stamina_ratio: float) -> float:
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	atk["stamina"] = CombatConstants.STAMINA_MAX * clampf(stamina_ratio, 0.0, 1.0)
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		"oberhau",
		{"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
		11.0,
		1.0,
		1.0,
		-1.0,
		-1.0,
		1.0,
		1.0,
		1.0,
		{},
		{}
	)
	var ke: float = float(res.get("result_dict", {}).get("strike_ke_j_applied", -1.0))
	CombatRegressionHarness._free_manager(m)
	return ke


static func _run_kinematic_delivery_low_striker_stamina_lowers_strike_ke(
	failures: PackedStringArray
) -> void:
	var ke_full: float = _kin_striker_stamina_strike_ke_sample(1.0)
	var ke_low: float = _kin_striker_stamina_strike_ke_sample(0.05)
	if ke_full <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_striker_stam: full ke too small %.4f" % ke_full)
	if ke_low >= ke_full - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"kin_striker_stam: low stamina should reduce ke (full=%.4f low=%.4f)"
			% [ke_full, ke_low]
		)


static func _run_kinematic_delivery_strike_momentum_mult_integration_pre_blunt_not_pen(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.32
	var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {"strike_momentum_mult": mult}
	)
	CombatRegressionHarness._free_manager(base["mgr"] as Node)
	CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
	if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_mom_mult_int: pre_blunt ratio %.4f want %.4f"
			% [float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
		)
	if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_mom_mult_int: blunt mpa ratio %.4f want %.4f"
			% [float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
		)
	if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
		CombatRegressionHarness._fail(failures, "kin_mom_mult_int: pre_cut should ignore strike_momentum_mult")
	if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
		CombatRegressionHarness._fail(failures, "kin_mom_mult_int: pen_sharp should ignore strike_momentum_mult")


static func _run_kinematic_delivery_get_attack_path_all_line_pairs_nonempty(
	failures: PackedStringArray
) -> void:
	for atk_ln in ["high", "right", "low", "left"]:
		for guard_ln in ["high", "right", "low", "left"]:
			var path: Array = CombatConstants.get_attack_path(atk_ln, guard_ln)
			if path.is_empty():
				CombatRegressionHarness._fail(
					failures,
					"kin_attack_path_pairs: empty path atk=%s guard=%s" % [atk_ln, guard_ln]
				)


static func _run_kinematic_delivery_near_full_parry_respects_min_cut_ratio_floor(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const parry_graze: float = 0.05
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var grazed: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, parry_graze, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var weapon: Weapon = _EntityAccess.get_weapon(clean["atk"] as Dictionary) as Weapon
	CombatRegressionHarness._free_manager(clean["mgr"] as Node)
	CombatRegressionHarness._free_manager(grazed["mgr"] as Node)
	if weapon == null:
		CombatRegressionHarness._fail(failures, "kin_cut_floor: missing weapon")
		return
	var base_cr: float = WeaponDamageHelper.get_cut_ratio(weapon, "oberhau", arch)
	var exp_cr: float = maxf(
		WeaponConstants.MIN_CUT_RATIO,
		base_cr - CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_graze)
	)
	var ratio_cut: float = float(grazed["pre_cut"]) / maxf(float(clean["pre_cut"]), 0.001)
	var want_ratio: float = exp_cr / maxf(base_cr, 0.001)
	if absf(ratio_cut - want_ratio) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_cut_floor: pre_cut ratio %.4f want %.4f (base_cr=%.4f exp_cr=%.4f)"
			% [ratio_cut, want_ratio, base_cr, exp_cr]
		)


static func _run_kinematic_delivery_discrete_line_alignment_matches_with_deflect_no_angles(
	failures: PackedStringArray
) -> void:
	var defender: Dictionary = {"guard_line": "right"}
	for atk_ln in ["high", "low", "left"]:
		var want: float = CombatConstants.get_line_alignment(atk_ln, "right")
		var got: float = CombatConstants.get_line_alignment_with_deflect(atk_ln, defender, {}, {})
		if absf(got - want) > 0.0001:
			CombatRegressionHarness._fail(
				failures,
				"kin_discrete_align: %s vs right want %.6f got %.6f" % [atk_ln, want, got]
			)


static func _run_kinematic_delivery_mixed_archetype_integration_ke_matches_helper(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var arch: Dictionary = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.35,
	}
	var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var m: Node = sample["mgr"] as Node
	var atk: Dictionary = sample["atk"] as Dictionary
	var tgt: Dictionary = sample["tgt"] as Dictionary
	var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
	var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
		m, atk, tgt, float(sample["intensity"]), arch, "oberhau", vo_pin, 1.0
	)
	var ai: AttackInstance = AttackInstance.new("oberhau", float(sample["intensity"]))
	ai.archetype = arch
	ai.velocity_m_s = v_asm
	var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
	CombatRegressionHarness._free_manager(m)
	if absf(float(sample["strike_ke_j"]) / ke_want - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_mixed_int: strike_ke_j ratio %.4f (got=%.4f want=%.4f v=%.4f)"
			% [float(sample["strike_ke_j"]) / ke_want, float(sample["strike_ke_j"]), ke_want, v_asm]
		)


static func _run_kinematic_delivery_angle_diff_symmetry_and_zero(
	failures: PackedStringArray
) -> void:
	if CombatConstants.angle_diff_deg(80.0, 200.0) != CombatConstants.angle_diff_deg(200.0, 80.0):
		CombatRegressionHarness._fail(failures, "kin_angle_sym: angle_diff should be symmetric")
	if CombatConstants.angle_diff_deg(12.0, 12.0) > 0.0001:
		CombatRegressionHarness._fail(failures, "kin_angle_sym: identical angles want 0 diff")
	if CombatConstants.get_alignment_from_angles(33.0, 33.0) < 0.999:
		CombatRegressionHarness._fail(failures, "kin_angle_sym: identical angles want align 1")


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** — target **`engagement_angle`** rear > flank > front scales exposed **`strike_ke_j`** (~**v²**).
static func _run_kinematic_delivery_closing_speed_engagement_angle_scales_strike_ke(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var front: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
	)
	var flank: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "flank"}
	)
	var rear: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "rear"}
	)
	var ke_front: float = float(front["strike_ke_j"])
	var ke_flank: float = float(flank["strike_ke_j"])
	var ke_rear: float = float(rear["strike_ke_j"])
	var cls_front: float = _StrikePhysics.closing_speed_multiplier(
		front["mgr"] as Node, front["atk"] as Dictionary, front["tgt"] as Dictionary, {}
	)
	var cls_rear: float = _StrikePhysics.closing_speed_multiplier(
		rear["mgr"] as Node, rear["atk"] as Dictionary, rear["tgt"] as Dictionary, {}
	)
	CombatRegressionHarness._free_manager(front["mgr"] as Node)
	CombatRegressionHarness._free_manager(flank["mgr"] as Node)
	CombatRegressionHarness._free_manager(rear["mgr"] as Node)
	if ke_front <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_close_ang: front strike_ke too small %.4f" % ke_front)
	if ke_flank <= ke_front + 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_ang: flank ke %.4f should exceed front %.4f" % [ke_flank, ke_front]
		)
	if ke_rear <= ke_flank + 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_ang: rear ke %.4f should exceed flank %.4f" % [ke_rear, ke_flank]
		)
	var ratio_ke: float = ke_rear / maxf(ke_front, 0.001)
	var ratio_want: float = (cls_rear / maxf(cls_front, 0.001)) ** 2.0
	if absf(ratio_ke - ratio_want) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_ang: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls front=%.4f rear=%.4f)"
			% [ratio_ke, ratio_want, cls_front, cls_rear]
		)


## Tier 5.1 (optional long-tail): chest **CUIRASS** — **`mechanical_post_armor` > 0**; tissue chip below unarmored at same pinned **`vo`**.
static func _run_kinematic_delivery_armored_chest_reduces_tissue_and_reports_mech_post_armor(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var bare: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var armored: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "CUIRASS"
	)
	var tissue_bare: float = float(bare["final_cut"]) + float(bare["final_blunt"])
	var tissue_arm: float = float(armored["final_cut"]) + float(armored["final_blunt"])
	var mech_arm: float = float(armored["mechanical_post_armor"])
	CombatRegressionHarness._free_manager(bare["mgr"] as Node)
	CombatRegressionHarness._free_manager(armored["mgr"] as Node)
	if mech_arm <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		CombatRegressionHarness._fail(
			failures,
			"kin_armor_chest: mechanical_post_armor want > 0 got %.4f" % mech_arm
		)
	if tissue_bare <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		CombatRegressionHarness._fail(
			failures, "kin_armor_chest: unarmored fixture should chip tissue (got %.4f)" % tissue_bare
		)
	if tissue_arm >= tissue_bare - 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_armor_chest: cuirass should reduce tissue (bare=%.4f armored=%.4f mech=%.4f)"
			% [tissue_bare, tissue_arm, mech_arm]
		)


## Tier 5.1 (optional long-tail): chest **GAMBESON** and **CUIRASS** both reduce tissue vs bare; both report **`mechanical_post_armor` > 0** (relative ordering not fixed on **oberhau**).
static func _run_kinematic_delivery_gambeson_and_cuirass_chest_both_below_bare(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var bare: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var cuirass: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "CUIRASS"
	)
	var gambeson: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "GAMBESON"
	)
	var tissue_bare: float = float(bare["final_cut"]) + float(bare["final_blunt"])
	var tissue_cuir: float = float(cuirass["final_cut"]) + float(cuirass["final_blunt"])
	var tissue_gam: float = float(gambeson["final_cut"]) + float(gambeson["final_blunt"])
	var mech_cuir: float = float(cuirass["mechanical_post_armor"])
	var mech_gam: float = float(gambeson["mechanical_post_armor"])
	CombatRegressionHarness._free_manager(bare["mgr"] as Node)
	CombatRegressionHarness._free_manager(cuirass["mgr"] as Node)
	CombatRegressionHarness._free_manager(gambeson["mgr"] as Node)
	if tissue_bare <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		CombatRegressionHarness._fail(
			failures, "kin_armor_grad: bare fixture should chip (got %.4f)" % tissue_bare
		)
	for label: String in ["cuirass", "gambeson"]:
		var tissue: float = tissue_cuir if label == "cuirass" else tissue_gam
		var mech: float = mech_cuir if label == "cuirass" else mech_gam
		if mech <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			CombatRegressionHarness._fail(
				failures, "kin_armor_grad: %s mechanical_post_armor want > 0 got %.4f" % [label, mech]
			)
		if tissue >= tissue_bare - 0.5:
			CombatRegressionHarness._fail(
				failures,
				"kin_armor_grad: %s tissue %.4f should stay below bare %.4f"
				% [label, tissue, tissue_bare]
			)


static func _kin_unarmed_pre_blunt_sample(parry_r: float) -> float:
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.register(CombatRegressionHarness._new_entity_unarmed(), "player")
	m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		"punch",
		{},
		-1.0,
		1.0,
		1.0,
		-1.0,
		-1.0,
		parry_r,
		1.0,
		1.0,
		{},
		{}
	)
	var pre: float = float(res.get("result_dict", {}).get("pre_blunt_applied", -999.0))
	CombatRegressionHarness._free_manager(m)
	return pre


## Tier 5.1 (optional long-tail): unarmed **`compute_and_apply_damage`** — **`pre_blunt_applied`** matches **`unarmed_base_pre_armor`** × closing × stamina × stance (no **`strike_ke_j`**).
static func _run_kinematic_delivery_unarmed_pre_blunt_matches_helper(
	failures: PackedStringArray
) -> void:
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.register(CombatRegressionHarness._new_entity_unarmed(), "player")
	m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		"punch",
		{},
		-1.0,
		1.0,
		1.0,
		-1.0,
		-1.0,
		1.0,
		1.0,
		1.0,
		{},
		{}
	)
	var rd: Dictionary = res.get("result_dict", {}) as Dictionary
	var pre_blunt: float = float(rd.get("pre_blunt_applied", -999.0))
	var strike_ke: float = float(rd.get("strike_ke_j_applied", -999.0))
	var atk_n: Node = _EntityAccess.scene_node(atk)
	var mod: float = atk_n.get_attack_damage_modifier() if (atk_n != null and atk_n.has_method("get_attack_damage_modifier")) else 1.0
	var strength: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
	var base: float = WeaponDamageHelper.unarmed_base_pre_armor(strength, mod)
	var st_ratio: float = clampf(
		_EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var stamina_u: float = sqrt(
		lerpf(
			CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT,
			1.0,
			CombatConstants.stamina_factor(st_ratio)
		)
	)
	var closing: float = _StrikePhysics.closing_speed_multiplier(m, atk, tgt, {})
	var stance: float = CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "damage")
	var want: float = base * closing * stamina_u * stance
	CombatRegressionHarness._free_manager(m)
	if strike_ke >= 0.0:
		CombatRegressionHarness._fail(
			failures,
			"kin_unarmed: strike_ke_j should stay unset (got %.4f)" % strike_ke
		)
	if pre_blunt < 0.0:
		CombatRegressionHarness._fail(failures, "kin_unarmed: pre_blunt_applied missing")
	elif absf(pre_blunt / want - 1.0) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_unarmed: pre_blunt ratio %.4f want 1 (got=%.4f want=%.4f base=%.4f)"
			% [pre_blunt / want, pre_blunt, want, base]
		)


## Tier 5.1 (optional long-tail): unarmed partial parry — **`pre_blunt`** scales by **`lerp(0.5, 1, parry_remaining_ratio)`** before stance.
static func _run_kinematic_delivery_unarmed_partial_parry_scales_pre_blunt(
	failures: PackedStringArray
) -> void:
	const parry_half: float = 0.5
	var pre_full: float = _kin_unarmed_pre_blunt_sample(1.0)
	var pre_half: float = _kin_unarmed_pre_blunt_sample(parry_half)
	if pre_full <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_unarmed_parry: full pre_blunt too small %.4f" % pre_full)
	var want_ratio: float = lerpf(0.5, 1.0, parry_half)
	if absf(pre_half / pre_full - want_ratio) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_unarmed_parry: ratio %.4f want %.4f (full=%.4f half=%.4f)"
			% [pre_half / pre_full, want_ratio, pre_full, pre_half]
		)


## Tier 5.1 (optional long-tail): **`strike_physics_ctx`** depth-polearm open-lane stab raises **`strike_ke_j`**; cut **`attack_type`** / **`over_shoulder`** lane do not.
static func _run_kinematic_delivery_depth_polearm_thrust_ctx_scales_strike_ke(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const move_id: String = "spear_thrust"
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var neutral: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, arch
	)
	var depth_open: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SPEAR",
		move_id,
		1.0,
		arch,
		{},
		"",
		{
			"depth_polearm_attack": true,
			"attack_type": move_id,
			"depth_polearm_lane_type": "open",
		}
	)
	var depth_cut: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SPEAR",
		move_id,
		1.0,
		arch,
		{},
		"",
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_slash",
			"depth_polearm_lane_type": "open",
		}
	)
	var depth_shoulder: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SPEAR",
		move_id,
		1.0,
		arch,
		{},
		"",
		{
			"depth_polearm_attack": true,
			"attack_type": move_id,
			"depth_polearm_lane_type": "over_shoulder",
		}
	)
	var ke_neutral: float = float(neutral["strike_ke_j"])
	var ke_open: float = float(depth_open["strike_ke_j"])
	var ke_cut: float = float(depth_cut["strike_ke_j"])
	var ke_shoulder: float = float(depth_shoulder["strike_ke_j"])
	var ctx_open: Dictionary = depth_open["strike_physics_ctx"] as Dictionary
	var cls_open: float = _StrikePhysics.closing_speed_multiplier(
		depth_open["mgr"] as Node,
		depth_open["atk"] as Dictionary,
		depth_open["tgt"] as Dictionary,
		ctx_open
	)
	var cls_neutral: float = _StrikePhysics.closing_speed_multiplier(
		neutral["mgr"] as Node,
		neutral["atk"] as Dictionary,
		neutral["tgt"] as Dictionary,
		{}
	)
	CombatRegressionHarness._free_manager(neutral["mgr"] as Node)
	CombatRegressionHarness._free_manager(depth_open["mgr"] as Node)
	CombatRegressionHarness._free_manager(depth_cut["mgr"] as Node)
	CombatRegressionHarness._free_manager(depth_shoulder["mgr"] as Node)
	if ke_neutral <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_depth_close: neutral strike_ke too small %.4f" % ke_neutral)
	if ke_open <= ke_neutral + 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_close: open lane ke %.4f should exceed neutral %.4f"
			% [ke_open, ke_neutral]
		)
	if absf(ke_cut / ke_neutral - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_close: cut attack_type should not boost thrust ke (ratio %.4f)"
			% [ke_cut / ke_neutral]
		)
	if absf(ke_shoulder / ke_neutral - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_close: over_shoulder lane should not boost (ratio %.4f)"
			% [ke_shoulder / ke_neutral]
		)
	var ratio_ke: float = ke_open / maxf(ke_neutral, 0.001)
	var ratio_want: float = (cls_open / maxf(cls_neutral, 0.001)) ** 2.0
	if absf(ratio_ke - ratio_want) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_close: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls neutral=%.4f open=%.4f)"
			% [ratio_ke, ratio_want, cls_neutral, cls_open]
		)
	if absf(cls_open - CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_close: open cls want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, cls_open]
		)


## Tier 5.1 (optional long-tail): **`strike_physics_ctx.tactical_ambush_mult`** at cap raises **`strike_ke_j`** (~**v²**); **≤ 1** unchanged.
static func _run_kinematic_delivery_tactical_ambush_mult_scales_strike_ke(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const amb_cap: float = 1.12
	var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var ambush: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SWORD",
		"oberhau",
		1.0,
		{},
		{},
		"",
		{"tactical_ambush_mult": amb_cap}
	)
	var ke_plain: float = float(plain["strike_ke_j"])
	var ke_amb: float = float(ambush["strike_ke_j"])
	var cls_plain: float = _StrikePhysics.closing_speed_multiplier(
		plain["mgr"] as Node, plain["atk"] as Dictionary, plain["tgt"] as Dictionary, {}
	)
	var cls_amb: float = _StrikePhysics.closing_speed_multiplier(
		ambush["mgr"] as Node,
		ambush["atk"] as Dictionary,
		ambush["tgt"] as Dictionary,
		{"tactical_ambush_mult": amb_cap}
	)
	CombatRegressionHarness._free_manager(plain["mgr"] as Node)
	CombatRegressionHarness._free_manager(ambush["mgr"] as Node)
	if ke_plain <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_ambush: plain strike_ke too small %.4f" % ke_plain)
	if ke_amb <= ke_plain + 0.25:
		CombatRegressionHarness._fail(
			failures,
			"kin_ambush: ambush ke %.4f should exceed plain %.4f" % [ke_amb, ke_plain]
		)
	var ratio_ke: float = ke_amb / maxf(ke_plain, 0.001)
	var ratio_want: float = (cls_amb / maxf(cls_plain, 0.001)) ** 2.0
	if absf(ratio_ke - ratio_want) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_ambush: ke ratio %.4f want ~(cls ratio)^2 %.4f (cls plain=%.4f amb=%.4f)"
			% [ratio_ke, ratio_want, cls_plain, cls_amb]
		)


## Tier 5.1 (optional long-tail): depth-polearm stab with **`depth_polearm_allows_low_targets` false** and non-open lane ⇒ no closing boost; default **true** still boosts.
static func _run_kinematic_delivery_depth_polearm_allows_low_false_no_closing_boost(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const move_id: String = "spear_thrust"
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var neutral: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, arch
	)
	var no_low: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SPEAR",
		move_id,
		1.0,
		arch,
		{},
		"",
		{
			"depth_polearm_attack": true,
			"attack_type": move_id,
			"depth_polearm_lane_type": "",
			"depth_polearm_allows_low_targets": false,
		}
	)
	var allow_low: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{},
		"SPEAR",
		move_id,
		1.0,
		arch,
		{},
		"",
		{
			"depth_polearm_attack": true,
			"attack_type": move_id,
			"depth_polearm_lane_type": "",
			"depth_polearm_allows_low_targets": true,
		}
	)
	var ke_neutral: float = float(neutral["strike_ke_j"])
	var ke_no_low: float = float(no_low["strike_ke_j"])
	var ke_allow: float = float(allow_low["strike_ke_j"])
	CombatRegressionHarness._free_manager(neutral["mgr"] as Node)
	CombatRegressionHarness._free_manager(no_low["mgr"] as Node)
	CombatRegressionHarness._free_manager(allow_low["mgr"] as Node)
	if ke_neutral <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_depth_allow_low: neutral ke too small %.4f" % ke_neutral)
	if absf(ke_no_low / ke_neutral - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_allow_low: allows_low false want neutral ratio (got %.4f / %.4f = %.4f)"
			% [ke_no_low, ke_neutral, ke_no_low / ke_neutral]
		)
	if ke_allow <= ke_neutral + 0.25:
		CombatRegressionHarness._fail(
			failures,
			"kin_depth_allow_low: default allows_low true should boost ke (neutral=%.4f allow=%.4f)"
			% [ke_neutral, ke_allow]
		)
