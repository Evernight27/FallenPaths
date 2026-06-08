class_name CombatDistanceBands
extends RefCounted

## MID/LONG/CLOSE bands from rank, `effective_pair_eff_dist`, `effective_pair_file_spacing_equivalent`, ZoC `mid_reach_files`, and weapon reach.
## Pair spacing from **`CombatPairGeometry`**; strike eligibility at MID also requires **`CombatMeleeListing.can_melee_threaten`** (`melee_range >= eff_dist`); not only `REACH_MID_MIN`.
## Depth-polearm lane gate (`depth_polearm_lane_open`) is computed **once per combatant** per pass (O(n²) → O(n) for that predicate).
## Canonical: **`update_distance_to_from_formations`** · **`purge_stale_distance_to_entries`** (fled/incap/off-field hygiene).

const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")


## Per-alive-combatant snapshot of **`CombatDepthPolearm.depth_polearm_lane_open`** ( **`zone_geometry_fid_str`** `fid` ).
static func depth_polearm_lane_open_by_combatant_id(manager: Node) -> Dictionary:
	var depth_lane_ok_by_id: Dictionary = {}
	for cc in manager.combatants:
		if not _EntityAccess.alive_bool(cc):
			continue
		var ccid: int = _EntityAccess.id_int(cc)
		if _EntityAccess.rank_int(cc) <= 0:
			depth_lane_ok_by_id[ccid] = false
			continue
		var fid_cc: String = _ZoneOfControl.zone_geometry_fid_str(manager, cc)
		depth_lane_ok_by_id[ccid] = _DepthPolearm.depth_polearm_lane_open(manager, cc, fid_cc)
	return depth_lane_ok_by_id


static func update_distance_to_from_formations(manager: Node) -> void:
	var depth_lane_ok_by_id: Dictionary = depth_polearm_lane_open_by_combatant_id(manager)
	var zone_ctx_by_id: Dictionary = _ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
	for c in manager.combatants:
		var d_to: Dictionary = _EntityAccess.nested_dictionary_for_mutation(c, "distance_to")
		var our_rank: int = _EntityAccess.rank_int(c)
		var cid: int = _EntityAccess.id_int(c)
		var fc: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(
			zone_ctx_by_id.get(cid, {}) as Dictionary
		)
		for opp in manager.combatants:
			if not _EntityAccess.is_living_hostile_to(c, opp):
				continue
			var oid: int = _EntityAccess.id_int(opp)
			var opp_rank: int = _EntityAccess.rank_int(opp)
			if our_rank > 0:
				if not bool(depth_lane_ok_by_id.get(_EntityAccess.id_int(c), false)):
					d_to[oid] = CombatConstants.DISTANCE_LONG
					continue
			var cur: String = str(d_to.get(oid, CombatConstants.DISTANCE_MID))
			if cur == CombatConstants.DISTANCE_CLOSE:
				var fo_close: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(
					zone_ctx_by_id.get(oid, {}) as Dictionary
				)
				var pair_close: Dictionary = _PairGeometry.effective_pair_geometry(
					manager, c, opp, fc, fo_close
				)
				if _MeleeListing.can_melee_threaten(manager, c, opp, pair_close):
					continue
				if _Doctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c)):
					continue
				# Stale CLOSE without reach (pre-close band patch or width change) — re-derive from geometry.
			# Rank-1+ enemy with open spear lane still participates in MID/LONG vs our rank-0 (Tier 1.9).
			if opp_rank > 0:
				if not bool(depth_lane_ok_by_id.get(oid, false)):
					d_to[oid] = CombatConstants.DISTANCE_LONG
					continue
			var fo: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(
				zone_ctx_by_id.get(oid, {}) as Dictionary
			)
			var mid_reach: int = _ZoneOfControl.mid_reach_files(manager, c, opp, fc, fo)
			var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, c, opp, fc, fo)
			var eff_dist: float = _PairGeometry.cached_eff_dist(pair_geom)
			var reach_here: float = maxf(_MeleeListing.melee_weapon_reach(c), _MeleeListing.melee_weapon_reach(opp))
			var eff_files: float = float(pair_geom.get("file_spacing_equiv", 0.0))
			var within_mid_files: bool = eff_files <= float(mid_reach) + CombatConstants.DIST_BAND_MID_FILE_EQUIV_SLACK
			if within_mid_files and _PairGeometry.melee_reach_covers_eff_dist(reach_here, eff_dist):
				d_to[oid] = CombatConstants.DISTANCE_MID
			else:
				# (C) Attacker reach already covers geometric separation — treat as mid so strike
				# Promote to MID when attacker's reach alone covers separation (keeps bands aligned with `can_melee_threaten` / action list).
				var atk_reach_only: float = _MeleeListing.melee_weapon_reach(c)
				atk_reach_only += _ZoneOfControl.weapon_reach_zoc_bonus_m(manager, c, opp)
				if _PairGeometry.melee_reach_covers_eff_dist(atk_reach_only + 1e-4, eff_dist):
					d_to[oid] = CombatConstants.DISTANCE_MID
				else:
					d_to[oid] = CombatConstants.DISTANCE_LONG
	for c in manager.combatants:
		var cid2: int = _EntityAccess.id_int(c)
		for opp in manager.combatants:
			if not _EntityAccess.is_living_hostile_to(c, opp):
				continue
			var oid2: int = _EntityAccess.id_int(opp)
			if _EntityAccess.nested_dictionary_for_mutation(c, "distance_to").get(oid2, "") == CombatConstants.DISTANCE_CLOSE:
				_EntityAccess.sync_close_distance_pair(c, opp, cid2, oid2)
	purge_stale_distance_to_entries(manager)


## Drop **`distance_to`** keys for fled / incapacitated / off-field opponents (post-flee mop-up hygiene).
static func purge_stale_distance_to_entries(manager: Node) -> void:
	if manager == null:
		return
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var d_to: Dictionary = _EntityAccess.nested_dictionary_for_mutation(c, "distance_to")
		var stale: Array = []
		for oid in d_to.keys():
			var opp: Dictionary = _EntityAccess.manager_get_combatant(manager, int(oid))
			if opp.is_empty() or not _EntityAccess.is_living_hostile_to(c, opp):
				stale.append(oid)
		for oid in stale:
			d_to.erase(oid)
