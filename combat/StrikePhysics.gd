class_name StrikePhysics
extends RefCounted

# Closing-speed tuning (also documented in docs/PHYSICS_DAMAGE_AND_FLOW.md when stable).
# Conservative vs peak hand speed: geometry/reaction advantage, not a second full weapon multiplier.
const _CLOSING_FRONT := 1.0
const _CLOSING_FLANK := 1.025
const _CLOSING_REAR := 1.045
const _CLOSING_MIN := 0.92
const _CLOSING_MAX := 1.10
const _AMBUSH_CAP := 1.03
const _AMBUSH_DIV := 1.12

## Relative closing speed along the strike line (gameplay proxy): engagement geometry and
## light tactical pressure. Multiplies impact velocity before KE / momentum (see AttackResolver).


## ctx: optional keys from resolve path before pending_attack is cleared, e.g. tactical_ambush_mult.
static func closing_speed_multiplier(_manager: Node, _atk: Dictionary, tgt: Dictionary, ctx: Dictionary = {}) -> float:
	var mult: float = 1.0
	var ang: String = str(tgt.get("engagement_angle", "front"))
	match ang:
		"rear":
			mult = _CLOSING_REAR
		"flank":
			mult = _CLOSING_FLANK
		_:
			mult = _CLOSING_FRONT
	var amb: float = float(ctx.get("tactical_ambush_mult", 1.0))
	if amb > 1.001:
		mult *= lerpf(1.0, _AMBUSH_CAP, clampf((amb - 1.0) / maxf(0.001, _AMBUSH_DIV - 1.0), 0.0, 1.0))
	return clampf(mult, _CLOSING_MIN, _CLOSING_MAX)
