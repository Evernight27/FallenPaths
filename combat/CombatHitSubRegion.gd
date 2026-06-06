class_name CombatHitSubRegion
extends RefCounted

const _Bleeding := preload("res://core/BleedingConstants.gd")

## Deterministic anatomy site on a hit part (S2). Path intercept + attack line bias; no combat RNG.
## Footing: **`attack_line`** biases site pick; **`guard_line`** arg unused at resolve — not L3 drift or PA geometry. LIVE_PATHS **`#wf-layer-labels`**.

static func resolve_sub_region(
	part: String,
	attack_line: String,
	_guard_line: String,
	alignment_context: Dictionary,
	_move_id: String,
	path_intercept_index: int
) -> String:
	var subs: Array = _Bleeding.SUB_REGIONS.get(part, [])
	if subs.is_empty():
		return ""
	var height_bias: float = _height_bias_from_attack_line(attack_line, alignment_context)
	var intercept_norm: float = _intercept_norm(path_intercept_index)
	var site_t: float = clampf(0.62 * height_bias + 0.38 * intercept_norm, 0.0, 1.0)
	var chosen: String = _sub_region_for_part(part, site_t, _move_id)
	if chosen.is_empty() or not subs.has(chosen):
		return fallback_sub_region(part, _stable_seed(part, attack_line, path_intercept_index))
	return chosen


## Hash-weighted pick from SUB_REGION_WEIGHTS (stable; not randf).
static func fallback_sub_region(part: String, stable_seed: int = 0) -> String:
	var weights: Dictionary = _Bleeding.SUB_REGION_WEIGHTS.get(part, {})
	if weights.is_empty():
		var subs: Array = _Bleeding.SUB_REGIONS.get(part, [])
		return str(subs[0]) if not subs.is_empty() else ""
	return _weighted_pick_deterministic(weights, stable_seed)


static func _stable_seed(part: String, attack_line: String, path_intercept_index: int) -> int:
	return hash("%s|%s|%d" % [part, attack_line, path_intercept_index]) & 0x7FFFFFFF


static func _stable_unit(stable_seed: int) -> float:
	return float(stable_seed % 10000) / 10000.0


static func _weighted_pick_deterministic(weights: Dictionary, stable_seed: int) -> String:
	var total: float = 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return ""
	var r: float = _stable_unit(stable_seed) * total
	var acc: float = 0.0
	for sub in weights:
		acc += float(weights[sub])
		if r < acc:
			return str(sub)
	var keys: Array = weights.keys()
	return str(keys[keys.size() - 1]) if not keys.is_empty() else ""


static func _intercept_norm(path_intercept_index: int) -> float:
	var early: float = float(CombatConstants.PATH_INTERCEPT_EARLY_MAX)
	var full: float = float(CombatConstants.PATH_INTERCEPT_FULL_MAX)
	return clampf(
		(float(path_intercept_index) - early) / maxf(1.0, full - early),
		0.0,
		1.0
	)


static func _height_bias_from_attack_line(attack_line: String, alignment_context: Dictionary) -> float:
	if alignment_context.get("attack_angle_deg", null) is float:
		var deg: float = float(alignment_context["attack_angle_deg"])
		deg = fmod(deg, 360.0)
		if deg < 0.0:
			deg += 360.0
		if deg <= 45.0 or deg >= 315.0:
			return 0.0
		if deg >= 135.0 and deg <= 225.0:
			return 1.0
		return 0.5
	var line: String = str(attack_line).strip_edges().to_lower()
	if line.is_empty():
		return 0.5
	if line.contains("high"):
		return 0.0
	if line.contains("low"):
		return 1.0
	if line == "high":
		return 0.0
	if line == "low":
		return 1.0
	return 0.45


static func _sub_region_for_part(part: String, site_t: float, move_id: String) -> String:
	match part:
		"head":
			if site_t < 0.38:
				return "scalp"
			if site_t < 0.72:
				return "face"
			return "neck"
		"chest":
			return "abdominal" if site_t >= 0.55 else "thoracic"
		"right_arm", "left_arm":
			return _sub_region_for_limb(site_t, move_id)
		"right_leg", "left_leg":
			if site_t < 0.28:
				return "thigh"
			if site_t < 0.48:
				return "knee"
			if site_t < 0.78:
				return "calf"
			return "foot"
		_:
			return ""


static func _sub_region_for_limb(site_t: float, move_id: String) -> String:
	var mid: String = str(move_id).strip_edges()
	if mid.contains("thrust") or mid.contains("stab"):
		if site_t < 0.35:
			return "upper_arm"
		return "forearm"
	if site_t < 0.22:
		return "upper_arm"
	if site_t < 0.42:
		return "elbow"
	if site_t < 0.72:
		return "forearm"
	return "hand"
