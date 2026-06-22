class_name HarnessFixtures
extends RefCounted

## Shared combat harness fixtures, setup helpers, cleanup utilities, and assertion methods.
## Extracted from CombatRegressionHarness to reduce its 12,515-line monolith.
## All methods are static; called by CombatRegressionHarness.run_all() and tail files.
## No behavioral changes — zero-diff refactor.

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _Harness := preload("res://combat/CombatRegressionHarness.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")


# ── Node lifecycle ────────────────────────────────────────────────────────

static var _harness_live_nodes: Array = []


static func _track_harness_node(n: Node) -> void:
	if n != null and is_instance_valid(n):
		_harness_live_nodes.append(n)


static func flush_harness_live_nodes() -> void:
	for n in _harness_live_nodes.duplicate():
		if n != null and is_instance_valid(n):
			_free_harness_node(n)
	_harness_live_nodes.clear()


static func _free_harness_node(n: Node) -> void:
	if n == null or not is_instance_valid(n):
		return
	var idx: int = _harness_live_nodes.find(n)
	if idx >= 0:
		_harness_live_nodes.remove_at(idx)
	n.free()


static func _free_manager(mgr: Node) -> void:
	if mgr == null or not is_instance_valid(mgr):
		return
	if mgr.get("combatants") is Array:
		var freed_ids: Dictionary = {}
		for c in mgr.combatants:
			var n: Node = _EntityAccess.scene_node(c)
			if n == null or not is_instance_valid(n):
				continue
			var nid: int = n.get_instance_id()
			if freed_ids.has(nid):
				continue
			freed_ids[nid] = true
			_free_harness_node(n)
		mgr.combatants.clear()
	if mgr.is_inside_tree():
		mgr.get_parent().remove_child(mgr)
	_free_harness_node(mgr)


## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager — keeps run_all() order-stable.
static func _free_manager_restore_global_rng(mgr: Node) -> void:
	seed(_Harness._HARNESS_RESTORE_GLOBAL_SEED)
	_free_manager(mgr)


# ── Entity creation ───────────────────────────────────────────────────────

static func _new_entity(weapon_id: String) -> CoreEntity:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	var w: Weapon = _Weapon.create_from_definition(weapon_id)
	if w != null:
		e.equip_weapon(w)
	_track_harness_node(e)
	return e


static func _new_entity_unarmed() -> CoreEntity:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	_track_harness_node(e)
	return e


# ── Manager setup ─────────────────────────────────────────────────────────

## Standard harness duel (SWORD 1x1 vs SWORD 1x1).
static func _harness_start_1v1(
	weapon_id: String = "SWORD",
	player_side: Dictionary = {"files": 1, "ranks": 1},
	enemy_side: Dictionary = {"files": 1, "ranks": 1}
) -> Node:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity(weapon_id), "player")
	mgr.register(_new_entity(weapon_id), "enemy")
	mgr.start(player_side, enemy_side)
	_harness_reset_combatants_form_balanced(mgr)
	return mgr


static func _harness_reset_combatants_form_balanced(mgr: Node) -> void:
	const _WF := preload("res://combat/CombatWeaponForm.gd")
	for c in mgr.combatants:
		if c is Dictionary:
			_WF.assign_form(mgr, c as Dictionary, _WF.FORM_BALANCED, "harness_baseline")


## Player-only manager (tooltip / UI probes with no enemy row).
static func _harness_start_player_only(
	player_side: Dictionary = {"files": 1, "ranks": 1}
) -> Node:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.start(player_side, player_side)
	_harness_reset_combatants_form_balanced(mgr)
	return mgr


# ── Equipment ─────────────────────────────────────────────────────────────

## Full plate kit for armor-mass harness probes.
static func _harness_equip_heavy_plate_kit(e: CoreEntity) -> void:
	var kit: Array = [
		["head", "KETTLE_HELM"],
		["chest", "CUIRASS"],
		["right_arm", "VAMBRACES_RIGHT"],
		["left_arm", "VAMBRACES_LEFT"],
		["right_leg", "GREAVES_RIGHT"],
		["left_leg", "GREAVES_LEFT"],
	]
	for row in kit:
		var ap: Variant = _ArmorPiece.create_from_definition(str(row[1]))
		if ap != null:
			e.equip_armor(str(row[0]), ap)


# ── Roster / formation lookups ────────────────────────────────────────────

static func _harness_find_living_at_rank_file(
	mgr: Node, side: String, rank: int, file: int
) -> Dictionary:
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.side_str(c) != side:
			continue
		if _EntityAccess.rank_int(c) != rank:
			continue
		if _EntityAccess.file_int(c) != file:
			continue
		return c
	return {}


# ── Formation fixtures ────────────────────────────────────────────────────

## 6v3 skirmish — flee rank-0 files, survivor at rank-0 (default file 4).
## Returns {mgr, survivor, survivor_id} or {} on fixture failure (frees mgr).
static func _harness_sparse_post_flee_6v3_mgr(
	survivor_file: int = 4,
	fled_files: Array = [0, 1, 2, 3]
) -> Dictionary:
	var mgr: Node = _MgrScript.new()
	for _i in 6:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 6, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	for file_raw in fled_files:
		var file: int = int(file_raw)
		var fled: Dictionary = _harness_find_living_at_rank_file(mgr, "player", 0, file)
		if fled.is_empty():
			_free_manager(mgr)
			return {}
		_FormationSlots.remove_combatant_from_slots(slots, _EntityAccess.id_int(fled))
		fled["combat_absent"] = true
		fled.state = CombatConstants.STATE_FLED
	mgr._recompute_zoc_and_distance()
	var survivor: Dictionary = _harness_find_living_at_rank_file(mgr, "player", 0, survivor_file)
	if survivor.is_empty():
		_free_manager(mgr)
		return {}
	return {
		"mgr": mgr,
		"survivor": survivor,
		"survivor_id": _EntityAccess.id_int(survivor),
	}


## 7v3 rank-0 player file 6 vs enemy file 2 (mapped wing; out of sword reach).
static func _harness_7v3_wing_rank0_fixtures() -> Array:
	var wide: Node = _MgrScript.new()
	for _i in 7:
		wide.register(_new_entity("SWORD"), "player")
	for _j in 3:
		wide.register(_new_entity("SWORD"), "enemy")
	wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p_wing: Dictionary = _harness_find_living_at_rank_file(wide, "player", 0, 6)
	var e_wing: Dictionary = _harness_find_living_at_rank_file(wide, "enemy", 0, 2)
	return [wide, p_wing, e_wing]


static func _harness_bind_pair_long_band(p: Dictionary, e: Dictionary) -> void:
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	_EntityAccess.nested_dictionary_for_mutation(p, "distance_to")[e_id] = (
		CombatConstants.DISTANCE_LONG
	)
	_EntityAccess.nested_dictionary_for_mutation(e, "distance_to")[p_id] = (
		CombatConstants.DISTANCE_LONG
	)


# ── Soak / test utilities ─────────────────────────────────────────────────

## Tier 1.8 (P9): kill a combatant through the manager's internal path.
static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
	if mgr == null:
		return
	var c: Variant = mgr._get_by_id(combatant_id)
	if c == null or typeof(c) != TYPE_DICTIONARY:
		return
	if not _EntityAccess.alive_bool(c):
		return
	c["alive"] = false
	mgr._on_combatant_died(c)


static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity(weapon_id), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	if bind:
		p["parry_was_bind"] = true
		p["parry_against_id"] = e_id
	seed(90210)
	_WindUpStarter.start(mgr, p_id, e_id, move_id)
	var dur: float = float(p.get("state_duration", 0.0))
	_free_manager_restore_global_rng(mgr)
	return dur


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
	for i in range(ids.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp


# ── Entity manipulation ───────────────────────────────────────────────────

static func _harness_destroy_limb(entity: CoreEntity, part: String) -> void:
	entity.body_cutting[part] = 0.0
	entity.body_blunt[part] = 0.0
	if entity.bone_health.has(part):
		entity.bone_health[part] = 0.0


static func _harness_restore_limb(entity: CoreEntity, part: String) -> void:
	if not entity.body_max.has(part):
		return
	var mx: float = float(entity.body_max[part])
	entity.body_cutting[part] = mx
	entity.body_blunt[part] = mx
	if entity.bone_health.has(part) and entity.bone_max.has(part):
		entity.bone_health[part] = float(entity.bone_max[part])


# ── Counter-tempo helper ──────────────────────────────────────────────────

static func _harness_counter_tempo_set_incoming_progress(
	mgr: Node, attacker_id: int, fraction: float
) -> void:
	var atk: Dictionary = mgr._get_by_id(attacker_id)
	if atk == null:
		return
	var dur: float = float(atk.get("state_duration", 0.0))
	if dur <= 0.0:
		atk["state_duration"] = 1.0
		dur = 1.0
	atk["state_timer"] = clampf(fraction, 0.0, 1.0) * dur


# ── Guard-line helpers ────────────────────────────────────────────────────

static func _harness_cardinal_attack_line(cardinal: String) -> String:
	if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.normalize_line(cardinal)
	return cardinal


static func _harness_adjacent_lines_for(cardinal_attack: String) -> Array:
	var atk: String = _harness_cardinal_attack_line(cardinal_attack)
	var adj_src: Dictionary = (
		_GuardLines.LINE_ADJACENTS
		if CombatConstants.is_feature_hema_eight_guard_lines_enabled()
		else CombatConstants.LINE_ADJACENTS
	)
	var raw: Variant = adj_src.get(atk, [])
	return raw if raw is Array else []


static func _harness_opposite_cardinal(cardinal: String) -> String:
	if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		return _GuardLines.opposite_line(_harness_cardinal_attack_line(cardinal))
	match cardinal:
		"high":
			return "low"
		"low":
			return "high"
		"left":
			return "right"
		"right":
			return "left"
	return "low"


# ── Assertion helpers (depth polearm) ─────────────────────────────────────

static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
	mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
	for assume_open in [false, true]:
		for c in mgr.combatants:
			if not _EntityAccess.alive_bool(c):
				continue
			var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, c)
			var via_empty: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, c, "", null, assume_open)
			var via_fid: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, c, fid, null, assume_open)
			if via_empty != via_fid:
				_Harness._fail(
					failures,
					"%s assume=%s id=%d empty=%s explicit=%s fid=%s"
					% [ctx, str(assume_open), _EntityAccess.id_int(c), str(via_empty), str(via_fid), fid]
				)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
	## For non-depth-attack cases (rank 0 or no lane open), depth_polearm_attack
	## should be false — the stamping function sets it to false and returns early.
	if not bool(pa.get("depth_polearm_attack", false)):
		pass  # depth_polearm_attack=false — expected for non-depth attacks
	else:
		_Harness._fail(failures, "%s id=%d depth_polearm_attack=true (unexpected)" % [ctx, pa.get("attacker_id", -1)])


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var cid: int = _EntityAccess.id_int(c)
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		## Cache is `depth_polearm_allows_low_targets` (set by stamp_depth_flags_on_pa).
		## Builder derives the same value from depth_polearm_lane_type / allows_low.
		var cached_open: bool = bool(pa.get("depth_polearm_allows_low_targets", true))
		var builder_open: bool = _DefenseChoice._depth_polearm_lane_is_open(pa)
		if cached_open != builder_open:
			_Harness._fail(
				failures,
				"%s id=%d cache=%s builder=%s"
				% [ctx, cid, str(cached_open), str(builder_open)]
			)


# ── IV-7 / IV-8 / IV-9 fixtures ───────────────────────────────────────────

static func _harness_iv7_fixture_combatant(ent: CoreEntity) -> Dictionary:
	return {
		"stats": {"agility": 100},
		"stamina": CombatConstants.STAMINA_MAX,
		"guard": 1.0,
		"state": CombatConstants.STATE_WAITING,
		"node": ent,
	}


static func _harness_action_ready_resolve_at(mgr: Node, combatant_id: int) -> float:
	for ev in mgr.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var evt := ev as Dictionary
		if evt.get("type", "") == CombatConstants.EVENT_ACTION_READY:
			if evt.get("combatant_id") == combatant_id:
				return float(evt.get("resolve_at", -1.0))
	return -1.0


static func _harness_iv8_three_player_fixtures(mgr: Node) -> Array:
	var result: Array = []
	for _i in 3:
		result.append(_new_entity("SWORD"))
	for ent in result:
		mgr.register(ent, "player")
	return result


static func _harness_iv9_enemy_rank0_with_gaps(mgr: Node) -> Array:
	## Create a gapped enemy line: 4 files wide with only 3 entities, leaving file 0 empty.
	var enemies: Array = []
	for _i in 4:
		enemies.append(_new_entity("SWORD"))
	# Only register 3 so manager fills files [0,1,2]; then shift to [1,2,3] for gap at file 0.
	for i in range(3):
		mgr.register(enemies[i], "enemy")
	# Use equal-width sides (both 4) to avoid SKIRMISH mode which would block compaction.
	mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
	var slots: Dictionary = _FormationSlots.formation_slots_dict(mgr.formations["enemy"])
	var new_slots: Dictionary = {}
	# Shift all occupied rank-0 slots to file+1 (creating gap at file 0).
	# Slot keys are Vector2i(rank, file) — shift the .y (file) coordinate.
	for k in slots.keys():
		if not (k is Vector2i):
			continue
		var cell: Vector2i = k as Vector2i
		if cell.x != 0:
			continue
		var cid: Variant = slots[k]
		var new_key: Vector2i = Vector2i(cell.x, cell.y + 1)
		if cid is Array:
			new_slots[new_key] = cid.duplicate()
			for id_val in cid:
				if id_val is int and id_val >= 0:
					for c in mgr.combatants:
						if _EntityAccess.id_int(c) == id_val:
							c.file = cell.y + 1
							break
		elif cid is int and cid >= 0:
			new_slots[new_key] = [cid]
			for c in mgr.combatants:
				if _EntityAccess.id_int(c) == cid:
					c.file = cell.y + 1
					break
	mgr.formations["enemy"]["slots"] = new_slots
	_FormationSlots.normalize_formation_slots(mgr.formations["enemy"])
	var form_enemy: Dictionary = mgr.formations["enemy"]
	return [form_enemy]


static func _harness_iv9_player_rotate_file_listed(mgr: Node) -> bool:
	var p0: Dictionary = {}
	var p1: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "player"):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.file_int(c) == 0:
			p0 = c
		elif _EntityAccess.file_int(c) == 1:
			p1 = c
	if p0.is_empty() or p1.is_empty():
		return false
	p0["gauge"] = 100.0
	p1["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(p0))
	return not _ListedActions.first_action_move_vs_target(
		acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(p1)
	).is_empty()


static func _harness_iv9_center_rank0_can_melee_threaten(mgr: Node) -> bool:
	var p_center: Dictionary = {}
	var e_center: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.is_alive_on_side(c, "player") and _EntityAccess.file_int(c) == 1:
			p_center = c
		elif _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.file_int(c) == 1:
			e_center = c
	if p_center.is_empty() or e_center.is_empty():
		return false
	p_center["gauge"] = 100.0
	return _MeleeListing.can_melee_threaten(mgr, p_center, e_center)


static func _harness_iv9_gap_column_cache_matches_occupied(formation: Dictionary) -> bool:
	if not CombatConstants.is_feature_gap_column_topology_enabled():
		return not formation.has("gap_column_files")
	var cached: Variant = formation.get("gap_column_files", null)
	if cached is not Array:
		return false
	var live: Array = _FormationSlots.occupied_column_files(formation)
	return (cached as Array) == live


static func _harness_iv9_resolve_adjacent_rank_pair_move(
	mgr: Node, initiator_id: int, partner_id: int, move_kind: String
) -> void:
	_FormationFlow.start_pair_move(mgr, initiator_id, partner_id, move_kind)
	_FormationFlow.handle_swap_rank_resolve(
		mgr,
		{
			"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
			"combatant_id": initiator_id,
			"resolve_at": mgr.combat_clock,
			"data": {"partner_id": partner_id, "move_kind": move_kind},
		}
	)
