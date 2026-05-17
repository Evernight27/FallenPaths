class_name AvailableActionsBuilder
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _CrashActions := preload("res://combat/CombatCrashActions.gd")
## Builds available actions for a combatant (attacks, medical). Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess),
## _get_parts_being_treated_on, _get_ally_medical_actions, _is_in_immediate_peril, _has_left_immediate_peril_permanently,
## combatants, medical_phase, medical_phase_winner.

static func formation_density_label(manager: Node, fid: String) -> String:
	if manager == null or fid.is_empty():
		return "normal"
	var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
	if form.is_empty():
		return "normal"
	return str(form.get("density", "normal"))


## Self-target `fall_back` into empty same-file rank-1: strict/normal discipline forbids; `loose` allows only when desperate/peril and line closure policy matches action builder.
static func solo_fall_back_action_legal(manager: Node, atk: Dictionary) -> bool:
	if manager == null or atk.is_empty():
		return false
	if not _EntityAccess.can_flee_or_fall_back(atk):
		return false
	if _EntityAccess.rank_int(atk) != 0:
		return false
	if _ZoneOfControl.is_intruded(atk):
		return false
	if _in_pair_abort_cooldown(manager, atk):
		return false
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, atk)
	var our_formation: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, atk, fid)
	if our_formation.is_empty():
		return false
	if int(our_formation.get("ranks", 1)) <= 1:
		return false
	if _FormationBreachRules.breach_blocks_open_lane_moves(manager, our_formation):
		return false
	var disc: String = CombatFormationEngagement.effective_line_discipline(manager, our_formation)
	if not CombatConstants.line_discipline_allows_solo_fall_back(disc):
		return false
	var our_file: int = _EntityAccess.file_int(atk)
	var slots_check: Dictionary = _FormationSlots.formation_slots_dict(our_formation)
	if _FormationSlots.slot_has_any_living_occupant(manager, slots_check, Vector2i(1, our_file)):
		return false
	if _FormationFlow.formation_has_frontline_fill_opportunity_at_file(manager, fid, our_file):
		return false
	return _EntityAccess.retreat_formation_body_damage_warranted(atk, manager)


static func formation_retreat_only_for(c: Dictionary) -> bool:
	return _MobilityRetreat.formation_retreat_only_for(c)


static func cannot_commit_melee(c: Dictionary) -> bool:
	return _MobilityRetreat.cannot_commit_melee(c)


static func resolve_move_allowed_when_cannot_melee(
	move_id: String, target_id: int, attacker_id: int
) -> bool:
	return _MobilityRetreat.resolve_move_allowed_when_cannot_melee(move_id, target_id, attacker_id)


static func is_offensive_melee_move_id(move_id: String) -> bool:
	return _MobilityRetreat.is_offensive_melee_move_id(move_id)


static func sync_cowering_state_if_no_functional_arm(c: Dictionary) -> void:
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c)


static func react_attacking_arm_lost_if_needed(manager: Node, c: Dictionary) -> void:
	_MobilityRetreat.react_attacking_arm_lost_if_needed(manager, c)


static func filter_actions_for_retreat_only(actions: Array, c: Dictionary) -> Array:
	return _MobilityRetreat.filter_actions_for_retreat_only(actions, c)


## Authoritative pair geometry — implementation in **`CombatPairGeometry`** (forwards preserve harness / call sites).
static func effective_pair_geometry(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> Dictionary:
	return _PairGeometry.effective_pair_geometry(
		manager, a, b, formation_a_cache, formation_b_cache
	)


static func effective_pair_file_spacing_equivalent(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> float:
	return _PairGeometry.effective_pair_file_spacing_equivalent(
		manager, a, b, formation_a_cache, formation_b_cache
	)


static func effective_pair_eff_dist(
	manager: Node,
	a: Dictionary,
	b: Dictionary,
	formation_a_cache: Variant = null,
	formation_b_cache: Variant = null
) -> float:
	return _PairGeometry.effective_pair_eff_dist(
		manager, a, b, formation_a_cache, formation_b_cache
	)


static func melee_weapon_reach(c: Dictionary) -> float:
	var w = _EntityAccess.get_weapon(c)
	if w == null:
		return 0.0
	return float(w.melee_range)


## Suffix for `get_available_actions` line only (back-rank depth polearm geometry); empty if N/A.
static func _format_depth_polearm_melee_context(manager: Node, c: Dictionary, wpn: Weapon, combatants: Array) -> String:
	var fid_ctx: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	var lane_open: bool = _DepthPolearm.depth_polearm_lane_open(manager, c, fid_ctx)
	var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(manager, c, fid_ctx)
	var front_id: int = _EntityAccess.id_int(front) if not front.is_empty() else -1
	var fd_ctx: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_ctx)
	var dens: String = str(fd_ctx.get("density", "normal")) if not fd_ctx.is_empty() else "normal"
	var melee_range: float = float(wpn.melee_range)
	var bits: PackedStringArray = []
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, 0):
		var pair_geom: Dictionary = effective_pair_geometry(manager, c, opp)
		var eff: float = float(pair_geom.get("eff_dist", 0.0))
		var dist: String = str(
			_EntityAccess.nested_dictionary_read(c, "distance_to").get(
				_EntityAccess.id_int(opp), CombatConstants.DISTANCE_LONG
			)
		)
		var swing: bool = melee_range >= eff
		# `line_ok`: same gate as `_melee_pair_rank_allowed` / `_opp_matches_melee_rank_target` (not `threatens_line_target` alone).
		var line_ok: bool = _DepthPolearm.depth_polearm_valid_line_threat(manager, c, opp, fid_ctx, lane_open)
		var threaten: bool = swing and line_ok and can_melee_threaten(manager, c, opp, pair_geom)
		bits.append(
			"opp%d eff=%.2f dist=%s reach_ok=%s line_ok=%s threaten=%s"
			% [_EntityAccess.id_int(opp), eff, dist, swing, line_ok, threaten]
		)
	if bits.is_empty():
		for opp in combatants:
			if not _EntityAccess.alive_bool(opp) or _EntityAccess.side_str(opp) == _EntityAccess.side_str(c):
				continue
			if _EntityAccess.rank_int(opp) != 0:
				continue
			var fid_o: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, opp)
			var fo: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp, fid_o)
			var eff: float = float(
				effective_pair_geometry(manager, c, opp, fd_ctx, fo).get("eff_dist", 0.0)
			)
			var dist: String = str(
				_EntityAccess.nested_dictionary_read(c, "distance_to").get(
					_EntityAccess.id_int(opp), CombatConstants.DISTANCE_LONG
				)
			)
			var swing: bool = melee_range >= eff
			bits.append(
				"opp%d eff=%.2f dist=%s reach_ok=%s (no spear lane — geometry only)"
				% [_EntityAccess.id_int(opp), eff, dist, swing]
			)
		if bits.is_empty():
			bits.append("(no enemy rank-0)")
	return (
		" | polearm id=%d %s rank=%d file=%d reach_m=%.2f lane_open=%s front_ally=%d dens=%s || %s"
		% [
			_EntityAccess.id_int(c),
			wpn.display_name,
			_EntityAccess.rank_int(c),
			_EntityAccess.file_int(c),
			melee_range,
			lane_open,
			front_id,
			dens,
			" ; ".join(bits)
		]
	)


## Tier 3.1 strike measure + pair stamping — **`CombatStrikeStamping`** (forwards preserve harness / call sites).
static func strike_measure_ratio_for_weapon_eff_dist(weapon: RefCounted, eff_dist: float) -> float:
	return _StrikeStamping.strike_measure_ratio_for_weapon_eff_dist(weapon, eff_dist)


static func strike_measure_ratio_for_attack_pair(
	manager: Node,
	atk: Dictionary,
	tgt: Dictionary,
	weapon: RefCounted,
	stamped_eff_dist: float = -1.0
) -> float:
	return _StrikeStamping.strike_measure_ratio_for_attack_pair(
		manager, atk, tgt, weapon, stamped_eff_dist
	)


static func stamp_attack_pair_geometry_on_dict(manager: Node, atk: Dictionary, tgt: Dictionary, pa: Dictionary) -> void:
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(manager, atk, tgt, pa)


static func stamp_strike_realism_on_pa(
	manager: Node,
	atk: Dictionary,
	tgt: Dictionary,
	pa: Dictionary,
	weapon: Variant,
	attack_type: String
) -> void:
	_StrikeStamping.stamp_strike_realism_on_pa(manager, atk, tgt, pa, weapon, attack_type)


static func stamp_attack_pair_and_strike_realism(
	manager: Node,
	atk: Dictionary,
	tgt: Dictionary,
	pa: Dictionary,
	weapon: Variant,
	attack_type: String
) -> void:
	_StrikeStamping.stamp_attack_pair_and_strike_realism(manager, atk, tgt, pa, weapon, attack_type)


static func _melee_pair_rank_allowed(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
	return _MeleeRank.melee_pair_rank_allowed(manager, attacker, defender)


static func _opp_matches_melee_rank_target(
	manager: Node, actor: Dictionary, opp: Dictionary, opp_rank_required: int
) -> bool:
	return _MeleeRank.opp_matches_melee_rank_target(manager, actor, opp, opp_rank_required)


static func _host_formation_has_enemy_intruder(combatants: Array, actor: Dictionary) -> bool:
	return _MeleeRank.host_formation_has_enemy_intruder(combatants, actor)


## Optional **`pair_geometry_cache`**: **`effective_pair_geometry`** result or stamped **`pa`** with **`effective_pair_eff_dist`** (skips a second pair-geometry pass).
static func _eff_dist_from_pair_geometry_cache(pair_geometry_cache: Variant) -> float:
	if pair_geometry_cache == null or not (pair_geometry_cache is Dictionary):
		return -1.0
	var g: Dictionary = pair_geometry_cache as Dictionary
	if g.has("effective_pair_eff_dist"):
		return float(g.get("effective_pair_eff_dist", -1.0))
	if g.has("eff_dist"):
		return float(g.get("eff_dist", -1.0))
	return -1.0


## True if attacker could list a non-parry melee strike vs defender (weapon reach + distance band vs build()).
static func can_melee_threaten(
	manager: Node,
	attacker: Dictionary,
	defender: Dictionary,
	pair_geometry_cache: Variant = null
) -> bool:
	if not _EntityAccess.alive_bool(attacker) or not _EntityAccess.alive_bool(defender):
		return false
	if _EntityAccess.side_str(attacker) == _EntityAccess.side_str(defender):
		return false
	if _EntityAccess.is_incapacitated(defender):
		return false
	if not _melee_pair_rank_allowed(manager, attacker, defender):
		return false
	if _EntityAccess.get_attacking_arm(attacker).is_empty():
		return false
	var weapon = _EntityAccess.get_weapon(attacker)
	if not _EntityAccess.weapon_has_attack_types(weapon):
		return false
	var melee_range: float = float(weapon.melee_range)
	var eff_dist: float = _eff_dist_from_pair_geometry_cache(pair_geometry_cache)
	if eff_dist < 0.0:
		eff_dist = effective_pair_eff_dist(manager, attacker, defender)
	var in_swing_range: bool = melee_range >= eff_dist
	var dist: String = str(
		_EntityAccess.nested_dictionary_read(attacker, "distance_to").get(
			_EntityAccess.id_int(defender), CombatConstants.DISTANCE_LONG
		)
	)
	if not in_swing_range:
		return false
	# CLOSE always; MID if geometric reach clears eff_dist (step-in / lunge — not only polearm REACH_MID_MIN).
	return dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID


## Per-pair failed-close backoff: logic-gates `attempt_close` off the action list until `CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S` elapses.
static func _close_attempt_pair_blocked(manager: Node, attacker: Dictionary, defender_id: int) -> bool:
	var d: Dictionary = _EntityAccess.nested_dictionary_read(attacker, "close_block_until_by_target_id")
	if d.is_empty():
		return false
	var until: Variant = d.get(defender_id, -1.0)
	if float(until) < 0.0:
		return false
	return float(manager.combat_clock) < float(until)


## `CombatEngagementResolver.resolve_close_attempt` only contests at LONG; never list close at MID/CLOSE.
static func _attempt_close_listed_for_pair(
	manager: Node, attacker: Dictionary, defender_id: int, dist: String
) -> bool:
	if dist != CombatConstants.DISTANCE_LONG:
		return false
	return not _close_attempt_pair_blocked(manager, attacker, defender_id)


## Melee / close / crash vs opponents whose `rank` matches `opp_rank_required` (0 = front line; 1 = stalemate fallback when no rank-0 enemy exists).
static func _append_melee_vs_enemy_line_rank(
	manager: Node,
	c: Dictionary,
	combatants: Array,
	actions: Array,
	move_ids: Array,
	melee_range: float,
	opp_rank_required: int,
	zone_geometry_fid: String = "",
	formation_attacker_cache: Variant = null
) -> void:
	var fid_c: String = (
		zone_geometry_fid
		if not zone_geometry_fid.is_empty()
		else _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
	)
	var fc: Dictionary = (
		(formation_attacker_cache as Dictionary)
		if formation_attacker_cache != null and formation_attacker_cache is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_c)
	)
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, opp_rank_required):
		var fid_o: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, opp)
		var fo: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, opp, fid_o)
		var eff_dist: float = float(
			effective_pair_geometry(manager, c, opp, fc, fo).get("eff_dist", 0.0)
		)
		var in_swing_range: bool = melee_range >= eff_dist
		var dist: String = str(
			_EntityAccess.nested_dictionary_read(c, "distance_to").get(
				_EntityAccess.id_int(opp), CombatConstants.DISTANCE_LONG
			)
		)
		if in_swing_range:
			if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID:
				for move_id in move_ids:
					if WeaponConstants.is_parry_move(move_id):
						continue
					actions.append({ "target_id": _EntityAccess.id_int(opp), "move_id": move_id })
			elif _attempt_close_listed_for_pair(manager, c, _EntityAccess.id_int(opp), dist):
				actions.append({ "target_id": _EntityAccess.id_int(opp), "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		else:
			if _attempt_close_listed_for_pair(manager, c, _EntityAccess.id_int(opp), dist):
				actions.append({ "target_id": _EntityAccess.id_int(opp), "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		if _CrashActions.crash_action_eligible(manager, c, opp, in_swing_range, dist):
			actions.append({"target_id": _EntityAccess.id_int(opp), "move_id": CombatConstants.MOVE_ID_CRASH})


static func build(manager: Node, combatant_id: int) -> Array:
	var log_fid: String = ""
	var log_breach_blocks_moves: bool = false
	var c = manager._get_by_id(combatant_id)
	if c == null or not _EntityAccess.alive_bool(c):
		return []
	var counter_tempo: bool = false
	# Gauge fills to 100 on `EVENT_ACTION_READY` only; sub-100 without counter window → no actions (not ready).
	if _EntityAccess.gauge_float(c) < 100.0:
		if _CounterTempo.can_act(manager, c):
			counter_tempo = true
		else:
			return []
	var state: String = _EntityAccess.state_str(c)
	if (
		state != CombatConstants.STATE_WAITING
		and state != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		and state != CombatConstants.STATE_COWERING
	):
		return []
	if _EntityAccess.is_unconscious(c):
		return []
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
	state = _EntityAccess.state_str(c)
	var formation_retreat_only: bool = _MobilityRetreat.formation_retreat_only_for(c)
	var actions: Array = []
	var combatants: Array = manager.combatants
	var medical_phase: bool = manager.medical_phase
	var medical_phase_winner: String = manager.medical_phase_winner

	# Receiving medical care: can hold/switch direct pressure on wounds NOT being treated by ally
	if (
		_EntityAccess.state_str(c) == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		and medical_phase
		and _EntityAccess.side_str(c) == medical_phase_winner
	):
		if _EntityAccess.scene_supports_medical_pressure_listing(c):
			var parts_being_treated: Array = manager._get_parts_being_treated_on(combatant_id)
			for part in _EntityAccess.get_wounded_parts(c):
				if part.is_empty() or part in parts_being_treated:
					continue
				if _EntityAccess.entity_has_direct_pressure_on_part(manager, c, part):
					continue
				if _EntityAccess.entity_can_apply_direct_pressure(manager, c, part):
					actions.append({ "target_id": combatant_id, "move_id": "apply_direct_pressure", "target_part": part })
		return actions

	# Combat phase: attacks and swap rank. Phase 2: filter by distance. Phase 3: rank + formation targeting.
	if not medical_phase:
		var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
		var our_formation: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid)
		var our_rank: int = _EntityAccess.rank_int(c)
		var our_file: int = _EntityAccess.file_int(c)
		var c_intruded: bool = _ZoneOfControl.is_intruded(c)
		# Phase 3: Rank 0 melee; intruders from depth; home ranks ≥1 vs intruders on formation; depth polearm vs line (Tier 1.9).
		var can_melee: bool = (
			not formation_retreat_only
			and (
				our_rank == 0
				or c_intruded
				or _host_formation_has_enemy_intruder(combatants, c)
				or _DepthPolearm.depth_polearm_lane_open(manager, c, fid)
			)
			and not _EntityAccess.get_attacking_arm(c).is_empty()
		)
		if can_melee:
			var weapon = _EntityAccess.get_weapon(c)
			if _EntityAccess.weapon_has_attack_types(weapon):
				var melee_range: float = float(weapon.melee_range)
				var move_ids: Array = _EntityAccess.weapon_attack_types(weapon)
				_append_melee_vs_enemy_line_rank(
					manager, c, combatants, actions, move_ids, melee_range, 0, fid, our_formation
				)
				var any_enemy_rank0: bool = false
				for opp_chk in combatants:
					if _opp_matches_melee_rank_target(manager, c, opp_chk, 0):
						any_enemy_rank0 = true
						break
				# Stalemate safety: `CombatFormationFlow` reconcile should guarantee a rank-0 enemy when possible; if not, avoid soft-lock.
				if not any_enemy_rank0:
					_append_melee_vs_enemy_line_rank(
						manager, c, combatants, actions, move_ids, melee_range, 1, fid, our_formation
					)
		# Phase 3: Swap rank — front→back disengage; plug when front incap; deeper→shallow relief (same column).
		# With 3+ depth ranks, middle/back rows must be able to swap toward the front or they only get wait.
		# Breach congestion: disengage / retreat withheld; plug-forward and relief swaps still allowed (FormationBreachRules.resolve_blocks_formation_move).
		# Skirmish (collapsed line) can uncleg moves; see FormationBreachRules.breach_blocks_open_lane_moves.
		var formation_ranks: int = our_formation.get("ranks", 1)
		var breach_blocks_moves: bool = not our_formation.is_empty() and _FormationBreachRules.breach_blocks_open_lane_moves(manager, our_formation)
		var pair_abort_blocked: bool = _in_pair_abort_cooldown(manager, c)
		var move_policy: Dictionary = _EngagementMode.movement_policy(manager)
		var can_swap_rank: bool = bool(move_policy.get("allow_swap_rank", false))
		var can_drag_back: bool = bool(move_policy.get("allow_drag_back", false))
		var can_fall_back: bool = bool(move_policy.get("allow_fall_back", false))
		log_fid = fid
		log_breach_blocks_moves = breach_blocks_moves
		if (
			not formation_retreat_only
			and not our_formation.is_empty()
			and formation_ranks > 1
			and not c_intruded
			and not pair_abort_blocked
			and _EntityAccess.can_flee_or_fall_back(c)
			and (can_swap_rank or can_drag_back)
		):
			if not breach_blocks_moves:
				for ally in combatants:
					if (
						not _EntityAccess.alive_bool(ally)
						or _EntityAccess.side_str(ally) != _EntityAccess.side_str(c)
						or _ZoneOfControl.formation_id_for_zone_geometry(manager, ally) != fid
					):
						continue
					if _EntityAccess.state_str(ally) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
						continue  # Partner busy
					var partner_rank: int = _EntityAccess.rank_int(ally)
					var partner_file: int = _EntityAccess.file_int(ally)
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
							allow_swap = CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, ally, manager)
						if allow_swap:
							actions.append({ "target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_SWAP_RANK })
							# Drag / fall_back_pair are front-line retreat flavors; relief rotation uses quick swap only.
							if not we_plug_forward and we_are_front and can_drag_back:
								actions.append({ "target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_DRAG_BACK })
								actions.append({ "target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_FALL_BACK })
						break
			else:
				for ally in combatants:
					if (
						not _EntityAccess.alive_bool(ally)
						or _EntityAccess.side_str(ally) != _EntityAccess.side_str(c)
						or _ZoneOfControl.formation_id_for_zone_geometry(manager, ally) != fid
					):
						continue
					if _EntityAccess.state_str(ally) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
						continue
					var partner_rank: int = _EntityAccess.rank_int(ally)
					var partner_file: int = _EntityAccess.file_int(ally)
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
						actions.append({ "target_id": _EntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_SWAP_RANK })
					break
		# Lateral front-row moves are **not** offered as voluntary actions: `CombatFormationFlow.reconcile_vacancy_plugs_*`
		# closes rank-0 holes with scored lateral plugs only when a hole exists.
		# Phase 5: fall back solo — only under `line_discipline` loose; strict/normal use paired relief only.
		if (
			not formation_retreat_only
			and not our_formation.is_empty()
			and formation_ranks > 1
			and our_rank == 0
			and not breach_blocks_moves
			and not c_intruded
			and not pair_abort_blocked
			and can_fall_back
			and _EntityAccess.can_flee_or_fall_back(c)
			and solo_fall_back_action_legal(manager, c)
		):
			actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FALL_BACK})
		if formation_retreat_only:
			# Cowering retreat: do not require stable_line `allow_fall_back` (casualties can set intrusions>0).
			if (
				not our_formation.is_empty()
				and formation_ranks > 1
				and our_rank == 0
				and not breach_blocks_moves
				and not c_intruded
				and not pair_abort_blocked
				and _EntityAccess.can_flee_or_fall_back(c)
				and solo_fall_back_action_legal(manager, c)
			):
				actions.append({"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FALL_BACK})
			# Rank > 0 cowering cannot solo fall_back; still offer wait so ticks do not soft-lock.
			_append_combat_wait_if_needed(actions, combatant_id)
			return actions
		_append_focus_line_actions_if_needed(manager, c, combatant_id, actions)
		_append_combat_wait_if_needed(actions, combatant_id)
	else:
		if (
			_EntityAccess.side_str(c) == medical_phase_winner
			and _EntityAccess.scene_can_apply_direct_pressure_api(c)
		):
			var immediate_peril: bool = manager._is_in_immediate_peril(c)
			for ally in combatants:
				if not _EntityAccess.alive_bool(ally) or _EntityAccess.side_str(ally) != _EntityAccess.side_str(c):
					continue
				if manager._has_left_immediate_peril_permanently(ally):
					var fp_raw: Variant = ally.get("failed_medical_parts", null)
					if fp_raw is Array and not (fp_raw as Array).is_empty():
						ally["failed_medical_parts"] = []
					for other in combatants:
						var pr_raw: Variant = other.get("pending_retry", null)
						if typeof(pr_raw) != TYPE_DICTIONARY:
							continue
						var pr: Dictionary = pr_raw as Dictionary
						if not pr.is_empty() and pr.get("target_id", -1) == _EntityAccess.id_int(ally):
							other["pending_retry"] = {}
			for ally in combatants:
				if (
					not _EntityAccess.alive_bool(ally)
					or _EntityAccess.side_str(ally) != _EntityAccess.side_str(c)
					or _EntityAccess.scene_node(ally) == null
				):
					continue
				if _EntityAccess.side_str(ally) != medical_phase_winner:
					continue
				if not _EntityAccess.scene_has_wounded_parts_listing(ally):
					continue
				if immediate_peril and _EntityAccess.id_int(ally) != _EntityAccess.id_int(c):
					continue
				var wounded: Array = _EntityAccess.get_wounded_parts(ally)
				var parts_being_treated: Array = manager._get_parts_being_treated_on(_EntityAccess.id_int(ally))
				for part in wounded:
					if part.is_empty():
						continue
					if part in parts_being_treated:
						continue
					var tgt_id: int = _EntityAccess.id_int(ally)
					for act in manager._get_ally_medical_actions(c, ally, part):
						actions.append({ "target_id": tgt_id, "move_id": act.move_id, "target_part": act.target_part })
	var result_actions: Array = actions
	if counter_tempo:
		result_actions = _CounterTempo.filter_actions_for_counter_tempo(actions, c)
	var medical_count: int = 0
	for a in result_actions:
		var mid: String = str(a.get("move_id", ""))
		if mid in CombatConstants.MEDICAL_MOVE_IDS:
			medical_count += 1
	if CombatDebug.flow_verbose_enabled():
		var crash_count: int = 0
		for a in result_actions:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				crash_count += 1
		var polearm_extra: String = ""
		if not medical_phase:
			var rpv: int = _EntityAccess.rank_int(c)
			var intrv: bool = _ZoneOfControl.is_intruded(c)
			if rpv > 0 and not intrv and not _EntityAccess.get_attacking_arm(c).is_empty():
				var w_pv: Variant = _EntityAccess.get_weapon(c)
				if w_pv is Weapon and (w_pv as Weapon).depth_melee_eligible:
					polearm_extra = _format_depth_polearm_melee_context(manager, c, w_pv as Weapon, combatants)
		var counter_filter_note: String = ""
		if counter_tempo and result_actions.size() != actions.size():
			counter_filter_note = " counter_tempo=%d->%d" % [actions.size(), result_actions.size()]
		CombatDebug.flow_log(
			(
				"get_available_actions id=%d side=%s state=%s rank=%d file=%d fid=%s breach_blocks_moves=%s med_phase=%s "
				+ "crash_viab=%.3f => %d actions (medical=%d crash=%d) [%s]%s%s"
			)
			% [
				combatant_id,
				_EntityAccess.side_str(c),
				_EntityAccess.state_str(c),
				_EntityAccess.rank_int(c),
				_EntityAccess.file_int(c),
				log_fid,
				log_breach_blocks_moves,
				medical_phase,
				CombatConstants.crash_breach_viability(c),
				result_actions.size(),
				medical_count,
				crash_count,
				CombatDebug.format_actions_compact(result_actions),
				polearm_extra,
				counter_filter_note
			],
			"get_available_actions:%d" % combatant_id
		)
		var dbg_intruded: bool = _ZoneOfControl.is_intruded(c)
		if (
			not medical_phase
			and (_EntityAccess.rank_int(c) == 0 or dbg_intruded)
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
					crash_absent_primary_reason(manager, c),
					CombatConstants.crash_breach_viability(c),
					_EntityAccess.tactical_penetration_depth_int(c),
					CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX,
					_EntityAccess.stamina_float(c, 0.0),
					CombatConstants.CRASH_STAMINA_COST,
					float(c.get("crash_cooldown_until", 0.0)),
					clock,
					log_breach_blocks_moves,
					_FormationBreachRules.is_skirmish_line_engagement(manager)
				],
				"crash_not_in_list:%d" % combatant_id
			)
	return result_actions


static func crash_absent_primary_reason(manager: Node, c: Dictionary) -> String:
	return _CrashActions.crash_absent_primary_reason(manager, c)


static func format_crash_absent_reason_for_ui(reason_key: String) -> String:
	return _CrashActions.format_crash_absent_reason_for_ui(reason_key)


## Tier 4.3.7: self-target guard-line / focus retarget while waiting.
static func _append_focus_line_actions_if_needed(
	_manager: Node, c: Dictionary, combatant_id: int, actions: Array
) -> void:
	if not _Attention.enabled() or c.is_empty():
		return
	for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
		actions.append({"target_id": combatant_id, "move_id": move_id})


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
