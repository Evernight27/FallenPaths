class_name CombatEngagementDiagnostics
extends RefCounted

## F5 / play-session lines (grep **`engagement_debug`**) — opposition map, distance bands, non-strike picks.
## Per-combatant dedupe on identical turn lines (reserve **`wait`** loops). Off under headless harness quiet.

const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")

static var _fight_start_logged: bool = false
static var _last_engagement_turn_line_by_cid: Dictionary = {}


static func reset_session() -> void:
	_fight_start_logged = false
	_last_engagement_turn_line_by_cid.clear()


static func diagnostics_active() -> bool:
	return (
		_OperationalLog.is_play_session_active()
		and CombatConstants.play_session_diagnostic_active()
	)


static func log_fight_start_summary(manager: Node) -> void:
	if not diagnostics_active() or manager == null or _fight_start_logged:
		return
	if not manager.has_meta(_EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		return
	_fight_start_logged = true
	var forms: Dictionary = manager.get("formations") as Dictionary
	var pf: int = int((forms.get("player", {}) as Dictionary).get("files", 1))
	var ef: int = int((forms.get("enemy", {}) as Dictionary).get("files", 1))
	var off_p: int = _EngagementOpposition.opposition_file_offset(manager, "player")
	var off_e: int = _EngagementOpposition.opposition_file_offset(manager, "enemy")
	_OperationalLog.play_combat(
		"engagement_debug fight_start offset_player=%d offset_enemy=%d files=%d/%d skirmish_rotate_player=%s skirmish_rotate_enemy=%s"
		% [
			off_p,
			off_e,
			pf,
			ef,
			str(_EngagementMode.allow_rotate_file_for_formation(manager, "player")).to_lower(),
			str(_EngagementMode.allow_rotate_file_for_formation(manager, "enemy")).to_lower(),
		]
	)
	var pairs: PackedStringArray = _rank0_opposition_pair_lines(manager, "player")
	for line in pairs:
		_OperationalLog.play_combat("engagement_debug rank0_map %s" % line)
	for line in _rank0_opposition_pair_lines(manager, "enemy"):
		_OperationalLog.play_combat("engagement_debug rank0_map %s" % line)
	_OperationalLog.play_combat(
		"engagement_debug hint grep engagement_debug turn — reserve_only+LONG: L4 close when wing_lack or pincer=flank_wing; rotate needs skirmish outnumber; center pincer=center pins"
	)


static func maybe_log_turn_pick(
	manager: Node, combatant_id: int, actions: Array, choice: Dictionary
) -> void:
	if not diagnostics_active() or manager == null or choice.is_empty():
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return
	var mid: String = str(choice.get("move_id", "")).strip_edges()
	if mid.is_empty():
		return
	if not _should_log_pick(mid, actions, c):
		return
	var layer: String = str(c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).strip_edges()
	var menu: String = _menu_kind(actions)
	var opposed: String = _nearest_opposed_label(manager, c)
	var wing_lack: bool = _EngagementOpposition.wing_lacks_mapped_opposition(manager, c)
	var pincer_role: String = _Doctrine.pincer_role_for_combatant(manager, c)
	var bands: String = _distance_band_summary(c)
	var counts: String = _action_menu_counts(actions)
	var line: String = (
		(
			"engagement_debug turn side=%s id=%d %s file=%d rank=%d menu=%s bands=%s opposed=%s "
			+ "mapped_opp=%s wing_lack=%s %s pick=%s%s%s"
		)
		% [
			_EntityAccess.side_str(c),
			combatant_id,
			_EntityAccess.get_display_name(c, combatant_id),
			_EntityAccess.file_int(c),
			_EntityAccess.rank_int(c),
			menu,
			bands,
			opposed,
			str(not wing_lack).to_lower(),
			str(wing_lack).to_lower(),
			counts,
			mid,
			(" layer=" + layer) if not layer.is_empty() else "",
			(" pincer=" + pincer_role) if not pincer_role.is_empty() else "",
		]
	)
	if line == str(_last_engagement_turn_line_by_cid.get(combatant_id, "")):
		return
	_last_engagement_turn_line_by_cid[combatant_id] = line
	_OperationalLog.play_combat(line)


static func _should_log_pick(move_id: String, actions: Array, c: Dictionary) -> bool:
	if _ListedActions.action_list_is_hold_line_menu(actions):
		return true
	if (
		CombatConstants.is_formation_movement_move(move_id)
		or move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
		or move_id == CombatConstants.MOVE_ID_WAIT
	):
		return true
	if not c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "").is_empty():
		return true
	return false


static func _menu_kind(actions: Array) -> String:
	if _ListedActions.action_list_is_reserve_posture_only(actions):
		return "reserve_only"
	if _ListedActions.action_list_is_hold_line_only(actions):
		return "hold_only"
	return "strikes_listed"


static func _action_menu_counts(actions: Array) -> String:
	var strikes: int = 0
	var close_n: int = 0
	var rotate_n: int = 0
	var wait_n: int = 0
	for raw in actions:
		if raw is not Dictionary:
			continue
		var mid: String = str((raw as Dictionary).get("move_id", ""))
		match mid:
			CombatConstants.MOVE_ID_WAIT:
				wait_n += 1
			CombatConstants.MOVE_ID_ROTATE_FILE:
				rotate_n += 1
			CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
				close_n += 1
			_:
				if CombatConstants.is_formation_movement_move(mid):
					pass
				elif not CombatConstants.is_focus_line_move(mid) and not mid.is_empty():
					strikes += 1
	return "strikes=%d close=%d rotate=%d wait=%d" % [strikes, close_n, rotate_n, wait_n]


static func _distance_band_summary(c: Dictionary) -> String:
	var d_to: Dictionary = _EntityAccess.nested_dictionary_read(c, "distance_to")
	if d_to.is_empty():
		return "(none)"
	var parts: PackedStringArray = PackedStringArray()
	for oid in d_to.keys():
		var band: String = str(d_to[oid])
		parts.append("e%d:%s" % [int(oid), band])
	parts.sort()
	return ", ".join(parts) if not parts.is_empty() else "(none)"


static func _nearest_opposed_label(manager: Node, actor: Dictionary) -> String:
	if manager == null or actor.is_empty():
		return "—"
	var side: String = _EntityAccess.side_str(actor)
	var offset: int = _EngagementOpposition.opposition_file_offset(manager, side)
	var actor_file: int = _EntityAccess.file_int(actor)
	var best_dist: int = 999999
	var best: Dictionary = {}
	var mapping: String = "none"
	for opp in manager.combatants:
		if not _EntityAccess.is_living_hostile_to(actor, opp):
			continue
		if _EntityAccess.rank_int(opp) != 0:
			continue
		if not _MeleeRank.opp_matches_melee_rank_target(manager, actor, opp, 0):
			continue
		var opp_file: int = _EntityAccess.file_int(opp)
		var dist: int = absi(actor_file - (opp_file + offset))
		if dist < best_dist:
			best_dist = dist
			best = opp
			mapping = (
				"strict"
				if actor_file == opp_file + offset
				else ("nearest@%d" % dist)
			)
	if best.is_empty():
		return "none"
	return "%s@f%d(%s)" % [
		_EntityAccess.get_display_name(best, _EntityAccess.id_int(best)),
		_EntityAccess.file_int(best),
		mapping,
	]


static func _rank0_opposition_pair_lines(manager: Node, side: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var rank0: Array = []
	for c in manager.combatants:
		if _EntityAccess.side_str(c) != side:
			continue
		if _EntityAccess.rank_int(c) != 0 or not _EntityAccess.alive_bool(c):
			continue
		rank0.append(c)
	rank0.sort_custom(func(a, b): return _EntityAccess.file_int(a) < _EntityAccess.file_int(b))
	var prefix: String = "p" if side == "player" else "e"
	for unit in rank0:
		var ff: int = _EntityAccess.file_int(unit)
		var label: String = _nearest_opposed_label(manager, unit)
		out.append("%s_f%d->%s" % [prefix, ff, label])
	return out
