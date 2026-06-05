class_name CombatFormationMoveListing
extends RefCounted

## Formation movement actions: swap rank, drag/fall_back pair, solo fall_back, rotate file (line discipline).
## **Read order:** append helpers → policy gates → flee/rout → per-move append (uses **`CombatListedActions`**).

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _Flee := preload("res://combat/CombatFormationFlee.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")


static func _append_formation_action(
	manager: Node, initiator: Dictionary, actions: Array, entry: Dictionary
) -> void:
	actions.append(entry)
	if manager != null and not initiator.is_empty():
		_MoveDuration.stamp_listed_action_duration_hint(manager, initiator, entry)


static func _in_formation_move_cooldown(
	manager: Node, c: Dictionary, cooldown_key: String
) -> bool:
	return _EntityAccess.combatant_cooldown_active(manager, c, cooldown_key, -1.0)


static func in_rotate_file_cooldown(manager: Node, c: Dictionary) -> bool:
	return _in_formation_move_cooldown(manager, c, "formation_rotate_file_cooldown_until")


static func in_pair_abort_cooldown(manager: Node, c: Dictionary) -> bool:
	return _in_formation_move_cooldown(manager, c, "formation_pair_abort_cooldown_until")


static func solo_fall_back_action_legal(
	manager: Node, atk: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
	if manager == null or atk.is_empty():
		return false
	if not _EntityAccess.can_flee_or_fall_back(atk):
		return false
	if _EntityAccess.rank_int(atk) != 0:
		return false
	if in_pair_abort_cooldown(manager, atk):
		return false
	var ctx_atk: Dictionary = zone_geometry_line_context_cache
	if ctx_atk.is_empty():
		ctx_atk = _ZoneOfControl.zone_geometry_line_context(manager, atk)
	var fid: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_atk)
	var our_formation: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_atk)
	if our_formation.is_empty():
		return false
	if int(our_formation.get("ranks", 1)) <= 1:
		return false
	var disc: String = CombatFormationEngagement.effective_line_discipline(manager, our_formation)
	if not CombatConstants.line_discipline_allows_solo_fall_back(disc):
		return false
	var our_file: int = _EntityAccess.file_int(atk)
	var slots_check: Dictionary = _FormationSlots.formation_slots_dict(our_formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots_check, Vector2i(1, our_file)):
		return false
	if _FormationFlow.formation_has_frontline_fill_opportunity_at_file(manager, fid, our_file):
		return false
	return _EntityAccess.retreat_formation_body_damage_warranted(atk, manager)


static func _is_adjacent_rank_ally(
	manager: Node, c: Dictionary, ally: Dictionary, fid: String, our_rank: int, our_file: int
) -> bool:
	if not _EntityAccess.is_available_formation_partner(c, ally):
		return false
	if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, ally, fid):
		return false
	if _EntityAccess.state_str(ally) in [
		CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK
	]:
		return false
	var partner_rank: int = _EntityAccess.rank_int(ally)
	var partner_file: int = _EntityAccess.file_int(ally)
	return partner_file == our_file and abs(partner_rank - our_rank) == 1


static func _is_adjacent_file_same_rank_ally(
	manager: Node, c: Dictionary, ally: Dictionary, fid: String, our_rank: int, our_file: int
) -> bool:
	if not _EntityAccess.is_available_formation_partner(c, ally):
		return false
	if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, ally, fid):
		return false
	if _EntityAccess.state_str(ally) in [
		CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK
	]:
		return false
	var partner_rank: int = _EntityAccess.rank_int(ally)
	var partner_file: int = _EntityAccess.file_int(ally)
	return partner_rank == our_rank and abs(partner_file - our_file) == 1


static func rotate_file_action_legal(
	manager: Node,
	c: Dictionary,
	ally: Dictionary,
	zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
	if manager == null or c.is_empty() or ally.is_empty():
		return false
	if _EntityAccess.rank_int(c) != 0:
		return false
	if in_pair_abort_cooldown(manager, c) or in_rotate_file_cooldown(manager, c):
		return false
	if in_rotate_file_cooldown(manager, ally):
		return false
	var ctx: Dictionary = zone_geometry_line_context_cache
	if ctx.is_empty():
		ctx = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx)
	if fid.is_empty():
		return false
	if int(_ZoneOfControl.zone_geometry_formation_from_pack(ctx).get("files", 1)) < 2:
		return false
	return _is_adjacent_file_same_rank_ally(
		manager, c, ally, fid, _EntityAccess.rank_int(c), _EntityAccess.file_int(c)
	)


static func _append_rotate_file_partner_actions(
	manager: Node,
	c: Dictionary,
	combatants: Array,
	fid: String,
	our_rank: int,
	our_file: int,
	actions: Array,
	zone_geometry_line_context_cache: Dictionary = {}
) -> void:
	for ally in combatants:
		if not _is_adjacent_file_same_rank_ally(manager, c, ally, fid, our_rank, our_file):
			continue
		if not rotate_file_action_legal(manager, c, ally, zone_geometry_line_context_cache):
			continue
		_append_formation_action(
			manager,
			c,
			actions,
			{"target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_ROTATE_FILE}
		)
		break


static func _append_adjacent_rank_partner_actions(
	manager: Node,
	c: Dictionary,
	combatants: Array,
	fid: String,
	our_rank: int,
	our_file: int,
	actions: Array,
	can_drag_back: bool
) -> void:
	for ally in combatants:
		if not _is_adjacent_rank_ally(manager, c, ally, fid, our_rank, our_file):
			continue
		var partner_rank: int = _EntityAccess.rank_int(ally)
		var we_are_front: bool = partner_rank > our_rank
		var partner_incapacitated: bool = _EntityAccess.is_incapacitated(ally)
		var we_plug_forward: bool = partner_rank < our_rank and partner_incapacitated
		var relief_swap: bool = (
			our_rank > partner_rank
			and not partner_incapacitated
			and CombatAIActionPicker.is_relief_swap_tactically_allowed(c, ally)
		)
		if not ((we_are_front and not partner_incapacitated) or we_plug_forward or relief_swap):
			continue
		var allow_swap: bool = false
		if we_plug_forward:
			allow_swap = true
		elif relief_swap:
			allow_swap = true
		elif we_are_front:
			allow_swap = CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, ally, manager)
		if allow_swap:
			_append_formation_action(
				manager,
				c,
				actions,
				{"target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_SWAP_RANK}
			)
			if not we_plug_forward and we_are_front and can_drag_back:
				_append_formation_action(
					manager,
					c,
					actions,
					{"target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_DRAG_BACK}
				)
				_append_formation_action(
					manager,
					c,
					actions,
					{"target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_FALL_BACK}
				)
		break


static func _solo_fall_back_listing_eligible(
	manager: Node,
	c: Dictionary,
	formation_ranks: int,
	our_rank: int,
	pair_abort_blocked: bool,
	zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
	if formation_ranks <= 1 or our_rank != 0:
		return false
	if pair_abort_blocked:
		return false
	if not _EntityAccess.can_flee_or_fall_back(c):
		return false
	return solo_fall_back_action_legal(manager, c, zone_geometry_line_context_cache)


## Appends swap / paired retreat / solo fall_back. Returns context for flow logs; **`cowering_early_exit`** when build should return after wait.
static func append_formation_move_actions(
	manager: Node,
	c: Dictionary,
	combatant_id: int,
	combatants: Array,
	actions: Array,
	formation_retreat_only: bool,
	zone_geometry_line_context_cache: Dictionary = {}
) -> Dictionary:
	var out: Dictionary = {"zone_fid": "", "cowering_early_exit": false}
	if manager == null or c.is_empty():
		return out
	var ctx_c: Dictionary = zone_geometry_line_context_cache
	if ctx_c.is_empty():
		ctx_c = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_c)
	var our_formation: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_c)
	var our_rank: int = _EntityAccess.rank_int(c)
	var our_file: int = _EntityAccess.file_int(c)
	out["zone_fid"] = fid
	var formation_ranks: int = int(our_formation.get("ranks", 1))
	var pair_abort_blocked: bool = in_pair_abort_cooldown(manager, c)
	var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
	var can_swap_rank: bool = bool(move_policy.get("allow_swap_rank", false))
	var can_drag_back: bool = bool(move_policy.get("allow_drag_back", false))
	var can_fall_back: bool = bool(move_policy.get("allow_fall_back", false))
	var home_fid: String = _EntityAccess.formation_id_str(c)
	var can_rotate_file: bool = _EngagementMode.allow_rotate_file_for_formation(manager, home_fid)
	if (
		not formation_retreat_only
		and not our_formation.is_empty()
		and formation_ranks > 1
		and not pair_abort_blocked
		and _EntityAccess.can_flee_or_fall_back(c)
		and (can_swap_rank or can_drag_back)
	):
		_append_adjacent_rank_partner_actions(
			manager, c, combatants, fid, our_rank, our_file, actions, can_drag_back
		)
	if (
		not formation_retreat_only
		and not our_formation.is_empty()
		and int(our_formation.get("files", 1)) >= 2
		and our_rank == 0
		and not pair_abort_blocked
		and can_rotate_file
	):
		_append_rotate_file_partner_actions(
			manager, c, combatants, fid, our_rank, our_file, actions, ctx_c
		)
	var solo_fb_ok: bool = _solo_fall_back_listing_eligible(
		manager, c, formation_ranks, our_rank, pair_abort_blocked, ctx_c
	)
	if solo_fb_ok and (formation_retreat_only or can_fall_back):
		_append_formation_action(
			manager,
			c,
			actions,
			{"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FALL_BACK}
		)
	_FormationRout.ensure_rout_baseline(manager)
	if _Flee.flee_action_legal(manager, c):
		_Flee.log_flee_listed_if_verbose(manager, c)
		_append_formation_action(
			manager,
			c,
			actions,
			{"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FLEE}
		)
	if formation_retreat_only:
		out["cowering_early_exit"] = true
	return out


## When no combat actions exist, only formation moves remain, or only guard focus lines (no melee), offer **`wait`**.
## Without the hold-line branch, back rank gets focus-only menus → AI cycles focus every turn (log/UI spam).
static func append_combat_wait_if_needed(actions: Array, combatant_id: int) -> void:
	if _ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
		return
	if actions.is_empty():
		actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
		return
	if _ListedActions.action_list_is_reserve_posture_only(actions):
		actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
		return
	if _ListedActions.action_list_is_hold_line_menu(actions):
		actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
		return
	for a in actions:
		if not CombatConstants.is_formation_movement_move(str(a.get("move_id", ""))):
			return
	actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
