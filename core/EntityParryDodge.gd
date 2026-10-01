class_name EntityParryDodge
extends RefCounted

## Parry reaction timing and dodge chance. Depends on consciousness and pain.
## Pure code-motion split from EntityPainConsciousness (one module/pass).

## Windup/reaction time differential dodge model (replaces flat DODGE_CHANCE_AT_FULL_SPEED=0.12).
## Clinical neurophysiology: visual reaction ~150-250 ms, movement initiation +50-100 ms → total ~200-350 ms.
## Defender can dodge if attacker windup > defender's minimum reaction time (base MRT 370 ms; agility/perception
## reduce it up to ~30%, giving a best-case effective MRT of ~260 ms).
## Dodge probability = sigmoid((windup_s - MRT) / scale), where scale controls slope steepness.

const DODGE_MIN_REACTION_TIME_S: float = 0.37  # visual + motor response for untrained human (~370 ms)
const DODGE_WINDUP_DIFF_SCALE: float = 0.08  # sigmoid steepness — wider = smoother transition
const DODGE_AGI_PERCEPTION_SENSITIVITY: float = 0.4  # agility+perception reduce effective MRT (max -30%)

# Physical step time constraint: the movement-execution time to laterally clear a blade path.
## This is distinct from the reaction time (DODGE_MIN_REACTION_TIME_S, the perceive-decide phase). A full dodge
## needs both in series; the step term is the physical displacement floor. Biomechanics: t = sqrt(2d/a) with
## d~0.4 m (clearance = shoulder half-width + blade margin) and a~4 m/s² sustained lateral accel (3-5 m/s² range
## gives 0.40-0.52 s). Set at the trained-fighter midpoint. (An earlier value, 0.28 s, sat below BOTH the reaction
## time and this physical floor — an unphysical "gameplay floor"; agency against fast attacks is instead carried by
## the reaction stat (MRT reduction) and DODGE_CHANCE_CEILING, which is the realistic source of evasion skill.)
const DODGE_MIN_STEP_TIME_S: float = 0.45  # trained-fighter lateral clear (sqrt(2*0.4/4) ~ 0.45 s)

## Dodge ceiling — caps the final dodge_chance to match historical HEMA data showing typical
## evasion rates of ~25-35% against trained opponents in close combat when windup exceeds MRT.
## Increased from 14%: real fighters use footwork, feints, and timing for meaningful evasion windows;
## near-0% dodge rate eliminates player agency and contradicts documented HEMA defensive drills.
const DODGE_CHANCE_CEILING: float = 0.35  # max dodge chance (veteran vs slow attack)


static func get_passive_parry_reaction_time(entity: Node) -> float:
    var perception_norm: float = clampf(EntityPainConsciousness._effective_perception(entity) / 100.0, 0.2, 1.5)
    var consciousness_norm: float = clampf(
        EntityPainConsciousness.get_effective_consciousness(entity) / 100.0, 0.1, 1.0
    )
    var head_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        EntityPainConsciousness._get_effective_pain_for_region(entity, BodyPartConstants.PART_HEAD)
    )
    var perception_factor: float = clampf(perception_norm * consciousness_norm * head_pain_mod, 0.15, 1.0)
    var base_reaction: float = EntityPainConsciousness.PASSIVE_PARRY_BASE_REACTION_S / perception_factor
    if EntityPainConsciousness.is_concussed(entity):
        var concussion_info: Dictionary = EntityPainConsciousness.get_concussion_phase_info(entity)
        var reaction_ms_add: float = concussion_info.get("reaction_time_ms_add", 0.0)
        base_reaction += reaction_ms_add / 1000.0
    # Progressive hypovolemic reaction-time impairment: cerebral hypoperfusion slows neuromuscular
    # response as blood volume drops (ATLS Class I-IV). Mirrors the hypovolemic cognitive mod in
    # get_performance_modifier — same 85% threshold and ramp shape — applied to the parry window.
    if "blood_volume" in entity:
        var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
        if blood_pct < 85.0:
            var hypovolemia_severity: float = (85.0 - blood_pct) / 85.0
            var reaction_slow: float = lerpf(
                1.0,
                PainConsciousnessConstants.HYPOVOLUME_REACTION_TIME_SLOW_MULT,
                clampf(hypovolemia_severity * 1.5, 0.0, 1.0)
            )
            base_reaction *= reaction_slow
    return base_reaction


static func get_dodge_chance(entity: Node) -> float:
    return get_dodge_chance_with_windup(entity, -1.0)


static func get_dodge_chance_with_windup(entity: Node, attacker_windup_override: float = -1.0) -> float:
    var leg: float = entity._get_leg_functionality() if entity.has_method("_get_leg_functionality") else 1.0
    var perf: float = EntityPainConsciousness.get_performance_modifier(entity)
    var leg_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        EntityPainConsciousness._get_effective_pain_for_region(entity, "legs")
    )
    ## Windup/reaction time differential model: dodge chance rises sigmoidally when attacker windup
    ## exceeds defender MRT.
    ## Agility + perception reduce effective MRT (better anticipation / faster neuromuscular response).
    var eff_agi_percep: float = (
        (EntityPainConsciousness._effective_agility(entity) + EntityPainConsciousness._effective_perception(entity))
        / 100.0
        * 0.5
    )
    var mrt_reduction: float = maxf(0.0, minf(eff_agi_percep * DODGE_AGI_PERCEPTION_SENSITIVITY, 0.3))
    var effective_mrt: float = DODGE_MIN_REACTION_TIME_S * (1.0 - mrt_reduction)
    ## Get attacker windup from override or fall back to default moderate windup (~400 ms).
    var attack_windup_s: float = 0.4  # moderate HEMA strike windup when unknown
    if attacker_windup_override >= 0.0:
        attack_windup_s = attacker_windup_override

    ## Physical step time constraint: even with perfect reaction, human can only move clear of a path
    ## in minimum DODGE_MIN_STEP_TIME_S. If attacker windup < min_step_time, dodge is physically impossible
    ## regardless of perception/agility — the strike reaches target before body can displace laterally.
    ## This prevents "superhuman" dodges where reaction time alone allows evasion of fast attacks.
    var step_time: float = DODGE_MIN_STEP_TIME_S
    # Armor encumbrance increases effective step time — heavy armor slows lateral displacement.
    var encumbrance_mult: float = EntityPainConsciousness._get_armor_encumbrance_modifier(entity)
    step_time /= encumbrance_mult
    ## If attack completes faster than minimum step time, dodge chance drops but doesn't go to zero.
    var step_constraint: float = 1.0
    if attack_windup_s < step_time:
        # Gradual exponential falloff as windup shortens — at half min step time, dodge drops to ~37%.
        step_constraint = exp(-2.0 * (1.0 - attack_windup_s / step_time))

    var windup_diff: float = attack_windup_s - effective_mrt
    var raw_dodge_chance: float = 1.0 / (1.0 + exp(-windup_diff / DODGE_WINDUP_DIFF_SCALE))
    ## Apply step time constraint — physical displacement limits dodge possibility for fast attacks.
    return clampf(minf(raw_dodge_chance * leg * perf * leg_pain_mod * step_constraint, DODGE_CHANCE_CEILING), 0.0, 1.0)
