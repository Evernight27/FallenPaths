class_name CombatAIActionPicker
extends RefCounted

## Picks one action from available actions using weighted randomness. **Combat move choice is fully AI-driven:**
## weights combine stamina + `CombatTargetScoring` (doctrine, file bias, commitment, distributed pressure, **engagement mode**, our formation posture+cohesion, **opponent** formation, **`breached_files`** column press on listed hostiles, stance). No human pick path.
## Medical: deterministic urgency + per-part threat; bandage/pack/tourniquet favor high `get_medical_effectiveness`, pressure favors lower skill.
## Pending retry: strongly prefer retrying the failed part when target is still in peril.
## For attacks: adds target_part from path when pathway allows (unguarded bonus).
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), _is_medical_move, _is_in_immediate_peril.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")

static func pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
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
	return opts

## True when front→back disengage swap is tactically justified (matches high-weight rules in _get_action_weight).
## Plug-forward (incapacitated partner) is handled separately in AvailableActionsBuilder.
## `manager`: required for body-damage / peril gate (fatigue alone must not justify retreat).
static func is_disengage_swap_tactically_allowed(
	c: Dictionary, partner: Dictionary, manager: Node
) -> bool:
	if partner == null or partner.is_empty():
		return false
	if CombatantEntityAccess.is_incapacitated(partner):
		return false
	if not CombatantEntityAccess.retreat_formation_body_damage_warranted(c, manager):
		return false
	var our_fitness: float = _get_positioning_fitness(c)
	var partner_fitness: float = _get_positioning_fitness(partner)
	var gap: float = partner_fitness - our_fitness
	if gap <= 0.0:
		return false
	if CombatantEntityAccess.get_attacking_arm(c).is_empty():
		return not CombatantEntityAccess.get_attacking_arm(partner).is_empty()
	if our_fitness <= CombatConstants.SWAP_RANK_AI_CRITICAL_FITNESS and gap >= CombatConstants.SWAP_RANK_AI_URGENT_MIN_GAP:
		return true
	return gap >= CombatConstants.SWAP_RANK_AI_MIN_FITNESS_GAP

## True when deeper rank (higher rank #) should swap forward with the rank ahead (relief / rotation).
## Mirror of is_disengage_swap_tactically_allowed: we are fitter than the fighter in front of us.
static func is_relief_swap_tactically_allowed(c: Dictionary, partner: Dictionary) -> bool:
	if partner == null or partner.is_empty():
		return false
	if CombatantEntityAccess.is_incapacitated(partner):
		return false
	var our_fitness: float = _get_positioning_fitness(c)
	var partner_fitness: float = _get_positioning_fitness(partner)
	var gap: float = our_fitness - partner_fitness
	if gap <= 0.0:
		return false
	if CombatantEntityAccess.get_attacking_arm(partner).is_empty():
		return not CombatantEntityAccess.get_attacking_arm(c).is_empty()
	if partner_fitness <= CombatConstants.SWAP_RANK_AI_CRITICAL_FITNESS and gap >= CombatConstants.SWAP_RANK_AI_URGENT_MIN_GAP:
		return true
	return gap >= CombatConstants.SWAP_RANK_AI_MIN_FITNESS_GAP

## Returns weight for action. Medical: urgency + direct pressure bleed + pending retry.
## Combat: attack/attempt_close = use stamina (exhausted less likely to engage); swap_rank = fitness only (no stamina).
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
		# Offered only when desperate / peril (AvailableActionsBuilder); keep below routine wait.
		return 0.45
	if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
		return 0.55
	if mid in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK]:
		var partner_id: int = a.get("target_id", -1)
		var partner = manager._get_by_id(partner_id) if partner_id >= 0 else null
		var partner_incapacitated: bool = partner != null and CombatantEntityAccess.is_incapacitated(partner)
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
	return (
		base_stamina
		* _TargetScoring.ai_targeting_weight_mult(manager, combatant_id, a, skip_targeting_prune)
		* polearm_lane
	)

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
	if ct == _WeaponConstants.ATTACK_TYPE_STAB:
		var w: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT
		var doc: String = _CombatDoctrine.doctrine_for_fid(manager, _EntityAccess.formation_id_str(c))
		if doc == CombatConstants.DOCTRINE_PINCH_CENTER:
			w *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT
		elif doc == CombatConstants.DOCTRINE_HOLD_LANE:
			w *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_HOLD_STAB_MULT
		elif doc == CombatConstants.DOCTRINE_PROBING:
			w *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PROBING_STAB_MULT
		return w
	if ct == _WeaponConstants.ATTACK_TYPE_CUT or ct == _WeaponConstants.ATTACK_TYPE_BLUNT:
		var w2: float = CombatConstants.DEPTH_POLEARM_AI_NON_STAB_WEIGHT_MULT
		var doc2: String = _CombatDoctrine.doctrine_for_fid(manager, _EntityAccess.formation_id_str(c))
		if doc2 == CombatConstants.DOCTRINE_HOLD_LANE:
			w2 *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_HOLD_NON_STAB_MULT
		elif doc2 == CombatConstants.DOCTRINE_PINCH_CENTER:
			w2 *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PINCH_NON_STAB_MULT
		elif doc2 == CombatConstants.DOCTRINE_PROBING:
			w2 *= CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PROBING_NON_STAB_MULT
		return w2
	return 1.0

## Fitness for formation positioning: performance (attack capability) × health (blood). Higher = more able to fight.
## Used for swap rank: lowest fitness should be in back. Does not use stamina/action-ready.
static func _get_positioning_fitness(c: Dictionary) -> float:
	var perf: float = CombatantEntityAccess.get_performance_modifier(c)
	var n: Node = CombatantEntityAccess.scene_node(c)
	var health: float = clampf(CombatantEntityAccess.get_blood_volume_from_node(n) / 100.0, 0.0, 1.0) if n != null else 1.0
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
	var tgt_n: Node = _EntityAccess.scene_node(tgt) if tgt != null else null
	if tgt == null or tgt_n == null or not tgt_n.has_method("get_targetable_parts"):
		return
	var targetable: Array = tgt_n.get_targetable_parts()
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
	var align_ctx: Dictionary = {"attack_angle_deg": CombatConstants.line_to_angle(atk_line), "guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt)}
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
