class_name CombatRegressionHarnessFeintTempoTail
extends RefCounted

## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`** — legacy **`stance_str`** rows here stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing — **not** Tier 4.4 PA (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** · **`#harness-footwork-catalog`** (feint rows).

const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _PassiveParryCtx := preload("res://combat/PassiveParryContext.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")

static func _feint_listing_read_m_expect_for_move_on_target(
	tgt_enemy: Dictionary,
	combatant_id_for_spacing: int,
	feint_move_id: String,
	attacker: Dictionary = {},
	pa_live: Dictionary = {}
) -> float:
	var pr_def: float = _DefenseChoice.defender_feint_listing_pr_def(
		tgt_enemy, combatant_id_for_spacing, feint_move_id, attacker, pa_live
	)
	return lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)


## Defender footwork on feint listing (off-balance / recovering / settled waiting); **1** otherwise.
static func _feint_listing_defender_footwork_state_mult_for_target(tgt_enemy: Dictionary) -> float:
	if _PassiveParryCtx.is_off_balance(tgt_enemy):
		return 1.0
	var st: String = str(tgt_enemy.get("state", ""))
	if st == CombatConstants.STATE_RECOVERING:
		return CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
			str(tgt_enemy.get("recovery_cause", "skip"))
		)
	if st == CombatConstants.STATE_WAITING:
		return CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
	return 1.0


## Defender-side feint-listing mult: readiness lerp × footwork state mult (when applicable).
static func _feint_listing_target_readiness_and_footwork_mult(
	tgt_enemy: Dictionary,
	combatant_id_for_spacing: int,
	feint_move_id: String
) -> float:
	return (
		_feint_listing_read_m_expect_for_move_on_target(tgt_enemy, combatant_id_for_spacing, feint_move_id)
		* _feint_listing_defender_footwork_state_mult_for_target(tgt_enemy)
	)


static func _feint_guard_zone_sample_global_seed_for_modifier(
	pa: Dictionary,
	tgt: Dictionary,
	parts: Array,
	move_id: String,
	parry_readiness_for_feint: float,
	want_mult: float,
	atk_id_for_spacing: int = -1
) -> int:
	for s: int in range(16384):
		seed(s)
		var m: float
		if parry_readiness_for_feint < 0.0:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id)
		elif atk_id_for_spacing < 0:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id, parry_readiness_for_feint)
		else:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id, parry_readiness_for_feint, atk_id_for_spacing)
		if is_equal_approx(m, want_mult):
			return s
	return -1


## Tier 4.2: **`DefenseChoiceResolver._guard_zone_modifier`** — feint telegraph mismatch → **`GUARD_ZONE_UNGUARDED_PENALTY`**; defender **`guard_zone`** moved to real line → **`GUARD_ZONE_BONUS`**; non-feint unchanged. **`AttackPathResolver`** uses **`randf`** — scan stable seeds per fixture, then restore global RNG.
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "left_leg", "feint_part": "head"}
	)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		CombatRegressionHarness._fail(failures, "feint_windup: pending target_part want left_leg got %s" % str(pa.get("target_part", "")))
	if str(pa.get("feint_part", "")) != "head":
		CombatRegressionHarness._fail(failures, "feint_windup: pending feint_part want head got %s" % str(pa.get("feint_part", "")))
	if str(e.get("guard_zone", "")) != "head":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup: defender incoming telegraph want head got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	var reveal_expect: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.0))
	if reveal_expect <= 0.0:
		CombatRegressionHarness._fail(failures, "feint_windup: oberhau_feint should define feint_target_reveal_at_progress > 0")
	if not pa.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(failures, "feint_windup: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, for stab **`thrust_feint`** on **SWORD** ( **`feint_windup_duration_mult`** stamp + telegraph keys).
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"thrust_feint",
		{"target_part": "chest", "feint_part": "head"}
	)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("attack_type", "")) != "thrust_feint":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: pending attack_type want thrust_feint got %s" % str(pa.get("attack_type", ""))
		)
	if str(pa.get("target_part", "")) != "chest":
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: pending target_part want chest got %s" % str(pa.get("target_part", "")))
	if str(pa.get("feint_part", "")) != "head":
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: pending feint_part want head got %s" % str(pa.get("feint_part", "")))
	if str(pa.get("move_contact_type", "")) != WeaponConstants.ATTACK_TYPE_STAB:
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: move_contact_type want stab got %s" % str(pa.get("move_contact_type", ""))
		)
	if str(e.get("guard_zone", "")) != "head":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: defender incoming telegraph want head got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: thrust_feint should define feint_windup_duration_mult > 1")
	if not pa.has("feint_windup_duration_mult"):
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: pending_attack should stamp feint_windup_duration_mult")
	if not is_equal_approx(float(pa.get("feint_windup_duration_mult", 0.0)), mult_expect):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: feint_windup_duration_mult want %s got %s"
			% [str(mult_expect), str(pa.get("feint_windup_duration_mult", ""))]
		)
	var reveal_expect: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_expect <= 0.0:
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: thrust_feint should define feint_target_reveal_at_progress > 0")
	if not pa.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(failures, "feint_windup_thrust: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_thrust: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`WeaponConstants`** move **`feint_windup_duration_mult`** on **`is_feint`** cuts extends **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs **`oberhau`** at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`pa["feint_target_reveal_at_progress"]`** when defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(failures: PackedStringArray) -> void:
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		CombatRegressionHarness._fail(failures, "feint_windup_mult: oberhau_feint should define feint_windup_duration_mult > 1")
	var mgr_o: Node = CombatRegressionHarness._harness_start_1v1()
	var po: Dictionary = mgr_o.combatants[0]
	var eo: Dictionary = mgr_o.combatants[1]
	var po_id: int = _EntityAccess.id_int(po)
	var eo_id: int = _EntityAccess.id_int(eo)
	eo["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_o, po_id, eo_id, "oberhau", {"target_part": "chest"})
	var d_o: float = float(po.get("state_duration", 0.0))
	var mgr_f: Node = CombatRegressionHarness._harness_start_1v1()
	var pf: Dictionary = mgr_f.combatants[0]
	var ef: Dictionary = mgr_f.combatants[1]
	var pf_id: int = _EntityAccess.id_int(pf)
	var ef_id: int = _EntityAccess.id_int(ef)
	ef["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_f, pf_id, ef_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	var d_f: float = float(pf.get("state_duration", 0.0))
	var pa_f: Dictionary = _EntityAccess.nested_dictionary_read(pf, "pending_attack")
	if not pa_f.has("feint_windup_duration_mult"):
		CombatRegressionHarness._fail(failures, "feint_windup_mult: pending_attack should stamp feint_windup_duration_mult")
	var reveal_f: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_f <= 0.0:
		CombatRegressionHarness._fail(failures, "feint_windup_mult: oberhau_feint should define feint_target_reveal_at_progress > 0")
	if not pa_f.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(failures, "feint_windup_mult: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa_f.get("feint_target_reveal_at_progress", -1.0)), reveal_f):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_f), str(pa_f.get("feint_target_reveal_at_progress", ""))]
		)
	if not is_equal_approx(float(pa_f.get("feint_windup_duration_mult", 0.0)), mult_expect):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult: pa feint_windup_duration_mult want %s got %s" % [str(mult_expect), str(pa_f.get("feint_windup_duration_mult", ""))]
		)
	if not is_equal_approx(float(pa_f.get("wind_up_duration", 0.0)), d_f):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult: wind_up_duration should match state_duration got pa=%s state=%s"
			% [str(pa_f.get("wind_up_duration", "")), str(d_f)]
		)
	var want_f: float = d_o * mult_expect
	if absf(d_f - want_f) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult: feint state_duration want ~ d_oberhau*mult got d_f=%s d_o=%s mult=%s"
			% [str(d_f), str(d_o), str(mult_expect)]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_o)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_f)


## Tier 4.2: **`WeaponConstants`** **`thrust_feint`** **`feint_windup_duration_mult`** extends **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs honest **`thrust`** at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`feint_target_reveal_at_progress`** when defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_thrust(failures: PackedStringArray) -> void:
	var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		CombatRegressionHarness._fail(failures, "feint_windup_mult_thrust: thrust_feint should define feint_windup_duration_mult > 1")
	var mgr_t: Node = CombatRegressionHarness._harness_start_1v1()
	var pt: Dictionary = mgr_t.combatants[0]
	var et: Dictionary = mgr_t.combatants[1]
	var pt_id: int = _EntityAccess.id_int(pt)
	var et_id: int = _EntityAccess.id_int(et)
	et["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_t, pt_id, et_id, "thrust", {"target_part": "chest"})
	var d_t: float = float(pt.get("state_duration", 0.0))
	var mgr_tf: Node = CombatRegressionHarness._harness_start_1v1()
	var ptf: Dictionary = mgr_tf.combatants[0]
	var etf: Dictionary = mgr_tf.combatants[1]
	var ptf_id: int = _EntityAccess.id_int(ptf)
	var etf_id: int = _EntityAccess.id_int(etf)
	etf["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_tf, ptf_id, etf_id, "thrust_feint", {"target_part": "chest", "feint_part": "head"})
	var d_tf: float = float(ptf.get("state_duration", 0.0))
	var pa_tf: Dictionary = _EntityAccess.nested_dictionary_read(ptf, "pending_attack")
	if not pa_tf.has("feint_windup_duration_mult"):
		CombatRegressionHarness._fail(failures, "feint_windup_mult_thrust: pending_attack should stamp feint_windup_duration_mult")
	var reveal_tf: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_tf <= 0.0:
		CombatRegressionHarness._fail(failures, "feint_windup_mult_thrust: thrust_feint should define feint_target_reveal_at_progress > 0")
	if not pa_tf.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(failures, "feint_windup_mult_thrust: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa_tf.get("feint_target_reveal_at_progress", -1.0)), reveal_tf):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult_thrust: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_tf), str(pa_tf.get("feint_target_reveal_at_progress", ""))]
		)
	if not is_equal_approx(float(pa_tf.get("feint_windup_duration_mult", 0.0)), mult_expect):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult_thrust: pa feint_windup_duration_mult want %s got %s"
			% [str(mult_expect), str(pa_tf.get("feint_windup_duration_mult", ""))]
		)
	if not is_equal_approx(float(pa_tf.get("wind_up_duration", 0.0)), d_tf):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult_thrust: wind_up_duration should match state_duration got pa=%s state=%s"
			% [str(pa_tf.get("wind_up_duration", "")), str(d_tf)]
		)
	var want_tf: float = d_t * mult_expect
	if absf(d_tf - want_tf) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_mult_thrust: feint state_duration want ~ d_thrust*mult got d_tf=%s d_t=%s mult=%s"
			% [str(d_tf), str(d_t), str(mult_expect)]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_t)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_tf)


## Tier 4.2: **`AttackWindUpStarter.start`** with **`target_part`** only (no **`feint_part`**) stamps **`pending_attack`** and sets defender **`guard_zone`** to **`target_part`** (non-feint **`oberhau`**). Uses **`CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED`** for stable wind-up rolls.
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
	_WindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "left_leg"})
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
		)
	if pa.has("feint_part") and str(pa.get("feint_part", "")) != "":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only: should not stamp non-empty feint_part got %s" % str(pa.get("feint_part", ""))
		)
	if pa.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only: plain oberhau should not stamp feint_target_reveal_at_progress"
		)
	if str(e.get("guard_zone", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only: defender guard_zone telegraph want left_leg got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only: defender incoming telegraph want left_leg got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, for honest **`thrust`** (no **`feint_target_reveal_at_progress`** on **`pending_attack`**).
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
	_WindUpStarter.start(mgr, p_id, e_id, "thrust", {"target_part": "left_leg"})
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only_thrust: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
		)
	if pa.has("feint_part") and str(pa.get("feint_part", "")) != "":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only_thrust: should not stamp non-empty feint_part got %s" % str(pa.get("feint_part", ""))
		)
	if pa.has("feint_target_reveal_at_progress"):
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only_thrust: plain thrust should not stamp feint_target_reveal_at_progress"
		)
	if str(e.get("guard_zone", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only_thrust: defender guard_zone telegraph want left_leg got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_windup_target_only_thrust: defender incoming telegraph want left_leg got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._add_attack_target_part`** for **`is_feint`** moves picks **`feint_part`** ≠ **`target_part`** when at least two targetable parts exist (bounded **`seed(0..4095)`** search on Godot **4.6.stable**). Restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** after the scan so **`run_all()`** order stays stable.
static func _run_feint_move_ai_distinct_feint_and_target_parts(failures: PackedStringArray) -> void:
	if not WeaponConstants.is_feint_move("oberhau_feint"):
		CombatRegressionHarness._fail(failures, "feint_ai: WeaponConstants.is_feint_move(oberhau_feint) should be true")
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	var found: bool = false
	for s in range(4096):
		seed(s)
		var choice: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
		_AIPicker._add_attack_target_part(choice, mgr, p_id)
		var tp: String = str(choice.get("target_part", ""))
		var fp: String = str(choice.get("feint_part", ""))
		if not tp.is_empty() and not fp.is_empty() and fp != tp:
			found = true
			break
	if not found:
		CombatRegressionHarness._fail(
			failures,
			"feint_ai: no seed in 0..4095 produced distinct non-empty feint_part and target_part for oberhau_feint"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_ai_distinct_feint_and_target_parts`**, for **`thrust_feint`** on **SWORD**.
static func _run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures: PackedStringArray) -> void:
	if not WeaponConstants.is_feint_move("thrust_feint"):
		CombatRegressionHarness._fail(failures, "feint_ai_thrust: WeaponConstants.is_feint_move(thrust_feint) should be true")
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	var found: bool = false
	for s in range(4096):
		seed(s)
		var choice: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
		_AIPicker._add_attack_target_part(choice, mgr, p_id)
		var tp: String = str(choice.get("target_part", ""))
		var fp: String = str(choice.get("feint_part", ""))
		if not tp.is_empty() and not fp.is_empty() and fp != tp:
			found = true
			break
	if not found:
		CombatRegressionHarness._fail(
			failures,
			"feint_ai_thrust: no seed in 0..4095 produced distinct non-empty feint_part and target_part for thrust_feint"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — **`oberhau_feint`** vs same-target **`oberhau`** scales by **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** (SWORD 1v1 fixture).
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr._recompute_zoc_and_distance()
	## Pin defender readiness to **0** (WAITING **`guard`**); isolates base **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** vs readiness lerp harness.
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	var enemy: Dictionary = mgr.combatants[1]
	enemy["off_balance_until"] = -1.0
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var read_m: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_listing_w: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
			% [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, for **`thrust_feint`** vs **`thrust`**.
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr._recompute_zoc_and_distance()
	var enemy: Dictionary = mgr.combatants[1]
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	var read_m: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_listing_w_thrust: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
			% [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: feint listing mult × **`lerpf(1, AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, passive_readiness)`** vs low defender **`guard`** (SWORD 1v1).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.0
	enemy["off_balance_until"] = -1.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_lo: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m_lo: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var want_lo: float = (
		w_plain_lo * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_lo * settled_m_lo
	)
	if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
			% [want_lo, w_feint_lo, w_plain_lo]
		)
	enemy["guard"] = 1.0
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_hi: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m_hi: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var stance_m_hi: float = _WeaponForm.mod(
		_EntityAccess.form_str(mgr.combatants[0]), "ai_feint_listing"
	)
	var want_hi: float = (
		w_plain_hi
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_hi
		* settled_m_hi
		* stance_m_hi
	)
	if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f"
			% [want_hi, w_feint_hi, w_plain_hi, read_m_hi, stance_m_hi]
		)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list: plain oberhau weight should not depend on defender guard lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	if w_feint_hi <= w_feint_lo + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, for **`thrust`** / **`thrust_feint`** (stab **`contact_type`** on readiness lerp).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.0
	enemy["off_balance_until"] = -1.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_lo_t: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m_lo_t: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var want_lo: float = (
		w_plain_lo
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_lo_t
		* settled_m_lo_t
	)
	if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list_thrust lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
			% [want_lo, w_feint_lo, w_plain_lo]
		)
	enemy["guard"] = 1.0
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_hi_t: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m_hi_t: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var stance_m_hi_t: float = _WeaponForm.mod(
		_EntityAccess.form_str(mgr.combatants[0]), "ai_feint_listing"
	)
	var want_hi: float = (
		w_plain_hi
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_hi_t
		* settled_m_hi_t
		* stance_m_hi_t
	)
	if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list_thrust hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f"
			% [want_hi, w_feint_hi, w_plain_hi, read_m_hi_t, stance_m_hi_t]
		)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list_thrust: plain thrust weight should not depend on defender guard lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	if w_feint_hi <= w_feint_lo + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_read_list_thrust: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — LONG **`distance_to[attacker]`** on defender damps readiness lerp vs MID (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG`**).
static func _run_feint_move_listing_spacing_long_dampens_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.55
	mgr._recompute_zoc_and_distance()
	var pr_def: float = _DefenseChoice.defender_feint_listing_pr_def(
		enemy, p_id, "oberhau_feint", {}, {}, true, false
	)
	var pr_long: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_l: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long
	)
	var want_ratio: float = read_l / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_l: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_l: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_long: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
			% [w_plain_m, w_plain_l]
		)
	elif w_feint_l >= w_feint_m - 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_long: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
		)
	else:
		var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			CombatRegressionHarness._fail(
				failures,
				"feint_list_sp_long: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — CLOSE **`distance_to[attacker]`** on defender boosts readiness lerp vs MID (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE`**).
static func _run_feint_move_listing_spacing_close_boosts_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.55
	mgr._recompute_zoc_and_distance()
	var pr_def: float = _DefenseChoice.defender_feint_listing_pr_def(
		enemy, p_id, "oberhau_feint", {}, {}, true, false
	)
	var pr_close: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_c: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_close
	)
	var want_ratio: float = read_c / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_c) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_close: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
			% [w_plain_m, w_plain_c]
		)
	elif w_feint_c <= w_feint_m + 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_close: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
		)
	else:
		var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			CombatRegressionHarness._fail(
				failures,
				"feint_list_sp_close: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — LONG damps vs MID when defender **`STATE_RECOVERING`** (**`READINESS_BY_CAUSE`**, not **`guard`**); same **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`** as WAITING.
static func _run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var pr_def: float = _DefenseChoice.defender_feint_listing_pr_def(
		enemy, p_id, "oberhau_feint", {}, {}, true, false
	)
	var pr_long: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_l: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long
	)
	var want_ratio: float = read_l / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_l: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_l: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_long_recov: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
			% [w_plain_m, w_plain_l]
		)
	elif w_feint_l >= w_feint_m - 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_long_recov: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
		)
	else:
		var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			CombatRegressionHarness._fail(
				failures,
				"feint_list_sp_long_recov: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — CLOSE boosts vs MID when defender **`STATE_RECOVERING`**; same spacing mults as WAITING harness.
static func _run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var pr_def: float = _DefenseChoice.defender_feint_listing_pr_def(
		enemy, p_id, "oberhau_feint", {}, {}, true, false
	)
	var pr_close: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_c: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_close
	)
	var want_ratio: float = read_c / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_c) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_close_recov: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
			% [w_plain_m, w_plain_c]
		)
	elif w_feint_c <= w_feint_m + 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_sp_close_recov: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
		)
	else:
		var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			CombatRegressionHarness._fail(
				failures,
				"feint_list_sp_close_recov: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`STATE_RECOVERING`** — feint listing uses **`PassiveParryContext.get_passive_parry_readiness`** × **`READINESS_BY_CAUSE`** (not **`guard`**).
static func _run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var pr: float = _PassiveParryCtx.get_passive_parry_readiness(enemy)
	var curve: Array = CombatConstants.READINESS_BY_CAUSE["attack_hit"]
	var want_pr: float = lerpf(curve[0], curve[1], 0.5)
	if not is_equal_approx(pr, want_pr):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov: passive readiness want %.6f got %.6f" % [want_pr, pr]
		)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var stance_m: float = _WeaponForm.mod(_EntityAccess.form_str(player), "ai_feint_listing")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_feint: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * stance_m
	)
	if absf(w_feint - want_feint) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov: want feint %.6f got %.6f plain=%.6f target_m=%.6f"
			% [want_feint, w_feint, w_plain, target_m]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low attacker **`stamina`** dampens feint listing only (**`AI_FEINT_LISTING_STAMINA_*`**); defender **`guard`** **0**, **`balanced`**.
static func _run_feint_move_listing_stamina_low_dampens_feint_weight(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * st_stamina
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f"
			% [want, w_feint, w_plain, st_stamina]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`hold_lane`** doctrine (**`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam_hold: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f hold=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`probing`** (**`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam_probe: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f probe=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`pinch_center`** (**`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam_pinch: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f pinch=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: short-horizon **`parry_deflect`** memory on **`attacker`** boosts feint-move listing vs that defender (**`(qo)`**).
static func _run_feint_move_listing_doctrine_probing_multiplies_feint_weight(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	mgr._recompute_zoc_and_distance()
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_p: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_p: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_p: float = (
		w_plain_p
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
	)
	if absf(w_feint_p - want_p) > 0.0001 * maxf(1.0, absf(w_plain_p)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_probe: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [
				want_p,
				w_feint_p,
				w_plain_p,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
			]
		)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_h: float = (
		w_plain_h
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_hold: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
			% [want_h, w_feint_h, w_plain_h]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", pinch_center)`** multiplies feint listing by **`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**; then **`hold_lane`** applies **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no pinch mult).
static func _run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	mgr._recompute_zoc_and_distance()
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_z: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_z: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_z: float = (
		w_plain_z
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
	)
	if absf(w_feint_z - want_z) > 0.0001 * maxf(1.0, absf(w_plain_z)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_pinch: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [
				want_z,
				w_feint_z,
				w_plain_z,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
			]
		)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_h: float = (
		w_plain_h
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_hold_after_pinch: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
			% [want_h, w_feint_h, w_plain_h]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`hold_lane`** feint listing × **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** vs explicit **`default`** (ratio **`w_feint/w_plain`**).
static func _run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_d: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_d: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_d) < 1e-9:
		CombatRegressionHarness._fail(failures, "feint_hold_vs_def: plain weight near zero")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var ratio_def: float = w_feint_d / w_plain_d
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_h) < 1e-9:
		CombatRegressionHarness._fail(failures, "feint_hold_vs_def: plain weight near zero (hold)")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var ratio_hold: float = w_feint_h / w_plain_h
	var want_ratio: float = ratio_def * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	if absf(ratio_hold - want_ratio) > 0.0001 * maxf(1.0, absf(ratio_def)):
		CombatRegressionHarness._fail(
			failures,
			"feint_hold_vs_def: want ratio %.6f got %.6f ratio_def=%.6f mult=%s"
			% [
				want_ratio,
				ratio_hold,
				ratio_def,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: attacker **`form_str`** × **`CombatWeaponForm.mod(..., "ai_feint_listing")`** on feint listing; settled WAITING × **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`** + full **`read_m`** chain via **`_feint_listing_read_m_expect_for_move_on_target`**.
static func _run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["off_balance_until"] = -1.0
	var w_plain_settled: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_settled: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	var w_plain_off: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_off: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_settled - w_plain_off) > 0.0002 * maxf(1.0, absf(w_plain_settled)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_settled_fw: plain oberhau should ignore footwork m=%.6f off=%.6f"
			% [w_plain_settled, w_plain_off]
		)
	elif w_feint_settled >= w_feint_off - 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_settled_fw: want feint_settled < feint_off got settled=%.6f off=%.6f"
			% [w_feint_settled, w_feint_off]
		)
	else:
		var got_ratio: float = (w_feint_settled / w_plain_settled) / (w_feint_off / w_plain_off)
		var want_ratio: float = (
			CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
			/ CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
		)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			CombatRegressionHarness._fail(
				failures,
				"feint_list_settled_fw: ratio want %.6f got %.6f (settled=%.6f off=%.6f)"
				% [want_ratio, got_ratio, w_feint_settled, w_feint_off]
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`STATE_RECOVERING`** (not off-balance) dampens feint listing (**`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**) vs settled **`STATE_WAITING`** at same **`guard`** (readiness lerp differs; ratio isolates footwork mults).
static func _run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	var w_plain_wait: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_wait: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	var w_plain_rec: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_rec: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_wait - w_plain_rec) > 0.0002 * maxf(1.0, absf(w_plain_wait)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov_fw: plain oberhau should match wait=%.6f rec=%.6f"
			% [w_plain_wait, w_plain_rec]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	enemy["state"] = CombatConstants.STATE_WAITING
	var read_wait: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_timer"] = 1.0
	var read_rec: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var got_ratio: float = (w_feint_rec / w_plain_rec) / (w_feint_wait / w_plain_wait)
	var want_ratio: float = (
		(read_rec / read_wait)
		* (
			CombatConstants.AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
			/ CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
		)
	)
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov_fw: ratio want %.6f got %.6f (wait=%.6f rec=%.6f read_w=%.6f read_r=%.6f)"
			% [want_ratio, got_ratio, w_feint_wait, w_feint_rec, read_wait, read_rec]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`recovery_cause`** selects **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** (inverse of dodge **`defense_footwork_recovering_dodge_mult_for_cause`**); **`attack_miss`** damps listing more than **`attack_hit`** at shared **`guard`** / timer.
static func _run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["state_duration"] = 1.0
	enemy["state_timer"] = 0.25
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["recovery_cause"] = "attack_hit"
	var w_plain_hit: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hit: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["recovery_cause"] = "attack_miss"
	var w_plain_miss: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_miss: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_hit - w_plain_miss) > 0.0002 * maxf(1.0, absf(w_plain_hit)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_cause_fw: plain should match hit=%.6f miss=%.6f" % [w_plain_hit, w_plain_miss]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	enemy["recovery_cause"] = "attack_hit"
	var read_hit: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	enemy["recovery_cause"] = "attack_miss"
	var read_miss: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var foot_hit: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_hit")
	var foot_miss: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_miss")
	var got_ratio: float = (w_feint_miss / w_plain_miss) / (w_feint_hit / w_plain_hit)
	var want_ratio: float = (read_miss / read_hit) * (foot_miss / foot_hit)
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_cause_fw: ratio want %.6f got %.6f foot_hit=%.6f foot_miss=%.6f"
			% [want_ratio, got_ratio, foot_hit, foot_miss]
		)
	elif foot_miss >= foot_hit - 1e-9:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_cause_fw: want foot_miss < foot_hit got hit=%.6f miss=%.6f"
			% [foot_hit, foot_miss]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: on **`STATE_RECOVERING`**, feint-listing **`read_m`** (spacing in **`pr_def`**) × **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** stack orthogonally — **`attack_hit`** at MID vs **`attack_miss`** at LONG.
static func _run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["state_duration"] = 1.0
	enemy["state_timer"] = 0.25
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["recovery_cause"] = "attack_hit"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_hit_mid: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hit_mid: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["recovery_cause"] = "attack_miss"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_miss_long: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_miss_long: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_hit_mid - w_plain_miss_long) > 0.0002 * maxf(1.0, absf(w_plain_hit_mid)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov_stack: plain should match hit_mid=%.6f miss_long=%.6f"
			% [w_plain_hit_mid, w_plain_miss_long]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	enemy["recovery_cause"] = "attack_hit"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var target_hit_mid: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	enemy["recovery_cause"] = "attack_miss"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var target_miss_long: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var got_ratio: float = (w_feint_miss_long / w_plain_miss_long) / (w_feint_hit_mid / w_plain_hit_mid)
	var want_ratio: float = target_miss_long / target_hit_mid
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_recov_stack: ratio want %.6f got %.6f t_hit_mid=%.6f t_miss_long=%.6f"
			% [want_ratio, got_ratio, target_hit_mid, target_miss_long]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Harness helper: set incoming attacker wind-up progress for **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** tests.
static func _run_counter_tempo_window_opens_on_incoming_wind_up(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	mgr.combat_clock = 1.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau", {"target_part": "chest"})
	var until: float = float(def.get(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL, -1.0))
	var want_until: float = 1.0 + float(atk.get("state_duration", 0.0)) * CombatConstants.COUNTER_TEMPO_WINDOW_FRACTION
	if absf(until - want_until) > 0.0002:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_window: until want %.4f got %.4f dur=%.4f"
			% [want_until, until, float(atk.get("state_duration", 0.0))]
		)
	if _CounterTempo.incoming_attacker_id(mgr, def_id) != atk_id:
		CombatRegressionHarness._fail(failures, "counter_tempo_window: incoming attacker id mismatch")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 counter-tempo: **`AvailableActionsBuilder`** lists melee-only **`counter_tempo`** actions when window open.
static func _run_counter_tempo_lists_melee_actions_when_window_open(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + float(atk.get("state_duration", 0.0)),
		"data": {}
	})
	var actions: Array = _ActionsBuilder.build(mgr, def_id)
	if actions.is_empty():
		CombatRegressionHarness._fail(failures, "counter_tempo_list: expected counter actions")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var saw_counter: bool = false
	var saw_close: bool = false
	var saw_focus: bool = false
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			saw_counter = true
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			saw_close = true
		if CombatConstants.is_focus_line_move(mid):
			saw_focus = true
	if not saw_counter:
		CombatRegressionHarness._fail(failures, "counter_tempo_list: no action flagged counter_tempo")
	if saw_close:
		CombatRegressionHarness._fail(failures, "counter_tempo_list: close should be filtered out")
	if saw_focus:
		CombatRegressionHarness._fail(failures, "counter_tempo_list: focus_line should be filtered out")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_spend_gauge_subtracts_cost(failures: PackedStringArray) -> void:
	var c: Dictionary = {"gauge": 60.0}
	_CounterTempo.spend_gauge(c)
	if absf(_EntityAccess.gauge_float(c) - 10.0) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_spend: want gauge 10 got %.4f" % _EntityAccess.gauge_float(c)
		)


## Tier 4.2 counter-tempo: counter **`EVENT_MELEE_ATTACK`** resolves before deferred incoming melee.
static func _run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	mgr.combat_clock = 0.0
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	var incoming_at: float = mgr.combat_clock + float(atk.get("state_duration", 0.0))
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": incoming_at,
		"data": {}
	})
	mgr.resolve_action(
		def_id,
		atk_id,
		"oberhau",
		{CombatConstants.ACTION_KEY_COUNTER_TEMPO: true, "target_part": "chest"}
	)
	var counter_at: float = _EventScheduler.get_pending_melee_attack_resolve_at(mgr, def_id)
	var incoming_at1: float = _EventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id)
	var counter_end: float = mgr.combat_clock + float(def.get("state_duration", 0.0))
	if counter_at < 0.0:
		CombatRegressionHarness._fail(failures, "counter_tempo_defer: counter melee not scheduled")
	if incoming_at1 < counter_end + CombatConstants.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S - 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_defer: incoming %.4f should be >= %.4f counter_at=%.4f"
			% [incoming_at1, counter_end, counter_at]
		)
	if counter_at >= incoming_at1:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_defer: counter should resolve before incoming got c=%.4f in=%.4f"
			% [counter_at, incoming_at1]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_abort_cancels_pending_incoming_melee(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + 1.0,
		"data": {}
	})
	_CounterTempo.abort_attacker_wind_up(mgr, atk_id)
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "counter_tempo_abort: incoming melee should be cancelled")
	if _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "counter_tempo_abort: attacker should not remain in wind_up")
	if def.has(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL):
		CombatRegressionHarness._fail(failures, "counter_tempo_abort: defender window should clear")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures: PackedStringArray) -> void:
	var mgr_n: Node = _MgrScript.new()
	mgr_n.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_n.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_n.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pn: Dictionary = mgr_n.combatants[0]
	var en: Dictionary = mgr_n.combatants[1]
	var pn_id: int = _EntityAccess.id_int(pn)
	var en_id: int = _EntityAccess.id_int(en)
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_n, pn_id, en_id, "oberhau", {"target_part": "chest"})
	var d_plain: float = float(pn.get("state_duration", 0.0))
	var mgr_c: Node = _MgrScript.new()
	mgr_c.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_c.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_c.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pc: Dictionary = mgr_c.combatants[0]
	var ec: Dictionary = mgr_c.combatants[1]
	var pc_id: int = _EntityAccess.id_int(pc)
	var ec_id: int = _EntityAccess.id_int(ec)
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr_c,
		pc_id,
		ec_id,
		"oberhau",
		{"target_part": "chest", CombatConstants.ACTION_KEY_COUNTER_TEMPO: true}
	)
	var d_counter: float = float(pc.get("state_duration", 0.0))
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(pc, "pending_attack")
	if not pa.get(CombatConstants.PA_KEY_COUNTER_TEMPO, false):
		CombatRegressionHarness._fail(failures, "counter_tempo_windup: pa should stamp counter_tempo")
	var want_c: float = d_plain * CombatConstants.COUNTER_TEMPO_WINDUP_MULT
	if absf(d_counter - want_c) > 0.0002:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_windup: duration want %.4f got %.4f plain=%.4f"
			% [want_c, d_counter, d_plain]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_n)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_c)


## Tier 4.2 counter-tempo AI: flagged actions × **`AI_COUNTER_TEMPO_*`**; plain **>** feint on incoming target during window.
static func _run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	var a_plain: Dictionary = {
		"move_id": "oberhau",
		"target_id": atk_id,
		CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
	}
	var a_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": atk_id,
		CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
	}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, def_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, def_id, mgr, true)
	var base_mult: float = (
		CombatConstants.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT
		* CombatConstants.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
	)
	if w_plain < w_feint:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_ai: plain should beat feint got plain=%.6f feint=%.6f" % [w_plain, w_feint]
		)
	var a_no_flag: Dictionary = {"move_id": "oberhau", "target_id": atk_id}
	var w_no_flag: float = _AIPicker._get_action_weight(a_no_flag, def_id, mgr, true)
	if w_plain <= w_no_flag * base_mult * 0.99:
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_ai: counter flag should boost vs plain listing got counter=%.6f no_flag=%.6f want>%f"
			% [w_plain, w_no_flag, w_no_flag * base_mult * 0.99]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 Approach B: **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** blocks **`can_act`** until incoming wind-up is far enough along.
static func _run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	if _CounterTempo.can_act(mgr, def):
		CombatRegressionHarness._fail(failures, "counter_tempo_gate: can_act should be false at 20% wind-up")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.49)
	if _CounterTempo.can_act(mgr, def):
		CombatRegressionHarness._fail(failures, "counter_tempo_gate: can_act should be false at 49% wind-up")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.51)
	if not _CounterTempo.can_act(mgr, def):
		CombatRegressionHarness._fail(failures, "counter_tempo_gate: can_act should be true at 51% wind-up")
	if _ActionsBuilder.build(mgr, def_id).is_empty():
		CombatRegressionHarness._fail(failures, "counter_tempo_gate: build should list counter actions at 51%")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CounterTempo.process_waiting`** schedules ready once progress gate opens (not at wind-up start).
static func _run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.1)
	if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		CombatRegressionHarness._fail(failures, "counter_tempo_wait: should not signal ready at 10% wind-up")
	_CounterTempo.process_waiting(mgr, def)
	if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		CombatRegressionHarness._fail(failures, "counter_tempo_wait: process_waiting should not signal at 10%")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	_CounterTempo.process_waiting(mgr, def)
	if not bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		CombatRegressionHarness._fail(failures, "counter_tempo_wait: should signal ready after 55% wind-up")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_ui_hint_winding_then_ready(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	_CounterTempo.process_waiting(mgr, def)
	if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_winding":
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_ui: want counter_winding got %s"
			% str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
		)
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.6)
	_CounterTempo.process_waiting(mgr, def)
	if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_ready":
		CombatRegressionHarness._fail(
			failures,
			"counter_tempo_ui: want counter_ready got %s"
			% str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 riposte chain: **`grant_riposte_chain`** after deflect → next wind-up vs that attacker × **`RIPOSTE_CHAIN_WINDUP_MULT`**.
static func _run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(
	failures: PackedStringArray
) -> void:
	var mgr_p: Node = _MgrScript.new()
	mgr_p.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_p.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_p.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def_p: Dictionary = mgr_p.combatants[0]
	var atk_p: Dictionary = mgr_p.combatants[1]
	var def_p_id: int = _EntityAccess.id_int(def_p)
	var atk_p_id: int = _EntityAccess.id_int(atk_p)
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_p, def_p_id, atk_p_id, "oberhau", {"target_part": "chest"})
	var d_plain: float = float(def_p.get("state_duration", 0.0))
	var mgr_r: Node = _MgrScript.new()
	mgr_r.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_r.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_r.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def_r: Dictionary = mgr_r.combatants[0]
	var atk_r: Dictionary = mgr_r.combatants[1]
	var def_r_id: int = _EntityAccess.id_int(def_r)
	var atk_r_id: int = _EntityAccess.id_int(atk_r)
	_CounterTempo.grant_riposte_chain(mgr_r, def_r, atk_r_id)
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_r, def_r_id, atk_r_id, "oberhau", {"target_part": "chest"})
	var d_rip: float = float(def_r.get("state_duration", 0.0))
	var pa_r: Dictionary = _EntityAccess.nested_dictionary_read(def_r, "pending_attack")
	if not pa_r.get(CombatConstants.PA_KEY_RIPOSTE_CHAIN, false):
		CombatRegressionHarness._fail(failures, "riposte_chain: pending_attack should stamp riposte_chain")
	var want_r: float = d_plain * CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT
	if absf(d_rip - want_r) > 0.0002:
		CombatRegressionHarness._fail(
			failures,
			"riposte_chain: duration want %.4f got %.4f plain=%.4f"
			% [want_r, d_rip, d_plain]
		)
	if def_r.has(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL):
		CombatRegressionHarness._fail(failures, "riposte_chain: riposte window should be consumed after wind-up start")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_p)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_r)


## Tier 4.3: salience — telegraph part implies wind-up targeted.
static func _run_feint_move_listing_stance_ai_feint_mult_ordering(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	mgr.combatants[1]["off_balance_until"] = -1.0
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var enemy: Dictionary = mgr.combatants[1]
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	CombatRegressionHarness.harness_assign_form(mgr, player, _WeaponForm.FORM_FOOL)
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var mult_c: float = _WeaponForm.mod(_WeaponForm.FORM_FOOL, "ai_feint_listing")
	var form_move_ratio_c: float = (
		_WeaponForm.action_weight_mult(_EntityAccess.form_str(player), "oberhau_feint")
		/ maxf(0.001, _WeaponForm.action_weight_mult(_EntityAccess.form_str(player), "oberhau"))
	)
	var want_c: float = (
		w_plain_c
		* form_move_ratio_c
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* mult_c
	)
	if absf(w_feint_c - want_c) > 0.0001 * maxf(1.0, absf(w_plain_c)):
		CombatRegressionHarness._fail(
			failures,
			"feint_stance_list ctrl: want feint %.6f (plain*base*stance) got %.6f plain=%.6f mult=%s"
			% [want_c, w_feint_c, w_plain_c, str(mult_c)]
		)
	CombatRegressionHarness.harness_assign_form(mgr, player, _WeaponForm.FORM_WALL)
	var w_plain_d: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_d: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var mult_d: float = _WeaponForm.mod(_WeaponForm.FORM_WALL, "ai_feint_listing")
	var form_move_ratio_d: float = (
		_WeaponForm.action_weight_mult(_EntityAccess.form_str(player), "oberhau_feint")
		/ maxf(0.001, _WeaponForm.action_weight_mult(_EntityAccess.form_str(player), "oberhau"))
	)
	var want_d: float = (
		w_plain_d
		* form_move_ratio_d
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* mult_d
	)
	if absf(w_feint_d - want_d) > 0.0001 * maxf(1.0, absf(w_plain_d)):
		CombatRegressionHarness._fail(
			failures,
			"feint_stance_list def: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [want_d, w_feint_d, w_plain_d, str(mult_d)]
		)
	var r_c: float = w_feint_c / w_plain_c
	var r_d: float = w_feint_d / w_plain_d
	if r_c <= r_d + 1e-6:
		CombatRegressionHarness._fail(
			failures,
			"feint_stance_list: want controlling feint/plain ratio > defensive got c=%.6f d=%.6f"
			% [r_c, r_d]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker.opts_from_choice`** omits empty **`feint_part`**; non-**`is_feint`** **`_add_attack_target_part`** does not introduce **`feint_part`** on the choice dict.
static func _run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_before: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_AIPicker.record_opp_parry_deflect_for_feint_listing(mgr, player, e_id)
	var w_after: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_boost: float = (
		w_before * CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT
	)
	if absf(w_after - want_boost) > 0.0001 * maxf(1.0, absf(w_before)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_parry_recent: want feint %.6f got %.6f before=%.6f top=%s"
			% [
				want_boost,
				w_after,
				w_before,
				str(CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT),
			]
		)
	var tick_now: int = mgr.get_combat_tick_index()
	player[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = {
		str(e_id): tick_now - maxi(100, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS + 2)
	}
	var w_stale: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_stale - w_before) > 0.0001 * maxf(1.0, absf(w_before)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_parry_stale: want feint %.6f got %.6f before=%.6f"
			% [w_before, w_stale, w_before]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`off_balance_until`** ( **`PassiveParryContext.is_off_balance`** ) boosts feint-move listing vs that defender (**`(qp)`**).
static func _run_feint_move_listing_defender_off_balance_boosts_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_balanced: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	var w_off: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_off: float = (
		w_balanced
		* CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
		/ CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
	)
	if absf(w_off - want_off) > 0.0001 * maxf(1.0, absf(w_balanced)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_off_balance: want feint %.6f got %.6f settled_base=%.6f"
			% [want_off, w_off, w_balanced]
		)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() - 1.0
	var w_cleared: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_cleared - w_balanced) > 0.0001 * maxf(1.0, absf(w_balanced)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_off_balance_clear: want feint %.6f got %.6f base=%.6f"
			% [w_balanced, w_cleared, w_balanced]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: settled **`STATE_WAITING`** (not off-balance) dampens feint listing (**`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**); off-balance uses **`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** instead.
static func _run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures: PackedStringArray) -> void:
	var c_target_only: Dictionary = {"move_id": "oberhau", "target_id": 1, "target_part": "chest"}
	var o_target: Dictionary = _AIPicker.opts_from_choice(c_target_only)
	if not o_target.has("target_part") or str(o_target.get("target_part", "")) != "chest":
		CombatRegressionHarness._fail(failures, "feint_opts: expected target_part chest in opts got %s" % str(o_target))
	if o_target.has("feint_part"):
		CombatRegressionHarness._fail(failures, "feint_opts: non-feint choice should omit feint_part got %s" % str(o_target))
	var c_with_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": "head"
	}
	var o_both: Dictionary = _AIPicker.opts_from_choice(c_with_feint)
	if str(o_both.get("feint_part", "")) != "head":
		CombatRegressionHarness._fail(failures, "feint_opts: should forward non-empty feint_part got %s" % str(o_both))
	var c_thrust_feint: Dictionary = {
		"move_id": "thrust_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": "head",
	}
	var o_thrust_feint: Dictionary = _AIPicker.opts_from_choice(c_thrust_feint)
	if str(o_thrust_feint.get("feint_part", "")) != "head":
		CombatRegressionHarness._fail(failures, "feint_opts: thrust_feint should forward non-empty feint_part got %s" % str(o_thrust_feint))
	var c_empty_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": ""
	}
	var o_no_feint: Dictionary = _AIPicker.opts_from_choice(c_empty_feint)
	if o_no_feint.has("feint_part"):
		CombatRegressionHarness._fail(failures, "feint_opts: empty feint_part should be omitted got %s" % str(o_no_feint))
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var choice: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	_AIPicker._add_attack_target_part(choice, mgr, p_id)
	if str(choice.get("target_part", "")).is_empty():
		CombatRegressionHarness._fail(failures, "feint_neg: expected oberhau target_part from _add_attack_target_part")
	if choice.has("feint_part") and str(choice.get("feint_part", "")) != "":
		CombatRegressionHarness._fail(
			failures,
			"feint_neg: non-feint oberhau must not set non-empty feint_part got %s" % str(choice.get("feint_part", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Pass **`parry_readiness_for_feint` < 0** for default-args call (no feint read-through). Pass **`atk_id_for_spacing` < 0** (default) unless the scan must use the optional spacing arg on **`_guard_zone_modifier`**.
static func _run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var tgt_baited: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_guard_zone: no PathResolver seed yields bait penalty in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(bait_seed)
	var m_pen: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
	if not is_equal_approx(m_pen, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(
			failures,
			"feint_guard_zone: baited want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_pen]
		)
	var tgt_readjust: Dictionary = {
		"guard_zone": "left_leg",
		"guard_line": "low",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var readjust_bonus_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_readjust,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_BONUS
	)
	if readjust_bonus_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_guard_zone: no PathResolver seed yields readjust bonus in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(readjust_bonus_seed)
	var m_ok: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_readjust, parts, "oberhau_feint")
	if not is_equal_approx(m_ok, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(failures, "feint_guard_zone: readjust want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_ok])
	var pa_plain: Dictionary = {"target_part": "head", "attack_type": "oberhau"}
	var tgt_plain: Dictionary = {"guard_zone": "head", "guard_line": "high"}
	var plain_bonus_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_plain,
		tgt_plain,
		parts,
		"oberhau",
		-1.0,
		CombatConstants.GUARD_ZONE_BONUS
	)
	if plain_bonus_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_guard_zone: no PathResolver seed yields non-feint bonus in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(plain_bonus_seed)
	var m_plain: float = _DefenseChoice._guard_zone_modifier(pa_plain, tgt_plain, parts, "oberhau")
	if not is_equal_approx(m_plain, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(failures, "feint_guard_zone: non-feint want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_plain])
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: high passive parry readiness + form can read real line despite **`guard_zone`** still on telegraph (**`FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** × **`CombatWeaponForm.mod(form_str, "feint_readthrough")`**). **`AttackPathResolver`** **`randf`** — scan a bait seed for telegraph mismatch, then **`seed(bait_seed)`** before each **`_guard_zone_modifier`** so **`expected_part`** matches across cases.
static func _run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var tgt_baited: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	CombatRegressionHarness.harness_sync_weapon_form_from_stance(
		tgt_baited, CombatConstants.STANCE_DEFENSIVE
	)
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_readthrough: no PathResolver seed yields bait penalty in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(bait_seed)
	var m_default_args: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
	if not is_equal_approx(m_default_args, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(
			failures,
			"feint_readthrough: default-args (no readiness) want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_default_args]
		)
	seed(bait_seed)
	var m_full: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 1.0)
	if not is_equal_approx(m_full, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(failures, "feint_readthrough: readiness 1 defensive want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_full])
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.86)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(failures, "feint_readthrough: readiness 0.86 defensive want bonus got %.2f" % m_mid)
	seed(bait_seed)
	var m_low: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.82)
	if not is_equal_approx(m_low, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(failures, "feint_readthrough: readiness 0.82 defensive want penalty got %.2f" % m_low)
	var tgt_agg: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "aggressive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	CombatRegressionHarness.harness_sync_weapon_form_from_stance(
		tgt_agg, CombatConstants.STANCE_AGGRESSIVE
	)
	seed(bait_seed)
	var m_agg: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_agg, parts, "oberhau_feint", 0.88)
	if not is_equal_approx(m_agg, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(failures, "feint_readthrough: aggressive 0.88 want penalty got %.2f" % m_agg)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` LONG** scales **`parry_readiness_for_feint`** before **`_feint_guard_reads_real_line`** in **`_guard_zone_modifier`** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_*`**); same base readiness at **MID** stays sub-threshold, **LONG** crosses (**defensive** × **`STANCE_MOD_FEINT_READTHROUGH`**).
static func _run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var atk_id: int = 42
	var tgt_baited_base: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	CombatRegressionHarness.harness_sync_weapon_form_from_stance(
		tgt_baited_base, CombatConstants.STANCE_DEFENSIVE
	)
	var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
	tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
	var tgt_long: Dictionary = tgt_baited_base.duplicate(true)
	tgt_long["distance_to"] = {atk_id: CombatConstants.DISTANCE_LONG}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited_base,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_gz_spacing: no PathResolver seed yields bait penalty in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	var pr_spacing: float = 0.845
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id)
	seed(bait_seed)
	var m_long: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_long, parts, "oberhau_feint", pr_spacing, atk_id)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(
			failures,
			"feint_gz_spacing: mid want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_mid]
		)
	if not is_equal_approx(m_long, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(failures, "feint_gz_spacing: long want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_long])
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` CLOSE** scales **`parry_readiness_for_feint`** down before **`_feint_guard_reads_real_line`**; same base readiness at **MID** clears the gate, **CLOSE** falls below (**defensive** × **`STANCE_MOD_FEINT_READTHROUGH`**).
static func _run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var atk_id: int = 43
	var tgt_baited_base: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	CombatRegressionHarness.harness_sync_weapon_form_from_stance(
		tgt_baited_base, CombatConstants.STANCE_DEFENSIVE
	)
	var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
	tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
	var tgt_close: Dictionary = tgt_baited_base.duplicate(true)
	tgt_close["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited_base,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_gz_spacing_close: no PathResolver seed yields bait penalty in 0..16383")
		seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
		return
	var pr_spacing: float = 0.855
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id)
	seed(bait_seed)
	var m_close: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_close, parts, "oberhau_feint", pr_spacing, atk_id)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
		CombatRegressionHarness._fail(
			failures,
			"feint_gz_spacing_close: mid want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_mid]
		)
	if not is_equal_approx(m_close, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		CombatRegressionHarness._fail(
			failures,
			"feint_gz_spacing_close: close want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_close]
		)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2 telegraph delay: **`DefenseChoiceResolver._feint_readiness_reveal_mult`** — early wind-up damps toward **`FEINT_PRE_REVEAL_READINESS_MULT`** until progress ≥ **`feint_target_reveal_at_progress`** (**`WeaponConstants`** / **`pa`**); no feint / reveal **0** → **1.0**; **`choose_defense`** **`parry_readiness`** echoes the same mult when feint passive parry applies.
static func _run_feint_target_reveal_progress_scales_readiness_mult(failures: PackedStringArray) -> void:
	var pa: Dictionary = {"feint_part": "head", "attack_type": "oberhau_feint"}
	var atk0: Dictionary = {
		"state": CombatConstants.STATE_WIND_UP,
		"state_timer": 0.0,
		"state_duration": 1.0,
	}
	var reveal: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.45))
	var m0: float = _DefenseChoice._feint_readiness_reveal_mult(pa, atk0)
	var want0: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.0)
	if not is_equal_approx(m0, want0):
		CombatRegressionHarness._fail(failures, "feint_reveal t=0 want %.6f got %.6f" % [want0, m0])
	var atk_half: Dictionary = atk0.duplicate()
	atk_half["state_timer"] = reveal * 0.5 * atk0["state_duration"]
	var m_h: float = _DefenseChoice._feint_readiness_reveal_mult(pa, atk_half)
	var want_h: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.5)
	if not is_equal_approx(m_h, want_h):
		CombatRegressionHarness._fail(failures, "feint_reveal half window want %.6f got %.6f" % [want_h, m_h])
	var atk_edge: Dictionary = atk0.duplicate()
	atk_edge["state_timer"] = reveal * atk0["state_duration"]
	if not is_equal_approx(_DefenseChoice._feint_readiness_reveal_mult(pa, atk_edge), 1.0):
		CombatRegressionHarness._fail(failures, "feint_reveal at reveal_at want 1.0")
	var atk_late: Dictionary = atk0.duplicate()
	atk_late["state_timer"] = 0.99
	if not is_equal_approx(_DefenseChoice._feint_readiness_reveal_mult(pa, atk_late), 1.0):
		CombatRegressionHarness._fail(failures, "feint_reveal late want 1.0")
	var pa_no_feint: Dictionary = {"feint_part": "", "attack_type": "oberhau"}
	if _DefenseChoice._feint_readiness_reveal_mult(pa_no_feint, atk0) != 1.0:
		CombatRegressionHarness._fail(failures, "feint_reveal empty feint_part want 1.0")
	var pa_off: Dictionary = {
		"feint_part": "head",
		"feint_target_reveal_at_progress": 0.0,
		"attack_type": "oberhau_feint",
	}
	if _DefenseChoice._feint_readiness_reveal_mult(pa_off, atk0) != 1.0:
		CombatRegressionHarness._fail(failures, "feint_reveal explicit zero want 1.0")
	var atk_rec: Dictionary = atk0.duplicate()
	atk_rec["state"] = CombatConstants.STATE_RECOVERING
	if _DefenseChoice._feint_readiness_reveal_mult(pa, atk_rec) != 1.0:
		CombatRegressionHarness._fail(failures, "feint_reveal non-wind_up attacker want 1.0")
	var pa_stab: Dictionary = {"feint_part": "chest", "attack_type": "thrust_feint"}
	var reveal_stab: float = float(WeaponConstants.get_move("thrust_feint").get("feint_target_reveal_at_progress", 0.4))
	if not is_equal_approx(reveal_stab, 0.4):
		CombatRegressionHarness._fail(failures, "feint_reveal thrust_feint move want reveal 0.4 got %.6f" % reveal_stab)
	var atk_stab_half: Dictionary = atk0.duplicate()
	atk_stab_half["state_timer"] = reveal_stab * 0.5 * atk0["state_duration"]
	var m_stab_h: float = _DefenseChoice._feint_readiness_reveal_mult(pa_stab, atk_stab_half)
	if not is_equal_approx(m_stab_h, want_h):
		CombatRegressionHarness._fail(
			failures,
			"feint_reveal thrust half window want %.6f got %.6f" % [want_h, m_stab_h]
		)
	# choose_defense: reported parry_readiness scales by same mult during feint wind-up early vs late.
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["stamina"] = CombatConstants.STAMINA_MAX
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n2: Node = _EntityAccess.scene_node(defender)
	var parts2: Array = _EntityAccess.get_targetable_parts_from_node(def_n2)
	if parts2.is_empty():
		CombatRegressionHarness._fail(failures, "feint_reveal choose_def: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_fe: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch_fe: Dictionary = WeaponConstants.get_archetype(
		str(move_fe.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa_cd: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	attacker["state"] = CombatConstants.STATE_WIND_UP
	attacker["state_duration"] = 1.0
	attacker["state_timer"] = 0.0
	seed(92003)
	var dc_e: Dictionary = _DefenseChoice.choose_defense(pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0)
	attacker["state_timer"] = 0.99
	seed(92003)
	var dc_l2: Dictionary = _DefenseChoice.choose_defense(pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0)
	var pr_e: float = float(dc_e.get("parry_readiness", -1.0))
	var pr_l2: float = float(dc_l2.get("parry_readiness", -1.0))
	if pr_e <= 1e-8 or pr_l2 <= 1e-8:
		CombatRegressionHarness._fail(
			failures,
			"feint_reveal choose_def: parry_readiness too small pr_e=%.6f pr_l=%.6f" % [pr_e, pr_l2]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not is_equal_approx(pr_e / pr_l2, want0):
		CombatRegressionHarness._fail(
			failures,
			"feint_reveal choose_def: early/late readiness ratio want %.6f got %.6f (pr_e=%.6f pr_l=%.6f)"
			% [want0, pr_e / pr_l2, pr_e, pr_l2]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2b (P4e): feint-move listing **`read_m`** damps early wind-up via **`_feint_readiness_reveal_mult`** (parity with **`choose_defense`**).
static func _run_feint_move_listing_reveal_progress_dampens_early_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 1.0
	enemy["off_balance_until"] = -1.0
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var reveal: float = float(
		WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.45)
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "head",
		"target_part": "chest",
		"target_id": e_id,
		"feint_target_reveal_at_progress": reveal,
	}
	player["pending_attack"] = pa
	player["state"] = CombatConstants.STATE_WIND_UP
	player["state_duration"] = 1.0
	player["state_timer"] = 0.0
	var w_early: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_early: float = _feint_listing_read_m_expect_for_move_on_target(
		enemy, p_id, "oberhau_feint", player, pa
	)
	var settled_m: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var stance_m: float = _WeaponForm.mod(_EntityAccess.form_str(player), "ai_feint_listing")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var want_early: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_early * settled_m * stance_m
	)
	if absf(w_early - want_early) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal early: want %.6f got %.6f read_m=%.6f" % [want_early, w_early, read_early]
		)
	player["state_timer"] = 0.99
	var w_late: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_late: float = _feint_listing_read_m_expect_for_move_on_target(
		enemy, p_id, "oberhau_feint", player, pa
	)
	var want_late: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_late * settled_m * stance_m
	)
	if absf(w_late - want_late) > 0.0001 * maxf(1.0, absf(w_plain)):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal late: want %.6f got %.6f read_m=%.6f" % [want_late, w_late, read_late]
		)
	if w_late <= w_early + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal: want late > early got early=%.6f late=%.6f" % [w_early, w_late]
		)
	if read_late <= read_early + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal: read_m late want > early got early=%.6f late=%.6f"
			% [read_early, read_late]
		)
	player["state"] = CombatConstants.STATE_WAITING
	player.erase("pending_attack")
	var w_waiting: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_waiting: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	if not is_equal_approx(w_waiting, w_late):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal waiting: weight should match no-live-pa listing got %.6f late=%.6f"
			% [w_waiting, w_late]
		)
	if not is_equal_approx(read_waiting, read_late):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_reveal waiting read_m: want late read_m %.6f got %.6f"
			% [read_late, read_waiting]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`DefenseChoiceResolver.choose_defense`** — when **`feint_part`** is set and defender does not read through (**`guard` × stance `feint_readthrough` < `FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`**), **`dodge_eval_part`** can follow the telegraph; harness sets **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** to **1.0** for a deterministic assert.
static func _run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(failures: PackedStringArray) -> void:
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "feint_dodge_eval: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not parts.has("left_leg"):
		CombatRegressionHarness._fail(failures, "feint_dodge_eval: fixture needs left_leg in targetable")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
	}
	seed(1337)
	var dc: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	if str(dc.get("dodge_eval_part", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_dodge_eval: want dodge_eval_part left_leg (telegraph bait) got %s" % str(dc.get("dodge_eval_part", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`feint_guard_zone_readiness_spacing_mult`** on **`pr_rt`** for **`_feint_guard_reads_real_line`** in **`_apply_feint_telegraph_bias_to_dodge_eval_part`** — defensive **`guard`** × **`STANCE_MOD_FEINT_READTHROUGH`** fails at **MID** (**`DISTANCE_MID`**) but clears at **LONG** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG`**). Same global **`seed(s)`** before each **`choose_defense`**: **LONG** keeps the initial **`BodyPartConstants.get_weighted_random_part`** draw (scan for **≠** **`left_leg`**); **MID** with harness bias **1.0** always telegraphs **`dodge_eval_part`** to **`feint_part`**.
static func _run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "defensive"
	defender["guard"] = 0.83
	defender["state"] = CombatConstants.STATE_WAITING
	defender["stamina"] = CombatConstants.STAMINA_MAX
	var dm: Dictionary = _EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty() or not parts.has("left_leg"):
		CombatRegressionHarness._fail(failures, "feint_tele_dodge_gz_spacing: need left_leg in targetable")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
	}
	var found_seed: int = -1
	var initial_part: String = ""
	for s in range(0, 65536):
		seed(s)
		dm[atk_id] = CombatConstants.DISTANCE_LONG
		var dc_l: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		var p_l: String = str(dc_l.get("dodge_eval_part", ""))
		if p_l == "left_leg":
			continue
		seed(s)
		dm[atk_id] = CombatConstants.DISTANCE_MID
		var dc_m: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		if str(dc_m.get("dodge_eval_part", "")) == "left_leg":
			found_seed = s
			initial_part = p_l
			break
	if found_seed < 0:
		CombatRegressionHarness._fail(failures, "feint_tele_dodge_gz_spacing: no seed in 0..65535 yields non-left_leg initial at LONG + telegraph left_leg at MID")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	seed(found_seed)
	dm[atk_id] = CombatConstants.DISTANCE_LONG
	var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	seed(found_seed)
	dm[atk_id] = CombatConstants.DISTANCE_MID
	var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	if str(dc_mid.get("dodge_eval_part", "")) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_tele_dodge_gz_spacing: mid want left_leg got %s (seed=%d)" % [str(dc_mid.get("dodge_eval_part", "")), found_seed]
		)
	if str(dc_long.get("dodge_eval_part", "")) != initial_part or initial_part == "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"feint_tele_dodge_gz_spacing: long want initial %s got %s (seed=%d)"
			% [initial_part, str(dc_long.get("dodge_eval_part", "")), found_seed]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: LONG **`distance_to[attacker]`** scales feint dodge telegraph bias down vs MID (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG`**) so the same RNG draw can take telegraph bite at MID but not at LONG.
static func _run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty() or not parts.has("left_leg"):
		CombatRegressionHarness._fail(failures, "feint_telegraph_spacing: need left_leg in targetable")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
	}
	var eff_mid: float = 0.85
	var eff_long: float = 0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG
	var de_mid: String = ""
	var de_long: String = ""
	var ok_spacing: bool = false
	for s in range(0, 65536):
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
		var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
		var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		de_mid = str(dc_mid.get("dodge_eval_part", ""))
		de_long = str(dc_long.get("dodge_eval_part", ""))
		if de_mid == "left_leg" and de_long != "left_leg":
			ok_spacing = true
			break
	if not ok_spacing:
		CombatRegressionHarness._fail(
			failures,
			"feint_telegraph_spacing: no seed in 0..65535 with mid=left_leg long!=left_leg (eff_mid=%.4f eff_long=%.4f last mid=%s long=%s)"
			% [eff_mid, eff_long, de_mid, de_long]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: CLOSE **`distance_to[attacker]`** scales feint dodge telegraph bias up vs MID (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE`**) so the same RNG draw can skip telegraph bite at MID but take it at CLOSE.
static func _run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty() or not parts.has("left_leg"):
		CombatRegressionHarness._fail(failures, "feint_telegraph_spacing_close: need left_leg in targetable")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
	}
	var eff_mid: float = 0.85
	var eff_close: float = clampf(
		0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var de_mid: String = ""
	var de_close: String = ""
	var ok_spacing: bool = false
	for s in range(0, 65536):
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
		var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
		var dc_close: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		de_mid = str(dc_mid.get("dodge_eval_part", ""))
		de_close = str(dc_close.get("dodge_eval_part", ""))
		if de_mid != "left_leg" and de_close == "left_leg":
			ok_spacing = true
			break
	if not ok_spacing:
		CombatRegressionHarness._fail(
			failures,
			"feint_telegraph_spacing_close: no seed in 0..65535 with mid!=left_leg close=left_leg (eff_mid=%.4f eff_close=%.4f last mid=%s close=%s)"
			% [eff_mid, eff_close, de_mid, de_close]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: non-empty **`feint_part`** → **`CombatConstants.COMMITMENT_FRACTION_FEINT`** — same **`wind_up_duration`** and defender **`reaction_time`** can yield on-time plain parry vs late feint parry (bracket duration between the two **`effective_wind_up`** thresholds).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "feint_commitment: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_plain: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_plain: Dictionary = WeaponConstants.get_archetype(
		str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var move_feint: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch_feint: Dictionary = WeaponConstants.get_archetype(
		str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var r_time: float = def_n.get_passive_parry_reaction_time()
	var cf: float = CombatConstants.COMMITMENT_FRACTION
	var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
	var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
	var eff_plain: float = w_up * (1.0 - cf)
	var eff_feint: float = w_up * (1.0 - cff)
	if eff_plain <= r_time or eff_feint >= r_time:
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
			% [r_time, w_up, eff_plain, eff_feint]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var pa_plain: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	var pa_feint: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	seed(44002)
	var dc_plain: Dictionary = _DefenseChoice.choose_defense(
		pa_plain, attacker, defender, parts, "oberhau", arch_plain, -1.0
	)
	seed(44002)
	var dc_feint: Dictionary = _DefenseChoice.choose_defense(
		pa_feint, attacker, defender, parts, "oberhau_feint", arch_feint, -1.0
	)
	if bool(dc_plain.get("late_parry", false)):
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment: plain oberhau want on-time parry late_parry=false got late=%s"
			% str(dc_plain.get("late_parry", false))
		)
	elif not bool(dc_feint.get("late_parry", false)):
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment: feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: same bracket as **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, for **`thrust`** vs **`thrust_feint`** (**stab** archetypes).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "feint_commitment_thrust: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_plain: Dictionary = WeaponConstants.get_move("thrust")
	var arch_plain: Dictionary = WeaponConstants.get_archetype(
		str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var move_feint: Dictionary = WeaponConstants.get_move("thrust_feint")
	var arch_feint: Dictionary = WeaponConstants.get_archetype(
		str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var r_time: float = def_n.get_passive_parry_reaction_time()
	var cf: float = CombatConstants.COMMITMENT_FRACTION
	var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
	var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
	var eff_plain: float = w_up * (1.0 - cf)
	var eff_feint: float = w_up * (1.0 - cff)
	if eff_plain <= r_time or eff_feint >= r_time:
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment_thrust: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
			% [r_time, w_up, eff_plain, eff_feint]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var pa_plain: Dictionary = {
		"attack_type": "thrust",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	var pa_feint: Dictionary = {
		"attack_type": "thrust_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	seed(44002)
	var dc_plain: Dictionary = _DefenseChoice.choose_defense(
		pa_plain, attacker, defender, parts, "thrust", arch_plain, -1.0
	)
	seed(44002)
	var dc_feint: Dictionary = _DefenseChoice.choose_defense(
		pa_feint, attacker, defender, parts, "thrust_feint", arch_feint, -1.0
	)
	if bool(dc_plain.get("late_parry", false)):
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment_thrust: plain thrust want on-time parry late_parry=false got late=%s"
			% str(dc_plain.get("late_parry", false))
		)
	elif not bool(dc_feint.get("late_parry", false)):
		CombatRegressionHarness._fail(
			failures,
			"feint_commitment_thrust: thrust_feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`DefenseChoiceResolver.choose_defense`** — defender **`distance_to[attacker]`** scales **`parry_c_d`** (CLOSE / LONG vs MID) and **`dodge_chance`** at CLOSE / LONG (**`CombatConstants.DEFENSE_SPACING_*`**).
static func _run_defense_spacing_band_modulates_parry_and_dodge(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_spacing: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91001)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91001)
	var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var cd_mid: float = float(dc_mid.get("parry_c_d", 0.0))
	var cd_long: float = float(dc_long.get("parry_c_d", 0.0))
	var dodge_mid: float = float(dc_mid.get("dodge_chance", 0.0))
	var dodge_long: float = float(dc_long.get("dodge_chance", 0.0))
	if cd_mid < 1.0:
		CombatRegressionHarness._fail(failures, "defense_spacing: mid parry_c_d too small %.3f" % cd_mid)
	elif not is_equal_approx(cd_long / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG):
		CombatRegressionHarness._fail(
			failures,
			"defense_spacing: parry_c_d long/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG, cd_long / cd_mid]
		)
	elif dodge_mid <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_spacing: mid dodge_chance too small")
	elif not is_equal_approx(dodge_long / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		CombatRegressionHarness._fail(
			failures,
			"defense_spacing: dodge long/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, dodge_long / dodge_mid]
		)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91001)
	var dc_close: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var cd_close: float = float(dc_close.get("parry_c_d", 0.0))
	var dodge_close: float = float(dc_close.get("dodge_chance", 0.0))
	if not is_equal_approx(cd_close / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE):
		CombatRegressionHarness._fail(
			failures,
			"defense_spacing: parry_c_d close/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE, cd_close / cd_mid]
		)
	elif not is_equal_approx(dodge_close / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		CombatRegressionHarness._fail(
			failures,
			"defense_spacing: dodge close/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, dodge_close / dodge_mid]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** defender gets recovering dodge mult vs off-balance **`STATE_WAITING`** baseline (no settled waiting-footwork mult).
static func _run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_footwork_recovering: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91002)
	var dc_wait: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	seed(91002)
	var dc_rec: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var d_wait: float = float(dc_wait.get("dodge_chance", 0.0))
	var d_rec: float = float(dc_rec.get("dodge_chance", 0.0))
	if d_wait <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_footwork_recovering: waiting dodge_chance too small %.6f" % d_wait)
	elif not is_equal_approx(
		d_rec / d_wait, CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
	):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_recovering: dodge rec/wait want ratio %.3f got %.3f"
			% [
				CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit"),
				d_rec / d_wait,
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`recovery_cause`** selects **`CombatConstants.defense_footwork_recovering_dodge_mult_for_cause`** (**`DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE`**) on reported **`dodge_chance`**; **`attack_miss`** > **`attack_hit`** at same **`distance_to`** / seed.
static func _run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_footwork_cause: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91003)
	var d_wait: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	seed(91003)
	var d_hit: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["state"] = CombatConstants.STATE_WAITING
	defender["recovery_cause"] = "skip"
	defender["state_duration"] = 0.0
	defender["state_timer"] = 0.0
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_miss"
	seed(91003)
	var d_miss: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	var m_hit: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
	var m_miss: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_miss")
	if d_wait <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_footwork_cause: waiting dodge_chance too small %.6f" % d_wait)
	elif not is_equal_approx(d_hit / d_wait, m_hit):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_cause: hit rec/wait want %.4f got %.4f" % [m_hit, d_hit / d_wait]
		)
	elif not is_equal_approx(d_miss / d_wait, m_miss):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_cause: miss rec/wait want %.4f got %.4f" % [m_miss, d_miss / d_wait]
		)
	elif not is_equal_approx(d_miss / d_hit, m_miss / m_hit):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_cause: miss/hit ratio want %.4f got %.4f" % [m_miss / m_hit, d_miss / d_hit]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** — pair **`distance_to`** spacing (**`DEFENSE_SPACING_DODGE_MULT_*`**) multiplies before **`defense_footwork_recovering_dodge_mult_for_cause`**; LONG/CLOSE vs MID ratios match WAITING spacing harness at fixed cause.
static func _run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_footwork_rec_spacing: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91004)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var d_mid: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91004)
	var d_long: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91004)
	var d_close: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_mid <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_footwork_rec_spacing: mid dodge_chance too small %.6f" % d_mid)
	elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_rec_spacing: long/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
		)
	elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_rec_spacing: close/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** (not off-balance) gets **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** on reported **`dodge_chance`** after spacing.
static func _run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = -1.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_footwork_waiting: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91005)
	var d_settled: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	seed(91005)
	var d_off: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_off <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_footwork_waiting: off-balance dodge_chance too small %.6f" % d_off)
	elif not is_equal_approx(d_settled / d_off, CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_waiting: settled/off want ratio %.4f got %.4f"
			% [CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT, d_settled / d_off]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** — pair **`distance_to`** spacing multiplies before **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`**.
static func _run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = -1.0
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "defense_footwork_wait_spacing: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91006)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var d_mid: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91006)
	var d_long: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91006)
	var d_close: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_mid <= 1e-6:
		CombatRegressionHarness._fail(failures, "defense_footwork_wait_spacing: mid dodge_chance too small %.6f" % d_mid)
	elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_wait_spacing: long/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
		)
	elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		CombatRegressionHarness._fail(
			failures,
			"defense_footwork_wait_spacing: close/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: incoming stab **`contact_type`** scales passive **`parry_readiness`** after guard (**`PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT`** vs cut baseline) in **`DefenseChoiceResolver.choose_defense`**.
static func _run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "incoming_contact_readiness: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_ober: Dictionary = WeaponConstants.get_archetype(
		str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var move_spear: Dictionary = WeaponConstants.get_move("spear_thrust")
	var arch_spear: Dictionary = WeaponConstants.get_archetype(
		str(move_spear.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var pa_base: Dictionary = {
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(92001)
	var pa_cut: Dictionary = pa_base.duplicate()
	pa_cut["attack_type"] = "oberhau"
	var dc_cut: Dictionary = _DefenseChoice.choose_defense(pa_cut, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	var pa_stab: Dictionary = pa_base.duplicate()
	pa_stab["attack_type"] = "spear_thrust"
	seed(92001)
	var dc_stab: Dictionary = _DefenseChoice.choose_defense(pa_stab, attacker, defender, parts, "spear_thrust", arch_spear, -1.0)
	var pr_c: float = float(dc_cut.get("parry_readiness", -1.0))
	var pr_s: float = float(dc_stab.get("parry_readiness", -1.0))
	if pr_c <= 1e-6:
		CombatRegressionHarness._fail(failures, "incoming_contact_readiness: cut parry_readiness too small %.4f" % pr_c)
	elif not is_equal_approx(pr_s / pr_c, CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT):
		CombatRegressionHarness._fail(
			failures,
			"incoming_contact_readiness: stab/cut readiness ratio want %.4f got %.4f (pr_cut=%.4f pr_stab=%.4f)"
			% [CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT, pr_s / pr_c, pr_c, pr_s]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: defender **`stamina`** scales **`choose_defense`** **`parry_readiness`** (feint read-through / guard-zone / dodge telegraph) via **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** (**`DefenseChoiceResolver._defender_passive_readiness_stamina_mult`**), not the **`pr_base`** term in **`parry_c_d *= parry_capacity_mult * pr_base`**.
static func _run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if parts.is_empty():
		CombatRegressionHarness._fail(failures, "def_stam_readiness: targetable parts empty")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	defender["stamina"] = CombatConstants.STAMINA_MAX
	var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_ober: Dictionary = WeaponConstants.get_archetype(
		str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(92002)
	var dc_hi: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	defender["stamina"] = 0.0
	seed(92002)
	var dc_lo: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	var pr_hi: float = float(dc_hi.get("parry_readiness", -1.0))
	var pr_lo: float = float(dc_lo.get("parry_readiness", -1.0))
	var want: float = lerpf(
		CombatConstants.STAMINA_AT_ZERO_PARRY_MULT,
		1.0,
		CombatConstants.stamina_factor(0.0)
	) / lerpf(
		CombatConstants.STAMINA_AT_ZERO_PARRY_MULT,
		1.0,
		CombatConstants.stamina_factor(1.0)
	)
	if pr_hi <= 1e-6:
		CombatRegressionHarness._fail(failures, "def_stam_readiness: full-stamina parry_readiness too small %.4f" % pr_hi)
	elif not is_equal_approx(pr_lo / pr_hi, want):
		CombatRegressionHarness._fail(
			failures,
			"def_stam_readiness: low/full readiness ratio want %.4f got %.4f (pr_lo=%.4f pr_hi=%.4f)"
			% [want, pr_lo / pr_hi, pr_lo, pr_hi]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — feint listing applies **`passive_parry_readiness_incoming_contact_mult`** to defender readiness: stab feint (**`thrust_feint`**) vs cut feint (**`oberhau_feint`**) at defender **`guard`** **1.0** (**SWORD** 1v1).
static func _run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 1.0
	if not WeaponConstants.is_feint_move("thrust_feint"):
		CombatRegressionHarness._fail(failures, "feint_list_incoming_ct: thrust_feint should register as is_feint")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var a_plain_c: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint_c: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var a_plain_s: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint_s: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	var wpc: float = _AIPicker._get_action_weight(a_plain_c, p_id, mgr, true)
	var wfc: float = _AIPicker._get_action_weight(a_feint_c, p_id, mgr, true)
	var wps: float = _AIPicker._get_action_weight(a_plain_s, p_id, mgr, true)
	var wfs: float = _AIPicker._get_action_weight(a_feint_s, p_id, mgr, true)
	if wpc <= 1e-8 or wps <= 1e-8:
		CombatRegressionHarness._fail(failures, "feint_list_incoming_ct: plain weights too small pc=%.8f ps=%.8f" % [wpc, wps])
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var boost_c: float = wfc / wpc
	var boost_s: float = wfs / wps
	if boost_s >= boost_c - 1e-5:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_incoming_ct: stab feint/thrust plain boost %.6f should be < cut feint/oberhau plain %.6f"
			% [boost_s, boost_c]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — feint listing defender readiness matches **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** after passive × incoming **`contact_type`** ( **`w_feint_lo` / `w_feint_hi` == read_m ratio**; attacker stamina full).
static func _run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.44
	mgr._recompute_zoc_and_distance()
	var pr_base: float = _DefenseChoice.defender_feint_listing_pr_def(
		enemy, p_id, "oberhau_feint", {}, {}, false, false
	)
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var pr_hi: float = clampf(
		pr_base
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var read_hi: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_hi
	)
	enemy["stamina"] = 0.0
	var pr_lo: float = clampf(
		pr_base
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var read_lo: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_lo
	)
	var want: float = read_lo / read_hi
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["stamina"] = 0.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_def_stam: plain weight should not depend on defender stamina lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	elif w_feint_hi <= 1e-8:
		CombatRegressionHarness._fail(failures, "feint_list_def_stam: full-stamina feint weight too small %.8f" % w_feint_hi)
	elif not is_equal_approx(w_feint_lo / w_feint_hi, want):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_def_stam: feint weight ratio want %.6f got %.6f (w_lo=%.6f w_hi=%.6f)"
			% [want, w_feint_lo / w_feint_hi, w_feint_lo, w_feint_hi]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender low stamina on feint **`read_m`** × attacker low stamina on **`AI_FEINT_LISTING_STAMINA_*`** multiply independently (**`w_ll/w_ml` == `w_lm/w_mm`** for **`oberhau_feint`**).
static func _run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.44
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	mgr._recompute_zoc_and_distance()
	var w_mm: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	mgr._recompute_zoc_and_distance()
	var w_ml: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stamina"] = 0.0
	mgr._recompute_zoc_and_distance()
	var w_lm: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	enemy["stamina"] = 0.0
	mgr._recompute_zoc_and_distance()
	var w_ll: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if w_mm <= 1e-8 or w_ml <= 1e-8:
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam_ortho: feint weights too small mm=%.8f ml=%.8f" % [w_mm, w_ml]
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var lhs: float = w_ll / w_ml
	var rhs: float = w_lm / w_mm
	if not is_equal_approx(lhs, rhs):
		CombatRegressionHarness._fail(
			failures,
			"feint_list_stam_ortho: w_ll/w_ml %.6f vs w_lm/w_mm %.6f (mm=%.6f ml=%.6f lm=%.6f ll=%.6f)"
			% [lhs, rhs, w_mm, w_ml, w_lm, w_ll]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: second **`AttackWindUpStarter.start`** without resolve clears prior defender **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** then restamps for the new wind-up.
static func _run_feint_telegraph_scrubbed_on_combat_manager_restart(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "left_leg", "feint_part": "head"}
	)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		CombatRegressionHarness._fail(
			failures,
			"feint_restart: expected telegraph head before second start got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if e.has(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART):
		CombatRegressionHarness._fail(
			failures,
			"feint_restart: second start should scrub incoming telegraph key got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.1: `stance_ai_targeting_mult` orders defensive < balanced < aggressive. See `docs/LIVE_PATHS.md#tier-4--ai--footwork--flurry`.
static func run_before_attention(failures: PackedStringArray) -> void:
	_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures)
	_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(failures)
	_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(failures)
	_run_feint_windup_duration_mult_extends_state_duration_vs_thrust(failures)
	_run_feint_windup_target_only_sets_defender_guard_zone_to_target(failures)
	_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(failures)
	_run_feint_move_ai_distinct_feint_and_target_parts(failures)
	_run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures)
	_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(failures)
	_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(failures)
	_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(failures)
	_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(failures)
	_run_feint_move_listing_spacing_long_dampens_vs_mid(failures)
	_run_feint_move_listing_spacing_close_boosts_vs_mid(failures)
	_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(failures)
	_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(failures)
	_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(failures)
	_run_feint_move_listing_stamina_low_dampens_feint_weight(failures)
	_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(failures)
	_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(failures)
	_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(failures)
	_run_feint_move_listing_doctrine_probing_multiplies_feint_weight(failures)
	_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(failures)
	_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(failures)
	_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(failures)
	_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(failures)
	_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(failures)
	_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(failures)
	_run_counter_tempo_window_opens_on_incoming_wind_up(failures)
	_run_counter_tempo_lists_melee_actions_when_window_open(failures)
	_run_counter_tempo_spend_gauge_subtracts_cost(failures)
	_run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(failures)
	_run_counter_tempo_abort_cancels_pending_incoming_melee(failures)
	_run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures)
	_run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(failures)
	_run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(failures)
	_run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(failures)
	_run_counter_tempo_ui_hint_winding_then_ready(failures)
	_run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(failures)


## III-8: legacy **`parry_deflect`** cause alias aligns passive readiness + tier-4.2 footwork with **`attack_deflect`**.
static func _run_recovery_cause_parry_deflect_alias_aligns_readiness_and_footwork(
	failures: PackedStringArray
) -> void:
	var def_curve: Array = CombatConstants.readiness_curve_for_cause("attack_deflect")
	var alias_curve: Array = CombatConstants.readiness_curve_for_cause("parry_deflect")
	if alias_curve != def_curve:
		CombatRegressionHarness._fail(
			failures,
			"recovery_cause_alias: readiness parry_deflect want %s got %s" % [def_curve, alias_curve]
		)
	var m_def: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_deflect")
	var m_alias: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("parry_deflect")
	if not is_equal_approx(m_def, m_alias):
		CombatRegressionHarness._fail(
			failures,
			"recovery_cause_alias: footwork parry_deflect want %.4f got %.4f" % [m_def, m_alias]
		)
	var c: Dictionary = {
		"state": CombatConstants.STATE_RECOVERING,
		"state_duration": 1.0,
		"state_timer": 0.5,
		"recovery_cause": "parry_deflect",
	}
	var c_canon: Dictionary = c.duplicate(true)
	c_canon["recovery_cause"] = "attack_deflect"
	var r_alias: float = _PassiveParryCtx.get_passive_parry_readiness(c)
	var r_canon: float = _PassiveParryCtx.get_passive_parry_readiness(c_canon)
	if not is_equal_approx(r_alias, r_canon):
		CombatRegressionHarness._fail(
			failures,
			"recovery_cause_alias: passive readiness want %.4f got %.4f" % [r_canon, r_alias]
		)
	var m_partial: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("parry_partial")
	if not is_equal_approx(m_def, m_partial):
		CombatRegressionHarness._fail(
			failures,
			"recovery_cause_alias: footwork parry_partial want %.4f got %.4f" % [m_def, m_partial]
		)


## III-8: canonical causes share readiness curves + inverse feint/dodge footwork mults.
static func _run_iii8_recovery_cause_table_parity(failures: PackedStringArray) -> void:
	const causes: Array = ["attack_hit", "attack_miss", "attack_deflect", "skip"]
	for k in causes:
		if not CombatConstants.DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE.has(k):
			CombatRegressionHarness._fail(
				failures, "iii8_table: missing footwork mult for cause %s" % k
			)
		var curve: Array = CombatConstants.readiness_curve_for_cause(str(k))
		if curve.size() < 2:
			CombatRegressionHarness._fail(
				failures, "iii8_table: readiness curve for %s want [early, late]" % k
			)
		var dodge_m: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause(str(k))
		var feint_m: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
			str(k)
		)
		if not is_equal_approx(feint_m, 1.0 / dodge_m):
			CombatRegressionHarness._fail(
				failures,
				"iii8_table: feint/dodge inverse mismatch for %s dodge=%.4f feint=%.4f"
				% [k, dodge_m, feint_m]
			)
	var m_hit: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
	var m_miss: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_miss")
	if m_miss <= m_hit:
		CombatRegressionHarness._fail(
			failures,
			"iii8_table: attack_miss dodge mult want > attack_hit got miss=%.4f hit=%.4f"
			% [m_miss, m_hit]
		)
	var hit_curve: Array = CombatConstants.readiness_curve_for_cause("attack_hit")
	var miss_curve: Array = CombatConstants.readiness_curve_for_cause("attack_miss")
	if float(miss_curve[1]) <= float(hit_curve[1]):
		CombatRegressionHarness._fail(
			failures,
			"iii8_table: attack_miss late readiness want > attack_hit"
		)


static func run_after_attention(failures: PackedStringArray) -> void:
	_run_feint_move_listing_stance_ai_feint_mult_ordering(failures)
	_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(failures)
	_run_feint_move_listing_defender_off_balance_boosts_feint_weight(failures)
	_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures)
	_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(failures)
	_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures)
	_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures)
	_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures)
	_run_feint_target_reveal_progress_scales_readiness_mult(failures)
	_run_feint_move_listing_reveal_progress_dampens_early_wind_up(failures)
	_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(failures)
	_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(failures)
	_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures)
	_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures)
	_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(failures)
	_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(failures)
	_run_defense_spacing_band_modulates_parry_and_dodge(failures)
	_run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures)
	_run_recovery_cause_parry_deflect_alias_aligns_readiness_and_footwork(failures)
	_run_iii8_recovery_cause_table_parity(failures)
	_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures)
	_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(failures)
	_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(failures)
	_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(failures)
	_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures)
	_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(failures)
	_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(failures)
	_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(failures)
	_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(failures)
	_run_feint_telegraph_scrubbed_on_combat_manager_restart(failures)
