class_name CombatDoctrine
extends RefCounted

## Per-formation **intent** (doctrine): steers hybrid targeting weights + ordering via `CombatTargetScoring` / `CombatAIActionPicker`.
## Pincer roles (**`PINCER_ROLE_*`**) when **`DOCTRINE_PINCH_CENTER`** + wider files than opponent: center pins, flank wings close/flank.
## Orthogonal to engagement-mode / posture targeting weights on melee/close listing.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")

const PINCER_ROLE_NONE := ""
const PINCER_ROLE_CENTER := "center"
const PINCER_ROLE_FLANK_WING := "flank_wing"


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
		clear_combatant_doctrine_commitment(c)
		c["close_block_until_by_target_id"] = {}


## Drop stale target commit after rank/file shuffle (rotate, swap) — mapped opposition may change.
static func clear_combatant_doctrine_commitment(c: Dictionary) -> void:
	if c.is_empty():
		return
	c["doctrine_target_commit_id"] = -1
	c["doctrine_commit_until"] = 0.0


## True when the **opposing** formation’s front rank has a **hollow center**: middle file(s) empty with at least one living rank-0 on both wings (`files >= 3`). Rank-0 on **`combatant_on_zone_geometry_fid`**. Used for automatic pinch doctrine; exposed for harness.
static func enemy_line_hollow_center_for_pinch(manager: Node, our_formation_id: String) -> bool:
	if manager == null:
		return false
	var opp_fid: String = _EntityAccess.opponent_side_label(str(our_formation_id))
	var fd: Dictionary = _FormationSlots.formation_record_for_manager(manager, opp_fid)
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
		if not _EntityAccess.is_standing_combatant(c):
			continue
		if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, opp_fid):
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


## Living rank-0 fighters on **`formation_id`** zone geometry (standing, not incapacitated).
static func living_rank0_front_count(manager: Node, formation_id: String) -> int:
	if manager == null:
		return 0
	var fid: String = str(formation_id)
	var n: int = 0
	for c in manager.combatants:
		if not _EntityAccess.is_standing_combatant(c):
			continue
		if not _ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, fid):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		n += 1
	return n


## p4c: wider formation + rank-0 count advantage → auto envelopment pinch (doctrine still **default**).
static func numeric_superiority_for_pinch(manager: Node, our_formation_id: String) -> bool:
	if manager == null:
		return false
	var our_fid: String = str(our_formation_id)
	var opp_fid: String = _EntityAccess.opponent_side_label(our_fid)
	var our_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, our_fid)
	var opp_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, opp_fid)
	if our_form.is_empty() or opp_form.is_empty():
		return false
	var our_files: int = maxi(1, int(our_form.get("files", 1)))
	var opp_files: int = maxi(1, int(opp_form.get("files", 1)))
	if our_files <= opp_files:
		return false
	var our_front: int = living_rank0_front_count(manager, our_fid)
	var opp_front: int = living_rank0_front_count(manager, opp_fid)
	return (
		our_front
		>= opp_front + int(CombatConstants.AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN)
	)


## Option 4 pilot (`CombatConstants.FEATURE_AUTOMATIC_DOCTRINE`): **default** doctrine → **pinch_center** when hollow enemy front or numeric superiority (p4c). Does not override player-set **hold** / **pinch**; does not auto-revert. Single call site: `CombatFormationEngagement.recompute_all`.
static func evaluate_automatic_doctrine(manager: Node) -> void:
	if manager == null or not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
		return
	for fid in ["player", "enemy"]:
		if doctrine_for_fid(manager, fid) != CombatConstants.DOCTRINE_DEFAULT:
			continue
		var reason: String = ""
		if enemy_line_hollow_center_for_pinch(manager, fid):
			reason = "hollow_center"
		elif numeric_superiority_for_pinch(manager, fid):
			reason = "numeric_superiority"
		if reason.is_empty():
			continue
		manager.set_formation_doctrine(fid, CombatConstants.DOCTRINE_PINCH_CENTER)
		_TacticalCombat.record_automatic_doctrine_pinch(manager, fid, reason)


## True when **`DOCTRINE_PINCH_CENTER`** and our formation spans more files than the opponent (7v3 skirmish pincer).
static func pincer_outnumber_active(manager: Node, formation_id: String) -> bool:
	if manager == null:
		return false
	var our_fid: String = str(formation_id)
	if doctrine_for_fid(manager, our_fid) != CombatConstants.DOCTRINE_PINCH_CENTER:
		return false
	var opp_fid: String = _EntityAccess.opponent_side_label(our_fid)
	var our_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, our_fid)
	var opp_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, opp_fid)
	if our_form.is_empty() or opp_form.is_empty():
		return false
	return int(our_form.get("files", 1)) > int(opp_form.get("files", 1))


## Rank-0 **center** vs **flank_wing** under pincer outnumber; empty when not applicable.
static func pincer_role_for_combatant(manager: Node, c: Dictionary) -> String:
	if manager == null or c.is_empty():
		return PINCER_ROLE_NONE
	if _EntityAccess.rank_int(c) != 0:
		return PINCER_ROLE_NONE
	var fid: String = _EntityAccess.formation_id_str(c)
	if not pincer_outnumber_active(manager, fid):
		return PINCER_ROLE_NONE
	var our_form: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	var opp_form: Dictionary = _FormationSlots.formation_record_for_manager(
		manager, _EntityAccess.opponent_side_label(fid)
	)
	if our_form.is_empty() or opp_form.is_empty():
		return PINCER_ROLE_NONE
	var our_files: int = maxi(1, int(our_form.get("files", 1)))
	var opp_files: int = maxi(1, int(opp_form.get("files", 1)))
	var our_file: int = _EntityAccess.file_int(c)
	var edge_margin: int = maxi(1, int((our_files - opp_files) / 2))
	var dist_from_near_edge: int = mini(our_file, our_files - 1 - our_file)
	if dist_from_near_edge < edge_margin:
		return PINCER_ROLE_FLANK_WING
	return PINCER_ROLE_CENTER


static func pincer_flank_wing_should_close_at_long(manager: Node, c: Dictionary) -> bool:
	return pincer_role_for_combatant(manager, c) == PINCER_ROLE_FLANK_WING


static func pincer_center_should_pin(manager: Node, c: Dictionary) -> bool:
	return pincer_role_for_combatant(manager, c) == PINCER_ROLE_CENTER


## Living rank-0 enemy id on the outer flank file matching this wing (left wing → min enemy file, right → max).
static func preferred_pincer_flank_enemy_id(manager: Node, wing: Dictionary) -> int:
	if manager == null or wing.is_empty():
		return -1
	if pincer_role_for_combatant(manager, wing) != PINCER_ROLE_FLANK_WING:
		return -1
	var our_form: Dictionary = _FormationSlots.formation_record_for_manager(
		manager, _EntityAccess.formation_id_str(wing)
	)
	if our_form.is_empty():
		return -1
	var our_files: int = maxi(1, int(our_form.get("files", 1)))
	var our_file: int = _EntityAccess.file_int(wing)
	var pick_min_file: bool = our_file <= (our_files - 1 - our_file)
	var best_id: int = -1
	var best_file: int = 999999 if pick_min_file else -999999
	for raw in manager.combatants:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var opp: Dictionary = raw as Dictionary
		if not _EntityAccess.is_living_hostile_to(wing, opp):
			continue
		if _EntityAccess.rank_int(opp) != 0:
			continue
		var ef: int = _EntityAccess.file_int(opp)
		if pick_min_file:
			if ef < best_file:
				best_file = ef
				best_id = _EntityAccess.id_int(opp)
		elif ef > best_file:
			best_file = ef
			best_id = _EntityAccess.id_int(opp)
	return best_id


static func _pincer_wing_has_active_commitment(manager: Node, c: Dictionary) -> bool:
	var tid: int = int(c.get("doctrine_target_commit_id", -1))
	if tid < 0:
		return false
	if manager == null:
		return true
	var clock: float = _EntityAccess.combat_clock_float(manager)
	if clock > float(c.get("doctrine_commit_until", 0.0)):
		return false
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
	return not tgt.is_empty() and _EntityAccess.is_standing_combatant(tgt)


## When a **center** fighter commits, stamp matching **flank_wing** allies toward outer enemy files (pincer mop-up).
static func propagate_pincer_wing_commitments_from_center(
	manager: Node, center_id: int, _center_target_id: int
) -> void:
	if manager == null or center_id < 0:
		return
	var center: Dictionary = _EntityAccess.manager_get_combatant(manager, center_id)
	if center.is_empty():
		return
	if pincer_role_for_combatant(manager, center) != PINCER_ROLE_CENTER:
		return
	var fid: String = _EntityAccess.formation_id_str(center)
	var until: float = (
		_EntityAccess.combat_clock_float(manager) + CombatConstants.DOCTRINE_COMMITMENT_DURATION_S
	)
	for raw in manager.combatants:
		if raw == null or typeof(raw) != TYPE_DICTIONARY:
			continue
		var wing: Dictionary = raw as Dictionary
		if _EntityAccess.formation_id_str(wing) != fid:
			continue
		if _EntityAccess.rank_int(wing) != 0:
			continue
		if pincer_role_for_combatant(manager, wing) != PINCER_ROLE_FLANK_WING:
			continue
		if _pincer_wing_has_active_commitment(manager, wing):
			continue
		var wing_tgt: int = preferred_pincer_flank_enemy_id(manager, wing)
		if wing_tgt < 0:
			continue
		wing["doctrine_target_commit_id"] = wing_tgt
		wing["doctrine_commit_until"] = until
