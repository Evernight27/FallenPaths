class_name AvailableActionsBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
## Builds available actions for a combatant (attacks, medical). Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess),
## _get_parts_being_treated_on, _get_ally_medical_actions, _is_in_immediate_peril, _has_left_immediate_peril_permanently,
## combatants, medical_phase, medical_phase_winner.

static func _formation_id_for_pair_geometry(manager: Node, c: Dictionary) -> String:
	return _ZoneOfControl.formation_id_for_zone_geometry(manager, c)


static func _wedge_distance_pull(manager: Node, a: Dictionary, b: Dictionary, half_width_spacing: float) -> float:
	var host_fid: String = ""
	var anchor_f: int = -1
	if str(a.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		host_fid = str(a.get("intrusion_host_fid", ""))
		anchor_f = int(a.get("intrusion_anchor_file", -1))
	elif str(b.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		host_fid = str(b.get("intrusion_host_fid", ""))
		anchor_f = int(b.get("intrusion_anchor_file", -1))
	if host_fid.is_empty() or anchor_f < 0:
		return 0.0
	var form: Dictionary = manager.formations.get(host_fid, {})
	if form.is_empty():
		return 0.0
	var p: float = _IntrusionWedge.pressure_at_file(form, anchor_f)
	var dep: float = _IntrusionWedge.depth_at_file(form, anchor_f)
	if p <= 0.0001 and dep <= 0.0001:
		return 0.0
	return p * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_PRESSURE_PULL \
		+ dep * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_DEPTH_PULL


## Wedge dict lives on **host** formation; intruders keep home `formation_id` but physically sit on host columns.
## Pressure (x) and depth (y) at this combatant’s engagement column (host wedge + anchor when intruded).
static func _wedge_pressure_depth_at_combatant_column(manager: Node, c: Dictionary) -> Vector2:
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		var hf: String = str(c.get("intrusion_host_fid", ""))
		if hf.is_empty():
			return Vector2.ZERO
		var form_i: Dictionary = manager.formations.get(hf, {})
		if form_i.is_empty():
			return Vector2.ZERO
		var fi_i: int = int(c.get("intrusion_anchor_file", c.get("file", 0)))
		return Vector2(_IntrusionWedge.pressure_at_file(form_i, fi_i), _IntrusionWedge.depth_at_file(form_i, fi_i))
	var fid: String = str(c.get("formation_id", ""))
	if fid.is_empty():
		return Vector2.ZERO
	var form: Dictionary = manager.formations.get(fid, {})
	if form.is_empty():
		return Vector2.ZERO
	var fi: int = int(c.get("file", 0))
	return Vector2(_IntrusionWedge.pressure_at_file(form, fi), _IntrusionWedge.depth_at_file(form, fi))


## Corridor pull when neither side uses intruder anchor path: wedge on someone's home column still tightens reach.
static func _wedge_bystander_corridor_pull(manager: Node, a: Dictionary, b: Dictionary, half_width_spacing: float) -> float:
	var va: Vector2 = _wedge_pressure_depth_at_combatant_column(manager, a)
	var vb: Vector2 = _wedge_pressure_depth_at_combatant_column(manager, b)
	var p: float = maxf(va.x, vb.x)
	var dep: float = maxf(va.y, vb.y)
	if p <= 0.0001 and dep <= 0.0001:
		return 0.0
	var m: float = CombatConstants.EFF_DIST_WEDGE_BYSTANDER_MULT
	return p * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_PRESSURE_PULL * m \
		+ dep * half_width_spacing * CombatConstants.EFF_DIST_WEDGE_DEPTH_PULL * m


## Continuous "file spacing" units matching `effective_pair_eff_dist` / (half_width * REACH_SAFETY * ZoC geom mult). For MID/LONG band gates vs integer `mid_reach_files`.
static func effective_pair_file_spacing_equivalent(manager: Node, a: Dictionary, b: Dictionary) -> float:
	var fid_a: String = _formation_id_for_pair_geometry(manager, a)
	var fid_b: String = _formation_id_for_pair_geometry(manager, b)
	var fa: Dictionary = manager.formations.get(fid_a, {})
	var fb: Dictionary = manager.formations.get(fid_b, {})
	var df_fb: float = absf(float(a.get("file", 0) - b.get("file", 0)))
	if fa.is_empty() or fb.is_empty():
		return df_fb
	var sa: float = CombatConstants.get_spacing_from_density(fa.get("density", "normal"))
	var sb: float = CombatConstants.get_spacing_from_density(fb.get("density", "normal"))
	var half_width: float = (sa + sb) * 0.5
	if half_width < 1e-5:
		return df_fb
	var zoc_m: float = _ZoneOfControl.geometric_reach_extent_multiplier(manager, a, b)
	var denom: float = half_width * CombatConstants.REACH_SAFETY_FACTOR * maxf(0.001, zoc_m)
	return effective_pair_eff_dist(manager, a, b) / denom


## Geometric separation along files + lane_offset lateral metric − wedge pull (intrusion corridor).
static func effective_pair_eff_dist(manager: Node, a: Dictionary, b: Dictionary) -> float:
	var fid_a: String = _formation_id_for_pair_geometry(manager, a)
	var fid_b: String = _formation_id_for_pair_geometry(manager, b)
	var fa: Dictionary = manager.formations.get(fid_a, {})
	var fb: Dictionary = manager.formations.get(fid_b, {})
	var df: float = absf(float(a.get("file", 0) - b.get("file", 0)))
	if fa.is_empty() or fb.is_empty():
		return df * CombatConstants.SPACING_NORMAL * CombatConstants.REACH_SAFETY_FACTOR
	var sa: float = CombatConstants.get_spacing_from_density(fa.get("density", "normal"))
	var sb: float = CombatConstants.get_spacing_from_density(fb.get("density", "normal"))
	var half_width: float = (sa + sb) * 0.5
	var base: float = df * half_width * CombatConstants.REACH_SAFETY_FACTOR
	var loa: float = clampf(
		float(a.get("lane_offset", 0.0)),
		-CombatConstants.LANE_OFFSET_ABS_MAX,
		CombatConstants.LANE_OFFSET_ABS_MAX
	)
	var lob: float = clampf(
		float(b.get("lane_offset", 0.0)),
		-CombatConstants.LANE_OFFSET_ABS_MAX,
		CombatConstants.LANE_OFFSET_ABS_MAX
	)
	var lateral_frac: float = absf(loa - lob)
	var lateral: float = (
		lateral_frac
		* CombatConstants.EFF_DIST_LANE_OFFSET_FILE_EQUIV
		* half_width
		* CombatConstants.REACH_SAFETY_FACTOR
	)
	var wedge_pull: float = maxf(
		_wedge_distance_pull(manager, a, b, half_width),
		_wedge_bystander_corridor_pull(manager, a, b, half_width)
	)
	var pre_zoc: float = maxf(0.04, base + lateral - wedge_pull)
	return pre_zoc * _ZoneOfControl.geometric_reach_extent_multiplier(manager, a, b)

static func melee_weapon_reach(c: Dictionary) -> float:
	var w = _EntityAccess.get_weapon(c)
	if w == null:
		return 0.0
	return float(w.melee_range)


## Front-line vs front-line; intruder vs host rank-0; host **any depth** vs intruder on that host formation; intruders strike rank-0 hosts.
static func _melee_pair_rank_allowed(attacker: Dictionary, defender: Dictionary) -> bool:
	var ar: int = int(attacker.get("rank", 0))
	var dr: int = int(defender.get("rank", 0))
	var ai: bool = str(attacker.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	var di: bool = str(defender.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	var ahf: String = str(attacker.get("intrusion_host_fid", ""))
	var dhf: String = str(defender.get("intrusion_host_fid", ""))
	if ar == 0 and dr == 0 and not ai and not di:
		return true
	if ai and not ahf.is_empty() and str(defender.get("formation_id", "")) == ahf and dr == 0:
		return true
	if di and not dhf.is_empty() and str(attacker.get("formation_id", "")) == dhf:
		return true
	return false


## Host formation for “who is this column on?” — intruders occupy host `slots` while `formation_id` stays home (P4).
static func _actor_host_fid_for_melee_targeting(actor: Dictionary) -> String:
	if str(actor.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		var hf: String = str(actor.get("intrusion_host_fid", ""))
		if not hf.is_empty():
			return hf
	return str(actor.get("formation_id", ""))


## `opp_rank_required` 0/1 file rank, or intruder lodged on actor’s host line (any depth) for 0/1 stalemate passes.
## Home rank > 0 must not use the rank-0 line pass to pick **non-intruding** enemy rank 0 (reach still gates intruders).
static func _opp_matches_melee_rank_target(actor: Dictionary, opp: Dictionary, opp_rank_required: int) -> bool:
	if not opp.get("alive", false) or opp.get("side", "") == actor.get("side", ""):
		return false
	var host_fid: String = _actor_host_fid_for_melee_targeting(actor)
	var ornk: int = int(opp.get("rank", 0))
	var opp_intr_on_actor_host: bool = (
		str(opp.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
		and str(opp.get("intrusion_host_fid", "")) == host_fid
	)
	if ornk == opp_rank_required:
		if (
			opp_rank_required == 0
			and int(actor.get("rank", 0)) > 0
			and str(actor.get("engagement_role", "")) != CombatConstants.ENGAGEMENT_ROLE_INTRUDED
			and not opp_intr_on_actor_host
		):
			return false
		return true
	if opp_rank_required <= 1 and opp_intr_on_actor_host:
		return true
	return false


static func _host_formation_has_enemy_intruder(combatants: Array, actor: Dictionary) -> bool:
	if str(actor.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return false
	var fid: String = str(actor.get("formation_id", ""))
	if fid.is_empty():
		return false
	var side: String = str(actor.get("side", ""))
	for x in combatants:
		if not x.get("alive", false):
			continue
		if str(x.get("side", "")) == side:
			continue
		if str(x.get("engagement_role", "")) != CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			continue
		if str(x.get("intrusion_host_fid", "")) == fid:
			return true
	return false


## True if attacker could list a non-parry melee strike vs defender (weapon reach + distance band vs build()).
static func can_melee_threaten(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
	if not attacker.get("alive", false) or not defender.get("alive", false):
		return false
	if attacker.get("side", "") == defender.get("side", ""):
		return false
	if not _melee_pair_rank_allowed(attacker, defender):
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


## Melee / close / crash vs opponents whose `rank` matches `opp_rank_required` (0 = front line; 1 = stalemate fallback when no rank-0 enemy exists).
static func _append_melee_vs_enemy_line_rank(
	manager: Node,
	c: Dictionary,
	combatants: Array,
	actions: Array,
	move_ids: Array,
	melee_range: float,
	can_attack_from_mid: bool,
	opp_rank_required: int
) -> void:
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, opp_rank_required):
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
			if dist in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID, CombatConstants.DISTANCE_LONG]:
				actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		if _crash_action_eligible(manager, c, opp, melee_range, can_attack_from_mid, eff_dist, in_swing_range, dist):
			actions.append({"target_id": opp.id, "move_id": CombatConstants.MOVE_ID_CRASH})


static func build(manager: Node, combatant_id: int) -> Array:
	var log_fid: String = ""
	var log_breach_blocks_moves: bool = false
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
			var entity = _EntityAccess.get_entity_from_manager(manager, c)
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
		var c_intruded: bool = str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
		# Phase 3: Rank 0 melee; intruders from depth; home ranks ≥1 may melee **enemy intruders on this formation** (reach + pair rules).
		var can_melee: bool = (
			our_rank == 0
			or c_intruded
			or _host_formation_has_enemy_intruder(combatants, c)
		) and not _EntityAccess.get_attacking_arm(c).is_empty()
		if can_melee:
			var weapon = _EntityAccess.get_weapon(c)
			if weapon != null and weapon.has_method("get_available_attack_types"):
				var melee_range: float = float(weapon.melee_range)
				var can_attack_from_mid: bool = melee_range >= CombatConstants.REACH_MID_MIN
				var move_ids: Array = weapon.get_available_attack_types()
				_append_melee_vs_enemy_line_rank(
					manager, c, combatants, actions, move_ids, melee_range, can_attack_from_mid, 0
				)
				var any_enemy_rank0: bool = false
				for opp_chk in combatants:
					if _opp_matches_melee_rank_target(c, opp_chk, 0):
						any_enemy_rank0 = true
						break
				# Stalemate safety: `CombatFormationFlow` reconcile should guarantee a rank-0 enemy when possible; if not, avoid soft-lock.
				if not any_enemy_rank0:
					_append_melee_vs_enemy_line_rank(
						manager, c, combatants, actions, move_ids, melee_range, can_attack_from_mid, 1
					)
		# Phase 3: Swap rank — front→back disengage; plug when front incap; deeper→shallow relief (same column).
		# With 3+ depth ranks, middle/back rows must be able to swap toward the front or they only get wait.
		# Breach congestion: disengage / retreat withheld; plug-forward and relief swaps still allowed (FormationBreachRules.resolve_blocks_formation_move).
		# Same-rank rotate_file is line movement and stays available under breach (see Phase 5).
		# Skirmish (collapsed line) can uncleg moves; see FormationBreachRules.breach_blocks_open_lane_moves.
		var formation_ranks: int = our_formation.get("ranks", 1)
		var breach_blocks_moves: bool = not our_formation.is_empty() and _FormationBreachRules.breach_blocks_open_lane_moves(manager, our_formation)
		var pair_abort_blocked: bool = _in_pair_abort_cooldown(manager, c)
		var rotate_blocked: bool = _in_rotate_file_cooldown(manager, c)
		var frontline_fill_required: bool = _FormationFlow.formation_has_frontline_fill_opportunity(
			manager, fid
		)
		var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
		var can_swap_rank: bool = bool(move_policy.get("allow_swap_rank", false))
		var can_drag_back: bool = bool(move_policy.get("allow_drag_back", false))
		var can_fall_back: bool = bool(move_policy.get("allow_fall_back", false))
		var can_rotate_file: bool = bool(move_policy.get("allow_rotate_file", false))
		log_fid = fid
		log_breach_blocks_moves = breach_blocks_moves
		if (
			not our_formation.is_empty()
			and formation_ranks > 1
			and not c_intruded
			and not pair_abort_blocked
			and (can_swap_rank or can_drag_back)
		):
			if not breach_blocks_moves:
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
							if not we_plug_forward and we_are_front and can_drag_back:
								actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_DRAG_BACK })
								actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_FALL_BACK })
						break
			else:
				for ally in combatants:
					if not ally.alive or ally.side != c.side or ally.get("formation_id", "") != fid:
						continue
					if ally.get("state", "") in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
						continue
					var partner_rank: int = ally.get("rank", 0)
					var partner_file: int = ally.get("file", 0)
					if partner_file != our_file or abs(partner_rank - our_rank) != 1:
						continue
					var partner_incapacitated: bool = _EntityAccess.is_incapacitated(ally)
					var we_plug_forward: bool = partner_rank < our_rank and partner_incapacitated
					var relief_swap: bool = our_rank > partner_rank and not partner_incapacitated \
						and CombatAIActionPicker.is_relief_swap_tactically_allowed(c, ally)
					if not we_plug_forward and not relief_swap:
						continue
					var allow_swap: bool = we_plug_forward or relief_swap
					if allow_swap:
						actions.append({ "target_id": ally.id, "move_id": CombatConstants.MOVE_ID_SWAP_RANK })
					break
		# Phase 5: rotate file — restrict to front rank only.
		# Back-rank lane shuffles can oscillate and fight against vacancy compaction;
		# rear movement should happen via swap/plug, not constant lateral rotate ping-pong.
		if (
			not our_formation.is_empty()
			and formation_ranks > 1
			and not c_intruded
			and our_rank == 0
			and not pair_abort_blocked
			and not rotate_blocked
			and not frontline_fill_required
			and can_rotate_file
		):
			for ally in combatants:
				if not ally.alive or ally.side != c.side or ally.get("formation_id", "") != fid:
					continue
				if ally.get("state", "") in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
					continue
				if _in_rotate_file_cooldown(manager, ally):
					continue
				if ally.get("rank", 0) != our_rank:
					continue
				if abs(ally.get("file", 0) - our_file) != 1:
					continue
				actions.append({"target_id": ally.id, "move_id": CombatConstants.MOVE_ID_ROTATE_FILE})
		# Phase 5: fall back solo — step to rear rank when that slot is empty.
		if (
			not our_formation.is_empty()
			and formation_ranks > 1
			and our_rank == 0
			and not breach_blocks_moves
			and not c_intruded
			and not pair_abort_blocked
			and can_fall_back
		):
			var slots_check: Dictionary = our_formation.get("slots", {})
			if not _FormationSlots.slot_has_any_living_occupant(manager, slots_check, Vector2i(1, our_file)):
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
		var mid: String = str(a.get("move_id", ""))
		if mid in CombatConstants.MEDICAL_MOVE_IDS:
			medical_count += 1
	if CombatConstants.COMBAT_EVENT_DEBUG:
		var crash_count: int = 0
		for a in actions:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				crash_count += 1
		CombatDebug.flow_log(
			"get_available_actions id=%d side=%s state=%s rank=%d file=%d fid=%s breach_blocks_moves=%s med_phase=%s crash_viab=%.3f => %d actions (medical=%d crash=%d) [%s]"
			% [
				combatant_id,
				str(c.get("side", "")),
				str(c.get("state", "")),
				c.get("rank", 0),
				c.get("file", 0),
				log_fid,
				log_breach_blocks_moves,
				medical_phase,
				CombatConstants.crash_breach_viability(c),
				actions.size(),
				medical_count,
				crash_count,
				CombatDebug.format_actions_compact(actions)
			]
		)
		var dbg_intruded: bool = str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
		if (
			not medical_phase
			and (int(c.get("rank", 0)) == 0 or dbg_intruded)
			and not _EntityAccess.get_attacking_arm(c).is_empty()
			and crash_count == 0
			and CombatConstants.crash_breach_viability(c) >= CombatConstants.CRASH_BREACH_VIABILITY_MIN
		):
			var clock: float = 0.0
			var ccv: Variant = manager.get("combat_clock")
			if ccv != null:
				clock = float(ccv)
			CombatDebug.flow_log(
				(
					"crash_not_in_action_list id=%d reason=%s viability=%.3f depth=%d max_depth=%d stamina=%.1f cost=%.1f "
					+ "cd_until=%.2f clock=%.2f breach_blocks_moves=%s skirmish=%s"
				)
				% [
					combatant_id,
					_crash_absent_primary_reason(manager, c),
					CombatConstants.crash_breach_viability(c),
					int(c.get("tactical_penetration_depth", 0)),
					CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX,
					float(c.get("stamina", 0.0)),
					CombatConstants.CRASH_STAMINA_COST,
					float(c.get("crash_cooldown_until", 0.0)),
					clock,
					log_breach_blocks_moves,
					_FormationBreachRules.is_skirmish_line_engagement(manager)
				]
			)
	return actions


## Crash (breach): in weapon reach, at close or mid-with-reach; stamina, cooldown, depth cap (Phase C).
static func _crash_action_eligible(
	manager: Node,
	c: Dictionary,
	_opp: Dictionary,
	_melee_range: float,
	can_attack_from_mid: bool,
	_eff_dist: float,
	in_swing_range: bool,
	dist: String
) -> bool:
	# Intrusion starts from the front line only; rear/intruded depths don't open new crash actions.
	if int(c.get("rank", 0)) != 0:
		return false
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return false
	if not _EngagementMode.crash_intrusion_attacker_allowed(manager, c):
		return false
	if not _EngagementMode.incursion_allowed(manager):
		return false
	if CombatConstants.crash_breach_viability(c) < CombatConstants.CRASH_BREACH_VIABILITY_MIN:
		return false
	if int(c.get("tactical_penetration_depth", 0)) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		return false
	if float(c.get("stamina", 0.0)) < CombatConstants.CRASH_STAMINA_COST:
		return false
	var clock: float = 0.0
	if manager != null:
		var cc: Variant = manager.get("combat_clock")
		if cc != null:
			clock = float(cc)
	if clock < float(c.get("crash_cooldown_until", 0.0)):
		return false
	if not in_swing_range:
		return false
	if dist == CombatConstants.DISTANCE_CLOSE:
		return true
	if dist == CombatConstants.DISTANCE_MID and can_attack_from_mid:
		return true
	return false


## Why crash was not listed despite front rank + viability (for COMBAT_EVENT_DEBUG). Breach clog does not gate crash.
static func _crash_absent_primary_reason(manager: Node, c: Dictionary) -> String:
	var block: String = _EngagementMode.crash_intrusion_attacker_block_reason(manager, c)
	if not block.is_empty():
		return block
	if not _EngagementMode.incursion_allowed(manager):
		var mode_now: String = _EngagementMode.engagement_mode(manager)
		return "engagement_mode_%s" % mode_now
	if int(c.get("tactical_penetration_depth", 0)) >= CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX:
		return "at_max_penetration_depth"
	if float(c.get("stamina", 0.0)) < CombatConstants.CRASH_STAMINA_COST:
		return "low_stamina"
	var clock: float = 0.0
	if manager != null:
		var cc: Variant = manager.get("combat_clock")
		if cc != null:
			clock = float(cc)
	if clock < float(c.get("crash_cooldown_until", 0.0)):
		return "crash_cooldown"
	var weapon = _EntityAccess.get_weapon(c)
	if weapon == null or not weapon.has_method("get_available_attack_types"):
		return "no_melee_weapon_profile"
	var melee_range: float = float(weapon.melee_range)
	var can_attack_from_mid: bool = melee_range >= CombatConstants.REACH_MID_MIN
	var any_enemy_rank0: bool = false
	for opp in manager.combatants:
		if _opp_matches_melee_rank_target(c, opp, 0):
			any_enemy_rank0 = true
			break
	var ranks_to_check: Array = [0] if any_enemy_rank0 else [1]
	var saw_line_enemy: bool = false
	var first_reason: String = ""
	for rank_req in ranks_to_check:
		for opp in manager.combatants:
			if not _opp_matches_melee_rank_target(c, opp, rank_req):
				continue
			saw_line_enemy = true
			var eff_dist: float = effective_pair_eff_dist(manager, c, opp)
			var in_swing: bool = melee_range >= eff_dist
			var dist: String = str(c.get("distance_to", {}).get(opp.get("id", -1), CombatConstants.DISTANCE_LONG))
			if _crash_action_eligible(manager, c, opp, melee_range, can_attack_from_mid, eff_dist, in_swing, dist):
				return "crash_eligible_but_missing_bug"
			if first_reason.is_empty():
				if not in_swing:
					first_reason = "out_of_swing_range"
				elif dist == CombatConstants.DISTANCE_LONG:
					first_reason = "distance_long"
				elif dist == CombatConstants.DISTANCE_MID and not can_attack_from_mid:
					first_reason = "distance_mid_short_weapon"
				else:
					first_reason = "distance_band_%s" % dist
	if not saw_line_enemy:
		return "no_front_rank_enemy"
	return first_reason if not first_reason.is_empty() else "unknown"


## When no combat actions exist, or only formation movement moves remain, offer wait (avoid ping-pong).
static func _append_combat_wait_if_needed(actions: Array, combatant_id: int) -> void:
	if actions.is_empty():
		actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})
		return
	for a in actions:
		if a.get("move_id", "") not in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
			return
	actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT})


static func _in_pair_abort_cooldown(manager: Node, c: Dictionary) -> bool:
	if manager == null:
		return false
	var until: float = float(c.get("formation_pair_abort_cooldown_until", -1.0))
	if until < 0.0:
		return false
	var clock: float = 0.0
	var cc: Variant = manager.get("combat_clock")
	if cc != null:
		clock = float(cc)
	return clock < until


static func _in_rotate_file_cooldown(manager: Node, c: Dictionary) -> bool:
	if manager == null:
		return false
	var until: float = float(c.get("formation_rotate_file_cooldown_until", -1.0))
	if until < 0.0:
		return false
	var clock: float = 0.0
	var cc: Variant = manager.get("combat_clock")
	if cc != null:
		clock = float(cc)
	return clock < until
