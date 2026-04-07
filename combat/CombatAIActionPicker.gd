class_name CombatAIActionPicker
extends RefCounted

## Picks one action from available actions using weighted randomness.
## Medical: weight by TARGET's urgency (prioritize treating most critical ally). Attacks: 1.
## Self direct pressure: weight by part's bleeding rate (prioritize most serious wound).
## Pending retry: strongly prefer retrying the failed part when target is still in peril.
## For attacks: adds target_part from path when pathway allows (unguarded bonus).
## Manager must have: _get_by_id, _get_entity, _is_medical_move, _get_medical_urgency, _is_in_immediate_peril.

static func pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
	if actions.is_empty():
		return {}
	var total: float = 0.0
	for a in actions:
		total += _get_action_weight(a, combatant_id, manager)
	var r: float = randf() * total
	for a in actions:
		var w: float = _get_action_weight(a, combatant_id, manager)
		if r < w:
			var choice: Dictionary = a.duplicate()
			_add_attack_target_part(choice, manager)
			return choice
		r -= w
	var fallback: Dictionary = actions[0].duplicate()
	_add_attack_target_part(fallback, manager)
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
static func is_disengage_swap_tactically_allowed(c: Dictionary, partner: Dictionary) -> bool:
	if partner == null or partner.is_empty():
		return false
	if CombatantEntityAccess.is_incapacitated(partner):
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
static func _get_action_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
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
		var via: float = CombatConstants.crash_breach_viability(c)
		var stamina_ratio_c: float = clampf(c.get("stamina", CombatConstants.STAMINA_MAX) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
		var sr_c: float = 0.78 if stamina_ratio_c < 0.32 else 1.0
		var shaped: float = pow(via, CombatConstants.CRASH_AI_VIABILITY_EXPONENT)
		return CombatConstants.CRASH_AI_WEIGHT_CAP * shaped * sr_c
	if mid == CombatConstants.MOVE_ID_FALL_BACK and a.get("target_id", -1) == combatant_id:
		return 0.65  # Solo step to rear — situational
	if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
		return 0.55
	if mid in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK]:
		var partner_id: int = a.get("target_id", -1)
		var partner = manager._get_by_id(partner_id) if partner_id >= 0 else null
		var partner_incapacitated: bool = partner != null and CombatantEntityAccess.is_incapacitated(partner)
		if partner_incapacitated:
			# Back rank plugging forward — partner (front) is incapacitated; strongly prefer.
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
		if partner != null and c.get("rank", 0) > partner.get("rank", 0):
			# Deeper rank swapping up (relief) — only swap_rank is offered for this path in builder.
			if mid != CombatConstants.MOVE_ID_SWAP_RANK:
				return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
			if is_relief_swap_tactically_allowed(c, partner):
				return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
			return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
		if partner != null and is_disengage_swap_tactically_allowed(c, partner):
			return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
		return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
	# Attack or attempt_close: engaging the enemy — use stamina (exhausted units less likely to act)
	var stamina_ratio: float = clampf(c.get("stamina", CombatConstants.STAMINA_MAX) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
	return 0.85 if stamina_ratio < 0.2 else 1.0

## Fitness for formation positioning: performance (attack capability) × health (blood). Higher = more able to fight.
## Used for swap rank: lowest fitness should be in back. Does not use stamina/action-ready.
static func _get_positioning_fitness(c: Dictionary) -> float:
	var perf: float = CombatantEntityAccess.get_performance_modifier(c)
	var node = c.get("node", null)
	var health: float = clampf(CombatantEntityAccess.get_blood_volume_from_node(node) / 100.0, 0.0, 1.0) if node != null else 1.0
	return perf * health

static func _get_medical_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
	var mid: String = a.get("move_id", "")
	var tgt = manager._get_by_id(a.get("target_id", -1))
	var urgency: float = manager._get_medical_urgency(tgt) if tgt != null else 0.0
	var w: float = 1.0 + urgency * (MedicalPhaseController.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
	# Self direct pressure while receiving care: prioritize part with highest bleeding
	if mid == "apply_direct_pressure" and a.get("target_id") == combatant_id and tgt != null:
		var part: String = a.get("target_part", "")
		if not part.is_empty() and tgt.node != null:
			var entity = manager._get_entity(tgt.node)
			if entity != null and entity.has_method("get_bleeding_rate_for_part"):
				w += entity.get_bleeding_rate_for_part(part) * 2.0
	# Pending retry: only one who can help; strongly prefer retrying the failed part.
	var pr = manager._get_by_id(combatant_id)
	var pending = pr.get("pending_retry", {}) if pr != null else {}
	if not pending.is_empty() and pending.get("target_id", -1) == a.get("target_id", -1) and pending.get("part", "") == a.get("target_part", ""):
		if tgt != null and manager._is_in_immediate_peril(tgt):
			w *= 20.0
	return w

static func _add_attack_target_part(choice: Dictionary, manager: Node) -> void:
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
	if tgt == null or tgt.node == null or not tgt.node.has_method("get_targetable_parts"):
		return
	var targetable: Array = tgt.node.get_targetable_parts()
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
