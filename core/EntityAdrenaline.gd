class_name EntityAdrenaline
extends RefCounted

# --- Adrenaline dump timing (HIGH #5 from biomechanics audit) ---
## Simplified clinical model: adrenaline dump is a single sustained combat state (~60-120s), not phased.
## Clinical data shows catecholamine surge sustains for 60-90s during acute stress, then gradually returns to baseline.
## Fine motor degradation (-30% precision) occurs during surge due to large-motor sympathetic activation.
## Pain suppression (-50% pain perception) allows continued fighting despite injury.
## Cooldown between dumps: 120s minimum — prevents repeated adrenaline dumping from trivial trauma.

# --- Probabilistic trigger (clinical catecholamine kinetics) ---
## Real-world catecholamine surge onset is NOT deterministic at a single blood-volume threshold.
## Baroreceptor-mediated epinephrine/norepinephrine release begins in Class II hemorrhage (15-30% loss,
## 70-85% remaining) but varies by individual factors: training level, stress tolerance, age, fitness.
## Clinical data shows sympathetic activation starts gradually in the upper Class II range, with most entities
## triggering between 60-75% (Class II/III boundary). We model this as a probability ramp:
##   - >82% remaining: no trigger (Class I — minimal stress response)
##   - 82-70% remaining: probability ramps from 0 to 1 (Class II → Class III transition; per-entity jitter shifts
##     the 82% upper bound by ±5%)
##   - 70-60% remaining: deterministic trigger + cooldown check (Class III — catecholamine crisis)
##   - <60% remaining: no new dump (Class IV — decompensated shock, baroreceptor failure; see MIN_ABS floor)
## Per-entity jitter: each entity gets a unique threshold offset (-5% to +5%) via seeded random,
## so not all entities dump simultaneously when crossing the same blood-volume boundary.

const ADRENALINE_DURATION_MIN_S: float = 60.0  # minimum post-control decay duration (acute stress response)
const ADRENALINE_DURATION_MAX_S: float = 120.0  # max post-control decay before return to baseline
const ADRENALINE_SUSTAIN_ARM_S: float = 60.0  # re-arm window while bleeding keeps the surge sustained
const ADRENALINE_FINE_MOTOR_PENALTY: float = 0.70  # -30% fine motor precision during surge (epinephrine effect)
const ADRENALINE_PAIN_SUPPRESSION: float = 0.50  # -50% pain perception during surge

## Upper boundary of probability ramp — above this, no dump possible (Class I hemorrhage).
## Shifted from 75% to 82% to match clinical Class II onset (70-85% remaining blood).
const ADRENALINE_TRIGGER_RAMP_MAX_REMAINING: float = 82.0
## Lower boundary of probability ramp — below this, dump is deterministic if cooldown allows.
## Shifted from 60% to 70% to trigger at Class III boundary (60-70% remaining).
const ADRENALINE_TRIGGER_RAMP_MIN_REMAINING: float = 70.0

## Minimum blood volume to trigger (absolute floor) — prevents dumps at near-death (Class IV <60%).
## Below this threshold, the patient is in decompensated shock and catecholamine response collapses;
## baroreceptor failure means epinephrine release cannot sustain. Matches ATLS Class III→IV boundary
## (`BleedingConstants.ATLS_CLASS_III_MIN_REMAINING` = 60% remaining; Class IV begins below it).
const ADRENALINE_TRIGGER_MIN_ABS_REMAINING: float = BleedingConstants.ATLS_CLASS_III_MIN_REMAINING

const ADRENALINE_COOLDOWN_S: float = 120.0  # minimum cooldown between adrenaline dumps (2 min)
const ADRENALINE_PERFORMANCE_BASELINE_MULT: float = 1.05  # +5% gross motor performance during sustained surge

# --- Adrenaline-blood interaction (HIGH #6 from hemorrhage audit) ---
## At Class III+ hemorrhage (>30% blood loss), sympathetic response overwhelms — adrenaline benefits are
## progressively negated.
## Clinical basis: catecholamine levels are sky-high in shock, but peripheral vasoconstriction + tissue hypoxia prevent
## beta-adrenergic receptors from responding (downregulation / receptor desensitization). Patient appears
## "wired but collapsing."
const ADRENALINE_NEUTRALIZATION_ATLS_CLASS_III_MIN: int = 3  # start negating at Class III (<=70% remaining blood)
const ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE: float = 0.5  # fraction of performance lost per class above threshold
const ADRENALINE_PAIN_NEUTRALIZATION_ATLS_CLASS_III_MIN: int = 3  # pain suppression also negated at Class III+


static func _get_adrenaline_phase_info(entity: Node) -> Dictionary:
    var result: Dictionary = {"phase": "none", "performance_mult": 1.0, "time_remaining_s": 0.0}
    if not entity.has_method("_get_adrenaline_dump_until_time"):
        return result
    var until: float = entity._get_adrenaline_dump_until_time()
    if until <= 0.0:
        return result
    var now: float = entity._get_game_time_seconds()
    if now >= until:
        entity._set_adrenaline_dump_until_time(-1.0)
        entity._set_adrenaline_phase("")
        return result
    result["phase"] = "surge"  # Simplified: single sustained state, no crash phase
    result["time_remaining_s"] = until - now
    # Single sustained performance effect: +5% gross motor during surge (not phased boost/crash)
    var ad_performance_mult: float = ADRENALINE_PERFORMANCE_BASELINE_MULT
    var ad_pain_suppression_mult: float = ADRENALINE_PAIN_SUPPRESSION
    var fine_motor_mult: float = ADRENALINE_FINE_MOTOR_PENALTY
    # Adrenaline-blood interaction: at Class III+ hemorrhage, progressively negate adrenaline benefits.
    if "blood_volume" in entity:
        var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
        var remaining_pct: float = blood_pct
        var atls_class: int = BleedingConstants.atls_hemorrhage_class_from_remaining_pct(remaining_pct)
        if atls_class >= ADRENALINE_NEUTRALIZATION_ATLS_CLASS_III_MIN:
            var classes_above: float = atls_class - ADRENALINE_NEUTRALIZATION_ATLS_CLASS_III_MIN + 1.0
            var performance_neutralization: float = minf(
                classes_above * ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE, 1.0
            )
            # Neutralization removes the adrenaline bonus (the +5% gross motor gain above baseline).
            # At worst returns 1.0 (baseline, no boost), never a penalty — blood loss negates benefits but doesn't
            # add penalties on top.
            var adrenaline_bonus: float = ADRENALINE_PERFORMANCE_BASELINE_MULT - 1.0  # = 0.05
            ad_performance_mult = 1.0 + adrenaline_bonus * (1.0 - performance_neutralization)
            if atls_class >= ADRENALINE_PAIN_NEUTRALIZATION_ATLS_CLASS_III_MIN:
                # Pain neutralization uses the same classes_above since both thresholds are identical (=3).
                var pain_neutralization: float = minf(classes_above * ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE, 1.0)
                ad_pain_suppression_mult = ADRENALINE_PAIN_SUPPRESSION * (1.0 - pain_neutralization)
            # Fine motor mult affected by blood loss — at Class III+, receptor desensitization reduces the -30%
            # fine motor penalty.
            var fm_neutralization: float = minf(classes_above * ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE, 1.0)
            fine_motor_mult = lerp(ADRENALINE_FINE_MOTOR_PENALTY, 1.0, fm_neutralization)
    result["performance_mult"] = ad_performance_mult
    result["pain_suppression_mult"] = ad_pain_suppression_mult
    result["fine_motor_mult"] = maxf(fine_motor_mult, 0.3)
    return result


static func _set_adrenaline_cooldown(entity: Node, current_time: float) -> void:
    """Sets adrenaline cooldown timer after a dump is triggered."""
    if entity.has_method("_set_adrenaline_cooldown_until"):
        entity._set_adrenaline_cooldown_until(current_time + ADRENALINE_COOLDOWN_S)


static func try_enter_adrenaline_dump(entity: Node, severity_factor: float = 1.0) -> void:
    var now: float = entity._get_game_time_seconds()
    var bleeding: bool = _is_actively_bleeding(entity)
    # Sustained sympathetic arousal under active hemorrhage. A bleeding fighter is under a PERSISTENT
    # stressor, so an in-progress surge is EXTENDED rather than allowed to fade and re-trigger on a
    # refractory cooldown ("on/off pulse" removed — see RESEARCH_adrenaline_hemorrhage.md §1b).
    if entity.has_method("_get_adrenaline_dump_until_time") and entity._get_adrenaline_dump_until_time() >= now:
        if bleeding:
            entity._set_adrenaline_dump_until_time(now + _compute_adrenaline_dump_duration(severity_factor))
            if entity.has_method("_get_adrenaline_phase") and entity._get_adrenaline_phase() != "surge":
                entity._set_adrenaline_phase("surge")
        return
    # Cooldown is a true neuro-refractory period for a NEW dump, but must not create a physiologic gap
    # while the fighter is still bleeding — an off-cycle under active hemorrhage is not clinically real.
    if not bleeding and entity.has_method("_get_adrenaline_cooldown_until"):
        var cooldown_until: float = entity._get_adrenaline_cooldown_until()
        if cooldown_until > 0.0 and now < cooldown_until:
            return  # Still in cooldown — no new dump allowed (only when not actively bleeding)
    # Blood-volume gate with probabilistic trigger. Adrenaline is a catecholamine surge triggered by
    # baroreceptor-mediated sympathetic activation during hemorrhage/acute stress (not deterministic at a
    # single threshold). Clinical kinetics:
    # Class I (<15% loss): minimal response — no dump expected.
    # Class II (15-30% loss, 70-85% remaining): baroreceptor detection → epinephrine/norepinephrine release begins;
    #   onset varies by individual training/stress tolerance. Modeled as probability ramp from ~75% down to ~60%.
    # Class III (30-40% loss, 60-70% remaining): catecholamine surge peaks — deterministic trigger while bleeding;
    #   while actively bleeding the surge sustains (no refractory off-cycle — see
    #   RESEARCH_adrenaline_hemorrhage.md §1b).
    # Class IV (>40% loss, <60% remaining): decompensated shock — baroreceptor failure means sympathetic response
    #   collapses; no new dumps below absolute floor (patient is in crisis mode).
    var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0) if "blood_volume" in entity else 100.0
    if blood_pct > ADRENALINE_TRIGGER_RAMP_MAX_REMAINING:
        return  # Class I — no sympathetic surge expected
    if blood_pct < ADRENALINE_TRIGGER_MIN_ABS_REMAINING:
        return  # Below absolute floor — decompensated shock, baroreceptor failure
    # Compute per-entity threshold jitter for inter-individual variability (-5% to +5%).
    # Uses entity name hash as pseudo-seed so the same entity always has the same threshold within a session.
    # (name is a built-in Node property, always present — no guard needed.)
    var jitter_seed: int = hash(entity.name)
    var orig_rand := RandomNumberGenerator.new()
    orig_rand.seed = jitter_seed
    var threshold_jitter: float = orig_rand.randf_range(-5.0, 5.0)
    var effective_trigger_threshold: float = ADRENALINE_TRIGGER_RAMP_MAX_REMAINING + threshold_jitter
    if blood_pct > effective_trigger_threshold:
        return  # Above this entity's individualized upper bound — no dump
    # Compute probability within the ramp zone (linear interpolation).
    var trigger_prob: float
    if blood_pct <= ADRENALINE_TRIGGER_RAMP_MIN_REMAINING:
        trigger_prob = 1.0  # Deterministic below ramp minimum (Class III crisis)
    elif blood_pct >= effective_trigger_threshold:
        trigger_prob = 0.0  # Above individualized upper bound
    else:
        # Linear probability ramp from 0 to 1 across the active zone.
        trigger_prob = clampf(
            (
                (effective_trigger_threshold - blood_pct)
                / (effective_trigger_threshold - ADRENALINE_TRIGGER_RAMP_MIN_REMAINING)
            ),
            0.0,
            1.0
        )
    # Probabilistic check — roll for adrenaline dump with computed probability.
    if randf() >= trigger_prob:
        return  # Roll failed — no dump this tick (will re-evaluate on next hit/tick)
    # Single sustained duration — no surge/plateau/crash phases per clinical data. This duration governs
    # post-control decay to baseline; while bleeding, tick_adrenaline_dump keeps it armed (sustained).
    var duration: float = _compute_adrenaline_dump_duration(severity_factor)
    entity._set_adrenaline_dump_until_time(entity._get_game_time_seconds() + duration)
    entity._set_adrenaline_phase("surge")  # Simplified: always "surge" — single sustained state
    # Record the neuro-refractory cooldown for NEW dumps (only enforced when not actively bleeding).
    _set_adrenaline_cooldown(entity, entity._get_game_time_seconds())
    var effective_trigger_pct: float = ADRENALINE_TRIGGER_RAMP_MAX_REMAINING + threshold_jitter
    var severity: float = severity_factor
    CombatDebug.combat_session(
        (
            (
                "%s adrenaline_dump STARTED blood=%.1f%% prob=%.2f jitter=%.1f eff_threshold=%.1f"
                + " severity=%.2f duration=%.1fs (cooldown=%.0fs)"
            )
            % [
                entity.name,
                blood_pct,
                trigger_prob,
                threshold_jitter,
                effective_trigger_pct,
                severity,
                duration,
                ADRENALINE_COOLDOWN_S
            ]
        )
    )


static func tick_adrenaline_dump(entity: Node) -> void:
    if entity.has_method("_get_adrenaline_dump_until_time") and entity._get_adrenaline_dump_until_time() <= 0.0:
        return
    var now: float = entity._get_game_time_seconds()
    # Sustained sympathetic arousal: while the fighter is ACTIVELY bleeding, the hemorrhage is a persistent
    # stressor — the surge does NOT return to baseline mid-bleed. Keep it armed until bleeding is controlled.
    # (See RESEARCH_adrenaline_hemorrhage.md §1b.) Expiry only applies once the stressor (bleeding) resolves.
    if _is_actively_bleeding(entity):
        if entity.has_method("_get_adrenaline_dump_until_time") and now >= entity._get_adrenaline_dump_until_time():
            entity._set_adrenaline_dump_until_time(now + ADRENALINE_SUSTAIN_ARM_S)
        if entity.has_method("_get_adrenaline_phase") and entity._get_adrenaline_phase() != "surge":
            entity._set_adrenaline_phase("surge")
        return
    # Not bleeding anymore: stressor resolved → surge decays to baseline on its timer (norepinephrine clearance).
    if entity.has_method("_get_adrenaline_dump_until_time") and now >= entity._get_adrenaline_dump_until_time():
        entity._set_adrenaline_dump_until_time(-1.0)
        entity._set_adrenaline_phase("")
        return
    if entity.has_method("_get_adrenaline_phase") and entity._get_adrenaline_phase() != "surge":
        entity._set_adrenaline_phase("surge")


## True while the entity is still losing blood — the persistent stressor that keeps sympathetic arousal up.
static func _is_actively_bleeding(entity: Node) -> bool:
    if entity.has_method("_get_total_bleeding_rate"):
        return entity._get_total_bleeding_rate() > BleedingConstants.BLEEDING_RATE_EPSILON
    if entity.has_method("get_total_bleeding_rate"):
        return float(entity.call("get_total_bleeding_rate")) > BleedingConstants.BLEEDING_RATE_EPSILON
    return false


## Randomized surge duration (also used to re-arm the sustained dump while bleeding); clamp keeps a sane window.
## Clinical: catecholamine surge sustains 60-90s before returning to baseline (RESEARCH_adrenaline_hemorrhage.md §2a).
## Floor at MIN_S (60s) — a dump below the clinical surge window is physiologically inaccurate.
static func _compute_adrenaline_dump_duration(severity_factor: float) -> float:
    var duration: float = randf_range(ADRENALINE_DURATION_MIN_S, ADRENALINE_DURATION_MAX_S) * severity_factor
    return clampf(duration, ADRENALINE_DURATION_MIN_S, ADRENALINE_DURATION_MAX_S * 1.5)
