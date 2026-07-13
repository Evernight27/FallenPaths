class_name ZoneOfControl
extends RefCounted

## Phase 4: Zone of control per formation (front, left_flank, right_flank, rear).
## Footing boundary: **`get_footing_duration_multiplier`** / **`get_lane_and_footing_duration_multiplier`**  -
## formation lane step-over **duration** only; **not** blade **`guard_line`**, PA, or **`weapon_form`**. LIVE_PATHS
## **`#wf-footing-terminology`** '. **`#wf-layer-labels`**.
## Control 0..1 from alive/capacity, casualties in slots, and cross-zone support.
## **`assign_combatant_zones`**, **`count_alive_in_zone`** (zone strength), and ZoC **engagement parry** use
## **`zone_geometry_for_combatant`** / **`zone_geometry_fid_str`** (home **`formation_id`**).
## ZoC / engagement  -  docs/LIVE_PATHS.md#tier-1-spec.
##
## Zone geometry API (home **`formation_id`** only):
## - **`zone_geometry_fid_str`** / **`formation_for_combatant_cached`**
## - One resolve: **`zone_geometry_line_context`** --'??'' **`zone_geometry_fid_from_pack`** /
## **`zone_geometry_formation_from_pack`**
## - Per-pass cache: **`zone_geometry_line_context_by_combatant_id`**
## - Pair: **`zone_geometry_for_pair`** + **`zone_geometry_*_from_pair_pack`**
## - Snapshot/UI row: **`zone_geometry_fid_from_row`**
## Aliases: **`formation_id_for_zone_geometry`**, **`formation_dict_for_zone_geometry`**.

const ZONE_FRONT := "front"
const ZONE_LEFT_FLANK := "left_flank"
const ZONE_RIGHT_FLANK := "right_flank"
const ZONE_REAR := "rear"
## Same value as CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE (encounter dict key).
const _ENCOUNTER_PROTECTION_CIRCLE_KEY := "protection_circle_active"
# Runtime preload ''''" circular dependency (EngagementOpposition preloads ZoneOfControl).
static var _opposition_cache: Variant = null


static func _get_opposition() -> GDScript:
    if _opposition_cache == null:
        _opposition_cache = load("res://combat/EngagementOpposition.gd")
    return _opposition_cache


static func all_zones() -> Array:
    return [ZONE_FRONT, ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK, ZONE_REAR]


## When false, flank/rear parry mods and ZoC-based mid-reach extension do not apply (encounter flag).
static func is_zoc_flanking_enabled(manager: Node) -> bool:
    if manager == null:
        return true
    var enc: Variant = manager.get("encounter")
    if enc is not Dictionary:
        return true
    return not enc.get(_ENCOUNTER_PROTECTION_CIRCLE_KEY, false)


static func _resolve_zone_geometry_fid(_manager: Node, c: Dictionary) -> String:
    return CombatantEntityAccess.formation_id_str(c)


static func formation_id_for_zone_geometry(manager: Node, c: Dictionary) -> String:
    return _resolve_zone_geometry_fid(manager, c)


## Read-only: **`manager.formations[fid]`** for zone geometry on **`combatant`**. `{}` if missing.
## When **`zone_geometry_fid`** is non-empty, it must match **`_resolve_zone_geometry_fid`** (skips a second
## resolution).
static func formation_dict_for_zone_geometry(
    manager: Node, combatant: Dictionary, zone_geometry_fid: String = ""
) -> Dictionary:
    return zone_geometry_formation_from_pack(zone_geometry_for_combatant(manager, combatant, zone_geometry_fid))


## Resolved host-line **`fid`** + formation record for one combatant (**`zone_geometry_fid`** optional cache).
static func zone_geometry_for_combatant(
    manager: Node, combatant: Dictionary, zone_geometry_fid: String = ""
) -> Dictionary:
    if manager == null or combatant.is_empty():
        return {"fid": "", "formation": {}}
    var fid: String = (
        zone_geometry_fid if not zone_geometry_fid.is_empty() else _resolve_zone_geometry_fid(manager, combatant)
    )
    if fid.is_empty():
        return {"fid": "", "formation": {}}
    return {
        "fid": fid,
        "formation": FormationSlots.formation_record_for_manager(manager, fid),
    }


## Pair snapshot for geometry, ZoC, and targeting (**`zone_geometry_fid_*`** optional caches).
static func zone_geometry_for_pair(
    manager: Node, a: Dictionary, b: Dictionary, zone_geometry_fid_a: String = "", zone_geometry_fid_b: String = ""
) -> Dictionary:
    var za: Dictionary = zone_geometry_for_combatant(manager, a, zone_geometry_fid_a)
    var zb: Dictionary = zone_geometry_for_combatant(manager, b, zone_geometry_fid_b)
    return {
        "fid_a": zone_geometry_fid_from_pack(za),
        "formation_a": zone_geometry_formation_from_pack(za),
        "fid_b": zone_geometry_fid_from_pack(zb),
        "formation_b": zone_geometry_formation_from_pack(zb),
    }


## Read **`zone_geometry_for_pair`** packs (no re-resolve).
static func zone_geometry_fid_a_from_pair_pack(zg: Dictionary) -> String:
    return zg.get("fid_a", "")


static func zone_geometry_fid_b_from_pair_pack(zg: Dictionary) -> String:
    return zg.get("fid_b", "")


static func zone_geometry_formation_a_from_pair_pack(zg: Dictionary) -> Dictionary:
    var f: Variant = zg.get("formation_a", null)
    return f as Dictionary if f is Dictionary else {}


static func zone_geometry_formation_b_from_pair_pack(zg: Dictionary) -> Dictionary:
    var f: Variant = zg.get("formation_b", null)
    return f as Dictionary if f is Dictionary else {}


## Opponent formation from per-id line cache, then pair fallback. When pair fallback runs and **`actor_fc`** is empty,
## fills it from **`formation_a`** (MeleeListing actor cache backfill).
static func opponent_formation_for_listing(
    manager: Node,
    actor: Dictionary,
    opp: Dictionary,
    zone_geometry_by_combatant_id: Dictionary,
    actor_fc: Dictionary = {}
) -> Dictionary:
    var opp_id: int = CombatantEntityAccess.id_int(opp)
    var opp_pack: Variant = zone_geometry_by_combatant_id.get(opp_id, null)
    var fo: Dictionary = zone_geometry_formation_from_pack(opp_pack) if opp_pack is Dictionary else {}
    if not fo.is_empty():
        return fo
    var pair_zg: Dictionary = zone_geometry_for_pair(manager, actor, opp)
    fo = zone_geometry_formation_b_from_pair_pack(pair_zg)
    if actor_fc.is_empty():
        var fa: Dictionary = zone_geometry_formation_a_from_pair_pack(pair_zg)
        for k in fa.keys():
            actor_fc[k] = fa[k]
    return fo


## **`fid`** + **`formation`** for one combatant (single **`zone_geometry_for_combatant`** resolve).
## Same key layout as that pack  -  use **`zone_geometry_fid_from_pack`** / **`zone_geometry_formation_from_pack`** on
## the result.
static func zone_geometry_line_context(
    manager: Node, combatant: Dictionary, zone_geometry_fid: String = ""
) -> Dictionary:
    var zg: Dictionary = zone_geometry_for_combatant(manager, combatant, zone_geometry_fid)
    return {
        "fid": zone_geometry_fid_from_pack(zg),
        "formation": zone_geometry_formation_from_pack(zg),
    }


## One **`zone_geometry_line_context`** per alive combatant id (O(n) band/listing pass cache).
static func zone_geometry_line_context_by_combatant_id(manager: Node) -> Dictionary:
    var out: Dictionary = {}
    if manager == null:
        return out
    for cc in manager.combatants:
        if not CombatantEntityAccess.alive_bool(cc):
            continue
        out[CombatantEntityAccess.id_int(cc)] = zone_geometry_line_context(manager, cc)
    return out


## Formation record: use **`formation_cache`** when already resolved; else **`zone_geometry_for_combatant`**.
static func formation_for_combatant_cached(
    manager: Node, combatant: Dictionary, formation_cache: Variant = null, zone_geometry_fid: String = ""
) -> Dictionary:
    if formation_cache is Dictionary:
        return formation_cache
    var zg: Dictionary = zone_geometry_for_combatant(manager, combatant, zone_geometry_fid)
    var f: Variant = zg.get("formation", null)
    if f is Dictionary:
        return f
    return {}


## Resolved host-line formation id (**`zone_geometry_fid`** optional cache). Does not load **`formations[fid]`**.
static func zone_geometry_fid_str(manager: Node, combatant: Dictionary, zone_geometry_fid: String = "") -> String:
    if not zone_geometry_fid.is_empty():
        return zone_geometry_fid
    if manager == null or combatant.is_empty():
        return ""
    return _resolve_zone_geometry_fid(manager, combatant)


## Snapshot **`zone_geometry_fid`** when stamped; else **`zone_geometry_fid_str`** (or home **`formation_id`** if no
## manager).
static func zone_geometry_fid_from_row(manager: Node, combatant: Dictionary) -> String:
    var z: String = combatant.get("zone_geometry_fid", "").strip_edges()
    if not z.is_empty():
        return z
    if manager != null and not combatant.is_empty():
        return zone_geometry_fid_str(manager, combatant)
    return CombatantEntityAccess.formation_id_str(combatant)


## **`fid`** / **`formation`** from an existing **`zone_geometry_for_combatant`** pack (no re-resolve).
static func zone_geometry_fid_from_pack(zg: Dictionary) -> String:
    return zg.get("fid", "")


static func zone_geometry_formation_from_pack(zg: Dictionary) -> Dictionary:
    var f: Variant = zg.get("formation", null)
    return f as Dictionary if f is Dictionary else {}


## True when **`combatant`**'s zone-geometry **`fid`** equals **`fid`**.
static func combatant_on_zone_geometry_fid(manager: Node, combatant: Dictionary, fid: String) -> bool:
    if fid.is_empty() or combatant.is_empty():
        return false
    return zone_geometry_fid_from_row(manager, combatant) == fid


## Rank 0: front center, left/right edge, or whole front when files==1. Rank 1+: rear.
static func zone_for_cell(files: int, _ranks: int, rank: int, file: int) -> String:
    if rank > 0:
        return ZONE_REAR
    if files <= 1:
        return ZONE_FRONT
    if file == 0:
        return ZONE_LEFT_FLANK
    if file == files - 1:
        return ZONE_RIGHT_FLANK
    return ZONE_FRONT


## Alive combatants whose **zone geometry** formation is `fid` (home `formation_id`), in `zone`.
static func count_alive_in_zone(manager: Node, fid: String, zone: String) -> int:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return 0
    var files: int = formation.get("files", 1)
    var ranks: int = formation.get("ranks", 1)
    var n: int = 0
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if not combatant_on_zone_geometry_fid(manager, c, fid):
            continue
        if zone_for_cell(files, ranks, CombatantEntityAccess.rank_int(c), CombatantEntityAccess.file_int(c)) == zone:
            n += 1
    return n


static func _obstacle_count_in_zone(manager: Node, fid: String, zone: String) -> int:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return 0
    var files: int = formation.get("files", 1)
    var ranks: int = formation.get("ranks", 1)
    var obstacles: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "slot_obstacles")
    var total: int = 0
    for key in obstacles:
        if not key is Vector2i:
            continue
        var ri: int = key.x
        var fi: int = key.y
        if zone_for_cell(files, ranks, ri, fi) == zone:
            var oc: Variant = obstacles[key]
            if oc is Array:
                total += (oc as Array).size()
    return total


static func _capacity_for_zone(files: int, ranks: int, zone: String) -> int:
    match zone:
        ZONE_REAR:
            if ranks <= 1:
                return 1
            return maxi(1, (ranks - 1) * files)
        ZONE_FRONT:
            if files <= 1:
                return maxi(1, ranks)
            if files == 2:
                return 1
            return maxi(1, (files - 2) * ranks)
        ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK:
            return maxi(1, ranks)
        _:
            return 1


static func _raw_zone_strength(manager: Node, fid: String, zone: String) -> float:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return 0.0
    var files: int = formation.get("files", 1)
    var ranks: int = formation.get("ranks", 1)
    var alive_n: float
    var cap: float
    if zone == ZONE_FRONT and files == 2:
        var l: float = float(count_alive_in_zone(manager, fid, ZONE_LEFT_FLANK))
        var r: float = float(count_alive_in_zone(manager, fid, ZONE_RIGHT_FLANK))
        alive_n = (l + r) * 0.5
        cap = float(maxi(1, ranks))
    else:
        alive_n = float(count_alive_in_zone(manager, fid, zone))
        cap = float(_capacity_for_zone(files, ranks, zone))
    var base: float = alive_n / maxf(1.0, cap)
    var obs: float = float(_obstacle_count_in_zone(manager, fid, zone))
    var obs_pen: float = minf(0.55, float(CombatConstants.ZOC_CASUALTY_PER_BODY) * obs)
    var max_p: float = CombatConstants.INCURSION_PRESSURE_MAX
    var inc_g: float = clampf(formation.get("incursion_pressure", 0.0), 0.0, max_p)
    var lane_z: float = _lane_stress_for_zone(formation, zone)
    var scaled_lane: float = lane_z * max_p
    var headroom: float = 0.0
    if max_p > 0.0001:
        headroom = 1.0 - (inc_g / max_p)
    var lane_add: float = scaled_lane * headroom * CombatConstants.INCURSION_LANE_HEADROOM_FACTOR
    var inc_combined: float = clampf(inc_g + lane_add, 0.0, max_p)
    var exposure: float = _zone_incursion_exposure(zone)
    var inc_pen: float = inc_combined * CombatConstants.ZOC_INCURSION_ZONE_PENALTY * exposure
    return maxf(0.0, base - obs_pen - inc_pen)


## 0..1 per-file lane stress. Written by TacticalCombat (dual living, density); ZoC reads it here  -  not bodies (see
## obs_pen).
static func _lane_stress_for_zone(formation: Dictionary, zone: String) -> float:
    var ls: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "lane_stress_by_file")
    if ls.is_empty():
        return 0.0
    var files: int = maxi(1, formation.get("files", 1))
    match zone:
        ZONE_LEFT_FLANK:
            return ls.get(0, 0.0)
        ZONE_RIGHT_FLANK:
            return ls.get(files - 1, 0.0)
        ZONE_FRONT:
            if files <= 1:
                return ls.get(0, 0.0)
            if files == 2:
                return (ls.get(0, 0.0) + ls.get(1, 0.0)) * 0.5
            var sum: float = 0.0
            var n: int = 0
            for f in range(1, files - 1):
                sum += ls.get(f, 0.0)
                n += 1
            return sum / maxi(1, n)
        ZONE_REAR:
            var mx: float = 0.0
            for f in range(files):
                mx = maxf(mx, ls.get(f, 0.0))
            return mx
        _:
            return 0.0


static func _zone_incursion_exposure(zone: String) -> float:
    match zone:
        ZONE_FRONT:
            return CombatConstants.ZOC_INCURSION_EXPOSURE_FRONT
        ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK:
            return CombatConstants.ZOC_INCURSION_EXPOSURE_FLANK
        ZONE_REAR:
            return CombatConstants.ZOC_INCURSION_EXPOSURE_REAR
        _:
            return 1.0


## Mutates formations[*].zone_control with keys front, left_flank, right_flank, rear (0..1).
static func recompute_zone_control(manager: Node) -> void:
    for fid in ["player", "enemy"]:
        var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if formation.is_empty():
            continue
        var base: Dictionary = {}
        for z in all_zones():
            base[z] = _raw_zone_strength(manager, fid, z)
        var f: float = base.get(ZONE_FRONT, 0.0)
        var l: float = base.get(ZONE_LEFT_FLANK, 0.0)
        var r: float = base.get(ZONE_RIGHT_FLANK, 0.0)
        var rr: float = base.get(ZONE_REAR, 0.0)
        var k_ff: float = CombatConstants.ZOC_FRONT_SUPPORT_TO_FLANK
        var k_fr: float = CombatConstants.ZOC_FLANK_SUPPORT_TO_FRONT
        var k_rf: float = CombatConstants.ZOC_REAR_SUPPORT_FROM_FRONT
        var adj_l: float = clampf(l + k_ff * f, 0.0, 1.0)
        var adj_r: float = clampf(r + k_ff * f, 0.0, 1.0)
        var adj_f: float = clampf(f + k_fr * (l + r) * 0.5, 0.0, 1.0)
        var adj_rr: float = clampf(rr + k_rf * f, 0.0, 1.0)
        formation["zone_control"] = {
            ZONE_FRONT: adj_f,
            ZONE_LEFT_FLANK: adj_l,
            ZONE_RIGHT_FLANK: adj_r,
            ZONE_REAR: adj_rr,
        }


static func assign_combatant_zones(manager: Node) -> void:
    for c in manager.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        # Intruders use host formation grid (`rank`/`file` on defender slots); home `formation_id` stays roster side.
        var formation: Dictionary = formation_for_combatant_cached(manager, c, null)
        if formation.is_empty():
            c["zone_id"] = ""
            c["occupied_zone_id"] = ""
            continue
        var files: int = formation.get("files", 1)
        var ranks: int = formation.get("ranks", 1)
        var zid: String = zone_for_cell(
            files, ranks, CombatantEntityAccess.rank_int(c), CombatantEntityAccess.file_int(c)
        )
        c["zone_id"] = zid
        c["occupied_zone_id"] = zid


static func recompute_all(manager: Node) -> void:
    recompute_zone_control(manager)
    assign_combatant_zones(manager)


## One-line UI/debug: zone strengths 0..1, or protection-circle notice.
static func format_zone_control_line(manager: Node, _side: String) -> String:
    if manager == null:
        return ""
    if not is_zoc_flanking_enabled(manager):
        return "ZoC: off (protection circle)"
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, _side)
    var zc: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "zone_control")
    if zc.is_empty():
        return ""
    var f: float = zc.get(ZONE_FRONT, 0.0)
    var l: float = zc.get(ZONE_LEFT_FLANK, 0.0)
    var r: float = zc.get(ZONE_RIGHT_FLANK, 0.0)
    var rr: float = zc.get(ZONE_REAR, 0.0)
    return "ZoC  F:%.2f  L:%.2f  R:%.2f  rear:%.2f" % [f, l, r, rr]


## Formation vs formation (both files >= 2): ZoC-based flank/rear parry mult on defender.
## Otherwise pack-style fallback: effective file spacing (wedge/lane_offset-aware) --'''deg''
## `PARRY_FLANK_EFFECTIVE_FILES_MIN`, else |fA1/2'"file| --'''deg'' 2 (Tier 3.1).
static func get_engagement_parry_multiplier(manager: Node, attacker_id: int, defender_id: int) -> float:
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    if atk.is_empty() or tgt.is_empty():
        return 1.0
    if not is_zoc_flanking_enabled(manager):
        return _engagement_parry_mult_pack_fallback(manager, atk, tgt)
    if not CombatantEntityAccess.is_alive_opponent_of(atk, tgt):
        return _engagement_parry_mult_pack_fallback(manager, atk, tgt)
    var zg: Dictionary = zone_geometry_for_pair(manager, atk, tgt)
    var fa: Dictionary = zone_geometry_formation_a_from_pair_pack(zg)
    var fd: Dictionary = zone_geometry_formation_b_from_pair_pack(zg)
    if _zoc_pair_uses_wide_line_geometry(fa, fd):
        return _engagement_parry_mult_zoc(manager, tgt, fd)
    return _engagement_parry_mult_pack_fallback(manager, atk, tgt, fa, fd)


static func _zoc_pair_uses_wide_line_geometry(f_atk: Dictionary, f_def: Dictionary) -> bool:
    if f_atk.is_empty() or f_def.is_empty():
        return false
    return f_atk.get("files", 1) >= 2 and f_def.get("files", 1) >= 2


static func _engagement_parry_mult_zoc(_manager: Node, defender: Dictionary, defender_formation: Dictionary) -> float:
    var formation: Dictionary = defender_formation
    if formation.is_empty():
        return 1.0
    var zc: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "zone_control")
    var files: int = formation.get("files", 1)
    var fd: int = CombatantEntityAccess.file_int(defender)
    var rank: int = CombatantEntityAccess.rank_int(defender)
    var thresh: float = CombatConstants.ZOC_ACCESS_THRESHOLD
    if zc.get(ZONE_REAR, 1.0) < thresh and rank == 0:
        return CombatConstants.REAR_PARRY_MOD
    if zc.get(ZONE_LEFT_FLANK, 1.0) < thresh and fd == 0:
        return CombatConstants.FLANK_PARRY_MOD
    if zc.get(ZONE_RIGHT_FLANK, 1.0) < thresh and fd == files - 1:
        return CombatConstants.FLANK_PARRY_MOD
    return 1.0


static func _engagement_parry_mult_pack_fallback(
    manager: Node,
    atk: Dictionary,
    tgt: Dictionary,
    formation_atk_cache: Variant = null,
    formation_def_cache: Variant = null
) -> float:
    if manager != null:
        # Runtime load ''''" circular dependency (CombatPairGeometry preloads ZoneOfControl).
        var pg: Variant = load("res://combat/CombatPairGeometry.gd")
        if pg != null:
            var eff: float = pg.effective_pair_file_spacing_equivalent(
                manager, atk, tgt, formation_atk_cache, formation_def_cache
            )
            if eff + 1e-4 >= CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN:
                return CombatConstants.FLANK_PARRY_MOD
    var df: int = int(absf(float(CombatantEntityAccess.file_int(atk) - CombatantEntityAccess.file_int(tgt))))
    if df >= 2:
        return CombatConstants.FLANK_PARRY_MOD
    return 1.0


## Scales geometric separation for engagement (weak front lines = compressed distance feel). 1.0 at full control.
## Note: mid_reach_files() also reacts to weak fronts (extra file of mid band)  -  intentional layered tuning, not
## duplicate math.
static func geometric_reach_extent_multiplier(
    manager: Node,
    our: Dictionary,
    opp: Dictionary,
    our_formation_cache: Variant = null,
    opp_formation_cache: Variant = null
) -> float:
    if not is_zoc_flanking_enabled(manager):
        return 1.0
    var fo: Dictionary = formation_for_combatant_cached(manager, our, our_formation_cache)
    var fe: Dictionary = formation_for_combatant_cached(manager, opp, opp_formation_cache)
    if fo.is_empty() or fe.is_empty():
        return 1.0
    if fo.get("files", 1) < 2 or fe.get("files", 1) < 2:
        return 1.0
    var wp: float = FormationSlots.formation_nested_dictionary_read(fo, "zone_control").get(ZONE_FRONT, 1.0)
    var we: float = FormationSlots.formation_nested_dictionary_read(fe, "zone_control").get(ZONE_FRONT, 1.0)
    var m: float = minf(wp, we)
    return lerpf(CombatConstants.ZOC_GEOMETRIC_EXTENT_MIN, 1.0, m)


## IV-13: long weapons gain virtual reach when front ZoC is weak (wide lines; listing/threaten only).
static func weapon_reach_zoc_bonus_m(manager: Node, attacker: Dictionary, defender: Dictionary) -> float:
    if not CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled():
        return 0.0
    if manager == null or attacker.is_empty() or defender.is_empty():
        return 0.0
    if not is_zoc_flanking_enabled(manager):
        return 0.0
    var fa: Dictionary = formation_for_combatant_cached(manager, attacker, null)
    var fb: Dictionary = formation_for_combatant_cached(manager, defender, null)
    if fa.is_empty() or fb.is_empty():
        return 0.0
    if int(fa.get("files", 1)) < 2 or int(fb.get("files", 1)) < 2:
        return 0.0
    var wp: float = float(FormationSlots.formation_nested_dictionary_read(fa, "zone_control").get(ZONE_FRONT, 1.0))
    var we: float = float(FormationSlots.formation_nested_dictionary_read(fb, "zone_control").get(ZONE_FRONT, 1.0))
    var weak_front: float = minf(wp, we)
    var weak_max: float = float(CombatConstants.IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX)
    if weak_front >= weak_max:
        return 0.0
    var reach: float = CombatantEntityAccess.weapon_melee_reach(attacker, CombatConstants.IV13_WEAPON_REACH_ZOC_REF_M)
    var ref_m: float = float(CombatConstants.IV13_WEAPON_REACH_ZOC_REF_M)
    var span_m: float = maxf(0.01, float(CombatConstants.IV13_WEAPON_REACH_ZOC_SPAN_M))
    var reach_t: float = clampf((reach - ref_m) / span_m, 0.0, 1.0)
    var weak_t: float = clampf(1.0 - weak_front / maxf(0.01, weak_max), 0.0, 1.0)
    return reach_t * weak_t * float(CombatConstants.IV13_WEAPON_REACH_ZOC_MAX_BONUS_M)


## When both sides have wide lines, allow mid band one file farther if either front zone is weak.
static func mid_reach_files(
    manager: Node,
    our: Dictionary,
    opp: Dictionary,
    our_formation_cache: Variant = null,
    opp_formation_cache: Variant = null
) -> int:
    if not is_zoc_flanking_enabled(manager):
        return 1
    var fo: Dictionary = formation_for_combatant_cached(manager, our, our_formation_cache)
    var fe: Dictionary = formation_for_combatant_cached(manager, opp, opp_formation_cache)
    if fo.is_empty() or fe.is_empty():
        return 1
    if fo.get("files", 1) < 2 or fe.get("files", 1) < 2:
        return 1
    var wp: float = FormationSlots.formation_nested_dictionary_read(fo, "zone_control").get(ZONE_FRONT, 1.0)
    var we: float = FormationSlots.formation_nested_dictionary_read(fe, "zone_control").get(ZONE_FRONT, 1.0)
    if minf(wp, we) < CombatConstants.ZOC_ACCESS_THRESHOLD:
        return 2
    return 1


## Phase 5: Swap rank / fall-back duration  -  lane clarity (bodies, density). See
## MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION f''s'Sec2.3.
static func get_swap_lane_duration_multiplier(manager: Node, fid: String, file: int) -> float:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return CombatConstants.LANE_MOD_CLEAR
    var ranks: int = formation.get("ranks", 1)
    var obstacles: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "slot_obstacles")
    var obs_here: int = 0
    var key0 := Vector2i(0, file)
    var key1 := Vector2i(1, file)
    if obstacles.has(key0) and obstacles[key0] is Array:
        obs_here += (obstacles[key0] as Array).size()
    if ranks > 1 and obstacles.has(key1) and obstacles[key1] is Array:
        obs_here += (obstacles[key1] as Array).size()
    var lane: float = CombatConstants.LANE_MOD_CLEAR
    if obs_here >= 2:
        lane = CombatConstants.LANE_MOD_BLOCKED
    elif obs_here >= 1:
        lane = CombatConstants.LANE_MOD_CROWDED
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    if FormationSlots.living_count_in_slot(manager, slots, key0) >= 2:
        lane = maxf(lane, CombatConstants.LANE_MOD_CROWDED)
    if ranks > 1 and FormationSlots.living_count_in_slot(manager, slots, key1) >= 2:
        lane = maxf(lane, CombatConstants.LANE_MOD_CROWDED)
    var density: String = formation.get("density", "normal")
    if density == "tight":
        lane *= 1.1
    elif density == "loose":
        lane *= 0.95
    return lane


## Phase 5: Opponent pressure on this formation  -  aggressive front line slows disengage. See investigation
## f''s'Sec2.4.
static func _opponent_front_rank_pressure_scan(manager: Node, fid: String) -> Dictionary:
    var out: Dictionary = {
        "front_count": 0,
        "ratio_sum": 0.0,
        "aggressive": false,
        "all_defensive": true,
        "controlling_disengage_mult": 1.0,
    }
    if manager == null or fid.is_empty():
        return out
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return out
    var our_side: String = FormationSlots.formation_side_str(formation)
    if our_side.is_empty():
        return out
    var opp_side: String = CombatantEntityAccess.opponent_side_label(our_side)
    for c in manager.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, opp_side):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        out["front_count"] = int(out["front_count"]) + 1
        var st_ratio: float = CombatantEntityAccess.stamina_ratio(c)
        out["ratio_sum"] = float(out["ratio_sum"]) + st_ratio
        var st: String = CombatantEntityAccess.state_str(c)
        if st == CombatConstants.STATE_WIND_UP or st == CombatConstants.STATE_RECOVERING:
            out["aggressive"] = true
            out["all_defensive"] = false
        var stance: String = CombatantEntityAccess.form_str(c)
        if (
            CombatWeaponForm.pressure_class_is(stance, "aggressive")
            and st_ratio >= CombatConstants.STANCE_MIN_STAMINA_AGGRESSIVE_RATIO
        ):
            out["aggressive"] = true
        if not CombatWeaponForm.pressure_class_is(stance, "defensive"):
            out["all_defensive"] = false
        if CombatWeaponForm.controlling_pressure_active(c):
            out["controlling_disengage_mult"] = maxf(
                float(out["controlling_disengage_mult"]), CombatWeaponForm.opponent_disengage_pressure_mult(stance)
            )
    return out


## Max rank-0 opponent **`controlling`** disengage duration factor (1.0 or **`1/STANCE_MOD_OPPONENT_DISENGAGE`**).
static func get_opponent_controlling_disengage_pressure_mult(manager: Node, fid: String) -> float:
    return float(_opponent_front_rank_pressure_scan(manager, fid).get("controlling_disengage_mult", 1.0))


static func get_opponent_pressure_duration_multiplier(manager: Node, fid: String) -> float:
    var scan: Dictionary = _opponent_front_rank_pressure_scan(manager, fid)
    var front_count: int = scan.get("front_count", 0)
    if front_count == 0:
        return CombatConstants.PRESSURE_MOD_DEFENSIVE
    var base_mod: float
    if scan.get("aggressive", false):
        base_mod = CombatConstants.PRESSURE_MOD_AGGRESSIVE
    else:
        var avg_ratio: float = scan.get("ratio_sum", 0.0) / front_count
        if scan.get("all_defensive", false) or avg_ratio < CombatConstants.OPPONENT_PRESSURE_DEFENSIVE_STAMINA_RATIO:
            base_mod = CombatConstants.PRESSURE_MOD_DEFENSIVE
        else:
            base_mod = CombatConstants.PRESSURE_MOD_NEUTRAL
    return base_mod * scan.get("controlling_disengage_mult", 1.0)


## Phase 5: Step over fallen  -  extra duration when slot_obstacles (bodies) in this file column.
## **Not** weapon-form / guard / PA footwork  -  formation lane duration only. LIVE_PATHS terminology table '.
## **`#wf-layer-labels`** (Formation lane footing).
static func get_footing_duration_multiplier(manager: Node, fid: String, file: int) -> float:
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return 1.0
    var ranks: int = formation.get("ranks", 1)
    var obstacles: Dictionary = FormationSlots.formation_nested_dictionary_read(formation, "slot_obstacles")
    var total: int = 0
    for r in range(ranks):
        var k := Vector2i(r, file)
        if obstacles.has(k) and obstacles[k] is Array:
            total += (obstacles[k] as Array).size()
    if total <= 0:
        return 1.0
    var t: float = clampf(float(total) / 4.0, 0.0, 1.0)
    return lerpf(CombatConstants.FOOTING_STEP_OVER_MIN, CombatConstants.FOOTING_STEP_OVER_MAX, t)


## Lane - -  footing (pressure applied in CombatManager). Used for swap / fall back / rotate duration.
static func get_lane_and_footing_duration_multiplier(manager: Node, fid: String, file: int) -> float:
    return get_swap_lane_duration_multiplier(manager, fid, file) * get_footing_duration_multiplier(manager, fid, file)


## MS-L9: positional awareness  -  check if a combatant is surrounded by hostiles on --'''deg''2 directions.
## Front + (left_flank OR right_flank) = surrounded. Rear excluded by design.
## All hostile combatants are treated as front-line pressure (rank-0 assumption for cross-formation).
## Same-fid intruders count as front pressure (they've breached our line).
static func is_combatant_surrounded(manager: Node, combatant_id: int) -> bool:
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return false
    var my_zg: Dictionary = zone_geometry_for_combatant(manager, c)
    var my_fid: String = zone_geometry_fid_from_pack(my_zg)
    var my_formation: Dictionary = zone_geometry_formation_from_pack(my_zg)
    if my_formation.is_empty():
        return false
    var hostile_zones: Array = [false, false, false]  # front, left_flank, right_flank
    for other in manager.combatants:
        if other is not Dictionary:
            continue
        var o: Dictionary = other
        if not CombatantEntityAccess.alive_bool(o):
            continue
        if CombatantEntityAccess.side_str(o) == CombatantEntityAccess.side_str(c):
            continue
        var other_zg: Dictionary = zone_geometry_for_combatant(manager, o)
        var other_fid: String = zone_geometry_fid_from_pack(other_zg)
        # Same formation: intruders on our grid count as front pressure.
        if other_fid == my_fid:
            hostile_zones[0] = true
        # Different formation: use opposition offset to determine relative position.
        else:
            var opp_offset: int = _get_opposition().opposition_file_offset(manager, CombatantEntityAccess.side_str(o))
            var my_files: int = int(my_formation.get("files", 1))
            var other_file: int = CombatantEntityAccess.file_int(o)
            var mapped_file: int = other_file + opp_offset
            # Flank pressure only when formation has --'''deg''2 files.
            if my_files >= 2:
                # If mapped file is at or beyond our left edge --'??'' left flank pressure.
                if mapped_file <= 0:
                    hostile_zones[1] = true
                # If mapped file is at or beyond our right edge --'??'' right flank pressure.
                elif mapped_file >= my_files - 1:
                    hostile_zones[2] = true
                # Otherwise hostile is in front band.
                else:
                    hostile_zones[0] = true
            else:
                # Single-file formation: all cross-formation hostiles are front.
                hostile_zones[0] = true
    return hostile_zones.count(true) >= 2
