class_name CombatFormationMoveDuration
extends RefCounted

## Estimated seconds for formation pair / solo moves (matches **`CombatFormationFlow`** resolve timing).
## Formation lane footing: **`ZoneOfControl.get_lane_and_footing_duration_multiplier`** — step-over bodies in file column; **not** blade **`guard_line`** / PA. LIVE_PATHS **`#wf-footing-terminology`**.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _Timing := preload("res://combat/CombatTiming.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")

## P4b canonical UI copy (Tier 0.1) — locked by **`_run_p4b_formation_duration_ui_copy_suite`**.
const P4B_HINT_PREFIX := "Formation move:"
const P4B_TOKEN_CROWDED_LANE := "crowded lane"
const P4B_TOKEN_BLOCKED_LANE := "blocked lane"
const P4B_TOKEN_UNDER_PRESSURE := "under pressure"
const P4B_TOKEN_LOW_PRESSURE := "low pressure"
const P4B_TOKEN_CONTROLLING_FRONT := "controlling front"
const P4B_TOKEN_HEAVY_ARMOR := "heavy armor"
const P4B_FLEE_INSTANT_HINT := "Flee: leaves field (instant)"
const P4B_LEADER_HOLD_LANE_INSTANT_HINT := "Hold lane: doctrine (instant)"
const P4B_LEADER_PROBING_INSTANT_HINT := "Probe: doctrine (instant)"
const P4B_LEADER_PINCH_CENTER_INSTANT_HINT := "Pinch center: doctrine (instant)"
const P4B_FORMATION_ACTIONS_MENU_PREFIX := "Formation actions: "
const P4B_LISTED_MOVES_PREFIX := "Listed formation moves: "


## P4b: doc-sync line for formation duration UI vocabulary (ii5a / harness).
static func p4b_formation_duration_ui_copy_line() -> String:
	return (
		"P4b formation UI: prefix='%s' tokens=%s|%s|%s|%s|%s|%s flee='%s'"
		% [
			P4B_HINT_PREFIX,
			P4B_TOKEN_CROWDED_LANE,
			P4B_TOKEN_BLOCKED_LANE,
			P4B_TOKEN_UNDER_PRESSURE,
			P4B_TOKEN_LOW_PRESSURE,
			P4B_TOKEN_CONTROLLING_FRONT,
			P4B_TOKEN_HEAVY_ARMOR,
			P4B_FLEE_INSTANT_HINT,
		]
	)


static func duration_hint_for_turn_display(hint: String) -> String:
	var h: String = str(hint).strip_edges()
	var prefix: String = P4B_HINT_PREFIX + " "
	if h.begins_with(prefix):
		return h.substr(prefix.length())
	return h


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
		CombatConstants.DRAG_BACK_DURATION_MULT
		if move_kind == CombatConstants.FORMATION_MOVE_KIND_DRAG_BACK
		else 1.0
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
	duration_s: float,
	lane_foot: float,
	pressure_mod: float,
	armor_mult: float = 1.0,
	controlling_front: bool = false
) -> String:
	var baseline: float = CombatConstants.BASE_FALL_BACK_S
	if (
		duration_s <= baseline * 1.05
		and lane_foot <= CombatConstants.LANE_MOD_CLEAR + 0.02
		and absf(pressure_mod - CombatConstants.PRESSURE_MOD_NEUTRAL) < 0.02
		and armor_mult <= 1.02
		and not controlling_front
	):
		return ""
	var parts: PackedStringArray = PackedStringArray(["~%.1fs" % duration_s])
	if lane_foot >= CombatConstants.LANE_MOD_BLOCKED - 0.05:
		parts.append(P4B_TOKEN_BLOCKED_LANE)
	elif lane_foot >= CombatConstants.LANE_MOD_CROWDED - 0.05:
		parts.append(P4B_TOKEN_CROWDED_LANE)
	if pressure_mod >= CombatConstants.PRESSURE_MOD_AGGRESSIVE - 0.05:
		parts.append(P4B_TOKEN_UNDER_PRESSURE)
	elif pressure_mod <= CombatConstants.PRESSURE_MOD_DEFENSIVE + 0.05:
		parts.append(P4B_TOKEN_LOW_PRESSURE)
	if controlling_front:
		parts.append(P4B_TOKEN_CONTROLLING_FRONT)
	if armor_mult >= 1.12:
		parts.append(P4B_TOKEN_HEAVY_ARMOR)
	return P4B_HINT_PREFIX + " " + ", ".join(parts)


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
	out["controlling_front"] = (
		_ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(manager, fid) > 1.01
	)
	out["armor_mult"] = _armor_mult(c)
	out["duration_s"] = estimate_solo_fall_back_duration_s(manager, c)
	return out


static func formation_preview_tooltip_line(manager: Node, c: Dictionary) -> String:
	var pv: Dictionary = preview_lane_pressure_for_combatant(manager, c)
	return format_duration_hint(
		float(pv.get("duration_s", CombatConstants.BASE_FALL_BACK_S)),
		float(pv.get("lane_foot", CombatConstants.LANE_MOD_CLEAR)),
		float(pv.get("pressure_mod", CombatConstants.PRESSURE_MOD_NEUTRAL)),
		float(pv.get("armor_mult", 1.0)),
		bool(pv.get("controlling_front", false))
	)


static func stamp_listed_action_duration_hint(
	manager: Node, initiator: Dictionary, action: Dictionary
) -> void:
	if manager == null or initiator.is_empty() or action.is_empty():
		return
	var mid: String = str(action.get("move_id", ""))
	if CombatConstants.is_leader_formation_command_move(mid):
		if mid == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
			action["formation_move_duration_hint"] = P4B_LEADER_HOLD_LANE_INSTANT_HINT
		elif mid == CombatConstants.MOVE_ID_ORDER_PROBING:
			action["formation_move_duration_hint"] = P4B_LEADER_PROBING_INSTANT_HINT
		elif mid == CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
			action["formation_move_duration_hint"] = P4B_LEADER_PINCH_CENTER_INSTANT_HINT
		return
	if not CombatConstants.is_formation_movement_move(mid):
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
					manager,
					initiator,
					partner,
					CombatConstants.formation_pair_move_kind_for_menu_move(mid)
				)
		CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_SWAP_RANK:
			dur = estimate_adjacent_rank_pair_duration_s(
				manager,
				initiator,
				partner,
				CombatConstants.formation_pair_move_kind_for_menu_move(mid)
			)
		CombatConstants.MOVE_ID_ROTATE_FILE:
			dur = estimate_rotate_file_duration_s(manager, initiator, partner)
		CombatConstants.MOVE_ID_FLEE:
			# Resolve is instant (`CombatFormationFlee.apply_flee`); listing hint only.
			action["formation_move_duration_hint"] = P4B_FLEE_INSTANT_HINT
			return
	var armor_mult: float = _armor_mult(initiator, partner)
	var controlling_front: bool = false
	if not fid.is_empty():
		controlling_front = (
			_ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(manager, fid) > 1.01
		)
	var hint: String = format_duration_hint(
		dur, lane_foot, pressure_mod, armor_mult, controlling_front
	)
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
			not CombatConstants.is_formation_movement_move(mid)
			and mid != CombatConstants.MOVE_ID_ATTEMPT_CLOSE
			and not CombatConstants.is_leader_formation_command_move(mid)
		):
			continue
		var label: String = _formation_action_display_label(mid)
		var tid: int = int(a.get("target_id", -1))
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			var close_tag: String = str(
				a.get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")
			).strip_edges()
			if not close_tag.is_empty():
				label = "%s vs %s" % [label, close_tag]
			elif tid >= 0:
				label = "%s → target %d" % [label, tid]
		elif (
			tid >= 0
			and mid != CombatConstants.MOVE_ID_FLEE
			and not CombatConstants.is_leader_formation_command_move(mid)
		):
			label = "%s → ally %d" % [label, tid]
		parts.append(label)
	if parts.is_empty():
		return ""
	return P4B_FORMATION_ACTIONS_MENU_PREFIX + ", ".join(parts)


## One combat-log line for player turn-ready when listed formation moves carry duration hints.
static func formation_listed_moves_turn_hint(actions: Array) -> String:
	var parts: PackedStringArray = []
	for a in actions:
		if a is not Dictionary:
			continue
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			var close_tag: String = str(
				a.get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "")
			).strip_edges()
			if not close_tag.is_empty():
				var close_label: String = _formation_action_display_label(mid)
				parts.append("%s — harder vs %s" % [close_label, close_tag])
			continue
		if CombatConstants.is_leader_formation_command_move(mid):
			var leader_hint: String = str(a.get("formation_move_duration_hint", "")).strip_edges()
			if not leader_hint.is_empty():
				parts.append(leader_hint)
			continue
		if not CombatConstants.is_formation_movement_move(mid):
			continue
		var hint: String = str(a.get("formation_move_duration_hint", "")).strip_edges()
		if hint.is_empty():
			continue
		var tid: int = int(a.get("target_id", -1))
		var label: String = _formation_action_display_label(mid)
		if tid >= 0:
			label = "%s (ally %d)" % [label, tid]
		parts.append("%s — %s" % [label, duration_hint_for_turn_display(hint)])
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	return P4B_LISTED_MOVES_PREFIX + "; ".join(parts)


## One **`FP_COMBAT: ui_hint`** line per turn: duration detail when stamped, else compact menu summary.
static func formation_turn_ready_ui_hint(actions: Array) -> String:
	var detail: String = formation_listed_moves_turn_hint(actions)
	if not detail.is_empty():
		return detail
	return formation_listed_moves_menu_line(actions)
