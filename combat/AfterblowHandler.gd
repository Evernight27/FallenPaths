class_name AfterblowHandler
extends RefCounted

## Dedicated afterblow handler. Physically realistic: target can complete a previously planned
## attack iff the blow wasn't intense enough to hinder that action.
## Choices: Hybrid hindrance, stance (supporting_leg), full resolution, damage *= (1-hindrance), B→A+B→C.

const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _BodyPartQuery := preload("res://core/BodyPartQuery.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

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
	var tgt = manager._get_by_id(target_id) if manager.has_method("_get_by_id") else null
	if tgt == null:
		return false
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(tgt, "pending_attack")
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
		return false
	var arm_inoperable: bool = _BodyPartQuery.is_arm_destroyed(tgt_n, attacking_arm) if tgt_n != null else true
	if hit_part == attacking_arm and arm_inoperable:
		_cancel_pending(manager, tgt)
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

static func _cancel_pending(_manager: Node, tgt: Dictionary) -> void:
	tgt.pending_attack = {}
	tgt.state = CombatConstants.STATE_RECOVERING
	tgt.state_timer = 0.0
	tgt.state_duration = CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S
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
