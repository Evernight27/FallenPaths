class_name CombatDoctrine
extends RefCounted

## Per-formation **intent** (doctrine): steers hybrid targeting weights + ordering via `CombatTargetScoring` / `CombatAIActionPicker`.
## Orthogonal to **crash** (breach intrusion): crash uses `CombatEngagementMode`, stamina, armor mass, and `BreachResolver`;
## doctrine does not gate crash listing — they stay separate to avoid one system silently overriding breach eligibility.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")


static func normalize(doctrine: String) -> String:
	var d: String = str(doctrine).strip_edges().to_lower()
	if d.is_empty() or d == CombatConstants.DOCTRINE_DEFAULT:
		return CombatConstants.DOCTRINE_DEFAULT
	if d == CombatConstants.DOCTRINE_PINCH_CENTER or d == "pinch" or d == "pincer":
		return CombatConstants.DOCTRINE_PINCH_CENTER
	if d == CombatConstants.DOCTRINE_HOLD_LANE or d == "hold":
		return CombatConstants.DOCTRINE_HOLD_LANE
	if d == CombatConstants.DOCTRINE_PROBING or d == "probing":
		return CombatConstants.DOCTRINE_PROBING
	return CombatConstants.DOCTRINE_DEFAULT


static func doctrine_for_fid(manager: Node, formation_id: String) -> String:
	if manager == null:
		return CombatConstants.DOCTRINE_DEFAULT
	var fd: Variant = manager.get("formation_doctrine")
	if fd == null or typeof(fd) != TYPE_DICTIONARY:
		return CombatConstants.DOCTRINE_DEFAULT
	var d: Variant = (fd as Dictionary).get(str(formation_id), CombatConstants.DOCTRINE_DEFAULT)
	return normalize(str(d))


static func clear_commitments_for_side(manager: Node, formation_id: String) -> void:
	if manager == null:
		return
	for c in manager.combatants:
		if _EntityAccess.formation_id_str(c) != formation_id:
			continue
		c["doctrine_target_commit_id"] = -1
		c["doctrine_commit_until"] = 0.0
		c["close_block_until_by_target_id"] = {}


## True when the **opposing** formation’s front rank has a **hollow center**: middle file(s) empty with at least one living rank-0 on both wings (`files >= 3`). Rank-0 bodies on the **host** grid use **`formation_id_for_zone_geometry`** (intruders count). Used for automatic pinch doctrine; exposed for harness.
static func enemy_line_hollow_center_for_pinch(manager: Node, our_formation_id: String) -> bool:
	if manager == null:
		return false
	var opp_fid: String = "enemy" if str(our_formation_id) == "player" else "player"
	var fd: Dictionary = _FormationSlots.formation_record_read(manager.formations, opp_fid)
	if fd.is_empty():
		return false
	var nfiles: int = maxi(1, int(fd.get("files", 1)))
	if nfiles < 3:
		return false
	var has_r0: Array = []
	has_r0.resize(nfiles)
	for i in nfiles:
		has_r0[i] = false
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if _ZoneOfControl.formation_id_for_zone_geometry(manager, c) != opp_fid:
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		var fi: int = _EntityAccess.file_int(c)
		if fi >= 0 and fi < nfiles:
			has_r0[fi] = true
	if (nfiles & 1) == 1:
		var center_idx: int = nfiles >> 1
		if bool(has_r0[center_idx]):
			return false
		var left: bool = false
		var right: bool = false
		for f in nfiles:
			if not bool(has_r0[f]):
				continue
			if f < center_idx:
				left = true
			elif f > center_idx:
				right = true
		return left and right
	var c0: int = (nfiles >> 1) - 1
	var c1: int = nfiles >> 1
	if bool(has_r0[c0]) or bool(has_r0[c1]):
		return false
	var left_even: bool = false
	var right_even: bool = false
	for f in nfiles:
		if not bool(has_r0[f]):
			continue
		if f < c0:
			left_even = true
		elif f > c1:
			right_even = true
	return left_even and right_even


## Option 4 pilot (`CombatConstants.FEATURE_AUTOMATIC_DOCTRINE`): **default** doctrine → **pinch_center** when `enemy_line_hollow_center_for_pinch`. Does not override player-set **hold** / **pinch**; does not auto-revert. Single call site: `CombatFormationEngagement.recompute_all`.
static func evaluate_automatic_doctrine(manager: Node) -> void:
	if manager == null or not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
		return
	for fid in ["player", "enemy"]:
		if doctrine_for_fid(manager, fid) != CombatConstants.DOCTRINE_DEFAULT:
			continue
		if enemy_line_hollow_center_for_pinch(manager, fid):
			manager.set_formation_doctrine(fid, CombatConstants.DOCTRINE_PINCH_CENTER)
			_TacticalCombat.record_automatic_doctrine_pinch(manager, fid)
