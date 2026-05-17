class_name CombatRegressionHarnessKinematicTail
extends RefCounted

## Tier 5.1 optional long-tail kinematic tests split from **`CombatRegressionHarness`** (Godot compile size).

const _Harness := preload("res://combat/CombatRegressionHarness.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
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


static func _run_kinematic_delivery_line_to_angle_unknown_line_returns_zero(
	failures: PackedStringArray
) -> void:
	if absf(CombatConstants.line_to_angle("__invalid__")) > 0.0001:
		_Harness._fail(
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
	seed(_Harness._HARNESS_RESTORE_GLOBAL_SEED)
	if CombatConstants.angle_diff_deg(heavy, light) < 0.05:
		_Harness._fail(
			failures,
			"kin_wobble_mass: heavy mass should shift angle vs light (light=%.4f heavy=%.4f)"
			% [light, heavy]
		)


static func _kin_striker_stamina_strike_ke_sample(stamina_ratio: float) -> float:
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.register(_Harness._new_entity("SWORD"), "player")
	m.register(_Harness._new_entity("SWORD"), "enemy")
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
	_Harness._free_manager(m)
	return ke


static func _run_kinematic_delivery_low_striker_stamina_lowers_strike_ke(
	failures: PackedStringArray
) -> void:
	var ke_full: float = _kin_striker_stamina_strike_ke_sample(1.0)
	var ke_low: float = _kin_striker_stamina_strike_ke_sample(0.05)
	if ke_full <= 0.5:
		_Harness._fail(failures, "kin_striker_stam: full ke too small %.4f" % ke_full)
	if ke_low >= ke_full - 0.01:
		_Harness._fail(
			failures,
			"kin_striker_stam: low stamina should reduce ke (full=%.4f low=%.4f)"
			% [ke_full, ke_low]
		)


static func _run_kinematic_delivery_strike_momentum_mult_integration_pre_blunt_not_pen(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.32
	var base: Dictionary = _Harness._kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = _Harness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {"strike_momentum_mult": mult}
	)
	_Harness._free_manager(base["mgr"] as Node)
	_Harness._free_manager(shaped["mgr"] as Node)
	if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - mult) > 0.04:
		_Harness._fail(
			failures,
			"kin_mom_mult_int: pre_blunt ratio %.4f want %.4f"
			% [float(shaped["pre_blunt"]) / float(base["pre_blunt"]), mult]
		)
	if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.04:
		_Harness._fail(
			failures,
			"kin_mom_mult_int: blunt mpa ratio %.4f want %.4f"
			% [float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
		)
	if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
		_Harness._fail(failures, "kin_mom_mult_int: pre_cut should ignore strike_momentum_mult")
	if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
		_Harness._fail(failures, "kin_mom_mult_int: pen_sharp should ignore strike_momentum_mult")


static func _run_kinematic_delivery_get_attack_path_all_line_pairs_nonempty(
	failures: PackedStringArray
) -> void:
	for atk_ln in ["high", "right", "low", "left"]:
		for guard_ln in ["high", "right", "low", "left"]:
			var path: Array = CombatConstants.get_attack_path(atk_ln, guard_ln)
			if path.is_empty():
				_Harness._fail(
					failures,
					"kin_attack_path_pairs: empty path atk=%s guard=%s" % [atk_ln, guard_ln]
				)


static func _run_kinematic_delivery_near_full_parry_respects_min_cut_ratio_floor(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const parry_graze: float = 0.05
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var clean: Dictionary = _Harness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var grazed: Dictionary = _Harness._kin_dmg_integration_sample(
		vo_pin, parry_graze, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var weapon: Weapon = _EntityAccess.get_weapon(clean["atk"] as Dictionary) as Weapon
	_Harness._free_manager(clean["mgr"] as Node)
	_Harness._free_manager(grazed["mgr"] as Node)
	if weapon == null:
		_Harness._fail(failures, "kin_cut_floor: missing weapon")
		return
	var base_cr: float = WeaponDamageHelper.get_cut_ratio(weapon, "oberhau", arch)
	var exp_cr: float = maxf(
		WeaponConstants.MIN_CUT_RATIO,
		base_cr - CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_graze)
	)
	var ratio_cut: float = float(grazed["pre_cut"]) / maxf(float(clean["pre_cut"]), 0.001)
	var want_ratio: float = exp_cr / maxf(base_cr, 0.001)
	if absf(ratio_cut - want_ratio) > 0.06:
		_Harness._fail(
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
			_Harness._fail(
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
	var sample: Dictionary = _Harness._kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch
	)
	var m: Node = sample["mgr"] as Node
	var atk: Dictionary = sample["atk"] as Dictionary
	var tgt: Dictionary = sample["tgt"] as Dictionary
	var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
	var v_asm: float = _Harness._kin_expected_damage_velocity_m_s(
		m, atk, tgt, float(sample["intensity"]), arch, "oberhau", vo_pin, 1.0
	)
	var ai: AttackInstance = AttackInstance.new("oberhau", float(sample["intensity"]))
	ai.archetype = arch
	ai.velocity_m_s = v_asm
	var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
	_Harness._free_manager(m)
	if absf(float(sample["strike_ke_j"]) / ke_want - 1.0) > 0.03:
		_Harness._fail(
			failures,
			"kin_mixed_int: strike_ke_j ratio %.4f (got=%.4f want=%.4f v=%.4f)"
			% [float(sample["strike_ke_j"]) / ke_want, float(sample["strike_ke_j"]), ke_want, v_asm]
		)


static func _run_kinematic_delivery_angle_diff_symmetry_and_zero(
	failures: PackedStringArray
) -> void:
	if CombatConstants.angle_diff_deg(80.0, 200.0) != CombatConstants.angle_diff_deg(200.0, 80.0):
		_Harness._fail(failures, "kin_angle_sym: angle_diff should be symmetric")
	if CombatConstants.angle_diff_deg(12.0, 12.0) > 0.0001:
		_Harness._fail(failures, "kin_angle_sym: identical angles want 0 diff")
	if CombatConstants.get_alignment_from_angles(33.0, 33.0) < 0.999:
		_Harness._fail(failures, "kin_angle_sym: identical angles want align 1")
