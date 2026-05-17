class_name CombatRegressionHarnessKinematicTail
extends RefCounted

## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _PathResolver := preload("res://combat/AttackPathResolver.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"
const _HumanSpecies := preload("res://species/human.tres")


static func _kin_fixture_vo(cfx: Dictionary, default_vo: float) -> float:
	return float(cfx.get("vo", default_vo))


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
	for cfx in CombatRegressionHarness._kin_fixtures_with_blunt_pen():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {"strike_momentum_mult": mult}, wid, move, 1.0, arch
		)
		CombatRegressionHarness._free_manager(base["mgr"] as Node)
		CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
		if float(base["pre_blunt"]) <= 0.1:
			CombatRegressionHarness._fail(failures, "%s: kin_mom_mult_int baseline pre_blunt too small" % tag)
		if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.04:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_mom_mult_int pre_blunt ratio %.4f want %.4f"
				% [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
			)
		if float(base["pen_blunt_mpa"]) > 0.0:
			if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.04:
				CombatRegressionHarness._fail(
					failures,
					"%s: kin_mom_mult_int blunt mpa ratio %.4f want %.4f"
					% [tag, float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
				)
		if float(base["pre_cut"]) > 0.1:
			if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
				CombatRegressionHarness._fail(
					failures, "%s: kin_mom_mult_int pre_cut should ignore strike_momentum_mult" % tag
				)
		if float(base["pen_sharp"]) > 0.001:
			if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
				CombatRegressionHarness._fail(
					failures, "%s: kin_mom_mult_int pen_sharp should ignore strike_momentum_mult" % tag
				)


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
	var hauberk: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "HAUBERK"
	)
	var tissue_hau: float = float(hauberk["final_cut"]) + float(hauberk["final_blunt"])
	var mech_hau: float = float(hauberk["mechanical_post_armor"])
	CombatRegressionHarness._free_manager(hauberk["mgr"] as Node)
	for label: String in ["cuirass", "gambeson", "hauberk"]:
		var tissue: float = (
			tissue_cuir if label == "cuirass" else (tissue_gam if label == "gambeson" else tissue_hau)
		)
		var mech: float = (
			mech_cuir if label == "cuirass" else (mech_gam if label == "gambeson" else mech_hau)
		)
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
	var mod: float = _EntityAccess.get_attack_damage_modifier(atk)
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
	if strike_ke > -0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_unarmed: strike_ke_j_applied should stay unset (got %.4f)" % strike_ke
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


static func _strike_physics_ctx_from_pa(pa: Dictionary, attack_type: String) -> Dictionary:
	return {
		"tactical_ambush_mult": float(pa.get("tactical_ambush_mult", 1.0)),
		"attack_type": attack_type,
		"depth_polearm_attack": bool(pa.get("depth_polearm_attack", false)),
		"depth_polearm_lane_type": str(pa.get("depth_polearm_lane_type", "")),
		"depth_polearm_allows_low_targets": bool(pa.get("depth_polearm_allows_low_targets", true)),
	}


static func _kin_strike_ke_on_manager(
	mgr: Node,
	atk: Dictionary,
	tgt: Dictionary,
	move_id: String,
	vo_pin: float,
	strike_physics_ctx: Dictionary
) -> float:
	mgr.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		mgr,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		move_id,
		arch,
		vo_pin,
		1.0,
		1.0,
		-1.0,
		-1.0,
		1.0,
		1.0,
		1.0,
		{},
		strike_physics_ctx
	)
	return float(res.get("result_dict", {}).get("strike_ke_j_applied", -999.0))


## Tier 5.1 (optional long-tail): rank-1 depth **`stamp_attack_pair_geometry_on_dict`** → **`strike_physics_ctx`** matches **`AttackResolver`**; open lane **`strike_ke_j`** matches manual ctx.
static func _run_kinematic_delivery_pa_stamp_open_lane_strike_ke_matches_manual_ctx(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const move_id: String = "spear_thrust"
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "kin_pa_stamp: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	var pa: Dictionary = {"attack_type": move_id, "tactical_ambush_mult": 1.0}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
	if not bool(pa.get("depth_polearm_attack", false)):
		CombatRegressionHarness._fail(failures, "kin_pa_stamp: depth_polearm_attack want true after stamp")
	if str(pa.get("depth_polearm_lane_type", "")) != CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN:
		CombatRegressionHarness._fail(
			failures,
			"kin_pa_stamp: lane_type want open got %s" % str(pa.get("depth_polearm_lane_type", ""))
		)
	var ctx_from_pa: Dictionary = _strike_physics_ctx_from_pa(pa, move_id)
	var manual_ctx: Dictionary = {
		"tactical_ambush_mult": 1.0,
		"depth_polearm_attack": true,
		"attack_type": move_id,
		"depth_polearm_lane_type": "open",
		"depth_polearm_allows_low_targets": true,
	}
	for key in manual_ctx:
		if ctx_from_pa.get(key) != manual_ctx.get(key):
			CombatRegressionHarness._fail(
				failures,
				"kin_pa_stamp: ctx[%s] want %s got %s"
				% [key, str(manual_ctx[key]), str(ctx_from_pa.get(key))]
			)
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var weapon: Weapon = _EntityAccess.get_weapon(depth) as Weapon
	var ke_got: float = _kin_strike_ke_on_manager(mgr, depth, enemy, move_id, vo_pin, ctx_from_pa)
	var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
		mgr, depth, enemy, 0.62, arch, move_id, vo_pin, 1.0, ctx_from_pa
	)
	var ai: AttackInstance = AttackInstance.new(move_id, 0.62)
	ai.archetype = arch
	ai.velocity_m_s = v_asm
	var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai) if weapon != null else -1.0
	CombatRegressionHarness._free_manager(mgr)
	if ke_got <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_pa_stamp: stamped ke too small %.4f" % ke_got)
	if weapon == null:
		CombatRegressionHarness._fail(failures, "kin_pa_stamp: missing spear weapon")
	elif absf(ke_got / ke_want - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_pa_stamp: strike_ke_j ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
			% [ke_got / ke_want, ke_got, ke_want, v_asm]
		)


## Tier 5.1 (optional long-tail): **`variance_context.off_balance`** widens **`get_attack_angle_deg`** spread (seeded); complements stamina-only harness in main file.
static func _run_kinematic_delivery_attack_angle_deg_variance_off_balance_spreads(
	failures: PackedStringArray
) -> void:
	seed(44007)
	var balanced: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"off_balance": false}
	)
	seed(44007)
	var off_bal: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"off_balance": true})
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if absf(balanced - off_bal) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_atk_angle_ob: off_balance should shift angle (balanced=%.4f off=%.4f)"
			% [balanced, off_bal]
		)


## Tier 5.1 (optional long-tail): heavy **`variance_context.weapon_mass_kg`** widens attack-angle spread vs reference mass (seeded).
static func _run_kinematic_delivery_attack_angle_deg_variance_weapon_mass_spreads(
	failures: PackedStringArray
) -> void:
	seed(44008)
	var ref_mass: float = CombatConstants.get_attack_angle_deg(
		"high",
		true,
		{},
		{"weapon_mass_kg": CombatConstants.ANGLE_VARIANCE_MASS_REFERENCE_KG}
	)
	seed(44008)
	var heavy: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"weapon_mass_kg": 3.0})
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if absf(ref_mass - heavy) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_atk_angle_mass: heavy mass should shift angle (ref=%.4f heavy=%.4f)"
			% [ref_mass, heavy]
		)


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** — **`tactical_ambush_mult` ≤ 1** does not raise closing (only **`amb > 1.001`** lerps toward **`_AMBUSH_CAP`**; code authoritative vs narrative “ambush cap” only).
static func _run_kinematic_delivery_tactical_ambush_mult_unity_no_boost(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var unity: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "", {"tactical_ambush_mult": 1.0}
	)
	var sub_one: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {}, "", {"tactical_ambush_mult": 0.85}
	)
	var ke_plain: float = float(plain["strike_ke_j"])
	var ke_unity: float = float(unity["strike_ke_j"])
	var ke_sub: float = float(sub_one["strike_ke_j"])
	CombatRegressionHarness._free_manager(plain["mgr"] as Node)
	CombatRegressionHarness._free_manager(unity["mgr"] as Node)
	CombatRegressionHarness._free_manager(sub_one["mgr"] as Node)
	if ke_plain <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_ambush_unity: plain strike_ke too small %.4f" % ke_plain)
	if absf(ke_unity / ke_plain - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_ambush_unity: mult=1.0 should not boost ke (ratio %.4f)"
			% [ke_unity / ke_plain]
		)
	if absf(ke_sub / ke_plain - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_ambush_unity: mult<1 should not boost ke (ratio %.4f)"
			% [ke_sub / ke_plain]
		)


## Tier 5.1 (optional long-tail): unknown **`engagement_angle`** on target ⇒ same closing multiplier as **`front`** (StrikePhysics default branch).
static func _run_kinematic_delivery_engagement_angle_unknown_matches_front(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var tgt_front: Dictionary = mgr.combatants[1].duplicate()
	tgt_front["engagement_angle"] = "front"
	var tgt_unknown: Dictionary = mgr.combatants[1].duplicate()
	tgt_unknown["engagement_angle"] = "diagonal"
	var cls_front: float = _StrikePhysics.closing_speed_multiplier(mgr, atk, tgt_front, {})
	var cls_unknown: float = _StrikePhysics.closing_speed_multiplier(mgr, atk, tgt_unknown, {})
	CombatRegressionHarness._free_manager(mgr)
	if absf(cls_unknown - cls_front) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"kin_eng_ang: unknown want front cls %.4f got %.4f"
			% [cls_front, cls_unknown]
		)


## Tier 5.1 (optional long-tail): parry **`v_intent`** on **SPEAR** **`spear_thrust`** uses thrust **`get_effective_velocity_m_s`** (not swing curve).
static func _run_kinematic_delivery_parry_v_intent_thrust_archetype(
	failures: PackedStringArray
) -> void:
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if spear == null:
		CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: missing spear")
		return
	const move_id: String = "spear_thrust"
	const intensity: float = 0.62
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var ai_derived: AttackInstance = AttackInstance.new(move_id, intensity)
	ai_derived.archetype = arch
	ai_derived.velocity_m_s = -1.0
	var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, ai_derived)
	var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, spear, move_id)
	if absf(v_eff - v_from_i) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"kin_parry_v_thrust: derived v_eff want %.6f got %.6f" % [v_from_i, v_eff]
		)
	if WeaponDamageHelper.kinematic_delivery(arch, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
		CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: explicit thrust archetype want thrust delivery")
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		CombatRegressionHarness._fail(failures, "kin_parry_v_thrust: missing sword")
		return
	var ai_cut: AttackInstance = AttackInstance.new("oberhau", intensity)
	ai_cut.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_cut.velocity_m_s = -1.0
	var v_cut: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_cut)
	if absf(v_eff - v_cut) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_parry_v_thrust: spear thrust v_eff %.4f should differ from sword oberhau %.4f"
			% [v_eff, v_cut]
		)


## Tier 5.1 (optional long-tail): **SPEAR** **`spear_thrust`** integration — **`pre_cut_applied`** ∝ **`sqrt(strike_ke_j)`** at two pinned **`velocity_override`** values.
static func _run_kinematic_delivery_thrust_integration_pre_cut_scales_sqrt_ke(
	failures: PackedStringArray
) -> void:
	const arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		9.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		14.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
	)
	var ke_lo: float = float(lo["strike_ke_j"])
	var ke_hi: float = float(hi["strike_ke_j"])
	var cut_lo: float = float(lo["pre_cut"])
	var cut_hi: float = float(hi["pre_cut"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if ke_hi <= ke_lo + 1e-4:
		CombatRegressionHarness._fail(
			failures, "kin_thrust_int: ke_hi should exceed ke_lo (lo=%.4f hi=%.4f)" % [ke_lo, ke_hi]
		)
	if cut_hi <= cut_lo + 1e-4:
		CombatRegressionHarness._fail(
			failures,
			"kin_thrust_int: pre_cut_hi should exceed pre_cut_lo (lo=%.4f hi=%.4f)" % [cut_lo, cut_hi]
		)
	var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
	var got_ratio: float = cut_hi / maxf(cut_lo, 0.001)
	if absf(got_ratio - want_ratio) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_thrust_int: pre_cut ratio %.4f want sqrt(ke) ratio %.4f"
			% [got_ratio, want_ratio]
		)


## Tier 5.1 (optional long-tail): **MACE** **`direct_blow`** integration — **`pre_blunt_applied`** rises with pinned **`velocity_override`**.
static func _run_kinematic_delivery_mace_integration_pre_blunt_rises_with_vo(
	failures: PackedStringArray
) -> void:
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		8.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		14.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
	)
	var blunt_lo: float = float(lo["pre_blunt"])
	var blunt_hi: float = float(hi["pre_blunt"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if blunt_hi <= blunt_lo + 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_mace_int: pre_blunt_hi should exceed lo (lo=%.4f hi=%.4f)" % [blunt_lo, blunt_hi]
		)


## Tier 5.1 (optional long-tail): **SPEAR** thrust integration — applied **`penetration_sharp`** ∝ **`KE^PENETRATION_EXPONENT`** at two pinned **`vo`**.
static func _run_kinematic_delivery_thrust_integration_pen_sharp_scales_ke_exponent(
	failures: PackedStringArray
) -> void:
	const arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		9.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		14.0, 1.0, 1.0, {}, "SPEAR", "spear_thrust", 1.0, arch
	)
	var ke_lo: float = float(lo["strike_ke_j"])
	var ke_hi: float = float(hi["strike_ke_j"])
	var pen_lo: float = float(lo["pen_sharp"])
	var pen_hi: float = float(hi["pen_sharp"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if ke_hi <= ke_lo + 1e-4 or pen_hi <= pen_lo + 1e-6:
		CombatRegressionHarness._fail(
			failures,
			"kin_thrust_pen: need rising ke/pen (ke lo=%.4f hi=%.4f pen lo=%.4f hi=%.4f)"
			% [ke_lo, ke_hi, pen_lo, pen_hi]
		)
	var exp: float = WeaponConstants.PENETRATION_EXPONENT
	var want_ratio: float = pow(ke_hi / maxf(ke_lo, 0.001), exp)
	var got_ratio: float = pen_hi / maxf(pen_lo, 0.001)
	if absf(got_ratio - want_ratio) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_thrust_pen: pen ratio %.4f want ke^%.2f ratio %.4f"
			% [got_ratio, exp, want_ratio]
		)


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`** — both angles ⇒ path keys from **`angle_to_nearest_line`**; hit part stays inside intercept segment.
static func _run_kinematic_delivery_resolve_hit_part_angle_path_keys(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 90.0
	const guard_deg: float = 0.0
	var align_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
	var atk_line_path: String = CombatConstants.angle_to_nearest_line(atk_deg)
	var guard_line_path: String = CombatConstants.angle_to_nearest_line(guard_deg)
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	if path.is_empty():
		CombatRegressionHarness._fail(failures, "kin_resolve_part: empty angle-based path")
		return
	var defender: Dictionary = {"guard_line": "high"}
	var align: float = CombatConstants.get_line_alignment_with_deflect("high", defender, align_ctx)
	var intercept_max: int = CombatRegressionHarness._kin_path_intercept_max_index(path, align)
	var targetable: Array = []
	for p in path:
		if p is String and not targetable.has(p):
			targetable.append(p)
	seed(44009)
	var part: String = _PathResolver.resolve_hit_part(
		"high", "high", targetable, {}, "", defender, align_ctx
	)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var allowed: Array = []
	for i in range(intercept_max + 1):
		if i < path.size():
			allowed.append(path[i])
	if part.is_empty():
		CombatRegressionHarness._fail(failures, "kin_resolve_part: empty hit part")
	elif not allowed.has(part):
		CombatRegressionHarness._fail(
			failures,
			"kin_resolve_part: part %s not in intercept segment %s (max=%d align=%.4f)"
			% [part, str(allowed), intercept_max, align]
		)
	var path_strings: Array = CombatConstants.get_attack_path("high", "high")
	if not path_strings.is_empty() and path[0] == path_strings[0]:
		CombatRegressionHarness._fail(
			failures,
			"kin_resolve_part: angle path first segment should differ from high/high (%s)"
			% str(path[0])
		)


## Tier 5.1 (optional long-tail): empty archetype on stab move — **`kinematic_delivery`** infers thrust; **`compute_and_apply_damage`** matches explicit thrust arch.
static func _run_kinematic_delivery_empty_arch_spear_thrust_infers_delivery(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const move_id: String = "spear_thrust"
	if WeaponDamageHelper.kinematic_delivery({}, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
		CombatRegressionHarness._fail(failures, "kin_infer_arch: empty arch + stab want thrust delivery")
	var explicit: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SPEAR", move_id, 1.0, {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	)
	var mgr: Node = _MgrScript.new()
	mgr.set_meta(CombatRegressionHarness._HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	mgr.set_meta(CombatRegressionHarness._HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var tgt: Dictionary = mgr.combatants[1]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		mgr,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		move_id,
		{},
		vo_pin,
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
	var ke_infer: float = float(rd.get("strike_ke_j_applied", -999.0))
	var cut_infer: float = float(rd.get("pre_cut_applied", -999.0))
	CombatRegressionHarness._free_manager(mgr)
	CombatRegressionHarness._free_manager(explicit["mgr"] as Node)
	if absf(ke_infer / float(explicit["strike_ke_j"]) - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_infer_arch: strike_ke ratio %.4f (infer=%.4f explicit=%.4f)"
			% [ke_infer / float(explicit["strike_ke_j"]), ke_infer, float(explicit["strike_ke_j"])]
		)
	if absf(cut_infer / float(explicit["pre_cut"]) - 1.0) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_infer_arch: pre_cut ratio %.4f (infer=%.4f explicit=%.4f)"
			% [cut_infer / float(explicit["pre_cut"]), cut_infer, float(explicit["pre_cut"])]
		)


## Tier 5.1 (optional long-tail): **`move_def.angle_offset_deg`** applies even when **`add_variance=false`** (seeded deterministic).
static func _run_kinematic_delivery_move_def_angle_offset_seeded_deterministic(
	failures: PackedStringArray
) -> void:
	var move_def: Dictionary = WeaponConstants.get_move("off_line_thrust")
	if float(move_def.get("angle_offset_deg", 0.0)) <= 0.0:
		CombatRegressionHarness._fail(failures, "kin_move_offset: off_line_thrust needs angle_offset_deg")
		return
	seed(44010)
	var a: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
	seed(44010)
	var b: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
	seed(44011)
	var c: float = CombatConstants.get_attack_angle_deg("high", false, move_def, {})
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if absf(a - b) > 0.0001:
		CombatRegressionHarness._fail(
			failures, "kin_move_offset: same seed want same angle (a=%.4f b=%.4f)" % [a, b]
		)
	if absf(a - c) < 0.05:
		CombatRegressionHarness._fail(
			failures, "kin_move_offset: different seed should shift angle (a=%.4f c=%.4f)" % [a, c]
		)
	var base: float = CombatConstants.line_to_angle("high")
	if absf(a - base) < 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_move_offset: offset should move angle away from line high (base=%.4f got=%.4f)"
			% [base, a]
		)


## Tier 5.1 (optional long-tail): **`velocity_override` < 0** — misaligned guard (**`alignment` 0**) does not scale applied pens (oblique branch skipped).
static func _run_kinematic_delivery_derived_velocity_misalign_skips_oblique_pen(
	failures: PackedStringArray
) -> void:
	var aligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(-1.0, 1.0, 1.0, {})
	var misaligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(-1.0, 1.0, 0.0, {})
	CombatRegressionHarness._free_manager(aligned["mgr"] as Node)
	CombatRegressionHarness._free_manager(misaligned["mgr"] as Node)
	if absf(float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]) - 1.0) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"kin_derived_misalign: sharp pen ratio %.4f want 1 (aligned=%.4f mis=%.4f)"
			% [
				float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]),
				float(aligned["pen_sharp"]),
				float(misaligned["pen_sharp"]),
			]
		)
	if absf(float(misaligned["pen_blunt_mpa"]) / float(aligned["pen_blunt_mpa"]) - 1.0) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"kin_derived_misalign: blunt mpa ratio %.4f want 1"
			% [float(misaligned["pen_blunt_mpa"]) / float(aligned["pen_blunt_mpa"])]
		)


## Tier 5.1 (optional long-tail): **MACE** integration — applied **`penetration_blunt_mpa`** rises with pinned **`velocity_override`**.
static func _run_kinematic_delivery_mace_integration_pen_blunt_mpa_rises_with_vo(
	failures: PackedStringArray
) -> void:
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		8.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		14.0, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
	)
	var pen_lo: float = float(lo["pen_blunt_mpa"])
	var pen_hi: float = float(hi["pen_blunt_mpa"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if pen_hi <= pen_lo + 1e-4:
		CombatRegressionHarness._fail(
			failures,
			"kin_mace_pen: mpa_hi should exceed lo (lo=%.4f hi=%.4f)" % [pen_lo, pen_hi]
		)


static func _kin_striker_pre_cut_sample(stamina_ratio: float) -> float:
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
	var pre: float = float(res.get("result_dict", {}).get("pre_cut_applied", -999.0))
	CombatRegressionHarness._free_manager(m)
	return pre


## Tier 5.1 (optional long-tail): low striker **`stamina`** lowers integration **`pre_cut_applied`** (same pinned **`vo`** as strike_ke tail).
static func _run_kinematic_delivery_low_striker_stamina_lowers_pre_cut(
	failures: PackedStringArray
) -> void:
	var cut_full: float = _kin_striker_pre_cut_sample(1.0)
	var cut_low: float = _kin_striker_pre_cut_sample(0.05)
	if cut_full <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_striker_pre: full pre_cut too small %.4f" % cut_full)
	if cut_low >= cut_full - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"kin_striker_pre: low stamina should reduce pre_cut (full=%.4f low=%.4f)"
			% [cut_full, cut_low]
		)


## Tier 5.1 (optional long-tail): **`move_def.angle_variance_deg`** widens attack-angle spread vs bare line (seeded).
static func _run_kinematic_delivery_move_def_angle_variance_wider_than_bare_line(
	failures: PackedStringArray
) -> void:
	var move_def: Dictionary = WeaponConstants.get_move("off_line_thrust")
	if float(move_def.get("angle_variance_deg", 0.0)) <= 0.0:
		CombatRegressionHarness._fail(failures, "kin_move_var: off_line_thrust needs angle_variance_deg")
		return
	seed(44012)
	var with_move: float = CombatConstants.get_attack_angle_deg("high", true, move_def, {"stamina_ratio": 1.0})
	seed(44012)
	var bare_line: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 1.0})
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if absf(with_move - bare_line) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_move_var: move variance should shift angle (bare=%.4f move=%.4f)"
			% [bare_line, with_move]
		)


## Tier 5.1 (optional long-tail): **`DefenseChoiceResolver.choose_defense`** — **`parry_p_a`** = **`m_a × v_intent × velocity_curve_factor(progress)`** with **`v_intent`** from **`WeaponDamageHelper.get_effective_velocity_m_s`**.
static func _run_kinematic_delivery_choose_defense_parry_p_a_matches_v_intent_formula(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_line"] = "high"
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts() if def_n != null and def_n.has_method("get_targetable_parts") else []
	)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "kin_parry_pa: targetable parts empty")
		CombatRegressionHarness._free_manager(mgr)
		return
	const attack_type: String = "oberhau"
	const intensity: float = 0.55
	const wind_up: float = 0.95
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var pa: Dictionary = {
		"attack_type": attack_type,
		"intensity": intensity,
		"wind_up_duration": wind_up,
		"tactical_ambush_mult": 1.0,
	}
	var dc: Dictionary = _DefenseChoice.choose_defense(
		pa, attacker, defender, parts, attack_type, arch, -1.0
	)
	CombatRegressionHarness._free_manager(mgr)
	if not bool(dc.get("can_parry_in_time", false)):
		CombatRegressionHarness._fail(failures, "kin_parry_pa: fixture should allow parry in time")
		return
	var atk_weapon: Weapon = _EntityAccess.get_weapon(attacker) as Weapon
	if atk_weapon == null:
		CombatRegressionHarness._fail(failures, "kin_parry_pa: missing attacker weapon")
		return
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var contact_type: String = str(move_def.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
	var m_a: float = (
		float(atk_weapon.get_striking_part_mass_kg(contact_type))
		if atk_weapon.has_method("has_parts") and atk_weapon.has_parts()
		else float(atk_weapon.mass)
	)
	var comm_frac: float = CombatConstants.commitment_fraction_for_pending_attack(pa)
	var effective_wind_up: float = wind_up * (1.0 - comm_frac)
	var reaction_time: float = _EntityAccess.get_passive_parry_reaction_time(defender)
	var parry_time: float = effective_wind_up - reaction_time
	var parry_progress: float = 1.0 - clampf(parry_time / maxf(0.001, effective_wind_up), 0.0, 1.0)
	var ai: AttackInstance = AttackInstance.new(attack_type, intensity)
	ai.archetype = arch
	ai.velocity_m_s = -1.0
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, ai)
	v_intent *= _StrikeRealism.velocity_intent_mult_from_pa(
		pa, atk_weapon, attack_type, intensity, arch
	)
	var want_pa: float = (
		m_a * v_intent * _CombatTiming.velocity_curve_factor(parry_progress)
	)
	var got_pa: float = float(dc.get("parry_p_a", 0.0))
	if got_pa <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_parry_pa: parry_p_a too small %.4f" % got_pa)
	elif absf(got_pa / want_pa - 1.0) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_parry_pa: ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f m=%.4f prog=%.4f)"
			% [got_pa / want_pa, got_pa, want_pa, v_intent, m_a, parry_progress]
		)


## Tier 5.1 (optional long-tail): rear **`engagement_angle`** × **`afterblow_damage_mult`** compose on assembled **`v`** → **`strike_ke_j`** (~**(cls × √ab)²**).
static func _run_kinematic_delivery_rear_afterblow_compose_on_strike_ke(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const ab_mult: float = 0.64
	var plain: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
	)
	var composed: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", ab_mult, {}, {"engagement_angle": "rear"}
	)
	var ke_plain: float = float(plain["strike_ke_j"])
	var ke_comp: float = float(composed["strike_ke_j"])
	var mgr_p: Node = plain["mgr"] as Node
	var mgr_c: Node = composed["mgr"] as Node
	var cls_front: float = _StrikePhysics.closing_speed_multiplier(
		mgr_p, plain["atk"] as Dictionary, plain["tgt"] as Dictionary, {}
	)
	var cls_rear: float = _StrikePhysics.closing_speed_multiplier(
		mgr_c, composed["atk"] as Dictionary, composed["tgt"] as Dictionary, {}
	)
	CombatRegressionHarness._free_manager(mgr_p)
	CombatRegressionHarness._free_manager(mgr_c)
	if ke_plain <= 1.0:
		CombatRegressionHarness._fail(failures, "kin_compose: plain strike_ke too small %.4f" % ke_plain)
	var ratio_ke: float = ke_comp / maxf(ke_plain, 0.001)
	var ratio_want: float = ((cls_rear / maxf(cls_front, 0.001)) * sqrt(ab_mult)) ** 2.0
	if absf(ratio_ke - ratio_want) > 0.07:
		CombatRegressionHarness._fail(
			failures,
			"kin_compose: ke ratio %.4f want (cls×√ab)² %.4f (cls front=%.4f rear=%.4f)"
			% [ratio_ke, ratio_want, cls_front, cls_rear]
		)


## Tier 5.1 (optional long-tail): **`get_stance_modifier(..., "damage")`** scales integration **`pre_cut_applied`** (aggressive > defensive).
static func _run_kinematic_delivery_stance_modifier_scales_pre_cut_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var mgr_a: Node = _MgrScript.new()
	mgr_a.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	mgr_a.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_a.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_a.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk_a: Dictionary = mgr_a.combatants[0]
	var tgt_a: Dictionary = mgr_a.combatants[1]
	atk_a["stance"] = CombatConstants.STANCE_AGGRESSIVE
	var res_a: Dictionary = _AttackResolver.compute_and_apply_damage(
		mgr_a,
		_EntityAccess.id_int(atk_a),
		_EntityAccess.id_int(tgt_a),
		atk_a,
		tgt_a,
		"chest",
		0.62,
		"oberhau",
		{"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
		vo_pin,
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
	var cut_agg: float = float(res_a.get("result_dict", {}).get("pre_cut_applied", -1.0))
	CombatRegressionHarness._free_manager(mgr_a)
	var mgr_d: Node = _MgrScript.new()
	mgr_d.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	mgr_d.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_d.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk_d: Dictionary = mgr_d.combatants[0]
	var tgt_d: Dictionary = mgr_d.combatants[1]
	atk_d["stance"] = CombatConstants.STANCE_DEFENSIVE
	var res_d: Dictionary = _AttackResolver.compute_and_apply_damage(
		mgr_d,
		_EntityAccess.id_int(atk_d),
		_EntityAccess.id_int(tgt_d),
		atk_d,
		tgt_d,
		"chest",
		0.62,
		"oberhau",
		{"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING},
		vo_pin,
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
	var cut_def: float = float(res_d.get("result_dict", {}).get("pre_cut_applied", -1.0))
	CombatRegressionHarness._free_manager(mgr_d)
	var stance_agg: float = CombatConstants.get_stance_modifier(CombatConstants.STANCE_AGGRESSIVE, "damage")
	var stance_def: float = CombatConstants.get_stance_modifier(CombatConstants.STANCE_DEFENSIVE, "damage")
	if cut_agg <= 0.5 or cut_def <= 0.5:
		CombatRegressionHarness._fail(
			failures, "kin_stance: pre_cut too small (agg=%.4f def=%.4f)" % [cut_agg, cut_def]
		)
	if cut_agg <= cut_def + 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_stance: aggressive pre_cut %.4f should exceed defensive %.4f"
			% [cut_agg, cut_def]
		)
	if absf(cut_agg / cut_def - stance_agg / stance_def) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_stance: pre_cut ratio %.4f want stance ratio %.4f"
			% [cut_agg / cut_def, stance_agg / stance_def]
		)


## Tier 5.1 (optional long-tail): rear **`engagement_angle`** raises integration **`pre_cut_applied`** (~√**`strike_ke_j`** ratio).
static func _run_kinematic_delivery_closing_speed_engagement_angle_scales_pre_cut(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var front: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "front"}
	)
	var rear: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, {}, {"engagement_angle": "rear"}
	)
	var cut_front: float = float(front["pre_cut"])
	var cut_rear: float = float(rear["pre_cut"])
	var ke_front: float = float(front["strike_ke_j"])
	var ke_rear: float = float(rear["strike_ke_j"])
	CombatRegressionHarness._free_manager(front["mgr"] as Node)
	CombatRegressionHarness._free_manager(rear["mgr"] as Node)
	if cut_rear <= cut_front + 0.01:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_pre: rear pre_cut %.4f should exceed front %.4f" % [cut_rear, cut_front]
		)
	var ratio_cut: float = cut_rear / maxf(cut_front, 0.001)
	var ratio_ke: float = ke_rear / maxf(ke_front, 0.001)
	if absf(ratio_cut - sqrt(ratio_ke)) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_pre: pre_cut ratio %.4f want sqrt(ke ratio) %.4f"
			% [ratio_cut, sqrt(ratio_ke)]
		)


## Tier 5.1 (optional long-tail): **SWORD** **`mixed`** **0.35** blend — integration **`pre_cut_applied`** tracks **`sqrt(strike_ke_j)`** at assembled **`v`**.
static func _run_kinematic_delivery_mixed_integration_pre_cut_scales_sqrt_ke(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var arch: Dictionary = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.35,
	}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin * 1.28, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var ke_lo: float = float(lo["strike_ke_j"])
	var ke_hi: float = float(hi["strike_ke_j"])
	var cut_lo: float = float(lo["pre_cut"])
	var cut_hi: float = float(hi["pre_cut"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
		CombatRegressionHarness._fail(failures, "kin_mixed_pre: need rising ke/pre_cut")
	var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
	var got_ratio: float = cut_hi / maxf(cut_lo, 0.001)
	if absf(got_ratio - want_ratio) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_mixed_pre: pre_cut ratio %.4f want sqrt(ke) %.4f"
			% [got_ratio, want_ratio]
		)


## Tier 5.1 (optional long-tail): **`StrikePhysics.closing_speed_multiplier`** clamps to **`_CLOSING_MAX`** even with rear + max ambush ctx.
static func _run_kinematic_delivery_closing_speed_clamps_at_ceiling(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var tgt: Dictionary = mgr.combatants[1]
	tgt["engagement_angle"] = "rear"
	var ctx: Dictionary = {"tactical_ambush_mult": 1.12}
	var cls: float = _StrikePhysics.closing_speed_multiplier(mgr, atk, tgt, ctx)
	CombatRegressionHarness._free_manager(mgr)
	if cls > 1.101:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_clamp: cls want <= ~1.10 got %.4f" % cls
		)
	if cls <= 1.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_close_clamp: rear+ambush should still boost above front baseline (got %.4f)" % cls
		)


## Tier 5.1 (optional long-tail): **`off_balance` + low `stamina_ratio`** in **`variance_context`** widen spread more than either alone (seeded).
static func _run_kinematic_delivery_variance_off_balance_and_stamina_compose(
	failures: PackedStringArray
) -> void:
	seed(44013)
	var full: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 1.0, "off_balance": false}
	)
	seed(44013)
	var stam_only: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 0.05, "off_balance": false}
	)
	seed(44013)
	var ob_only: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 1.0, "off_balance": true}
	)
	seed(44013)
	var both: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 0.05, "off_balance": true}
	)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var d_stam: float = CombatConstants.angle_diff_deg(stam_only, full)
	var d_ob: float = CombatConstants.angle_diff_deg(ob_only, full)
	var d_both: float = CombatConstants.angle_diff_deg(both, full)
	if d_both <= d_stam + 0.03 and d_both <= d_ob + 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_var_compose: both should exceed single factors (d_stam=%.4f d_ob=%.4f d_both=%.4f)"
			% [d_stam, d_ob, d_both]
		)


## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`** — guard on attack opposite line + severity ≥ threshold ⇒ opposite bind (no magnitude RNG).
static func _run_kinematic_delivery_deflected_line_opposite_severity_bind(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 0.0
	const guard_deg: float = 180.0
	const severity: float = 0.9
	var line: String = CombatConstants.get_deflected_line_from_angles(
		atk_deg, guard_deg, severity, WeaponConstants.ATTACK_TYPE_CUT, 1.0
	)
	if line != "low":
		CombatRegressionHarness._fail(
			failures,
			"kin_defl_opp: high vs low guard at severity %.2f want low got %s"
			% [severity, line]
		)
	var below: String = CombatConstants.get_deflected_line_from_angles(
		atk_deg,
		guard_deg,
		CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.05,
		WeaponConstants.ATTACK_TYPE_CUT,
		1.0
	)
	if below == "low":
		CombatRegressionHarness._fail(
			failures,
			"kin_defl_opp: sub-threshold severity should not bind to opposite (got low)"
		)


static func _kin_entity_with_human_species(weapon_id: String) -> CoreEntity:
	var e: CoreEntity = CombatRegressionHarness._new_entity(weapon_id)
	if e.species == null:
		e.species = _HumanSpecies
		e.apply_species()
	return e


static func _kin_dmg_sample_on_part(
	part: String,
	vo: float,
	weapon_id: String,
	move_id: String,
	arch: Dictionary
) -> Dictionary:
	var m: Node = _MgrScript.new()
	m.set_meta(CombatRegressionHarness._HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.set_meta(CombatRegressionHarness._HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
	m.register(_kin_entity_with_human_species(weapon_id), "player")
	m.register(_kin_entity_with_human_species(weapon_id), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		part,
		0.62,
		move_id,
		arch,
		vo,
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
	return {
		"mgr": m,
		"tgt": tgt,
		"pre_blunt": float(rd.get("pre_blunt_applied", -999.0)),
		"pre_cut": float(rd.get("pre_cut_applied", -999.0)),
	}


## Tier 5.1 (optional long-tail): **`effective_blunt_target_mass_kg`** — **MACE** **`direct_blow`** **`pre_blunt_applied`** differs on **head** vs **chest** (reduced-mass coupling).
static func _run_kinematic_delivery_target_mass_scales_blunt_pre_armor(
	failures: PackedStringArray
) -> void:
	const arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	const vo_pin: float = 12.0
	var chest: Dictionary = _kin_dmg_sample_on_part("chest", vo_pin, "MACE", "direct_blow", arch)
	var head: Dictionary = _kin_dmg_sample_on_part("head", vo_pin, "MACE", "direct_blow", arch)
	var blunt_chest: float = float(chest["pre_blunt"])
	var blunt_head: float = float(head["pre_blunt"])
	var mass_chest: float = WeaponDamageHelper.effective_blunt_target_mass_kg(chest["tgt"] as Dictionary, "chest")
	var mass_head: float = WeaponDamageHelper.effective_blunt_target_mass_kg(head["tgt"] as Dictionary, "head")
	CombatRegressionHarness._free_manager(chest["mgr"] as Node)
	CombatRegressionHarness._free_manager(head["mgr"] as Node)
	if mass_head >= mass_chest - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"kin_tgt_mass: head effective mass %.4f should be < chest %.4f"
			% [mass_head, mass_chest]
		)
	if absf(blunt_head - blunt_chest) < 0.5:
		CombatRegressionHarness._fail(
			failures,
			"kin_tgt_mass: pre_blunt should differ by part (chest=%.4f head=%.4f)"
			% [blunt_chest, blunt_head]
		)
	if blunt_head >= blunt_chest - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"kin_tgt_mass: lighter head target want lower blunt (chest=%.4f head=%.4f)"
			% [blunt_chest, blunt_head]
		)


## Tier 5.1 (optional long-tail): **AXE** **`diagonal_chop`** integration — **`pre_cut_applied`** ∝ **`sqrt(strike_ke_j)`**.
static func _run_kinematic_delivery_axe_integration_pre_cut_scales_sqrt_ke(
	failures: PackedStringArray
) -> void:
	const arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		9.0, 1.0, 1.0, {}, "AXE", "diagonal_chop", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		14.0, 1.0, 1.0, {}, "AXE", "diagonal_chop", 1.0, arch
	)
	var ke_lo: float = float(lo["strike_ke_j"])
	var ke_hi: float = float(hi["strike_ke_j"])
	var cut_lo: float = float(lo["pre_cut"])
	var cut_hi: float = float(hi["pre_cut"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
		CombatRegressionHarness._fail(failures, "kin_axe_int: need rising ke/pre_cut")
	var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
	if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_axe_int: pre_cut ratio %.4f want sqrt(ke) %.4f"
			% [cut_hi / cut_lo, want_ratio]
		)


## Tier 5.1 (optional long-tail): **`strike_mods.cut_damage_mult`** scales integration **`pre_cut_applied`** only (not **`penetration_sharp_applied`**).
static func _run_kinematic_delivery_cut_damage_mult_integration_scales_pre_cut_only(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.38
	for cfx in CombatRegressionHarness._kin_fixtures_cut_swing():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {"cut_damage_mult": mult}, wid, move, 1.0, arch
		)
		CombatRegressionHarness._free_manager(base["mgr"] as Node)
		CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
		if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - mult) > 0.05:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_cut_dmg_mult pre_cut ratio %.4f want %.4f"
				% [tag, float(shaped["pre_cut"]) / float(base["pre_cut"]), mult]
			)
		if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.03:
			CombatRegressionHarness._fail(
				failures, "%s: kin_cut_dmg_mult pen_sharp should ignore cut_damage_mult" % tag
			)


static func _kin_unarmed_pre_blunt_afterblow_sample(afterblow_mult: float) -> float:
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
		afterblow_mult,
		1.0,
		{},
		{}
	)
	var pre: float = float(res.get("result_dict", {}).get("pre_blunt_applied", -999.0))
	CombatRegressionHarness._free_manager(m)
	return pre


## Tier 5.1 (optional long-tail): unarmed path — **`afterblow_damage_mult`** scales **`pre_blunt_applied`** via **`sqrt(mult)`** (closing/stamina path, not KE).
static func _run_kinematic_delivery_unarmed_afterblow_scales_pre_blunt(
	failures: PackedStringArray
) -> void:
	const ab_full: float = 1.0
	const ab_half: float = 0.55
	var pre_full: float = _kin_unarmed_pre_blunt_afterblow_sample(ab_full)
	var pre_half: float = _kin_unarmed_pre_blunt_afterblow_sample(ab_half)
	if pre_full <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_unarmed_ab: full pre_blunt too small %.4f" % pre_full)
	var want_ratio: float = sqrt(ab_half)
	if absf(pre_half / pre_full - want_ratio) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"kin_unarmed_ab: ratio %.4f want sqrt(ab) %.4f (full=%.4f half=%.4f)"
			% [pre_half / pre_full, want_ratio, pre_full, pre_half]
		)


## Tier 5.1 (optional long-tail): **DAGGER** **`quick_slash`** integration — **`pre_cut_applied`** ∝ **`sqrt(strike_ke_j)`**.
static func _run_kinematic_delivery_dagger_integration_pre_cut_scales_sqrt_ke(
	failures: PackedStringArray
) -> void:
	const arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var lo: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		10.0, 1.0, 1.0, {}, "DAGGER", "quick_slash", 1.0, arch
	)
	var hi: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		18.0, 1.0, 1.0, {}, "DAGGER", "quick_slash", 1.0, arch
	)
	var ke_lo: float = float(lo["strike_ke_j"])
	var ke_hi: float = float(hi["strike_ke_j"])
	var cut_lo: float = float(lo["pre_cut"])
	var cut_hi: float = float(hi["pre_cut"])
	CombatRegressionHarness._free_manager(lo["mgr"] as Node)
	CombatRegressionHarness._free_manager(hi["mgr"] as Node)
	if ke_hi <= ke_lo + 1e-4 or cut_hi <= cut_lo + 1e-4:
		CombatRegressionHarness._fail(failures, "kin_dagger_int: need rising ke/pre_cut")
	var want_ratio: float = sqrt(ke_hi / maxf(ke_lo, 0.001))
	if absf(cut_hi / maxf(cut_lo, 0.001) - want_ratio) > 0.04:
		CombatRegressionHarness._fail(
			failures,
			"kin_dagger_int: pre_cut ratio %.4f want sqrt(ke) %.4f"
			% [cut_hi / cut_lo, want_ratio]
		)


## Tier 5.1 (optional long-tail): **`strike_mods.blunt_damage_mult`** scales integration **`pre_blunt_applied`** only (not **`penetration_sharp_applied`**).
static func _run_kinematic_delivery_blunt_damage_mult_integration_scales_pre_blunt_only(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.28
	for cfx in CombatRegressionHarness._kin_fixtures_with_blunt_pen():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var base: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var shaped: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {"blunt_damage_mult": mult}, wid, move, 1.0, arch
		)
		CombatRegressionHarness._free_manager(base["mgr"] as Node)
		CombatRegressionHarness._free_manager(shaped["mgr"] as Node)
		if float(base["pre_blunt"]) <= 0.1:
			CombatRegressionHarness._fail(failures, "%s: kin_blunt_dmg_mult baseline pre_blunt too small" % tag)
		if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.05:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_blunt_dmg_mult pre_blunt ratio %.4f want %.4f"
				% [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
			)
		if float(base["pen_sharp"]) > 0.001:
			if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.03:
				CombatRegressionHarness._fail(
					failures, "%s: kin_blunt_dmg_mult pen_sharp should ignore blunt_damage_mult" % tag
				)


## Tier 5.1 (optional long-tail): **`get_deflected_line_from_angles`** — stab contact uses lower opposite-severity threshold than cut.
static func _run_kinematic_delivery_deflected_line_stab_opposite_severity_bind(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 0.0
	const guard_deg: float = 180.0
	const stab_sev: float = CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST + 0.02
	var line_stab: String = CombatConstants.get_deflected_line_from_angles(
		atk_deg, guard_deg, stab_sev, WeaponConstants.ATTACK_TYPE_STAB, 1.0
	)
	if line_stab != "low":
		CombatRegressionHarness._fail(
			failures,
			"kin_defl_stab: stab at severity %.2f want low got %s" % [stab_sev, line_stab]
		)
	var cut_sev: float = CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.02
	var line_cut: String = CombatConstants.get_deflected_line_from_angles(
		atk_deg, guard_deg, cut_sev, WeaponConstants.ATTACK_TYPE_CUT, 1.0
	)
	if line_cut == "low":
		CombatRegressionHarness._fail(
			failures,
			"kin_defl_stab: cut below cut threshold should not bind opposite at severity %.2f"
			% cut_sev
		)


## Tier 5.1 (optional long-tail): **SWORD** **`thrust`** move — empty archetype infers thrust delivery on integration path.
static func _run_kinematic_delivery_empty_arch_sword_thrust_infers_delivery(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const move_id: String = "thrust"
	if WeaponDamageHelper.kinematic_delivery({}, move_id) != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
		CombatRegressionHarness._fail(failures, "kin_infer_sword: empty arch + stab want thrust")
	var explicit: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", move_id, 1.0, {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	)
	var mgr: Node = _MgrScript.new()
	mgr.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var tgt: Dictionary = mgr.combatants[1]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		mgr,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		0.62,
		move_id,
		{},
		vo_pin,
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
	var ke_infer: float = float(res.get("result_dict", {}).get("strike_ke_j_applied", -999.0))
	CombatRegressionHarness._free_manager(mgr)
	CombatRegressionHarness._free_manager(explicit["mgr"] as Node)
	if absf(ke_infer / float(explicit["strike_ke_j"]) - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_infer_sword: strike_ke ratio %.4f (infer=%.4f explicit=%.4f)"
			% [ke_infer / float(explicit["strike_ke_j"]), ke_infer, float(explicit["strike_ke_j"])]
		)


## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` ≥ 0**) — **`pre_blunt_applied`** rises, **`pre_cut_applied`** falls — **SWORD** / **AXE** / **DAGGER**.
static func _run_kinematic_delivery_partial_parry_cut_to_blunt_integration_sword(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const parry_half: float = 0.5
	for cfx in CombatRegressionHarness._kin_fixtures_cut_swing():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var partial: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, parry_half, 1.0, {}, wid, move, 1.0, arch
		)
		var pre_cut_clean: float = float(clean["pre_cut"])
		var pre_cut_part: float = float(partial["pre_cut"])
		var pre_blunt_clean: float = float(clean["pre_blunt"])
		var pre_blunt_part: float = float(partial["pre_blunt"])
		CombatRegressionHarness._free_manager(clean["mgr"] as Node)
		CombatRegressionHarness._free_manager(partial["mgr"] as Node)
		if pre_cut_part >= pre_cut_clean - 0.5:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_parry_shift_int partial should lower pre_cut (clean=%.4f part=%.4f)"
				% [tag, pre_cut_clean, pre_cut_part]
			)
		if pre_blunt_part <= pre_blunt_clean + 0.01:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_parry_shift_int partial should raise pre_blunt (clean=%.4f part=%.4f)"
				% [tag, pre_blunt_clean, pre_blunt_part]
			)


## Tier 5.1 (optional long-tail): pinned **`velocity_override`** — misaligned guard scales applied pens (oblique active); complements derived-**`v`** skip test.
static func _run_kinematic_delivery_pinned_vo_misalign_scales_pen_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	var want_ratio: float = lerpf(1.0, amin, ascale)
	for cfx in CombatRegressionHarness._kin_fixtures_with_sharp_pen():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var aligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var misaligned: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 0.0, {}, wid, move, 1.0, arch
		)
		CombatRegressionHarness._free_manager(aligned["mgr"] as Node)
		CombatRegressionHarness._free_manager(misaligned["mgr"] as Node)
		if float(misaligned["pen_sharp"]) >= float(aligned["pen_sharp"]) - 0.001:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_pin_oblique misalign should reduce pen_sharp (aligned=%.4f mis=%.4f)"
				% [tag, float(aligned["pen_sharp"]), float(misaligned["pen_sharp"])]
			)
		if absf(float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]) - want_ratio) > 0.04:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_pin_oblique pen ratio %.4f want oblique %.4f"
				% [tag, float(misaligned["pen_sharp"]) / float(aligned["pen_sharp"]), want_ratio]
			)


## Tier 5.1 (optional long-tail): assembled **`v`** stamina scale — low striker **`strike_ke_j`** ratio ≈ **`stamina_vel_scale²`** (pinned **`vo`**).
static func _run_kinematic_delivery_striker_stamina_strike_ke_matches_sqrt_stamina_scale(
	failures: PackedStringArray
) -> void:
	const st_ratio_low: float = 0.05
	var ke_full: float = _kin_striker_stamina_strike_ke_sample(1.0)
	var ke_low: float = _kin_striker_stamina_strike_ke_sample(st_ratio_low)
	if ke_full <= 0.5:
		CombatRegressionHarness._fail(failures, "kin_stam_ke: full ke too small %.4f" % ke_full)
	var st_vel: float = sqrt(
		lerpf(
			CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT,
			1.0,
			CombatConstants.stamina_factor(st_ratio_low)
		)
	)
	var want_ratio: float = st_vel * st_vel
	if absf(ke_low / ke_full - want_ratio) > 0.06:
		CombatRegressionHarness._fail(
			failures,
			"kin_stam_ke: ke ratio %.4f want stamina_vel² %.4f (full=%.4f low=%.4f)"
			% [ke_low / ke_full, want_ratio, ke_full, ke_low]
		)


static func _kin_result_split_fields_sample(
	vo: float,
	weapon_id: String,
	move_id: String,
	arch: Dictionary
) -> Dictionary:
	var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo, 1.0, 1.0, {}, weapon_id, move_id, 1.0, arch
	)
	CombatRegressionHarness._free_manager(sample["mgr"] as Node)
	return {
		"final_cut": float(sample["final_cut"]),
		"final_blunt": float(sample["final_blunt"]),
		"final_bone": float(sample["final_bone"]),
		"total_physical": float(sample["total_physical"]),
	}


## Tier 5.1 (optional long-tail): weapon path — **`afterblow_damage_mult`** scales **`pre_cut_applied`** by **`sqrt(mult)`** (**`v`** × √mult → **`pre_cut`** ∝ √KE).
static func _run_kinematic_delivery_afterblow_scales_pre_cut_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const ab_mult: float = 0.6
	var want_ratio: float = sqrt(ab_mult)
	for cfx in CombatRegressionHarness._kin_fixtures_with_sharp_pen():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var clean: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, 1.0, arch
		)
		var hindered: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
			vo, 1.0, 1.0, {}, wid, move, ab_mult, arch
		)
		CombatRegressionHarness._free_manager(clean["mgr"] as Node)
		CombatRegressionHarness._free_manager(hindered["mgr"] as Node)
		if float(clean["pre_cut"]) <= 0.5:
			CombatRegressionHarness._fail(failures, "%s: kin_ab_pre_cut baseline pre_cut too small" % tag)
		var ratio_cut: float = float(hindered["pre_cut"]) / maxf(float(clean["pre_cut"]), 0.001)
		if absf(ratio_cut - want_ratio) > 0.06:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_ab_pre_cut ratio %.4f want sqrt(ab) %.4f (clean=%.4f hind=%.4f)"
				% [tag, ratio_cut, want_ratio, float(clean["pre_cut"]), float(hindered["pre_cut"])]
			)


## Tier 5.1 (optional long-tail): **MACE** integration — **`blunt_contact_cm_applied`** matches **`WeaponDamageHelper.compute_penetration`** **BLUNT** dict.
static func _run_kinematic_delivery_mace_blunt_contact_cm_matches_helper_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 12.0
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var sample: Dictionary = CombatRegressionHarness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "MACE", "direct_blow", 1.0, arch
	)
	var m: Node = sample["mgr"] as Node
	var atk: Dictionary = sample["atk"] as Dictionary
	var tgt: Dictionary = sample["tgt"] as Dictionary
	var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
	var ai: AttackInstance = AttackInstance.new("direct_blow", 0.62)
	ai.archetype = arch
	ai.velocity_m_s = vo_pin
	var v_asm: float = CombatRegressionHarness._kin_expected_damage_velocity_m_s(
		m, atk, tgt, 0.62, arch, "direct_blow", vo_pin, 1.0, {}
	)
	ai.velocity_m_s = v_asm
	var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest")
	var pen_blunt: Dictionary = WeaponDamageHelper.compute_penetration(
		weapon,
		ai,
		WeaponConstants.DAMAGE_TYPE_BLUNT,
		{"target_effective_mass_kg": target_mass}
	)
	var want_bc: float = float(pen_blunt.get("blunt_contact_cm", -1.0))
	var got_bc: float = float(sample["blunt_contact_cm"])
	CombatRegressionHarness._free_manager(m)
	if want_bc <= 0.0:
		CombatRegressionHarness._fail(failures, "kin_mace_bc: helper blunt_contact_cm invalid %.4f" % want_bc)
	if absf(got_bc / want_bc - 1.0) > 0.03:
		CombatRegressionHarness._fail(
			failures,
			"kin_mace_bc: ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
			% [got_bc / want_bc, got_bc, want_bc, v_asm]
		)


## Tier 5.1 (optional long-tail): **`take_damage_split`** result — **`total_physical`** = **`final_cut`** + **`final_blunt`** + **`final_bone`**.
static func _run_kinematic_delivery_entity_split_total_includes_final_bone(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 14.0
	for cfx in CombatRegressionHarness._kin_fixtures_all_damage():
		var wid: String = str(cfx["wid"])
		var move: String = str(cfx["move"])
		var tag: String = str(cfx["tag"])
		var vo: float = _kin_fixture_vo(cfx, vo_pin)
		var arch: Dictionary = CombatRegressionHarness._kin_arch_for_move(move)
		var rd: Dictionary = _kin_result_split_fields_sample(vo, wid, move, arch)
		var fc: float = float(rd["final_cut"])
		var fb: float = float(rd["final_blunt"])
		var bone: float = float(rd["final_bone"])
		var total: float = float(rd["total_physical"])
		if fc < 0.0 or fb < 0.0 or bone < 0.0 or total < 0.0:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_entity_bone missing split fields (cut=%.4f blunt=%.4f bone=%.4f total=%.4f)"
				% [tag, fc, fb, bone, total]
			)
		if total + 0.02 < fc + fb + bone:
			CombatRegressionHarness._fail(
				failures,
				"%s: kin_entity_bone total %.4f < tissue+bone %.4f (cut=%.4f blunt=%.4f bone=%.4f)"
				% [tag, total, fc + fb + bone, fc, fb, bone]
			)
		if total <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			CombatRegressionHarness._fail(
				failures, "%s: kin_entity_bone total_physical too small %.4f" % [tag, total]
			)


## Entry point — defined last so Godot resolves all `_run_*` bodies before `run()` (large-script forward-ref limit).
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
	_run_kinematic_delivery_pa_stamp_open_lane_strike_ke_matches_manual_ctx(failures)
	_run_kinematic_delivery_attack_angle_deg_variance_off_balance_spreads(failures)
	_run_kinematic_delivery_attack_angle_deg_variance_weapon_mass_spreads(failures)
	_run_kinematic_delivery_tactical_ambush_mult_unity_no_boost(failures)
	_run_kinematic_delivery_engagement_angle_unknown_matches_front(failures)
	_run_kinematic_delivery_parry_v_intent_thrust_archetype(failures)
	_run_kinematic_delivery_thrust_integration_pre_cut_scales_sqrt_ke(failures)
	_run_kinematic_delivery_mace_integration_pre_blunt_rises_with_vo(failures)
	_run_kinematic_delivery_thrust_integration_pen_sharp_scales_ke_exponent(failures)
	_run_kinematic_delivery_resolve_hit_part_angle_path_keys(failures)
	_run_kinematic_delivery_empty_arch_spear_thrust_infers_delivery(failures)
	_run_kinematic_delivery_move_def_angle_offset_seeded_deterministic(failures)
	_run_kinematic_delivery_derived_velocity_misalign_skips_oblique_pen(failures)
	_run_kinematic_delivery_mace_integration_pen_blunt_mpa_rises_with_vo(failures)
	_run_kinematic_delivery_low_striker_stamina_lowers_pre_cut(failures)
	_run_kinematic_delivery_move_def_angle_variance_wider_than_bare_line(failures)
	_run_kinematic_delivery_choose_defense_parry_p_a_matches_v_intent_formula(failures)
	_run_kinematic_delivery_rear_afterblow_compose_on_strike_ke(failures)
	_run_kinematic_delivery_stance_modifier_scales_pre_cut_integration(failures)
	_run_kinematic_delivery_closing_speed_engagement_angle_scales_pre_cut(failures)
	_run_kinematic_delivery_mixed_integration_pre_cut_scales_sqrt_ke(failures)
	_run_kinematic_delivery_closing_speed_clamps_at_ceiling(failures)
	_run_kinematic_delivery_variance_off_balance_and_stamina_compose(failures)
	_run_kinematic_delivery_deflected_line_opposite_severity_bind(failures)
	_run_kinematic_delivery_target_mass_scales_blunt_pre_armor(failures)
	_run_kinematic_delivery_axe_integration_pre_cut_scales_sqrt_ke(failures)
	_run_kinematic_delivery_cut_damage_mult_integration_scales_pre_cut_only(failures)
	_run_kinematic_delivery_unarmed_afterblow_scales_pre_blunt(failures)
	_run_kinematic_delivery_dagger_integration_pre_cut_scales_sqrt_ke(failures)
	_run_kinematic_delivery_blunt_damage_mult_integration_scales_pre_blunt_only(failures)
	_run_kinematic_delivery_deflected_line_stab_opposite_severity_bind(failures)
	_run_kinematic_delivery_empty_arch_sword_thrust_infers_delivery(failures)
	_run_kinematic_delivery_partial_parry_cut_to_blunt_integration_sword(failures)
	_run_kinematic_delivery_pinned_vo_misalign_scales_pen_integration(failures)
	_run_kinematic_delivery_striker_stamina_strike_ke_matches_sqrt_stamina_scale(failures)
	_run_kinematic_delivery_afterblow_scales_pre_cut_integration(failures)
	_run_kinematic_delivery_mace_blunt_contact_cm_matches_helper_integration(failures)
	_run_kinematic_delivery_entity_split_total_includes_final_bone(failures)
