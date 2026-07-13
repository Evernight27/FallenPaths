class_name StrikePhysics
extends RefCounted

# Closing-speed tuning: docs/LIVE_PATHS.md#research-audit when stable.
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


## ctx: `tactical_ambush_mult`; optional `depth_polearm_attack` + `attack_type` + lane fields (align with
## **`DefenseChoiceResolver._depth_polearm_lane_is_open`**).
static func depth_polearm_thrust_closing_factor(ctx: Dictionary) -> float:
    if not ctx.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false):
        return 1.0
    var atk_type: String = str(ctx.get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
    if atk_type.is_empty():
        return 1.0
    var md: Dictionary = WeaponConstants.get_move(atk_type)
    if str(md.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)).to_lower() != WeaponConstants.ATTACK_TYPE_STAB:
        return 1.0
    var lane: String = str(ctx.get("depth_polearm_lane_type", "")).strip_edges()
    if lane == "over_shoulder":
        return 1.0
    if lane == "open":
        return CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT
    var allow_low: bool = ctx.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true)
    if not allow_low:
        return 1.0
    return CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT


## ctx: optional `tactical_ambush_mult`, `depth_polearm_attack`, `attack_type`, `depth_polearm_lane_type`,
## `depth_polearm_allows_low_targets`.
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
    mult *= depth_polearm_thrust_closing_factor(ctx)
    var amb: float = ctx.get("tactical_ambush_mult", 1.0)
    if amb > 1.001:
        mult *= lerpf(1.0, _AMBUSH_CAP, clampf((amb - 1.0) / maxf(0.001, _AMBUSH_DIV - 1.0), 0.0, 1.0))
    return clampf(mult, _CLOSING_MIN, _CLOSING_MAX)
