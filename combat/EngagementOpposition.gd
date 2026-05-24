class_name EngagementOpposition
extends RefCounted

## III-4 Track A: logical file opposition between independent side grids (center offset + nearest wing).
## Seeded once at combat start; **`CombatTargetScoring.is_file_opposed_rank0_pair`** delegates here (PR4).

const META_OPPOSITION_FILE_OFFSET_BY_SIDE := "_opposition_file_offset_by_side"

const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")


static func clear_opposition_meta(manager: Node) -> void:
	if manager != null and manager.has_meta(META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		manager.remove_meta(META_OPPOSITION_FILE_OFFSET_BY_SIDE)


static func _offset_dict(manager: Node) -> Dictionary:
	if manager == null or not manager.has_meta(META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		return {}
	var raw: Variant = manager.get_meta(META_OPPOSITION_FILE_OFFSET_BY_SIDE)
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func seed_from_formations(manager: Node) -> void:
	if manager == null:
		return
	clear_opposition_meta(manager)
	var forms: Variant = manager.get("formations")
	if forms == null or not forms is Dictionary:
		return
	var fd: Dictionary = forms as Dictionary
	if not fd.has("player") or not fd.has("enemy"):
		return
	var p_files: int = int((fd["player"] as Dictionary).get("files", 1))
	var e_files: int = int((fd["enemy"] as Dictionary).get("files", 1))
	var offset_player: int = int(floorf(float(p_files - e_files) / 2.0))
	manager.set_meta(
		META_OPPOSITION_FILE_OFFSET_BY_SIDE,
		{"player": offset_player, "enemy": -offset_player}
	)


static func opposition_file_offset(manager: Node, side: String) -> int:
	return int(_offset_dict(manager).get(str(side), 0))


static func _mapped_opposition_file_distance(actor_file: int, opp_file: int, actor_side_offset: int) -> int:
	return absi(actor_file - (opp_file + actor_side_offset))


## Minimum mapped distance from `ref` (rank-0) to any living rank-0 melee target; **999999** when none.
static func _min_mapped_opposition_distance(
	manager: Node, ref: Dictionary, actor_side_offset: int
) -> int:
	if manager == null or ref.is_empty():
		return 999999
	var actor_file: int = _EntityAccess.file_int(ref)
	var best: int = 999999
	for other in manager.combatants:
		if not _EntityAccess.is_living_hostile_to(ref, other):
			continue
		if not _MeleeRank.opp_matches_melee_rank_target(manager, ref, other, 0):
			continue
		best = mini(
			best,
			_mapped_opposition_file_distance(actor_file, _EntityAccess.file_int(other), actor_side_offset)
		)
	return best


## Track A **3a:** center pairs use strict `file == opp.file + offset`; wings use nearest rank-0 hostile by mapped distance.
static func is_mapped_file_opposed(manager: Node, actor: Dictionary, opp: Dictionary) -> bool:
	if manager == null:
		return false
	if _EntityAccess.rank_int(actor) != 0 or _EntityAccess.rank_int(opp) != 0:
		return false
	if not _EntityAccess.is_living_hostile_to(actor, opp):
		return false
	var offset: int = opposition_file_offset(manager, _EntityAccess.side_str(actor))
	var actor_file: int = _EntityAccess.file_int(actor)
	var opp_file: int = _EntityAccess.file_int(opp)
	if actor_file == opp_file + offset:
		return true
	var best: int = _min_mapped_opposition_distance(manager, actor, offset)
	if best >= 999999:
		return false
	return _mapped_opposition_file_distance(actor_file, opp_file, offset) == best


static func _depth_lane_open_resolved(
	manager: Node,
	actor: Dictionary,
	depth_lane_open_cache: Variant,
	zone_geometry_fid: String
) -> bool:
	if depth_lane_open_cache != null:
		return bool(depth_lane_open_cache)
	var fid: String = zone_geometry_fid
	if fid.is_empty():
		fid = _ZoneOfControl.zone_geometry_fid_str(manager, actor)
	return _DepthPolearm.depth_polearm_lane_open(manager, actor, fid)


## True when no enemy rank 0 is mapped-opposed to this fighter's reference rank-0 (self or same-file partner when depth lane open).
static func wing_lacks_mapped_opposition(
	manager: Node, actor: Dictionary, depth_lane_open_cache: Variant = null, zone_geometry_fid: String = ""
) -> bool:
	if manager == null:
		return false
	var ref: Dictionary = actor
	if _EntityAccess.rank_int(actor) != 0:
		if not _depth_lane_open_resolved(manager, actor, depth_lane_open_cache, zone_geometry_fid):
			return false
		var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(manager, actor, zone_geometry_fid)
		if front.is_empty():
			return false
		ref = front
	var offset: int = opposition_file_offset(manager, _EntityAccess.side_str(ref))
	var ref_file: int = _EntityAccess.file_int(ref)
	var best: int = _min_mapped_opposition_distance(manager, ref, offset)
	if best >= 999999:
		return true
	for opp in manager.combatants:
		if not _EntityAccess.is_living_hostile_to(actor, opp):
			continue
		if not _MeleeRank.opp_matches_melee_rank_target(manager, actor, opp, 0):
			continue
		if _EntityAccess.rank_int(opp) != 0:
			continue
		if _mapped_opposition_file_distance(ref_file, _EntityAccess.file_int(opp), offset) == best:
			return false
	return true
