class_name CombatRegressionHarnessAttentionFootworkTail
extends RefCounted

## Tier 4.2–4.4 attention / mental stack / footwork / battle UI hint tests (compile split).

const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _CombatSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")

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
	var ally_id: int = _EntityAccess.id_int(ally)
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
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var actions: Array = [
		{"move_id": "oberhau", "target_id": _EntityAccess.id_int(mgr.combatants[2])},
		{
			"move_id": "apply_direct_pressure",
			"target_id": ally_id,
			"target_part": "chest",
		},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_medical: expected stack pick")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	if not mgr._is_medical_move(str(picked.get("move_id", ""))):
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_medical: want medical move got %s" % str(picked.get("move_id", ""))
		)
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
static func _run_mental_stack_attack_layer_matches_legacy_weights(failures: PackedStringArray) -> void:
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
		CombatRegressionHarness._fail(failures, "mental_stack_legacy: try_pick should be empty without salience")
	var w: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(false)
	var stacked_off: Dictionary = _MentalStack.try_pick(actions, p_id, mgr)
	var w_off: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(true)
	if not stacked_off.is_empty():
		CombatRegressionHarness._fail(failures, "mental_stack_legacy: try_pick off should stay empty")
	if absf(w - w_off) > 0.0001 * maxf(1.0, absf(w)):
		CombatRegressionHarness._fail(failures, "mental_stack_legacy: weight changed %.6f vs %.6f" % [w, w_off])
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
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
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
	if str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != "medical":
		CombatRegressionHarness._fail(
			failures,
			"mental_stack_layer: want medical got %s"
			% str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


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
	var def: Dictionary = {
		CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER: "incoming",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
	}
	var hint: String = _Attention.format_attention_ui_hint(def)
	CombatConstants.set_feature_combat_attention_load(false)
	if not hint.contains("Stack incoming"):
		CombatRegressionHarness._fail(failures, "attention_ui_stack: want Stack incoming in '%s'" % hint)


## Tier 4.3.7: yomi **`parry_deflect`** count boosts feint listing mult.
static func _run_footwork_attack_step_offset_stamped_on_windup(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(off - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
		CombatRegressionHarness._fail(failures, "footwork_windup: want left-line offset got %.2f" % off)


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
	if is_equal_approx(bar_no_mgr, 55.0):
		CombatRegressionHarness._fail(failures, "gauge_bar_live: without manager should use stamina not gauge")
	if not is_equal_approx(bar_with_mgr, 55.0):
		CombatRegressionHarness._fail(
			failures,
			"gauge_bar_live: with manager want gauge=55 got %.2f" % bar_with_mgr
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


## Tier 4.2 UI: counter-tempo row maps gauge bar to readiness **`gauge`** (not stamina).
static func _run_battle_ui_gauge_bar_uses_gauge_float_during_counter_tempo(
	failures: PackedStringArray
) -> void:
	var row_counter: Dictionary = {
		"alive": true,
		"counter_tempo_ui_hint": "counter_ready",
		"gauge": 72.0,
		"stamina": 40.0,
	}
	if absf(_BattleUIUpdater.gauge_bar_value_for_combatant(row_counter) - 72.0) > 0.01:
		CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: counter row should use gauge=72")
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
	_run_mental_stack_attack_layer_matches_legacy_weights(failures)
	_run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures)
	_run_yomi_updates_on_parry_deflect_clears_on_hit(failures)
	_run_attention_ui_hint_formats_when_telegraph_set(failures)
	_run_attention_refresh_waiting_tick_stamps_ui_hint(failures)
	_run_yomi_focus_drift_sets_habitual_part_on_ai(failures)
	_run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(failures)
	_run_guard_from_move_syncs_focus_part_with_guard_line(failures)
	_run_mental_stack_stamps_layer_on_medical_pick(failures)
	_run_focus_line_actions_listed_when_attention_enabled(failures)
	_run_focus_line_resolve_sets_guard_and_focus(failures)
	_run_focus_line_party_leader_prefers_telegraph_match(failures)
	_run_yomi_parry_deflect_boosts_feint_listing_mult(failures)
	_run_yomi_defense_readiness_mult_boosts_after_parry_deflect(failures)
	_run_attention_ui_hint_includes_mental_stack_layer(failures)
	_run_footwork_attack_step_offset_stamped_on_windup(failures)
	_run_footwork_offset_shifts_attack_angle_deg(failures)
	_run_footwork_offset_scrubbed_on_combat_start(failures)
	_run_footwork_defender_parry_step_stamps_offset(failures)
	_run_footwork_defender_offset_shifts_guard_angle_deg(failures)
	_run_footwork_defender_dodge_step_stamps_offset(failures)
	_run_footwork_defender_offset_scrubbed_after_exchange(failures)
	_run_footwork_ui_hint_formats_offset(failures)
	_run_footwork_ui_hint_clears_on_clear_position_offset(failures)
	_run_footwork_abort_attacker_wind_up_clears_offset(failures)
	_run_footwork_waiting_hides_stale_step_ui(failures)
	_run_footwork_back_rank_abort_clears_depth_windup(failures)
	_run_footwork_ui_hint_clears_on_combat_start(failures)
	_run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures)
	_run_combat_ui_hints_footwork_stale_stamp_prefers_live_offset(failures)
	_run_combat_ui_hints_gauge_tooltip_counter_ready(failures)
	_run_battle_ui_gauge_tooltip_live_counter_tempo_needs_manager(failures)
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
	_run_battle_ui_gauge_label_renders_exported_hints_when_features_off(failures)
	_run_battle_ui_gauge_label_recovering_includes_exported_attention(failures)
	_run_player_counter_tempo_turn_ready_hint_when_window_open(failures)
	_run_battle_ui_gauge_bar_uses_gauge_float_during_counter_tempo(failures)
	_run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures)
	_run_footwork_choose_defense_dodge_does_not_keep_parry_offset(failures)
	_run_footwork_arc_contact_applies_offset_once(failures)
	_run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(failures)
	_run_footwork_windup_arc_intended_includes_attacker_step(failures)
	_run_footwork_partial_follow_through_freezes_resolve_angles(failures)
	_run_footwork_disabled_skips_windup_stamp(failures)
