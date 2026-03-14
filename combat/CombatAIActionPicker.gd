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

## Returns weight for action (medical: urgency + direct pressure bleed + pending retry; attack: 1).
static func _get_action_weight(a: Dictionary, combatant_id: int, manager: Node) -> float:
	var mid: String = a.get("move_id", "")
	if not manager._is_medical_move(mid):
		return 1.0
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
	var tgt_id: int = choice.get("target_id", -1)
	var tgt = manager._get_by_id(tgt_id)
	if tgt == null or tgt.node == null or not tgt.node.has_method("get_targetable_parts"):
		return
	var targetable: Array = tgt.node.get_targetable_parts()
	if targetable.is_empty():
		return
	var move_def: Dictionary = WeaponConstants.get_move(choice.get("move_id", ""))
	var atk_line: String = move_def.get("attack_line", "high")
	var guard_line: String = tgt.get("guard_line", "high")
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
