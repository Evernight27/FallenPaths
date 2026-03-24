class_name ZoneOfControl
extends RefCounted

## Phase 4: Zone of control per formation (front, left_flank, right_flank, rear).
## Control 0..1 from alive/capacity, casualties in slots, and cross-zone support.
## See docs/IMPLEMENTATION_OUTLINE.md Phase 4.

const ZONE_FRONT := "front"
const ZONE_LEFT_FLANK := "left_flank"
const ZONE_RIGHT_FLANK := "right_flank"
const ZONE_REAR := "rear"

static func all_zones() -> Array:
	return [ZONE_FRONT, ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK, ZONE_REAR]

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

static func _count_alive_in_zone(manager: Node, fid: String, zone: String) -> int:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return 0
	var files: int = formation.get("files", 1)
	var ranks: int = formation.get("ranks", 1)
	var n: int = 0
	for c in manager.combatants:
		if not c.alive or c.get("formation_id", "") != fid:
			continue
		if zone_for_cell(files, ranks, c.get("rank", 0), c.get("file", 0)) == zone:
			n += 1
	return n

static func _obstacle_count_in_zone(manager: Node, fid: String, zone: String) -> int:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return 0
	var files: int = formation.get("files", 1)
	var ranks: int = formation.get("ranks", 1)
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var total: int = 0
	for key in obstacles:
		if not key is Vector2i:
			continue
		var ri: int = key.x
		var fi: int = key.y
		if zone_for_cell(files, ranks, ri, fi) == zone:
			var arr: Array = obstacles[key]
			total += arr.size()
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
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return 0.0
	var files: int = formation.get("files", 1)
	var ranks: int = formation.get("ranks", 1)
	var alive_n: float
	var cap: float
	if zone == ZONE_FRONT and files == 2:
		var l: float = float(_count_alive_in_zone(manager, fid, ZONE_LEFT_FLANK))
		var r: float = float(_count_alive_in_zone(manager, fid, ZONE_RIGHT_FLANK))
		alive_n = (l + r) * 0.5
		cap = float(maxi(1, ranks))
	else:
		alive_n = float(_count_alive_in_zone(manager, fid, zone))
		cap = float(_capacity_for_zone(files, ranks, zone))
	var base: float = alive_n / maxf(1.0, cap)
	var obs: float = float(_obstacle_count_in_zone(manager, fid, zone))
	var obs_pen: float = minf(0.55, float(CombatConstants.ZOC_CASUALTY_PER_BODY) * obs)
	return maxf(0.0, base - obs_pen)

## Mutates formations[*].zone_control with keys front, left_flank, right_flank, rear (0..1).
static func recompute_zone_control(manager: Node) -> void:
	for fid in ["player", "enemy"]:
		var formation: Dictionary = manager.formations.get(fid, {})
		if formation.is_empty():
			continue
		var base: Dictionary = {}
		for z in all_zones():
			base[z] = _raw_zone_strength(manager, fid, z)
		var f: float = float(base.get(ZONE_FRONT, 0.0))
		var l: float = float(base.get(ZONE_LEFT_FLANK, 0.0))
		var r: float = float(base.get(ZONE_RIGHT_FLANK, 0.0))
		var rr: float = float(base.get(ZONE_REAR, 0.0))
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
		if not c.alive:
			continue
		var fid: String = c.get("formation_id", "")
		if fid.is_empty() or not manager.formations.has(fid):
			c["zone_id"] = ""
			c["occupied_zone_id"] = ""
			continue
		var formation: Dictionary = manager.formations.get(fid, {})
		var files: int = formation.get("files", 1)
		var ranks: int = formation.get("ranks", 1)
		var zid: String = zone_for_cell(files, ranks, c.get("rank", 0), c.get("file", 0))
		c["zone_id"] = zid
		c["occupied_zone_id"] = zid

static func recompute_all(manager: Node) -> void:
	recompute_zone_control(manager)
	assign_combatant_zones(manager)

## Formation vs formation (both files >= 2): ZoC-based flank/rear parry mult on defender.
## Otherwise pack-style fallback: |Δfile| >= 2 => flank mod.
static func get_engagement_parry_multiplier(manager: Node, attacker_id: int, defender_id: int) -> float:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(defender_id)
	if atk == null or tgt == null:
		return 1.0
	if _should_use_zoc_for_pair(manager, atk, tgt):
		return _engagement_parry_mult_zoc(manager, tgt)
	return _engagement_parry_mult_pack_fallback(atk, tgt)

static func _should_use_zoc_for_pair(manager: Node, atk: Dictionary, tgt: Dictionary) -> bool:
	if atk.side == tgt.side:
		return false
	var fa: Dictionary = manager.formations.get(atk.get("formation_id", ""), {})
	var fd: Dictionary = manager.formations.get(tgt.get("formation_id", ""), {})
	if fa.is_empty() or fd.is_empty():
		return false
	return fa.get("files", 1) >= 2 and fd.get("files", 1) >= 2

static func _engagement_parry_mult_zoc(manager: Node, defender: Dictionary) -> float:
	var fid: String = defender.get("formation_id", "")
	var formation: Dictionary = manager.formations.get(fid, {})
	var zc: Dictionary = formation.get("zone_control", {})
	var files: int = formation.get("files", 1)
	var fd: int = defender.get("file", 0)
	var rank: int = defender.get("rank", 0)
	var thresh: float = CombatConstants.ZOC_ACCESS_THRESHOLD
	if zc.get(ZONE_REAR, 1.0) < thresh and rank == 0:
		return CombatConstants.REAR_PARRY_MOD
	if zc.get(ZONE_LEFT_FLANK, 1.0) < thresh and fd == 0:
		return CombatConstants.FLANK_PARRY_MOD
	if zc.get(ZONE_RIGHT_FLANK, 1.0) < thresh and fd == files - 1:
		return CombatConstants.FLANK_PARRY_MOD
	return 1.0

static func _engagement_parry_mult_pack_fallback(atk: Dictionary, tgt: Dictionary) -> float:
	var df: int = int(absf(float(atk.get("file", 0) - tgt.get("file", 0))))
	if df >= 2:
		return CombatConstants.FLANK_PARRY_MOD
	return 1.0

## When both sides have wide lines, allow mid band one file farther if either front zone is weak.
static func mid_reach_files(manager: Node, our: Dictionary, opp: Dictionary) -> int:
	var fo: Dictionary = manager.formations.get(our.get("formation_id", ""), {})
	var fe: Dictionary = manager.formations.get(opp.get("formation_id", ""), {})
	if fo.is_empty() or fe.is_empty():
		return 1
	if fo.get("files", 1) < 2 or fe.get("files", 1) < 2:
		return 1
	var wp: float = float(fo.get("zone_control", {}).get(ZONE_FRONT, 1.0))
	var we: float = float(fe.get("zone_control", {}).get(ZONE_FRONT, 1.0))
	if minf(wp, we) < CombatConstants.ZOC_ACCESS_THRESHOLD:
		return 2
	return 1
