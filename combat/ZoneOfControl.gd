class_name ZoneOfControl
extends RefCounted

## Phase 4: Zone of control per formation (front, left_flank, right_flank, rear).
## Control 0..1 from alive/capacity, casualties in slots, and cross-zone support.
## See docs/IMPLEMENTATION_OUTLINE.md Phase 4.

const ZONE_FRONT := "front"
const ZONE_LEFT_FLANK := "left_flank"
const ZONE_RIGHT_FLANK := "right_flank"
const ZONE_REAR := "rear"
## Same value as CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE (encounter dict key).
const _ENCOUNTER_PROTECTION_CIRCLE_KEY := "protection_circle_active"
const _FormationSlots := preload("res://combat/FormationSlots.gd")

static func all_zones() -> Array:
	return [ZONE_FRONT, ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK, ZONE_REAR]

## When false, flank/rear parry mods and ZoC-based mid-reach extension do not apply (encounter flag).
static func is_zoc_flanking_enabled(manager: Node) -> bool:
	if manager == null:
		return true
	var enc: Variant = manager.get("encounter")
	if enc == null or typeof(enc) != TYPE_DICTIONARY:
		return true
	return not bool((enc as Dictionary).get(_ENCOUNTER_PROTECTION_CIRCLE_KEY, false))

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
	var max_p: float = CombatConstants.INCURSION_PRESSURE_MAX
	var inc_g: float = clampf(float(formation.get("incursion_pressure", 0.0)), 0.0, max_p)
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


## 0..1 per-file lane stress (dual living + density only). Zone aggregate for merging with global incursion — not bodies (see obs_pen).
static func _lane_stress_for_zone(formation: Dictionary, zone: String) -> float:
	var ls: Dictionary = formation.get("lane_stress_by_file", {})
	if ls.is_empty():
		return 0.0
	var files: int = maxi(1, formation.get("files", 1))
	match zone:
		ZONE_LEFT_FLANK:
			return float(ls.get(0, 0.0))
		ZONE_RIGHT_FLANK:
			return float(ls.get(files - 1, 0.0))
		ZONE_FRONT:
			if files <= 1:
				return float(ls.get(0, 0.0))
			if files == 2:
				return (float(ls.get(0, 0.0)) + float(ls.get(1, 0.0))) * 0.5
			var sum: float = 0.0
			var n: int = 0
			for f in range(1, files - 1):
				sum += float(ls.get(f, 0.0))
				n += 1
			return sum / float(maxi(1, n))
		ZONE_REAR:
			var mx: float = 0.0
			for f in range(files):
				mx = maxf(mx, float(ls.get(f, 0.0)))
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

## One-line UI/debug: zone strengths 0..1, or protection-circle notice.
static func format_zone_control_line(manager: Node, _side: String) -> String:
	if manager == null:
		return ""
	if not is_zoc_flanking_enabled(manager):
		return "ZoC: off (protection circle)"
	var formation: Dictionary = manager.formations.get(_side, {})
	var zc: Dictionary = formation.get("zone_control", {})
	if zc.is_empty():
		return ""
	var f: float = float(zc.get(ZONE_FRONT, 0.0))
	var l: float = float(zc.get(ZONE_LEFT_FLANK, 0.0))
	var r: float = float(zc.get(ZONE_RIGHT_FLANK, 0.0))
	var rr: float = float(zc.get(ZONE_REAR, 0.0))
	return "ZoC  F:%.2f  L:%.2f  R:%.2f  rear:%.2f" % [f, l, r, rr]

## Formation vs formation (both files >= 2): ZoC-based flank/rear parry mult on defender.
## Otherwise pack-style fallback: |Δfile| >= 2 => flank mod.
static func get_engagement_parry_multiplier(manager: Node, attacker_id: int, defender_id: int) -> float:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(defender_id)
	if atk == null or tgt == null:
		return 1.0
	if not is_zoc_flanking_enabled(manager):
		return _engagement_parry_mult_pack_fallback(atk, tgt)
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

## Scales geometric separation for engagement (weak front lines = compressed distance feel). 1.0 at full control.
## Note: mid_reach_files() also reacts to weak fronts (extra file of mid band) — intentional layered tuning, not duplicate math.
static func geometric_reach_extent_multiplier(manager: Node, our: Dictionary, opp: Dictionary) -> float:
	if not is_zoc_flanking_enabled(manager):
		return 1.0
	var fo: Dictionary = manager.formations.get(our.get("formation_id", ""), {})
	var fe: Dictionary = manager.formations.get(opp.get("formation_id", ""), {})
	if fo.is_empty() or fe.is_empty():
		return 1.0
	if fo.get("files", 1) < 2 or fe.get("files", 1) < 2:
		return 1.0
	var wp: float = float(fo.get("zone_control", {}).get(ZONE_FRONT, 1.0))
	var we: float = float(fe.get("zone_control", {}).get(ZONE_FRONT, 1.0))
	var m: float = minf(wp, we)
	return lerpf(CombatConstants.ZOC_GEOMETRIC_EXTENT_MIN, 1.0, m)


## When both sides have wide lines, allow mid band one file farther if either front zone is weak.
static func mid_reach_files(manager: Node, our: Dictionary, opp: Dictionary) -> int:
	if not is_zoc_flanking_enabled(manager):
		return 1
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


## Phase 5: Swap rank / fall-back duration — lane clarity (bodies, density). See MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION §2.3.
static func get_swap_lane_duration_multiplier(manager: Node, fid: String, file: int) -> float:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return CombatConstants.LANE_MOD_CLEAR
	var ranks: int = formation.get("ranks", 1)
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var obs_here: int = 0
	var key0 := Vector2i(0, file)
	var key1 := Vector2i(1, file)
	if obstacles.has(key0):
		obs_here += obstacles[key0].size()
	if ranks > 1 and obstacles.has(key1):
		obs_here += obstacles[key1].size()
	var lane: float = CombatConstants.LANE_MOD_CLEAR
	if obs_here >= 2:
		lane = CombatConstants.LANE_MOD_BLOCKED
	elif obs_here >= 1:
		lane = CombatConstants.LANE_MOD_CROWDED
	var slots: Dictionary = formation.get("slots", {})
	if _FormationSlots.living_count_in_slot(manager, slots, key0) >= 2:
		lane = maxf(lane, CombatConstants.LANE_MOD_CROWDED)
	if ranks > 1 and _FormationSlots.living_count_in_slot(manager, slots, key1) >= 2:
		lane = maxf(lane, CombatConstants.LANE_MOD_CROWDED)
	var density: String = formation.get("density", "normal")
	if density == "tight":
		lane *= 1.1
	elif density == "loose":
		lane *= 0.95
	return lane


## Phase 5: Opponent pressure on this formation — aggressive front line slows disengage. See investigation §2.4.
static func get_opponent_pressure_duration_multiplier(manager: Node, fid: String) -> float:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return CombatConstants.PRESSURE_MOD_NEUTRAL
	var our_side: String = formation.get("side", "")
	if our_side.is_empty():
		return CombatConstants.PRESSURE_MOD_NEUTRAL
	var opp_side: String = "enemy" if our_side == "player" else "player"
	var front_count: int = 0
	var stam_sum: float = 0.0
	var aggressive: bool = false
	var all_defensive: bool = true
	for c in manager.combatants:
		if not c.alive or c.side != opp_side:
			continue
		if c.get("rank", 0) != 0:
			continue
		front_count += 1
		stam_sum += float(c.get("stamina", CombatConstants.STAMINA_MAX))
		var st: String = c.get("state", "")
		if st == CombatConstants.STATE_WIND_UP or st == CombatConstants.STATE_RECOVERING:
			aggressive = true
			all_defensive = false
		var stance: String = c.get("stance", CombatConstants.STANCE_BALANCED)
		if stance == CombatConstants.STANCE_AGGRESSIVE and float(c.get("stamina", 0.0)) >= CombatConstants.STANCE_MIN_STAMINA_AGGRESSIVE:
			aggressive = true
		if stance != CombatConstants.STANCE_DEFENSIVE:
			all_defensive = false
	if front_count == 0:
		return CombatConstants.PRESSURE_MOD_DEFENSIVE
	if aggressive:
		return CombatConstants.PRESSURE_MOD_AGGRESSIVE
	var avg_stam: float = stam_sum / float(front_count)
	if all_defensive or avg_stam < CombatConstants.STAMINA_MAX * 0.35:
		return CombatConstants.PRESSURE_MOD_DEFENSIVE
	return CombatConstants.PRESSURE_MOD_NEUTRAL


## Phase 5: Step over fallen — extra duration when slot_obstacles (bodies) in this file column.
static func get_footing_duration_multiplier(manager: Node, fid: String, file: int) -> float:
	var formation: Dictionary = manager.formations.get(fid, {})
	if formation.is_empty():
		return 1.0
	var ranks: int = formation.get("ranks", 1)
	var obstacles: Dictionary = formation.get("slot_obstacles", {})
	var total: int = 0
	for r in range(ranks):
		var k := Vector2i(r, file)
		if obstacles.has(k):
			total += obstacles[k].size()
	if total <= 0:
		return 1.0
	var t: float = clampf(float(total) / 4.0, 0.0, 1.0)
	return lerpf(CombatConstants.FOOTING_STEP_OVER_MIN, CombatConstants.FOOTING_STEP_OVER_MAX, t)


## Lane × footing (pressure applied in CombatManager). Used for swap / fall back / rotate duration.
static func get_lane_and_footing_duration_multiplier(manager: Node, fid: String, file: int) -> float:
	return get_swap_lane_duration_multiplier(manager, fid, file) * get_footing_duration_multiplier(manager, fid, file)
