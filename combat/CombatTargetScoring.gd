class_name CombatTargetScoring
extends RefCounted

## Hybrid targeting (AI logic gates only — see `CombatManager.resolve_action` / `TurnReadyHandler`).
##
## **Data flow (high level):**
## 1. `CombatManager.start` → `formation_doctrine` defaults; combatants get commitment + close-block dicts.
## 2. `_recompute_zoc_and_distance` → `CombatDistanceBands` (incl. reach/band alignment) → pair `distance_to`.
## 3. `get_available_actions` → `AvailableActionsBuilder.build` → `CombatMeleeListing` / formation / medical listing modules (`attempt_close` only at LONG via `CombatMeleeListing.attempt_close_listed_for_pair`, gated by `close_attempt_pair_blocked`; picker weight 0 if stale).
## 4. `CombatAIActionPicker.pick` → prune once → `ai_targeting_weight_mult(..., skip_prune=true)` (doctrine, file, commitment, pressure, **engagement mode**, our posture+cohesion, **opponent** formation, stance, **incap** defender hedge) × stamina × depth-spear move weights (incl. doctrine stab/cut nudge). **`ally_pressure_count`** for rank>0 uses **`CombatMeleeRankTargeting.melee_pair_rank_allowed`** to the committed defender (not **`depth_polearm_lane_open`** alone).
## 5. `CombatResolveAction` → melee wind-up → `on_combat_commitment`; close → `CombatEngagementResolver` (success → commitment + clear close block; fail → per-target cooldown).
## 6. `set_formation_doctrine` → clears commitments on that formation (doctrine change); death → `clear_all_targeting_state_for_dead_defender`.
##
## **Doctrine:** `DOCTRINE_PINCH_CENTER` / `HOLD_LANE` steer **listed** melee/close weights and ordering; `DOCTRINE_PROBING` nudges **depth spear** stab/cut listing weights only.

const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")


static func clear_all_targeting_state_for_dead_defender(manager: Node, dead_id: int) -> void:
	if manager == null or dead_id < 0:
		return
	for c in manager.combatants:
		if int(c.get("doctrine_target_commit_id", -1)) == dead_id:
			c["doctrine_target_commit_id"] = -1
		var blk: Dictionary = _EntityAccess.nested_dictionary_for_mutation(c, "close_block_until_by_target_id")
		if blk.has(dead_id):
			blk.erase(dead_id)


static func prune_expired_commitments(manager: Node) -> void:
	if manager == null:
		return
	var clock: float = _EntityAccess.combat_clock_float(manager)
	for c in manager.combatants:
		var tid: int = int(c.get("doctrine_target_commit_id", -1))
		if tid < 0:
			continue
		if clock > float(c.get("doctrine_commit_until", 0.0)):
			c["doctrine_target_commit_id"] = -1
			continue
		var t: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
		if t.is_empty() or not _EntityAccess.is_standing_combatant(t):
			c["doctrine_target_commit_id"] = -1


static func on_combat_commitment(manager: Node, attacker_id: int, target_id: int) -> void:
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or not _EntityAccess.is_alive_opponent_of(atk, tgt):
		return
	atk["doctrine_target_commit_id"] = target_id
	atk["doctrine_commit_until"] = _EntityAccess.combat_clock_float(manager) + CombatConstants.DOCTRINE_COMMITMENT_DURATION_S


static func is_file_opposed_rank0_pair(actor: Dictionary, opp: Dictionary) -> bool:
	if _EntityAccess.rank_int(actor) != 0 or _EntityAccess.rank_int(opp) != 0:
		return false
	if not _EntityAccess.is_living_hostile_to(actor, opp):
		return false
	return _EntityAccess.file_int(actor) == _EntityAccess.file_int(opp)


## When set, must be the result of **`depth_polearm_lane_open(manager, actor, zone_geometry_fid)`** for this scoring pass (see **`hostile_pair_targeting_weight_mult`**).
static func _depth_lane_open_resolved(
	manager: Node,
	actor: Dictionary,
	depth_lane_open_cache: Variant,
	zone_geometry_fid: String = ""
) -> bool:
	if depth_lane_open_cache != null:
		return bool(depth_lane_open_cache)
	var fid: String = zone_geometry_fid
	if fid.is_empty():
		fid = _ZoneOfControl.zone_geometry_fid_str(manager, actor)
	return _DepthPolearm.depth_polearm_lane_open(manager, actor, fid)


## File-opposed to **our** front rank (rank-0 actor, or same-file rank-0 partner when actor is depth polearm).
static func is_melee_file_opposed_priority(
	manager: Node,
	actor: Dictionary,
	opp: Dictionary,
	depth_lane_open_cache: Variant = null,
	zone_geometry_fid: String = ""
) -> bool:
	if is_file_opposed_rank0_pair(actor, opp):
		return true
	if manager == null or not _depth_lane_open_resolved(manager, actor, depth_lane_open_cache, zone_geometry_fid):
		return false
	var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(manager, actor, zone_geometry_fid)
	if front.is_empty():
		return false
	return is_file_opposed_rank0_pair(front, opp)


## True when no enemy rank 0 is **file-opposed** to this fighter’s **reference rank-0** (self, or same-file partner if depth polearm lane is open — Tier 1.6 pinch geometry).
static func wing_lacks_file_opposed(
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
	for opp in manager.combatants:
		if not _EntityAccess.is_living_hostile_to(actor, opp):
			continue
		if not _MeleeRank.opp_matches_melee_rank_target(manager, actor, opp, 0):
			continue
		if is_file_opposed_rank0_pair(ref, opp):
			return false
	return true


static func _enemy_front_file_center(manager: Node, enemy_side: String) -> float:
	var lo: int = 999999
	var hi: int = -999999
	var any: bool = false
	for c in manager.combatants:
		if not _EntityAccess.is_living_on_side(c, enemy_side):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		var fi: int = _EntityAccess.file_int(c)
		lo = mini(lo, fi)
		hi = maxi(hi, fi)
		any = true
	if not any:
		return 0.0
	return (float(lo) + float(hi)) * 0.5


## Optional **`eff_dist_cache`**: **`effective_pair_geometry` → `eff_dist`** when the caller already computed pair geometry (e.g. **`hostile_pair_targeting_weight_mult`**).
static func soft_geometry_score(
	manager: Node, actor: Dictionary, opp: Dictionary, eff_dist_cache: Variant = null
) -> float:
	var eff: float = -1.0
	if eff_dist_cache != null:
		eff = float(eff_dist_cache)
	if eff < 0.0:
		eff = _PairGeometry.cached_eff_dist(_PairGeometry.effective_pair_geometry(manager, actor, opp))
	var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
	return 1.0 / (1.0 + eff * k)


static func pinch_score_mult(
	manager: Node,
	actor: Dictionary,
	opp: Dictionary,
	depth_lane_open_cache: Variant = null,
	zone_geometry_fid: String = ""
) -> float:
	if manager == null:
		return 1.0
	var doc: String = _Doctrine.doctrine_for_fid(manager, _EntityAccess.formation_id_str(actor))
	if doc != CombatConstants.DOCTRINE_PINCH_CENTER:
		return 1.0
	if not wing_lacks_file_opposed(manager, actor, depth_lane_open_cache, zone_geometry_fid):
		return 1.0
	var ec: float = _enemy_front_file_center(manager, _EntityAccess.opponent_side_for(actor))
	var inward: float = absf(float(_EntityAccess.file_int(opp)) - ec)
	var bonus: float = CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
	return 1.0 + bonus


static func hold_lane_mult(
	manager: Node,
	actor: Dictionary,
	opp: Dictionary,
	depth_lane_open_cache: Variant = null,
	zone_geometry_fid: String = ""
) -> float:
	var doc: String = _Doctrine.doctrine_for_fid(manager, _EntityAccess.formation_id_str(actor))
	if doc != CombatConstants.DOCTRINE_HOLD_LANE:
		return 1.0
	if is_melee_file_opposed_priority(manager, actor, opp, depth_lane_open_cache, zone_geometry_fid):
		return 1.0
	return CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT


static func ally_pressure_count(manager: Node, defender_id: int, ally_side: String, exclude_attacker_id: int) -> int:
	if manager == null:
		return 0
	var n: int = 0
	for c in manager.combatants:
		if not _EntityAccess.is_alive_on_side(c, ally_side):
			continue
		if _EntityAccess.id_int(c) == exclude_attacker_id:
			continue
		if int(c.get("doctrine_target_commit_id", -1)) != defender_id:
			continue
		var rk: int = _EntityAccess.rank_int(c)
		if rk == 0:
			n += 1
		else:
			var dfd: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
			if dfd.is_empty() or not _EntityAccess.is_standing_combatant(dfd):
				continue
			if _MeleeRank.melee_pair_rank_allowed(manager, c, dfd):
				n += 1
	return n


static func distributed_pressure_mult(manager: Node, attacker: Dictionary, defender_id: int) -> float:
	var cnt: float = float(
		ally_pressure_count(
			manager, defender_id, _EntityAccess.side_str(attacker), _EntityAccess.id_int(attacker)
		)
	)
	var ref: float = CombatConstants.DOCTRINE_PRESSURE_COUNT_REF
	var decay: float = CombatConstants.DOCTRINE_PRESSURE_DECAY_PER_ALLY
	return 1.0 / (1.0 + decay * cnt / maxf(0.001, ref))


## IV-2: damp hostile weight when **`attempt_close`** slots on defender are saturated (spread to other targets).
static func close_slot_saturation_targeting_mult(
	manager: Node, defender: Dictionary, exclude_attacker_id: int
) -> float:
	if manager == null or defender.is_empty():
		return 1.0
	if _MeleeListing.defender_has_free_close_slot(
		manager, defender, exclude_attacker_id
	):
		return 1.0
	return CombatConstants.CLOSE_SLOTS_FULL_TARGETING_MULT


static func commitment_match_mult(actor: Dictionary, target_id: int) -> float:
	if int(actor.get("doctrine_target_commit_id", -1)) == target_id:
		return CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT
	return 1.0


## Tier 1.6 (P7): LINE posture scales with cohesion (ragged → slightly lower listed-target weights; solid → slight commit). OPEN/DUEL: looser cohesion → small aggression nudge.
## Intruders: uses host-line formation via **`formation_for_combatant_cached`** (cohesion/posture match tactical position).
## Optional **`formation_dict_cache`**: **`zone_geometry_line_context(manager, actor).formation`** when the caller already resolved it (e.g. **`hostile_pair_targeting_weight_mult`**).
static func posture_cohesion_targeting_mult(
	manager: Node, actor: Dictionary, formation_dict_cache: Variant = null
) -> float:
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, actor, formation_dict_cache)
	if fd.is_empty():
		return 1.0
	var coh: float = clampf(float(fd.get("line_cohesion", 1.0)), 0.0, 1.0)
	var pst: String = str(fd.get("engagement_posture", "")).strip_edges().to_lower()
	if pst == CombatConstants.ENGAGEMENT_POSTURE_LINE:
		return lerpf(
			CombatConstants.AI_TARGETING_LINE_COH_LO_MULT,
			CombatConstants.AI_TARGETING_LINE_COH_HI_MULT,
			coh
		)
	if pst == CombatConstants.ENGAGEMENT_POSTURE_OPEN or pst == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
		return lerpf(
			CombatConstants.AI_TARGETING_OPEN_COH_LOOSE_MULT,
			CombatConstants.AI_TARGETING_OPEN_COH_TIGHT_MULT,
			coh
		)
	return 1.0


## Tier 1.6 / 1.7: battle-scale resolved engagement mode nudge on listed hostile weights (duel focus / formation line / skirmish baseline).
static func engagement_mode_targeting_mult(manager: Node) -> float:
	if manager == null:
		return 1.0
	var m: String = _EngagementMode.engagement_mode(manager)
	match m:
		CombatConstants.ENGAGEMENT_MODE_DUEL:
			return CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT
		CombatConstants.ENGAGEMENT_MODE_FORMATION:
			return CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT
		_:
			return CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT


## Tier 1.6 breadth: listed hostile weight vs **target** formation `engagement_posture` + `line_cohesion` (enemy LINE wall solid → slight hedge; OPEN/DUEL → small press).
## Uses **`formation_for_combatant_cached`** (home-line **`formation_id`** after D-008).
## Optional **`formation_dict_cache`**: **`zone_geometry_line_context(manager, opp).formation`** when the caller already resolved it (e.g. hostile pair path).
static func opponent_formation_targeting_mult(
	manager: Node, opp: Dictionary, formation_dict_cache: Variant = null
) -> float:
	if manager == null or opp.is_empty():
		return 1.0
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(manager, opp, formation_dict_cache)
	if fd.is_empty():
		return 1.0
	var coh: float = clampf(float(fd.get("line_cohesion", 1.0)), 0.0, 1.0)
	var pst: String = str(fd.get("engagement_posture", "")).strip_edges().to_lower()
	if pst == CombatConstants.ENGAGEMENT_POSTURE_LINE:
		return lerpf(
			CombatConstants.AI_TARGETING_OPP_LINE_COH_SOLID_MULT,
			CombatConstants.AI_TARGETING_OPP_LINE_COH_RAGGED_MULT,
			1.0 - coh
		)
	if pst == CombatConstants.ENGAGEMENT_POSTURE_OPEN or pst == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
		return CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT
	return 1.0


## Tier 4.1: attacker stance nudges listed hostile melee/close weights (aggressive commits; defensive hedges).
static func stance_ai_targeting_mult(actor: Dictionary) -> float:
	if actor.is_empty():
		return 1.0
	return CombatConstants.get_stance_modifier(_EntityAccess.stance_str(actor), "ai_melee_focus")


static func file_opposed_mult(
	manager: Node,
	actor: Dictionary,
	opp: Dictionary,
	depth_lane_open_cache: Variant = null,
	zone_geometry_fid: String = ""
) -> float:
	if manager != null and is_melee_file_opposed_priority(manager, actor, opp, depth_lane_open_cache, zone_geometry_fid):
		return CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT
	return 1.0


static func targets_hostile_for_scoring(move_id: String) -> bool:
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return true
	if move_id in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
		return false
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return false
	if move_id in CombatConstants.MEDICAL_MOVE_IDS:
		return false
	return true


## Tier 1.6: same multipliers as hostile `ai_targeting_weight_mult` rows, for a fixed attacker–opponent pair (listing order, AI weights, tests; engagement mode + opponent formation).
## `cached_engagement_mode_targeting_mult`: pass a float from `engagement_mode_targeting_mult(manager)` when sorting many opponents (avoids repeated mode snapshots); default **null** recomputes.
## Optional **`actor_zone_geometry_line_context`**: reuse **`zone_geometry_line_context(manager, atk)`** when scoring many opponents (listing sort).
## Optional **`opponent_zone_geometry_line_context`**: reuse per-id cache from **`zone_geometry_line_context_by_combatant_id`** (avoids home-roster **`formation_for_combatant_cached`** on the defender).
static func hostile_pair_targeting_weight_mult(
	manager: Node,
	atk: Dictionary,
	opp: Dictionary,
	cached_engagement_mode_targeting_mult: Variant = null,
	actor_zone_geometry_line_context: Dictionary = {},
	opponent_zone_geometry_line_context: Dictionary = {}
) -> float:
	if manager == null or atk.is_empty() or opp.is_empty():
		return 1.0
	if not _EntityAccess.is_alive_opponent_of(atk, opp):
		return 1.0
	var fid_atk: String = ""
	var fd_atk: Dictionary = {}
	var fd_opp: Dictionary = {}
	if not actor_zone_geometry_line_context.is_empty():
		fid_atk = _ZoneOfControl.zone_geometry_fid_from_pack(actor_zone_geometry_line_context)
		fd_atk = _ZoneOfControl.zone_geometry_formation_from_pack(actor_zone_geometry_line_context)
		if not opponent_zone_geometry_line_context.is_empty():
			fd_opp = _ZoneOfControl.zone_geometry_formation_from_pack(opponent_zone_geometry_line_context)
		else:
			var zg_actor: Dictionary = _ZoneOfControl.zone_geometry_for_pair(manager, atk, opp)
			fd_opp = _ZoneOfControl.zone_geometry_formation_b_from_pair_pack(zg_actor)
	else:
		var zg: Dictionary = _ZoneOfControl.zone_geometry_for_pair(manager, atk, opp)
		fid_atk = _ZoneOfControl.zone_geometry_fid_a_from_pair_pack(zg)
		fd_atk = _ZoneOfControl.zone_geometry_formation_a_from_pair_pack(zg)
		fd_opp = _ZoneOfControl.zone_geometry_formation_b_from_pair_pack(zg)
	var depth_lane_atk: Variant = null
	if _EntityAccess.rank_int(atk) > 0:
		depth_lane_atk = _DepthPolearm.depth_polearm_lane_open(manager, atk, fid_atk)
	var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, atk, opp, fd_atk, fd_opp)
	var w: float = soft_geometry_score(manager, atk, opp, _PairGeometry.cached_eff_dist(pair_geom))
	w *= pinch_score_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= hold_lane_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= file_opposed_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= commitment_match_mult(atk, _EntityAccess.id_int(opp))
	w *= distributed_pressure_mult(manager, atk, _EntityAccess.id_int(opp))
	w *= close_slot_saturation_targeting_mult(manager, opp, _EntityAccess.id_int(atk))
	if cached_engagement_mode_targeting_mult == null:
		w *= engagement_mode_targeting_mult(manager)
	else:
		w *= float(cached_engagement_mode_targeting_mult)
	w *= posture_cohesion_targeting_mult(manager, atk, fd_atk)
	w *= opponent_formation_targeting_mult(manager, opp, fd_opp)
	w *= stance_ai_targeting_mult(atk)
	if _EntityAccess.is_incapacitated(opp):
		w *= CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT
	return clampf(w, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX)


## Extra weight for AI pick only (player UI unchanged).
## `skip_prune`: when **true**, skip `prune_expired_commitments` (caller already pruned — e.g. `CombatAIActionPicker.pick`).
## Optional zone caches: same as **`hostile_pair_targeting_weight_mult`** ( **`CombatAIActionPicker.pick_weighted`** passes both).
static func ai_targeting_weight_mult(
	manager: Node,
	attacker_id: int,
	action: Dictionary,
	skip_prune: bool = false,
	actor_zone_geometry_line_context: Dictionary = {},
	zone_geometry_by_combatant_id: Dictionary = {}
) -> float:
	if not skip_prune:
		prune_expired_commitments(manager)
	var mid: String = str(action.get("move_id", ""))
	if not targets_hostile_for_scoring(mid):
		return 1.0
	var tid: int = int(action.get("target_id", -1))
	if tid < 0:
		return 1.0
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	var opp: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
	if atk.is_empty() or opp.is_empty():
		return 1.0
	var opp_ctx: Dictionary = {}
	if not zone_geometry_by_combatant_id.is_empty():
		var opp_pack: Variant = zone_geometry_by_combatant_id.get(tid, null)
		if opp_pack is Dictionary:
			opp_ctx = opp_pack as Dictionary
	return hostile_pair_targeting_weight_mult(
		manager, atk, opp, null, actor_zone_geometry_line_context, opp_ctx
	)


## (A) Order rank-line opponents: file-opposed first, then `hostile_pair_targeting_weight_mult` (geometry, doctrine, commitment, pressure, engagement mode, posture, opponent formation, stance — Tier 1.6).
static func ordered_melee_opponents(
	manager: Node,
	actor: Dictionary,
	combatants: Array,
	opp_rank_required: int,
	actor_zone_geometry_line_context_cache: Dictionary = {}
) -> Array:
	prune_expired_commitments(manager)
	var raw: Array = []
	for opp in combatants:
		if not _MeleeRank.opp_matches_melee_rank_target(manager, actor, opp, opp_rank_required):
			continue
		raw.append(opp)
	if raw.size() <= 1:
		return raw
	var em_cached: float = engagement_mode_targeting_mult(manager)
	var ctx_actor: Dictionary = actor_zone_geometry_line_context_cache
	if ctx_actor.is_empty():
		ctx_actor = _ZoneOfControl.zone_geometry_line_context(manager, actor)
	var fid_actor: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_actor)
	var depth_lane_actor: Variant = null
	if _EntityAccess.rank_int(actor) > 0:
		depth_lane_actor = _DepthPolearm.depth_polearm_lane_open(manager, actor, fid_actor)
	var zone_by_id: Dictionary = _ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
	var file_opposed_by_id: Dictionary = {}
	var weights_by_id: Dictionary = {}
	for opp in raw:
		var oid: int = _EntityAccess.id_int(opp)
		file_opposed_by_id[oid] = is_melee_file_opposed_priority(
			manager, actor, opp, depth_lane_actor, fid_actor
		)
		var opp_ctx: Dictionary = zone_by_id.get(oid, {}) as Dictionary
		weights_by_id[oid] = hostile_pair_targeting_weight_mult(
			manager, actor, opp, em_cached, ctx_actor, opp_ctx
		)
	raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var aid: int = _EntityAccess.id_int(a)
		var bid: int = _EntityAccess.id_int(b)
		var afo: bool = bool(file_opposed_by_id.get(aid, false))
		var bfo: bool = bool(file_opposed_by_id.get(bid, false))
		if afo != bfo:
			return afo
		var sa: float = float(weights_by_id.get(aid, 1.0))
		var sb: float = float(weights_by_id.get(bid, 1.0))
		if not is_equal_approx(sa, sb):
			return sa > sb
		return aid < bid
	)
	return raw
