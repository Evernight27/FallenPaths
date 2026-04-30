class_name CombatTargetScoring
extends RefCounted

## Hybrid targeting (AI logic gates only — see `CombatManager.resolve_action` / `TurnReadyHandler`).
##
## **Data flow (high level):**
## 1. `CombatManager.start` → `formation_doctrine` defaults; combatants get commitment + close-block dicts.
## 2. `_recompute_zoc_and_distance` → `CombatDistanceBands` (incl. reach/band alignment) → pair `distance_to`.
## 3. `get_available_actions` → `AvailableActionsBuilder` (ordered opponents, `attempt_close` gated by `_close_attempt_pair_blocked`).
## 4. `CombatAIActionPicker.pick` → `ai_targeting_weight_mult` (doctrine, file, commitment, pressure) × stamina.
## 5. `CombatResolveAction` → melee wind-up → `on_combat_commitment`; close → `CombatEngagementResolver` (success → commitment + clear close block; fail → per-target cooldown).
## 6. `set_formation_doctrine` → clears commitments on that formation (doctrine change); death → `clear_all_targeting_state_for_dead_defender`.
##
## **Doctrine vs crash:** `DOCTRINE_PINCH_CENTER` / `HOLD_LANE` steer **listed** melee/close weights and ordering only. **Crash** is a separate breach move (stamina, armor mass, engagement mode); it does not read doctrine today — no conflicting state, just independent logic gates.

const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")


static func clear_all_targeting_state_for_dead_defender(manager: Node, dead_id: int) -> void:
	if manager == null or dead_id < 0:
		return
	for c in manager.combatants:
		if int(c.get("doctrine_target_commit_id", -1)) == dead_id:
			c["doctrine_target_commit_id"] = -1
		var blk: Dictionary = c.get("close_block_until_by_target_id", {}) as Dictionary
		if blk.has(dead_id):
			blk.erase(dead_id)
			c["close_block_until_by_target_id"] = blk


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
		if t == null or not t.get("alive", false):
			c["doctrine_target_commit_id"] = -1


static func on_combat_commitment(manager: Node, attacker_id: int, target_id: int) -> void:
	var atk = manager._get_by_id(attacker_id)
	if atk == null:
		return
	var tgt = manager._get_by_id(target_id)
	if tgt == null or not tgt.get("alive", false):
		return
	if atk.get("side", "") == tgt.get("side", ""):
		return
	atk["doctrine_target_commit_id"] = target_id
	atk["doctrine_commit_until"] = float(manager.combat_clock) + CombatConstants.DOCTRINE_COMMITMENT_DURATION_S


static func is_file_opposed_rank0_pair(actor: Dictionary, opp: Dictionary) -> bool:
	if int(actor.get("rank", 0)) != 0 or int(opp.get("rank", 0)) != 0:
		return false
	if actor.get("side", "") == opp.get("side", ""):
		return false
	if not opp.get("alive", false):
		return false
	if _EntityAccess.is_incapacitated(opp):
		return false
	return int(actor.get("file", 0)) == int(opp.get("file", 0))


static func wing_lacks_file_opposed(manager: Node, actor: Dictionary) -> bool:
	if int(actor.get("rank", 0)) != 0:
		return false
	if str(actor.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return false
	var my_side: String = str(actor.get("side", ""))
	for opp in manager.combatants:
		if not opp.get("alive", false) or str(opp.get("side", "")) == my_side:
			continue
		if _EntityAccess.is_incapacitated(opp):
			continue
		if not _ActionsBuilder._opp_matches_melee_rank_target(actor, opp, 0):
			continue
		if is_file_opposed_rank0_pair(actor, opp):
			return false
	return true


static func _enemy_front_file_center(manager: Node, enemy_side: String) -> float:
	var lo: int = 999999
	var hi: int = -999999
	var any: bool = false
	for c in manager.combatants:
		if not c.get("alive", false) or str(c.get("side", "")) != enemy_side:
			continue
		if int(c.get("rank", 0)) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		var fi: int = int(c.get("file", 0))
		lo = mini(lo, fi)
		hi = maxi(hi, fi)
		any = true
	if not any:
		return 0.0
	return (float(lo) + float(hi)) * 0.5


static func _opponent_side_for(actor: Dictionary) -> String:
	return "enemy" if str(actor.get("side", "")) == "player" else "player"


static func soft_geometry_score(manager: Node, actor: Dictionary, opp: Dictionary) -> float:
	var eff: float = _ActionsBuilder.effective_pair_eff_dist(manager, actor, opp)
	var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
	return 1.0 / (1.0 + eff * k)


static func pinch_score_mult(manager: Node, actor: Dictionary, opp: Dictionary) -> float:
	var doc: String = _Doctrine.doctrine_for_fid(manager, str(actor.get("formation_id", "")))
	if doc != CombatConstants.DOCTRINE_PINCH_CENTER:
		return 1.0
	if not wing_lacks_file_opposed(manager, actor):
		return 1.0
	var ec: float = _enemy_front_file_center(manager, _opponent_side_for(actor))
	var inward: float = absf(float(opp.get("file", 0)) - ec)
	var bonus: float = CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
	return 1.0 + bonus


static func hold_lane_mult(manager: Node, actor: Dictionary, opp: Dictionary) -> float:
	var doc: String = _Doctrine.doctrine_for_fid(manager, str(actor.get("formation_id", "")))
	if doc != CombatConstants.DOCTRINE_HOLD_LANE:
		return 1.0
	if is_file_opposed_rank0_pair(actor, opp):
		return 1.0
	return CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT


static func ally_pressure_count(manager: Node, defender_id: int, ally_side: String, exclude_attacker_id: int) -> int:
	var n: int = 0
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if str(c.get("side", "")) != ally_side:
			continue
		if int(c.get("id", -1)) == exclude_attacker_id:
			continue
		if int(c.get("rank", 0)) != 0:
			continue
		if int(c.get("doctrine_target_commit_id", -1)) == defender_id:
			n += 1
	return n


static func distributed_pressure_mult(manager: Node, attacker: Dictionary, defender_id: int) -> float:
	var cnt: float = float(
		ally_pressure_count(manager, defender_id, str(attacker.get("side", "")), int(attacker.get("id", -1)))
	)
	var ref: float = CombatConstants.DOCTRINE_PRESSURE_COUNT_REF
	var decay: float = CombatConstants.DOCTRINE_PRESSURE_DECAY_PER_ALLY
	return 1.0 / (1.0 + decay * cnt / maxf(0.001, ref))


static func commitment_match_mult(actor: Dictionary, target_id: int) -> float:
	if int(actor.get("doctrine_target_commit_id", -1)) == target_id:
		return CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT
	return 1.0


static func file_opposed_mult(actor: Dictionary, opp: Dictionary) -> float:
	if is_file_opposed_rank0_pair(actor, opp):
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


## Extra weight for AI pick only (player UI unchanged).
static func ai_targeting_weight_mult(manager: Node, attacker_id: int, action: Dictionary) -> float:
	prune_expired_commitments(manager)
	var mid: String = str(action.get("move_id", ""))
	if not targets_hostile_for_scoring(mid):
		return 1.0
	var tid: int = int(action.get("target_id", -1))
	if tid < 0:
		return 1.0
	var atk = manager._get_by_id(attacker_id)
	var opp = manager._get_by_id(tid)
	if atk == null or opp == null or not opp.get("alive", false):
		return 1.0
	if atk.get("side", "") == opp.get("side", ""):
		return 1.0
	var w: float = soft_geometry_score(manager, atk, opp)
	w *= pinch_score_mult(manager, atk, opp)
	w *= hold_lane_mult(manager, atk, opp)
	w *= file_opposed_mult(atk, opp)
	w *= commitment_match_mult(atk, tid)
	w *= distributed_pressure_mult(manager, atk, tid)
	return clampf(w, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX)


## (A) Order rank-line opponents: file-opposed first, then higher soft score (geometry + pinch intent).
static func ordered_melee_opponents(
	manager: Node,
	actor: Dictionary,
	combatants: Array,
	opp_rank_required: int
) -> Array:
	var raw: Array = []
	for opp in combatants:
		if not _ActionsBuilder._opp_matches_melee_rank_target(actor, opp, opp_rank_required):
			continue
		raw.append(opp)
	if raw.size() <= 1:
		return raw
	raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var afo: bool = is_file_opposed_rank0_pair(actor, a)
		var bfo: bool = is_file_opposed_rank0_pair(actor, b)
		if afo != bfo:
			return afo
		var sa: float = soft_geometry_score(manager, actor, a) * pinch_score_mult(manager, actor, a)
		var sb: float = soft_geometry_score(manager, actor, b) * pinch_score_mult(manager, actor, b)
		if not is_equal_approx(sa, sb):
			return sa > sb
		return int(a.get("id", 0)) < int(b.get("id", 0))
	)
	return raw
