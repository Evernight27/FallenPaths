class_name CombatRegressionHarnessAttentionFootworkTail
extends RefCounted

## Tier 4.2–4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) · **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) · **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** · PA hub **`#wf-tier-44-pa`**.

const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MedicalActionStarter := preload("res://combat/MedicalActionStarter.gd")
const _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _CombatSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")


static func _t44_harness_ensure_flurry_bind() -> bool:
	var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
	CombatConstants.set_feature_flurry_bind_exchange_load(true)
	return saved


static func _t44_harness_restore_flurry_bind(saved: bool) -> void:
	CombatConstants.set_feature_flurry_bind_exchange_load(saved)
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _VacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")


static func _harness_immediate_peril_bleeding_chest(ent: Node, blood_volume: float) -> void:
	if ent == null:
		return
	ent.blood_volume = blood_volume
	_EntityWounds.add_wound(
		ent, "chest", _Bleeding.INJURY_TYPE_CUT, 9.0, "thoracic", _Bleeding.SEVERITY_MODERATE
	)


static func _run_attention_being_wind_up_targeted_when_telegraph_set(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	if not _Attention.is_being_wind_up_targeted(mgr, def_id):
		CombatRegressionHarness._fail(failures, "attention_wind_up_targeted: expected true when telegraph set")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: counter salience tracks **`CounterTempo.can_act`**.
static func _run_attention_counter_tempo_salience_matches_can_act(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	var can: bool = _CounterTempo.can_act(mgr, def)
	var sal: bool = _Attention.has_actionable_counter_tempo(mgr, def)
	if sal != can:
		CombatRegressionHarness._fail(failures, "attention_counter_salience: want %s got %s" % [str(can), str(sal)])
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: peril + incoming telegraph stack **`attention_load`**.
static func _run_attention_load_stacks_peril_and_incoming(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var atk: Dictionary = mgr.combatants[2]
	var medic_id: int = _EntityAccess.id_int(medic)
	var atk_id: int = _EntityAccess.id_int(atk)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
	_WindUpStarter.start(mgr, atk_id, medic_id, "oberhau")
	_Attention.refresh_salience(mgr, medic_id)
	var load: float = _Attention.get_attention_load(medic)
	var want_min: float = (
		CombatConstants.ATTENTION_LOAD_TELEGRAPH_WEIGHT
		+ CombatConstants.ATTENTION_LOAD_PERIL_WEIGHT
	) * 0.99
	if load < want_min:
		CombatRegressionHarness._fail(
			failures,
			"attention_load_stack: want load >= %.4f got %.4f" % [want_min, load]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: wrong-line focus dampens feint read-through line mult vs correct-line focus.
static func _run_focus_intensity_scales_feint_readthrough_and_guard_zone(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {
		"guard_zone": "head",
		"guard": 0.95,
		"stance": CombatConstants.STANCE_BALANCED,
		"state": CombatConstants.STATE_WAITING,
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
	}
	var pa: Dictionary = {"feint_part": "head", "target_part": "chest", "attack_type": "oberhau_feint"}
	var wrong_m: float = _Attention.focus_line_mult_for_feint(def, pa)
	_Attention.set_focus(def, "chest")
	var right_m: float = _Attention.focus_line_mult_for_feint(def, pa)
	if wrong_m >= right_m:
		CombatRegressionHarness._fail(
			failures,
			"focus_line_mult: wrong %.4f should be < correct %.4f" % [wrong_m, right_m]
		)
	if absf(wrong_m - CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT) > 0.0001:
		CombatRegressionHarness._fail(failures, "focus_line_mult wrong: want %.4f got %.4f" % [CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT, wrong_m])


## Tier 4.3: high **`attention_load`** reduces **`focus_effective`**.
static func _run_attention_load_dampens_focus_effective_readiness(failures: PackedStringArray) -> void:
	var c: Dictionary = {CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0}
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 0.0
	var fe_clear: float = _Attention.focus_effective(c)
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 1.0
	var fe_load: float = _Attention.focus_effective(c)
	var want_load: float = 1.0 - CombatConstants.ATTENTION_LOAD_FOCUS_PENALTY
	if absf(fe_clear - 1.0) > 0.0001:
		CombatRegressionHarness._fail(failures, "focus_effective clear: want 1.0 got %.4f" % fe_clear)
	if absf(fe_load - want_load) > 0.0001:
		CombatRegressionHarness._fail(failures, "focus_effective load: want %.4f got %.4f" % [want_load, fe_load])




## Enemy win still ends combat immediately (no medical phase).
static func _run_mental_stack_medical_overrides_attack(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[2])
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	_harness_immediate_peril_bleeding_chest(ally_ent, 30.0)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"

	var actions: Array = [
		{"move_id": "oberhau", "target_id": enemy_id},
		{
			"move_id": "apply_direct_pressure",
			"target_id": ally_id,
			"target_part": "chest",
		},
	]

	# --- Robust diagnostics: each step fails with full context on mismatch ---
	var _ctx: String = ""
	_ctx += "medic_id=%d ally_id=%d enemy_id=%d med_phase=%s |" % [
		medic_id, ally_id, enemy_id, str(mgr.medical_phase)]

	# 1. Verify entity setup
	var _ally_bv: float = -1.0
	if ally_ent != null:
		_ally_bv = float(ally_ent.get("blood_volume"))
	_ctx += " bv=%.1f|" % _ally_bv
	if _ally_bv > 42.0:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: ally blood_volume=%.1f > 42 threshold — peril won't trigger" % _ally_bv)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 2. Verify is_in_immediate_peril on ally (direct, via combatant dict)
	var _ally_peril: bool = _EntityAccess.is_in_immediate_peril(mgr, ally)
	_ctx += " peril=%s|" % str(_ally_peril)
	if not _ally_peril:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: is_in_immediate_peril(ally)=false — expected true")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 3. Verify L0: medic NOT in peril
	var _medic_peril: bool = _EntityAccess.is_in_immediate_peril(mgr, medic)
	_ctx += " medic_peril=%s|" % str(_medic_peril)
	if _medic_peril:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: is_in_immediate_peril(medic)=true — should be false")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 4. Verify L1 trigger: ally_in_immediate_peril from attention perspective
	var _l1_ally_peril: bool = _Attention.ally_in_immediate_peril(mgr, medic_id)
	_ctx += " l1_peril=%s|" % str(_l1_ally_peril)
	if not _l1_ally_peril:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: ally_in_immediate_peril(medic)=false — expected true")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 5. Verify coordinated medical filter includes the pressure action
	var _coordinated: Array = _MentalStack._filter_coordinated_medical_actions(actions, medic_id, mgr)
	var _coord_has_pressure: bool = false
	for _ca in _coordinated:
		if _ca is Dictionary:
			var _dca: Dictionary = _ca as Dictionary
			if str(_dca.get("move_id", "")) == "apply_direct_pressure":
				_coord_has_pressure = true
				break
	_ctx += " coord_count=%d|" % _coordinated.size()
	if not _coord_has_pressure:
		var _fallback_list: Array = _MentalStack._filter_ally_medical_actions_fallback(actions, medic_id, mgr)
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_medical diag: coordinated filter empty (count=%d), fallback count=%d — medical_action_allowed likely failed"
			% [_coordinated.size(), _fallback_list.size()])
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 6. Verify coordination blocked reason is empty for the pressure action
	var _blocked_reason: String = _MedicalCoord.medical_action_coordination_blocked(
		mgr, medic_id, ally_id, "chest", "apply_direct_pressure")
	if not _blocked_reason.is_empty():
		_ctx += " blocked='%s'|" % _blocked_reason
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: coordination_blocked='%s'" % _blocked_reason)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 7. Verify can_stack_assist_pressure is FALSE (no compression yet)
	var _can_stack: bool = _MedicalCoord.can_stack_assist_pressure(mgr, medic_id, ally_id, "chest")
	_ctx += " can_stack=%s|" % str(_can_stack)
	if _can_stack:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: can_stack_assist_pressure=true — expected false (no compression yet)")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# 8. Verify entity bleeding rate for chest > 0
	var _ally_dict: Dictionary = _EntityAccess.manager_get_combatant(mgr, ally_id)
	var _bleed_rate: float = 0.0
	if not _ally_dict.is_empty():
		_bleed_rate = _EntityAccess.entity_bleeding_rate_for_part(mgr, _ally_dict, "chest")
	_ctx += " bleed_rate=%.2f|" % _bleed_rate
	if _bleed_rate <= 0.0:
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical diag: entity_bleeding_rate_for_part(chest)=%.2f — expected > 0" % _bleed_rate)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	# --- Run try_pick and verify result ---
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	_ctx += " pick=%s|" % str(picked)

	if picked.is_empty():
		CombatRegressionHarness._fail(
			failures, "mental_stack_medical: expected stack pick (all layers returned empty). ctx=" + _ctx)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	var _picked_move: String = str(picked.get("move_id", ""))
	var _post_c: Dictionary = _EntityAccess.manager_get_combatant(mgr, medic_id)
	var _picked_layer: String = str(_post_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "NONE"))
	_ctx += " move=%s layer=%s" % [_picked_move, _picked_layer]

	if not mgr._is_medical_move(_picked_move):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_medical: want medical move got '%s' (ctx=%s)" % [_picked_move, _ctx])
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	if _picked_layer != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_medical: expected layer=%s got layer=%s move=%s (ctx=%s)"
			% [CombatConstants.MENTAL_STACK_LAYER_MEDICAL, _picked_layer, _picked_move, _ctx])
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return

	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: incoming wind-up restricts picks to counter or melee vs attacker.
static func _run_mental_stack_incoming_windup_prefers_defense(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	var actions: Array = [
		{"move_id": "oberhau", "target_id": atk_id},
		{"move_id": "wait"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, def_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_incoming: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var tid: int = int(picked.get("target_id", -1))
	if bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
		pass
	elif tid != atk_id:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_incoming: pick should target incoming attacker %d got target %d move %s"
			% [atk_id, tid, str(picked.get("move_id", ""))]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: counter window open → stack prefers counter-tempo listing.
static func _run_mental_stack_counter_over_plain_attack_when_window_open(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + float(atk.get("state_duration", 0.0)),
		"data": {},
	})
	var actions: Array = _ActionsBuilder.build(mgr, def_id)
	var saw_counter: bool = false
	for raw in actions:
		if typeof(raw) == TYPE_DICTIONARY and bool((raw as Dictionary).get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			saw_counter = true
			break
	if not saw_counter:
		CombatRegressionHarness._fail(failures, "mental_stack_counter: expected counter_tempo in action list")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _MentalStack.try_pick(actions, def_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_counter: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_counter: want counter_tempo action got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: no salience → **`try_pick`** empty; attack weights unchanged with stack off.
static func _run_mental_stack_attack_layer_matches_stance_alias_weights(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var a: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var actions: Array = [a]
	var stacked: Dictionary = _MentalStack.try_pick(actions, p_id, mgr)
	if not stacked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack: try_pick should be empty without salience")
	var w: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(false)
	var stacked_off: Dictionary = _MentalStack.try_pick(actions, p_id, mgr)
	var w_off: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(true)
	if not stacked_off.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack: try_pick off should stay empty")
	if absf(w - w_off) > 0.0001 * maxf(1.0, absf(w)):
		CombatRegressionHarness._fail(failures, "mental_stack: weight changed %.6f vs %.6f" % [w, w_off])
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: repeated high-line attacks raise yomi feint mult on that line.
static func _run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 7
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	var m0: float = _Attention.yomi_feint_listing_mult(def, atk_id, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	var m1: float = _Attention.yomi_feint_listing_mult(def, atk_id, "head")
	if m1 <= m0 or m0 <= 1.0:
		CombatRegressionHarness._fail(
			failures,
			"yomi_feint: mult should rise above 1.0 got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.3 UI: **`format_attention_ui_hint`** includes telegraph + focus when incoming.
static func _run_yomi_updates_on_parry_deflect_clears_on_hit(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 3
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var root: Dictionary = def.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, {}) as Dictionary
	var entry: Dictionary = root.get(str(atk_id), {}) as Dictionary
	if int(entry.get("parry_deflect", 0)) != 1:
		CombatRegressionHarness._fail(failures, "yomi_parry: want parry_deflect count 1")
	_Attention.clear_yomi_for_attacker(def, atk_id)
	if def.has(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER):
		CombatRegressionHarness._fail(failures, "yomi_clear: yomi root should be empty after clear")


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", probing)`** multiplies feint listing by **`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**; then **`hold_lane`** applies **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no probing mult).
static func _run_attention_ui_hint_formats_when_telegraph_set(failures: PackedStringArray) -> void:
	var def: Dictionary = {
		"guard_zone": "head",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
		CombatConstants.COMBATANT_KEY_ATTENTION_LOAD: 0.2,
	}
	var hint: String = _Attention.format_attention_ui_hint(def)
	if not hint.contains("Tel head"):
		CombatRegressionHarness._fail(failures, "attention_ui_hint: want Tel head in '%s'" % hint)
	if not hint.contains("Focus head"):
		CombatRegressionHarness._fail(failures, "attention_ui_hint: want Focus head in '%s'" % hint)
	if not hint.contains("Load"):
		CombatRegressionHarness._fail(failures, "attention_ui_hint: want Load segment in '%s'" % hint)


## Tier 4.3 UI: **`refresh_for_waiting_tick`** stamps **`COMBATANT_KEY_ATTENTION_UI_HINT`**.
static func _run_attention_refresh_waiting_tick_stamps_ui_hint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	_WindUpStarter.start(mgr, _EntityAccess.id_int(atk), _EntityAccess.id_int(def), "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	_StateHandlers.process_waiting(mgr, def, 0.05)
	var hint: String = str(def.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, ""))
	if hint.is_empty():
		CombatRegressionHarness._fail(failures, "attention_ui_refresh: expected non-empty attention_ui_hint")
	_WindUpStarter.clear_incoming_attack_telegraph_from_pa(
		mgr, _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	)
	if def.has(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT):
		CombatRegressionHarness._fail(failures, "attention_ui_refresh: hint should clear when telegraph cleared")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: yomi habit line sets AI **`focus_part`** on drift.
static func _run_yomi_focus_drift_sets_habitual_part_on_ai(failures: PackedStringArray) -> void:
	var def: Dictionary = {"side": "enemy", "is_party_leader": false}
	var atk_id: int = 11
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.apply_yomi_focus_drift(null, def, atk_id)
	if _Attention.get_focus_part(def) != "head":
		CombatRegressionHarness._fail(
			failures,
			"yomi_focus_drift: want focus head got %s" % _Attention.get_focus_part(def)
		)


## Tier 4.3: mismatched feint telegraph line keeps habitual focus (not bait part).
static func _run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {
		"side": "enemy",
		"is_party_leader": false,
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "left_arm",
	}
	var atk_id: int = 12
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.apply_yomi_focus_drift(null, def, atk_id)
	if _Attention.get_focus_part(def) != "head":
		CombatRegressionHarness._fail(
			failures,
			"yomi_focus_drift_mismatch: want habit head got %s" % _Attention.get_focus_part(def)
		)


## Tier 4.3: explicit guard move updates **`focus_part`** with **`guard_zone`**.
static func _run_guard_from_move_syncs_focus_part_with_guard_line(failures: PackedStringArray) -> void:
	var c: Dictionary = {
		"guard_line": CombatConstants.GUARD_DEFAULT,
		"guard_zone": "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
	}
	_GuardLineUpdater.set_guard_from_line(c, "low")
	if str(c.get("guard_zone", "")) != "left_leg":
		CombatRegressionHarness._fail(failures, "guard_focus_sync: want guard_zone left_leg got %s" % str(c.get("guard_zone")))
	if _Attention.get_focus_part(c) != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"guard_focus_sync: want focus left_leg got %s" % _Attention.get_focus_part(c)
		)


## Tier 4.3: mental stack stamps **`COMBATANT_KEY_MENTAL_STACK_LAYER`** on layer pick.
static func _run_mental_stack_stamps_layer_on_medical_pick(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	_harness_immediate_peril_bleeding_chest(ally_ent, 30.0)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var actions: Array = [
		{"move_id": "oberhau", "target_id": _EntityAccess.id_int(mgr.combatants[2])},
		{"move_id": "apply_direct_pressure", "target_id": ally_id, "target_part": "chest"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_layer: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_MEDICAL:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_layer: want medical got %s"
			% str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: self immediate peril picks coordinated self-aid before ally medical.
static func _run_mental_stack_self_peril_before_ally_medical(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var medic_ent: Node = _EntityAccess.get_entity_from_manager(mgr, medic)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	_harness_immediate_peril_bleeding_chest(medic_ent, 28.0)
	_harness_immediate_peril_bleeding_chest(ally_ent, 32.0)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var actions: Array = [
		{"move_id": "oberhau", "target_id": _EntityAccess.id_int(mgr.combatants[2])},
		{"move_id": "apply_direct_pressure", "target_id": medic_id, "target_part": "chest"},
		{"move_id": "apply_direct_pressure", "target_id": ally_id, "target_part": "chest"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_self: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_SELF_MEDICAL:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_self: want self_medical layer got %s"
			% str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if int(picked.get("target_id", -1)) != medic_id:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_self: want self target %d got %d" % [medic_id, int(picked.get("target_id", -1))]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3: hold-line-only menu → **`wait`** unless incoming telegraph needs another guard line.
static func _run_mental_stack_hold_line_only_picks_focus_or_wait(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var back: Dictionary = mgr.combatants[0]
	var back_id: int = _EntityAccess.id_int(back)
	back["guard_line"] = "low"
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": back_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": back_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, back_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_hold: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(back.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_hold: want hold_line got %s"
			% str(back.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
		CombatRegressionHarness._fail(
			failures, "mental_stack_hold: no telegraph want wait got %s" % str(picked.get("move_id", ""))
		)
	back[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	# Simulate wind-up targeting without full manager telegraph wiring — layer only checks key + targeted.
	if not _Attention.is_being_wind_up_targeted(mgr, back_id):
		CombatRegressionHarness._fail(failures, "mental_stack_hold: setup want wind_up targeted")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked_tele: Dictionary = _MentalStack.try_pick(actions, back_id, mgr)
	if str(picked_tele.get("move_id", "")) != CombatConstants.MOVE_ID_FOCUS_HIGH:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_hold: telegraph head vs guard low want focus_high got %s"
			% str(picked_tele.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 Track A PR7: L4 reserve posture wing with LONG close listed → **`attempt_close`** (not **`wait`**).
static func _run_mental_stack_hold_line_attempt_close_wing(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
	if wing.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: missing wing/enemy fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	# Nearest-wing maps rank-0 wings to outer enemies; use depth-only hostiles so L4 close path still applies.
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy" and _EntityAccess.rank_int(c) == 0:
			c["rank"] = 1
	var wing_id: int = _EntityAccess.id_int(wing)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	if not _EngagementOpposition.wing_lacks_mapped_opposition(mgr, wing):
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: setup want wing_lacks_mapped_opposition")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(wing, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_LONG
	wing["gauge"] = 100.0
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": wing_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": wing_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	if not _ListedActions.action_list_is_reserve_posture_only(actions):
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: setup want reserve_posture_only menu")
	var picked: Dictionary = _MentalStack.try_pick(actions, wing_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(wing.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_close_wing: want hold_line got %s"
			% str(wing.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_close_wing: want attempt_close got %s" % str(picked.get("move_id", ""))
		)
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, wing, actions)
	if hint.is_empty() or not hint.contains("close"):
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: want wing close hint got '%s'" % hint)
	# Mapped-opposed center (rank-0 vs rank-0) still defaults to wait when reserve-only without close need.
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 2)
	var e_front: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy" and _EntityAccess.file_int(c) == 1:
			c["rank"] = 0
			e_front = c
			break
	if center.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_close_wing: missing center fixture")
	else:
		var center_id: int = _EntityAccess.id_int(center)
		if _EngagementOpposition.wing_lacks_mapped_opposition(mgr, center):
			CombatRegressionHarness._fail(failures, "mental_stack_close_wing: center should have mapped opposition")
		var center_actions: Array = [
			{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
			{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
		]
		dist = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
		dist[enemy_id] = CombatConstants.DISTANCE_LONG
		var center_pick: Dictionary = _MentalStack.try_pick(center_actions, center_id, mgr)
		if str(center_pick.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
			CombatRegressionHarness._fail(
				failures,
				"mental_stack_close_wing: mapped center want wait got %s"
				% str(center_pick.get("move_id", ""))
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mapped center during mop-up still L4-picks **`attempt_close`** (not wing_lacks-only).
static func _run_mental_stack_hold_line_attempt_close_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: setup want envelop_mop_up_active")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: missing center/enemy fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if _EngagementOpposition.wing_lacks_mapped_opposition(mgr, center):
		CombatRegressionHarness._fail(
			failures, "mental_stack_close_mop_up: center should have mapped opposition"
		)
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_LONG
	center["gauge"] = 100.0
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	if not _CombatDoctrine.hold_line_close_pick_eligible(mgr, center):
		CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up: want hold_line_close_pick_eligible")
	var picked: Dictionary = _MentalStack.try_pick(actions, center_id, mgr)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_close_mop_up: want attempt_close got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: L4 picks **`attempt_close`** at MID band during mop-up (band/reach gap).
static func _run_mental_stack_hold_line_attempt_close_mop_up_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up_mid: missing fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_MID
	center["gauge"] = 100.0
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	if not _MeleeListing.attempt_close_listed_for_pair(
		mgr, center, enemy_id, CombatConstants.DISTANCE_MID
	):
		CombatRegressionHarness._fail(failures, "mental_stack_close_mop_up_mid: setup want close listed at MID")
	var picked: Dictionary = _MentalStack.try_pick(actions, center_id, mgr)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_close_mop_up_mid: want attempt_close got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up close beats focus retarget even under incoming telegraph (no focus_* tail loop).
static func _run_mental_stack_close_beats_focus_mop_up_under_telegraph(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(
			failures, "mental_stack_close_beats_focus_mop_up: missing center/enemy fixtures"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_LONG
	center["gauge"] = 100.0
	center["guard_line"] = "low"
	center[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	if not _Attention.is_being_wind_up_targeted(mgr, center_id):
		CombatRegressionHarness._fail(
			failures, "mental_stack_close_beats_focus_mop_up: setup want wind_up targeted"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, center_id, mgr)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_close_beats_focus_mop_up: want attempt_close got %s"
			% str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line gauge hint when `attempt_close` is listed.
static func _run_hold_line_hint_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "hold_line_hint_mop_up: missing center/enemy fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": center_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, center, actions)
	if hint.is_empty() or not hint.contains("Mop-up"):
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up: want mop-up hint got '%s'" % hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: mop-up hold-line hint when listed melee strikes finish the last enemy.
static func _run_hold_line_hint_mop_up_strikes_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_strikes: missing center/enemy fixtures"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": center_id},
		{"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
	]
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, center, actions)
	if hint.is_empty() or not hint.contains("Mop-up"):
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_strikes: want mop-up hint got '%s'" % hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up beats generic back-rank copy.
static func _run_hold_line_hint_mop_up_rear_rank(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 14:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 7, "ranks": 2, "density": "normal"},
		{"files": 3, "ranks": 1, "density": "normal"}
	)
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if rear.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_rear: missing rear/enemy fixtures"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
		{"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
	]
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
	if hint.is_empty() or not hint.contains("Mop-up"):
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_rear: want mop-up hint got '%s'" % hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## III-4 **3e**: rear rank with listed strikes during mop-up gets strike-finish mop-up copy.
static func _run_hold_line_hint_mop_up_rear_rank_strikes(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 14:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 7, "ranks": 2, "density": "normal"},
		{"files": 3, "ranks": 1, "density": "normal"}
	)
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if rear.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_rear_strikes: missing rear/enemy fixtures"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(rear, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
		{"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
	]
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
	if hint.is_empty() or not hint.contains("listed strike"):
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_mop_up_rear_strikes: want strike mop-up hint got '%s'" % hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Back rank reserve-only when not mop-up stays generic back-rank copy.
static func _run_hold_line_hint_back_rank_not_mopup(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 14:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 7, "ranks": 2, "density": "normal"},
		{"files": 3, "ranks": 1, "density": "normal"}
	)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 3)
	if rear.is_empty():
		CombatRegressionHarness._fail(failures, "hold_line_hint_back_rank: missing rear fixture")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
	]
	var hint: String = _PlayerTurnHints.hold_line_focus_only_hint(mgr, rear, actions)
	if hint.is_empty() or not hint.begins_with("Back rank"):
		CombatRegressionHarness._fail(
			failures, "hold_line_hint_back_rank: want back-rank copy got '%s'" % hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: rank-0 gap → rear **`swap_rank`** beats listed strikes; stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_swap_rank_over_strike(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want relief swap blocked for plug test")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	var front_id: int = _EntityAccess.id_int(front)
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, rear_id)
	if not _ListedActions.actions_include_move_vs_target(
		acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK
	):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: want swap_rank listed vs front partner")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not _ListedActions.action_list_has_hostile_strike(acts, rear_id):
		var enemy_id: int = -1
		for c in mgr.combatants:
			if _EntityAccess.is_living_on_side(c, "enemy"):
				enemy_id = _EntityAccess.id_int(c)
				break
		if enemy_id < 0:
			CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: missing enemy for strike fixture")
			CombatRegressionHarness._free_manager_restore_global_rng(mgr)
			return
		acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
	var picked: Dictionary = _MentalStack.try_pick(acts, rear_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_swap: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_swap: want formation_plug got %s"
			% str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_swap: want swap_rank got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: incapacitated front partner → rear **`swap_rank`** stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_incap_forward(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	if front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: missing front/rear fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front.state = CombatConstants.STATE_COWERING
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
	rear["gauge"] = 100.0
	var rear_id: int = _EntityAccess.id_int(rear)
	var acts: Array = _ActionsBuilder.build(mgr, rear_id)
	if not _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: want swap_rank listed over incap front")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _MentalStack.try_pick(acts, rear_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_incap: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_incap: want formation_plug got %s"
			% str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_incap: want swap_rank got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: Skirmish rank-0 hole → front **`rotate_file`** when formation-only menu; stamps **`formation_plug`**.
static func _run_mental_stack_formation_plug_rotate_skirmish_hole(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: expected skirmish mode")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rot_tgt: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: missing hole/rotate fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_rank0_hole(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: want rank-0 hole after kill")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var rot_src_id: int = _EntityAccess.id_int(rot_src)
	var rot_tgt_id: int = _EntityAccess.id_int(rot_tgt)
	rot_src["gauge"] = 100.0
	if not _FormationMoves.rotate_file_action_legal(mgr, rot_src, rot_tgt):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: want legal rotate_file vs adjacent file")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	# Rotate plug path matches utility weight: formation-only menu (no listed strikes).
	var acts: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rot_src_id},
		{"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": rot_tgt_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(acts, rot_src_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_rotate: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_rotate: want formation_plug got %s"
			% str(rot_src.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_ROTATE_FILE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_rotate: want rotate_file got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: fight-finish tail with listed offense must not stamp **`formation_plug`**.
static func _run_mental_stack_formation_plug_skipped_fight_finish(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want envelop_mop_up_active")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	if center.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: missing center fixture")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	center["gauge"] = 100.0
	var center_id: int = _EntityAccess.id_int(center)
	var acts: Array = _ActionsBuilder.build(mgr, center_id)
	if not _CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want fight_finish_tail")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not _ListedActions.action_list_has_hostile_strike(acts, center_id):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: want listed offense")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _MentalStack.try_pick(acts, center_id, mgr)
	if str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == (
		CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
	):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_skip_ff: formation_plug must not fire on fight-finish tail"
		)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_ff: expected stack pick on fight-finish")
	if str(picked.get("move_id", "")) in [
		CombatConstants.MOVE_ID_WAIT,
		CombatConstants.MOVE_ID_ROTATE_FILE,
		CombatConstants.MOVE_ID_SWAP_RANK,
	] or CombatConstants.is_focus_line_move(str(picked.get("move_id", ""))):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_skip_ff: want offense pick got %s layer=%s"
			% [
				str(picked.get("move_id", "")),
				str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: envelop mop-up + listed strikes defers plug (rear rank with hole still finishes).
static func _run_mental_stack_formation_plug_skipped_mop_up_offense(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 10:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(4, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want envelop_mop_up_active")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want relief swap blocked")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	rear["gauge"] = 100.0
	var rear_id: int = _EntityAccess.id_int(rear)
	var acts: Array = _ActionsBuilder.build(mgr, rear_id)
	if not _ListedActions.action_list_has_hostile_strike(acts, rear_id):
		var enemy_id: int = -1
		for c in mgr.combatants:
			if _EntityAccess.is_living_on_side(c, "enemy"):
				enemy_id = _EntityAccess.id_int(c)
				break
		if enemy_id < 0:
			CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_mop: missing living enemy")
			CombatRegressionHarness._free_manager_restore_global_rng(mgr)
			return
		acts.append({"move_id": "thrust", "target_id": enemy_id, "target_part": "head"})
	var front_id: int = _EntityAccess.id_int(front)
	if not _ListedActions.actions_include_move_vs_target(
		acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK
	):
		if not _FormationMoves.swap_rank_action_legal(mgr, rear, front):
			CombatRegressionHarness._fail(
				failures, "mental_stack_plug_skip_mop: want legal swap_rank for plug-defer fixture"
			)
			CombatRegressionHarness._free_manager_restore_global_rng(mgr)
			return
		acts.append({"move_id": CombatConstants.MOVE_ID_SWAP_RANK, "target_id": front_id})
	if not _VacancyPlugs.formation_plug_layer_blocked(mgr, rear, acts, rear_id):
		CombatRegressionHarness._fail(
			failures, "mental_stack_plug_skip_mop: want formation_plug_layer_blocked during mop-up offense"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _AIPicker.pick(acts, rear_id, mgr)
	if str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == (
		CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
	):
		CombatRegressionHarness._fail(
			failures, "mental_stack_plug_skip_mop: formation_plug must defer during mop-up offense"
		)
	if picked.is_empty() or str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_SWAP_RANK:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_skip_mop: want non-plug offense got %s layer=%s"
			% [
				str(picked.get("move_id", "")),
				str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: intact line + strikes only → stack miss (no **`formation_plug`** stamp).
static func _run_mental_stack_formation_plug_no_gap_stack_miss(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var player_id: int = _EntityAccess.id_int(player)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[1])
	player["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, player_id)
	if not _ListedActions.action_list_has_hostile_strike(acts, player_id):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want listed strikes")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want no swap_rank on intact duel")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if _VacancyPlugs.formation_plug_layer_eligible(mgr, player, player_id, acts):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want plug layer ineligible")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var stacked: Dictionary = _MentalStack.try_pick(acts, player_id, mgr)
	if not stacked.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_no_gap: want stack miss got %s layer=%s"
			% [
				str(stacked.get("move_id", "")),
				str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")),
			]
		)
	if not str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_no_gap: want cleared stack layer stamp")
	var picked: Dictionary = _AIPicker.pick(acts, player_id, mgr)
	if picked.is_empty() or str(picked.get("move_id", "")) in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_no_gap: want utility offense got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: sparse post-flee line + listed melee defers plug even when shuffle moves exist.
static func _run_mental_stack_formation_plug_skipped_sparse_line_offense(failures: PackedStringArray) -> void:
	var fix: Dictionary = CombatRegressionHarness._harness_sparse_post_flee_6v3_mgr()
	if fix.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: fixture setup failed")
		return
	var mgr: Node = fix["mgr"]
	var survivor: Dictionary = fix["survivor"]
	var survivor_id: int = int(fix["survivor_id"])
	survivor["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, survivor_id)
	if not _ListedActions.action_list_has_hostile_melee_strike(acts, survivor_id):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: want listed melee")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(mgr, survivor, acts, survivor_id):
		CombatRegressionHarness._fail(
			failures, "mental_stack_plug_skip_sparse: want sparse_line_prefer_finish_over_shuffle"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not _VacancyPlugs.formation_plug_layer_blocked(mgr, survivor, acts, survivor_id):
		CombatRegressionHarness._fail(
			failures, "mental_stack_plug_skip_sparse: want formation_plug_layer_blocked"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _AIPicker.pick(acts, survivor_id, mgr)
	if str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == (
		CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
	):
		CombatRegressionHarness._fail(
			failures, "mental_stack_plug_skip_sparse: formation_plug must defer on sparse finish line"
		)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_skip_sparse: expected pick")
	if str(picked.get("move_id", "")) in [
		CombatConstants.MOVE_ID_WAIT,
		CombatConstants.MOVE_ID_ROTATE_FILE,
		CombatConstants.MOVE_ID_SWAP_RANK,
	] or CombatConstants.is_focus_line_move(str(picked.get("move_id", ""))):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_skip_sparse: want offense pick got %s"
			% str(picked.get("move_id", ""))
		)
	if CombatConstants.is_feature_mental_stack_ai_enabled():
		var layer: String = str(
			survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")
		)
		if layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
			CombatRegressionHarness._fail(
				failures,
				"mental_stack_plug_skip_sparse: want sparse_fight layer got %s"
				% layer
			)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## L4b: sparse post-flee rank-0 **`try_pick`** stamps **`sparse_fight`** and chooses offense.
static func _run_mental_stack_sparse_fight_stamps_layer_on_try_pick(
	failures: PackedStringArray
) -> void:
	if not CombatConstants.is_feature_mental_stack_ai_enabled():
		return
	var fix: Dictionary = CombatRegressionHarness._harness_sparse_post_flee_6v3_mgr()
	if fix.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: fixture setup failed")
		return
	var mgr: Node = fix["mgr"]
	var survivor: Dictionary = fix["survivor"]
	var survivor_id: int = int(fix["survivor_id"])
	if not _FormationFlow.skirmish_line_sparse_after_casualties(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: want sparse line")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	survivor["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, survivor_id)
	if not _ListedActions.action_list_has_hostile_strike(acts, survivor_id):
		CombatRegressionHarness._fail(
			failures, "mental_stack_sparse_fight: want hostile strike listed for survivor"
		)
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _MentalStack.try_pick(acts, survivor_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_sparse_fight: expected try_pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var layer: String = str(survivor.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
	var mid: String = str(picked.get("move_id", ""))
	if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
		CombatRegressionHarness._fail(
			failures, "mental_stack_sparse_fight: want offense pick got %s layer=%s" % [mid, layer]
		)
	var reserve_only: bool = _ListedActions.action_list_is_reserve_posture_only(acts)
	if reserve_only:
		if layer not in [
			CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
			CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT,
		]:
			CombatRegressionHarness._fail(
				failures,
				"mental_stack_sparse_fight: reserve_only want hold_line or sparse_fight got %s"
				% layer
			)
	elif layer != CombatConstants.MENTAL_STACK_LAYER_SPARSE_FIGHT:
		CombatRegressionHarness._fail(
			failures, "mental_stack_sparse_fight: want sparse_fight layer got %s" % layer
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L5: full **`CombatAIActionPicker.pick`** path stamps **`formation_plug`** on rank-0 gap relief.
static func _run_mental_stack_formation_plug_picker_e2e(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_plug_picker: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "mental_stack_plug_picker: want relief swap blocked")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	rear["gauge"] = 100.0
	var rear_id: int = _EntityAccess.id_int(rear)
	var acts: Array = _ActionsBuilder.build(mgr, rear_id)
	var picked: Dictionary = _AIPicker.pick(acts, rear_id, mgr)
	if str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_picker: want formation_plug got %s"
			% str(rear.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_SWAP_RANK:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_plug_picker: want swap_rank got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: low cohesion + wounded front on losing side → **`flee`** beats listed strike; stamps **`rout`**.
static func _run_mental_stack_rout_stressed_flee_beats_strike(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	ent.blood_volume = 82.0
	form["line_cohesion"] = 0.38
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_stress: want abandonment warranted")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var fighter_id: int = _EntityAccess.id_int(front_c)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[2])
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
		{"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, fighter_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_rout_stress: expected rout layer pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != (
		CombatConstants.MENTAL_STACK_LAYER_ROUT
	):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_rout_stress: want rout got %s"
			% str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_rout_stress: want flee got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: heavy side casualties → **`flee`** beats **`wait`**; stamps **`rout`**.
static func _run_mental_stack_rout_casualty_flee_beats_wait(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.9
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	var rear_id: int = _EntityAccess.id_int(mgr.combatants[1])
	CombatRegressionHarness._soak_kill_combatant(mgr, rear_id)
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = 82.0
	if not _FormationRout.rout_cognition_pressure(mgr, front_c):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_casualty: want rout pressure")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var fighter_id: int = _EntityAccess.id_int(front_c)
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, fighter_id, mgr)
	if str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != (
		CombatConstants.MENTAL_STACK_LAYER_ROUT
	):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_rout_casualty: want rout got %s"
			% str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_rout_casualty: want flee got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: fight-finish tail must not stamp **`rout`** when listed offense should finish.
static func _run_mental_stack_rout_skipped_fight_finish(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: want envelop_mop_up_active")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	if center.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: missing center fixture")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	center["gauge"] = 100.0
	var center_id: int = _EntityAccess.id_int(center)
	var acts: Array = _ActionsBuilder.build(mgr, center_id)
	if not _CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: want fight_finish_tail")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	acts.append({"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": center_id})
	var picked: Dictionary = _MentalStack.try_pick(acts, center_id, mgr)
	if str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == (
		CombatConstants.MENTAL_STACK_LAYER_ROUT
	):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: rout must not fire on fight-finish tail")
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: expected stack pick on fight-finish")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: winning side on firm line — no **`rout`** stamp when only wait + strike listed.
static func _run_mental_stack_rout_firm_line_no_stamp(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	ent.blood_volume = 82.0
	form["line_cohesion"] = 0.88
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if _FormationRout.rout_cognition_pressure(mgr, front_c):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_firm: winning firm line must not have rout pressure")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var fighter_id: int = _EntityAccess.id_int(front_c)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[2])
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
	]
	_MentalStack.try_pick(actions, fighter_id, mgr)
	if str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) == (
		CombatConstants.MENTAL_STACK_LAYER_ROUT
	):
		CombatRegressionHarness._fail(failures, "mental_stack_rout_firm: rout must not stamp on firm winning line")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L7: high fight exhaustion → wait / disengage layer before utility pick.
static func _run_mental_stack_exhaustion_tunnel_prefers_disengage(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var fighter: Dictionary = mgr.combatants[0]
	var fighter_id: int = _EntityAccess.id_int(fighter)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[1])
	fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.62
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, fighter_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_exhaustion: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_exhaustion: want exhaustion layer got %s"
			% str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
		CombatRegressionHarness._fail(
			failures, "mental_stack_exhaustion: want wait got %s" % str(picked.get("move_id", ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L7: when flee is listed, exhaustion tunnel must not pick rotate_file over abandon-field.
static func _run_mental_stack_exhaustion_tunnel_flee_beats_rotate_file(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 2, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var fighter: Dictionary = mgr.combatants[0]
	var fighter_id: int = _EntityAccess.id_int(fighter)
	fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD + 0.05
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, fighter_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_flee_rotate: expected exhaustion layer pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_ROTATE_FILE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_flee_rotate: rotate_file must not win when flee is listed in exhaustion tunnel"
		)
	if str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_flee_rotate: want exhaustion layer got %s"
			% str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Critical stamina (below MS-L7 index): L5 must not pick rotate_file when flee is listed.
static func _run_mental_stack_critical_stamina_flee_beats_rotate_file(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 2, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var fighter: Dictionary = mgr.combatants[0]
	var fighter_id: int = _EntityAccess.id_int(fighter)
	fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD - 0.15
	fighter["stamina"] = 0.05 * float(fighter.get("stamina_max", 100.0))
	var actions: Array = [
		{"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
		{"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, fighter_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_crit_flee: expected L5 pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_ROTATE_FILE:
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_crit_flee: rotate_file must not win when flee is listed at critical stamina"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## p4a: MS-L7 tunnel threshold aligns with offense-damp floor + 50% FP exhaustion band.
static func _run_p4a_ms_l7_exhaustion_threshold_parity(failures: PackedStringArray) -> void:
	var damp_start: float = CombatConstants.EXHAUSTION_OFFENSE_DAMP_START
	var tunnel: float = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
	var floor_m: float = CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR
	if absf(tunnel - 0.5) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"p4a_ms_l7: tunnel threshold should align with 50%% FP band got %.2f" % tunnel
		)
	var c: Dictionary = {}
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = damp_start - 0.02
	if absf(_Exhaustion.exhaustion_offense_weight_mult(c) - 1.0) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"p4a_ms_l7: below damp start want mult=1.0 got %.3f" % _Exhaustion.exhaustion_offense_weight_mult(c)
		)
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = tunnel - 0.01
	if _Exhaustion.exhaustion_tunnel_active(c):
		CombatRegressionHarness._fail(failures, "p4a_ms_l7: tunnel must not fire below threshold")
	var mid_m: float = _Exhaustion.exhaustion_offense_weight_mult(c)
	if mid_m <= floor_m + 0.001 or mid_m >= 1.0 - 0.001:
		CombatRegressionHarness._fail(
			failures, "p4a_ms_l7: mid ramp want partial damp got %.3f" % mid_m
		)
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = tunnel
	if not _Exhaustion.exhaustion_tunnel_active(c):
		CombatRegressionHarness._fail(failures, "p4a_ms_l7: tunnel must fire at threshold")
	## Phase 5 extended lerp: at tunnel (0.50) weight is ~0.675 (midpoint), not floor.
	## Floor only applies at exhausted threshold (0.75+).
	var at_tunnel_m: float = _Exhaustion.exhaustion_offense_weight_mult(c)
	if at_tunnel_m < 0.55 or at_tunnel_m > 0.80:
		CombatRegressionHarness._fail(
			failures,
			"p4a_ms_l7: at tunnel want mid ramp %.3f got %.3f (extended lerp to 0.75)"
			% [0.675, at_tunnel_m]
		)


## Tier 4.3.7: focus-line moves listed when combat attention is on.
static func _run_focus_line_actions_listed_when_attention_enabled(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["state"] = CombatConstants.STATE_WAITING
	player["gauge"] = 100.0
	var actions: Array = _ActionsBuilder.build(mgr, pid)
	var found: int = 0
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if CombatConstants.is_focus_line_move(str(a.get("move_id", ""))):
			found += 1
	if found != CombatConstants.FOCUS_LINE_MOVE_IDS.size():
		CombatRegressionHarness._fail(failures, "focus_line_list: want %d focus moves got %d" % [CombatConstants.FOCUS_LINE_MOVE_IDS.size(), found])
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Hold-line menus must include **`wait`** (focus-only lists used to omit it → focus spam).
static func _run_append_combat_wait_lists_wait_for_focus_only_menu(failures: PackedStringArray) -> void:
	var cid: int = 3
	var actions: Array = []
	for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
		actions.append({"target_id": cid, "move_id": move_id})
	if not _ListedActions.action_list_is_hold_line_only(actions):
		CombatRegressionHarness._fail(failures, "append_combat_wait: setup want hold_line_only menu")
	_FormationMoves.append_combat_wait_if_needed(actions, cid)
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
		CombatRegressionHarness._fail(failures, "append_combat_wait: want wait on focus-only menu")


## Close + focus without melee must also list **`wait`** (post-flee reserve spam path).
static func _run_append_combat_wait_lists_wait_for_close_and_focus_menu(failures: PackedStringArray) -> void:
	var cid: int = 4
	var actions: Array = [
		{"target_id": 7, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE},
		{"target_id": 8, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE},
	]
	for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
		actions.append({"target_id": cid, "move_id": move_id})
	if not _ListedActions.action_list_is_reserve_posture_only(actions):
		CombatRegressionHarness._fail(failures, "append_combat_wait: setup want reserve_posture_only menu")
	_FormationMoves.append_combat_wait_if_needed(actions, cid)
	if not _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
		CombatRegressionHarness._fail(failures, "append_combat_wait: want wait on close+focus menu")


## No-op focus (guard already on that line) → **`skip_turn`** / wait, not another focus_line resolve.
static func _run_focus_line_noop_skips_without_guard_change(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var back: Dictionary = mgr.combatants[0]
	var bid: int = _EntityAccess.id_int(back)
	back["rank"] = 1
	back["state"] = CombatConstants.STATE_WAITING
	back["gauge"] = 100.0
	back["guard_line"] = "high"
	back[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "head"
	var resolved: Array = []
	mgr.connect("action_resolved", func(_a, _t, result): resolved.append(result))
	mgr.resolve_action(bid, bid, CombatConstants.MOVE_ID_FOCUS_HIGH, {})
	if resolved.is_empty():
		CombatRegressionHarness._fail(failures, "focus_noop: expected action_resolved")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var outcome: String = str((resolved[0] as Dictionary).get("outcome", ""))
	if outcome != "wait":
		CombatRegressionHarness._fail(failures, "focus_noop: want wait outcome got %s" % outcome)
	if str(back.get("guard_line", "")) != "high":
		CombatRegressionHarness._fail(failures, "focus_noop: guard_line should be unchanged")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.7: **`resolve_action`** on **`focus_high`** sets guard + focus.
static func _run_focus_line_resolve_sets_guard_and_focus(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["state"] = CombatConstants.STATE_WAITING
	player["gauge"] = 100.0
	player["guard_line"] = "low"
	player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
	mgr.resolve_action(pid, pid, CombatConstants.MOVE_ID_FOCUS_HIGH, {})
	if str(player.get("guard_line", "")) != "high":
		CombatRegressionHarness._fail(failures, "focus_line_resolve: want guard_line high got %s" % str(player.get("guard_line")))
	if _Attention.get_focus_part(player) != "head":
		CombatRegressionHarness._fail(
			failures,
			"focus_line_resolve: want focus head got %s" % _Attention.get_focus_part(player)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.7: party lead weights telegraph-matching focus line above other focus lines.
static func _run_focus_line_party_leader_prefers_telegraph_match(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["is_party_leader"] = true
	player["guard_line"] = "low"
	player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
	player[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	var w_match: float = _AIPicker._get_action_weight(
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
	)
	var w_other: float = _AIPicker._get_action_weight(
		{"move_id": CombatConstants.MOVE_ID_FOCUS_LOW, "target_id": pid}, pid, mgr, true
	)
	if w_match <= w_other:
		CombatRegressionHarness._fail(
			failures,
			"focus_line_leader: telegraph match weight %.4f should exceed other line %.4f"
			% [w_match, w_other]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.8: yomi **`parry_deflect`** raises defender reported readiness vs that attacker.
static func _run_yomi_parry_deflect_boosts_feint_listing_mult(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 13
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m0: float = _Attention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m1: float = _Attention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
	if m1 <= m0 or m0 <= 1.0:
		CombatRegressionHarness._fail(
			failures,
			"yomi_parry_deflect_feint: mult should rise got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.3: **`parry_deflect`** increments yomi; **`hit`** clears attacker entry.
static func _run_yomi_defense_readiness_mult_boosts_after_parry_deflect(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {}
	var atk_id: int = 14
	var m0: float = _Attention.yomi_defense_readiness_mult(def, atk_id)
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m1: float = _Attention.yomi_defense_readiness_mult(def, atk_id)
	if m1 <= m0 or m0 != 1.0:
		CombatRegressionHarness._fail(
			failures,
			"yomi_defense_readiness: want rise from 1.0 got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.4: wind-up stamps per-line **`position_angle_offset_deg`** on attacker.
static func _run_attention_ui_hint_includes_mental_stack_layer(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	for layer in [
		"incoming",
		CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
		CombatConstants.MENTAL_STACK_LAYER_ROUT,
		CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
	]:
		var def: Dictionary = {
			CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER: layer,
			CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
			CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
		}
		var hint: String = _Attention.format_attention_ui_hint(def)
		if not hint.contains("Stack %s" % layer):
			CombatRegressionHarness._fail(
				failures,
				"attention_ui_stack: want Stack %s in '%s'" % [layer, hint]
			)
	CombatConstants.set_feature_combat_attention_load(false)


## Tier 4.3.7: yomi **`parry_deflect`** count boosts feint listing mult.
static func _run_footwork_attack_step_offset_stamped_on_windup(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(off - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
		CombatRegressionHarness._fail(failures, "footwork_windup: want left-line offset got %.2f" % off)


## Tier 4.4: **`attack_eval_step_deg_for_attacker`** does not stamp offset before wind-up commit.
static func _run_footwork_attack_eval_no_stamp_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	var eval: float = _Footwork.attack_eval_step_deg_for_attacker(atk, "left")
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(
			failures, "footwork_attack_eval: attack_eval must not stamp offset on combatant"
		)
	if absf(eval - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
		CombatRegressionHarness._fail(
			failures, "footwork_attack_eval: want left-line eval got %.2f" % eval
		)


## Tier 4.4: idle listing preview uses **`attack_eval_step_deg_for_attacker`**, not stale stamp.
static func _run_footwork_picker_preview_uses_attack_eval_when_idle(
	failures: PackedStringArray
) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	var base: float = CombatConstants.line_to_angle("left")
	var atk: Dictionary = {
		"state": CombatConstants.STATE_WAITING,
		"distance_to": {2: CombatConstants.DISTANCE_CLOSE},
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: 99.0,
	}
	var preview: float = _Footwork.attack_angle_deg_for_listing_preview(
		atk, "left", base, 2
	)
	var eval_step: float = _Footwork.attack_eval_step_deg_for_attacker(atk, "left", 2)
	var want: float = fmod(base + eval_step + 360.0, 360.0)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	if absf(preview - want) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"footwork_picker_preview: idle want %.2f got %.2f (eval step %.2f)"
			% [want, preview, eval_step]
		)
	if absf(preview - _Footwork.apply_offset_to_angle_deg(base, atk)) < 0.02:
		CombatRegressionHarness._fail(
			failures, "footwork_picker_preview: must not reuse stale idle stamp"
		)


## Tier 4.4: wind-up listing preview uses live stamp, not eval preview.
static func _run_footwork_picker_preview_wind_up_uses_live_stamp(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var base: float = CombatConstants.line_to_angle("left")
	var stamp: float = 7.0
	var atk: Dictionary = {
		"state": CombatConstants.STATE_WIND_UP,
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: stamp,
	}
	var preview: float = _Footwork.attack_angle_deg_for_listing_preview(
		atk, "left", base, 2
	)
	var want: float = fmod(base + stamp + 360.0, 360.0)
	if absf(preview - want) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_picker_preview_wind_up: want %.2f got %.2f"
			% [want, preview]
		)


## Tier 4.4 spatial slice 3: idle listing preview includes flurry bind mult.
static func _run_footwork_picker_preview_flurry_bind_when_idle(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var base_line: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base_line) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	atk["state"] = CombatConstants.STATE_WAITING
	var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(atk), def_id)
	var base_angle: float = CombatConstants.line_to_angle("left")
	var preview: float = _Footwork.attack_angle_deg_for_listing_preview(
		atk, "left", base_angle, def_id, mgr
	)
	var eval_step: float = _Footwork.attack_eval_step_deg_for_attacker(atk, "left", def_id, mgr)
	var want: float = fmod(base_angle + eval_step + 360.0, 360.0)
	var want_step: float = base_line * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)
	if absf(eval_step - want_step) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"footwork_picker_preview_flurry: eval step want %.2f got %.2f"
			% [want_step, eval_step]
		)
	if absf(preview - want) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"footwork_picker_preview_flurry: preview want %.2f got %.2f"
			% [want, preview]
		)


## Tier 4.4: offset rotates reported attack angle for parry alignment.
static func _run_footwork_offset_shifts_attack_angle_deg(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("left")
		),
	}
	var base_deg: float = CombatConstants.line_to_angle("left")
	var shifted: float = _Footwork.apply_offset_to_angle_deg(base_deg, atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(
		base_deg + CombatConstants.position_angle_offset_deg_for_attack_line("left") + 360.0,
		360.0
	)
	if absf(shifted - want) > 0.05:
		CombatRegressionHarness._fail(failures, "footwork_angle: want %.2f got %.2f" % [want, shifted])


## Tier 4.4: **`CombatManager.start()`** scrubs position offset.
static func _run_footwork_offset_scrubbed_on_combat_start(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 12.0
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_scrub: offset should clear on start")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.4.2: committed parry stamps scaled defender offset from guard line.
## Tier 4.4 octant: diagonal form homes get non-zero parry PA when eight-guard lookup is wired — LIVE_PATHS **`#wf-form-guard-pa-matrix`**.
static func _assert_form_home_parry_step_via_octant(
	failures: PackedStringArray, form_id: String, expect_home: String
) -> void:
	var home: String = _WeaponForm.home_guard_line(form_id)
	if home != expect_home:
		CombatRegressionHarness._fail(
			failures,
			"footwork_eight_line: %s home want %s got %s" % [form_id, expect_home, home]
		)
		return
	var def: Dictionary = {"guard_line": home}
	_Footwork.apply_defender_step_on_parry(def, home)
	var raw: float = CombatConstants.position_angle_offset_deg_for_attack_line(home)
	var anchor: float = _GuardLines.position_angle_offset_deg_for_line(home)
	if absf(raw - anchor) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_eight_line: %s raw delegate want %.2f got %.2f" % [form_id, anchor, raw]
		)
		return
	if absf(raw) < 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_eight_line: %s raw offset want non-zero got %.2f" % [form_id, raw]
		)
		return
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		home, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(off - want) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_eight_line: %s parry want %.2f got %.2f (raw=%.2f)" % [form_id, want, off, raw]
		)


static func _run_footwork_eight_line_home_guard_parry_step(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_assert_form_home_parry_step_via_octant(failures, _WeaponForm.FORM_OX, _GuardLines.LINE_HIGH_RIGHT)
	_assert_form_home_parry_step_via_octant(failures, _WeaponForm.FORM_WRATH, _GuardLines.LINE_HIGH_LEFT)
	_assert_form_home_parry_step_via_octant(failures, _WeaponForm.FORM_FOOL, _GuardLines.LINE_LOW_LEFT)


## Tier 4.4 octant: wind-up PA from diagonal **`attack_line`** — not form home.
static func _assert_octant_windup_stamps_line(failures: PackedStringArray, line: String) -> void:
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, line)
	var want: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
	var anchor: float = _GuardLines.position_angle_offset_deg_for_line(line)
	var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(want - anchor) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_octant_windup: %s delegate want %.2f got %.2f" % [line, anchor, want]
		)
		return
	if absf(off - want) > 0.01:
		CombatRegressionHarness._fail(
			failures, "footwork_octant_windup: %s stamp want %.2f got %.2f" % [line, want, off]
		)


## WF-T1: all four diagonals stamp wind-up PA via **`CombatConstants`** → **`CombatGuardLines`** lookup.
static func _run_footwork_octant_windup_step_diagonals(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	for line in [
		_GuardLines.LINE_HIGH_RIGHT,
		_GuardLines.LINE_LOW_RIGHT,
		_GuardLines.LINE_LOW_LEFT,
		_GuardLines.LINE_HIGH_LEFT,
	]:
		_assert_octant_windup_stamps_line(failures, line)


## WF-T1: eight-guard flag on — **`CombatConstants.position_angle_offset_deg_for_attack_line`** delegates to **`CombatGuardLines`** for every line.
static func _run_footwork_octant_lookup_delegates_to_guard_lines(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	for line in _GuardLines.ALL_LINES:
		var anchor: float = _GuardLines.position_angle_offset_deg_for_line(line)
		var got: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
		if absf(got - anchor) > 0.01:
			CombatRegressionHarness._fail(
				failures,
				"footwork_octant_lookup: %s want %.2f got %.2f" % [line, anchor, got]
			)
	for line in [
		_GuardLines.LINE_HIGH_RIGHT,
		_GuardLines.LINE_LOW_RIGHT,
		_GuardLines.LINE_LOW_LEFT,
		_GuardLines.LINE_HIGH_LEFT,
	]:
		var cardinal: String = _GuardLines.cardinal_for_path_lookup(line)
		var diag_raw: float = _GuardLines.position_angle_offset_deg_for_line(line)
		var card_raw: float = _GuardLines.position_angle_offset_deg_for_line(cardinal)
		if absf(diag_raw - card_raw) < 0.01:
			CombatRegressionHarness._fail(
				failures,
				"footwork_octant_lookup: %s raw %.2f should differ from cardinal %s %.2f"
				% [line, diag_raw, cardinal, card_raw]
			)


## WF-T1: dodge body-part → octant line — scaled dodge step uses octant raw, not mapped cardinal.
static func _assert_defender_dodge_octant_via_leg(
	failures: PackedStringArray, part: String, expect_line: String, cardinal_line: String
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {}
	_Footwork.apply_defender_step_on_dodge(def, part)
	var line: String = CombatConstants.guard_line_for_body_part(part)
	if line != expect_line:
		CombatRegressionHarness._fail(
			failures,
			"footwork_def_dodge_octant: %s line want %s got %s" % [part, expect_line, line]
		)
		return
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	var cardinal_dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		cardinal_line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(off - want) > 0.01:
		CombatRegressionHarness._fail(
			failures, "footwork_def_dodge_octant: %s want %.2f got %.2f" % [part, want, off]
		)
	if absf(off - cardinal_dodge) < 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_def_dodge_octant: %s octant %.2f should differ from cardinal %s %.2f"
			% [part, off, cardinal_line, cardinal_dodge]
		)


static func _run_footwork_defender_dodge_step_stamps_octant_low_left(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	_assert_defender_dodge_octant_via_leg(
		failures, "left_leg", _GuardLines.LINE_LOW_LEFT, _GuardLines.LINE_LOW
	)


static func _run_footwork_defender_dodge_step_stamps_octant_right_leg(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	_assert_defender_dodge_octant_via_leg(
		failures, "right_leg", _GuardLines.LINE_LOW_RIGHT, _GuardLines.LINE_LOW
	)


## WF-T1: **`parry_eval_step_deg_for_defender`** uses octant guard line without stamping offset.
static func _run_footwork_parry_eval_step_octant_home(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var line: String = _GuardLines.LINE_LOW_LEFT
	var def: Dictionary = {"guard_line": line}
	var eval: float = _Footwork.parry_eval_step_deg_for_defender(def)
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(
			failures, "footwork_parry_eval_octant: parry_eval must not stamp offset on combatant"
		)
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	if absf(eval - want) < 0.01:
		return
	CombatRegressionHarness._fail(
		failures, "footwork_parry_eval_octant: low_left want %.2f got %.2f" % [want, eval]
	)


## WF-T1: **`dodge_eval_step_deg_for_defender`** uses body-part line without stamping offset.
static func _run_footwork_dodge_eval_step_octant_arm(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {"guard_line": "high"}
	var eval: float = _Footwork.dodge_eval_step_deg_for_defender(def, "left_arm")
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(
			failures, "footwork_dodge_eval_octant: dodge_eval must not stamp offset on combatant"
		)
	var line: String = CombatConstants.guard_line_for_body_part("left_arm")
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(eval - want) > 0.01:
		CombatRegressionHarness._fail(
			failures, "footwork_dodge_eval_octant: left_arm want %.2f got %.2f" % [want, eval]
		)


## WF-T1: Camp-5 soak confirms defender step scales (constants-only — no runtime retune hook).
static func _run_footwork_defender_scales_wf_t1_locked(failures: PackedStringArray) -> void:
	if absf(CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY - 0.55) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"footwork_def_scale_wf_t1: parry want 0.55 got %.4f"
			% CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
		)
	if absf(CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE - 0.85) > 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"footwork_def_scale_wf_t1: dodge want 0.85 got %.4f"
			% CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
		)


## WF-T1: defender parry scale (0.55) < dodge scale (0.85) on the same octant line.
static func _run_footwork_defender_parry_step_lt_dodge_on_octant(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	var line: String = _GuardLines.LINE_HIGH_LEFT
	var parry: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	var dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(parry) >= absf(dodge):
		CombatRegressionHarness._fail(
			failures,
			"footwork_def_scale: high_left parry %.2f should be smaller than dodge %.2f" % [parry, dodge]
		)


## WF-T1: **`guard_angle_deg`** includes octant parry step on diagonal home guard.
static func _run_footwork_guard_angle_deg_octant_parry_step(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var line: String = _GuardLines.LINE_HIGH_LEFT
	var def: Dictionary = {"guard_line": line}
	_Footwork.apply_defender_step_on_parry(def, line)
	var base_deg: float = CombatConstants.get_guard_angle_deg(def, {})
	var shifted: float = _Footwork.guard_angle_deg(def, {})
	var step: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	var want: float = fmod(base_deg + step + 360.0, 360.0)
	if absf(shifted - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_guard_angle_octant: want %.2f got %.2f (base=%.2f step=%.2f)"
			% [want, shifted, base_deg, step]
		)


## Tier 4.4 spatial slice 1: engagement band scales PA step magnitude (CLOSE > LONG).
static func _run_t44_spatial_band_pa_attacker_close_gt_long(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		return
	var atk_close: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
	_Footwork.apply_attack_step_on_windup(atk_close, "left", 2)
	var close_off: float = float(
		atk_close.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	var atk_long: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_LONG}}
	_Footwork.apply_attack_step_on_windup(atk_long, "left", 2)
	var long_off: float = float(
		atk_long.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	var want_close: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
	var want_long: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_LONG
	if absf(close_off - want_close) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_spatial_band_pa_attacker: close want %.2f got %.2f" % [want_close, close_off]
		)
	if absf(long_off - want_long) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_spatial_band_pa_attacker: long want %.2f got %.2f" % [want_long, long_off]
		)
	if absf(close_off) <= absf(long_off) + 0.001:
		CombatRegressionHarness._fail(
			failures, "t44_spatial_band_pa_attacker: |close| should exceed |long|"
		)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


static func _run_t44_spatial_band_pa_defender_close_gt_long(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		return
	var def_close: Dictionary = {
		"guard_line": "left",
		"distance_to": {1: CombatConstants.DISTANCE_CLOSE},
	}
	_Footwork.apply_defender_step_on_parry(def_close, "left", 1)
	var close_off: float = float(
		def_close.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	var def_long: Dictionary = {
		"guard_line": "left",
		"distance_to": {1: CombatConstants.DISTANCE_LONG},
	}
	_Footwork.apply_defender_step_on_parry(def_long, "left", 1)
	var long_off: float = float(
		def_long.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	var want_close: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
	var want_long: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_LONG
	if absf(close_off - want_close) > 0.01 or absf(long_off - want_long) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_spatial_band_pa_defender: close=%.2f long=%.2f want %.2f/%.2f"
			% [close_off, long_off, want_close, want_long]
		)
	if absf(close_off) <= absf(long_off) + 0.001:
		CombatRegressionHarness._fail(
			failures, "t44_spatial_band_pa_defender: |close| should exceed |long|"
		)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


static func _run_t44_spatial_band_pa_flag_off_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(false)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	var atk: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
	_Footwork.apply_attack_step_on_windup(atk, "left", 2)
	var off_close: float = float(
		atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	atk["distance_to"] = {2: CombatConstants.DISTANCE_LONG}
	_Footwork.apply_attack_step_on_windup(atk, "left", 2)
	var off_long: float = float(
		atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	if absf(off_close - base) > 0.01 or absf(off_long - base) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_spatial_band_pa_flag_off: want base %.2f close=%.2f long=%.2f"
			% [base, off_close, off_long]
		)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


## Tier 4.4 spatial slice 2: wing file dodge step > interior file (parry unchanged).
static func _run_t44_spatial_file_dodge_wing_gt_interior(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var wing: Dictionary = {}
	var center: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_living_on_side(c, "player"):
			continue
		var fi: int = _EntityAccess.file_int(c)
		if fi == 0:
			wing = c
		elif fi == 1:
			center = c
	if wing.is_empty() or center.is_empty():
		CombatRegressionHarness._fail(failures, "t44_file_dodge: missing wing/center fixtures")
		CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		CombatRegressionHarness._free_manager(mgr)
		return
	_Footwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
	var wing_off: float = float(
		wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	_Footwork.apply_defender_step_on_dodge(center, "left_arm", -1, mgr)
	var center_off: float = float(
		center.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	var want_wing: float = base * CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
	if absf(wing_off - want_wing) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_file_dodge: wing want %.2f got %.2f" % [want_wing, wing_off]
		)
	if absf(center_off - base) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_file_dodge: center want %.2f got %.2f" % [base, center_off]
		)
	if absf(wing_off) <= absf(center_off) + 0.001:
		CombatRegressionHarness._fail(failures, "t44_file_dodge: |wing| should exceed |center|")
	var right_wing: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_living_on_side(c, "player"):
			continue
		if _EntityAccess.file_int(c) == 2:
			right_wing = c
			break
	if right_wing.is_empty():
		CombatRegressionHarness._fail(failures, "t44_file_dodge: missing right-wing fixture")
	else:
		_Footwork.apply_defender_step_on_dodge(right_wing, "left_arm", -1, mgr)
		var rw_off: float = float(
			right_wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
		)
		if absf(rw_off - want_wing) > 0.01:
			CombatRegressionHarness._fail(
				failures,
				"t44_file_dodge: right wing want %.2f got %.2f" % [want_wing, rw_off]
			)
	_Footwork.apply_defender_step_on_parry(wing, "left", -1)
	var wing_parry: float = float(
		wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	_Footwork.apply_defender_step_on_parry(center, "left", -1)
	var center_parry: float = float(
		center.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
	)
	if absf(wing_parry - center_parry) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_file_dodge: parry must not differ wing=%.2f center=%.2f"
			% [wing_parry, center_parry]
		)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 2: **`dodge_eval_step_deg_for_defender`** matches dodge stamp on wing file.
static func _run_t44_spatial_file_dodge_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var wing: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
			wing = c
			break
	if wing.is_empty():
		CombatRegressionHarness._fail(failures, "t44_file_dodge_eval: missing wing fixture")
	else:
		var eval_deg: float = _Footwork.dodge_eval_step_deg_for_defender(
			wing, "left_arm", -1, mgr
		)
		_Footwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
		var stamp_deg: float = float(
			wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
		)
		if absf(eval_deg - stamp_deg) > 0.01:
			CombatRegressionHarness._fail(
				failures,
				"t44_file_dodge_eval: want parity eval=%.2f stamp=%.2f" % [eval_deg, stamp_deg]
			)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_file_dodge_flag_off_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(false)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var wing: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
			wing = c
			break
	_Footwork.apply_defender_step_on_dodge(wing, "left_arm", -1, mgr)
	var off: float = float(wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	CombatRegressionHarness._free_manager(mgr)
	if absf(off - base) > 0.01:
		CombatRegressionHarness._fail(
			failures, "t44_file_dodge_off: flag off want base %.2f got %.2f" % [base, off]
		)


static func _run_t44_spatial_file_dodge_suite(failures: PackedStringArray) -> void:
	var sync_line: String = CombatConstants.t44_spatial_file_dodge_doc_sync_line()
	if sync_line.is_empty() or "slice2=wing_file_dodge_step_bias" not in sync_line:
		CombatRegressionHarness._fail(failures, "t44_file_dodge: bad doc_sync_line %s" % sync_line)
	_run_t44_spatial_file_dodge_wing_gt_interior(failures)
	_run_t44_spatial_file_dodge_eval_parity(failures)
	_run_t44_spatial_file_dodge_flag_off_parity(failures)


## Tier 4.4 spatial slice 3: active bind flurry vs partner boosts PA wind-up step.
static func _run_t44_spatial_flurry_pa_bind_boost(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var atk_id: int = _EntityAccess.id_int(atk)
	mgr.combat_clock = 0.0
	_FlurryBind.open_window(mgr, atk_id, def_id)
	_Footwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
	var got: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want: float = base * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
	if absf(got - want) > 0.02:
		CombatRegressionHarness._fail(
			failures, "t44_flurry_pa: bind boost want %.2f got %.2f" % [want, got]
		)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry window open but flag off → base PA only.
static func _run_t44_spatial_flurry_pa_flag_off_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(false)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(atk), def_id)
	_Footwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
	var got: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)
	if absf(got - base) > 0.02:
		CombatRegressionHarness._fail(
			failures, "t44_flurry_pa_off: want base %.2f got %.2f" % [base, got]
		)


static func _run_t44_spatial_flurry_pa_parry_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[0])
	def["guard_line"] = "left"
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(def), atk_id)
	var eval_deg: float = _Footwork.parry_eval_step_deg_for_defender(def, atk_id, mgr)
	_Footwork.apply_defender_step_on_parry(def, "left", atk_id, mgr)
	var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(eval_deg - stamp_deg) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_flurry_pa: parry_eval want stamp parity eval=%.2f stamp=%.2f"
			% [eval_deg, stamp_deg]
		)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry bind — **`dodge_eval_step_deg_for_defender`** matches dodge stamp.
static func _run_t44_spatial_flurry_pa_dodge_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[0])
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(def), atk_id)
	var eval_deg: float = _Footwork.dodge_eval_step_deg_for_defender(
		def, "left_arm", atk_id, mgr
	)
	_Footwork.apply_defender_step_on_dodge(def, "left_arm", atk_id, mgr)
	var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(eval_deg - stamp_deg) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_flurry_pa: dodge_eval want stamp parity eval=%.2f stamp=%.2f"
			% [eval_deg, stamp_deg]
		)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial slice 3: flurry bind — **`attack_eval_step_deg_for_attacker`** matches wind-up stamp.
static func _run_t44_spatial_flurry_pa_attack_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(atk), def_id)
	var eval_deg: float = _Footwork.attack_eval_step_deg_for_attacker(atk, "left", def_id, mgr)
	_Footwork.apply_attack_step_on_windup(atk, "left", def_id, mgr)
	var stamp_deg: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want: float = base * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
	if absf(eval_deg - stamp_deg) > 0.01 or absf(stamp_deg - want) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"t44_flurry_pa: attack_eval want parity eval=%.2f stamp=%.2f want=%.2f"
			% [eval_deg, stamp_deg, want]
		)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_flurry_pa_suite(failures: PackedStringArray) -> void:
	var sync_line: String = CombatConstants.t44_spatial_flurry_pa_doc_sync_line()
	if sync_line.is_empty() or "slice3=flurry_bind_pa_boost" not in sync_line:
		CombatRegressionHarness._fail(failures, "t44_flurry_pa: bad doc_sync_line %s" % sync_line)
	_run_t44_spatial_flurry_pa_bind_boost(failures)
	_run_t44_spatial_flurry_pa_attack_eval_parity(failures)
	_run_t44_spatial_flurry_pa_parry_eval_parity(failures)
	_run_t44_spatial_flurry_pa_dodge_eval_parity(failures)
	_run_t44_spatial_flurry_pa_flag_off_parity(failures)


static func _run_t44_spatial_band_pa_parry_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	var def: Dictionary = {
		"guard_line": "left",
		"distance_to": {2: CombatConstants.DISTANCE_CLOSE},
	}
	var eval_deg: float = _Footwork.parry_eval_step_deg_for_defender(def, 2)
	_Footwork.apply_defender_step_on_parry(def, "left", 2)
	var stamp_deg: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	if absf(eval_deg - stamp_deg) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"t44_band_pa: parry_eval want stamp parity eval=%.2f stamp=%.2f"
			% [eval_deg, stamp_deg]
		)


static func _run_t44_spatial_stacked_band_file_dodge(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var wing: Dictionary = {}
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[3])
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
			wing = c
			break
	if wing.is_empty():
		CombatRegressionHarness._fail(failures, "t44_stacked: missing wing fixture")
	else:
		wing["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
		_Footwork.apply_defender_step_on_dodge(wing, "left_arm", atk_id, mgr)
		var got: float = float(
			wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
		)
		var want: float = (
			base
			* CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
			* CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
		)
		if absf(got - want) > 0.02:
			CombatRegressionHarness._fail(
				failures,
				"t44_stacked: want %.2f got %.2f (close+wing)" % [want, got]
			)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_band_pa_attacker_eval_parity(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		return
	var atk: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
	var eval_deg: float = _Footwork.attack_eval_step_deg_for_attacker(atk, "left", 2)
	_Footwork.apply_attack_step_on_windup(atk, "left", 2)
	var stamp_deg: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
	if absf(eval_deg - stamp_deg) > 0.01 or absf(stamp_deg - want) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"t44_band_pa: attacker_eval want parity eval=%.2f stamp=%.2f want=%.2f"
			% [eval_deg, stamp_deg, want]
		)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)


static func _run_t44_spatial_stacked_band_flurry_dodge(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[0])
	def["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
	_FlurryBind.open_window(mgr, _EntityAccess.id_int(def), atk_id)
	_Footwork.apply_defender_step_on_dodge(def, "left_arm", atk_id, mgr)
	var got: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want: float = (
		base
		* CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
		* CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
	)
	if absf(got - want) > 0.02:
		CombatRegressionHarness._fail(
			failures,
			"t44_stacked_flurry: want %.2f got %.2f (close+flurry dodge)" % [want, got]
		)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


## Tier 4.4 spatial: band + wing file + flurry stack on dodge stamp.
static func _run_t44_spatial_stacked_band_file_flurry_dodge(failures: PackedStringArray) -> void:
	var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
	var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
	var saved_file: bool = CombatConstants.is_feature_t44_spatial_file_dodge_bias_enabled()
	var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
	var saved_bind: bool = _t44_harness_ensure_flurry_bind()
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_t44_spatial_band_pa_load(true)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(true)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
	var base: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(base) < 0.01:
		CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
		CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
		CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
		CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
		_t44_harness_restore_flurry_bind(saved_bind)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var wing: Dictionary = {}
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[3])
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
			wing = c
			break
	if wing.is_empty():
		CombatRegressionHarness._fail(failures, "t44_stacked_all: missing wing fixture")
	else:
		wing["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
		_FlurryBind.open_window(mgr, _EntityAccess.id_int(wing), atk_id)
		_Footwork.apply_defender_step_on_dodge(wing, "left_arm", atk_id, mgr)
		var got: float = float(
			wing.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)
		)
		var want: float = (
			base
			* CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
			* CombatConstants.T44_SPATIAL_FILE_DODGE_WING_MULT
			* CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
		)
		if absf(got - want) > 0.03:
			CombatRegressionHarness._fail(
				failures,
				"t44_stacked_all: want %.2f got %.2f (close+wing+flurry)" % [want, got]
			)
	CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
	CombatConstants.set_feature_t44_spatial_file_dodge_bias_load(saved_file)
	CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
	CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
	_t44_harness_restore_flurry_bind(saved_bind)
	CombatRegressionHarness._free_manager(mgr)


static func _run_t44_spatial_band_pa_suite(failures: PackedStringArray) -> void:
	var sync_line: String = CombatConstants.t44_spatial_band_pa_doc_sync_line()
	if sync_line.is_empty():
		CombatRegressionHarness._fail(failures, "t44_spatial_band_pa: empty doc_sync_line")
	_run_t44_spatial_band_pa_attacker_close_gt_long(failures)
	_run_t44_spatial_band_pa_attacker_eval_parity(failures)
	_run_t44_spatial_band_pa_defender_close_gt_long(failures)
	_run_t44_spatial_band_pa_parry_eval_parity(failures)
	_run_t44_spatial_stacked_band_file_dodge(failures)
	_run_t44_spatial_stacked_band_flurry_dodge(failures)
	_run_t44_spatial_stacked_band_file_flurry_dodge(failures)
	_run_t44_spatial_band_pa_flag_off_parity(failures)


## WF-T1 suite: octant raw table + defender scales — single entry for Phase 0 maintain.
static func _run_footwork_wf_t1_octant_suite(failures: PackedStringArray) -> void:
	_run_footwork_defender_scales_wf_t1_locked(failures)
	_run_footwork_octant_lookup_delegates_to_guard_lines(failures)
	_run_footwork_eight_line_home_guard_parry_step(failures)
	_run_footwork_octant_windup_step_diagonals(failures)
	_run_footwork_defender_dodge_step_stamps_octant_low_left(failures)
	_run_footwork_defender_dodge_step_stamps_octant_right_leg(failures)
	_run_footwork_parry_eval_step_octant_home(failures)
	_run_footwork_dodge_eval_step_octant_arm(failures)
	_run_footwork_defender_parry_step_lt_dodge_on_octant(failures)
	_run_footwork_guard_angle_deg_octant_parry_step(failures)
	_run_footwork_attack_angle_includes_octant_windup(failures)


## WF-T1: attacker contact angle includes octant wind-up step (**`high_right`** / ox home).
static func _run_footwork_attack_angle_includes_octant_windup(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var line: String = _GuardLines.LINE_HIGH_RIGHT
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line(line)
		),
	}
	var base_deg: float = _GuardLines.line_to_angle(line)
	var shifted: float = _Footwork.apply_offset_to_angle_deg(base_deg, atk)
	var step: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
	var want: float = fmod(base_deg + step + 360.0, 360.0)
	if absf(shifted - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_attack_angle_octant: high_right want %.2f got %.2f (base=%.2f step=%.2f)"
			% [want, shifted, base_deg, step]
		)


static func _run_footwork_defender_parry_step_stamps_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {}
	_Footwork.apply_defender_step_on_parry(def, "left")
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	if absf(off - want) > 0.01:
		CombatRegressionHarness._fail(failures, "footwork_def_parry: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: defender offset rotates effective guard angle for alignment.
static func _run_footwork_defender_offset_shifts_guard_angle_deg(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {
		"guard_line": "left",
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_defender_offset_deg_for_line(
				"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
			)
		),
	}
	var base_deg: float = CombatConstants.get_guard_angle_deg(def, {})
	var shifted: float = _Footwork.guard_angle_deg(def, {})
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(
		base_deg
		+ CombatConstants.position_angle_defender_offset_deg_for_line(
			"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
		)
		+ 360.0,
		360.0
	)
	if absf(shifted - want) > 0.05:
		CombatRegressionHarness._fail(failures, "footwork_def_guard: want %.2f got %.2f" % [want, shifted])


## Tier 4.4.2: dodge stamps larger scaled offset from eval part line.
static func _run_footwork_defender_dodge_step_stamps_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {}
	_Footwork.apply_defender_step_on_dodge(def, "left_arm")
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(off - want) > 0.01:
		CombatRegressionHarness._fail(failures, "footwork_def_dodge: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: exchange end clears defender offset (dodge applier path).
static func _run_footwork_defender_offset_scrubbed_after_exchange(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	def[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 9.0
	_AttackResultApplier.apply_result(
		mgr,
		_EntityAccess.id_int(atk),
		{"action": "dodge", "target_id": _EntityAccess.id_int(def), "recovery_duration": 0.2},
	)
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_def_scrub: defender offset should clear after dodge")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.4.3: footwork UI hint shows step label without degree clutter.
static func _run_footwork_ui_hint_formats_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var hint: String = _Footwork.format_position_angle_ui_hint(atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if hint != "Step":
		CombatRegressionHarness._fail(failures, "footwork_ui_hint: want 'Step' got '%s'" % hint)


## Tier 4.4.3: formation diagram has no footwork degree suffix.
static func _run_footwork_ui_hint_clears_on_clear_position_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_Footwork.clear_position_offset(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: hint key should be erased")
	if _Footwork.format_position_angle_ui_hint(c) != "":
		CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: format should be empty")
	if _Footwork.get_ui_hint(c) != "":
		CombatRegressionHarness._fail(failures, "footwork_ui_hint_clear: get_ui_hint should be empty")


## Tier 4.4: aborted wind-up clears attacker step offset (reserve / back rank stuck UI).
static func _run_footwork_abort_attacker_wind_up_clears_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	_WindUpStarter.start(mgr, atk_id, _EntityAccess.id_int(def), "slash")
	if absf(_Footwork.get_attacker_offset_deg(atk)) < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_abort: wind-up should stamp offset before abort")
	_CounterTempo.abort_attacker_wind_up(mgr, atk_id)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_abort: offset key should be erased after abort")
	if _Footwork.get_ui_hint(atk) != "":
		CombatRegressionHarness._fail(failures, "footwork_abort: get_ui_hint should be empty after abort")
	if _EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_abort: want short recovery after abort got '%s'" % _EntityAccess.state_str(atk)
		)


## Tier 4.4 UI: idle waiting hides stale offset on gauge/diagram even if dict key leaked.
static func _run_footwork_waiting_hides_stale_step_ui(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
	_Footwork.apply_attack_step_on_windup(c, "right")
	if _Footwork.get_ui_hint(c) != "":
		CombatRegressionHarness._fail(failures, "footwork_waiting_ui: get_ui_hint should be empty while waiting")
	if _Footwork.get_diagram_label_suffix(c) != "":
		CombatRegressionHarness._fail(failures, "footwork_waiting_ui: diagram suffix should be empty while waiting")
	CombatConstants.set_feature_position_angle_footwork_load(true)


## Tier 4.4 UI: snapshot rows omit PA export while idle waiting even if offset key leaked.
static func _run_footwork_snapshot_omits_pa_while_waiting(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	atk["state"] = CombatConstants.STATE_WAITING
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_snapshot_waiting: expected rows")
		return
	var row: Dictionary = rows[0]
	if row.has("position_angle_offset_deg"):
		CombatRegressionHarness._fail(
			failures, "footwork_snapshot_waiting: offset should not export while waiting"
		)
	if row.has("position_angle_ui_hint"):
		CombatRegressionHarness._fail(
			failures, "footwork_snapshot_waiting: ui hint should not export while waiting"
		)


## Tier 4.4: **`process_waiting`** scrubs leaked PA keys on idle reserve (wf_m3 idle step leak guard).
static func _run_footwork_process_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "guard": 1.0, "stamina": 80.0}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_StateHandlers.process_waiting(null, c, 0.05)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_waiting_scrub: offset key should be erased")
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_waiting_scrub: ui hint key should be erased")


## Tier 4.4 + III-8: **`complete_recovery`** accepts compatibility **`parry_deflect`** cause (deflect guard path + PA scrub).
static func _run_footwork_complete_recovery_parry_deflect_alias(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	c["state"] = CombatConstants.STATE_RECOVERING
	c["recovery_cause"] = "parry_deflect"
	c["last_move_id"] = "oberhau"
	c["effective_attack_line"] = "high"
	c["defender_guard_line_at_parry"] = "high"
	c["parry_clash_context"] = {"severity": 0.4}
	_Footwork.apply_attack_step_on_windup(c, "left")
	_StateHandlers.complete_recovery(mgr, c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_recovery_alias: offset should be cleared")
	if c.has("defender_guard_line_at_parry"):
		CombatRegressionHarness._fail(
			failures, "footwork_recovery_alias: deflect guard path should erase defender_guard_line_at_parry"
		)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_recovery_alias: want waiting after recovery got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: cowering tick scrubs leaked PA (**`process_incapacitation`** — no **`process_waiting`** on cowering).
static func _run_footwork_cowering_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	c["state"] = CombatConstants.STATE_COWERING
	_Footwork.apply_attack_step_on_windup(c, "left")
	_StateHandlers.process_incapacitation(mgr, c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_cowering_scrub: offset key should be erased")
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_cowering_scrub: ui hint key should be erased")


## Tier 4.4: formation-move timer tick scrubs leaked PA (**`process_formation_move_timer`**).
static func _run_footwork_formation_move_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {
		"state": CombatConstants.STATE_SWAP_RANK,
		"state_timer": 0.0,
		"state_duration": 0.5,
	}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_StateHandlers.process_formation_move_timer(c, 0.05)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_formation_scrub: offset key should be erased")
	if absf(float(c.get("state_timer", 0.0)) - 0.05) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"footwork_formation_scrub: timer should advance got %.4f" % float(c.get("state_timer", 0.0))
		)


## Tier 4.4: medical wind-up tick scrubs leaked PA (**`process_medical_wind_up`**).
static func _run_footwork_medical_wind_up_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {
		"state": CombatConstants.STATE_MEDICAL_WIND_UP,
		"state_timer": 0.0,
		"state_duration": 1.0,
	}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_StateHandlers.process_medical_wind_up(null, c, 0.05)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_medical_wind_up_scrub: offset key should be erased")
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_medical_wind_up_scrub: ui hint key should be erased")


## Tier 4.4: receiving-medical tick scrubs leaked PA (**`process_receiving_medical`**).
static func _run_footwork_receiving_medical_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {
		"state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
		"receiving_care_action_cooldown": 999.0,
	}
	_Footwork.apply_attack_step_on_windup(c, "left")
	_StateHandlers.process_receiving_medical(null, c, 0.05)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_receiving_medical_scrub: offset key should be erased")
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_receiving_medical_scrub: ui hint key should be erased")


## Tier 4.4: formation resolve return-to-waiting scrubs leaked PA (**`_set_combatant_waiting`**).
static func _run_footwork_formation_flow_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_FALLING_BACK}
	_Footwork.apply_attack_step_on_windup(c, "high")
	_FormationFlow._set_combatant_waiting(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_formation_waiting_scrub: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_formation_waiting_scrub: want waiting got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: **`return_to_waiting`** scrubs leaked PA on immediate idle transitions.
static func _run_footwork_return_to_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_RECOVERING}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_Footwork.return_to_waiting(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_return_waiting: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_return_waiting: want waiting got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: parry idle clears defender PA before **`waiting`** (same-frame snapshot guard).
static func _run_footwork_parry_idle_clears_pa_before_waiting(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var tgt: Dictionary = {"state": CombatConstants.STATE_WIND_UP, "guard_line": "high"}
	_Footwork.apply_defender_step_on_parry(tgt, "high")
	_AttackResultApplier._defender_set_idle_after_parry(tgt)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if tgt.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_parry_idle: offset key should be erased before waiting")
	if _EntityAccess.state_str(tgt) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_parry_idle: want waiting got '%s'" % _EntityAccess.state_str(tgt)
		)


## Tier 4.4: medical phase halt scrubs leaked PA on losing-side idle reset.
static func _run_footwork_medical_phase_halt_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var loser: Dictionary = mgr.combatants[1]
	loser["state"] = CombatConstants.STATE_RECOVERING
	loser["state_timer"] = 0.2
	loser["state_duration"] = 0.8
	_Footwork.apply_attack_step_on_windup(loser, "left")
	_MedicalPhase.halt_losing_side_combat(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if loser.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_medical_halt: offset key should be erased")
	if _EntityAccess.state_str(loser) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_medical_halt: want waiting got '%s'" % _EntityAccess.state_str(loser)
		)


## Tier 4.4: **`return_to_cowering`** scrubs leaked PA on no-arm idle transitions.
static func _run_footwork_return_to_cowering_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_RECOVERING}
	_Footwork.apply_attack_step_on_windup(c, "left")
	_Footwork.return_to_cowering(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_return_cowering: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_return_cowering: want cowering got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: mobility cowering sync scrubs leaked PA (**`sync_cowering_state_if_no_functional_arm`**).
static func _run_footwork_cowering_entry_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c["state"] = CombatConstants.STATE_WAITING
	_Footwork.apply_attack_step_on_windup(c, "right")
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_cowering_entry: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_cowering_entry: want cowering got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: flee resolve scrubs leaked PA (**`CombatFormationFlee.apply_flee`** via resolve).
static func _run_footwork_flee_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c["state"] = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	_Footwork.apply_attack_step_on_windup(c, "high")
	_ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_flee_scrub: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_FLED:
		CombatRegressionHarness._fail(
			failures,
			"footwork_flee_scrub: want fled got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: turn-ready / action-build death finalize clears PA (**`finalize_dead_combatant_if_node_dead`**).
static func _run_footwork_finalize_dead_combatant_clears_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: Node = _EntityAccess.scene_node(c)
	if ent == null:
		CombatRegressionHarness._fail(failures, "footwork_finalize_dead: missing entity")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	ent.blood_volume = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
	c["alive"] = true
	c["state"] = CombatConstants.STATE_WAITING
	_Footwork.apply_attack_step_on_windup(c, "high")
	if not _EntityAccess.finalize_dead_combatant_if_node_dead(mgr, c):
		CombatRegressionHarness._fail(failures, "footwork_finalize_dead: finalize should return true")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_finalize_dead: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_DEAD:
		CombatRegressionHarness._fail(
			failures,
			"footwork_finalize_dead: want dead got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: bleed-out death tick clears PA before **`STATE_DEAD`** (**`process_death_tick`**).
static func _run_footwork_death_tick_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: Node = _EntityAccess.scene_node(c)
	if ent == null:
		CombatRegressionHarness._fail(failures, "footwork_death_tick: missing entity")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	ent.blood_volume = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
	c["alive"] = true
	_Footwork.apply_attack_step_on_windup(c, "right")
	_StateHandlers.process_death_tick(mgr, c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_death_tick: offset key should be erased")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_DEAD:
		CombatRegressionHarness._fail(
			failures,
			"footwork_death_tick: want dead got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: formation move start scrubs leaked PA on both partners (**`start_pair_move`**).
static func _run_footwork_formation_move_start_scrubs_leaked_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	_Footwork.apply_attack_step_on_windup(p0, "left")
	_Footwork.apply_attack_step_on_windup(p1, "right")
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	for label_pair in [["p0", p0], ["p1", p1]]:
		var label: String = label_pair[0]
		var cd: Dictionary = label_pair[1]
		if cd.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
			CombatRegressionHarness._fail(
				failures, "footwork_formation_start_%s: offset key should be erased" % label
			)
		if _EntityAccess.state_str(cd) != CombatConstants.STATE_SWAP_RANK:
			CombatRegressionHarness._fail(
				failures,
				"footwork_formation_start_%s: want swap_rank got '%s'"
				% [label, _EntityAccess.state_str(cd)]
			)


## Tier 4.4: ally medical wind-up start scrubs target PA on **`receiving_medical_attention`** entry.
static func _run_footwork_medical_start_scrubs_target_receiving_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ally_ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally: Dictionary = mgr.combatants[1]
	var ally_id: int = _EntityAccess.id_int(ally)
	ally_ent.take_damage_split(8.0, 3.0, "chest")
	_Footwork.apply_attack_step_on_windup(ally, "high")
	_MedicalActionStarter.start(
		mgr, healer_id, ally_id, CombatConstants.MOVE_ID_PACK_WOUND, "chest"
	)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if ally.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(
			failures, "footwork_medical_start_target: offset key should be erased on receiving entry"
		)
	if _EntityAccess.state_str(ally) != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
		CombatRegressionHarness._fail(
			failures,
			"footwork_medical_start_target: want receiving_medical_attention got '%s'"
			% _EntityAccess.state_str(ally)
		)


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).
static func _run_footwork_enter_short_recovery_clears_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 12.0
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
	_StateHandlers.enter_short_recovery(c)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(
			failures, "footwork_enter_short_recovery: offset key should be erased"
		)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_enter_short_recovery: want recovering got '%s'" % _EntityAccess.state_str(c)
		)


## Tier 4.4: parry stamp reconciles leaked idle PA before fresh defender step.
static func _run_footwork_parry_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "guard_line": "high"}
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
	_Footwork.apply_defender_step_on_parry(c, "high")
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"high", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(got - want) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_parry_stamp_scrub: want high parry offset %.2f got %.2f" % [want, got]
		)
	if absf(got - 99.0) < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_parry_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: dodge stamp reconciles leaked idle PA before fresh defender step.
static func _run_footwork_dodge_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
	_Footwork.apply_defender_step_on_dodge(c, "left_leg")
	var line: String = CombatConstants.guard_line_for_body_part("left_leg")
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(got - want) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_dodge_stamp_scrub: want dodge offset %.2f got %.2f" % [want, got]
		)
	if absf(got - 99.0) < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_dodge_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).
static func _run_footwork_windup_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
	_Footwork.apply_attack_step_on_windup(c, "high")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_offset_deg_for_attack_line("high")
	var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	if absf(got - want) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_windup_stamp_scrub: want high offset %.2f got %.2f" % [want, got]
		)
	if absf(got - 99.0) < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_windup_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: medical wind-up complete clears medic PA before **`STATE_RECOVERING`**.
static func _run_footwork_medical_complete_scrubs_medic_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ally_ent, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer: Dictionary = mgr.combatants[0]
	var ally_id: int = _EntityAccess.id_int(mgr.combatants[1])
	ally_ent.take_damage_split(8.0, 3.0, "chest")
	healer["state"] = CombatConstants.STATE_MEDICAL_WIND_UP
	healer["state_duration"] = 2.0
	healer["pending_medical"] = {
		"medical_id": CombatConstants.MOVE_ID_PACK_WOUND,
		"target_part": "chest",
		"target_combatant_id": ally_id,
	}
	_Footwork.apply_attack_step_on_windup(healer, "left")
	_MedicalWindUp.complete(mgr, healer, healer.pending_medical)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if healer.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_medical_complete: medic offset should be cleared")
	if _EntityAccess.state_str(healer) != CombatConstants.STATE_RECOVERING:
		CombatRegressionHarness._fail(
			failures,
			"footwork_medical_complete: want recovering got '%s'" % _EntityAccess.state_str(healer)
		)


## Tier 4.4: rank-1 depth spear abort clears footwork (back rank reserve stuck -14°).
static func _run_footwork_back_rank_abort_clears_depth_windup(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = {}
	var front: Dictionary = {}
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
			if _EntityAccess.rank_int(c) == 1:
				depth = c
			elif _EntityAccess.rank_int(c) == 0:
				front = c
		elif _EntityAccess.rank_int(c) == 0:
			enemy = c
	if depth.is_empty() or front.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: expected player front+depth and enemy front")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: depth lane should be open for rank-1 spear")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var depth_id: int = _EntityAccess.id_int(depth)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	_WindUpStarter.start(mgr, depth_id, enemy_id, "spear_slash")
	if absf(_Footwork.get_attacker_offset_deg(depth)) < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: depth wind-up should stamp offset")
	_CounterTempo.abort_attacker_wind_up(mgr, depth_id)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if depth.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: offset should clear after abort")
	if _Footwork.get_ui_hint(depth) != "":
		CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: UI hint should be empty after abort")


## Tier 4.4.3: combat start scrubs stamped footwork UI hint (via clear_position_offset).
static func _run_footwork_ui_hint_clears_on_combat_start(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	_Footwork.apply_attack_step_on_windup(atk, "left")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		CombatRegressionHarness._fail(failures, "footwork_ui_hint_start: hint key should be erased on combat start")
	if _Footwork.get_ui_hint(atk) != "":
		CombatRegressionHarness._fail(failures, "footwork_ui_hint_start: get_ui_hint should be empty after start")


## Tier 4.4.3: combatant snapshot exposes offset + hint when footwork flag on.
static func _run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
	_Footwork.apply_attack_step_on_windup(c, "right")
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99°"
	var live: String = _Footwork.get_ui_hint(c)
	var want_live: String = _Footwork.format_position_angle_ui_hint(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if live != want_live:
		CombatRegressionHarness._fail(failures, "footwork_stale_stamp: want '%s' got '%s'" % [want_live, live])


## Tier 4.4.3: **`CombatUiHints.footwork_hint_text`** matches **`CombatFootwork.get_ui_hint`** (UI path).
static func _run_combat_ui_hints_footwork_stale_stamp_prefers_live_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
	_Footwork.apply_attack_step_on_windup(c, "right")
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99°"
	var live: String = _UiHints.footwork_hint_text(c)
	var want_live: String = _Footwork.format_position_angle_ui_hint(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if live != want_live:
		CombatRegressionHarness._fail(failures, "ui_hints_footwork_stale: want '%s' got '%s'" % [want_live, live])


## Tier 4.2 / 4.4: **`CombatUiHints.gauge_tooltip_lines`** reads stamped counter-tempo row keys.
static func _run_combat_ui_hints_gauge_tooltip_counter_ready(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var c: Dictionary = {"counter_tempo_ui_hint": "counter_ready"}
	var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c)
	var joined: String = "\n".join(tips)
	CombatConstants.set_feature_counter_tempo_load(true)
	if not joined.contains("Counter window open"):
		CombatRegressionHarness._fail(failures, "ui_hints_gauge_counter: want counter open tip got '%s'" % joined)


## Tier 4.2 UI: live counter-tempo tooltip needs **`manager`** when row keys are unstamped.
static func _run_battle_ui_gauge_tooltip_live_counter_tempo_needs_manager(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
	def.erase("counter_tempo_ui_hint")
	var without_mgr: String = "\n".join(_UiHints.gauge_tooltip_lines(def))
	var with_mgr: String = "\n".join(_UiHints.gauge_tooltip_lines(def, mgr))
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if without_mgr.contains("counter window"):
		CombatRegressionHarness._fail(
			failures,
			"gauge_tooltip_live: unstamped row should not show counter tip without manager got '%s'"
			% without_mgr
		)
	if not with_mgr.to_lower().contains("counter window"):
		CombatRegressionHarness._fail(
			failures,
			"gauge_tooltip_live: want counter window tip with manager got '%s'" % with_mgr
		)


## Camp-3.3: one-shot combat-log hints fire once per fight (manager meta).
static func _run_medical_phase_hints_emit_once_per_fight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var hints: Array = []
	mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr)
	_UiHints.emit_medical_phase_session_hints(mgr)
	var log_copy: PackedStringArray = _UiHints.medical_phase_combat_log_hints()
	if hints.size() != log_copy.size():
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_once: want %d hints on first emit got %d"
			% [log_copy.size(), hints.size()]
		)
	for line in log_copy:
		if not hints.has(line):
			CombatRegressionHarness._fail(
				failures, "medical_phase_hints_once: missing log line '%s'" % line
			)
	var joined: String = " ".join(hints)
	if not joined.contains("direct pressure") or not joined.contains("battle bandages are free"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_once: want triage priority copy got '%s'" % joined
		)
	if not joined.contains("dress the wound"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_once: want stabilize-vs-dressing copy got '%s'" % joined
		)
	if not joined.contains("cannot strike"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_once: want winner-lock copy got '%s'" % joined
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: world meta suppresses hints on later fights in the same session.
static func _run_medical_phase_hints_emit_once_per_world_session(
	failures: PackedStringArray
) -> void:
	var world: Node = Node.new()
	var mgr_a: Node = _MgrScript.new()
	mgr_a.medical_phase = true
	var hints_a: Array = []
	mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_a, world)
	var mgr_b: Node = _MgrScript.new()
	mgr_b.medical_phase = true
	var hints_b: Array = []
	mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_b, world)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
	if hints_a.is_empty():
		CombatRegressionHarness._fail(failures, "medical_phase_hints_world: first fight should emit")
	if not hints_b.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_world: second fight should not re-emit got %d" % hints_b.size()
		)


## Camp-3.3: without world meta, each new fight may show hints once (per-fight meta).
static func _run_medical_phase_hints_emit_again_on_new_fight_without_world(
	failures: PackedStringArray
) -> void:
	var mgr_a: Node = _MgrScript.new()
	mgr_a.medical_phase = true
	var hints_a: Array = []
	mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_a)
	var mgr_b: Node = _MgrScript.new()
	mgr_b.medical_phase = true
	var hints_b: Array = []
	mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_b)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
	if hints_a.is_empty() or hints_b.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_new_fight: want hints on both fights got %d and %d"
			% [hints_a.size(), hints_b.size()]
		)


## Camp-3.3: contract early-exit hint re-emits each fight even when session triage hints are suppressed.
static func _run_medical_phase_hints_campaign_each_contract_fight(
	failures: PackedStringArray
) -> void:
	var world: Node = Node.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var mgr_a: Node = _MgrScript.new()
	mgr_a.medical_phase = true
	var hints_a: Array = []
	mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_a, world)
	var mgr_b: Node = _MgrScript.new()
	mgr_b.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_b.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_b.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var ent_b: Node = _EntityAccess.scene_node(mgr_b.combatants[0])
	ent_b.take_damage_split(8.0, 2.0, "left_arm")
	mgr_b.medical_phase = true
	mgr_b.medical_phase_winner = "player"
	var hints_b: Array = []
	mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_b, world)
	var joined_a: String = " ".join(hints_a)
	var joined_b: String = " ".join(hints_b)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
	if hints_a.is_empty():
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign_each: first fight should emit hints"
		)
	if hints_b.is_empty():
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign_each: second fight should emit campaign hint"
		)
	if not joined_b.contains("Return to camp and finish medical treatment"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_each: second fight want early-exit copy got '%s'"
			% joined_b
		)
	if joined_b.contains("Medical phase — your side triages only"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_each: second fight should not repeat general triage hints"
		)
	if hints_b.size() != 1:
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_each: second fight want 1 hint got %d (%s)"
			% [hints_b.size(), joined_b]
		)
	if not joined_a.contains("Medical phase — your side triages only"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_each: first fight should include general triage hints"
		)


## Camp-3.3: low-med supply warning re-emits on later contract fights (not only first session hint).
static func _run_medical_phase_hints_campaign_supply_each_fight(
	failures: PackedStringArray
) -> void:
	var world: Node2D = Node2D.new()
	_CompanyState.init_from_defaults(world)
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	_CompanyState.set_medical_supplies(world, 1)
	_CompanyState.wire_party_medical_supply(world)
	var mgr_a: Node = _MgrScript.new()
	mgr_a.medical_phase = true
	var hints_a: Array = []
	mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_a, world)
	var mgr_b: Node = _MgrScript.new()
	mgr_b.medical_phase = true
	var hints_b: Array = []
	mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr_b, world)
	var joined_b: String = " ".join(hints_b)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
	if not " ".join(hints_a).contains("One med left"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign_supply: first fight want supply warning"
		)
	if not joined_b.contains("One med left"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_supply: second fight want supply warning got '%s'"
			% joined_b
		)


## Camp-3.3: clean contract victories get the ready early-exit hint (no simulate-remaining copy).
static func _run_medical_phase_hints_campaign_early_exit_ready(
	failures: PackedStringArray
) -> void:
	var world: Node = Node.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var hints: Array = []
	mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr, world)
	var joined: String = " ".join(hints)
	if not joined.contains("triage complete"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign_ready: want ready copy got '%s'" % joined
		)
	if joined.contains("simulate remaining"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_hints_campaign_ready: should not ask to simulate when triage done"
		)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: contract fights add early-exit hint when medical phase begins.
static func _run_medical_phase_hints_campaign_early_exit(failures: PackedStringArray) -> void:
	var world: Node = Node.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var ent: Node = _EntityAccess.scene_node(mgr.combatants[0])
	ent.take_damage_split(8.0, 2.0, "left_arm")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var hints: Array = []
	mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
	_UiHints.emit_medical_phase_session_hints(mgr, world)
	var joined: String = " ".join(hints)
	if not joined.contains("Return to camp and finish medical treatment"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign: want early-exit copy got '%s'" % joined
		)
	if not joined.contains("Party field care"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_hints_campaign: want map field-care copy got '%s'" % joined
		)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: contract medical tooltips mention return-to-camp auto-triage.
static func _run_medical_phase_gauge_tooltip_campaign_early_exit(
	failures: PackedStringArray
) -> void:
	var world: Node2D = Node2D.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var tips: String = "\n".join(_UiHints.medical_phase_context_tooltip_lines(mgr, world))
	if not tips.contains("Return to camp"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_campaign: want return-to-camp tip got '%s'" % tips
		)
	if not tips.contains("player side triages"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_campaign: want winner-lock tip got '%s'" % tips
		)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: clean contract victories get ready tooltip copy (no auto-complete clause).
static func _run_medical_phase_gauge_tooltip_campaign_ready(
	failures: PackedStringArray
) -> void:
	var world: Node2D = Node2D.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var tips: String = "\n".join(_UiHints.medical_phase_context_tooltip_lines(mgr, world))
	if not tips.contains("Triage complete"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_campaign_ready: want ready tip got '%s'" % tips
		)
	if tips.contains("remaining triage completes automatically"):
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_gauge_campaign_ready: should not mention auto-complete when done"
		)
	world.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: gauge tooltips during medical phase include triage priority + winner lock.
static func _run_medical_phase_gauge_tooltip_pressure_and_winner_lock(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "gauge": 100.0, "stamina": 40.0}
	var tips: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	if not tips.contains("player side triages"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_tip: want winner-lock line got '%s'" % tips
		)
	if not tips.contains("direct pressure") or not tips.contains("Battle bandages are free"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_tip: want triage priority copy got '%s'" % tips
		)
	mgr.medical_phase = false
	var off: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	if off.contains("Medical phase"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_gauge_tip: should omit medical copy when phase off"
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: receiving-care rows get medical-busy tooltip during medical phase.
static func _run_medical_phase_gauge_tooltip_medical_busy_receiving(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var c: Dictionary = {"state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION}
	var tips: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not tips.contains("Receiving care"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_busy: want receiving-care busy tip got '%s'" % tips
		)


## Camp-3.3: medic wind-up rows get medical-busy tooltip during medical phase.
static func _run_medical_phase_gauge_tooltip_medical_busy_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var c: Dictionary = {"state": CombatConstants.STATE_MEDICAL_WIND_UP}
	var tips: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not tips.contains("Medical wind-up"):
		CombatRegressionHarness._fail(
			failures, "medical_phase_busy_wu: want wind-up busy tip got '%s'" % tips
		)


## Camp-3.3: **`BattleUIUpdater`** primary label for receiving care during medical phase.
static func _run_battle_ui_gauge_label_receiving_care_during_medical_phase(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	var c: Dictionary = {
		"state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
		"alive": true,
		"gauge": 0.0,
		"stamina": 40.0,
	}
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not label.contains("Receiving care"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_receiving: want Receiving care primary got '%s'" % label
		)


## Camp-3.3: **`BattleUIUpdater`** primary label shows procedure during medical wind-up.
static func _run_battle_ui_gauge_label_medical_wind_up_primary(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	var c: Dictionary = {
		"state": CombatConstants.STATE_MEDICAL_WIND_UP,
		"alive": true,
		"state_timer": 0.5,
		"state_duration": 3.0,
		"pending_medical": {"medical_id": "apply_direct_pressure", "target_combatant_id": 1},
		"gauge": 0.0,
		"stamina": 40.0,
	}
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not label.contains("Direct pressure") or not label.contains("2.5s"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_med_wu: want procedure + timer primary got '%s'" % label
		)


## Tier 6.1 UI: cowering mobility lines on gauge tooltips.
static func _run_combat_ui_hints_cowering_gauge_tooltip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c["state"] = CombatConstants.STATE_COWERING
	var mobile_tip: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	if not mobile_tip.contains("fall back"):
		CombatRegressionHarness._fail(failures, "ui_hints_cowering: mobile want fall back tip got '%s'" % mobile_tip)
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	var immobile_tip: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not immobile_tip.contains("holding position"):
		CombatRegressionHarness._fail(failures, "ui_hints_cowering: immobile want holding tip got '%s'" % immobile_tip)


## Tier 6.1 UI: formation diagram cell tooltips include cowering mobility.
static func _run_combat_ui_hints_formation_cowering_tooltip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c["state"] = CombatConstants.STATE_COWERING
	var nm: String = _EntityAccess.get_display_name(c, _EntityAccess.id_int(c))
	var lines: PackedStringArray = _UiHints.formation_cell_tooltip_lines(c, nm, mgr)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	var joined: String = "\n".join(lines)
	if not joined.contains("fall back"):
		CombatRegressionHarness._fail(failures, "ui_hints_formation_cow: want fall back got '%s'" % joined)


static func _run_battle_ui_gauge_label_live_counter_tempo_needs_manager(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
	def.erase("counter_tempo_ui_hint")
	var without_mgr: String = _BattleUIUpdater.gauge_label_text_for_combatant(def)
	var with_mgr: String = _BattleUIUpdater.gauge_label_text_for_combatant(def, mgr)
	var bar_no_mgr: float = _BattleUIUpdater.gauge_bar_value_for_combatant(def)
	var bar_with_mgr: float = _BattleUIUpdater.gauge_bar_value_for_combatant(def, mgr)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if without_mgr.begins_with("Seize tempo"):
		CombatRegressionHarness._fail(
			failures,
			"gauge_label_live: unstamped row should not show counter label without manager got '%s'"
			% without_mgr
		)
	if not with_mgr.begins_with("Seize tempo"):
		CombatRegressionHarness._fail(
			failures,
			"gauge_label_live: want Seize tempo prefix with manager got '%s'" % with_mgr
		)
	if not is_equal_approx(bar_no_mgr, 100.0):
		CombatRegressionHarness._fail(
			failures, "gauge_bar_live: without manager bar should show stamina (100) got %.2f" % bar_no_mgr
		)
	if not is_equal_approx(bar_with_mgr, 100.0):
		CombatRegressionHarness._fail(
			failures,
			"gauge_bar_live: with manager bar should still show stamina (100) got %.2f" % bar_with_mgr
		)


## Tier 4.2 UI: formation tooltips derive counter window from **`manager`** when unstamped.
static func _run_combat_ui_hints_formation_counter_tempo_needs_manager(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
	def.erase("counter_tempo_ui_hint")
	var nm: String = _EntityAccess.get_display_name(def, def_id)
	var without_mgr: String = "\n".join(_UiHints.formation_cell_tooltip_lines(def, nm))
	var with_mgr: String = "\n".join(_UiHints.formation_cell_tooltip_lines(def, nm, mgr))
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if without_mgr.contains("counter window"):
		CombatRegressionHarness._fail(
			failures,
			"formation_counter_live: without manager got '%s'" % without_mgr
		)
	if not with_mgr.contains("counter window building"):
		CombatRegressionHarness._fail(
			failures,
			"formation_counter_live: with manager want building tip got '%s'" % with_mgr
		)


## Tier 4.3 UI: with **`manager`**, stale **`attention_ui_hint`** stamp ignored when telegraph absent.
static func _run_combat_ui_hints_attention_stale_stamp_prefers_live(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var c: Dictionary = {"guard_zone": "head", CombatConstants.COMBATANT_KEY_FOCUS_PART: "head"}
	c[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = "Tel head · Focus head 99%"
	var mgr: Node = _MgrScript.new()
	var stamped_path: String = _UiHints.attention_hint_text(c)
	var live_path: String = _UiHints.attention_hint_text(c, mgr)
	CombatConstants.set_feature_combat_attention_load(false)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not stamped_path.contains("Tel head"):
		CombatRegressionHarness._fail(failures, "attention_stale: snapshot path want Tel got '%s'" % stamped_path)
	if live_path.contains("Tel head"):
		CombatRegressionHarness._fail(failures, "attention_stale: live path should drop Tel got '%s'" % live_path)


## Tier 4.3 UI: **`attention_hint_text(..., manager)`** refreshes load during incoming wind-up.
static func _run_combat_ui_hints_attention_live_refresh_load_during_windup(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	_WindUpStarter.start(mgr, _EntityAccess.id_int(atk), _EntityAccess.id_int(def), "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	def.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	def.erase("attention_ui_hint")
	def[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 0.0
	var without_mgr: String = _UiHints.attention_hint_text(def)
	var with_mgr: String = _UiHints.attention_hint_text(def, mgr)
	CombatConstants.set_feature_combat_attention_load(false)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if without_mgr.contains("Load 45") or without_mgr.contains("Load 40"):
		CombatRegressionHarness._fail(
			failures,
			"attention_live_load: without manager should not refresh load got '%s'" % without_mgr
		)
	if with_mgr.find("Load ") < 0:
		CombatRegressionHarness._fail(failures, "attention_live_load: with manager want Load segment got '%s'" % with_mgr)


static func _run_strike_stamping_weapon_eff_dist_sanity(failures: PackedStringArray) -> void:
	var w: Weapon = _Weapon.create_from_definition("SWORD")
	if w == null:
		CombatRegressionHarness._fail(failures, "strike_stamp: missing SWORD")
		return
	var eff: float = 1.25
	var ratio: float = _StrikeStamping.strike_measure_ratio_for_weapon_eff_dist(w, eff)
	if not is_finite(ratio) or ratio < 0.0:
		CombatRegressionHarness._fail(failures, "strike_stamp: want finite non-negative ratio got %.4f" % ratio)


## Tier 4.4 UI: stamped hint without offset is ignored (row/diagram stay blank).
static func _run_footwork_ui_hint_ignores_orphan_stamp_without_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {}
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99°"
	var live: String = _Footwork.get_ui_hint(c)
	var sfx: String = _Footwork.get_diagram_label_suffix(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if not live.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_orphan_stamp: get_ui_hint should be empty got '%s'" % live)
	if not sfx.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_orphan_stamp: diagram suffix should be empty got '%s'" % sfx)


## Tier 4.4.3: clearing offset clears stamped UI hint key.
static func _run_footwork_diagram_label_suffix_compact(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
	_Footwork.apply_attack_step_on_windup(c, "left")
	var sfx: String = _Footwork.get_diagram_label_suffix(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if not sfx.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_diagram_suffix: want empty got '%s'" % sfx)


## Tier 4.4.3: stale stamped hint yields live offset when they disagree.
static func _run_footwork_snapshot_includes_position_hint_when_enabled(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	_WindUpStarter.start(mgr, _EntityAccess.id_int(atk), _EntityAccess.id_int(def), "slash")
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_snapshot: expected one row")
		return
	var row: Dictionary = rows[0]
	if not row.has("position_angle_offset_deg"):
		CombatRegressionHarness._fail(failures, "footwork_snapshot: missing position_angle_offset_deg")
	var want_hint: String = _Footwork.get_ui_hint(atk)
	if str(row.get("position_angle_ui_hint", "")) != want_hint:
		CombatRegressionHarness._fail(
			failures,
			"footwork_snapshot: ui hint mismatch row='%s' want='%s'"
			% [row.get("position_angle_ui_hint", ""), want_hint]
		)


## Tier 4.4.3: snapshot derives UI hint from offset when stamp key missing.
static func _run_footwork_snapshot_ui_hint_from_unstamped_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var atk: Dictionary = mgr.combatants[0]
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
	atk["state"] = CombatConstants.STATE_WIND_UP
	atk.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	var rows: Array = _CombatSnapshot.build(mgr)
	var want_hint: String = _Footwork.get_ui_hint(atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_snapshot_unstamped: expected one row")
		return
	var row: Dictionary = rows[0]
	if str(row.get("position_angle_ui_hint", "")) != want_hint:
		CombatRegressionHarness._fail(
			failures,
			"footwork_snapshot_unstamped: want '%s' got '%s'" % [want_hint, row.get("position_angle_ui_hint", "")]
		)
	if absf(float(row.get("position_angle_offset_deg", 0.0)) - off) > 0.01:
		CombatRegressionHarness._fail(failures, "footwork_snapshot_unstamped: offset deg missing or wrong")


## Tier 4.4 UI soak: snapshot copies stamped attention hint for gauge/diagram consumers.
static func _run_footwork_snapshot_omits_position_when_disabled(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var atk: Dictionary = mgr.combatants[0]
	_Footwork.apply_attack_step_on_windup(atk, "left")
	CombatConstants.set_feature_position_angle_footwork_load(false)
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "footwork_snapshot_disabled: expected one row")
		return
	var row: Dictionary = rows[0]
	if row.has("position_angle_offset_deg") or row.has("position_angle_ui_hint"):
		CombatRegressionHarness._fail(
			failures,
			"footwork_snapshot_disabled: should omit position_angle keys when flag off"
		)


## Tier 4.4: body-part → guard line for dodge step direction.
static func _run_combat_snapshot_exports_attention_ui_hint_when_stamped(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	var stamped: String = "Tel head · Focus head 80%"
	def[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = stamped
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_combat_attention_load(false)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_attention: expected one row")
		return
	if str(rows[0].get("attention_ui_hint", "")) != stamped:
		CombatRegressionHarness._fail(
			failures,
			"snapshot_attention: row='%s' want='%s'"
			% [rows[0].get("attention_ui_hint", ""), stamped]
		)


## Tier 4.4 UI soak: snapshot copies stamped counter-tempo hint for gauge consumers.
static func _run_combat_snapshot_exports_counter_tempo_ui_hint_when_stamped(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	var stamped: String = "counter_ready"
	def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = stamped
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_counter_tempo: expected one row")
		return
	if str(rows[0].get("counter_tempo_ui_hint", "")) != stamped:
		CombatRegressionHarness._fail(
			failures,
			"snapshot_counter_tempo: row='%s' want='%s'"
			% [rows[0].get("counter_tempo_ui_hint", ""), stamped]
		)


## Tier 4.2 UI soak: counter-tempo row hint wins over scheduled-next **`status_override`**.
static func _run_combat_snapshot_suppresses_next_override_during_counter_tempo(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_ready"
	mgr.event_queue.append({
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": def_id,
		"resolve_at": float(mgr.combat_clock) + 0.5,
	})
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_counter_next: expected one row")
		return
	var row: Dictionary = rows[0]
	if str(row.get("counter_tempo_ui_hint", "")) != "counter_ready":
		CombatRegressionHarness._fail(
			failures,
			"snapshot_counter_next: counter hint missing row=%s" % row.get("counter_tempo_ui_hint", "")
		)
	if row.has("status_override"):
		CombatRegressionHarness._fail(
			failures,
			"snapshot_counter_next: status_override should be suppressed got '%s'"
			% row.get("status_override", "")
		)


## Tier 4.3 UI soak: snapshot derives attention row hint from telegraph when stamp missing.
static func _run_combat_snapshot_derives_attention_ui_hint_from_telegraph(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	def[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	def.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	var want: String = _UiHints.attention_hint_text(def, mgr)
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_combat_attention_load(false)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if want.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_attention_derive: expected non-empty derived hint")
		return
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_attention_derive: expected one row")
		return
	if str(rows[0].get("attention_ui_hint", "")) != want:
		CombatRegressionHarness._fail(
			failures,
			"snapshot_attention_derive: row='%s' want='%s'"
			% [rows[0].get("attention_ui_hint", ""), want]
		)


## Tier 4.2 UI soak: snapshot derives counter-tempo hint from open window when stamp missing.
static func _run_combat_snapshot_derives_counter_tempo_ui_hint_from_open_window(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
	var rows: Array = _CombatSnapshot.build(mgr)
	var want: String = _CounterTempo.snapshot_ui_hint(mgr, def)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_counter_derive: expected two rows")
		return
	var row: Dictionary = rows[1]
	if want != "counter_winding":
		CombatRegressionHarness._fail(failures, "snapshot_counter_derive: want counter_winding got '%s'" % want)
	if str(row.get("counter_tempo_ui_hint", "")) != want:
		CombatRegressionHarness._fail(
			failures,
			"snapshot_counter_derive: row='%s' want='%s'"
			% [row.get("counter_tempo_ui_hint", ""), want]
		)


## Tier 4.2 UI: gauge label prefers counter hint over **`status_override`**.
static func _run_battle_ui_gauge_label_counter_beats_status_override(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var row: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"status_override": "Next: 0.1s",
		"counter_tempo_ui_hint": "counter_ready",
		"gauge": 100.0,
		"stamina": 100.0,
	}
	var text: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	CombatConstants.set_feature_counter_tempo_load(true)
	if not text.begins_with("Counter!"):
		CombatRegressionHarness._fail(failures, "battle_ui_counter_label: want Counter! prefix got '%s'" % text)
	if text.find("Next:") >= 0:
		CombatRegressionHarness._fail(failures, "battle_ui_counter_label: should not show Next override in '%s'" % text)


## Tier 4.3 UI: **`status_override`** row still shows attention fragment.
static func _run_battle_ui_gauge_label_status_override_includes_attention(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var attn: String = "Tel head · Focus head 80%"
	var row: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"status_override": "Closing 1.2s",
		"attention_ui_hint": attn,
		"gauge": 40.0,
		"stamina": 40.0,
	}
	var text: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	CombatConstants.set_feature_combat_attention_load(false)
	if text.find("Closing") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_status_attn: missing Closing in '%s'" % text)
	if text.find("Tel head") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_status_attn: missing attention in '%s'" % text)


## Tier 4.2 UI: counter-tempo wind-up uses **Counter** prefix on gauge row.
static func _run_battle_ui_gauge_label_counter_wind_up_prefix(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var row: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WIND_UP,
		"state_timer": 0.1,
		"state_duration": 0.5,
		"is_counter_tempo_wind_up": true,
	}
	var text: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	CombatConstants.set_feature_counter_tempo_load(true)
	if not text.begins_with("Counter "):
		CombatRegressionHarness._fail(failures, "battle_ui_counter_windup: want Counter prefix got '%s'" % text)


## Tier 4.2 UI soak: snapshot skips Closing/Crash/Next overrides while counter window UI active.
static func _run_combat_snapshot_omits_closing_override_during_counter_tempo(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_ready"
	def["action_cooldown_until"] = float(mgr.combat_clock) + 2.0
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "snapshot_counter_closing: expected one row")
		return
	if rows[0].has("status_override"):
		CombatRegressionHarness._fail(
			failures,
			"snapshot_counter_closing: status_override should be suppressed got '%s'"
			% rows[0].get("status_override", "")
		)


## Tier 4.4 UI soak: **`gauge_label_text_for_combatant`** matches **`CombatCombatantsSnapshot.build`** row.
## WF-1c + Tier 4.4: gauge suffix order **Step → Atk → Form** during wind-up — LIVE_PATHS **`#wf-soak-audit-status`**.
static func _run_battle_ui_gauge_suffix_step_atk_form_order(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WIND_UP,
		"state_timer": 0.0,
		"state_duration": 1.0,
		"gauge": 100.0,
		"stamina": 67.0,
		"guard_line": "high",
		CombatConstants.COMBATANT_KEY_WEAPON_FORM: _WeaponForm.FORM_OX,
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: 14.0,
		"pending_attack": {"attack_line": "high_right", "move_id": "oberhau"},
	}
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c)
	for needle in ["Step", "Atk", " · Form Ox"]:
		if needle not in label:
			CombatRegressionHarness._fail(
				failures,
				"gauge_suffix_step_atk_form: missing '%s' in '%s'" % [needle, label]
			)
			return
	var step_i: int = label.find("Step")
	var atk_i: int = label.find("Atk")
	var form_i: int = label.find(" · Form Ox")
	if step_i < 0 or atk_i < 0 or form_i < 0 or not (step_i < atk_i and atk_i < form_i):
		CombatRegressionHarness._fail(
			failures,
			"gauge_suffix_step_atk_form: want Step<Atk<Form order got '%s'" % label
		)


static func _run_battle_ui_gauge_label_matches_snapshot_row(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_combat_attention_load(true)
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	def[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_winding"
	def["gauge"] = 80.0
	def["stamina"] = 80.0
	var rows: Array = _CombatSnapshot.build(mgr)
	if rows.is_empty():
		CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: expected one row")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var row: Dictionary = rows[0]
	var want: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatConstants.set_feature_combat_attention_load(false)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if not want.begins_with("Seize tempo"):
		CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: want Seize tempo prefix got '%s'" % want)
	if want.find("Tel head") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: missing attention fragment in '%s'" % want)


## Tier 4.4 UI soak: exported row hints still render when feature flags are toggled off.
static func _run_battle_ui_gauge_label_renders_exported_hints_when_features_off(
	failures: PackedStringArray
) -> void:
	var row: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"attention_ui_hint": "Tel head · Focus head 80%",
		"counter_tempo_ui_hint": "counter_ready",
		"position_angle_ui_hint": "Step +14°",
		"gauge": 100.0,
		"stamina": 100.0,
	}
	CombatConstants.set_feature_combat_attention_load(false)
	CombatConstants.set_feature_counter_tempo_load(false)
	CombatConstants.set_feature_position_angle_footwork_load(false)
	var text: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	CombatConstants.set_feature_combat_attention_load(true)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if not text.begins_with("Counter!"):
		CombatRegressionHarness._fail(failures, "battle_ui_exported_off: want Counter! prefix got '%s'" % text)
	if text.find("Tel head") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_exported_off: missing attention in '%s'" % text)
	if text.find("Step +14") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_exported_off: missing footwork in '%s'" % text)


## Tier 4.3 UI: recovering row keeps exported attention fragment.
static func _run_battle_ui_gauge_label_recovering_includes_exported_attention(
	failures: PackedStringArray
) -> void:
	var row: Dictionary = {
		"alive": true,
		"state": "recovering",
		"state_timer": 0.2,
		"state_duration": 1.0,
		"attention_ui_hint": "Tel head · Focus head 80%",
	}
	var text: String = _BattleUIUpdater.gauge_label_text_for_combatant(row)
	if not text.begins_with("Recov."):
		CombatRegressionHarness._fail(failures, "battle_ui_recov_attn: want Recov prefix got '%s'" % text)
	if text.find("Tel head") < 0:
		CombatRegressionHarness._fail(failures, "battle_ui_recov_attn: missing attention in '%s'" % text)


## Tier 4.2 UI: player turn-ready combat log hint when counter-tempo melee is listed.
static func _run_player_counter_tempo_turn_ready_hint_when_window_open(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var ply: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	var ply_id: int = _EntityAccess.id_int(ply)
	var en_id: int = _EntityAccess.id_int(en)
	ply["gauge"] = 80.0
	_WindUpStarter.start(mgr, en_id, ply_id, "oberhau")
	CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, en_id, 0.6)
	_CounterTempo.process_waiting(mgr, ply)
	var actions: Array = mgr.get_available_actions(ply_id)
	var hint: String = _PlayerTurnHints.counter_tempo_hint_if_applicable(mgr, ply, actions)
	CombatConstants.set_feature_counter_tempo_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if hint.is_empty():
		CombatRegressionHarness._fail(failures, "player_counter_hint: expected non-empty hint")
		return
	if hint.find("seize tempo") < 0:
		CombatRegressionHarness._fail(failures, "player_counter_hint: want seize tempo in '%s'" % hint)


## Tier 4.2 UI: progress bar always maps to stamina (counter-tempo readiness on label only).
static func _run_battle_ui_gauge_bar_always_stamina_even_during_counter_tempo(
	failures: PackedStringArray
) -> void:
	var row_counter: Dictionary = {
		"alive": true,
		"counter_tempo_ui_hint": "counter_ready",
		"gauge": 72.0,
		"stamina": 40.0,
	}
	if absf(_BattleUIUpdater.gauge_bar_value_for_combatant(row_counter) - 40.0) > 0.01:
		CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: counter row should use stamina=40")
	if absf(_BattleUIUpdater.gauge_bar_max_for_combatant(row_counter) - CombatConstants.STAMINA_MAX) > 0.01:
		CombatRegressionHarness._fail(
			failures,
			"battle_ui_gauge_bar: fresh counter row max should be STAMINA_MAX"
		)
	var row_plain: Dictionary = {
		"alive": true,
		"gauge": 72.0,
		"stamina": 40.0,
	}
	if absf(_BattleUIUpdater.gauge_bar_value_for_combatant(row_plain) - 40.0) > 0.01:
		CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: plain row should use stamina=40")


## Tier 4.4.3: snapshot omits position-angle fields when footwork flag off.
static func _run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures: PackedStringArray) -> void:
	var want_leg: String = (
		_GuardLines.LINE_LOW_RIGHT
		if CombatConstants.is_feature_hema_eight_guard_lines_enabled()
		else "low"
	)
	var want_chest: String = (
		_GuardLines.LINE_HIGH
		if CombatConstants.is_feature_hema_eight_guard_lines_enabled()
		else "high"
	)
	if CombatConstants.guard_line_for_body_part("right_leg") != want_leg:
		CombatRegressionHarness._fail(failures, "footwork_part_line: right_leg want %s" % want_leg)
	if CombatConstants.guard_line_for_body_part("chest") != want_chest:
		CombatRegressionHarness._fail(failures, "footwork_part_line: chest want %s" % want_chest)


## Tier 4.4: parry-eval helpers do not stamp offset; dodge commit replaces parry stamp.
static func _run_footwork_choose_defense_dodge_does_not_keep_parry_offset(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {"guard_line": "left"}
	var prov: float = _Footwork.parry_eval_step_deg_for_defender(def)
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_provisional: parry_eval must not stamp offset on combatant")
	if prov < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_provisional: want non-zero eval step for left guard")
	var dodge_prov: float = _Footwork.dodge_eval_step_deg_for_defender(def, "left_arm")
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_provisional: dodge_eval must not stamp offset on combatant")
	if dodge_prov < 0.01:
		CombatRegressionHarness._fail(failures, "footwork_provisional: want non-zero dodge eval for left_arm")
	_Footwork.apply_defender_step_on_parry(def, "left")
	var parry_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	_Footwork.clear_position_offset(def)
	_Footwork.apply_defender_step_on_dodge(def, "left_arm")
	var dodge_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want_dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(parry_off - dodge_off) < 0.01:
		CombatRegressionHarness._fail(
			failures,
			"footwork_commit_dodge: dodge offset should differ from parry stamp got %.2f"
			% dodge_off
		)
	if absf(dodge_off - want_dodge) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_commit_dodge: want dodge offset %.2f got %.2f" % [want_dodge, dodge_off]
		)


## Tier 4.4: **`arc_end_deg_for_contact_geometry`** must not treat offset-bearing **`attack_angle_deg`** as arc end.
static func _run_footwork_arc_contact_applies_offset_once(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("left")
		),
	}
	var arc_start: float = 0.0
	var arc_end_base: float = 90.0
	var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end_base, 1.0)
	at_contact = _Footwork.apply_offset_to_angle_deg(at_contact, atk)
	var doubled: float = _Footwork.apply_offset_to_angle_deg(
		CombatConstants.get_arc_angle_at_progress(arc_start, arc_end_base + atk.get(
			CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0
		), 1.0),
		atk
	)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(arc_end_base + float(atk.get(
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0
	)) + 360.0, 360.0)
	if absf(at_contact - want) > 0.05:
		CombatRegressionHarness._fail(failures, "footwork_arc_once: want %.2f got %.2f" % [want, at_contact])
	if absf(doubled - at_contact) < 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_arc_once: double-apply would match got %.2f (want distinct)" % at_contact
		)


## Tier 4.4: flag off — step-on-windup does not stamp offset (restore production default after).
static func _run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	var pa: Dictionary = {
		"arc_intended_deg": 90.0,
		"attack_angle_deg": fmod(90.0 + off + 360.0, 360.0),
	}
	var end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(end - 90.0) > 0.05:
		CombatRegressionHarness._fail(failures, "footwork_arc_end_fb: want intended 90 got %.2f" % end)
	var arc_start: float = float(pa.get("arc_start_deg", 0.0))
	var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
	var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, 1.0)
	var atk: Dictionary = {CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: off}
	at_contact = _Footwork.apply_offset_to_angle_deg(at_contact, atk)
	var doubled: float = _Footwork.apply_offset_to_angle_deg(90.0 + off, atk)
	if absf(at_contact - doubled) < 0.05:
		CombatRegressionHarness._fail(failures, "footwork_arc_end_fb: progress-1 should apply offset once got %.2f" % at_contact)


## Tier 4.4: **`parry_partial`** follow-through must not re-roll resolve angle geometry.
static func _run_footwork_windup_arc_intended_includes_attacker_step(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	var p_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	var e_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(p_ent, "player")
	mgr.register(e_ent, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	seed(42)
	_WindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "chest"})
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var atk: Dictionary = mgr._get_by_id(p_id)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	var intended: float = float(pa.get("arc_intended_deg", -999.0))
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var atk_line: String = str(move_def.get("attack_line", "high"))
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line(atk_line)
	var want: float = fmod(CombatConstants.line_to_angle(atk_line) + off + 360.0, 360.0)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)
	if intended < -900.0:
		CombatRegressionHarness._fail(failures, "footwork_windup_intended: missing arc_intended_deg")
		return
	if absf(intended - want) > 0.05:
		CombatRegressionHarness._fail(failures, "footwork_windup_intended: want %.2f got %.2f" % [want, intended])


## Tier 4.4: **`arc_end_deg`** stays pre-offset; parry contact applies footwork once (not twice at progress 1).
static func _run_footwork_partial_follow_through_freezes_resolve_angles(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("high")
		),
	}
	var pa: Dictionary = {
		"passive_parry_attempted": true,
		"attack_angle_deg": 201.0,
		"arc_end_deg": 187.0,
		"arc_span_deg": 42.0,
		"effective_attack_line": "left",
		"arc_start_deg": 0.0,
	}
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	_AttackResolver.stamp_resolve_angle_geometry_on_pa(pa, atk, "high", move_def, 0.0)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(float(pa.get("attack_angle_deg", -1.0)) - 201.0) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_partial_freeze: attack_angle_deg changed to %.2f" % float(pa.get("attack_angle_deg", -1.0))
		)
	if absf(float(pa.get("arc_end_deg", -1.0)) - 187.0) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_partial_freeze: arc_end_deg changed to %.2f" % float(pa.get("arc_end_deg", -1.0))
		)
	if absf(float(pa.get("arc_span_deg", -1.0)) - 42.0) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"footwork_partial_freeze: arc_span_deg changed to %.2f" % float(pa.get("arc_span_deg", -1.0))
		)
	if str(pa.get("effective_attack_line", "")) != "left":
		CombatRegressionHarness._fail(
			failures,
			"footwork_partial_freeze: effective_attack_line changed to %s"
			% str(pa.get("effective_attack_line", ""))
		)


## Tier 4.4: wind-up **`arc_intended_deg`** includes attacker step (guard transition + arc query).
static func _run_footwork_disabled_skips_windup_stamp(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(false)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		CombatRegressionHarness._fail(failures, "footwork_disabled: offset must not stamp when flag off")


## Tier 4.3.8: attention UI hint shows last mental-stack layer stamp.
static func run(failures: PackedStringArray) -> void:
	_run_attention_being_wind_up_targeted_when_telegraph_set(failures)
	_run_attention_counter_tempo_salience_matches_can_act(failures)
	_run_attention_load_stacks_peril_and_incoming(failures)
	_run_focus_intensity_scales_feint_readthrough_and_guard_zone(failures)
	_run_attention_load_dampens_focus_effective_readiness(failures)
	_run_mental_stack_medical_overrides_attack(failures)
	_run_mental_stack_incoming_windup_prefers_defense(failures)
	_run_mental_stack_counter_over_plain_attack_when_window_open(failures)
	_run_mental_stack_attack_layer_matches_stance_alias_weights(failures)
	_run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures)
	_run_yomi_updates_on_parry_deflect_clears_on_hit(failures)
	_run_attention_ui_hint_formats_when_telegraph_set(failures)
	_run_attention_refresh_waiting_tick_stamps_ui_hint(failures)
	_run_yomi_focus_drift_sets_habitual_part_on_ai(failures)
	_run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(failures)
	_run_guard_from_move_syncs_focus_part_with_guard_line(failures)
	_run_mental_stack_stamps_layer_on_medical_pick(failures)
	_run_mental_stack_self_peril_before_ally_medical(failures)
	_run_mental_stack_hold_line_only_picks_focus_or_wait(failures)
	_run_mental_stack_hold_line_attempt_close_wing(failures)
	_run_mental_stack_hold_line_attempt_close_mop_up(failures)
	_run_mental_stack_hold_line_attempt_close_mop_up_mid(failures)
	_run_mental_stack_close_beats_focus_mop_up_under_telegraph(failures)
	_run_hold_line_hint_mop_up(failures)
	_run_hold_line_hint_mop_up_strikes_listed(failures)
	_run_hold_line_hint_mop_up_rear_rank(failures)
	_run_hold_line_hint_mop_up_rear_rank_strikes(failures)
	_run_hold_line_hint_back_rank_not_mopup(failures)
	_run_mental_stack_formation_plug_swap_rank_over_strike(failures)
	_run_mental_stack_formation_plug_incap_forward(failures)
	_run_mental_stack_formation_plug_rotate_skirmish_hole(failures)
	_run_mental_stack_formation_plug_skipped_fight_finish(failures)
	_run_mental_stack_formation_plug_skipped_mop_up_offense(failures)
	_run_mental_stack_formation_plug_no_gap_stack_miss(failures)
	_run_mental_stack_formation_plug_skipped_sparse_line_offense(failures)
	_run_mental_stack_sparse_fight_stamps_layer_on_try_pick(failures)
	_run_mental_stack_formation_plug_picker_e2e(failures)
	_run_mental_stack_rout_stressed_flee_beats_strike(failures)
	_run_mental_stack_rout_casualty_flee_beats_wait(failures)
	_run_mental_stack_rout_skipped_fight_finish(failures)
	_run_mental_stack_rout_firm_line_no_stamp(failures)
	_run_mental_stack_exhaustion_tunnel_prefers_disengage(failures)
	_run_mental_stack_exhaustion_tunnel_flee_beats_rotate_file(failures)
	_run_mental_stack_critical_stamina_flee_beats_rotate_file(failures)
	_run_p4a_ms_l7_exhaustion_threshold_parity(failures)
	_run_focus_line_actions_listed_when_attention_enabled(failures)
	_run_append_combat_wait_lists_wait_for_focus_only_menu(failures)
	_run_append_combat_wait_lists_wait_for_close_and_focus_menu(failures)
	_run_focus_line_noop_skips_without_guard_change(failures)
	_run_focus_line_resolve_sets_guard_and_focus(failures)
	_run_focus_line_party_leader_prefers_telegraph_match(failures)
	_run_yomi_parry_deflect_boosts_feint_listing_mult(failures)
	_run_yomi_defense_readiness_mult_boosts_after_parry_deflect(failures)
	_run_attention_ui_hint_includes_mental_stack_layer(failures)
	_run_footwork_attack_step_offset_stamped_on_windup(failures)
	_run_footwork_attack_eval_no_stamp_offset(failures)
	_run_footwork_picker_preview_uses_attack_eval_when_idle(failures)
	_run_footwork_picker_preview_wind_up_uses_live_stamp(failures)
	_run_footwork_picker_preview_flurry_bind_when_idle(failures)
	_run_footwork_offset_shifts_attack_angle_deg(failures)
	_run_footwork_offset_scrubbed_on_combat_start(failures)
	_run_footwork_defender_parry_step_stamps_offset(failures)
	_run_t44_spatial_band_pa_suite(failures)
	_run_t44_spatial_file_dodge_suite(failures)
	_run_t44_spatial_flurry_pa_suite(failures)
	_run_footwork_wf_t1_octant_suite(failures)
	_run_footwork_defender_offset_shifts_guard_angle_deg(failures)
	_run_footwork_defender_dodge_step_stamps_offset(failures)
	_run_footwork_defender_offset_scrubbed_after_exchange(failures)
	_run_footwork_ui_hint_formats_offset(failures)
	_run_footwork_ui_hint_clears_on_clear_position_offset(failures)
	_run_footwork_abort_attacker_wind_up_clears_offset(failures)
	_run_footwork_waiting_hides_stale_step_ui(failures)
	_run_footwork_snapshot_omits_pa_while_waiting(failures)
	_run_footwork_process_waiting_scrubs_leaked_offset(failures)
	_run_footwork_complete_recovery_parry_deflect_alias(failures)
	_run_footwork_cowering_scrubs_leaked_offset(failures)
	_run_footwork_formation_move_scrubs_leaked_offset(failures)
	_run_footwork_medical_wind_up_scrubs_leaked_offset(failures)
	_run_footwork_receiving_medical_scrubs_leaked_offset(failures)
	_run_footwork_formation_flow_waiting_scrubs_leaked_offset(failures)
	_run_footwork_return_to_waiting_scrubs_leaked_offset(failures)
	_run_footwork_parry_idle_clears_pa_before_waiting(failures)
	_run_footwork_medical_phase_halt_scrubs_leaked_offset(failures)
	_run_footwork_return_to_cowering_scrubs_leaked_offset(failures)
	_run_footwork_cowering_entry_scrubs_leaked_offset(failures)
	_run_footwork_flee_scrubs_leaked_offset(failures)
	_run_footwork_death_tick_scrubs_leaked_offset(failures)
	_run_footwork_finalize_dead_combatant_clears_offset(failures)
	_run_footwork_formation_move_start_scrubs_leaked_offset(failures)
	_run_footwork_medical_start_scrubs_target_receiving_offset(failures)
	_run_footwork_enter_short_recovery_clears_offset(failures)
	_run_footwork_parry_stamp_scrubs_leaked_idle_offset(failures)
	_run_footwork_dodge_stamp_scrubs_leaked_idle_offset(failures)
	_run_footwork_windup_stamp_scrubs_leaked_idle_offset(failures)
	_run_footwork_medical_complete_scrubs_medic_offset(failures)
	_run_footwork_back_rank_abort_clears_depth_windup(failures)
	_run_footwork_ui_hint_clears_on_combat_start(failures)
	_run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures)
	_run_combat_ui_hints_footwork_stale_stamp_prefers_live_offset(failures)
	_run_combat_ui_hints_gauge_tooltip_counter_ready(failures)
	_run_battle_ui_gauge_tooltip_live_counter_tempo_needs_manager(failures)
	_run_medical_phase_hints_emit_once_per_fight(failures)
	_run_medical_phase_hints_emit_once_per_world_session(failures)
	_run_medical_phase_hints_emit_again_on_new_fight_without_world(failures)
	_run_medical_phase_hints_campaign_early_exit(failures)
	_run_medical_phase_hints_campaign_early_exit_ready(failures)
	_run_medical_phase_hints_campaign_each_contract_fight(failures)
	_run_medical_phase_hints_campaign_supply_each_fight(failures)
	_run_medical_phase_gauge_tooltip_campaign_early_exit(failures)
	_run_medical_phase_gauge_tooltip_campaign_ready(failures)
	_run_medical_phase_gauge_tooltip_pressure_and_winner_lock(failures)
	_run_medical_phase_gauge_tooltip_medical_busy_receiving(failures)
	_run_medical_phase_gauge_tooltip_medical_busy_wind_up(failures)
	_run_battle_ui_gauge_label_receiving_care_during_medical_phase(failures)
	_run_battle_ui_gauge_label_medical_wind_up_primary(failures)
	_run_combat_ui_hints_cowering_gauge_tooltip(failures)
	_run_combat_ui_hints_formation_cowering_tooltip(failures)
	_run_battle_ui_gauge_label_live_counter_tempo_needs_manager(failures)
	_run_combat_ui_hints_formation_counter_tempo_needs_manager(failures)
	_run_combat_ui_hints_attention_stale_stamp_prefers_live(failures)
	_run_combat_ui_hints_attention_live_refresh_load_during_windup(failures)
	_run_strike_stamping_weapon_eff_dist_sanity(failures)
	_run_footwork_ui_hint_ignores_orphan_stamp_without_offset(failures)
	_run_footwork_diagram_label_suffix_compact(failures)
	_run_footwork_snapshot_includes_position_hint_when_enabled(failures)
	_run_footwork_snapshot_ui_hint_from_unstamped_offset(failures)
	_run_footwork_snapshot_omits_position_when_disabled(failures)
	_run_combat_snapshot_exports_attention_ui_hint_when_stamped(failures)
	_run_combat_snapshot_exports_counter_tempo_ui_hint_when_stamped(failures)
	_run_combat_snapshot_suppresses_next_override_during_counter_tempo(failures)
	_run_combat_snapshot_derives_attention_ui_hint_from_telegraph(failures)
	_run_combat_snapshot_derives_counter_tempo_ui_hint_from_open_window(failures)
	_run_battle_ui_gauge_label_counter_beats_status_override(failures)
	_run_battle_ui_gauge_label_status_override_includes_attention(failures)
	_run_battle_ui_gauge_label_counter_wind_up_prefix(failures)
	_run_combat_snapshot_omits_closing_override_during_counter_tempo(failures)
	_run_battle_ui_gauge_label_matches_snapshot_row(failures)
	_run_battle_ui_gauge_suffix_step_atk_form_order(failures)
	_run_battle_ui_gauge_label_renders_exported_hints_when_features_off(failures)
	_run_battle_ui_gauge_label_recovering_includes_exported_attention(failures)
	_run_player_counter_tempo_turn_ready_hint_when_window_open(failures)
	_run_battle_ui_gauge_bar_always_stamina_even_during_counter_tempo(failures)
	_run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures)
	_run_footwork_choose_defense_dodge_does_not_keep_parry_offset(failures)
	_run_footwork_arc_contact_applies_offset_once(failures)
	_run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(failures)
	_run_footwork_windup_arc_intended_includes_attacker_step(failures)
	_run_footwork_partial_follow_through_freezes_resolve_angles(failures)
	_run_footwork_disabled_skips_windup_stamp(failures)
