class_name AvailableActionsBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Builds available actions for a combatant (attacks, medical). Manager must have: _get_by_id, _get_entity,
## _get_parts_being_treated_on, _get_ally_medical_actions, _is_in_immediate_peril, _has_left_immediate_peril_permanently,
## combatants, medical_phase, medical_phase_winner.

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
					# Phase 3: Formation targeting — opponent must be in rank 0 (front) of their formation to melee.
					var opp_fid: String = opp.get("formation_id", "")
					var opp_formation: Dictionary = manager.formations.get(opp_fid, {}) if manager.formations else {}
					var opp_rank: int = opp.get("rank", 0)
					if not our_formation.is_empty() and not opp_formation.is_empty():
						if opp_rank != 0:
							continue  # Can only melee front rank of enemy formation
						# effective_distance = |Δfile| × avg_spacing; weapon must reach effective_distance × REACH_SAFETY_FACTOR
						var our_spacing: float = CombatConstants.get_spacing_from_density(our_formation.get("density", "normal"))
						var opp_spacing: float = CombatConstants.get_spacing_from_density(opp_formation.get("density", "normal"))
						var avg_spacing: float = (our_spacing + opp_spacing) * 0.5
						var opp_file: int = opp.get("file", 0)
						var eff_dist: float = absf(float(our_file - opp_file)) * avg_spacing * CombatConstants.REACH_SAFETY_FACTOR
						if melee_range < eff_dist:
							continue  # Out of reach
					var dist: String = c.get("distance_to", {}).get(opp.id, CombatConstants.DISTANCE_LONG)
					if dist == CombatConstants.DISTANCE_CLOSE or (dist == CombatConstants.DISTANCE_MID and can_attack_from_mid):
						for move_id in move_ids:
							if WeaponConstants.is_parry_move(move_id):
								continue
							actions.append({ "target_id": opp.id, "move_id": move_id })
					elif dist in [CombatConstants.DISTANCE_MID, CombatConstants.DISTANCE_LONG]:
						actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		# Phase 3: Swap rank — front can initiate to disengage; back can initiate only when front is incapacitated.
		# Rank N may swap with rank N+1 to disengage. Back rank can swap with incapacitated front (plug forward).
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
				# Can we initiate? Front→back (disengage) when partner healthy; back→front when front incapacitated.
				# Do NOT allow front to swap with incapacitated back — that would put the only fighter in the rear.
				var we_are_front: bool = partner_rank > our_rank
				var partner_incapacitated: bool = _EntityAccess.is_incapacitated(ally)
				var we_plug_forward: bool = partner_rank < our_rank and partner_incapacitated
				if (we_are_front and not partner_incapacitated) or we_plug_forward:
					actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_SWAP_RANK })
					break
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
	if medical_count > 0:
		print("[Combat] get_available_actions: combatant_id=%d => %d total (%d medical: bandage/pack/direct_pressure/tourniquet)" % [combatant_id, actions.size(), medical_count])
	return actions
