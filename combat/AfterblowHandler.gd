class_name AfterblowHandler
extends RefCounted

## Dedicated afterblow handler. Physically realistic: target can complete a previously planned
## attack iff the blow wasn't intense enough to hinder that action.
## Footing: **`CombatFootwork.clear_on_exchange_end`** on afterblow resolve path. LIVE_PATHS **`#wf-tier-44-pa`** (clear).
## Choices: Hybrid hindrance, stance (supporting_leg), full resolution, damage *= (1-hindrance), B→A+B→C.

const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _BodyPartQuery := preload("res://core/BodyPartQuery.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

# Part relevance for hindrance (attacking arm from pending; supporting leg from stance)
static func _get_part_relevance(hit_part: String, attacking_arm: String, supporting_leg: String) -> float:
	if hit_part == attacking_arm:
		return 1.0
	if hit_part == "head":
		return 0.8
	if hit_part == "chest":
		return 0.6
	if hit_part == supporting_leg:
		return 0.55
	if hit_part == "left_leg" or hit_part == "right_leg":
		return 0.3
	if hit_part == "left_arm" or hit_part == "right_arm":
		return 0.2
	return 0.5

static func _get_supporting_leg(entity: Node) -> String:
	if entity == null:
		return "right_leg"
	var dom: String = entity.get("dominant_hand") if "dominant_hand" in entity else "right_arm"
	return "right_leg" if dom == "right_arm" else "left_leg"

## Returns true if afterblow was triggered (B's attack resolved). False if hindered, cancelled, or no pending attack.
static func try_afterblow(manager: Node, _attacker_id: int, target_id: int, result_dict: Dictionary, intensity: float) -> bool:
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty():
		return false
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(tgt, "pending_attack")
	if _MedicalPhase.combat_resolution_blocked(manager):
		if not pa.is_empty() or _EntityAccess.state_str(tgt) == CombatConstants.STATE_WIND_UP:
			_CounterTempo.abort_attacker_wind_up(manager, target_id)
			_Footwork.return_to_waiting(tgt)
			tgt.gauge = 0.0
		return false
	if pa.is_empty():
		return false
	if _EntityAccess.state_str(tgt) != CombatConstants.STATE_WIND_UP:
		return false
	var hit_part: String = result_dict.get("part", "")
	var outcome: String = result_dict.get("outcome", "hit")
	var final_cut: float = float(result_dict.get("final_cut", 0.0))
	var final_blunt: float = float(result_dict.get("final_blunt", 0.0))
	var final_bone: float = float(result_dict.get("final_bone", 0.0))
	var total_dmg: float = final_cut + final_blunt + final_bone

	# Immediate disqualifiers
	var tgt_n: Node = _EntityAccess.scene_node(tgt)
	var attacking_arm: String = _EntityAccess.get_attacking_arm(tgt)
	if attacking_arm.is_empty():
		_abort_afterblow_wind_up_no_arm(manager, target_id, tgt)
		return false
	var arm_inoperable: bool = _BodyPartQuery.is_arm_destroyed(tgt_n, attacking_arm) if tgt_n != null else true
	if hit_part == attacking_arm and arm_inoperable:
		_abort_afterblow_wind_up_no_arm(manager, target_id, tgt)
		return false
	if hit_part == "head" and _EntityAccess.is_incapacitated(tgt):
		_cancel_pending(manager, tgt)
		return false

	# Hindrance score (hybrid model)
	if outcome == "deflected":
		# Not hindered — allow
		return _execute_afterblow(manager, tgt, 0.0)
	var part_relevance: float = _get_part_relevance(hit_part, attacking_arm, _get_supporting_leg(tgt_n))
	var severity: float = clampf(total_dmg / CombatConstants.AFTERBLOW_DAMAGE_HINDER_THRESHOLD, 0.0, 1.5)
	var outcome_mult: float = 0.6 if outcome == "glancing" or outcome == "negligible" else 1.0
	var hindrance: float = clampf(part_relevance * severity * intensity * outcome_mult, 0.0, 1.0)

	if hindrance >= CombatConstants.AFTERBLOW_HINDRANCE_BLOCK:
		_cancel_pending(manager, tgt)
		return false
	if hindrance <= CombatConstants.AFTERBLOW_HINDRANCE_ALLOW:
		return _execute_afterblow(manager, tgt, hindrance)
	if randf() < hindrance:
		_cancel_pending(manager, tgt)
		return false
	return _execute_afterblow(manager, tgt, hindrance)

static func _abort_afterblow_wind_up_no_arm(manager: Node, target_id: int, tgt: Dictionary) -> void:
	if manager == null or tgt.is_empty() or target_id < 0:
		return
	_CounterTempo.abort_attacker_wind_up(manager, target_id)
	_MobilityRetreat.react_attacking_arm_lost_if_needed(manager, tgt)


static func _cancel_pending(manager: Node, tgt: Dictionary) -> void:
	_Footwork.clear_on_exchange_end(tgt)
	tgt.pending_attack = {}
	tgt.state = CombatConstants.STATE_RECOVERING
	tgt.state_timer = 0.0
	tgt.state_duration = CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S
	var tid: int = _EntityAccess.id_int(tgt)
	if tid >= 0:
		_EntityAccess.manager_schedule_event(
			manager,
			{
				"type": CombatConstants.EVENT_RECOVERY_END,
				"combatant_id": tid,
				"resolve_at": _EntityAccess.combat_clock_float(manager) + CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S,
				"data": {},
			}
		)
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log("afterblow %s hindered swing_cancelled" % _EntityAccess.get_display_name(tgt))

static func _execute_afterblow(manager: Node, tgt: Dictionary, hindrance: float) -> bool:
	var pa: Dictionary = _EntityAccess.nested_dictionary_for_mutation(tgt, "pending_attack")
	var damage_mult: float = 1.0 - hindrance
	pa["afterblow_damage_mult"] = maxf(0.2, damage_mult)
	# Headless regression only: `CombatRegressionHarness` sets **`_harness_record_afterblow_damage_mult`** on the manager.
	if manager != null and manager.has_meta("_harness_record_afterblow_damage_mult"):
		manager.set_meta("_harness_last_afterblow_damage_mult", float(pa["afterblow_damage_mult"]))
	var tgt_id: int = _EntityAccess.id_int(tgt)
	if CombatDebug.flow_verbose_enabled():
		var tgt_name: String = _EntityAccess.get_display_name(tgt, tgt_id)
		CombatDebug.flow_log("afterblow %s completes hindrance=%.2f dmg_mult=%.2f" % [tgt_name, hindrance, pa["afterblow_damage_mult"]])
	manager._execute_attack(tgt_id)
	return true
