class_name AvailableActionsBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
## Builds available actions for a combatant (attacks, medical). Manager must have: _get_by_id, _get_entity,
## _get_parts_being_treated_on, _get_ally_medical_actions, _is_in_immediate_peril, _has_left_immediate_peril_permanently,
## combatants, medical_phase, medical_phase_winner.

## Geometric separation along files: |Δfile| × avg_spacing × REACH_SAFETY_FACTOR (same as melee targeting).
static func effective_pair_eff_dist(manager: Node, a: Dictionary, b: Dictionary) -> float:
	var df: float = absf(float(a.get("file", 0) - b.get("file", 0)))
	var fa: Dictionary = manager.formations.get(a.get("formation_id", ""), {})
	var fb: Dictionary = manager.formations.get(b.get("formation_id", ""), {})
	if fa.is_empty() or fb.is_empty():
		return df * CombatConstants.SPACING_NORMAL * CombatConstants.REACH_SAFETY_FACTOR
	var sa: float = CombatConstants.get_spacing_from_density(fa.get("density", "normal"))
	var sb: float = CombatConstants.get_spacing_from_density(fb.get("density", "normal"))
	var base: float = df * (sa + sb) * 0.5 * CombatConstants.REACH_SAFETY_FACTOR
	return base * _ZoneOfControl.geometric_reach_extent_multiplier(manager, a, b)

static func melee_weapon_reach(c: Dictionary) -> float:
	var w = _EntityAccess.get_weapon(c)
	if w == null:
		return 0.0
	return float(w.melee_range)

## True if attacker could list a non-parry melee strike vs defender (weapon reach + distance band vs build()).
static func can_melee_threaten(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
	if not attacker.get("alive", false) or not defender.get("alive", false):
		return false
	if attacker.get("side", "") == defender.get("side", ""):
		return false
	if attacker.get("rank", 0) != 0 or defender.get("rank", 0) != 0:
		return false
	if _EntityAccess.get_attacking_arm(attacker).is_empty():
		return false
	var weapon = _EntityAccess.get_weapon(attacker)
	if weapon == null or not weapon.has_method("get_available_attack_types"):
		return false
	var melee_range: float = float(weapon.melee_range)
	var can_attack_from_mid: bool = melee_range >= CombatConstants.REACH_MID_MIN
	var eff_dist: float = effective_pair_eff_dist(manager, attacker, defender)
	var in_swing_range: bool = melee_range >= eff_dist
	var dist: String = str(attacker.get("distance_to", {}).get(defender.get("id", -1), CombatConstants.DISTANCE_LONG))
	if not in_swing_range:
		return false
	if dist == CombatConstants.DISTANCE_CLOSE:
		return true
	if dist == CombatConstants.DISTANCE_MID and can_attack_from_mid:
		return true
	return false

static func build(manager: Node, combatant_id: int) -> Array:
	var c = manager._get_by_id(combatant_id)
	if c == null or not c.alive or c.gauge < 100.0:
		return []
	if c.state != CombatConstants.STATE_WAITING and c.state != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
		return []
	if _EntityAccess.is_incapacitated(c):
		return []
	var actions: Array = []
	var combatants: Array = manager.combatants
	var medical_phase: bool = manager.medical_phase
	var medical_phase_winner: String = manager.medical_phase_winner

	# Receiving medical care: can hold/switch direct pressure on wounds NOT being treated by ally
	if c.state == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION and medical_phase and c.side == medical_phase_winner:
		if c.node != null and c.node.has_method("can_apply_direct_pressure") and c.node.has_method("get_wounded_parts"):
			var parts_being_treated: Array = manager._get_parts_being_treated_on(combatant_id)
			var entity = manager._get_entity(c.node)
			for part in c.node.get_wounded_parts():
				if part.is_empty() or part in parts_being_treated:
					continue
				if entity != null and entity.has_method("has_direct_pressure_on_part") and entity.has_direct_pressure_on_part(part):
					continue
				if entity != null and entity.has_method("can_apply_direct_pressure") and entity.can_apply_direct_pressure(part):
					actions.append({ "target_id": combatant_id, "move_id": "apply_direct_pressure", "target_part": part })
		return actions

	# Combat phase: attacks and swap rank. Phase 2: filter by distance. Phase 3: rank + formation targeting.
	if not medical_phase:
		var fid: String = c.get("formation_id", "")
		var formations_dict: Dictionary = manager.formations
		var our_formation: Dictionary = formations_dict.get(fid, {})
		var our_rank: int = c.get("rank", 0)
		var our_file: int = c.get("file", 0)
		# Phase 3: Rank 0 melee only; rank 1+ cannot melee (support/ranged; no ranged yet → swap rank).
		var can_melee: bool = our_rank == 0 and not _EntityAccess.get_attacking_arm(c).is_empty()
		if can_melee:
			var weapon = _EntityAccess.get_weapon(c)
			if weapon != null and weapon.has_method("get_available_attack_types"):
				var melee_range: float = float(weapon.melee_range)
				var can_attack_from_mid: bool = melee_range >= CombatConstants.REACH_MID_MIN
				var move_ids: Array = weapon.get_available_attack_types()
				for opp in combatants:
					if not opp.alive or opp.side == c.side:
						continue
					var opp_rank: int = opp.get("rank", 0)
					if opp_rank != 0:
						continue  # Melee only vs enemy front rank
					var eff_dist: float = effective_pair_eff_dist(manager, c, opp)
					var in_swing_range: bool = melee_range >= eff_dist
					var dist: String = c.get("distance_to", {}).get(opp.id, CombatConstants.DISTANCE_LONG)
					if in_swing_range:
						if dist == CombatConstants.DISTANCE_CLOSE or (dist == CombatConstants.DISTANCE_MID and can_attack_from_mid):
							for move_id in move_ids:
								if WeaponConstants.is_parry_move(move_id):
									continue
								actions.append({ "target_id": opp.id, "move_id": move_id })
						elif dist in [CombatConstants.DISTANCE_MID, CombatConstants.DISTANCE_LONG]:
							actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
					else:
						# Out of swing reach (file spacing) — still offer close attempts (do not skip the opponent entirely).
						if dist in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID, CombatConstants.DISTANCE_LONG]:
							actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		# Phase 3: Swap rank — front→back disengage; plug when front incap; deeper→shallow relief (same column).
		# With 3+ depth ranks, middle/back rows must be able to swap toward the front or they only get wait.
		var formation_ranks: int = our_formation.get("ranks", 1)
		if not our_formation.is_empty() and formation_ranks > 1:
			for ally in combatants:
				if not ally.alive or ally.side != c.side or ally.get("formation_id", "") != fid:
					continue
				if ally.get("state", "") in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
					continue  # Partner busy
				var partner_rank: int = ally.get("rank", 0)
				var partner_file: int = ally.get("file", 0)
				if partner_file != our_file or abs(partner_rank - our_rank) != 1:
					continue  # Must be same file, adjacent rank
				var we_are_front: bool = partner_rank > our_rank
				var partner_incapacitated: bool = _EntityAccess.is_incapacitated(ally)
				var we_plug_forward: bool = partner_rank < our_rank and partner_incapacitated
				var relief_swap: bool = our_rank > partner_rank and not partner_incapacitated \
					and CombatAIActionPicker.is_relief_swap_tactically_allowed(c, ally)
				if (we_are_front and not partner_incapacitated) or we_plug_forward or relief_swap:
					var allow_swap: bool = false
					if we_plug_forward:
						allow_swap = true
					elif relief_swap:
						allow_swap = true
					elif we_are_front:
						allow_swap = CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, ally)
					if allow_swap:
						actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_SWAP_RANK })
						# Drag / fall_back_pair are front-line retreat flavors; relief rotation uses quick swap only.
						if not we_plug_forward and we_are_front:
							actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_DRAG_BACK })
							actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_FALL_BACK })
					break
		# Phase 5: rotate file — front rank only, adjacent files, both must be free to coordinate.
		if not our_formation.is_empty() and formation_ranks > 1 and our_rank == 0:
			for ally in combatants:
				if not ally.alive or ally.side != c.side or ally.get("formation_id", "") != fid:
					continue
				if ally.get("state", "") in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
					continue
				if ally.get("rank", 0) != 0:
					continue
				if abs(ally.get("file", 0) - our_file) != 1:
					continue
				actions.append({"target_id": ally.id, "move_id": CombatConstants.MOVE_ID_ROTATE_FILE})
		# Phase 5: fall back solo — step to rear rank when that slot is empty.
		if not our_formation.is_empty() and formation_ranks > 1 and our_rank == 0:
			var slots_check: Dictionary = our_formation.get("slots", {})
			if not _FormationSlots.slot_has_any(slots_check, Vector2i(1, our_file)):
				actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FALL_BACK})
		_append_combat_wait_if_needed(actions, combatant_id)
	else:
		if c.side == medical_phase_winner and c.node != null and c.node.has_method("can_apply_direct_pressure"):
			var immediate_peril: bool = manager._is_in_immediate_peril(c)
			for ally in combatants:
				if not ally.alive or ally.side != c.side:
					continue
				if manager._has_left_immediate_peril_permanently(ally) and ally.get("failed_medical_parts", []).size() > 0:
					ally.failed_medical_parts = []
					for other in combatants:
						var pr = other.get("pending_retry", {})
						if not pr.is_empty() and pr.get("target_id", -1) == ally.id:
							other.pending_retry = {}
			for ally in combatants:
				if not ally.alive or ally.side != c.side or ally.node == null:
					continue
				if ally.side != medical_phase_winner:
					continue
				if not ally.node.has_method("get_wounded_parts"):
					continue
				if immediate_peril and ally.id != c.id:
					continue
				var wounded: Array = ally.node.get_wounded_parts()
				for part in wounded:
					if part.is_empty():
						continue
					var tgt_id: int = ally.id
					for act in manager._get_ally_medical_actions(c, ally, part):
						actions.append({ "target_id": tgt_id, "move_id": act.move_id, "target_part": act.target_part })
	var medical_count: int = 0
	for a in actions:
		var mid: String = a.get("move_id", "")
		if mid in CombatConstants.MEDICAL_MOVE_IDS:
			medical_count += 1
	if medical_count > 0 and CombatConstants.COMBAT_EVENT_DEBUG:
		CombatDebug.flow_log("get_available_actions id=%d => %d actions (%d medical)" % [combatant_id, actions.size(), medical_count])
	return actions


## When no combat actions exist, or only formation movement moves remain, offer wait (avoid ping-pong).
static func _append_combat_wait_if_needed(actions: Array, combatant_id: int) -> void:
	if actions.is_empty():
		actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
		return
	for a in actions:
		if a.get("move_id", "") not in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
			return
	actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
