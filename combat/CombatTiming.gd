class_name CombatTiming
extends RefCounted

## Combat timing calculations: intensity, wind-up, recovery, velocity curve.
## Extracted from CombatManager for reuse by AttackResolver and other systems.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Formation move duration: heavier armor slows fall-back / swap / rotate (see **`FORMATION_ARMOR_*`** in **`CombatConstants`**).
static func armor_mass_duration_multiplier_for_node(node: Node) -> float:
	if node == null:
		return 1.0
	var m: float = _EntityAccess.get_total_armor_mass_kg_from_node(node)
	var ref: float = CombatConstants.FORMATION_ARMOR_MASS_REF_KG
	var t: float = clampf(m / ref, 0.0, 1.5)
	return lerpf(1.0, CombatConstants.FORMATION_ARMOR_MAX_SLOW_MULT, t)


## Current time in seconds (Time.get_ticks_msec() / 1000.0). Single source for combat time checks.
static func now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

static func intensity_from_stats(c: Dictionary) -> float:
	var str_val: float = float(_EntityAccess.stats_dict(c).get("strength", 100))
	var base: float = 0.2 + CombatConstants.INTENSITY_STRENGTH_SCALE * (str_val / CombatConstants.INTENSITY_STRENGTH_NORM)
	return clampf(base + randf_range(-CombatConstants.INTENSITY_RANDOM_RANGE, CombatConstants.INTENSITY_RANDOM_RANGE), 0.1, 1.0)

static func wind_up_duration(intensity: float, windup_multiplier: float = 1.0) -> float:
	return (CombatConstants.WIND_UP_BASE_S + CombatConstants.WIND_UP_SCALE_S * intensity) * maxf(0.5, windup_multiplier)


## Guard-line transition multiplier for wind-up (clamped — see **`GUARD_TRANSITION_MULT_MAX`**).
static func guard_transition_mult(align: float) -> float:
	var a: float = clampf(align, 0.0, 1.0)
	var raw: float = 1.0 + (1.0 - a) * CombatConstants.GUARD_TRANSITION_COST_SCALE
	return minf(raw, CombatConstants.GUARD_TRANSITION_MULT_MAX)

## Velocity curve over wind-up progress (0 = swing start, 1 = impact). Peak at 1.0 so impact uses full velocity.
## Quadratic (p²): blade accelerates into impact; early parry meets less momentum than linear.
static func velocity_curve_factor(progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	return p * p

## Agility shortens recovery (higher = faster back to ready). agility 100 = 1.0; 50 = 0.7, 150 = 1.3.
static func recovery_duration(intensity: float, outcome: String, recovery_multiplier: float = 1.0, perf_mod: float = 1.0, agility: int = 100, glancing_severity: float = -1.0) -> float:
	var commitment: float = intensity
	var extra: float = CombatConstants.RECOVERY_EXTRA_HIT_S
	if outcome == "deflected":
		extra = CombatConstants.RECOVERY_EXTRA_DEFLECTED_BASE_S + CombatConstants.RECOVERY_DEFLECT_MOMENTUM_SCALE_S * commitment
	elif outcome == "negligible":
		extra = CombatConstants.RECOVERY_EXTRA_NEGLIGIBLE_CHIP_S
	elif outcome == "full_stop":
		extra = CombatConstants.RECOVERY_EXTRA_FULL_STOP_BASE_S + CombatConstants.RECOVERY_FULL_STOP_COMMITMENT_SCALE_S * commitment
	elif outcome == "glancing":
		var sev: float = clampf(glancing_severity, 0.0, 1.0) if glancing_severity >= 0.0 else 0.5
		extra = CombatConstants.RECOVERY_EXTRA_GLANCING_BASE_S + (1.0 - sev) * CombatConstants.RECOVERY_GLANCING_SEVERITY_SCALE_S * commitment
	elif outcome == "miss" or outcome == "dodge":
		# Commitment scales miss penalty: light stab whiff = short recovery; heavy overhead whiff = long (momentum carries you)
		extra = CombatConstants.RECOVERY_EXTRA_MISS_BASE_S + CombatConstants.RECOVERY_MISS_COMMITMENT_SCALE_S * commitment
	var base: float = (CombatConstants.RECOVERY_BASE_S + CombatConstants.RECOVERY_COMMITMENT_SCALE_S * commitment + extra) * maxf(0.5, recovery_multiplier)
	# Pain/consciousness: wounded entities recover slower
	if perf_mod > 0.0:
		base /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	# Agility: higher agility shortens recovery
	base /= clampf(float(agility) / 100.0, CombatConstants.RECOVERY_AGILITY_MIN, CombatConstants.RECOVERY_AGILITY_MAX)
	return base
