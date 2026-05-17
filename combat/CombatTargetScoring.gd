class_name CombatTargetScoring
extends RefCounted

## Hybrid targeting (AI logic gates only — see `CombatManager.resolve_action` / `TurnReadyHandler`).
##
## **Data flow (high level):**
## 1. `CombatManager.start` → `formation_doctrine` defaults; combatants get commitment + close-block dicts.
## 2. `_recompute_zoc_and_distance` → `CombatDistanceBands` (incl. reach/band alignment) → pair `distance_to`.
## 3. `get_available_actions` → `AvailableActionsBuilder` (ordered opponents; MID+geometric reach lists melee; `attempt_close` only at LONG via `_attempt_close_listed_for_pair`, gated by `_close_attempt_pair_blocked`; picker weight 0 if stale).
## 4. `CombatAIActionPicker.pick` → prune once → `ai_targeting_weight_mult(..., skip_prune=true)` (doctrine, file, commitment, pressure, **engagement mode**, our posture+cohesion, **opponent** formation, **opponent file breach** severity, stance, **incap** defender hedge) × stamina × depth-spear move weights (incl. doctrine stab/cut nudge). **`ally_pressure_count`** for rank>0 uses **`AvailableActionsBuilder._melee_pair_rank_allowed`** to the committed defender (not **`depth_polearm_lane_open`** alone).
## 5. `CombatResolveAction` → melee wind-up → `on_combat_commitment`; close → `CombatEngagementResolver` (success → commitment + clear close block; fail → per-target cooldown).
## 6. `set_formation_doctrine` → clears commitments on that formation (doctrine change); death → `clear_all_targeting_state_for_dead_defender`.
##
## **Doctrine vs crash:** `DOCTRINE_PINCH_CENTER` / `HOLD_LANE` steer **listed** melee/close weights and ordering; `DOCTRINE_PROBING` nudges **depth spear** stab/cut listing weights only. **Crash** is a separate breach move (stamina, armor mass, engagement mode); it does not read doctrine today — no conflicting state, just independent logic gates.

const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")


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
	var clock: float = float(manager.combat_clock)
	for c in manager.combatants:
		var tid: int = int(c.get("doctrine_target_commit_id", -1))
		if tid < 0:
			continue
		if clock > float(c.get("doctrine_commit_until", 0.0)):
			c["doctrine_target_commit_id"] = -1
			continue
		var t = manager._get_by_id(tid)
		if t == null or not _EntityAccess.alive_bool(t):
			c["doctrine_target_commit_id"] = -1


static func on_combat_commitment(manager: Node, attacker_id: int, target_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not _EntityAccess.alive_bool(tgt):
		return
	if _EntityAccess.side_str(atk) == _EntityAccess.side_str(tgt):
		return
	atk["doctrine_target_commit_id"] = target_id
	atk["doctrine_commit_until"] = float(manager.combat_clock) + CombatConstants.DOCTRINE_COMMITMENT_DURATION_S


static func is_file_opposed_rank0_pair(actor: Dictionary, opp: Dictionary) -> bool:
	if _EntityAccess.rank_int(actor) != 0 or _EntityAccess.rank_int(opp) != 0:
		return false
	if _EntityAccess.side_str(actor) == _EntityAccess.side_str(opp):
		return false
	if not _EntityAccess.alive_bool(opp):
		return false
	if _EntityAccess.is_incapacitated(opp):
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
		fid = _ZoneOfControl.formation_id_for_zone_geometry(manager, actor)
	return _ActionsBuilder.depth_polearm_lane_open(manager, actor, fid)


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
	var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(manager, actor, zone_geometry_fid)
	if front.is_empty():
		return false
	return is_file_opposed_rank0_pair(front, opp)


## True when no enemy rank 0 is **file-opposed** to this fighter’s **reference rank-0** (self, or same-file partner if depth polearm lane is open — Tier 1.6 pinch geometry).
static func wing_lacks_file_opposed(
	manager: Node, actor: Dictionary, depth_lane_open_cache: Variant = null, zone_geometry_fid: String = ""
) -> bool:
	if manager == null:
		return false
	if _ZoneOfControl.is_intruded(actor):
		return false
	var ref: Dictionary = actor
	if _EntityAccess.rank_int(actor) != 0:
		if not _depth_lane_open_resolved(manager, actor, depth_lane_open_cache, zone_geometry_fid):
			return false
		var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(manager, actor, zone_geometry_fid)
		if front.is_empty():
			return false
		ref = front
	var my_side: String = _EntityAccess.side_str(actor)
	for opp in manager.combatants:
		if not _EntityAccess.alive_bool(opp) or _EntityAccess.side_str(opp) == my_side:
			continue
		if _EntityAccess.is_incapacitated(opp):
			continue
		if not _ActionsBuilder._opp_matches_melee_rank_target(manager, actor, opp, 0):
			continue
		if is_file_opposed_rank0_pair(ref, opp):
			return false
	return true


static func _enemy_front_file_center(manager: Node, enemy_side: String) -> float:
	var lo: int = 999999
	var hi: int = -999999
	var any: bool = false
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.side_str(c) != enemy_side:
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		var fi: int = _EntityAccess.file_int(c)
		lo = mini(lo, fi)
		hi = maxi(hi, fi)
		any = true
	if not any:
		return 0.0
	return (float(lo) + float(hi)) * 0.5


static func _opponent_side_for(actor: Dictionary) -> String:
	return "enemy" if _EntityAccess.side_str(actor) == "player" else "player"


## Optional **`eff_dist_cache`**: **`effective_pair_geometry` → `eff_dist`** when the caller already computed pair geometry (e.g. **`hostile_pair_targeting_weight_mult`**).
static func soft_geometry_score(
	manager: Node, actor: Dictionary, opp: Dictionary, eff_dist_cache: Variant = null
) -> float:
	var eff: float = -1.0
	if eff_dist_cache != null:
		eff = float(eff_dist_cache)
	if eff < 0.0:
		eff = _ActionsBuilder.effective_pair_eff_dist(manager, actor, opp)
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
	var ec: float = _enemy_front_file_center(manager, _opponent_side_for(actor))
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
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.side_str(c) != ally_side:
			continue
		if _EntityAccess.id_int(c) == exclude_attacker_id:
			continue
		if int(c.get("doctrine_target_commit_id", -1)) != defender_id:
			continue
		var rk: int = _EntityAccess.rank_int(c)
		if rk == 0:
			n += 1
		else:
			var dfd = manager._get_by_id(defender_id)
			if dfd == null or not _EntityAccess.alive_bool(dfd):
				continue
			if _ActionsBuilder._melee_pair_rank_allowed(manager, c, dfd):
				n += 1
	return n


static func distributed_pressure_mult(manager: Node, attacker: Dictionary, defender_id: int) -> float:
	var cnt: float = float(
		ally_pressure_count(manager, defender_id, _EntityAccess.side_str(attacker), _EntityAccess.id_int(attacker))
	)
	var ref: float = CombatConstants.DOCTRINE_PRESSURE_COUNT_REF
	var decay: float = CombatConstants.DOCTRINE_PRESSURE_DECAY_PER_ALLY
	return 1.0 / (1.0 + decay * cnt / maxf(0.001, ref))


static func commitment_match_mult(actor: Dictionary, target_id: int) -> float:
	if int(actor.get("doctrine_target_commit_id", -1)) == target_id:
		return CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT
	return 1.0


## Tier 1.6 (P7): LINE posture scales with cohesion (ragged → slightly lower listed-target weights; solid → slight commit). OPEN/DUEL: looser cohesion → small aggression nudge.
## Intruders: uses **`ZoneOfControl.formation_dict_for_zone_geometry`** (host line) so cohesion/posture match tactical position.
## Optional **`formation_dict_cache`**: **`formation_dict_for_zone_geometry(manager, actor)`** when the caller already resolved it (e.g. **`hostile_pair_targeting_weight_mult`**).
static func posture_cohesion_targeting_mult(
	manager: Node, actor: Dictionary, formation_dict_cache: Variant = null
) -> float:
	var fd: Dictionary = (
		(formation_dict_cache as Dictionary)
		if formation_dict_cache != null and formation_dict_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, actor)
	)
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
## Intruders: **`formation_id_for_zone_geometry`** (host line), not home roster id.
## Optional **`formation_dict_cache`**: **`formation_dict_for_zone_geometry(manager, opp)`** when the caller already resolved it (e.g. hostile pair path).
static func opponent_formation_targeting_mult(
	manager: Node, opp: Dictionary, formation_dict_cache: Variant = null
) -> float:
	if manager == null or opp.is_empty():
		return 1.0
	var fd: Dictionary = (
		(formation_dict_cache as Dictionary)
		if formation_dict_cache != null and formation_dict_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp)
	)
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


## Tier 1.6 breadth: slight press on targets in a **breached** enemy file (`formation.breached_files` at their `file`; severity read matches **`FormationBreachRules.breached_file_severity`** via **`CombatFileKeyedDict`**).
## Intruders: **`formation_id_for_zone_geometry`** so breach keys match the host line.
## Optional **`formation_dict_cache`**: same contract as **`opponent_formation_targeting_mult`**.
static func opponent_breach_file_targeting_mult(
	manager: Node, opp: Dictionary, formation_dict_cache: Variant = null
) -> float:
	if manager == null or opp.is_empty():
		return 1.0
	var fd: Dictionary = (
		(formation_dict_cache as Dictionary)
		if formation_dict_cache != null and formation_dict_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp)
	)
	if fd.is_empty():
		return 1.0
	var bf: Dictionary = _FormationSlots.formation_nested_dictionary_read(fd, "breached_files")
	if bf.is_empty():
		return 1.0
	var sev: float = clampf(
		_FormationBreachRules.breached_file_severity(bf, _EntityAccess.file_int(opp), 0.0),
		0.0,
		1.0
	)
	if sev <= 0.001:
		return 1.0
	return lerpf(1.0, CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX, sev)


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
	if move_id == CombatConstants.MOVE_ID_CRASH:
		return false
	if move_id in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
		return false
	if move_id == CombatConstants.MOVE_ID_WAIT:
		return false
	if move_id in CombatConstants.MEDICAL_MOVE_IDS:
		return false
	return true


## Tier 1.6: same multipliers as hostile `ai_targeting_weight_mult` rows, for a fixed attacker–opponent pair (listing order, AI weights, tests; engagement mode + opponent formation + breach file).
## `cached_engagement_mode_targeting_mult`: pass a float from `engagement_mode_targeting_mult(manager)` when sorting many opponents (avoids repeated mode snapshots); default **null** recomputes.
static func hostile_pair_targeting_weight_mult(
	manager: Node,
	atk: Dictionary,
	opp: Dictionary,
	cached_engagement_mode_targeting_mult: Variant = null
) -> float:
	if manager == null or atk.is_empty() or opp.is_empty():
		return 1.0
	if not _EntityAccess.alive_bool(opp):
		return 1.0
	if _EntityAccess.side_str(atk) == _EntityAccess.side_str(opp):
		return 1.0
	var fid_atk: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, atk)
	var fid_opp: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, opp)
	var fd_atk: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, atk, fid_atk)
	var fd_opp: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp, fid_opp)
	var depth_lane_atk: Variant = null
	if _EntityAccess.rank_int(atk) > 0:
		depth_lane_atk = _ActionsBuilder.depth_polearm_lane_open(manager, atk, fid_atk)
	var pair_geom: Dictionary = _ActionsBuilder.effective_pair_geometry(manager, atk, opp, fd_atk, fd_opp)
	var w: float = soft_geometry_score(manager, atk, opp, pair_geom.get("eff_dist"))
	w *= pinch_score_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= hold_lane_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= file_opposed_mult(manager, atk, opp, depth_lane_atk, fid_atk)
	w *= commitment_match_mult(atk, _EntityAccess.id_int(opp))
	w *= distributed_pressure_mult(manager, atk, _EntityAccess.id_int(opp))
	if cached_engagement_mode_targeting_mult == null:
		w *= engagement_mode_targeting_mult(manager)
	else:
		w *= float(cached_engagement_mode_targeting_mult)
	w *= posture_cohesion_targeting_mult(manager, atk, fd_atk)
	w *= opponent_formation_targeting_mult(manager, opp, fd_opp)
	w *= opponent_breach_file_targeting_mult(manager, opp, fd_opp)
	w *= stance_ai_targeting_mult(atk)
	if _EntityAccess.is_incapacitated(opp):
		w *= CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT
	return clampf(w, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX)


## Extra weight for AI pick only (player UI unchanged).
## `skip_prune`: when **true**, skip `prune_expired_commitments` (caller already pruned — e.g. `CombatAIActionPicker.pick`).
static func ai_targeting_weight_mult(
	manager: Node, attacker_id: int, action: Dictionary, skip_prune: bool = false
) -> float:
	if not skip_prune:
		prune_expired_commitments(manager)
	var mid: String = str(action.get("move_id", ""))
	if not targets_hostile_for_scoring(mid):
		return 1.0
	var tid: int = int(action.get("target_id", -1))
	if tid < 0:
		return 1.0
	var atk = manager._get_by_id(attacker_id)
	var opp = manager._get_by_id(tid)
	if atk == null or opp == null:
		return 1.0
	return hostile_pair_targeting_weight_mult(manager, atk, opp)


## (A) Order rank-line opponents: file-opposed first, then `hostile_pair_targeting_weight_mult` (geometry, doctrine, commitment, pressure, engagement mode, posture, opponent formation, breach file, stance — Tier 1.6).
static func ordered_melee_opponents(
	manager: Node,
	actor: Dictionary,
	combatants: Array,
	opp_rank_required: int
) -> Array:
	prune_expired_commitments(manager)
	var raw: Array = []
	for opp in combatants:
		if not _ActionsBuilder._opp_matches_melee_rank_target(manager, actor, opp, opp_rank_required):
			continue
		raw.append(opp)
	if raw.size() <= 1:
		return raw
	var em_cached: float = engagement_mode_targeting_mult(manager)
	var fid_actor: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, actor)
	var depth_lane_actor: Variant = null
	if _EntityAccess.rank_int(actor) > 0:
		depth_lane_actor = _ActionsBuilder.depth_polearm_lane_open(manager, actor, fid_actor)
	raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var afo: bool = is_melee_file_opposed_priority(manager, actor, a, depth_lane_actor, fid_actor)
		var bfo: bool = is_melee_file_opposed_priority(manager, actor, b, depth_lane_actor, fid_actor)
		if afo != bfo:
			return afo
		var sa: float = hostile_pair_targeting_weight_mult(manager, actor, a, em_cached)
		var sb: float = hostile_pair_targeting_weight_mult(manager, actor, b, em_cached)
		if not is_equal_approx(sa, sb):
			return sa > sb
		return _EntityAccess.id_int(a, 0) < _EntityAccess.id_int(b, 0)
	)
	return raw
