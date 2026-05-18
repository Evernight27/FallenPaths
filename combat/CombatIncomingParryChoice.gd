class_name CombatIncomingParryChoice
extends RefCounted

## Tier 0: overlapping melee wind-ups on one defender — run **`can_parry_all`** first (split capacity via
## **`choose_defense`**); if false, commit passive parry to highest threat only (see **`TACTICAL_FORMATIONS_FF4`**).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")


static func incoming_attacker_ids_on_defender(
	manager: Node, defender_id: int, anchor_time: float = -1.0
) -> Array:
	var out: Array = []
	if manager == null or defender_id < 0:
		return out
	var now: float = (
		anchor_time if anchor_time >= 0.0 else _EntityAccess.combat_clock_float(manager)
	)
	var window: float = CombatConstants.INCOMING_MELEE_PARRY_WINDOW_S
	for c in manager.combatants:
		if c == null or typeof(c) != TYPE_DICTIONARY:
			continue
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WIND_UP:
			continue
		var aid: int = _EntityAccess.id_int(c)
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		if int(pa.get("target_id", -1)) != defender_id:
			continue
		var resolve_at: float = _EventScheduler.get_pending_melee_attack_resolve_at(manager, aid)
		if resolve_at < 0.0:
			continue
		if absf(resolve_at - now) <= window:
			out.append(aid)
	return out


static func threat_score_for_attacker(manager: Node, attacker_id: int) -> float:
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return 0.0
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	var intensity: float = clampf(float(pa.get("intensity", 0.5)), 0.0, 1.0)
	var str_val: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
	return intensity * (0.5 + str_val / 200.0)


static func choose_parry_target_attacker_id(
	manager: Node, defender_id: int, anchor_time: float = -1.0
) -> int:
	var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor_time)
	if incoming.is_empty():
		return -1
	if incoming.size() == 1:
		return int(incoming[0])
	var best_id: int = -1
	var best_score: float = -1.0
	for raw in incoming:
		var aid: int = int(raw)
		var score: float = threat_score_for_attacker(manager, aid)
		if score > best_score:
			best_score = score
			best_id = aid
	return best_id


## True when defender can parry every overlapping wind-up in the window (split surround capacity + reaction time).
static func can_parry_all(manager: Node, defender_id: int, anchor_time: float = -1.0) -> bool:
	if manager == null or defender_id < 0 or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
		return false
	var anchor: float = anchor_time
	if anchor < 0.0:
		anchor = _EntityAccess.combat_clock_float(manager)
	var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
	if incoming.size() <= 1:
		return true
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if tgt.is_empty() or not _EntityAccess.has_weapon(tgt):
		return false
	if not _EntityAccess.has_passive_parry_reaction_time(tgt):
		return false
	var threat_n: int = incoming.size()
	var total_p_a: float = 0.0
	var min_c_d: float = 1.0e12
	for raw in incoming:
		var aid: int = int(raw)
		var est: Dictionary = _incoming_parry_estimate(manager, tgt, aid, threat_n)
		if not bool(est.get("viable", false)):
			return false
		total_p_a += float(est.get("parry_p_a", 0.0))
		min_c_d = minf(min_c_d, float(est.get("parry_c_d", 0.0)))
	if min_c_d >= 1.0e11:
		return false
	var budget: float = min_c_d * CombatConstants.INCOMING_PARRY_ALL_COMBINED_P_A_BUDGET_MULT
	return total_p_a <= budget + 0.001


static func _incoming_parry_estimate(
	manager: Node, tgt: Dictionary, attacker_id: int, threat_count: int
) -> Dictionary:
	var out: Dictionary = {"viable": false, "parry_p_a": 0.0, "parry_c_d": 0.0}
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return out
	var pa_src: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	if pa_src.is_empty():
		return out
	var attack_type: String = str(pa_src.get("attack_type", "")).strip_edges()
	if attack_type.is_empty():
		return out
	var pa: Dictionary = pa_src.duplicate()
	pa["surround_threat_count"] = threat_count
	var def_n: Node = _EntityAccess.scene_node(tgt)
	var targetable: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
	if targetable.is_empty():
		return out
	var atk_w: Variant = _EntityAccess.get_weapon(atk)
	var archetype: Dictionary = {}
	if atk_w != null:
		var move_def: Dictionary = _WeaponConstants.get_move(attack_type)
		archetype = _WeaponConstants.get_archetype(
			str(move_def.get("archetype_id", _WeaponConstants.ARCHETYPE_OVERHEAD))
		)
	var dc: Dictionary = _DefenseChoice.choose_defense(
		pa, atk, tgt, targetable, attack_type, archetype, -1.0
	)
	var p_a: float = float(dc.get("parry_p_a", 0.0))
	var c_d: float = float(dc.get("parry_c_d", 0.0))
	out["parry_p_a"] = p_a
	out["parry_c_d"] = c_d
	if not bool(dc.get("can_parry_in_time", false)):
		return out
	if p_a <= c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO:
		out["viable"] = true
	return out


static func _parry_viable_for_incoming_attack(
	manager: Node, tgt: Dictionary, attacker_id: int, threat_count: int
) -> bool:
	return bool(_incoming_parry_estimate(manager, tgt, attacker_id, threat_count).get("viable", false))


## Stamps **`pa`** when this resolve is not the committed parry target among overlapping wind-ups.
static func stamp_parry_choice_on_pa(
	manager: Node,
	pa: Dictionary,
	defender_id: int,
	attacker_id: int,
	anchor_time: float = -1.0
) -> void:
	if manager == null or pa.is_empty() or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
		return
	var anchor: float = anchor_time
	if anchor < 0.0:
		anchor = _EventScheduler.get_pending_melee_attack_resolve_at(manager, attacker_id)
	if anchor < 0.0:
		anchor = _EntityAccess.combat_clock_float(manager)
	var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
	if incoming.size() <= 1:
		return
	if can_parry_all(manager, defender_id, anchor):
		pa["parry_all_incoming_batch"] = true
		return
	var chosen: int = choose_parry_target_attacker_id(manager, defender_id, anchor)
	if chosen < 0:
		return
	pa["parry_commitment_attacker_id"] = chosen
	if attacker_id != chosen:
		pa["parry_choice_blocked"] = true


## True when **`choose_defense`** should skip parry capacity for this resolve (non-chosen overlapping wind-up).
static func parry_choice_blocked_for_resolve(
	manager: Node, defender_id: int, attacker_id: int, anchor_time: float = -1.0
) -> bool:
	if manager == null or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
		return false
	var anchor: float = anchor_time
	if anchor < 0.0:
		anchor = _EventScheduler.get_pending_melee_attack_resolve_at(manager, attacker_id)
	if anchor < 0.0:
		anchor = _EntityAccess.combat_clock_float(manager)
	var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
	if incoming.size() <= 1:
		return false
	if can_parry_all(manager, defender_id, anchor):
		return false
	return attacker_id != choose_parry_target_attacker_id(manager, defender_id, anchor)
