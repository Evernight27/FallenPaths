class_name CombatAIActionPicker
extends RefCounted

## Picks one action from available actions using weighted randomness. **Combat move choice is fully AI-driven:**
## weights combine stamina + `CombatTargetScoring` (doctrine, file bias, commitment, distributed pressure, **engagement mode**, our formation posture+cohesion, **opponent** formation, **`breached_files`** column press on listed hostiles, stance). No human pick path.
## Medical: deterministic urgency + per-part threat; bandage/pack/tourniquet favor high `get_medical_effectiveness`, pressure favors lower skill.
## Pending retry: strongly prefer retrying the failed part when target is still in peril.
## For attacks: adds target_part from path when pathway allows (unguarded bonus). Counter-tempo listing (**`ACTION_KEY_COUNTER_TEMPO`**) × **`CounterTempo.counter_tempo_listing_weight_mult`** (**`AI_COUNTER_TEMPO_*`**). **`is_feint`** moves get **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** × defender-readiness lerp (**`PassiveParryContext.get_passive_parry_readiness`** × **`CombatConstants.passive_parry_readiness_incoming_contact_mult`** for this move’s **`contact_type`** × **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** on the defender × **`CombatConstants.ai_feint_listing_defender_readiness_spacing_mult`** from defender **`distance_to[attacker]`** — same curve as **`DefenseChoiceResolver`** reported readiness, not attacker stamina) × attacker **`CombatConstants.get_stance_modifier(..., "ai_feint_listing")`** × defender footwork state mult (**`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** when off-balance; elif **`STATE_RECOVERING`**, **`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**; elif settled **`STATE_WAITING`**, **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**) × optional low-stamina feint dampening × formation doctrine **`probing`** / **`pinch_center`** / **`hold_lane`** (**`AI_FEINT_LISTING_DOCTRINE_*_MULT`**) × short-horizon boost after that defender **`parry_deflect`** (**`COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`**, **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_*`**) (Tier 4.2).
## Feint **listing** does not apply **`DefenseChoiceResolver._feint_readiness_reveal_mult`** (telegraph-delay readiness is defender-side in **`choose_defense`** vs the attacker’s live **`pa`** / **`STATE_WIND_UP`**).
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), _is_medical_move, _is_in_immediate_peril.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

static func pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if actions.is_empty():
		return {}
	var stacked: Dictionary = _MentalStack.try_pick(actions, combatant_id, manager)
	if not stacked.is_empty():
		var choice_stacked: Dictionary = stacked.duplicate()
		_add_attack_target_part(choice_stacked, manager, combatant_id)
		return choice_stacked
	return pick_weighted(actions, combatant_id, manager)


## Weighted random choice without **`MentalStackDecider`** (used by stack layers to avoid recursion).
static func pick_weighted(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if actions.is_empty():
		return {}
	_TargetScoring.prune_expired_commitments(manager)
	var total: float = 0.0
	for a in actions:
		total += _get_action_weight(a, combatant_id, manager, true)
	var r: float = randf() * total
	for a in actions:
		var w: float = _get_action_weight(a, combatant_id, manager, true)
		if r < w:
			var choice: Dictionary = a.duplicate()
			_add_attack_target_part(choice, manager, combatant_id)
			return choice
		r -= w
	var fallback: Dictionary = actions[0].duplicate()
	_add_attack_target_part(fallback, manager, combatant_id)
	return fallback

## Build opts dict from AI choice (target_part, feint_part) for resolve_action. Shared by all pick-and-resolve callers.
static func opts_from_choice(choice: Dictionary) -> Dictionary:
	var opts: Dictionary = {}
	if choice.get("target_part", "") != "":
		opts["target_part"] = choice.target_part
	if choice.get("feint_part", "") != "":
		opts["feint_part"] = choice.feint_part
	if choice.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
		opts[CombatConstants.ACTION_KEY_COUNTER_TEMPO] = true
	return opts

## Shared swap-rank fitness gate: `disengage` = front yields to fitter rear; relief = rear replaces exhausted front.
static func _swap_rank_fitness_swap_allowed(
	c: Dictionary, partner: Dictionary, manager: Node, disengage: bool
) -> bool:
	if partner == null or partner.is_empty():
		return false
	if _EntityAccess.is_incapacitated(partner):
		return false
	if disengage and not _EntityAccess.retreat_formation_body_damage_warranted(c, manager):
		return false
	var our_fitness: float = _get_positioning_fitness(c)
	var partner_fitness: float = _get_positioning_fitness(partner)
	var gap: float = (partner_fitness - our_fitness) if disengage else (our_fitness - partner_fitness)
	if gap <= 0.0:
		return false
	if disengage:
		if _EntityAccess.get_attacking_arm(c).is_empty():
			return not _EntityAccess.get_attacking_arm(partner).is_empty()
	else:
		if _EntityAccess.get_attacking_arm(partner).is_empty():
			return not _EntityAccess.get_attacking_arm(c).is_empty()
	var stressed_fitness: float = our_fitness if disengage else partner_fitness
	if (
		stressed_fitness <= CombatConstants.SWAP_RANK_AI_CRITICAL_FITNESS
		and gap >= CombatConstants.SWAP_RANK_AI_URGENT_MIN_GAP
	):
		return true
	return gap >= CombatConstants.SWAP_RANK_AI_MIN_FITNESS_GAP


## True when front→back disengage swap is tactically justified (matches high-weight rules in _get_action_weight).
## Plug-forward (incapacitated partner) is handled separately in AvailableActionsBuilder.
## `manager`: required for body-damage / peril gate (fatigue alone must not justify retreat).
static func is_disengage_swap_tactically_allowed(
	c: Dictionary, partner: Dictionary, manager: Node
) -> bool:
	return _swap_rank_fitness_swap_allowed(c, partner, manager, true)


## True when deeper rank (higher rank #) should swap forward with the rank ahead (relief / rotation).
static func is_relief_swap_tactically_allowed(c: Dictionary, partner: Dictionary) -> bool:
	return _swap_rank_fitness_swap_allowed(c, partner, null, false)

## Returns weight for action. Medical: urgency + direct pressure bleed + pending retry.
## Combat: attack/attempt_close = use stamina (exhausted less likely to engage); `attempt_close` weight 0 unless LONG + not close-blocked; swap_rank = fitness only (no stamina).
## `skip_targeting_prune`: pass **true** when `pick()` already called `prune_expired_commitments` (avoids O(actions) redundant prunes).
static func _get_action_weight(
	a: Dictionary, combatant_id: int, manager: Node, skip_targeting_prune: bool = false
) -> float:
	var mid: String = a.get("move_id", "")
	if manager._is_medical_move(mid):
		return _get_medical_weight(a, combatant_id, manager)
	# Combat actions: attack, attempt_close, swap_rank
	var c = manager._get_by_id(combatant_id)
	if c == null:
		return 1.0
	if mid == CombatConstants.MOVE_ID_WAIT:
		return 1.0
	if CombatConstants.is_focus_line_move(mid):
		return _focus_line_action_weight(mid, combatant_id, manager, c)
	if mid == CombatConstants.MOVE_ID_CRASH:
		if CombatConstants.is_incursion_breach_harness_active():
			return 1.0e9
		if not _EngagementMode.crash_intrusion_attacker_allowed(manager, c):
			return 0.0
		var via: float = CombatConstants.crash_breach_viability(c)
		var stamina_ratio_c: float = clampf(_EntityAccess.stamina_float(c) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
		var sr_c: float = 0.78 if stamina_ratio_c < 0.32 else 1.0
		var shaped: float = pow(via, CombatConstants.CRASH_AI_VIABILITY_EXPONENT)
		var fid_crash: String = _ZoneOfControl.formation_id_for_zone_geometry(manager, c)
		var fd_crash: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(manager, c, fid_crash)
		var pst_m: float = _crash_weight_posture_mult(manager, c, fd_crash)
		var coh_m: float = crash_line_cohesion_weight_mult(manager, c, fd_crash)
		return CombatConstants.CRASH_AI_WEIGHT_CAP * shaped * sr_c * pst_m * coh_m
	if mid == CombatConstants.MOVE_ID_FALL_BACK and a.get("target_id", -1) == combatant_id:
		if (
			_EntityAccess.state_str(c) == CombatConstants.STATE_COWERING
			or _EntityAccess.is_cowering(c)
		):
			return CombatConstants.COWERING_SOLO_FALL_BACK_AI_WEIGHT
		# Offered only when desperate / peril (AvailableActionsBuilder); keep below routine wait.
		return 0.45
	if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
		return 0.55
	if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		var tgt_id_close: int = int(a.get("target_id", -1))
		if tgt_id_close < 0:
			return 0.0
		var dist_close: String = str(
			_EntityAccess.nested_dictionary_read(c, "distance_to").get(
				tgt_id_close, CombatConstants.DISTANCE_LONG
			)
		)
		if not _ActionsBuilder._attempt_close_listed_for_pair(manager, c, tgt_id_close, dist_close):
			return 0.0
	if mid in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK]:
		var partner_id: int = a.get("target_id", -1)
		var partner = manager._get_by_id(partner_id) if partner_id >= 0 else null
		var partner_incapacitated: bool = partner != null and _EntityAccess.is_incapacitated(partner)
		if partner_incapacitated:
			# Back rank plugging forward — partner (front) is incapacitated; strongly prefer.
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
		if partner != null and _EntityAccess.rank_int(c) > _EntityAccess.rank_int(partner):
			# Deeper rank swapping up (relief) — only swap_rank is offered for this path in builder.
			if mid != CombatConstants.MOVE_ID_SWAP_RANK:
				return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
			if is_relief_swap_tactically_allowed(c, partner):
				return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
			return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
		if partner != null and is_disengage_swap_tactically_allowed(c, partner, manager):
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
		return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
	# Attack or attempt_close: engaging the enemy — use stamina + hybrid targeting (doctrine, file, pressure).
	var stamina_ratio: float = clampf(_EntityAccess.stamina_float(c) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
	var base_stamina: float = 0.85 if stamina_ratio < 0.2 else 1.0
	var polearm_lane: float = _depth_polearm_action_weight_mult(manager, c, mid)
	var feint_list_m: float = 1.0
	if mid != CombatConstants.MOVE_ID_ATTEMPT_CLOSE and _WeaponConstants.is_feint_move(mid):
		var pr_def: float = 0.0
		var tid_feint: int = int(a.get("target_id", -1))
		if tid_feint >= 0:
			var tgt_feint = manager._get_by_id(tid_feint)
			if tgt_feint != null:
				pr_def = clampf(_PassiveParry.get_passive_parry_readiness(tgt_feint), 0.0, 1.0)
				var ct_mv: String = str(_WeaponConstants.get_move(mid).get("contact_type", _WeaponConstants.ATTACK_TYPE_CUT))
				pr_def = clampf(
					pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_mv), 0.0, 1.0
				)
				pr_def = clampf(
					pr_def
					* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
						_EntityAccess.stamina_float(tgt_feint) / CombatConstants.STAMINA_MAX
					),
					0.0,
					1.0
				)
				pr_def = clampf(
					pr_def
					* CombatConstants.ai_feint_listing_defender_readiness_spacing_mult(
						tgt_feint, _EntityAccess.id_int(c)
					),
					0.0,
					1.0
				)
		var read_m: float = lerpf(
			1.0,
			CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT,
			pr_def
		)
		var stance_feint_m: float = CombatConstants.get_stance_modifier(
			_EntityAccess.stance_str(c), "ai_feint_listing"
		)
		feint_list_m = (
			CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * stance_feint_m
		)
		if tid_feint >= 0:
			var tgt_ob: Variant = manager._get_by_id(tid_feint)
			if tgt_ob is Dictionary:
				if _PassiveParry.is_off_balance(tgt_ob):
					feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
				elif _EntityAccess.state_str(tgt_ob) == CombatConstants.STATE_RECOVERING:
					feint_list_m *= CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
						str(tgt_ob.get("recovery_cause", "skip"))
					)
				elif _EntityAccess.state_str(tgt_ob) == CombatConstants.STATE_WAITING:
					feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
		if stamina_ratio < CombatConstants.AI_FEINT_LISTING_STAMINA_GATE:
			var st_feint_stamina: float = lerpf(
				CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
				1.0,
				stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
			)
			feint_list_m *= st_feint_stamina
		var fid_atk: String = _EntityAccess.formation_id_str(c)
		var doc_feint: String = _CombatDoctrine.doctrine_for_fid(manager, fid_atk)
		if doc_feint == CombatConstants.DOCTRINE_PROBING:
			feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
		elif doc_feint == CombatConstants.DOCTRINE_PINCH_CENTER:
			feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
		elif doc_feint == CombatConstants.DOCTRINE_HOLD_LANE:
			feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
		feint_list_m *= _feint_listing_opp_parry_deflect_pressure_mult(manager, c, tid_feint)
		if tid_feint >= 0:
			var tgt_yomi: Variant = manager._get_by_id(tid_feint)
			if tgt_yomi is Dictionary:
				var dom_line: String = _Attention.dominant_attack_line_toward_defender(
					tgt_yomi as Dictionary, combatant_id
				)
				var fp_est: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, "head")
				feint_list_m *= _Attention.yomi_feint_listing_mult(
					tgt_yomi as Dictionary, combatant_id, fp_est
				)
				feint_list_m *= _Attention.yomi_parry_deflect_feint_listing_mult(
					tgt_yomi as Dictionary, combatant_id
				)
	var counter_tempo_m: float = _CounterTempo.counter_tempo_listing_weight_mult(
		manager, combatant_id, a, mid
	)
	return (
		base_stamina
		* _TargetScoring.ai_targeting_weight_mult(manager, combatant_id, a, skip_targeting_prune)
		* polearm_lane
		* feint_list_m
		* counter_tempo_m
	)

## Tier 4.3.7: focus-line retarget — party lead favors matching incoming telegraph; others rarely shift.
static func _focus_line_action_weight(
	move_id: String, combatant_id: int, manager: Node, c: Dictionary
) -> float:
	if not _Attention.enabled():
		return 0.0
	var line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
	if line.is_empty():
		return 0.0
	var part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(line, "")
	if part.is_empty() or part == _Attention.get_focus_part(c):
		return CombatConstants.AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT
	if bool(c.get("is_party_leader", false)) and _Attention.is_being_wind_up_targeted(manager, combatant_id):
		var tele: String = str(
			c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")
		).strip_edges()
		var tele_line: String = CombatConstants.PART_TO_LINE.get(tele, "")
		if tele_line == line:
			return CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
	return CombatConstants.AI_FOCUS_LINE_BASE_WEIGHT


## Tier 1.9 (P10): when depth spear lane is open **and** at least one **valid line** rank-0 hostile exists, prefer thrusts; de-emphasize closing (thrust works from MID).
## Formation **`doctrine`** (`pinch_center` / `hold_lane` / `probing`) nudges stab vs cut weights (Tier 1.9 optional coupling).
static func _depth_polearm_action_weight_mult(manager: Node, c: Dictionary, move_id: String) -> float:
	if manager == null or c.is_empty() or not _ActionsBuilder.depth_polearm_lane_open(manager, c):
		return 1.0
	if not _ActionsBuilder.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(manager, c, manager.combatants):
		return 1.0
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return CombatConstants.DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT
	var ct: String = _WeaponConstants.contact_type_for_move_id(move_id)
	var fid: String = _EntityAccess.formation_id_str(c)
	if ct == _WeaponConstants.ATTACK_TYPE_STAB:
		var w: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT
		var doc: String = _CombatDoctrine.doctrine_for_fid(manager, fid)
		if doc == CombatConstants.DOCTRINE_PINCH_CENTER:
			w *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB
			)
		elif doc == CombatConstants.DOCTRINE_HOLD_LANE:
			w *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_HOLD_STAB
			)
		elif doc == CombatConstants.DOCTRINE_PROBING:
			w *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PROBING_STAB
			)
		return w
	if ct == _WeaponConstants.ATTACK_TYPE_CUT or ct == _WeaponConstants.ATTACK_TYPE_BLUNT:
		var w2: float = CombatConstants.DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT
		var doc2: String = _CombatDoctrine.doctrine_for_fid(manager, fid)
		if doc2 == CombatConstants.DOCTRINE_HOLD_LANE:
			w2 *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_HOLD_NON_STAB
			)
		elif doc2 == CombatConstants.DOCTRINE_PINCH_CENTER:
			w2 *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_NON_STAB
			)
		elif doc2 == CombatConstants.DOCTRINE_PROBING:
			w2 *= manager.get_depth_polearm_ai_doctrine_mult(
				fid, CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PROBING_NON_STAB
			)
		return w2
	return 1.0

## Fitness for formation positioning: performance (attack capability) × health (blood). Higher = more able to fight.
## Used for swap rank: lowest fitness should be in back. Does not use stamina/action-ready.
static func _get_positioning_fitness(c: Dictionary) -> float:
	var perf: float = _EntityAccess.get_performance_modifier(c)
	var n: Node = _EntityAccess.scene_node(c)
	var health: float = clampf(_EntityAccess.get_blood_volume_from_node(n) / 100.0, 0.0, 1.0) if n != null else 1.0
	return perf * health


## Tier 1.6 (P7): `line_cohesion` 0..1 → lerp(CRASH_AI_COHESION_LOW_MULT, HIGH). Exposed for `CombatRegressionHarness`.
## When **`fd_cached`** is a Dictionary, use it (e.g. same **`formation_dict_for_zone_geometry`** as **`_crash_weight_posture_mult`**); else resolve from **`c`**.
static func crash_line_cohesion_weight_mult(manager: Node, c: Dictionary, fd_cached: Variant = null) -> float:
	if manager == null or c.is_empty():
		return 1.0
	var fd: Dictionary = (
		(fd_cached as Dictionary)
		if fd_cached != null and fd_cached is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, c)
	)
	if fd.is_empty():
		return 1.0
	var coh: float = clampf(float(fd.get("line_cohesion", 1.0)), 0.0, 1.0)
	return lerpf(
		CombatConstants.CRASH_AI_COHESION_LOW_MULT,
		CombatConstants.CRASH_AI_COHESION_HIGH_MULT,
		coh
	)


## Tier 4.2: after **`AttackResultApplier`** **`parry_deflect`**, record defender tick on **`attacker`** for short-horizon feint listing pressure.
static func record_opp_parry_deflect_for_feint_listing(manager: Node, attacker: Dictionary, defender_id: int) -> void:
	if manager == null or attacker.is_empty() or defender_id < 0:
		return
	var tick_now: int = manager.get_combat_tick_index()
	var mem: Dictionary = {}
	var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
	if raw_m != null and raw_m is Dictionary:
		mem = (raw_m as Dictionary).duplicate()
	mem[str(defender_id)] = tick_now
	attacker[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = mem


## Tier 4.2: clear short-horizon parry-deflect memory for this defender (e.g. after a **`hit`** landed).
static func clear_feint_listing_opp_parry_deflect_for_target(attacker: Dictionary, defender_id: int) -> void:
	if attacker.is_empty() or defender_id < 0:
		return
	var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
	if raw_m == null or not (raw_m is Dictionary):
		return
	var mem: Dictionary = (raw_m as Dictionary).duplicate()
	mem.erase(str(defender_id))
	if mem.is_empty():
		attacker.erase(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK)
	else:
		attacker[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = mem


static func _feint_listing_opp_parry_deflect_pressure_mult(
	manager: Node, attacker: Dictionary, defender_id: int
) -> float:
	if manager == null or attacker.is_empty() or defender_id < 0:
		return 1.0
	var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
	if raw_m == null or not (raw_m is Dictionary):
		return 1.0
	var st: Variant = (raw_m as Dictionary).get(str(defender_id), null)
	if st == null:
		return 1.0
	var stored_tick: int = int(st)
	var tick_now: int = manager.get_combat_tick_index()
	var age: int = tick_now - stored_tick
	if age < 0:
		return 1.0
	var win: int = maxi(1, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS)
	var t: float = 1.0 - clampf(float(age) / float(win), 0.0, 1.0)
	return lerpf(
		1.0,
		CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT,
		t
	)


static func _crash_weight_posture_mult(manager: Node, c: Dictionary, fd_cached: Variant = null) -> float:
	if manager == null:
		return 1.0
	if c.is_empty():
		return 1.0
	var fd: Dictionary = (
		(fd_cached as Dictionary)
		if fd_cached != null and fd_cached is Dictionary
		else _ZoneOfControl.formation_dict_for_zone_geometry(manager, c)
	)
	if fd.is_empty():
		return 1.0
	var pst: String = str(fd.get("engagement_posture", ""))
	if pst == CombatConstants.ENGAGEMENT_POSTURE_OPEN:
		return CombatConstants.CRASH_AI_POSTURE_OPEN_EXTRA_MULT
	if pst == CombatConstants.ENGAGEMENT_POSTURE_LINE:
		return CombatConstants.CRASH_AI_POSTURE_LINE_EXTRA_MULT
	if pst == CombatConstants.ENGAGEMENT_POSTURE_DUEL:
		return CombatConstants.CRASH_AI_POSTURE_DUEL_EXTRA_MULT
	return 1.0


static func _get_medical_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
	var mid: String = a.get("move_id", "")
	var tgt = manager._get_by_id(a.get("target_id", -1))
	var performer = manager._get_by_id(combatant_id)
	var perf_entity: Node = _EntityAccess.get_entity_from_manager(manager, performer) if performer != null else null
	var eff_raw: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
	var eff: float = clampf(eff_raw, _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MIN, _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MAX)
	var urgency: float = _MedicalPhase.get_medical_urgency_deterministic(manager, tgt) if tgt != null else 0.0
	var part: String = str(a.get("target_part", ""))
	var part_threat: float = 0.0
	if tgt != null and not part.is_empty():
		part_threat = _MedicalPhase.get_part_intervention_threat(manager, tgt, part)
	var w: float = 1.0 + urgency * (_MedicalPhase.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
	w += part_threat * _MedicalPhase.MEDICAL_AI_PART_THREAT_MULT
	var advanced: bool = mid in ["bandage_self", "pack_wound", "apply_tourniquet"]
	if advanced:
		w *= pow(eff, _MedicalPhase.MEDICAL_AI_ADVANCED_SKILL_EXP)
	elif mid == "apply_direct_pressure":
		var span: float = maxf(_MedicalPhase.MEDICAL_AI_EFF_CLAMP_MAX - _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MIN, 0.01)
		var t: float = clampf((eff - _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MIN) / span, 0.0, 1.0)
		w *= lerpf(_MedicalPhase.MEDICAL_AI_PRESSURE_LOW_SKILL_MULT, _MedicalPhase.MEDICAL_AI_PRESSURE_HIGH_SKILL_MULT, t)
	# Pending retry: only one who can help; strongly prefer retrying the failed part.
	var pending: Dictionary = {}
	if performer != null:
		var pnd_raw: Variant = performer.get("pending_retry", null)
		if typeof(pnd_raw) == TYPE_DICTIONARY:
			pending = pnd_raw as Dictionary
	if not pending.is_empty() and pending.get("target_id", -1) == a.get("target_id", -1) and pending.get("part", "") == a.get("target_part", ""):
		if tgt != null and manager._is_in_immediate_peril(tgt):
			w *= 20.0
	return maxf(w, 0.001)

static func _add_attack_target_part(choice: Dictionary, manager: Node, attacker_id: int) -> void:
	if manager._is_medical_move(choice.get("move_id", "")):
		return
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return  # Close attempt targets a combatant, not a body part
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_CRASH:
		return
	if choice.get("move_id", "") in [
		CombatConstants.MOVE_ID_SWAP_RANK,
		CombatConstants.MOVE_ID_DRAG_BACK,
		CombatConstants.MOVE_ID_FALL_BACK,
		CombatConstants.MOVE_ID_ROTATE_FILE,
	]:
		return
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_WAIT:
		return
	var tgt_id: int = choice.get("target_id", -1)
	var tgt = manager._get_by_id(tgt_id)
	if tgt == null:
		return
	var targetable: Array = _EntityAccess.get_targetable_parts(tgt)
	if targetable.is_empty():
		return
	var atk_pick = manager._get_by_id(attacker_id)
	if atk_pick != null:
		targetable = _ActionsBuilder.depth_polearm_targetable_parts_filter(manager, atk_pick, targetable)
	if targetable.is_empty():
		return
	var move_def: Dictionary = WeaponConstants.get_move(choice.get("move_id", ""))
	var atk_line: String = move_def.get("attack_line", "high")
	var guard_line: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
	var path: Array = CombatConstants.get_attack_path(atk_line, guard_line)
	var atk_angle_list: float = CombatConstants.line_to_angle(atk_line)
	if atk_pick != null:
		atk_angle_list = _Footwork.apply_offset_to_angle_deg(atk_angle_list, atk_pick)
	var guard_angle_list: float = (
		_Footwork.guard_angle_deg(tgt, {})
		if _Footwork.enabled()
		else CombatConstants.get_guard_angle_deg(tgt)
	)
	var align_ctx: Dictionary = {
		"attack_angle_deg": atk_angle_list,
		"guard_angle_deg": guard_angle_list,
	}
	var alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
	var intercept_max: int = int(lerpf(
		float(CombatConstants.PATH_INTERCEPT_EARLY_MAX),
		float(path.size() - 1),
		1.0 - alignment
	))
	intercept_max = clampi(intercept_max, 0, path.size() - 1)
	var path_segment: Array = []
	for i in range(intercept_max + 1):
		if i < path.size() and targetable.has(path[i]):
			path_segment.append(path[i])
	if not path_segment.is_empty():
		var preferred: Array = move_def.get("preferred_parts", [])
		var mult: float = CombatConstants.PREFERRED_PART_BONUS_MULT if not preferred.is_empty() else 1.0
		choice["target_part"] = BodyPartConstants.get_weighted_random_part(path_segment, preferred, mult)
		# Feint D: for feint moves, pick feint_part != target_part to bait defender
		if move_def.get("is_feint", false):
			var others: Array = []
			for p in targetable:
				if p != choice["target_part"]:
					others.append(p)
			if not others.is_empty():
				choice["feint_part"] = others[randi() % others.size()]
