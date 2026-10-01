class_name EngagementOpposition
extends RefCounted

## III-4 Track A: logical file opposition between independent side grids (center offset + nearest wing).
## Seeded once at combat start; **`CombatTargetScoring.is_file_opposed_rank0_pair`** delegates here (PR4).
const META_OPPOSITION_FILE_OFFSET_BY_SIDE := "_opposition_file_offset_by_side"
const NO_OPPONENT_DISTANCE := 999999


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
    var p_files: int = int((fd["player"] as Dictionary).get(DataKeys.FORMATION_FILES, 1))
    var e_files: int = int((fd["enemy"] as Dictionary).get(DataKeys.FORMATION_FILES, 1))
    var offset_player: int = int(floorf(float(p_files - e_files) / 2.0))
    manager.set_meta(META_OPPOSITION_FILE_OFFSET_BY_SIDE, {"player": offset_player, "enemy": -offset_player})


static func opposition_file_offset(manager: Node, side: String) -> int:
    return int(_offset_dict(manager).get(str(side), 0))


## Mapped file gap for reach/bands when Track A opposition applies (wings use nearest, not raw `|Δ--?file|`).
static func mapped_opposition_file_distance(manager: Node, actor: Dictionary, opp: Dictionary) -> int:
    if manager == null or actor.is_empty() or opp.is_empty():
        return absi(CombatantEntityAccess.file_int(actor) - CombatantEntityAccess.file_int(opp))
    var offset: int = opposition_file_offset(manager, CombatantEntityAccess.side_str(actor))
    return _mapped_opposition_file_distance(
        CombatantEntityAccess.file_int(actor), CombatantEntityAccess.file_int(opp), offset
    )


static func _mapped_opposition_file_distance(actor_file: int, opp_file: int, actor_side_offset: int) -> int:
    return absi(actor_file - (opp_file + actor_side_offset))


## Minimum mapped distance from `ref` (rank-0) to any living rank-0 melee target; **NO_OPPONENT_DISTANCE** when none.
static func _min_mapped_opposition_distance(manager: Node, ref: Dictionary, actor_side_offset: int) -> int:
    if manager == null or ref.is_empty():
        return NO_OPPONENT_DISTANCE
    var actor_file: int = CombatantEntityAccess.file_int(ref)
    var best: int = NO_OPPONENT_DISTANCE
    for other in manager.combatants:
        if not CombatantEntityAccess.is_living_hostile_to(ref, other):
            continue
        if not CombatMeleeRankTargeting.opp_matches_melee_rank_target(manager, ref, other, 0):
            continue
        best = mini(
            best, _mapped_opposition_file_distance(actor_file, CombatantEntityAccess.file_int(other), actor_side_offset)
        )
    return best


## Track A **3a:** center pairs use strict `file == opp.file + offset`; wings use nearest rank-0 hostile by mapped
## distance.
static func is_mapped_file_opposed(manager: Node, actor: Dictionary, opp: Dictionary) -> bool:
    if manager == null:
        return false
    if CombatantEntityAccess.rank_int(actor) != 0 or CombatantEntityAccess.rank_int(opp) != 0:
        return false
    if not CombatantEntityAccess.is_living_hostile_to(actor, opp):
        return false
    var offset: int = opposition_file_offset(manager, CombatantEntityAccess.side_str(actor))
    var actor_file: int = CombatantEntityAccess.file_int(actor)
    var opp_file: int = CombatantEntityAccess.file_int(opp)
    if actor_file == opp_file + offset:
        return true
    var best: int = _min_mapped_opposition_distance(manager, actor, offset)
    if best >= NO_OPPONENT_DISTANCE:
        return false
    return _mapped_opposition_file_distance(actor_file, opp_file, offset) == best


static func _depth_lane_open_resolved(
    manager: Node, actor: Dictionary, depth_lane_open_cache: Variant, zone_geometry_fid: String
) -> bool:
    if depth_lane_open_cache != null:
        return depth_lane_open_cache == true
    var fid: String = zone_geometry_fid
    if fid.is_empty():
        fid = ZoneOfControl.zone_geometry_fid_str(manager, actor)
    return CombatDepthPolearm.depth_polearm_lane_open(manager, actor, fid)


## True when no enemy rank 0 is mapped-opposed to this fighter's reference rank-0 (self or same-file partner when depth
## lane open).
static func wing_lacks_mapped_opposition(
    manager: Node, actor: Dictionary, depth_lane_open_cache: Variant = null, zone_geometry_fid: String = ""
) -> bool:
    if manager == null:
        return false
    var ref: Dictionary = actor
    if CombatantEntityAccess.rank_int(actor) != 0:
        if not _depth_lane_open_resolved(manager, actor, depth_lane_open_cache, zone_geometry_fid):
            return false
        var front: Dictionary = CombatDepthPolearm.same_file_living_rank0_ally(manager, actor, zone_geometry_fid)
        if front.is_empty():
            return false
        ref = front
    var offset: int = opposition_file_offset(manager, CombatantEntityAccess.side_str(ref))
    var ref_file: int = CombatantEntityAccess.file_int(ref)
    var best: int = _min_mapped_opposition_distance(manager, ref, offset)
    if best >= NO_OPPONENT_DISTANCE:
        return true
    for opp in manager.combatants:
        if not CombatantEntityAccess.is_living_hostile_to(actor, opp):
            continue
        if not CombatMeleeRankTargeting.opp_matches_melee_rank_target(manager, actor, opp, 0):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        if _mapped_opposition_file_distance(ref_file, CombatantEntityAccess.file_int(opp), offset) == best:
            return false
    return true


## Mapped rank-0 at **LONG** when weapon reach does not cover assigned foe →'s'--? bind close before strikes.
static func rank0_needs_bind_close_at_long(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty() or CombatantEntityAccess.rank_int(c) != 0:
        return false
    var attacker_id: int = CombatantEntityAccess.id_int(c)
    for opp in manager.combatants:
        if not CombatantEntityAccess.is_living_hostile_to(c, opp):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        if not is_mapped_file_opposed(manager, c, opp):
            continue
        var oid: int = CombatantEntityAccess.id_int(opp)
        var band: String = CombatantEntityAccess.distance_to_opponent_band(c, oid, "")
        if band != CombatConstants.DISTANCE_LONG:
            continue
        var eff: float = CombatPairGeometry.effective_pair_eff_dist(manager, c, opp)
        if CombatPairGeometry.melee_reach_covers_eff_dist(CombatantEntityAccess.weapon_melee_reach(c), eff):
            continue
        var blk: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "close_block_until_by_target_id")
        if not blk.is_empty():
            var until: Variant = blk.get(oid, -1.0)
            if CombatantEntityAccess.timestamp_cooldown_active(manager, float(until), -1.0):
                continue
        if not _defender_has_free_close_slot(manager, opp, attacker_id):
            continue
        return true
    return false


static func _defender_has_free_close_slot(manager: Node, defender: Dictionary, exclude_attacker_id: int) -> bool:
    var ctx: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, defender)
    var form_geom: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx)
    var density: String = (
        str(form_geom.get(DataKeys.FORMATION_DENSITY, "normal")) if not form_geom.is_empty() else "normal"
    )
    var cap: int = CombatConstants.max_close_slots_for_density(density)
    var defender_id: int = CombatantEntityAccess.id_int(defender)
    var n: int = 0
    for atk in manager.combatants:
        if not CombatantEntityAccess.alive_bool(atk):
            continue
        if CombatantEntityAccess.id_int(atk) == exclude_attacker_id:
            continue
        if CombatantEntityAccess.distance_to_opponent_band(atk, defender_id) == CombatConstants.DISTANCE_CLOSE:
            n += 1
    return n < cap
