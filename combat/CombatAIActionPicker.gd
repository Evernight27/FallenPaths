class_name CombatAIActionPicker
extends RefCounted

## Picks one action from available actions using weighted randomness. **Combat move choice is fully AI-driven:**
## WF turn pick (L2): **`CombatWeaponForm.action_weight_mult`**, **`wait_action_weight_mult`**, focus **`preferred_guards`**; listing path preview uses **`CombatFootwork.attack_angle_deg_for_listing_preview`** + **`guard_angle_deg`** when PA on — **`#wf-tier-44-pa`** (geometry) · **`#wf-pick-vs-strike`**; **`evaluate_automatic_form`** after mental-stack miss — **`assign_form`** only.
## weights combine stamina + `CombatTargetScoring` (doctrine, file bias, commitment, distributed pressure, **engagement mode**, our formation posture+cohesion, **opponent** formation, stance). No human pick path.
## Medical: deterministic urgency + per-part threat; bandage/pack/tourniquet favor high `get_medical_effectiveness`, pressure favors lower skill.
## Pending retry: strongly prefer retrying the failed part when target is still in peril.
## For attacks: adds target_part from path when pathway allows (unguarded bonus). Counter-tempo listing (**`ACTION_KEY_COUNTER_TEMPO`**) × **`CounterTempo.counter_tempo_listing_weight_mult`** (**`AI_COUNTER_TEMPO_*`**). **`is_feint`** moves get **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** × defender-readiness lerp (**`PassiveParryContext.get_passive_parry_readiness`** × **`CombatConstants.passive_parry_readiness_incoming_contact_mult`** for this move’s **`contact_type`** × **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** on the defender × **`CombatConstants.ai_feint_listing_defender_readiness_spacing_mult`** from defender **`distance_to[attacker]`** — same curve as **`DefenseChoiceResolver`** reported readiness, not attacker stamina) × attacker **`CombatWeaponForm.mod(form_str, "ai_feint_listing")`** × defender footwork state mult (**`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** when off-balance; elif **`STATE_RECOVERING`**, **`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**; elif settled **`STATE_WAITING`**, **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**) × optional low-stamina feint dampening × formation doctrine **`probing`** / **`pinch_center`** / **`hold_lane`** (**`AI_FEINT_LISTING_DOCTRINE_*_MULT`**) × short-horizon boost after that defender **`parry_deflect`** (**`COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`**, **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_*`**) (Tier 4.2).
## Feint **listing** applies **`DefenseChoiceResolver._feint_readiness_reveal_mult`** when the attacker has live **`pending_attack`** on the listed target (same move / wind-up progress as **`choose_defense`**).
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), _is_medical_move.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _EngagementDiag := preload("res://combat/CombatEngagementDiagnostics.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _MoodBias := preload("res://combat/CombatCampaignMoodBias.gd")

static func pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if actions.is_empty():
		return {}
	var c_pick: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	actions = _MobilityRetreat.filter_actions_for_retreat_only(actions, c_pick)
	if actions.is_empty():
		return {}
	var stacked: Dictionary = _MentalStack.try_pick(actions, combatant_id, manager)
	if not stacked.is_empty():
		var choice_stacked: Dictionary = stacked.duplicate()
		_add_attack_target_part(choice_stacked, manager, combatant_id)
		return choice_stacked
	_WeaponForm.evaluate_automatic_form(manager, c_pick)
	return pick_weighted(actions, combatant_id, manager)


## Weighted random choice without **`MentalStackDecider`** (used by stack layers to avoid recursion).
## **`weight_menu_context`**: full turn menu for `_get_action_weight` when picking from a narrowed pool (MS-L5 plug).
static func pick_weighted(
	actions: Array,
	combatant_id: int,
	manager: Node,
	weight_menu_context: Array = []
) -> Dictionary:
	if actions.is_empty():
		return {}
	var c_pick: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	actions = _MobilityRetreat.filter_actions_for_retreat_only(actions, c_pick)
	if actions.is_empty():
		return {}
	_TargetScoring.prune_expired_commitments(manager)
	var ctx_actor: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c_pick)
	var zone_by_id: Dictionary = _ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
	var weight_ctx: Array = (
		weight_menu_context if not weight_menu_context.is_empty() else actions
	)
	var total: float = 0.0
	for a in actions:
		total += _get_action_weight(
			a, combatant_id, manager, true, ctx_actor, zone_by_id, weight_ctx
		)
	var r: float = randf() * total
	for a in actions:
		var w: float = _get_action_weight(
			a, combatant_id, manager, true, ctx_actor, zone_by_id, weight_ctx
		)
		if r < w:
			var choice: Dictionary = a.duplicate()
			_add_attack_target_part(choice, manager, combatant_id)
			return choice
		r -= w
	var fallback: Dictionary = actions[0].duplicate()
	_add_attack_target_part(fallback, manager, combatant_id)
	return fallback


## Deterministic medical pick for campaign batch exit (highest triage weight, no RNG).
static func pick_highest_medical(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if actions.is_empty():
		return {}
	var best: Dictionary = {}
	var best_w: float = -1.0
	for a in actions:
		if a is not Dictionary:
			continue
		var w: float = _get_medical_weight(a as Dictionary, combatant_id, manager)
		if w > best_w:
			best_w = w
			best = (a as Dictionary).duplicate()
	return best


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


## Apply a picked move via **`CombatManager.resolve_action`** (shared by player/enemy turn paths).
static func resolve_choice(
	manager: Node, combatant_id: int, choice: Dictionary, self_target: bool = false
) -> bool:
	var opts: Dictionary = opts_from_choice(choice)
	var target_id: int = combatant_id if self_target else int(choice.get("target_id", combatant_id))
	var move_id: String = str(choice.get("move_id", ""))
	var committed: bool = manager.resolve_action(combatant_id, target_id, move_id, opts)
	if not committed:
		_verify_turn_committed_after_resolve(manager, combatant_id, move_id)
	return committed


static func _verify_turn_committed_after_resolve(
	manager: Node, combatant_id: int, move_id: String
) -> void:
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return
	if _EntityAccess.gauge_float(c) < 99.9:
		return
	CombatDebug.resolve_action_rejected(
		manager,
		combatant_id,
		move_id,
		"no state change after resolve (gauge still full)",
		true
	)


## Pick from **`actions`** then resolve; optional **`CombatDebug.flow_log_turn`** when **`log_side`** set.
static func resolve_picked_turn(
	manager: Node,
	combatant_id: int,
	actions: Array,
	log_side: String = "",
	self_target: bool = false
) -> void:
	if actions.is_empty():
		return
	var choice: Dictionary = pick(actions, combatant_id, manager)
	_EngagementDiag.maybe_log_turn_pick(manager, combatant_id, actions, choice)
	var committed: bool = resolve_choice(manager, combatant_id, choice, self_target)
	if not committed and manager != null and bool(manager.medical_phase):
		_EntityAccess.manager_skip_turn(
			manager, combatant_id, "pass", "medical coordination blocked stale pick"
		)
	elif not committed:
		_verify_turn_committed_after_resolve(
			manager, combatant_id, str(choice.get("move_id", ""))
		)
	if not log_side.is_empty() and committed:
		CombatDebug.flow_log_turn(log_side, combatant_id, actions, choice, manager)


## **`skip_turn`** when no actions; else **`resolve_picked_turn`** (player/enemy **`ACTION_READY`** paths).
static func resolve_picked_turn_or_skip(
	manager: Node,
	combatant_id: int,
	actions: Array,
	log_side: String = "",
	self_target: bool = false
) -> void:
	if manager != null and bool(manager.medical_phase):
		actions = manager.get_available_actions(combatant_id)
		actions = _MedicalCoord.filter_actions_for_pick(manager, combatant_id, actions)
	if actions.is_empty():
		_EntityAccess.manager_skip_turn(manager, combatant_id, CombatConstants.SKIP_TURN_LOG_PASS, "no available actions")
		return
	resolve_picked_turn(manager, combatant_id, actions, log_side, self_target)

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
## Plug-forward (incapacitated partner) is handled separately in `CombatFormationMoveListing`.
## `manager`: required for body-damage / peril gate (fatigue alone must not justify retreat).
static func is_disengage_swap_tactically_allowed(
	c: Dictionary, partner: Dictionary, manager: Node
) -> bool:
	return _swap_rank_fitness_swap_allowed(c, partner, manager, true)


## True when deeper rank (higher rank #) should swap forward with the rank ahead (relief / rotation).
static func is_relief_swap_tactically_allowed(c: Dictionary, partner: Dictionary) -> bool:
	return _swap_rank_fitness_swap_allowed(c, partner, null, false)

## Returns weight for action. Medical: urgency + direct pressure bleed + pending retry.
## Combat: attack/attempt_close = use stamina (exhausted less likely to engage); `attempt_close` weight 0 unless listed pair (`attempt_close_listed_for_pair`); swap_rank = fitness only (no stamina).
## `skip_targeting_prune`: pass **true** when `pick()` already called `prune_expired_commitments` (avoids O(actions) redundant prunes).
static func _get_action_weight(
	a: Dictionary,
	combatant_id: int,
	manager: Node,
	skip_targeting_prune: bool = false,
	actor_zone_geometry_line_context: Dictionary = {},
	zone_geometry_by_combatant_id: Dictionary = {},
	all_actions: Array = []
) -> float:
	var mid: String = a.get("move_id", "")
	if CombatConstants.is_medical_move(mid):
		return _get_medical_weight(a, combatant_id, manager)
	# Combat actions: attack, attempt_close, swap_rank
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return 1.0
	if (
		_MobilityRetreat.cannot_commit_melee(c)
		and not _MobilityRetreat.resolve_move_allowed_when_cannot_melee(
			mid, int(a.get("target_id", -1)), combatant_id
		)
	):
		return 0.0
	if mid == CombatConstants.MOVE_ID_WAIT:
		var wait_w: float = _WeaponForm.wait_action_weight_mult(_EntityAccess.form_str(c))
		var fid_wait: String = _EntityAccess.formation_id_str(c)
		if (
			not all_actions.is_empty()
			and _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
		):
			if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid_wait):
				wait_w *= CombatConstants.AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT
			elif (
				_CombatDoctrine.envelop_mop_up_active(manager, fid_wait)
				or _CombatDoctrine.mop_up_underdog_active(manager, c)
			):
				wait_w *= CombatConstants.AI_WAIT_MOP_UP_FINISH_MULT
		var mood_wait_mult: float = _MoodBias.wait_action_weight_mult(
			_MoodBias.mood_bias_for_combatant(manager, c)
		)
		wait_w *= mood_wait_mult
		return wait_w
	if CombatConstants.is_focus_line_move(mid):
		return _focus_line_action_weight(mid, combatant_id, manager, c, all_actions)
	if CombatConstants.is_leader_formation_command_move(mid):
		if int(a.get("target_id", -1)) != combatant_id:
			return 0.0
		if not _EntityAccess.is_formation_command_issuer(c):
			return 0.0
		return _leader_formation_command_pick_weight(manager, c, mid)
	if mid == CombatConstants.MOVE_ID_FLEE and int(a.get("target_id", -1)) == combatant_id:
		if _MobilityRetreat.formation_retreat_only_for(c):
			return CombatConstants.COWERING_FLEE_AI_WEIGHT
		const _FormationRout := preload("res://combat/CombatFormationRout.gd")
		var flee_w: float = (
			CombatConstants.AI_FLEE_ROUTINE_WEIGHT * _FormationRout.flee_ai_pick_mult(manager, c)
		)
		if (
			_Exhaustion.exhaustion_tunnel_active(c)
			or _EntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
		):
			flee_w = maxf(flee_w, CombatConstants.AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT)
		var mood_flee_mult: float = _MoodBias.flee_action_weight_mult(
			_MoodBias.mood_bias_for_combatant(manager, c)
		)
		flee_w *= mood_flee_mult
		return flee_w
	if mid == CombatConstants.MOVE_ID_FALL_BACK and a.get("target_id", -1) == combatant_id:
		if _MobilityRetreat.formation_retreat_only_for(c):
			return CombatConstants.COWERING_SOLO_FALL_BACK_AI_WEIGHT
		# Offered only when desperate / peril (AvailableActionsBuilder); keep below routine wait.
		var mood_disengage_mult: float = _MoodBias.disengage_action_weight_mult(
			_MoodBias.mood_bias_for_combatant(manager, c)
		)
		return 0.45 * mood_disengage_mult / _opponent_controlling_disengage_listing_divisor(manager, c)
	if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
		var partner_id_rot: int = int(a.get("target_id", -1))
		if _FormationFlow.rotate_file_reverse_pair_blocked(manager, c, partner_id_rot):
			return 0.0
		if (
			not all_actions.is_empty()
			and _CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, all_actions)
		):
			return 0.0
		var rot_w: float = 0.55
		var lane_preview: Dictionary = _FormationMoveDuration.preview_lane_pressure_for_combatant(manager, c)
		if float(lane_preview.get("lane_foot", 0.0)) >= CombatConstants.LANE_MOD_BLOCKED - 0.05:
			rot_w *= CombatConstants.AI_FORMATION_MOVE_BLOCKED_LANE_MULT
		if _CombatDoctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c)):
			rot_w *= CombatConstants.ENVELOP_MOP_UP_ROTATE_AI_WEIGHT_MULT
		var engagement_listed: bool = (
			not all_actions.is_empty()
			and _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
		)
		var close_only_long: bool = _long_close_only_offense_menu(
			manager, c, combatant_id, all_actions
		)
		if engagement_listed:
			if close_only_long:
				rot_w *= CombatConstants.AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT
			else:
				rot_w *= CombatConstants.AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT
		var fid_rot: String = _EntityAccess.formation_id_str(c)
		if (
			not engagement_listed
			and _FormationFlow.formation_line_has_rank0_gap(manager, fid_rot)
			and not _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid_rot)
			and not (
				not all_actions.is_empty()
				and _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(
					manager, c, all_actions, combatant_id
				)
			)
		):
			rot_w = maxf(rot_w, CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT)
		return rot_w
	## III-4 **3e**: plug_forward AI weight during envelop mop-up.
	if mid == CombatConstants.MOVE_ID_PLUG_FORWARD:
		var partner_id_pf: int = int(a.get("target_id", -1))
		if partner_id_pf < 0:
			return 0.0
		var partner_pf: Dictionary = _EntityAccess.manager_get_combatant(manager, partner_id_pf)
		if partner_pf.is_empty():
			return 0.0
		if not _CombatDoctrine.envelop_mop_up_active(manager, _EntityAccess.side_str(c)):
			return 0.0
		var pf_w: float = CombatConstants.PLUG_FORWARD_AI_HIGH_WEIGHT
		var engagement_listed: bool = (
			not all_actions.is_empty()
			and _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
		)
		if not engagement_listed:
			pf_w *= CombatConstants.PLUG_FORWARD_AI_LOW_WEIGHT
		return pf_w
	if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		var tgt_id_close: int = int(a.get("target_id", -1))
		if tgt_id_close < 0:
			return 0.0
		var dist_close: String = _EntityAccess.distance_to_opponent_band(c, tgt_id_close)
		if _MeleeListing.close_attempt_pair_blocked(manager, c, tgt_id_close):
			if (
				not all_actions.is_empty()
				and _CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
			):
				return CombatConstants.AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT
			return 0.0
		if not _MeleeListing.attempt_close_listed_for_pair(manager, c, tgt_id_close, dist_close):
			if (
				not all_actions.is_empty()
				and _CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
			):
				return CombatConstants.AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT
			return 0.0
		if dist_close == CombatConstants.DISTANCE_CLOSE or dist_close == CombatConstants.DISTANCE_MID:
			if _CombatDoctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c)):
				return 0.0
			if (
				not all_actions.is_empty()
				and _ListedActions.action_list_has_hostile_melee_strike(all_actions, combatant_id)
				and (
					_CombatDoctrine.fight_finish_tail_active(
						manager, c, all_actions, combatant_id
					)
					or _FormationFlow.skirmish_line_sparse_after_casualties(
						manager, _EntityAccess.formation_id_str(c)
					)
				)
			):
				return 0.0
	if mid in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK]:
		if (
			mid == CombatConstants.MOVE_ID_SWAP_RANK
			and not all_actions.is_empty()
			and _EntityAccess.rank_int(c) == 0
			and _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
			and _CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
		):
			return 0.0
		var partner_id: int = a.get("target_id", -1)
		var partner: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, partner_id)
		var partner_incapacitated: bool = not partner.is_empty() and _EntityAccess.is_incapacitated(partner)
		if partner_incapacitated:
			# Back rank plugging forward — partner (front) is incapacitated; strongly prefer.
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
		if not partner.is_empty() and _EntityAccess.rank_int(c) > _EntityAccess.rank_int(partner):
			# Deeper rank swapping up (relief) — only swap_rank is offered for this path in builder.
			if mid != CombatConstants.MOVE_ID_SWAP_RANK:
				return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
			if is_relief_swap_tactically_allowed(c, partner):
				return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
			var fid_plug: String = _EntityAccess.formation_id_str(c)
			if (
				_FormationFlow.formation_line_has_rank0_gap(manager, fid_plug)
				and not _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid_plug)
				and (
					all_actions.is_empty()
					or not _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(
						manager, c, all_actions, combatant_id
					)
				)
			):
				return CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT
			return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
		if not partner.is_empty() and is_disengage_swap_tactically_allowed(c, partner, manager):
			var mood_dm: float = _MoodBias.disengage_action_weight_mult(
				_MoodBias.mood_bias_for_combatant(manager, c)
			)
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT * mood_dm / _opponent_controlling_disengage_listing_divisor(manager, c)
		var mood_dm2: float = _MoodBias.disengage_action_weight_mult(
			_MoodBias.mood_bias_for_combatant(manager, c)
		)
		return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT * mood_dm2 / _opponent_controlling_disengage_listing_divisor(manager, c)
	# Attack or attempt_close: engaging the enemy — use stamina + hybrid targeting (doctrine, file, pressure).
	var comps: Dictionary = _compute_attack_weight_components(
		a, combatant_id, manager, mid, c, skip_targeting_prune,
		actor_zone_geometry_line_context, zone_geometry_by_combatant_id, all_actions
	)
	var post_strike_mult: float = _post_strike_weight_mult(c, a, manager)
	return comps.weight * _salience_offense_weight_mult(c, manager) * post_strike_mult


## Extracted from **`_get_action_weight`** for auditability. Returns `{weight, ...}` dictionary.
## Computes all per-attack multipliers: stamina base, polearm lane, form weights, counter-read,
## feint listing (readiness, footwork state, doctrine, yomi), counter-tempo, attrition, exhaustion.
static func _compute_attack_weight_components(
	a: Dictionary,
	combatant_id: int,
	manager: Node,
	move_id: String,
	c: Dictionary,
	skip_targeting_prune: bool,
	actor_zone_geometry_line_context: Dictionary,
	zone_geometry_by_combatant_id: Dictionary,
	all_actions: Array
) -> Dictionary:
	var stamina_ratio: float = _EntityAccess.stamina_ratio(c)
	var base_stamina: float = CombatConstants.ai_offense_stamina_weight_mult(stamina_ratio)
	var polearm_lane: float = _depth_polearm_action_weight_mult(
		manager, c, move_id, actor_zone_geometry_line_context
	)
	var form_move_m: float = _WeaponForm.action_weight_mult(_EntityAccess.form_str(c), move_id)
	var form_counter_m: float = 1.0
	var tid_counter: int = int(a.get("target_id", -1))
	if tid_counter >= 0:
		var inferred: String = ""
		var cache_raw: Variant = c.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
		if cache_raw is Dictionary:
			inferred = str((cache_raw as Dictionary).get(str(tid_counter), "")).strip_edges()
		if inferred.is_empty():
			inferred = _WeaponForm.infer_opponent_form(manager, c, tid_counter)
		form_counter_m = _WeaponForm.form_counter_mult(_EntityAccess.form_str(c), inferred, move_id)
	var feint_list_m: float = 1.0
	if move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE and _WeaponConstants.is_feint_move(move_id):
		var _tid_feint: int = int(a.get("target_id", -1))
		var _resistance_active: bool = (
			CombatConstants.is_feature_ms_feint_resistance_enabled()
			and _tid_feint >= 0
			and not _EntityAccess.manager_get_combatant(manager, _tid_feint).is_empty()
			and _is_feint_resistance_active(_tid_feint, manager)
		)
		if _resistance_active:
			CombatDebug.flow_log(
				"feint_resistance active move=%s vs defender=%d readiness=%.2f state=%s"
				% [move_id, _tid_feint, _PassiveParry.get_passive_parry_readiness(_EntityAccess.manager_get_combatant(manager, _tid_feint)), _EntityAccess.state_str(_EntityAccess.manager_get_combatant(manager, _tid_feint))]
			)
		var pr_def: float = 0.0
		if _tid_feint >= 0:
			var tgt_feint: Dictionary = _EntityAccess.manager_get_combatant(manager, _tid_feint)
			if not tgt_feint.is_empty():
				var pa_live: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
				pr_def = _DefenseChoice.defender_feint_listing_pr_def(
					tgt_feint, _EntityAccess.id_int(c), move_id, c, pa_live
				)
		var read_m: float = lerpf(
			1.0,
			CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT,
			pr_def
		)
		var stance_feint_m: float = _WeaponForm.mod(_EntityAccess.form_str(c), "ai_feint_listing")
		feint_list_m = (
			CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * stance_feint_m
		)
		if _tid_feint >= 0:
			var tgt_ob: Dictionary = _EntityAccess.manager_get_combatant(manager, _tid_feint)
			if not tgt_ob.is_empty():
				if not _resistance_active:
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
				feint_list_m *= _feint_listing_opp_parry_deflect_pressure_mult(manager, c, _tid_feint)
				if _tid_feint >= 0:
					var tgt_yomi: Dictionary = _EntityAccess.manager_get_combatant(manager, _tid_feint)
					if not tgt_yomi.is_empty():
						var dom_line: String = _Attention.dominant_attack_line_toward_defender(
							tgt_yomi, combatant_id
						)
						var fp_est: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, "head")
						feint_list_m *= _Attention.yomi_feint_listing_mult(tgt_yomi, combatant_id, fp_est)
						feint_list_m *= _Attention.yomi_parry_deflect_feint_listing_mult(tgt_yomi, combatant_id)
	var counter_tempo_m: float = _CounterTempo.counter_tempo_listing_weight_mult(
		manager, combatant_id, a, move_id
	)
	var attrition_m: float = _attrition_offense_weight_mult(manager, c)
	var exh_offense_m: float = _Exhaustion.exhaustion_offense_weight_mult(c)
	var mood_offense_m: float = _MoodBias.offense_action_weight_mult(
		_MoodBias.mood_bias_for_combatant(manager, c)
	)
	var w: float = (
		base_stamina
		* _TargetScoring.ai_targeting_weight_mult(
			manager,
			combatant_id,
			a,
			skip_targeting_prune,
			actor_zone_geometry_line_context,
			zone_geometry_by_combatant_id
		)
		* polearm_lane
		* form_move_m
		* form_counter_m
		* feint_list_m
		* counter_tempo_m
		* attrition_m
		* exh_offense_m
		* mood_offense_m
	)
	if (
		move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
		and _CombatDoctrine.envelop_mop_up_active(manager, _EntityAccess.formation_id_str(c))
	):
		w *= CombatConstants.ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT
	if (
		move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
		and _FormationFlow.skirmish_line_sparse_after_casualties(
			manager, _EntityAccess.formation_id_str(c)
		)
	):
		w *= CombatConstants.AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT
	elif (
		not all_actions.is_empty()
		and _FormationFlow.skirmish_line_sparse_after_casualties(
			manager, _EntityAccess.formation_id_str(c)
		)
		and _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
	):
		w *= CombatConstants.AI_SPARSE_LINE_OFFENSE_MULT
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		var tgt_id_close_w: int = int(a.get("target_id", -1))
		if tgt_id_close_w >= 0:
			var tgt_close: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_id_close_w)
			if not tgt_close.is_empty():
				w *= _WeaponForm.opponent_close_listing_weight_mult_for_defender(tgt_close)
		if (
			not all_actions.is_empty()
			and _long_close_only_offense_menu(manager, c, combatant_id, all_actions)
			and _EntityAccess.distance_to_opponent_band(c, tgt_id_close_w) == CombatConstants.DISTANCE_LONG
		):
			w *= CombatConstants.AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT
		elif _EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
			w *= CombatConstants.AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT
	w *= _TacticalCombat.iv12_offense_weight_mult(manager, combatant_id)
	return {"weight": w}


## IV-11: doctrine-context weight for party leader / enemy commander instant orders.
static func _leader_formation_command_pick_weight(
	manager: Node, c: Dictionary, move_id: String
) -> float:
	var w: float = CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
	if move_id != CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
		return w
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty():
		return w
	if _CombatDoctrine.numeric_superiority_for_pinch(manager, fid):
		w *= CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
	var mood_bias: float = _MoodBias.mood_bias_for_combatant(manager, c)
	w *= _MoodBias.offense_action_weight_mult(mood_bias)
	return w


## LONG band, close listed but no melee strikes — mapped rank-0 band-lag shuffle (not bind-close wings).
static func _long_close_only_offense_menu(
	manager: Node, c: Dictionary, combatant_id: int, all_actions: Array
) -> bool:
	if manager == null or c.is_empty() or combatant_id < 0 or all_actions.is_empty():
		return false
	if _ListedActions.action_list_has_hostile_melee_strike(all_actions, combatant_id):
		return false
	if _EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
		return false
	var fid: String = _EntityAccess.formation_id_str(c)
	if _CombatDoctrine.envelop_mop_up_active(manager, fid):
		return false
	if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
		return false
	if _EngagementOpposition.wing_lacks_mapped_opposition(manager, c):
		return false
	if not _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
		return false
	for raw in all_actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			continue
		var tid: int = int(a.get("target_id", -1))
		if tid < 0:
			continue
		if _EntityAccess.distance_to_opponent_band(c, tid, "") != CombatConstants.DISTANCE_LONG:
			continue
		if _MeleeListing.attempt_close_listed_for_pair(manager, c, tid, CombatConstants.DISTANCE_LONG):
			return true
	return false


## MS-L8: post-strike weight bonus — apply multiplicative boost to strikes vs recently struck target.
static func _post_strike_weight_mult(c: Dictionary, a: Dictionary, manager: Node) -> float:
	if not CombatConstants.is_feature_ms_post_strike_enabled():
		return 1.0
	var strike_tick_val: float = float(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK, 0.0))
	if strike_tick_val <= 0.0:
		return 1.0
	var current_clock: float = manager.combat_clock
	if absf(strike_tick_val - current_clock) >= CombatConstants.POST_STRIKE_MOMENTUM_CLOCK_TOLERANCE:
		return 1.0
	# Stamp is active — check if this action targets the struck combatant.
	var struck_id: int = int(c.get(CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID, -1))
	if struck_id < 0:
		return 1.0
	var tid: int = int(a.get("target_id", -1))
	if tid != struck_id:
		return 1.0
	var mid: String = str(a.get("move_id", ""))
	if CombatConstants.is_medical_move(mid):
		return 1.0
	if mid == CombatConstants.MOVE_ID_WAIT or mid == CombatConstants.MOVE_ID_FLEE:
		return 1.0
	if CombatConstants.is_formation_movement_move(mid):
		return 1.0
	# This is a strike/close vs the recently struck target — apply bonus.
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
	if tgt.is_empty() or not _EntityAccess.alive_bool(tgt):
		return 1.0
	# Check if defender was forced to parry (has parry_against_id set).
	var parry_forced: bool = tgt.has("parry_against_id") and int(tgt.get("parry_against_id", -1)) >= 0
	if parry_forced:
		return CombatConstants.POST_STRIKE_MOMENTUM_WEIGHT_BONUS
	return CombatConstants.POST_STRIKE_HIT_WEIGHT_BONUS


## Phase 2: Feint resistance gate — returns true when defender has high readiness and is not off-balance.
## Swordmaster teaching: "Do not react to the feint - wait for the real attack."
## Threshold >0.75 means: settled fighter with decent guard (>=0.80) rejects feints;
## recovering fighter must be >89% through recovery (0.75 / 0.85 curve max).
static func _is_feint_resistance_active(defender_id: int, manager: Node) -> bool:
	if defender_id < 0:
		return false
	var defender: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if defender.is_empty():
		return false
	var readiness: float = _PassiveParry.get_passive_parry_readiness(defender)
	if readiness <= 0.75:
		return false
	var state: String = _EntityAccess.state_str(defender)
	if state == CombatConstants.STATE_WIND_UP:
		return false
	if _PassiveParry.is_off_balance(defender):
		return false
	return true


## When mental stack is on but no layer fired: high **`attention_load`** dampens offensive picks (still weighted, not hard block).
## Combat-finish tails (sparse / mop-up) skip salience damp so fights actually end.
static func _salience_offense_weight_mult(c: Dictionary, manager: Node = null) -> float:
	if not CombatConstants.is_feature_mental_stack_ai_enabled():
		return 1.0
	if not _Attention.enabled():
		return 1.0
	if manager != null and not c.is_empty():
		var fid_sal: String = _EntityAccess.formation_id_str(c)
		if (
			_FormationFlow.skirmish_line_sparse_after_casualties(manager, fid_sal)
			or _CombatDoctrine.envelop_mop_up_active(manager, fid_sal)
			or _CombatDoctrine.mop_up_underdog_active(manager, c)
		):
			return 1.0
	var attention_load: float = _Attention.get_attention_load(c)
	if attention_load <= 0.05:
		return 1.0
	return lerpf(
		1.0,
		1.0 - CombatConstants.MENTAL_STACK_SALIENCE_OFFENSE_DAMP_MAX,
		attention_load
	)


## Duel/skirmish (few standing on side): damp routine offense.
## Skip damp on post-flee sparse lines and mop-up tails — low headcount should finish, not idle.
static func _attrition_offense_weight_mult(manager: Node, c: Dictionary) -> float:
	if manager == null:
		return 1.0
	var fid: String = _EntityAccess.formation_id_str(c)
	if _CombatDoctrine.envelop_mop_up_active(manager, fid):
		return 1.0
	if _CombatDoctrine.mop_up_underdog_active(manager, c):
		return 1.0
	if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
		return 1.0
	var side: String = _EntityAccess.side_str(c)
	var standing: int = _EngagementMode.count_active_for_side(manager, side)
	if standing <= int(CombatConstants.AI_ATTRITION_LOW_STANDING_MAX):
		return CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT
	return 1.0


## Fight-finish tails (sparse / mop-up / underdog): damp focus shuffle when strikes/close are listed.
static func _fight_finish_focus_damp_mult(
	manager: Node, c: Dictionary, combatant_id: int, all_actions: Array
) -> float:
	if manager == null or c.is_empty() or all_actions.is_empty():
		return 1.0
	if not _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
		return 1.0
	if not _CombatDoctrine.sparse_line_prefer_finish_over_shuffle(
		manager, c, all_actions, combatant_id
	):
		return 1.0
	return CombatConstants.AI_FOCUS_LINE_SPARSE_ENGAGEMENT_LISTED_MULT


## Tier 4.3.7: focus-line retarget — party lead favors matching incoming telegraph; others rarely shift.
static func _focus_line_action_weight(
	move_id: String, combatant_id: int, manager: Node, c: Dictionary, all_actions: Array = []
) -> float:
	if not _Attention.enabled():
		return 0.0
	var line: String = CombatConstants.guard_line_for_focus_move_id(move_id)
	if line.is_empty():
		return 0.0
	var cur_line: String = str(c.get("guard_line", CombatConstants.GUARD_DEFAULT)).strip_edges()
	if cur_line == line:
		return 0.0
	var part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(line, "")
	var fid_focus: String = _EntityAccess.formation_id_str(c)
	var mood_focus_mult: float = _MoodBias.focus_line_action_weight_mult(
		_MoodBias.mood_bias_for_combatant(manager, c)
	)
	if part.is_empty() or part == _Attention.get_focus_part(c):
		var already_w: float = CombatConstants.AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT
		if _CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
			already_w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
		already_w *= _form_focus_preferred_mult(c, line)
		already_w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
		already_w *= mood_focus_mult
		return already_w
	if _EntityAccess.is_formation_telegraph_leader(c) and _Attention.is_being_wind_up_targeted(manager, combatant_id):
		var tele: String = str(
			c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")
		).strip_edges()
		var tele_line: String = CombatConstants.PART_TO_LINE.get(tele, "")
		if tele_line == line:
			var leader_w: float = CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
			if _CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
				leader_w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
			leader_w *= _form_focus_preferred_mult(c, line)
			leader_w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
			leader_w *= mood_focus_mult
			return leader_w
	var w: float = CombatConstants.AI_FOCUS_LINE_BASE_WEIGHT
	if _CombatDoctrine.envelop_mop_up_active(manager, fid_focus):
		w *= CombatConstants.ENVELOP_MOP_UP_FOCUS_AI_WEIGHT_MULT
	w *= _form_focus_preferred_mult(c, line)
	w *= _fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)
	w *= mood_focus_mult
	return w


static func _form_focus_preferred_mult(c: Dictionary, line: String) -> float:
	var form: String = _EntityAccess.form_str(c)
	for pg in _WeaponForm.preferred_guards(form):
		if str(pg) == line:
			return CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT
	return 1.0


## Controlling opponent front rank → lower disengage listing weight (pairs with duration mult).
static func _opponent_controlling_disengage_listing_divisor(manager: Node, c: Dictionary) -> float:
	if manager == null or c.is_empty():
		return 1.0
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty():
		return 1.0
	return maxf(
		1.0,
		_ZoneOfControl.get_opponent_controlling_disengage_pressure_mult(manager, fid)
	)


## Tier 1.9 (P10): when depth spear lane is open **and** at least one **valid line** rank-0 hostile exists, prefer thrusts; de-emphasize closing (thrust works from MID).
## Formation **`doctrine`** (`pinch_center` / `hold_lane` / `probing`) nudges stab vs cut weights (Tier 1.9 optional coupling).
static func _depth_polearm_action_weight_mult(
	manager: Node,
	c: Dictionary,
	move_id: String,
	actor_zone_geometry_line_context: Dictionary = {}
) -> float:
	if manager == null or c.is_empty():
		return 1.0
	var fid_depth: String = (
		_ZoneOfControl.zone_geometry_fid_from_pack(actor_zone_geometry_line_context)
		if not actor_zone_geometry_line_context.is_empty()
		else _ZoneOfControl.zone_geometry_fid_str(manager, c)
	)
	if not _DepthPolearm.depth_polearm_lane_open(manager, c, fid_depth):
		return 1.0
	if not _DepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(manager, c, manager.combatants):
		return 1.0
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return CombatConstants.DEPTH_POLEARM_AI_ATTEMPT_CLOSE_MULT
	var ct: String = _WeaponConstants.contact_type_for_move_id(move_id)
	# Doctrine keys use home roster **`formation_id`**.
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


static func _get_medical_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
	var mid: String = a.get("move_id", "")
	var tgt_id: int = int(a.get("target_id", -1))
	var part: String = str(a.get("target_part", ""))
	if not _MedicalCoord.medical_action_allowed(manager, combatant_id, tgt_id, part, mid):
		return _MedicalPhase.MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_id)
	var performer: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	var perf_entity: Node = _EntityAccess.get_entity_from_manager(manager, performer)
	var eff_raw: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
	var eff: float = clampf(eff_raw, _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MIN, _MedicalPhase.MEDICAL_AI_EFF_CLAMP_MAX)
	var urgency: float = _MedicalPhase.get_medical_urgency_deterministic(manager, tgt) if not tgt.is_empty() else 0.0
	var part_threat: float = 0.0
	if not tgt.is_empty() and not part.is_empty():
		part_threat = _MedicalPhase.get_part_intervention_threat(manager, tgt, part)
	var w: float = 1.0 + urgency * (_MedicalPhase.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
	w += part_threat * _MedicalPhase.MEDICAL_AI_PART_THREAT_MULT
	var advanced: bool = CombatConstants.is_wind_up_medical_move(mid)
	if advanced:
		w *= pow(eff, _MedicalPhase.MEDICAL_AI_ADVANCED_SKILL_EXP)
	elif mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
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
		if not tgt.is_empty() and _EntityAccess.is_in_immediate_peril(manager, tgt):
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_PENDING_RETRY_PERIL
		else:
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_PENDING_RETRY
	var failed_raw: Variant = tgt.get("failed_medical_parts", null) if not tgt.is_empty() else null
	if (
		failed_raw is Array
		and part in (failed_raw as Array)
		and CombatConstants.is_wind_up_medical_move(mid)
	):
		w *= _MedicalPhase.MEDICAL_AI_WEIGHT_FAILED_PART_RETRY
	if not tgt.is_empty() and not _EntityAccess.is_in_immediate_peril(manager, tgt):
		if mid == CombatConstants.MOVE_ID_STABILIZE_WOUND:
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_STABILIZE_OUT_OF_PERIL
		elif mid == CombatConstants.MOVE_ID_BANDAGE_SELF or mid == CombatConstants.MOVE_ID_PACK_WOUND:
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_DRESSING_OUT_OF_PERIL
	if (
		not tgt.is_empty()
		and not part.is_empty()
		and _EntityAccess.is_in_immediate_peril(manager, tgt)
		and _EntityAccess.entity_is_tourniquet_indicated_for_part(manager, tgt, part)
	):
		if mid == CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_TOURNIQUET_INDICATED
		elif CombatConstants.is_dressing_medical_move(mid):
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_BANDAGE_BEFORE_HEMOSTASIS
	if not tgt.is_empty() and not part.is_empty():
		var bleed_r: float = _EntityAccess.entity_bleeding_rate_for_part(manager, tgt, part)
		var active_bleed: bool = bleed_r > _Bleeding.BLEEDING_RATE_EPSILON
		var held: bool = _EntityAccess.entity_has_direct_pressure_on_part(manager, tgt, part)
		if mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE and _MedicalCoord.can_stack_assist_pressure(
			manager, combatant_id, tgt_id, part
		):
			w *= _MedicalPhase.MEDICAL_AI_WEIGHT_TREATMENT_ASSIST_PRESSURE
		elif held and mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
			return _MedicalPhase.MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED
		if active_bleed and not held:
			if mid == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
				w *= _MedicalPhase.MEDICAL_AI_WEIGHT_PRESSURE_ACTIVE_BLEED
			elif CombatConstants.is_dressing_medical_move(mid):
				if not _MedicalPhase.dressings_allowed_for_part(manager, tgt, part):
					return 0.001
				if mid == CombatConstants.MOVE_ID_PACK_WOUND:
					w *= _MedicalPhase.MEDICAL_AI_WEIGHT_PACK_BEFORE_PRESSURE
	return maxf(w, 0.001)

static func _add_attack_target_part(choice: Dictionary, manager: Node, attacker_id: int) -> void:
	if CombatConstants.is_medical_move(str(choice.get("move_id", ""))):
		return
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return  # Close attempt targets a combatant, not a body part
	if choice.get("move_id", "") in [
		CombatConstants.MOVE_ID_SWAP_RANK,
		CombatConstants.MOVE_ID_DRAG_BACK,
		CombatConstants.MOVE_ID_FALL_BACK,
		CombatConstants.MOVE_ID_ROTATE_FILE,
	]:
		return
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_WAIT:
		return
	if choice.get("move_id", "") == CombatConstants.MOVE_ID_FLEE:
		return
	var tgt_id: int = choice.get("target_id", -1)
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_id)
	if tgt.is_empty():
		return
	var targetable: Array = _EntityAccess.get_targetable_parts(tgt)
	if targetable.is_empty():
		return
	var atk_pick: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if not atk_pick.is_empty():
		targetable = _DepthPolearm.depth_polearm_targetable_parts_filter(manager, atk_pick, targetable)
	if targetable.is_empty():
		return
	var move_def: Dictionary = WeaponConstants.get_move(choice.get("move_id", ""))
	var atk_line: String = move_def.get("attack_line", "high")
	var guard_line: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
	var path: Array = CombatConstants.get_attack_path(atk_line, guard_line)
	var atk_angle_list: float = CombatConstants.line_to_angle(atk_line)
	if atk_pick != null and not atk_pick.is_empty():
		atk_angle_list = _Footwork.attack_angle_deg_for_listing_preview(
			atk_pick, atk_line, atk_angle_list, tgt_id, manager
		)
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
