class_name CombatEngagementDiagnostics
extends RefCounted

## F5 / play-session lines (grep **`engagement_debug`**) — opposition map, distance bands, non-strike picks.
## Off under headless harness quiet; on with **`OperationalLog.begin_play_session`**.

const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")

static var _fight_start_logged: bool = false


static func reset_session() -> void:
	_fight_start_logged = false


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
	var line_gap_p: bool = _FormationFlow.formation_line_has_rank0_gap(manager, "player")
	var line_gap_e: bool = _FormationFlow.formation_line_has_rank0_gap(manager, "enemy")
	_OperationalLog.play_combat(
		(
			"engagement_debug fight_start offset_player=%d offset_enemy=%d files=%d/%d "
			+ "skirmish_rotate_player=%s skirmish_rotate_enemy=%s line_gap_player=%s line_gap_enemy=%s"
		)
		% [
			off_p,
			off_e,
			pf,
			ef,
			str(_EngagementMode.allow_rotate_file_for_formation(manager, "player")).to_lower(),
			str(_EngagementMode.allow_rotate_file_for_formation(manager, "enemy")).to_lower(),
			str(line_gap_p).to_lower(),
			str(line_gap_e).to_lower(),
		]
	)
	var pairs: PackedStringArray = _rank0_opposition_pair_lines(manager)
	for line in pairs:
		_OperationalLog.play_combat("engagement_debug rank0_map %s" % line)
	_OperationalLog.play_combat(
		"engagement_debug hint grep engagement_debug turn — reserve_only+LONG=no strikes; rotate needs skirmish outnumber; wing_lack=true enables L4 close; mop_up=true suppresses rotate without melee; mop_up combat tail want strikes_listed/strikes>0 not close-only stall (3e); line_plug_pick=1 on rank-0 gap swap/rotate or incap plug-forward swap"
	)


static func maybe_log_turn_pick(
	manager: Node, combatant_id: int, actions: Array, choice: Dictionary
) -> void:
	if not diagnostics_active() or manager == null or choice.is_empty():
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty() or not _EntityAccess.is_player_side(c):
		return
	var mid: String = str(choice.get("move_id", "")).strip_edges()
	if mid.is_empty():
		return
	if not _should_log_pick(mid, actions, c, manager):
		return
	var layer: String = str(c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).strip_edges()
	var menu: String = _menu_kind(actions)
	var opposed: String = _nearest_opposed_label(manager, c)
	var wing_lack: bool = _EngagementOpposition.wing_lacks_mapped_opposition(manager, c)
	var fid: String = _EntityAccess.formation_id_str(c)
	var mop_up: bool = _CombatDoctrine.envelop_mop_up_active(manager, fid)
	var rotate_suppress: bool = _CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, actions)
	var line_plug: bool = _FormationFlow.formation_line_has_rank0_gap(manager, fid)
	var line_plug_pick: bool = false
	if line_plug:
		if mid == CombatConstants.MOVE_ID_SWAP_RANK and _EntityAccess.rank_int(c) > 0:
			line_plug_pick = true
		elif (
			mid == CombatConstants.MOVE_ID_ROTATE_FILE
			and _EntityAccess.rank_int(c) == 0
			and str(_EngagementMode.engagement_mode(manager)) == CombatConstants.ENGAGEMENT_MODE_SKIRMISH
		):
			line_plug_pick = true
	elif (
		mid == CombatConstants.MOVE_ID_SWAP_RANK
		and _EntityAccess.rank_int(c) > 0
		and _swap_rank_incap_plug_forward_pick(c, choice, manager)
	):
		line_plug_pick = true
	var line_plug_logged: bool = line_plug or line_plug_pick
	var bands: String = _distance_band_summary(c)
	var counts: String = _action_menu_counts(actions)
	_OperationalLog.play_combat(
		(
			"engagement_debug turn id=%d %s file=%d rank=%d menu=%s bands=%s opposed=%s "
			+ "mapped_opp=%s wing_lack=%s mop_up=%s rotate_suppress=%s line_plug=%s %s pick=%s%s%s"
		)
		% [
			combatant_id,
			_EntityAccess.get_display_name(c, combatant_id),
			_EntityAccess.file_int(c),
			_EntityAccess.rank_int(c),
			menu,
			bands,
			opposed,
			str(not wing_lack).to_lower(),
			str(wing_lack).to_lower(),
			str(mop_up).to_lower(),
			str(rotate_suppress).to_lower(),
			str(line_plug_logged).to_lower(),
			counts,
			mid,
			(" layer=" + layer) if not layer.is_empty() else "",
			" line_plug_pick=1" if line_plug_pick else "",
		]
	)


static func _should_log_pick(move_id: String, actions: Array, c: Dictionary, manager: Node) -> bool:
	if manager != null:
		var fid: String = _EntityAccess.formation_id_str(c)
		if (
			_CombatDoctrine.envelop_mop_up_active(manager, fid)
			and _ListedActions.action_list_has_hostile_melee_strike(actions, _EntityAccess.id_int(c))
		):
			return true
	if _ListedActions.action_list_is_reserve_posture_only(actions):
		return true
	if move_id in [
		CombatConstants.MOVE_ID_WAIT,
		CombatConstants.MOVE_ID_ROTATE_FILE,
		CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
		CombatConstants.MOVE_ID_FLEE,
		CombatConstants.MOVE_ID_FALL_BACK,
		CombatConstants.MOVE_ID_SWAP_RANK,
		CombatConstants.MOVE_ID_DRAG_BACK,
	]:
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
			CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK, CombatConstants.MOVE_ID_FLEE:
				pass
			_:
				if not mid.begins_with("focus_") and not mid.is_empty():
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


static func _swap_rank_incap_plug_forward_pick(
	c: Dictionary, choice: Dictionary, manager: Node
) -> bool:
	if manager == null or c.is_empty() or choice.is_empty():
		return false
	var partner: Dictionary = _EntityAccess.manager_get_combatant(
		manager, int(choice.get("target_id", -1))
	)
	if partner.is_empty():
		return false
	if _EntityAccess.rank_int(partner) >= _EntityAccess.rank_int(c):
		return false
	return _EntityAccess.is_incapacitated(partner)


static func _rank0_opposition_pair_lines(manager: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var players: Array = []
	for c in manager.combatants:
		if _EntityAccess.is_player_side(c) and _EntityAccess.rank_int(c) == 0 and _EntityAccess.alive_bool(c):
			players.append(c)
	players.sort_custom(func(a, b): return _EntityAccess.file_int(a) < _EntityAccess.file_int(b))
	for p in players:
		var pf: int = _EntityAccess.file_int(p)
		var label: String = _nearest_opposed_label(manager, p)
		out.append("p_f%d->%s" % [pf, label])
	return out
