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


static func formation_density_label(manager: Node, fid: String) -> String:
	if manager == null or fid.is_empty():
		return "normal"
	var form: Dictionary = manager.formations.get(fid, {}) as Dictionary
	if form.is_empty():
		return "normal"
	return str(form.get("density", "normal"))


## Self-target `fall_back` into empty same-file rank-1: strict/normal discipline forbids; `loose` allows only when desperate/peril and line closure policy matches action builder.
static func solo_fall_back_action_legal(manager: Node, atk: Dictionary) -> bool:
	if manager == null or atk.is_empty():
		return false
	if int(atk.get("rank", 0)) != 0:
		return false
	if str(atk.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return false
	if _in_pair_abort_cooldown(manager, atk):
		return false
	var fid: String = str(atk.get("formation_id", ""))
	var our_formation: Dictionary = manager.formations.get(fid, {})
	if our_formation.is_empty():
		return false
	if int(our_formation.get("ranks", 1)) <= 1:
		return false
	if _FormationBreachRules.breach_blocks_open_lane_moves(manager, our_formation):
		return false
	var disc: String = CombatFormationEngagement.effective_line_discipline(manager, our_formation)
	if not CombatConstants.line_discipline_allows_solo_fall_back(disc):
		return false
	var our_file: int = int(atk.get("file", 0))
	var slots_check: Dictionary = our_formation.get("slots", {})
	if _FormationSlots.slot_has_any_living_occupant(manager, slots_check, Vector2i(1, our_file)):
		return false
	if _FormationFlow.formation_has_frontline_fill_opportunity(manager, fid):
		return false
	return _EntityAccess.retreat_formation_body_damage_warranted(atk, manager)


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


## Living same-file rank-0 ally on home formation (opens spear / polearm lane from depth).
static func same_file_living_rank0_ally(manager: Node, c: Dictionary) -> Dictionary:
	if manager == null or c.is_empty():
		return {}
	var fid: String = str(c.get("formation_id", ""))
	if fid.is_empty():
		return {}
	var f: int = int(c.get("file", 0))
	var side: String = str(c.get("side", ""))
	for x in manager.combatants:
		if not x.get("alive", false):
			continue
		if str(x.get("side", "")) != side:
			continue
		if str(x.get("formation_id", "")) != fid:
			continue
		if int(x.get("rank", 0)) != 0:
			continue
		if int(x.get("file", 0)) != f:
			continue
		if _EntityAccess.is_incapacitated(x):
			continue
		return x
	return {}


## Tier 1.9 (P10): home depth rank + `depth_melee_eligible` weapon + same-file front rank alive.
static func depth_polearm_lane_open(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return false
	if int(c.get("rank", 0)) <= 0:
		return false
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return false
	var w: Variant = _EntityAccess.get_weapon(c)
	if w == null or not (w is Weapon) or not (w as Weapon).depth_melee_eligible:
		return false
	return not same_file_living_rank0_ally(manager, c).is_empty()


## Enemy rank 0 lies within the depth-thrust **lateral window** vs our same-file rank-0 partner (channel / angle).
## Does not check weapon reach or distance band — use with `can_melee_threaten` / action build.
static func depth_polearm_threatens_line_target(front_rank0_ally: Dictionary, opp: Dictionary) -> bool:
	if front_rank0_ally.is_empty() or opp.is_empty():
		return false
	if int(front_rank0_ally.get("rank", 0)) != 0 or int(opp.get("rank", 0)) != 0:
		return false
	if str(front_rank0_ally.get("side", "")) == str(opp.get("side", "")):
		return false
	if not opp.get("alive", false):
		return false
	if _EntityAccess.is_incapacitated(opp):
		return false
	var df: int = absi(int(opp.get("file", 0)) - int(front_rank0_ally.get("file", 0)))
	return df <= int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)


static func depth_polearm_valid_line_threat(manager: Node, attacker: Dictionary, opp: Dictionary) -> bool:
	if manager == null or attacker.is_empty() or opp.is_empty():
		return false
	if not depth_polearm_lane_open(manager, attacker):
		return false
	var front: Dictionary = same_file_living_rank0_ally(manager, attacker)
	return depth_polearm_threatens_line_target(front, opp)


## Suffix for `get_available_actions` line only (back-rank depth polearm geometry); empty if N/A.
static func _format_depth_polearm_melee_context(manager: Node, c: Dictionary, wpn: Weapon, combatants: Array) -> String:
	var lane_open: bool = depth_polearm_lane_open(manager, c)
	var front: Dictionary = same_file_living_rank0_ally(manager, c)
	var front_id: int = int(front.get("id", -1)) if not front.is_empty() else -1
	var dens: String = formation_density_label(manager, str(c.get("formation_id", "")))
	var melee_range: float = float(wpn.melee_range)
	var bits: PackedStringArray = []
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, 0):
		var eff: float = effective_pair_eff_dist(manager, c, opp)
		var dist: String = str(c.get("distance_to", {}).get(opp.id, CombatConstants.DISTANCE_LONG))
		var swing: bool = melee_range >= eff
		var line_ok: bool = false
		if not front.is_empty():
			line_ok = depth_polearm_threatens_line_target(front, opp)
		var threaten: bool = swing and line_ok and can_melee_threaten(manager, c, opp)
		bits.append(
			"opp%d eff=%.2f dist=%s reach_ok=%s line_ok=%s threaten=%s"
			% [opp.id, eff, dist, swing, line_ok, threaten]
		)
	if bits.is_empty():
		for opp in combatants:
			if not opp.get("alive", false) or str(opp.get("side", "")) == str(c.get("side", "")):
				continue
			if int(opp.get("rank", 0)) != 0:
				continue
			var eff: float = effective_pair_eff_dist(manager, c, opp)
			var dist: String = str(c.get("distance_to", {}).get(opp.id, CombatConstants.DISTANCE_LONG))
			var swing: bool = melee_range >= eff
			bits.append(
				"opp%d eff=%.2f dist=%s reach_ok=%s (no spear lane — geometry only)"
				% [opp.id, eff, dist, swing]
			)
		if bits.is_empty():
			bits.append("(no enemy rank-0)")
	return (
		" | polearm id=%d %s rank=%d file=%d reach_m=%.2f lane_open=%s front_ally=%d dens=%s || %s"
		% [
			c.get("id", -1),
			wpn.display_name,
			int(c.get("rank", 0)),
			int(c.get("file", 0)),
			melee_range,
			lane_open,
			front_id,
			dens,
			" ; ".join(bits)
		]
	)


## Over-shoulder (tight/normal density) vs open (loose) lane — filters targetable parts for depth thrusts.
static func depth_polearm_targetable_parts_filter(manager: Node, attacker: Dictionary, targetable: Array) -> Array:
	if targetable.is_empty() or manager == null or attacker.is_empty():
		return targetable
	if not depth_polearm_lane_open(manager, attacker):
		return targetable
	if int(attacker.get("rank", 0)) <= 0:
		return targetable
	var dens: String = formation_density_label(manager, str(attacker.get("formation_id", "")))
	if dens == "loose":
		return targetable
	var out: Array = []
	for p in targetable:
		if p == "left_leg" or p == "right_leg":
			continue
		out.append(p)
	return out if not out.is_empty() else targetable


## Front-line vs front-line; intruder vs host rank-0; host **any depth** vs intruder on that host formation; intruders strike rank-0 hosts;
## depth polearm vs enemy rank 0 within `DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES` of the same-file rank-0 partner (Tier 1.9).
static func _melee_pair_rank_allowed(manager: Node, attacker: Dictionary, defender: Dictionary) -> bool:
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
	if manager != null and ar > 0 and not ai and dr == 0 and not di and depth_polearm_lane_open(manager, attacker):
		var front_ally: Dictionary = same_file_living_rank0_ally(manager, attacker)
		return depth_polearm_threatens_line_target(front_ally, defender)
	return false


## Host formation for “who is this column on?” — intruders occupy host `slots` while `formation_id` stays home (P4).
static func _actor_host_fid_for_melee_targeting(actor: Dictionary) -> String:
	if str(actor.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		var hf: String = str(actor.get("intrusion_host_fid", ""))
		if not hf.is_empty():
			return hf
	return str(actor.get("formation_id", ""))


## `opp_rank_required` 0/1 file rank, or intruder lodged on actor’s host line (any depth) for 0/1 stalemate passes.
## Home rank > 0 may pick enemy rank 0 in the depth lateral window when **depth polearm lane** is open (Tier 1.9); else only intruders on host.
static func _opp_matches_melee_rank_target(manager: Node, actor: Dictionary, opp: Dictionary, opp_rank_required: int) -> bool:
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
			if manager == null or not depth_polearm_lane_open(manager, actor):
				return false
			var front_ally: Dictionary = same_file_living_rank0_ally(manager, actor)
			if not depth_polearm_threatens_line_target(front_ally, opp):
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
	if not _melee_pair_rank_allowed(manager, attacker, defender):
		return false
	if _EntityAccess.get_attacking_arm(attacker).is_empty():
		return false
	var weapon = _EntityAccess.get_weapon(attacker)
	if weapon == null or not weapon.has_method("get_available_attack_types"):
		return false
	var melee_range: float = float(weapon.melee_range)
	var eff_dist: float = effective_pair_eff_dist(manager, attacker, defender)
	var in_swing_range: bool = melee_range >= eff_dist
	var dist: String = str(attacker.get("distance_to", {}).get(defender.get("id", -1), CombatConstants.DISTANCE_LONG))
	if not in_swing_range:
		return false
	# CLOSE always; MID if geometric reach clears eff_dist (step-in / lunge — not only polearm REACH_MID_MIN).
	return dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID


## Per-pair failed-close backoff: logic-gates `attempt_close` off the action list until `CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S` elapses.
static func _close_attempt_pair_blocked(manager: Node, attacker: Dictionary, defender_id: int) -> bool:
	var d: Dictionary = attacker.get("close_block_until_by_target_id", {}) as Dictionary
	if d.is_empty():
		return false
	var until: Variant = d.get(defender_id, -1.0)
	if float(until) < 0.0:
		return false
	return float(manager.combat_clock) < float(until)


## Melee / close / crash vs opponents whose `rank` matches `opp_rank_required` (0 = front line; 1 = stalemate fallback when no rank-0 enemy exists).
static func _append_melee_vs_enemy_line_rank(
	manager: Node,
	c: Dictionary,
	combatants: Array,
	actions: Array,
	move_ids: Array,
	melee_range: float,
	opp_rank_required: int
) -> void:
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, opp_rank_required):
		var eff_dist: float = effective_pair_eff_dist(manager, c, opp)
		var in_swing_range: bool = melee_range >= eff_dist
		var dist: String = c.get("distance_to", {}).get(opp.id, CombatConstants.DISTANCE_LONG)
		if in_swing_range:
			if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID:
				for move_id in move_ids:
					if WeaponConstants.is_parry_move(move_id):
						continue
					actions.append({ "target_id": opp.id, "move_id": move_id })
			elif dist == CombatConstants.DISTANCE_LONG:
				if not _close_attempt_pair_blocked(manager, c, opp.id):
					actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		else:
			if dist in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID, CombatConstants.DISTANCE_LONG]:
				if not _close_attempt_pair_blocked(manager, c, opp.id):
					actions.append({ "target_id": opp.id, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE })
		if _crash_action_eligible(manager, c, opp, in_swing_range, dist):
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
		# Phase 3: Rank 0 melee; intruders from depth; home ranks ≥1 vs intruders on formation; depth polearm vs line (Tier 1.9).
		var can_melee: bool = (
			our_rank == 0
			or c_intruded
			or _host_formation_has_enemy_intruder(combatants, c)
			or depth_polearm_lane_open(manager, c)
		) and not _EntityAccess.get_attacking_arm(c).is_empty()
		if can_melee:
			var weapon = _EntityAccess.get_weapon(c)
			if weapon != null and weapon.has_method("get_available_attack_types"):
				var melee_range: float = float(weapon.melee_range)
				var move_ids: Array = weapon.get_available_attack_types()
				_append_melee_vs_enemy_line_rank(
					manager, c, combatants, actions, move_ids, melee_range, 0
				)
				var any_enemy_rank0: bool = false
				for opp_chk in combatants:
					if _opp_matches_melee_rank_target(manager, c, opp_chk, 0):
						any_enemy_rank0 = true
						break
				# Stalemate safety: `CombatFormationFlow` reconcile should guarantee a rank-0 enemy when possible; if not, avoid soft-lock.
				if not any_enemy_rank0:
					_append_melee_vs_enemy_line_rank(
						manager, c, combatants, actions, move_ids, melee_range, 1
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
							allow_swap = CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, ally, manager)
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
		# Lateral front-row moves are **not** offered as voluntary actions: `CombatFormationFlow.reconcile_vacancy_plugs_*`
		# closes rank-0 holes with scored lateral plugs only when a hole exists.
		# Phase 5: fall back solo — only under `line_discipline` loose; strict/normal use paired relief only.
		if (
			not our_formation.is_empty()
			and formation_ranks > 1
			and our_rank == 0
			and not breach_blocks_moves
			and not c_intruded
			and not pair_abort_blocked
			and can_fall_back
			and solo_fall_back_action_legal(manager, c)
		):
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
				var parts_being_treated: Array = manager._get_parts_being_treated_on(ally.id)
				for part in wounded:
					if part.is_empty():
						continue
					if part in parts_being_treated:
						continue
					var tgt_id: int = ally.id
					for act in manager._get_ally_medical_actions(c, ally, part):
						actions.append({ "target_id": tgt_id, "move_id": act.move_id, "target_part": act.target_part })
	var medical_count: int = 0
	for a in actions:
		var mid: String = str(a.get("move_id", ""))
		if mid in CombatConstants.MEDICAL_MOVE_IDS:
			medical_count += 1
	if CombatDebug.flow_verbose_enabled():
		var crash_count: int = 0
		for a in actions:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				crash_count += 1
		var polearm_extra: String = ""
		if not medical_phase:
			var rpv: int = int(c.get("rank", 0))
			var intrv: bool = str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED
			if rpv > 0 and not intrv and not _EntityAccess.get_attacking_arm(c).is_empty():
				var w_pv: Variant = _EntityAccess.get_weapon(c)
				if w_pv is Weapon and (w_pv as Weapon).depth_melee_eligible:
					polearm_extra = _format_depth_polearm_melee_context(manager, c, w_pv as Weapon, combatants)
		CombatDebug.flow_log(
			(
				"get_available_actions id=%d side=%s state=%s rank=%d file=%d fid=%s breach_blocks_moves=%s med_phase=%s "
				+ "crash_viab=%.3f => %d actions (medical=%d crash=%d) [%s]%s"
			)
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
				CombatDebug.format_actions_compact(actions),
				polearm_extra
			],
			"get_available_actions:%d" % combatant_id
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
					crash_absent_primary_reason(manager, c),
					CombatConstants.crash_breach_viability(c),
					int(c.get("tactical_penetration_depth", 0)),
					CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX,
					float(c.get("stamina", 0.0)),
					CombatConstants.CRASH_STAMINA_COST,
					float(c.get("crash_cooldown_until", 0.0)),
					clock,
					log_breach_blocks_moves,
					_FormationBreachRules.is_skirmish_line_engagement(manager)
				],
				"crash_not_in_list:%d" % combatant_id
			)
	return actions


## Crash (breach): in weapon reach, at close or mid with geometric reach; stamina, cooldown, depth cap (Phase C).
static func _crash_action_eligible(
	manager: Node,
	c: Dictionary,
	_opp: Dictionary,
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
	return dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID


## Why crash was not listed despite front rank + viability (for verbose flow logs / UI hints). Breach clog does not gate crash.
static func crash_absent_primary_reason(manager: Node, c: Dictionary) -> String:
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
	var any_enemy_rank0: bool = false
	for opp in manager.combatants:
		if _opp_matches_melee_rank_target(manager, c, opp, 0):
			any_enemy_rank0 = true
			break
	var ranks_to_check: Array = [0] if any_enemy_rank0 else [1]
	var saw_line_enemy: bool = false
	var first_reason: String = ""
	for rank_req in ranks_to_check:
		for opp in manager.combatants:
			if not _opp_matches_melee_rank_target(manager, c, opp, rank_req):
				continue
			saw_line_enemy = true
			var eff_dist: float = effective_pair_eff_dist(manager, c, opp)
			var in_swing: bool = melee_range >= eff_dist
			var dist: String = str(c.get("distance_to", {}).get(opp.get("id", -1), CombatConstants.DISTANCE_LONG))
			if _crash_action_eligible(manager, c, opp, in_swing, dist):
				return "crash_eligible_but_missing_bug"
			if first_reason.is_empty():
				if not in_swing:
					first_reason = "out_of_swing_range"
				elif dist == CombatConstants.DISTANCE_LONG:
					first_reason = "distance_long"
				else:
					first_reason = "distance_band_%s" % dist
	if not saw_line_enemy:
		return "no_front_rank_enemy"
	return first_reason if not first_reason.is_empty() else "unknown"


static func format_crash_absent_reason_for_ui(reason_key: String) -> String:
	var k: String = str(reason_key)
	if k.begins_with("engagement_mode_"):
		var m: String = k.trim_prefix("engagement_mode_")
		return "Breach rush unavailable: %s" % _EngagementMode.mode_display_name(m)
	match k:
		"intrusion_disabled":
			return "Breach rush unavailable: intrusions disabled (development flag)"
		"intruder_cap":
			return "Breach rush unavailable: intruder cap (heavy armor role)"
		"light_armor":
			return "Breach rush unavailable: need heavy armor (mass)"
		"low_breach_power":
			return "Breach rush unavailable: not strong enough for a line breach"
		"at_max_penetration_depth":
			return "Breach rush unavailable: at max penetration depth"
		"low_stamina":
			return "Breach rush unavailable: low stamina"
		"crash_cooldown":
			return "Breach rush unavailable: crash on cooldown"
		"no_melee_weapon_profile":
			return "Breach rush unavailable: no melee weapon"
		"no_front_rank_enemy":
			return "Breach rush unavailable: no valid front target"
		"out_of_swing_range":
			return "Breach rush unavailable: out of weapon reach"
		"distance_long":
			return "Breach rush unavailable: target too far"
		"unknown":
			return "Breach rush unavailable"
		_:
			if k.begins_with("distance_band_"):
				return "Breach rush unavailable: spacing (%s)" % k.trim_prefix("distance_band_")
			return "Breach rush unavailable (%s)" % k


## Player UI / combat log: one line when crash is absent but breach viability suggests it matters.
static func player_crash_absence_hint_if_missing(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty():
		return ""
	if str(c.get("side", "")) != "player":
		return ""
	if bool(manager.medical_phase):
		return ""
	# Crash intrusion is native front rank only (`_crash_action_eligible`); skip hints for intruders / rear ranks.
	if str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
		return ""
	if int(c.get("rank", 0)) != 0:
		return ""
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return ""
	var crash_count: int = 0
	for a in actions:
		if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
			crash_count += 1
	if crash_count > 0:
		return ""
	if CombatConstants.crash_breach_viability(c) < CombatConstants.CRASH_BREACH_VIABILITY_MIN:
		return ""
	var raw: String = crash_absent_primary_reason(manager, c)
	if raw.is_empty() or raw == "crash_eligible_but_missing_bug":
		return ""
	return format_crash_absent_reason_for_ui(raw)


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
