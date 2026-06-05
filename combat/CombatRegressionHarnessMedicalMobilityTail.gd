class_name CombatRegressionHarnessMedicalMobilityTail
extends RefCounted

## Tier 6.1 medical mobility + cowering tests split from CombatRegressionHarness (compile size).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _FormationFlee := preload("res://combat/CombatFormationFlee.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _AfterblowHandler := preload("res://combat/AfterblowHandler.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _DefenseResolution := preload("res://combat/DefenseResolutionHandler.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _ProcessTick := preload("res://combat/CombatProcessTick.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")

## Tier 6.1: **`can_flee_or_fall_back`** — leg **`MOBILITY_FLEE_THRESHOLD`** and unconscious gate.
static func _run_medical_mobility_can_flee_leg_and_consciousness(failures: PackedStringArray) -> void:
	var mobile: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
	if not mobile.can_flee_or_fall_back():
		CombatRegressionHarness._fail(failures, "med_mobility: healthy entity should flee")
	mobile.consciousness = 5.0
	mobile._consciousness_dirty = false
	if mobile.can_flee_or_fall_back():
		CombatRegressionHarness._fail(failures, "med_mobility: unconscious should not flee")
	var immobile: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
	CombatRegressionHarness._harness_destroy_limb(immobile, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(immobile, "right_leg")
	if immobile.get_leg_functionality() >= PainConsciousnessConstants.MOBILITY_FLEE_THRESHOLD:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility: destroyed legs want leg < %.2f got %.3f"
			% [PainConsciousnessConstants.MOBILITY_FLEE_THRESHOLD, immobile.get_leg_functionality()]
		)
	if immobile.can_flee_or_fall_back():
		CombatRegressionHarness._fail(failures, "med_mobility: leg-destroyed should not flee")
## Tier 6.2: mobile cowering rank-0 lists **`flee`** in formation engagement.
static func _run_medical_mobility_cowering_lists_flee_in_formation_mode(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{
			"files": 2,
			"ranks": 3,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 2, "ranks": 2, "density": "normal"}
	)
	var _med_list_id_at := func(rank: int, file: int) -> int:
		for row in mgr.combatants:
			if (
				_EntityAccess.is_player_side(row)
				and _EntityAccess.rank_int(row) == rank
				and _EntityAccess.file_int(row) == file
			):
				return _EntityAccess.id_int(row)
		return -1
	var deep_id: int = _med_list_id_at.call(2, 0)
	if deep_id >= 0:
		CombatRegressionHarness._soak_kill_combatant(mgr, deep_id)
	var rear_victim_id: int = _med_list_id_at.call(1, 0)
	if rear_victim_id >= 0:
		CombatRegressionHarness._soak_kill_combatant(mgr, rear_victim_id)
	mgr.notify_formation_changed("player")
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = {}
	for row in mgr.combatants:
		if (
			_EntityAccess.is_player_side(row)
			and _EntityAccess.rank_int(row) == 0
			and _EntityAccess.file_int(row) == 0
		):
			front_c = row
			break
	if front_c.is_empty():
		CombatRegressionHarness._fail(failures, "flee_list: missing rank-0 file-0")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front_c.state = CombatConstants.STATE_COWERING
	front_c.gauge = 100.0
	if not _FormationFlee.flee_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_list: flee_action_legal should pass for mobile cowering")
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(front_c))
	if not _ListedActions.actions_include_self_target_move(
		acts, _EntityAccess.id_int(front_c), CombatConstants.MOVE_ID_FLEE
	):
		CombatRegressionHarness._fail(failures, "flee_list: mobile cowering want flee in build got %s" % str(acts))
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: mobile cowering (no arms, legs ok) is not skipped by **`process_incapacitation`**.
static func _run_medical_mobility_cowering_mobile_not_skipped_in_process_incap(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_player_only()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	if _StateHandlers.process_incapacitation(mgr, c):
		CombatRegressionHarness._fail(failures, "med_mobility: mobile cowering should not skip tick")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	if not _StateHandlers.process_incapacitation(mgr, c):
		CombatRegressionHarness._fail(failures, "med_mobility: immobile cowering should skip tick")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: mobile cowering receives gauge on **`EVENT_ACTION_READY`** (formation retreat listing).
static func _run_medical_mobility_cowering_action_ready_fills_gauge_for_mobile(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 0.0
	if not ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_ready: expected cowering after arm loss")
		return
	_EventDispatch.handle_action_ready(mgr, c)
	if _EntityAccess.gauge_float(c) < 100.0:
		CombatRegressionHarness._fail(failures, "med_mobility_ready: mobile cowering should reach gauge 100 on ACTION_READY")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	c.gauge = 0.0
	_EventDispatch.handle_action_ready(mgr, c)
	if _EntityAccess.gauge_float(c) >= 100.0:
		CombatRegressionHarness._fail(failures, "med_mobility_ready: immobile cowering must not get ACTION_READY gauge")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering rank-0 with legs may list solo **`fall_back`** when line discipline is loose.
static func _run_medical_mobility_cowering_mobile_solo_fall_back_legal(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_fb: expected cowering after arm loss")
	if not _FormationMoves.solo_fall_back_action_legal(mgr, c):
		CombatRegressionHarness._fail(failures, "med_mobility_fb: solo fall_back should be legal for mobile cowering")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	if _FormationMoves.solo_fall_back_action_legal(mgr, c):
		CombatRegressionHarness._fail(failures, "med_mobility_fb: immobile cowering must not allow solo fall_back")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: formation engagement — mobile cowering rank-0 lists **`fall_back`** in **`AvailableActionsBuilder.build`**.
static func _run_medical_mobility_cowering_lists_fall_back_in_formation_mode(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 6:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	# Six players on 2×3 — kill rank-2 file-0 before rank-1 file-0; need ≥4 actives after kills for formation hysteresis.
	mgr.start(
		{
			"files": 2,
			"ranks": 3,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 2, "ranks": 2, "density": "normal"}
	)
	var fid: String = "player"
	var _med_list_id_at := func(rank: int, file: int) -> int:
		for c in mgr.combatants:
			if (
				_EntityAccess.is_player_side(c)
				and _EntityAccess.rank_int(c) == rank
				and _EntityAccess.file_int(c) == file
			):
				return _EntityAccess.id_int(c)
		return -1
	var deep_id: int = _med_list_id_at.call(2, 0)
	if deep_id >= 0:
		CombatRegressionHarness._soak_kill_combatant(mgr, deep_id)
	var rear_victim_id: int = _med_list_id_at.call(1, 0)
	if rear_victim_id < 0:
		CombatRegressionHarness._fail(failures, "med_mobility_list: setup missing rank-1 file-0 player")
		return
	CombatRegressionHarness._soak_kill_combatant(mgr, rear_victim_id)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(
		_FormationSlots.formation_record_for_manager(mgr, fid)
	)
	if _FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(1, 0)):
		CombatRegressionHarness._fail(failures, "med_mobility_list: rank-1 file-0 must be vacant for solo fall_back")
		return
	mgr.notify_formation_changed("player")
	if _EngagementMode.engagement_mode(mgr) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_list: want formation mode after casualty got %s"
			% _EngagementMode.engagement_mode(mgr)
		)
	var front_c: Dictionary = {}
	for c in mgr.combatants:
		if (
			_EntityAccess.is_player_side(c)
			and _EntityAccess.rank_int(c) == 0
			and _EntityAccess.file_int(c) == 0
		):
			front_c = c
			break
	if front_c.is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_list: missing living player rank-0 file-0")
		return
	var policy: Dictionary = _EngagementMode.movement_policy(mgr)
	if not bool(policy.get("allow_fall_back", false)):
		CombatRegressionHarness._fail(failures, "med_mobility_list: formation policy must allow fall_back")
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX - 5.0
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front_c.state = CombatConstants.STATE_COWERING
	front_c.gauge = 100.0
	if not ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_list: expected cowering on rank-0")
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, fid)
	var our_file: int = _EntityAccess.file_int(front_c)
	if _FormationFlow.formation_has_frontline_fill_opportunity_at_file(mgr, fid, our_file):
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_list: unexpected rank-0 plug at file %d blocks solo fall_back"
			% our_file
		)
	if not _FormationMoves.solo_fall_back_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_list: solo fall_back illegal (rank=%d file=%d disc=%s)"
			% [
				_EntityAccess.rank_int(front_c),
				_EntityAccess.file_int(front_c),
				CombatFormationEngagement.effective_line_discipline(mgr, form),
			]
		)
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(front_c))
	if not _ListedActions.actions_include_self_target_move(
		acts, _EntityAccess.id_int(front_c), CombatConstants.MOVE_ID_FALL_BACK
	):
		var c_b: Dictionary = _EntityAccess.manager_get_combatant(mgr, _EntityAccess.id_int(front_c))
		var zf: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, c_b, null)
		var mp: Dictionary = _EngagementMode.movement_policy(mgr)
		CombatRegressionHarness._fail(
			failures,
			(
				"med_mobility_list: expected fall_back in build (acts=%s legal=%s g=%.0f"
				+ " zf_empty=%s ranks=%d allow_fb=%s mode=%s)"
			)
			% [
				str(acts),
				_FormationMoves.solo_fall_back_action_legal(mgr, front_c),
				_EntityAccess.gauge_float(c_b),
				zf.is_empty(),
				int(zf.get("ranks", 1)),
				bool(mp.get("allow_fall_back", false)),
				str(mp.get("mode", "")),
			]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering solo **`fall_back`** resolves when movement policy blocks routine line retreat.
static func _run_medical_mobility_cowering_resolve_solo_fall_back_without_movement_policy(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_SKIRMISH)
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	ent.blood_volume = CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX - 5.0
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not _FormationMoves.solo_fall_back_action_legal(mgr, c):
		CombatRegressionHarness._fail(failures, "med_resolve_fb: setup solo fall_back should be legal")
		return
	if bool(_EngagementMode.movement_policy(mgr).get("allow_fall_back", false)):
		CombatRegressionHarness._fail(failures, "med_resolve_fb: want skirmish policy to block routine fall_back")
		return
	var cid: int = _EntityAccess.id_int(c)
	mgr.resolve_action(cid, cid, CombatConstants.MOVE_ID_FALL_BACK, {})
	if _EntityAccess.state_str(c) != CombatConstants.STATE_FALLING_BACK:
		CombatRegressionHarness._fail(
			failures,
			"med_resolve_fb: cowering solo fall_back should start (state=%s)"
			% _EntityAccess.state_str(c)
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: rank-1 mobile cowering lists **wait** only (no solo **fall_back**); avoids empty action soft-lock.
static func _run_medical_mobility_cowering_depth_lists_wait_not_fall_back(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	var players: Array = []
	for row in mgr.combatants:
		if _EntityAccess.is_player_side(row):
			players.append(row)
	if players.size() < 2:
		CombatRegressionHarness._fail(failures, "med_mobility_depth: need 2 players got %d" % players.size())
		return
	var c: Dictionary = players[1]
	if _EntityAccess.rank_int(c) != 1:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_depth: second player want rank 1 got rank=%d"
			% _EntityAccess.rank_int(c)
		)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not ent.can_flee_or_fall_back():
		CombatRegressionHarness._fail(failures, "med_mobility_depth: want mobile cowering legs ok")
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	var cid_depth: int = _EntityAccess.id_int(c)
	var has_wait: bool = _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_WAIT)
	var has_fb: bool = _ListedActions.actions_include_self_target_move(
		acts, cid_depth, CombatConstants.MOVE_ID_FALL_BACK
	)
	if not has_wait:
		CombatRegressionHarness._fail(failures, "med_mobility_depth: rank-1 cowering want wait in build (acts=%s)" % str(acts))
	if has_fb:
		CombatRegressionHarness._fail(failures, "med_mobility_depth: rank-1 cowering must not solo fall_back")
	var depth_hint: String = _PlayerTurnHints.cowering_retreat_hint_if_applicable(mgr, c, acts)
	if depth_hint.is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_depth: want retreat hint got empty")
	elif not depth_hint.contains("holding position") and not depth_hint.contains("flee abandons"):
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_depth: want holding-position or flee hint got '%s'" % depth_hint
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: player UI hint when cowering with mobile legs (same turn-ready hint path as formation/rout).
static func _run_medical_mobility_cowering_player_retreat_ui_hint(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{
			"files": 2,
			"ranks": 3,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 2, "ranks": 2, "density": "normal"}
	)
	var _hint_id_at := func(rank: int, file: int) -> int:
		for row in mgr.combatants:
			if (
				_EntityAccess.is_player_side(row)
				and _EntityAccess.rank_int(row) == rank
				and _EntityAccess.file_int(row) == file
			):
				return _EntityAccess.id_int(row)
		return -1
	var deep_id: int = _hint_id_at.call(2, 0)
	if deep_id >= 0:
		CombatRegressionHarness._soak_kill_combatant(mgr, deep_id)
	var rear_id: int = _hint_id_at.call(1, 0)
	if rear_id < 0:
		CombatRegressionHarness._fail(failures, "med_mobility_hint: setup missing rank-1 file-0")
		return
	CombatRegressionHarness._soak_kill_combatant(mgr, rear_id)
	mgr.notify_formation_changed("player")
	var front_c: Dictionary = {}
	for row in mgr.combatants:
		if (
			_EntityAccess.is_player_side(row)
			and _EntityAccess.rank_int(row) == 0
			and _EntityAccess.file_int(row) == 0
		):
			front_c = row
			break
	if front_c.is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_hint: missing rank-0 file-0")
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front_c.state = CombatConstants.STATE_COWERING
	front_c.gauge = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(front_c))
	var fb_hint: String = _PlayerTurnHints.cowering_retreat_hint_if_applicable(mgr, front_c, acts)
	if fb_hint.is_empty() or not fb_hint.contains("fall back"):
		CombatRegressionHarness._fail(failures, "med_mobility_hint: fall_back listed want retreat hint got '%s'" % fb_hint)
	var enemy_c: Dictionary = {}
	for row in mgr.combatants:
		if _EntityAccess.is_enemy_side(row):
			enemy_c = row
			break
	var enemy_hint: String = _PlayerTurnHints.cowering_retreat_hint_if_applicable(
		mgr, enemy_c, acts
	)
	if not enemy_hint.is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_hint: enemy must not get player retreat hint")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering solo **fall_back** AI weight exceeds **wait** so mobile no-arms units retreat when legal.
static func _run_medical_mobility_cowering_ai_fall_back_weight_beats_wait(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var cid: int = _EntityAccess.id_int(c)
	var acts: Array = _ActionsBuilder.build(mgr, cid)
	var fb_act: Dictionary = _ListedActions.first_self_target_action(
		acts, cid, CombatConstants.MOVE_ID_FALL_BACK
	)
	var wait_act: Dictionary = _ListedActions.first_action_with_move_id(
		acts, CombatConstants.MOVE_ID_WAIT
	)
	if fb_act.is_empty() or wait_act.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_ai_w: want fall_back+wait in build got %s" % str(acts)
		)
		return
	var w_fb: float = _AIPicker._get_action_weight(fb_act, cid, mgr, true)
	var w_wait: float = _AIPicker._get_action_weight(wait_act, cid, mgr, true)
	if w_fb <= w_wait:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_ai_w: cowering fall_back want > wait got fb=%.3f wait=%.3f"
			% [w_fb, w_wait]
		)
	if absf(w_fb - CombatConstants.COWERING_SOLO_FALL_BACK_AI_WEIGHT) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_ai_w: want COWERING_SOLO_FALL_BACK_AI_WEIGHT got %.3f"
			% w_fb
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1 / 6.2: weighted **`pick_weighted`** favors retreat (**fall_back** or **flee**) over **wait** for mobile cowering.
static func _run_medical_mobility_cowering_ai_pick_favors_fall_back(
	failures: PackedStringArray
) -> void:
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var cid: int = _EntityAccess.id_int(c)
	seed(90211)
	var acts: Array = _ActionsBuilder.build(mgr, cid)
	var retreat_picks: int = 0
	var trials: int = 200
	for _t in trials:
		var choice: Dictionary = _AIPicker.pick_weighted(acts, cid, mgr)
		var mid: String = str(choice.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_FALL_BACK or mid == CombatConstants.MOVE_ID_FLEE:
			retreat_picks += 1
	if retreat_picks < 90:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_ai_pick: want retreat (fall_back|flee) majority got %d/%d"
			% [retreat_picks, trials]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: arm functionality return clears **STATE_COWERING** via **`process_incapacitation`**.
static func _run_medical_mobility_cowering_arm_recovery_clears_state(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_player_only()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 50.0
	if not ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_recover: setup want cowering")
		return
	CombatRegressionHarness._harness_restore_limb(ent, "right_arm")
	if ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_recover: one arm restored should end cowering")
		return
	if _StateHandlers.process_incapacitation(mgr, c):
		CombatRegressionHarness._fail(failures, "med_mobility_recover: recovered arms should not skip tick")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_recover: want STATE_WAITING got %s"
			% _EntityAccess.state_str(c)
		)
	if _EntityAccess.gauge_float(c) != 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_recover: gauge should reset on arm recovery")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _harness_assert_retreat_only_action_list(
	failures: PackedStringArray, acts: Array, tag: String
) -> void:
	var bad_mid: String = _MobilityRetreat.first_disallowed_retreat_only_move_id(acts)
	if not bad_mid.is_empty():
		CombatRegressionHarness._fail(failures, "%s: offensive/disallowed move_id '%s' in [%s]" % [tag, bad_mid, acts])


## Tier 6.1: no functional arm (or cowering) must not list weapon strikes / close in **`build`**.
static func _run_medical_mobility_cowering_no_offensive_melee_in_action_builder(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_WAITING
	c.gauge = 100.0
	if not ent.is_cowering():
		CombatRegressionHarness._fail(failures, "med_mobility_no_melee: setup want cowering entity")
		return
	var acts_waiting: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	_harness_assert_retreat_only_action_list(
		failures, acts_waiting, "med_mobility_no_melee: stale WAITING"
	)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_no_melee: build should sync STATE_COWERING got %s"
			% _EntityAccess.state_str(c)
		)
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var acts_cowering: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	_harness_assert_retreat_only_action_list(
		failures, acts_cowering, "med_mobility_no_melee: STATE_COWERING"
	)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: **`CombatResolveAction`** must not start melee wind-up when retreat-only.
static func _run_medical_mobility_cowering_resolve_blocks_melee_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	var p_id: int = _EntityAccess.id_int(c)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	_ResolveAction.resolve(mgr, p_id, e_id, "overhead_strike", {})
	if _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "med_mobility_resolve: must not enter wind-up without functional arm")
	if not _EntityAccess.nested_dictionary_read(c, "pending_attack").is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_resolve: must not stamp pending_attack without functional arm")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: stale pre-recovery **`EVENT_ACTION_READY`** is dropped when recovery ends into cowering.
static func _run_medical_mobility_cowering_stale_action_ready_cancelled_on_recovery_end(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1_enemy_first()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	var cid: int = _EntityAccess.id_int(c)
	c.state = CombatConstants.STATE_RECOVERING
	c.state_duration = 0.5
	c.gauge = 0.0
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	mgr.event_queue.append({
		"type": CombatConstants.EVENT_ACTION_READY,
		"combatant_id": cid,
		"resolve_at": float(mgr.combat_clock),
		"data": {},
	})
	mgr.event_queue.append({
		"type": CombatConstants.EVENT_RECOVERY_END,
		"combatant_id": cid,
		"resolve_at": float(mgr.combat_clock),
		"data": {},
	})
	_EventScheduler.sort_event_queue(mgr)
	_EventDispatch.process_event_queue(mgr)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_stale_ready: want cowering after recovery got %s"
			% _EntityAccess.state_str(c)
		)
	if _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "med_mobility_stale_ready: must not wind up from stale ACTION_READY")
	if _EventScheduler.get_next_action_ready_at(mgr, cid) < 0.0 and _EntityAccess.can_flee_or_fall_back(c):
		CombatRegressionHarness._fail(failures, "med_mobility_stale_ready: mobile cowering should reschedule ACTION_READY")
	c.gauge = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, cid)
	_harness_assert_retreat_only_action_list(
		failures, acts, "med_mobility_stale_ready: post-recovery build"
	)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: **`CombatAIActionPicker.pick`** never chooses weapon strikes when retreat-only.
static func _run_medical_mobility_cowering_ai_pick_never_offensive(
	failures: PackedStringArray
) -> void:
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var mgr: Node = CombatRegressionHarness._harness_start_1v1_enemy_first()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	var cid: int = _EntityAccess.id_int(c)
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var acts: Array = [
		{"target_id": cid, "move_id": CombatConstants.MOVE_ID_WAIT},
		{"target_id": _EntityAccess.id_int(mgr.combatants[1]), "move_id": "overhead_strike"},
	]
	seed(88061)
	for _t in 80:
		var choice: Dictionary = _AIPicker.pick(acts, cid, mgr)
		var mid: String = str(choice.get("move_id", ""))
		if mid != CombatConstants.MOVE_ID_WAIT and mid != CombatConstants.MOVE_ID_FALL_BACK:
			CombatRegressionHarness._fail(
				failures,
				"med_mobility_ai_pick: retreat-only must not pick '%s' got %s"
				% [mid, choice]
			)
			break
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: arm loss during wind-up — **`EVENT_MELEE_ATTACK`** aborts before resolve.
static func _run_medical_mobility_cowering_mid_windup_arm_loss_aborts_melee(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en_ent: CoreEntity = _EntityAccess.scene_node(mgr.combatants[1]) as CoreEntity
	var chest_before: float = float(en_ent.body_cutting.get("chest", 0.0))
	_WindUpStarter.start(mgr, p_id, e_id, "thrust")
	var ent: CoreEntity = _EntityAccess.scene_node(p) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	_EventDispatch.handle_melee_attack(mgr, p)
	if _EntityAccess.state_str(p) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "med_mobility_windup_abort: must leave WIND_UP after arm loss at melee event")
	var chest_after: float = float(en_ent.body_cutting.get("chest", 0.0))
	if chest_after < chest_before - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_windup_abort: enemy took damage %.2f -> %.2f"
			% [chest_before, chest_after]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: defender arm loss on hit triggers **`react_attacking_arm_lost_if_needed`** (cowering + cancel ready).
static func _run_medical_mobility_cowering_react_after_hit_arm_loss(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	def.state = CombatConstants.STATE_WAITING
	def.gauge = 50.0
	var def_ent: CoreEntity = _EntityAccess.scene_node(def) as CoreEntity
	_EventScheduler.schedule_action_ready(mgr, def_id, 0.2)
	CombatRegressionHarness._harness_destroy_limb(def_ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(def_ent, "left_arm")
	_MobilityRetreat.react_attacking_arm_lost_if_needed(mgr, def)
	if _EntityAccess.state_str(def) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_react: want STATE_COWERING got %s"
			% _EntityAccess.state_str(def)
		)
	if _EventScheduler.get_next_action_ready_at(mgr, def_id) < 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_react: should reschedule ACTION_READY for mobile cowering")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: afterblow aborts when striker's attacking arm is destroyed on the counter-hit.
static func _run_medical_mobility_cowering_afterblow_aborts_destroyed_attacking_arm(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	mgr._recompute_zoc_and_distance()
	CombatRegressionHarness._afterblow_harness_seed_pending_cut(mgr, 1, 0)
	var striker: Dictionary = mgr.combatants[1]
	var striker_ent: CoreEntity = _EntityAccess.scene_node(striker) as CoreEntity
	var arm: String = _EntityAccess.get_attacking_arm(striker)
	if arm.is_empty():
		arm = "right_arm"
	CombatRegressionHarness._harness_destroy_limb(striker_ent, arm)
	if not _EntityAccess.get_attacking_arm(striker).is_empty():
		CombatRegressionHarness._harness_destroy_limb(striker_ent, "left_arm")
	if not _EntityAccess.get_attacking_arm(striker).is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_afterblow_arm: could not strip attacking arm")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var tid: int = _EntityAccess.id_int(striker)
	var rd: Dictionary = {
		"part": arm,
		"outcome": "hit",
		"final_cut": 20.0,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		CombatRegressionHarness._fail(failures, "med_mobility_afterblow_arm: try_afterblow must be false when arm destroyed")
	if _EntityAccess.state_str(striker) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "med_mobility_afterblow_arm: must leave WIND_UP")
	if not _EntityAccess.nested_dictionary_read(striker, "pending_attack").is_empty():
		CombatRegressionHarness._fail(failures, "med_mobility_afterblow_arm: pending_attack must clear")
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, tid) >= 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_afterblow_arm: pending melee event must cancel")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: tick during wind-up aborts when arms are lost before **`EVENT_MELEE_ATTACK`**.
static func _run_medical_mobility_cowering_process_windup_aborts_when_no_arm(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_WindUpStarter.start(mgr, p_id, e_id, "thrust")
	var p: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(p) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	_StateHandlers.process_wind_up(mgr, p, 0.05)
	if _EntityAccess.state_str(p) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "med_mobility_windup_tick: process_wind_up must abort when no arm")
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, p_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_windup_tick: pending melee must cancel on abort")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: arm loss during **`RECOVERING`** completes into cowering without waiting for stale recovery end.
static func _run_medical_mobility_cowering_recovery_completes_early_when_arm_lost(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_player_only()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	c.state = CombatConstants.STATE_RECOVERING
	c.state_duration = 2.0
	c.state_timer = 0.0
	mgr.event_queue.append({
		"type": CombatConstants.EVENT_RECOVERY_END,
		"combatant_id": _EntityAccess.id_int(c),
		"resolve_at": float(mgr.combat_clock) + 2.0,
		"data": {},
	})
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	_StateHandlers.process_recovering(mgr, c, 0.05)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
		CombatRegressionHarness._fail(
			failures,
			"med_mobility_rec_early: want cowering got %s"
			% _EntityAccess.state_str(c)
		)
	if _EventScheduler.get_next_action_ready_at(mgr, _EntityAccess.id_int(c)) < 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_rec_early: should schedule retreat ACTION_READY")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: parry riposte turn-ready is not scheduled for a defender with no functional arm.
static func _run_medical_mobility_cowering_parry_riposte_skips_no_arm_defender(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[1])
	def.state = CombatConstants.STATE_WAITING
	var def_ent: CoreEntity = _EntityAccess.scene_node(def) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(def_ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(def_ent, "left_arm")
	_EventScheduler.cancel_pending_action_ready(mgr, def_id)
	var result: Dictionary = {
		"action": "parry_deflect",
		"target_id": def_id,
		"recovery_duration": 0.5,
	}
	_AttackResultApplier.apply_result(mgr, atk_id, result)
	if _EventScheduler.get_next_action_ready_at(mgr, def_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_parry: must not schedule riposte ACTION_READY without arms")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: immobile cowering (no arms, no legs) must not get **`EVENT_ACTION_READY`** scheduled.
static func _run_medical_mobility_cowering_immobile_skips_action_ready_schedule(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_player_only()
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	c.state = CombatConstants.STATE_COWERING
	_EventScheduler.cancel_pending_action_ready(mgr, _EntityAccess.id_int(c))
	_EventScheduler.schedule_action_ready(mgr, _EntityAccess.id_int(c), 0.1)
	if _EventScheduler.get_next_action_ready_at(mgr, _EntityAccess.id_int(c)) >= 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_immobile: must not queue ACTION_READY")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: parry deflect on armless defender clears bind / riposte chain (no follow-up offense).
static func _run_medical_mobility_cowering_parry_deflect_clears_bind_without_arms(
	failures: PackedStringArray
) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var def_ent: CoreEntity = _EntityAccess.scene_node(def) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(def_ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(def_ent, "left_arm")
	var result: Dictionary = {
		"action": "parry_deflect",
		"target_id": def_id,
		"recovery_duration": 0.5,
		"parry_clash_context": {"parry_control": 1.0, "archetype_id": "slash"},
	}
	_AttackResultApplier.apply_result(mgr, atk_id, result)
	if bool(def.get("parry_was_bind", false)):
		CombatRegressionHarness._fail(failures, "med_mobility_parry_bind: armless defender must not bind")
	if int(def.get("parry_against_id", -1)) >= 0:
		CombatRegressionHarness._fail(failures, "med_mobility_parry_bind: parry_against_id must clear")
	if float(def.get(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL, -1.0)) > 0.0:
		CombatRegressionHarness._fail(failures, "med_mobility_parry_bind: riposte chain must not grant without arms")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.1: **`is_offensive_melee_move_id`** classifies strikes vs retreat moves.
static func _run_medical_mobility_cowering_is_offensive_move_id_helper(
	failures: PackedStringArray
) -> void:
	if not _MobilityRetreat.is_offensive_melee_move_id("overhead_strike"):
		CombatRegressionHarness._fail(failures, "med_mobility_off_id: strike should be offensive")
	if _MobilityRetreat.is_offensive_melee_move_id(CombatConstants.MOVE_ID_WAIT):
		CombatRegressionHarness._fail(failures, "med_mobility_off_id: wait must not be offensive")
	if _MobilityRetreat.is_offensive_melee_move_id(CombatConstants.MOVE_ID_FALL_BACK):
		CombatRegressionHarness._fail(failures, "med_mobility_off_id: fall_back must not be offensive")


## III-6: depth-rank wind-up aborts when same-file rank-0 lane closes mid telegraph.
static func _run_depth_wind_up_aborts_when_lane_closes(failures: PackedStringArray) -> void:
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
		CombatRegressionHarness._fail(failures, "depth_lane_abort: missing front/depth/enemy fixtures")
		return
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_lane_abort: setup want open depth lane")
		return
	var depth_id: int = _EntityAccess.id_int(depth)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	_WindUpStarter.start(mgr, depth_id, enemy_id, "spear_thrust")
	if _EntityAccess.state_str(depth) != CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "depth_lane_abort: depth should enter wind_up")
		return
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(depth, "pending_attack")
	if str(pa.get("depth_polearm_lane_type", "")).is_empty():
		CombatRegressionHarness._fail(failures, "depth_lane_abort: depth wind-up should stamp lane type")
		return
	front["alive"] = false
	if not _StateHandlers.process_depth_wind_up_lane_cancel(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_lane_abort: expected lane-close cancel")
	elif _EntityAccess.state_str(depth) != CombatConstants.STATE_RECOVERING:
		CombatRegressionHarness._fail(
			failures,
			"depth_lane_abort: want recovering after abort got %s" % _EntityAccess.state_str(depth)
		)
	CombatRegressionHarness._free_manager(mgr)


static func run(failures: PackedStringArray) -> void:
	_run_medical_mobility_can_flee_leg_and_consciousness(failures)
	_run_medical_mobility_cowering_lists_flee_in_formation_mode(failures)
	_run_medical_mobility_cowering_mobile_not_skipped_in_process_incap(failures)
	_run_medical_mobility_cowering_action_ready_fills_gauge_for_mobile(failures)
	_run_medical_mobility_cowering_mobile_solo_fall_back_legal(failures)
	_run_medical_mobility_cowering_lists_fall_back_in_formation_mode(failures)
	_run_medical_mobility_cowering_resolve_solo_fall_back_without_movement_policy(failures)
	_run_medical_mobility_cowering_depth_lists_wait_not_fall_back(failures)
	_run_medical_mobility_cowering_player_retreat_ui_hint(failures)
	_run_medical_mobility_cowering_ai_fall_back_weight_beats_wait(failures)
	_run_medical_mobility_cowering_ai_pick_favors_fall_back(failures)
	_run_medical_mobility_cowering_arm_recovery_clears_state(failures)
	_run_medical_mobility_cowering_no_offensive_melee_in_action_builder(failures)
	_run_medical_mobility_cowering_resolve_blocks_melee_wind_up(failures)
	_run_medical_mobility_cowering_stale_action_ready_cancelled_on_recovery_end(failures)
	_run_medical_mobility_cowering_ai_pick_never_offensive(failures)
	_run_medical_mobility_cowering_mid_windup_arm_loss_aborts_melee(failures)
	_run_medical_mobility_cowering_react_after_hit_arm_loss(failures)
	_run_medical_mobility_cowering_afterblow_aborts_destroyed_attacking_arm(failures)
	_run_medical_mobility_cowering_process_windup_aborts_when_no_arm(failures)
	_run_depth_wind_up_aborts_when_lane_closes(failures)
	_run_medical_mobility_cowering_recovery_completes_early_when_arm_lost(failures)
	_run_medical_mobility_cowering_parry_riposte_skips_no_arm_defender(failures)
	_run_medical_mobility_cowering_immobile_skips_action_ready_schedule(failures)
	_run_medical_mobility_cowering_parry_deflect_clears_bind_without_arms(failures)
	_run_medical_mobility_cowering_is_offensive_move_id_helper(failures)
