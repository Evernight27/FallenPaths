class_name CombatFormationMoveDuration
extends RefCounted

## Estimated seconds for formation pair / solo moves (matches **`CombatFormationFlow`** resolve timing).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _Timing := preload("res://combat/CombatTiming.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")


## Formation **`fid`** for lane/pressure timing (tactical grid / zone geometry).
static func _zone_fid_for_lane_timing(manager: Node, c: Dictionary) -> String:
	if manager == null:
		return _EntityAccess.formation_id_str(c)
	return _ZoneOfControl.zone_geometry_fid_str(manager, c)


static func _agi_scale_s(initiator: Dictionary) -> float:
	var agi: float = float(_EntityAccess.stats_dict(initiator).get("agility", 100))
	return CombatConstants.BASE_FALL_BACK_S * (100.0 / maxf(50.0, agi))


static func _armor_mult(initiator: Dictionary, partner: Dictionary = {}) -> float:
	var a0: float = _Timing.armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(initiator))
	if partner.is_empty():
		return a0
	var a1: float = _Timing.armor_mass_duration_multiplier_for_node(_EntityAccess.scene_node(partner))
	return maxf(a0, a1)


static func estimate_adjacent_rank_pair_duration_s(
	manager: Node, initiator: Dictionary, partner: Dictionary, move_kind: String
) -> float:
	if manager == null or initiator.is_empty() or partner.is_empty():
		return CombatConstants.BASE_FALL_BACK_S
	var fid: String = _zone_fid_for_lane_timing(manager, initiator)
	var f0: int = _EntityAccess.file_int(initiator)
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	var kind_mult: float = (
		CombatConstants.DRAG_BACK_DURATION_MULT if move_kind == "drag_back" else 1.0
	)
	return (
		_agi_scale_s(initiator) * lane_foot * pressure_mod * kind_mult * _armor_mult(initiator, partner)
	)


static func estimate_solo_fall_back_duration_s(manager: Node, initiator: Dictionary) -> float:
	if manager == null or initiator.is_empty():
		return CombatConstants.BASE_FALL_BACK_S
	var fid: String = _zone_fid_for_lane_timing(manager, initiator)
	var f: int = _EntityAccess.file_int(initiator)
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	return _agi_scale_s(initiator) * lane_foot * pressure_mod * _armor_mult(initiator)


static func estimate_rotate_file_duration_s(
	manager: Node, initiator: Dictionary, partner: Dictionary
) -> float:
	if manager == null or initiator.is_empty() or partner.is_empty():
		return CombatConstants.BASE_FALL_BACK_S
	var fid: String = _zone_fid_for_lane_timing(manager, initiator)
	var f0: int = _EntityAccess.file_int(initiator)
	var lane_foot: float = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
	var pressure_mod: float = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	return _agi_scale_s(initiator) * lane_foot * pressure_mod * _armor_mult(initiator, partner)


static func format_duration_hint(
	duration_s: float, lane_foot: float, pressure_mod: float, armor_mult: float = 1.0
) -> String:
	var baseline: float = CombatConstants.BASE_FALL_BACK_S
	if (
		duration_s <= baseline * 1.05
		and lane_foot <= CombatConstants.LANE_MOD_CLEAR + 0.02
		and absf(pressure_mod - CombatConstants.PRESSURE_MOD_NEUTRAL) < 0.02
		and armor_mult <= 1.02
	):
		return ""
	var parts: PackedStringArray = PackedStringArray(["~%.1fs" % duration_s])
	if lane_foot >= CombatConstants.LANE_MOD_BLOCKED - 0.05:
		parts.append("blocked lane")
	elif lane_foot >= CombatConstants.LANE_MOD_CROWDED - 0.05:
		parts.append("crowded lane")
	if pressure_mod >= CombatConstants.PRESSURE_MOD_AGGRESSIVE - 0.05:
		parts.append("under pressure")
	elif pressure_mod <= CombatConstants.PRESSURE_MOD_DEFENSIVE + 0.05:
		parts.append("low pressure")
	if armor_mult >= 1.12:
		parts.append("heavy armor")
	return "Formation move: " + ", ".join(parts)


static func preview_lane_pressure_for_combatant(manager: Node, c: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"lane_foot": CombatConstants.LANE_MOD_CLEAR,
		"pressure_mod": CombatConstants.PRESSURE_MOD_NEUTRAL,
		"duration_s": CombatConstants.BASE_FALL_BACK_S,
	}
	if manager == null or c.is_empty():
		return out
	var fid: String = _zone_fid_for_lane_timing(manager, c)
	if fid.is_empty():
		return out
	var f: int = _EntityAccess.file_int(c)
	out["lane_foot"] = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f)
	out["pressure_mod"] = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	out["armor_mult"] = _armor_mult(c)
	out["duration_s"] = estimate_solo_fall_back_duration_s(manager, c)
	return out


static func formation_preview_tooltip_line(manager: Node, c: Dictionary) -> String:
	var pv: Dictionary = preview_lane_pressure_for_combatant(manager, c)
	return format_duration_hint(
		float(pv.get("duration_s", CombatConstants.BASE_FALL_BACK_S)),
		float(pv.get("lane_foot", CombatConstants.LANE_MOD_CLEAR)),
		float(pv.get("pressure_mod", CombatConstants.PRESSURE_MOD_NEUTRAL)),
		float(pv.get("armor_mult", 1.0))
	)


static func stamp_listed_action_duration_hint(
	manager: Node, initiator: Dictionary, action: Dictionary
) -> void:
	if manager == null or initiator.is_empty() or action.is_empty():
		return
	var mid: String = str(action.get("move_id", ""))
	if mid not in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
		return
	var tid: int = int(action.get("target_id", -1))
	var self_id: int = _EntityAccess.id_int(initiator)
	var partner: Dictionary = {}
	if tid >= 0 and tid != self_id:
		partner = _EntityAccess.manager_get_combatant(manager, tid)
	var dur: float = CombatConstants.BASE_FALL_BACK_S
	var lane_foot: float = CombatConstants.LANE_MOD_CLEAR
	var pressure_mod: float = CombatConstants.PRESSURE_MOD_NEUTRAL
	var fid: String = _zone_fid_for_lane_timing(manager, initiator)
	var f0: int = _EntityAccess.file_int(initiator)
	if not fid.is_empty():
		lane_foot = _ZoneOfControl.get_lane_and_footing_duration_multiplier(manager, fid, f0)
		pressure_mod = _ZoneOfControl.get_opponent_pressure_duration_multiplier(manager, fid)
	match mid:
		CombatConstants.MOVE_ID_FALL_BACK:
			if tid == self_id or partner.is_empty():
				dur = estimate_solo_fall_back_duration_s(manager, initiator)
			else:
				dur = estimate_adjacent_rank_pair_duration_s(
					manager, initiator, partner, "fall_back_pair"
				)
		CombatConstants.MOVE_ID_DRAG_BACK:
			dur = estimate_adjacent_rank_pair_duration_s(manager, initiator, partner, "drag_back")
		CombatConstants.MOVE_ID_SWAP_RANK:
			dur = estimate_adjacent_rank_pair_duration_s(manager, initiator, partner, "swap_rank")
		CombatConstants.MOVE_ID_ROTATE_FILE:
			dur = estimate_rotate_file_duration_s(manager, initiator, partner)
		CombatConstants.MOVE_ID_FLEE:
			# Resolve is instant (`CombatFormationFlee.apply_flee`); listing hint only.
			action["formation_move_duration_hint"] = "Flee: leaves field (instant)"
			return
	var armor_mult: float = _armor_mult(initiator, partner)
	var hint: String = format_duration_hint(dur, lane_foot, pressure_mod, armor_mult)
	if not hint.is_empty():
		action["formation_move_duration_hint"] = hint


static func _formation_action_display_label(move_id: String) -> String:
	var labels: Dictionary = _BattleUIConstants.FORMATION_ACTION_LABELS
	if labels.has(move_id):
		return str(labels[move_id])
	return move_id.replace("_", " ")


## Human-readable formation menu line for player turn-ready (Phase 2 **II-5a**).
static func formation_listed_moves_menu_line(actions: Array) -> String:
	var parts: PackedStringArray = []
	for a in actions:
		if a is not Dictionary:
			continue
		var mid: String = str(a.get("move_id", ""))
		if (
			mid not in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS
			and mid != CombatConstants.MOVE_ID_ATTEMPT_CLOSE
		):
			continue
		var label: String = _formation_action_display_label(mid)
		var tid: int = int(a.get("target_id", -1))
		if tid >= 0 and mid != CombatConstants.MOVE_ID_FLEE:
			label = "%s → ally %d" % [label, tid]
		parts.append(label)
	if parts.is_empty():
		return ""
	return "Formation actions: " + ", ".join(parts)


## One combat-log line for player turn-ready when listed formation moves carry duration hints.
static func formation_listed_moves_turn_hint(actions: Array) -> String:
	var parts: PackedStringArray = []
	for a in actions:
		if a is not Dictionary:
			continue
		var mid: String = str(a.get("move_id", ""))
		if mid not in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
			continue
		var hint: String = str(a.get("formation_move_duration_hint", "")).strip_edges()
		if hint.is_empty():
			continue
		var tid: int = int(a.get("target_id", -1))
		var label: String = _formation_action_display_label(mid)
		if tid >= 0:
			label = "%s (ally %d)" % [label, tid]
		parts.append("%s — %s" % [label, hint])
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	return "Listed formation moves: " + "; ".join(parts)


## One **`FP_COMBAT: ui_hint`** line per turn: duration detail when stamped, else compact menu summary.
static func formation_turn_ready_ui_hint(actions: Array) -> String:
	var detail: String = formation_listed_moves_turn_hint(actions)
	if not detail.is_empty():
		return detail
	return formation_listed_moves_menu_line(actions)
