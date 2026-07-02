class_name AttackPathResolver
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _WeightedSample := preload("res://core/WeightedSample.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _Bp := preload("res://core/BodyPartConstants.gd")
const _Proficiency := preload("res://core/EntityProficiency.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")

## Maximum stacking multiplier before INT-based preferred_mult (enforces ~1.5x cap on product of anatomy × weapon × form × move_family).
const MAX_PRE_INT_WEIGHT_MULT: float = 1.5

## Option 6: Path + Guard Intercept  -  hit part selection from blade trajectory.
## Footing: optional **`alignment_context`** **`attack_angle_deg`** / **`guard_angle_deg`**  -  use **`CombatFootwork.guard_angle_deg`** at contact, not raw **`guard_line`** alone when PA flag on. LIVE_PATHS **`#wf-tier-44-pa`** (geometry).
## Path varies by (attack_line, guard_line): defender posture determines what's in the blade's way.
## High guard vs high attack = arms first; low guard vs high attack = head exposed first.
## Intercept: high alignment = early contact; low = blade travels further.

## Returns hit part from path + intercept. Falls back to weighted random if path yields nothing.
## defender_ctx: optional { state, recovery_cause, passive_parry_attempted } for reaction-state modifiers.
## defender: optional combatant dict for deflect-aware alignment (guard_deflect_blend).
## intended_part: optional; when in path segment, boosts weight (attacker aimed here).
## alignment_context: optional { attack_angle_deg, guard_angle_deg } for angle-based alignment.
## attacker: optional combatant dict for proficiency-scaled intended-part boost.
## move_def: optional move definition for contact_type / preferred_parts context.
static func resolve_hit_part(
	attack_line: String,
	guard_line: String,
	targetable: Array,
	defender_ctx: Dictionary = {},
	intended_part: String = "",
	defender: Dictionary = {},
	alignment_context: Dictionary = {},
	attacker: Dictionary = {},
	move_def: Dictionary = {},
	depth_allows_low: bool = true
) -> String:
	if targetable.is_empty():
		return ""
	var atk_line_path: String = attack_line
	var guard_line_path: String = guard_line
	if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
		atk_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["attack_angle_deg"]))
		guard_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["guard_angle_deg"]))
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	if path.is_empty():
		return BodyPartConstants.get_weighted_random_part(targetable)
	var def_for_align: Dictionary = defender if not defender.is_empty() else {"guard_line": guard_line}
	var alignment: float = CombatConstants.get_line_alignment_with_deflect(attack_line, def_for_align, alignment_context)
	var intercept_max: int = intercept_max_index_for_alignment(path, alignment)
	var path_segment: Array = []
	for i in range(intercept_max + 1):
		if i < path.size():
			var p: String = path[i]
			if targetable.has(p):
				path_segment.append(p)
	if path_segment.is_empty():
		return BodyPartConstants.get_weighted_random_part(targetable)
	# Reaction state: RECOVERING + attack_hit = staggered, bias center mass. Parry attempted + hit = limbs in way.
	var part_weights: Dictionary = {}
	for p in path_segment:
		part_weights[p] = 1.0
	var recovery_cause: String = CombatConstants.normalize_recovery_cause(
		defender_ctx.get("recovery_cause", "")
	)
	var passive_parry: bool = defender_ctx.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
	if recovery_cause == "attack_hit" and _EntityAccess.state_str(defender_ctx) == CombatConstants.STATE_RECOVERING:
		# Staggered: center mass (chest) more likely
		if part_weights.has(BodyPartConstants.PART_CHEST):
			part_weights[BodyPartConstants.PART_CHEST] = 1.5
	if passive_parry:
		# Blade met blade; if hit, limbs (arms) more likely in the way
		for limb in [BodyPartConstants.PART_LEFT_ARM, BodyPartConstants.PART_RIGHT_ARM]:
			if part_weights.has(limb):
				part_weights[limb] = 1.4
	var interpose: Dictionary = _GuardLines.arm_interpose_eval(attack_line, guard_line, alignment, targetable)
	if interpose.get("active", false):
		var interpose_arm: String = interpose.get("arm", "")
		if path_segment.has(interpose_arm):
			part_weights[interpose_arm] = (
				part_weights.get(interpose_arm, 1.0) * CombatConstants.ARM_INTERPOSE_HIT_WEIGHT_MULT
			)
	var contact_type: String = str(move_def.get("contact_type", "")).to_lower()
	if not attacker.is_empty():
		var wid_resolve: String = _weapon_id_for_attacker(attacker)
		for p in path_segment:
			var part_wptm: float = _Bp.weapon_part_target_mult(wid_resolve, p, contact_type)
			if not depth_allows_low and (p == BodyPartConstants.PART_LEFT_LEG or p == BodyPartConstants.PART_RIGHT_LEG):
				part_wptm = 1.0
			part_weights[p] = part_weights.get(p, 1.0) * part_wptm
	# Intended target: boost weight when in path (attacker aimed here; pathway allows it).
	if not intended_part.is_empty() and path_segment.has(intended_part):
		var intended_boost: float = 2.0
		if not attacker.is_empty():
			var ent: CoreEntity = _EntityAccess.scene_entity(attacker)
			if ent != null:
				intended_boost = _Proficiency.intended_part_boost_mult(
					ent,
					_weapon_id_for_attacker(attacker),
					_EntityAccess.form_str(attacker)
				)
		part_weights[intended_part] = part_weights.get(intended_part, 1.0) * intended_boost
	var part: String = BodyPartConstants.get_weighted_random_part(path_segment) if part_weights.values().min() == part_weights.values().max() else _WeightedSample.pick_random(part_weights)
	if part.is_empty():
		part = BodyPartConstants.get_weighted_random_part(path_segment)
	if CombatConstants.combat_debug_active():
		var angle_info: String = ""
		if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
			angle_info = " (atk=%.0fdeg guard=%.0fdeg)" % [float(alignment_context["attack_angle_deg"]), float(alignment_context["guard_angle_deg"])]
		CombatDebug.log("path atk=%s guard=%s%s align=%.2f intercept_max=%d segment=%s => %s" % [atk_line_path, guard_line_path, angle_info, alignment, intercept_max, str(path_segment), part])
	return part


## Path intercept depth from alignment (0 = early parts on path, path.size()-1 = full depth).
static func intercept_max_index_for_alignment(path: Array, alignment: float) -> int:
	if path.is_empty():
		return 0
	var intercept_max: int = int(
		lerpf(
			float(CombatConstants.PATH_INTERCEPT_EARLY_MAX),
			float(path.size() - 1),
			1.0 - alignment
		)
	)
	return clampi(intercept_max, 0, path.size() - 1)


static func path_intercept_max_index(
	attack_line: String,
	guard_line: String,
	alignment: float,
	alignment_context: Dictionary = {}
) -> int:
	var atk_line_path: String = attack_line
	var guard_line_path: String = guard_line
	if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
		atk_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["attack_angle_deg"]))
		guard_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["guard_angle_deg"]))
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	return intercept_max_index_for_alignment(path, alignment)


## Targetable parts on attack path up to intercept depth (listing / AI pick).
static func path_segment_for_strike(
	attack_line: String,
	guard_line: String,
	targetable: Array,
	alignment: float,
	alignment_context: Dictionary = {}
) -> Array:
	if targetable.is_empty():
		return []
	var atk_line_path: String = attack_line
	var guard_line_path: String = guard_line
	if alignment_context.get("attack_angle_deg", null) is float and alignment_context.get("guard_angle_deg", null) is float:
		atk_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["attack_angle_deg"]))
		guard_line_path = CombatConstants.angle_to_nearest_line(float(alignment_context["guard_angle_deg"]))
	var path: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	if path.is_empty():
		return targetable.duplicate()
	var intercept_max: int = intercept_max_index_for_alignment(path, alignment)
	var segment: Array = []
	for i in range(intercept_max + 1):
		if i < path.size():
			var p: String = path[i]
			if targetable.has(p):
				segment.append(p)
	return segment


## Per-part weights for AI target pick: move, weapon, form, defender focus, yomi, attacker stats.
static func _stat_exploit_tier(stat: float) -> float:
	var spread: float = maxf(CombatConstants.AI_PICK_STAT_SPREAD, 1.0)
	var floor_stat: float = CombatConstants.AI_PICK_STAT_BASELINE - spread * 0.5
	return clampf((stat - floor_stat) / spread, 0.0, 1.0)


static func _weapon_id_for_attacker(attacker: Dictionary) -> String:
	var weapon: Variant = _EntityAccess.get_weapon(attacker)
	if weapon == null:
		return ""
	if "weapon_type" in weapon:
		return str(weapon.weapon_type).to_upper().strip_edges()
	return ""


static func part_weights_for_ai_pick(
	path_segment: Array,
	attack_line: String,
	move_def: Dictionary,
	attacker: Dictionary,
	defender: Dictionary,
	attacker_id: int,
	move_id: String = "",
	depth_allows_low: bool = true
) -> Dictionary:
	var weights: Dictionary = {}
	if path_segment.is_empty():
		return weights
	var wid_pick: String = _weapon_id_for_attacker(attacker)
	if move_id.is_empty():
		move_id = str(move_def.get("id", ""))
	var preferred: Array = (
		_WeaponConstants.preferred_parts_for_weapon_move(wid_pick, move_id)
		if not move_id.is_empty()
		else move_def.get("preferred_parts", [])
	)
	var contact_type: String = str(move_def.get("contact_type", "")).to_lower()
	var focus_part: String = _Attention.get_focus_part(defender) if _Attention.enabled() else ""
	var focus_line: String = CombatConstants.PART_TO_LINE.get(focus_part, "")
	var dom_line: String = ""
	var dom_count: int = 0
	if _Attention.enabled() and attacker_id >= 0:
		dom_line = _Attention.dominant_attack_line_toward_defender(defender, attacker_id)
		if not dom_line.is_empty():
			dom_count = _Attention.line_count_toward_defender(defender, attacker_id, dom_line)
	var form: String = _EntityAccess.form_str(attacker)
	var weapon_id: String = wid_pick
	var ent: CoreEntity = _EntityAccess.scene_entity(attacker)
	var form_prof_tier: float = _Proficiency.form_proficiency_tier(ent, form) if ent != null else 0.0
	var weapon_prof_tier: float = _Proficiency.weapon_proficiency_tier(ent, weapon_id) if ent != null else 0.0
	var prof_aim_mult: float = _Proficiency.proficiency_aim_part_mult(ent, weapon_id, form) if ent != null else 1.0
	var stats: Dictionary = _EntityAccess.stats_dict(attacker)
	var perception: float = float(stats.get("perception", CombatConstants.DEFAULT_STAT_VALUE))
	var intelligence: float = float(stats.get("intelligence", CombatConstants.DEFAULT_STAT_VALUE))
	var perc_tier: float = _stat_exploit_tier(perception)
	var intel_tier: float = _stat_exploit_tier(intelligence)
	var off_focus_mult: float = lerpf(
		CombatConstants.AI_PICK_NOVICE_OFF_FOCUS_MULT,
		CombatConstants.AI_PICK_OFF_FOCUS_PART_MULT,
		perc_tier
	)
	var on_focus_penalty: float = lerpf(
		0.92,
		CombatConstants.AI_PICK_ON_FOCUS_LINE_PENALTY_MULT,
		perc_tier
	)
	var yomi_habit_mult: float = lerpf(
		CombatConstants.AI_PICK_NOVICE_YOMI_HABIT_MULT,
		CombatConstants.AI_PICK_YOMI_HABIT_LINE_PART_MULT,
		perc_tier
	)
	var yomi_counter_mult: float = lerpf(
		CombatConstants.AI_PICK_NOVICE_YOMI_COUNTER_MULT,
		CombatConstants.AI_PICK_YOMI_COUNTER_LINE_PART_MULT,
		perc_tier
	)
	var preferred_mult: float = lerpf(
		CombatConstants.AI_PICK_NOVICE_PREFERRED_MULT,
		CombatConstants.PREFERRED_PART_BONUS_MULT,
		intel_tier
	)
	for p in path_segment:
		var w: float = _Bp.BODY_PART_TARGET_WEIGHTS.get(p, 1.0)
		var wid_mult: float = _Bp.weapon_part_target_mult(weapon_id, p, contact_type)
		if not depth_allows_low and (p == BodyPartConstants.PART_LEFT_LEG or p == BodyPartConstants.PART_RIGHT_LEG):
			wid_mult = 1.0
		w *= wid_mult
		w *= _WeaponForm.target_part_weight_mult(form, p, form_prof_tier, _EntityAccess.get_weapon(attacker))
		if not move_id.is_empty():
			w *= _WeaponForm.move_family_part_weight_mult(
				form, move_id, p, _EntityAccess.get_weapon(attacker)
			)
		w *= lerpf(1.0, prof_aim_mult, weapon_prof_tier * 0.5 + form_prof_tier * 0.5)
		var raw_weight: float = w
		var anatomy_base: float = _Bp.BODY_PART_TARGET_WEIGHTS.get(p, 1.0)
		w = minf(raw_weight, anatomy_base * MAX_PRE_INT_WEIGHT_MULT)
		if preferred.has(p):
			w *= preferred_mult
		var part_line: String = CombatConstants.PART_TO_LINE.get(p, "")
		if not focus_part.is_empty():
			if p == focus_part and part_line == attack_line:
				w *= on_focus_penalty
			elif part_line != focus_line or p != focus_part:
				w *= off_focus_mult
		if not dom_line.is_empty() and dom_count >= CombatConstants.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT:
			var habit_part: String = str(CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, ""))
			if attack_line == dom_line and p == habit_part:
				w *= yomi_habit_mult
			elif attack_line != dom_line:
				w *= yomi_counter_mult
		for pg in _WeaponForm.preferred_guards(form):
			if pg == attack_line or str(CombatConstants.LINE_TO_DEFAULT_PART.get(pg, "")) == p:
				w *= CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT
				break
		weights[p] = maxf(w, 0.001)
	# Diagonal variance: blend across resolved lines instead of using declared attack_line weights.
	weights = _apply_diagonal_variance_weights(weights, path_segment, attack_line, move_def, attacker, defender, attacker_id, move_id, preferred_mult, preferred)
	return weights


static func pick_weighted_part_from_weights(weights: Dictionary, fallback_segment: Array) -> String:
	if weights.is_empty():
		return _Bp.get_weighted_random_part(fallback_segment)
	var flat: bool = true
	var first_w: float = -1.0
	for w in weights.values():
		if first_w < 0.0:
			first_w = float(w)
		elif absf(float(w) - first_w) > 0.001:
			flat = false
			break
	if flat:
		return _Bp.get_weighted_random_part(fallback_segment)
	var picked: String = _WeightedSample.pick_random(weights)
	if picked.is_empty():
		return _Bp.get_weighted_random_part(fallback_segment)
	return picked


## AI turn pick: path segment from guard + alignment, weighted by focus/yomi/form/move.
static func pick_ai_target_part(
	attack_line: String,
	guard_line: String,
	targetable: Array,
	alignment: float,
	move_def: Dictionary,
	attacker: Dictionary,
	defender: Dictionary,
	attacker_id: int,
	alignment_context: Dictionary = {},
	move_id: String = "",
	depth_allows_low: bool = true
) -> String:
	var segment: Array = path_segment_for_strike(
		attack_line, guard_line, targetable, alignment, alignment_context
	)
	if segment.is_empty():
		return _Bp.get_weighted_random_part(targetable)
	var weights: Dictionary = part_weights_for_ai_pick(
		segment, attack_line, move_def, attacker, defender, attacker_id, move_id, depth_allows_low
	)
	return pick_weighted_part_from_weights(weights, segment)


## Feint telegraph part: bait defender focus / yomi habit when possible.
static func pick_feint_part_for_attack(
	target_part: String,
	targetable: Array,
	defender: Dictionary,
	attacker_id: int
) -> String:
	var candidates: Array = []
	for p in targetable:
		if p != target_part:
			candidates.append(p)
	if candidates.is_empty():
		return ""
	if _Attention.enabled():
		var focus_part: String = _Attention.get_focus_part(defender)
		if not focus_part.is_empty() and focus_part != target_part and candidates.has(focus_part):
			return focus_part
		var dom_line: String = _Attention.dominant_attack_line_toward_defender(defender, attacker_id)
		if not dom_line.is_empty():
			var habit_part: String = str(CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, ""))
			if habit_part != target_part and candidates.has(habit_part):
				return habit_part
	return candidates[randi() % candidates.size()]


## Get diagonal resolve distribution for a move_id and guard_line. Returns {resolved_line: probability} or empty if no diagonal variance.
static func _get_diagonal_resolve_distribution(move_id: String, guard_line: String) -> Dictionary:
	var raw: Dictionary = _WeaponConstants.DIAGONAL_WEIGHTS.get(move_id, {}).get(guard_line, {})
	if raw.is_empty():
		return {}
	var total: float = 0.0
	for w in raw.values():
		total += float(w)
	if total <= 0.0:
		return {}
	var result: Dictionary = {}
	for line in raw.keys():
		result[line] = float(raw[line]) / total
	return result


## Compute Layer B weights as expected distribution over diagonal resolve lines, replacing declared-line weighting.
static func _apply_diagonal_variance_weights(weights: Dictionary, segment: Array, attack_line: String, move_def: Dictionary, attacker: Dictionary, defender: Dictionary, attacker_id: int, move_id: String, preferred_mult: float, preferred: Array) -> Dictionary:
	if move_id.is_empty():
		return weights
	var diagonal_dist: Dictionary = _get_diagonal_resolve_distribution(move_id, attack_line)
	if diagonal_dist.is_empty():
		return weights
	var expected_weights: Dictionary = {}
	for resolved_line in diagonal_dist.keys():
		var line_w: Dictionary = _compute_weights_for_segment(segment, resolved_line, move_def, attacker, defender, attacker_id, move_id, preferred_mult, preferred)
		for p in line_w.keys():
			expected_weights[p] = expected_weights.get(p, 0.0) + line_w[p] * diagonal_dist[resolved_line]
	var result: Dictionary = {}
	for p in weights.keys():
		result[p] = maxf(expected_weights.get(p, 0.001), 0.001)
	return result


## Extract weight computation loop for use by diagonal variance blending.
static func _compute_weights_for_segment(
	path_segment: Array,
	resolved_line: String,
	move_def: Dictionary,
	attacker: Dictionary,
	defender: Dictionary,
	attacker_id: int,
	move_id: String,
	preferred_mult: float,
	preferred: Array
) -> Dictionary:
	var weights: Dictionary = {}
	if path_segment.is_empty():
		return weights
	var wid_pick: String = _weapon_id_for_attacker(attacker)
	var preferred_guards: Array = _WeaponForm.preferred_guards(_EntityAccess.form_str(attacker))
	var form_prof_tier: float = 0.0
	var weapon_prof_tier: float = 0.0
	var prof_aim_mult: float = 1.0
	var focus_part: String = ""
	var focus_line: String = ""
	var dom_line: String = ""
	var dom_count: int = 0
	var on_focus_penalty: float = 1.0
	var off_focus_mult: float = 1.0
	var yomi_habit_mult: float = 1.0
	var yomi_counter_mult: float = 1.0
	if _Attention.enabled():
		focus_part = _Attention.get_focus_part(defender)
		focus_line = CombatConstants.PART_TO_LINE.get(focus_part, "")
		dom_line = _Attention.dominant_attack_line_toward_defender(defender, attacker_id)
		if not dom_line.is_empty():
			dom_count = _Attention.line_count_toward_defender(defender, attacker_id, dom_line)
	var ent: CoreEntity = _EntityAccess.scene_entity(attacker)
	if ent != null:
		form_prof_tier = _Proficiency.form_proficiency_tier(ent, _EntityAccess.form_str(attacker))
		weapon_prof_tier = _Proficiency.weapon_proficiency_tier(ent, wid_pick)
		prof_aim_mult = _Proficiency.proficiency_aim_part_mult(ent, wid_pick, _EntityAccess.form_str(attacker))
	var stats: Dictionary = _EntityAccess.stats_dict(attacker)
	var perception: float = float(stats.get("perception", CombatConstants.DEFAULT_STAT_VALUE))
	var perc_tier: float = _stat_exploit_tier(perception)
	on_focus_penalty = lerpf(CombatConstants.AI_PICK_NOVICE_ON_FOCUS_LINE_PENALTY_MULT, CombatConstants.AI_PICK_ON_FOCUS_LINE_PENALTY_MULT, perc_tier)
	off_focus_mult = lerpf(CombatConstants.AI_PICK_NOVICE_OFF_FOCUS_MULT, CombatConstants.AI_PICK_OFF_FOCUS_PART_MULT, perc_tier)
	yomi_habit_mult = lerpf(CombatConstants.AI_PICK_NOVICE_YOMI_HABIT_MULT, CombatConstants.AI_PICK_YOMI_HABIT_LINE_PART_MULT, perc_tier)
	yomi_counter_mult = lerpf(CombatConstants.AI_PICK_NOVICE_YOMI_COUNTER_MULT, CombatConstants.AI_PICK_YOMI_COUNTER_LINE_PART_MULT, perc_tier)
	var contact_type: String = str(move_def.get("contact_type", "")).to_lower()
	for p in path_segment:
		var w: float = _Bp.BODY_PART_TARGET_WEIGHTS.get(p, 1.0)
		w *= _Bp.weapon_part_target_mult(wid_pick, p, contact_type)
		w *= _WeaponForm.target_part_weight_mult(_EntityAccess.form_str(attacker), p, form_prof_tier, _EntityAccess.get_weapon(attacker))
		if not move_id.is_empty():
			w *= _WeaponForm.move_family_part_weight_mult(_EntityAccess.form_str(attacker), move_id, p, _EntityAccess.get_weapon(attacker))
		w *= lerpf(1.0, prof_aim_mult, weapon_prof_tier * 0.5 + form_prof_tier * 0.5)
		if preferred.has(p):
			w *= preferred_mult
		var part_line: String = CombatConstants.PART_TO_LINE.get(p, "")
		if not focus_part.is_empty():
			if p == focus_part and part_line == resolved_line:
				w *= on_focus_penalty
			elif part_line != focus_line or p != focus_part:
				w *= off_focus_mult
		if not dom_line.is_empty() and dom_count >= CombatConstants.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT:
			var habit_part: String = str(CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, ""))
			if resolved_line == dom_line and p == habit_part:
				w *= yomi_habit_mult
			elif resolved_line != dom_line:
				w *= yomi_counter_mult
		for pg in preferred_guards:
			if pg == resolved_line or str(CombatConstants.LINE_TO_DEFAULT_PART.get(pg, "")) == p:
				w *= CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT
				break
		weights[p] = maxf(w, 0.001)
	return weights



