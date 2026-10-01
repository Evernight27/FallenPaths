class_name EntityConcussion
extends RefCounted

## Concussion / Second-Impact-Syndrome subdomain, extracted from **`EntityPainConsciousness`**.
## Pure functions over `entity: Node` (state carried on the entity via meta keys). Shared
## `_session_entity_label` helper stays on `EntityPainConsciousness` and is called by reference.

# --- Concussion constants (Issue 1: head trauma / concussion mechanics) ---
## Phase-based model per RESEARCH_concussion_mTBI_combat.md §6b. Phases use proportional weights
## from PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_* of total capped duration.
## Modifiers interpolate continuously between phase boundaries (see get_concussion_phase_info).
## Concussion trigger threshold: the transmitted-KE ratio (ke_reaching_skull / sub-region fracture anchor) that
## must be reached to trigger the concussion check. The trigger passes ke_blunt_bone (post soft-tissue-budget KE
## actually reaching the skull) over the sub-region fracture anchor (CombatDamageMechanism.blunt_fracture_j_anchor),
## so ratio 1.0 == the energy needed to FRACTURE the skull at that sub-region. Concussion (mTBI) onset is
## CLINICALLY BELOW skull fracture (diffuse axonal shearing precedes fracture), so MIN < 1.0: a strong blunt blow
## that reaches ~75% of fracture energy concusses without necessarily fracturing. Committed mace (~90J impact ->
## ~65J reaching a 80J scalp anchor = 0.81) and axe (~85J -> 0.75) clear it; sword cuts (~80J -> 0.69), dagger and
## spear thrusts do not — preserving the KO-weapon identity of blunt arms.
## NOTE: the old bone-pool ratio (allocated_bone / head_bone_max, threshold 1.2) was dead code — head bone
## allocation is capped at bone_max (8) so the ratio never exceeded 1.0 and the gate could never fire in combat.
# transmitted-KE ratio (reaching-KE / fracture anchor) to trigger concussion — mTBI onset sits below fracture energy
const CONCUSSION_BONE_THRESHOLD_MIN: float = 0.75

# 1.5x fracture energy = clearly skull-damaging => near-guaranteed severe concussion; keeps the severity lerp meaningful
# for the realistic 0.75-1.5 band
const CONCUSSION_BONE_THRESHOLD_MAX: float = 1.5

const CONCUSSION_DAMAGE_RATIO_FACTOR: float = 0.2  # damage ratio contribution weight (0-1)

# --- Transient LOC from strong head impact (concussion knockout) ---
## A head blow whose transmitted-KE ratio clears the mTBI-onset threshold can knock the fighter
## out cold for a brief window, on top of the lingering cognitive impairment of the recovery
## phases. Clinically ~10% of concussions cause LOC; here the probability scales with how far
## past onset the ratio sits (a committed mace ~0.81 has a meaningful KO chance; a sword cut
## ~0.69 does not), so the mace/axe keep their KO-weapon identity without every head tap K.O.
const CONCUSSION_LOC_TRIGGER_RATIO: float = 0.75  # same as concussion onset — below this, no LOC possible

const CONCUSSION_LOC_FULL_RATIO: float = 1.0  # at fracture energy the KO probability ramps to its cap region

const CONCUSSION_LOC_MIN_PROB: float = 0.10  # ~10% of concussions cause LOC (matches clinical incidence)

const CONCUSSION_LOC_MAX_PROB: float = 0.80  # cap for impacts well past fracture energy

const CONCUSSION_LOC_DUR_MIN_S: float = 3.0  # brief blackout for a just-over-threshold hit

const CONCUSSION_LOC_DUR_MAX_S: float = 18.0  # prolonged blackout for a maximal-severity hit

# Rotational acceleration concussion thresholds — Rowson/Duma Virginia Tech helmet tests (2011-2013).
## Linear acceleration alone is a poor TBI predictor; rotational acceleration causes diffuse axonal injury
## via shearing of white matter tracts. VT 5-star helmet test scale: ≥8 rad/s² mild TBI, ≥35 rad/s² severe.
## In-game angular velocity (rad/s) at head COM converted to acceleration via α = Δω/Δt where Δt ≈ 0.01s impact
## duration.
const CONCUSSION_ROTATIONAL_ACC_THRESHOLD_RAD_S2: float = 8.0  # mild TBI onset (VT 5-star scale)

const CONCUSSION_ROTATIONAL_ACC_SEVERE_RAD_S2: float = 35.0  # severe TBI / guaranteed concussion

# --- Head rotational-inertia mapping (transmitted head KE -> angular acceleration) ---
## Rowson/Duma: rotational acceleration, not linear, is the dominant TBI / diffuse-axonal-injury
## predictor. A weapon impact imparts angular velocity to the head; alpha = omega / dt. I_head and dt
## are STANDARD biomechanical values (head I about a transverse axis through CG ~0.004-0.006 kg.m^2 in
## finite-element head models; contact duration 0.005-0.02 s).
##
## NOTE: the in-game mild/severe onsets are NOT the raw VT rad/s^2 numbers above — those were never
## calibrated to this mapping. Instead, try_enter_concussion_from_rotation() is called with mild/severe
## alpha thresholds ANCHORED TO THE CALIBRATED FRACTURE-ENERGY REFERENCE
## (rotational_alpha_thresholds_for_fracture_anchor), so I_head / dt / share cancel out of the gate and
## the trigger reduces to "transmitted-head-KE >= 0.75x fracture energy", mirroring the linear channel's
## 0.75-1.5 band. The constants below only set the physically-meaningful alpha VALUE logged/used for the
## mTBI framing. See RESEARCH_concussion_mTBI_combat.md.
const HEAD_MOMENT_OF_INERTIA_KG_M2: float = 0.005  # head I about transverse axis through CG (standard FE head models)

const HEAD_IMPACT_DURATION_S: float = 0.01  # standard head-impact contact duration (0.005-0.02 s)

## Off-center share of transmitted head KE that drives head rotation vs. pure translation. A central
## strike is all translational; a temple/cheekbone strike is roughly 50/50. Used only for the logged
## alpha value; it cancels out of the fracture-anchored gate.
const HEAD_ROTATIONAL_KE_SHARE: float = 0.5

# Clinical phase durations for SIS re-impact window check only (not used as game-time boundaries).
## Phase boundary weights are in PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_*.
const CONCUSSION_CRITICAL_DURATION_S: float = 90.0

## Max total concussion duration for gameplay pacing — caps the computed recovery time.
## Clinical data says most adults resolve within ~14 days, but that maps to unrealistic downtime in-game.
## Capped at ~90 s (1.5 min) so the full phase progression (critical→acute→subacute→recovery) completes within a single
## combat encounter.
const CONCUSSION_MAX_TOTAL_DURATION_S: float = 90.0

## Severity-to-duration anchors: mild concussion gets shorter total recovery, severe gets up to MAX.
const CONCUSSION_MIN_TOTAL_DURATION_S: float = 25.0  # mild (low severity) — ~25 s

const SIS_CRITICAL_WINDOW_S: float = 300.0  # 5 minutes — research §6d critical tier boundary

const SIS_EARLY_WINDOW_S: float = 900.0  # 15 minutes — research §6d early tier boundary

const SIS_LATE_WINDOW_S: float = 7200.0  # 2 hours — research §6d late tier boundary

const SIS_SEVERITY_MULTIPLIER_CRITICAL: float = 4.5  # hit within first 5min — per research ×3-5x range

const SIS_SEVERITY_MULTIPLIER_EARLY: float = 2.5  # 5min - 15min — per research ×2-3x range

const SIS_SEVERITY_MULTIPLIER_LATE: float = 1.75  # 15min - 2hr — per research ×1.5-2x range

# Cumulative concussion tracking — each successive concussion in a session has increasing severity and longer recovery.
## Clinical basis (Giza & Hovda, J Neurotrauma 2014;元في Union 2015): repeated concussions within hours
## produce metabolically vulnerable brain tissue — energy crisis compounds with each hit. SIS research
## (§6d) shows re-impact within the vulnerability window multiplies severity ×3-5x. These bonuses model
## the sub-threshold cumulative effect: each prior concussion extends the metabolic vulnerability window
## and amplifies the next hit's severity. The 15%/20% rates are calibrated to produce 3 cumulative hits
## reaching ~SIS Early-tier severity (×2-3x), consistent with clinical observations that 3+ concussions
## within 24 hours significantly worsen outcomes.
const CONCUSSION_CUMULATIVE_SEVERITY_BONUS: float = 0.15  # +15% severity per prior concussion in same session

const CONCUSSION_CUMULATIVE_DURATION_BONUS: float = 0.20  # +20% duration per prior concussion

# Persistent concussion fatigue — cumulative brain impairment from repeated sub-threshold concussions.
## Each concussion adds a small persistent penalty (based on severity) that lingers after the phase-based effects
## resolve.
## Cap at 0.45 to prevent total incapacitation.
const CONCUSSION_PERSISTENT_FATIGUE_PER_HIT: float = 0.12  # max fatigue contribution per concussion hit

# --- Concussion methods (Issue 1) ---


static func try_enter_concussion_from_head_bone_damage(entity: Node, bone_damage_ratio: float) -> void:
    if not entity.has_method("_get_vital_parts"):
        return
    var vital_parts: Array = entity._get_vital_parts()
    if not "head" in vital_parts:
        return
    if bone_damage_ratio < CONCUSSION_BONE_THRESHOLD_MIN:
        return
    var current_time: float = _get_current_simulation_time(entity)
    var current_until: float = 0.0
    if entity.has_meta("_concussion_until_time"):
        current_until = float(entity.get_meta("_concussion_until_time", 0.0))
    # Cumulative concussion tracking — count prior concussions in this session for SIS and severity escalation.
    var cumulative_count: int = 0
    if entity.has_meta("_cumulative_concussion_count"):
        cumulative_count = int(entity.get_meta("_cumulative_concussion_count", 0))
    # Shared variables to avoid redeclaration across if/fallthrough paths (linter CONFUSABLE_LOCAL_DECLARATION).
    var sis_multiplier: float
    var cumulative_bonus: float
    var who: String
    # Calculate base severity from bone damage ratio (0-1 scale).
    var severity: float = (
        (bone_damage_ratio - CONCUSSION_BONE_THRESHOLD_MIN)
        / (CONCUSSION_BONE_THRESHOLD_MAX - CONCUSSION_BONE_THRESHOLD_MIN)
    )
    severity = clampf(severity, 0.0, 1.0)
    var entity_damage_ratio: float = _get_entity_overall_damage_ratio(entity)
    var weighted_severity: float = (
        severity * (1.0 - CONCUSSION_DAMAGE_RATIO_FACTOR) + entity_damage_ratio * CONCUSSION_DAMAGE_RATIO_FACTOR
    )
    weighted_severity = clampf(weighted_severity, 0.0, 1.0)
    if current_until > current_time:
        # Re-impact during existing concussion — apply phase-based severity escalation.
        var onset_from_meta: float = current_time  # fallback if not set (backward compat)
        if entity.has_meta("_concussion_onset_time"):
            onset_from_meta = float(entity.get_meta("_concussion_onset_time"))
        var time_since_initial: float = current_time - onset_from_meta
        sis_multiplier = _get_sis_severity_multiplier(time_since_initial, cumulative_count)
        cumulative_bonus = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
        var new_weighted_severity_raw: float = weighted_severity * sis_multiplier * cumulative_bonus
        check_and_apply_sis_catastrophic_outcome(entity, new_weighted_severity_raw)
        # A SIS catastrophic outcome above may have extended _concussion_until_time by a 1-12h
        # recovery window. Capture it so the re-impact timeline math below cannot clobber the
        # extension (a re-impact never shortens the concussion already in progress).
        var post_cata_until: float = float(entity.get_meta("_concussion_until_time", current_until))
        var new_weighted_severity: float = clampf(new_weighted_severity_raw, 0.0, 2.0)  # cap at double severity
        if time_since_initial < CONCUSSION_CRITICAL_DURATION_S and new_weighted_severity <= 0.5:
            # Mild re-impact during critical phase — extend with SIS consideration.
            # Even mild impacts add a minimum severity bump to prevent trivial taps from extending without effect.
            var min_severity_bump: float = 0.05  # at least +5% severity from any head trauma during concussion
            new_weighted_severity = maxf(new_weighted_severity, weighted_severity + min_severity_bump)
            var ext: float = lerp(
                CONCUSSION_MIN_TOTAL_DURATION_S * 0.25,
                CONCUSSION_MAX_TOTAL_DURATION_S * 0.3,
                bone_damage_ratio / CONCUSSION_BONE_THRESHOLD_MAX
            )
            entity.set_meta("_concussion_until_time", maxf(current_until + ext, post_cata_until))
        else:
            # Severe re-impact or later phase — calculate extended timeline with phases.
            var total_recover_s = _calculate_total_recovery_duration(
                new_weighted_severity, cumulative_count + 1, sis_multiplier
            )
            entity.set_meta("_concussion_until_time", maxf(current_time + total_recover_s, post_cata_until))
        entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
        entity.set_meta("_last_concussion_time", current_time)
        if cumulative_count == 0:
            entity.set_meta("_concussion_onset_time", current_time)  # only first impact sets onset for phase tracking
        # Accumulate persistent concussion fatigue from repeated sub-threshold impacts.
        var prior_fatigue: float = float(entity.get_meta("_concussion_persistent_fatigue", 0.0))
        var fatigue_bump: float = minf(bone_damage_ratio * CONCUSSION_PERSISTENT_FATIGUE_PER_HIT, 0.12)
        entity.set_meta("_concussion_persistent_fatigue", clampf(prior_fatigue + fatigue_bump, 0.0, 0.45))
        who = EntityPainConsciousness._session_entity_label(entity)
        if OperationalLog.play_session_is_editor_f5():
            CombatF5SoakTrace.note_concussion_entry(
                who, bone_damage_ratio, float(entity.get_meta("_concussion_until_time", 0.0)) - current_time
            )
        else:
            CombatDebug.combat_session(
                (
                    "concussion_reimpact %s bone_damage=%.2f cumulative=%d total_recovery=%.1fs"
                    % [
                        who,
                        bone_damage_ratio,
                        cumulative_count + 1,
                        float(entity.get_meta("_concussion_until_time", 0.0)) - current_time
                    ]
                )
            )
        _maybe_apply_concussion_loc(entity, current_time, bone_damage_ratio, new_weighted_severity)
        return
    # Initial concussion — set phase-based recovery timeline.
    ## First impact uses no SIS multiplier (SIS only applies to re-impacts during healing).
    sis_multiplier = 1.0  # first impact — not yet in SIS window
    cumulative_bonus = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
    var final_weighted_severity: float = weighted_severity * sis_multiplier * cumulative_bonus
    final_weighted_severity = clampf(final_weighted_severity, 0.0, 2.0)
    var total_recovery_s: float = _calculate_total_recovery_duration(
        final_weighted_severity, cumulative_count + 1, sis_multiplier
    )
    entity.set_meta("_concussion_until_time", current_time + total_recovery_s)
    entity.set_meta("_concussion_onset_time", current_time)
    entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
    entity.set_meta("_last_concussion_time", current_time)
    # Initial concussion also sets persistent fatigue baseline.
    var init_fatigue: float = minf(weighted_severity * CONCUSSION_PERSISTENT_FATIGUE_PER_HIT, 0.12)
    entity.set_meta("_concussion_persistent_fatigue", clampf(init_fatigue, 0.0, 0.45))
    who = EntityPainConsciousness._session_entity_label(entity)
    if OperationalLog.play_session_is_editor_f5():
        CombatF5SoakTrace.note_concussion_entry(who, bone_damage_ratio, total_recovery_s)
    else:
        CombatDebug.combat_session(
            (
                "concussion_entered %s bone_damage=%.2f cumulative=%d recovery=%.1fs"
                % [who, bone_damage_ratio, cumulative_count + 1, total_recovery_s]
            )
        )
    _maybe_apply_concussion_loc(entity, current_time, bone_damage_ratio, final_weighted_severity)


## Transient LOC (concussion knockout): a head blow whose transmitted-KE ratio clears the mTBI-onset
## threshold may knock the fighter out cold for a brief window, layered on top of the lingering
## recovery-phase impairment. Probability ramps with how far past onset the ratio sits (a committed
## mace ~0.81 has a real KO chance; a sword cut ~0.69, below onset, never does). Duration scales with
## the impact's severity. Uses a dedicated seeded RNG (like the torso internal-bleed roll) so the
## outcome is deterministic per (entity, time) and does NOT consume the global RNG sequence.


static func _maybe_apply_concussion_loc(
    entity: Node, current_time: float, transmitted_ratio: float, severity: float
) -> void:
    if transmitted_ratio < CONCUSSION_LOC_TRIGGER_RATIO:
        return
    var prob_t: float = clampf(
        (
            (transmitted_ratio - CONCUSSION_LOC_TRIGGER_RATIO)
            / maxf(CONCUSSION_LOC_FULL_RATIO - CONCUSSION_LOC_TRIGGER_RATIO, 0.001)
        ),
        0.0,
        1.0
    )
    var prob: float = lerpf(CONCUSSION_LOC_MIN_PROB, CONCUSSION_LOC_MAX_PROB, prob_t)
    var loc_seed: int = hash(
        "%s:concloc:%d" % [EntityPainConsciousness._session_entity_label(entity), int(current_time * 1000.0)]
    )
    var loc_rng := RandomNumberGenerator.new()
    loc_rng.seed = loc_seed
    if loc_rng.randf() >= prob:
        return
    var loc_dur: float = lerpf(CONCUSSION_LOC_DUR_MIN_S, CONCUSSION_LOC_DUR_MAX_S, clampf(severity, 0.0, 1.0))
    entity.set_meta("_concussion_loc_until_time", current_time + loc_dur)
    # Persistent flag so the weapon-sweep harness can count transient-KO events even after the
    # LOC window expires and consciousness recovers.
    entity.set_meta("_ever_concussion_loc", true)
    CombatDebug.combat_session(
        (
            "concussion_loc %s ratio=%.2f prob=%.2f dur=%.1fs"
            % [EntityPainConsciousness._session_entity_label(entity), transmitted_ratio, prob, loc_dur]
        )
    )


## Head angular acceleration (rad/s^2) imparted by a head impact carrying `ke_head_transmitted_j`
## of post-armor KE, assuming `HEAD_ROTATIONAL_KE_SHARE` of it manifests as head rotation.
## alpha = sqrt(2 * KE_rot / I_head) / dt. Monotonic in KE, so it is a valid proxy for "how hard the
## head spun" even though the absolute rad/s^2 value depends on I_head / dt / share.


static func head_rotational_accel_rad_s2(
    ke_head_transmitted_j: float,
    i_head_kg_m2: float = HEAD_MOMENT_OF_INERTIA_KG_M2,
    impact_duration_s: float = HEAD_IMPACT_DURATION_S
) -> float:
    if ke_head_transmitted_j <= 0.0:
        return 0.0
    var ke_rot: float = ke_head_transmitted_j * HEAD_ROTATIONAL_KE_SHARE
    var omega: float = sqrt(2.0 * ke_rot / maxf(i_head_kg_m2, 0.0001))
    return omega / maxf(impact_duration_s, 0.0001)


## Fracture-energy-anchored mild/severe alpha thresholds for the rotational channel. Mild onset at
## 0.75x fracture energy (matches CONCUSSION_BONE_THRESHOLD_MIN); severe at 1.5x fracture energy
## (matches CONCUSSION_BONE_THRESHOLD_MAX "clearly skull-damaging"). Because alpha is a monotonic
## function of transmitted KE, computing the thresholds with the same head_rotational_accel_rad_s2()
## mapping makes I_head / dt / share cancel out of the gate: the trigger reduces to
## transmitted-head-KE in the 0.75-1.5x fracture-energy band, the same band the linear channel uses.


static func rotational_alpha_thresholds_for_fracture_anchor(fracture_anchor_j: float) -> Array:
    return [
        head_rotational_accel_rad_s2(0.75 * fracture_anchor_j),
        head_rotational_accel_rad_s2(1.5 * fracture_anchor_j),
    ]


## Rotational acceleration concussion check — Rowson/Duma VT helmet test scale.
## Called from strike resolution when angular velocity data is available (blunt impacts, weapon swings).
## Rotational forces cause diffuse axonal injury via white matter tract shearing; more damaging than linear alone.
## `mild_alpha` / `severe_alpha` are the onset/severe thresholds in rad/s^2; defaults are the raw VT
## numbers, but the damage pipeline passes fracture-anchored values (see above).


static func try_enter_concussion_from_rotation(
    entity: Node,
    rotational_accel_rad_s2: float,
    mild_alpha: float = CONCUSSION_ROTATIONAL_ACC_THRESHOLD_RAD_S2,
    severe_alpha: float = CONCUSSION_ROTATIONAL_ACC_SEVERE_RAD_S2
) -> void:
    if not entity.has_method("_get_vital_parts"):
        return
    var vital_parts: Array = entity._get_vital_parts()
    if not "head" in vital_parts:
        return
    ## Check if already concussed (SIS window applies).
    var current_time: float = _get_current_simulation_time(entity)
    var current_until: float = 0.0
    if entity.has_meta("_concussion_until_time"):
        current_until = float(entity.get_meta("_concussion_until_time", 0.0))
    if rotational_accel_rad_s2 < mild_alpha:
        return
    ## Severity: lerp 0->1 between mild_alpha and severe_alpha, capped at 1.0 at/above severe.
    var severity: float
    if rotational_accel_rad_s2 >= severe_alpha:
        severity = 1.0
    else:
        severity = (rotational_accel_rad_s2 - mild_alpha) / (severe_alpha - mild_alpha)
    severity = clampf(severity, 0.0, 1.0)
    ## SIS re-impact check (same logic as linear path).
    var cumulative_count: int = 0
    if entity.has_meta("_cumulative_concussion_count"):
        cumulative_count = int(entity.get_meta("_cumulative_concussion_count", 0))
    var sis_multiplier: float
    if current_until > current_time:
        sis_multiplier = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
        var new_severity: float = severity * sis_multiplier
        # SIS catastrophic gate runs on the RAW (unclamped) severity, matching the head-bone channel:
        # clamping to 2.0 first made the >= 4.0 gate unreachable for a pure rotational re-impact, so a
        # rotational-only fighter could never take a SIS catastrophic outcome (stun / perm stat loss).
        check_and_apply_sis_catastrophic_outcome(entity, new_severity)
        new_severity = clampf(new_severity, 0.0, 2.0)
        if current_until - current_time < CONCUSSION_CRITICAL_DURATION_S and new_severity <= 0.5:
            var ext: float = lerp(
                CONCUSSION_MIN_TOTAL_DURATION_S * 0.25, CONCUSSION_MAX_TOTAL_DURATION_S * 0.3, new_severity
            )
            entity.set_meta("_concussion_until_time", current_until + ext)
        else:
            var total_recover_s: float = _calculate_total_recovery_duration(
                new_severity, cumulative_count + 1, sis_multiplier
            )
            entity.set_meta("_concussion_until_time", current_time + total_recover_s)
        entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
        entity.set_meta("_last_concussion_time", current_time)
        CombatDebug.combat_session(
            (
                "concussion_rot_reimpact %s alpha=%.1f rad/s^2 sev=%.2f cumulative=%d"
                % [
                    EntityPainConsciousness._session_entity_label(entity),
                    rotational_accel_rad_s2,
                    new_severity,
                    cumulative_count + 1
                ]
            )
        )
        if OperationalLog.play_session_is_editor_f5():
            var who: String = EntityPainConsciousness._session_entity_label(entity)
            CombatF5SoakTrace.note_concussion_entry(
                who, severity, float(entity.get_meta("_concussion_until_time", 0.0)) - current_time
            )
        return
    ## Initial rotational concussion — set recovery timeline.
    var cumulative_bonus: float = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
    var final_severity: float = severity * cumulative_bonus
    final_severity = clampf(final_severity, 0.0, 2.0)
    var total_recovery_s: float = _calculate_total_recovery_duration(final_severity, cumulative_count + 1, 1.0)
    entity.set_meta("_concussion_until_time", current_time + total_recovery_s)
    entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
    entity.set_meta("_last_concussion_time", current_time)
    var init_fatigue: float = minf(severity * CONCUSSION_PERSISTENT_FATIGUE_PER_HIT, 0.12)
    entity.set_meta("_concussion_persistent_fatigue", clampf(init_fatigue, 0.0, 0.45))
    CombatDebug.combat_session(
        (
            "concussion_rot_entered %s alpha=%.1f rad/s^2 sev=%.2f recovery=%.1fs"
            % [
                EntityPainConsciousness._session_entity_label(entity),
                rotational_accel_rad_s2,
                final_severity,
                total_recovery_s
            ]
        )
    )
    if OperationalLog.play_session_is_editor_f5():
        var who: String = EntityPainConsciousness._session_entity_label(entity)
        CombatF5SoakTrace.note_concussion_entry(who, severity, total_recovery_s)


static func is_concussed(entity: Node) -> bool:
    if not is_instance_valid(entity) or not entity.is_inside_tree():
        return false
    var curr: float = _get_current_simulation_time(entity)
    var until: float = 0.0
    if entity.has_method("get_meta"):
        until = float(entity.get_meta("_concussion_until_time", 0.0))
    return until > curr


static func get_concussion_phase_info(entity: Node) -> Dictionary:
    """Returns phase info with smoothly interpolated modifiers across concussion recovery.

    Phase boundaries use proportional weights from PainConsciousnessConstants (Critical=15%, Acute=40%,
        Subacute=35%, Recovery=10%)
    of the total capped duration. Within each phase, modifiers interpolate linearly between the boundary values,
    mirroring the continuous clinical recovery curve rather than step-function jumps.

    Each modifiable field has two boundary values: at phase onset (start) and phase offset (end).
    The interpolation fraction is time_in_phase / phase_duration, clamped [0,1]."""
    if not is_concussed(entity):
        return {
            "phase": 0,
            "time_in_phase": 0.0,
            "perception_mult": 1.0,
            "reaction_time_ms_add": 0.0,
            "balance_mult": 1.0,
            "visual_tracking_mult": 1.0,
            "spatial_judgment_ms_add": 0.0,
            "decision_quality_mult": 1.0,
            "healing_mult": 1.0
        }
    var current_time: float = _get_current_simulation_time(entity)
    var until: float = 0.0
    if entity.has_method("get_meta"):
        until = float(entity.get_meta("_concussion_until_time", 0.0))
    var total_duration: float = maxf(until - current_time, 0.01)
    var onset_time: float = current_time
    if entity.has_meta("_concussion_onset_time"):
        onset_time = float(entity.get_meta("_concussion_onset_time"))
    var elapsed: float = minf(maxf(current_time - onset_time, 0.0), total_duration)

    # Phase boundary times (cumulative fractions of total duration).
    var critical_end: float = total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_CRITICAL
    var acute_end: float = critical_end + total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_ACUTE
    var subacute_end: float = acute_end + total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_SUBACUTE
    # Recovery extends to total_duration (the remainder is 10%).

    # Boundary values at each phase transition point.
    ## All fields use the "at onset" value as the starting point of a phase and "at offset" as the ending point.
    ## Interpolation: value = start + frac * (end - start), where frac = time_in_phase / phase_duration.

    var phase_id: int = 0
    var perception_mult: float
    var reaction_time_ms_add: float
    var balance_mult: float
    var visual_tracking_mult: float
    var spatial_judgment_ms_add: float
    var decision_quality_mult: float
    var healing_mult: float

    if elapsed < critical_end:
        # Phase: Critical (onset=0, offset=critical_end).
        phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL
        var phase_dur: float = maxf(critical_end, 0.01)
        var frac: float = clampf((elapsed - 0.0) / phase_dur, 0.0, 1.0)
        # Interpolate within critical phase (start=offset from prior phase or initial values, end=critical->acute
        # boundary).
        # clinical data: 0.25-0.40 at onset; slight improvement even within critical
        perception_mult = lerp(0.35, 0.42, frac)
        reaction_time_ms_add = lerp(150.0, 100.0, frac)  # research §6c: critical +100-150ms (complex reaction delay)
        balance_mult = lerp(0.50, 0.53, frac)
        visual_tracking_mult = lerp(0.30, 0.35, frac)
        spatial_judgment_ms_add = lerp(500.0, 300.0, frac)  # research §6c: critical +400-500ms (onset=top)
        decision_quality_mult = lerp(0.30, 0.38, frac)
        healing_mult = lerp(
            PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT,
            PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT,
            frac
        )
    elif elapsed < acute_end:
        # Phase: Acute (onset=critical_end, offset=acute_end).
        phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE
        var phase_dur: float = maxf(acute_end - critical_end, 0.01)
        var frac: float = clampf((elapsed - critical_end) / phase_dur, 0.0, 1.0)
        perception_mult = lerp(0.42, 0.60, frac)  # recovers from critical boundary to acute-end value
        # research §6c: acute +60-100ms; continuity from critical-end (100)
        reaction_time_ms_add = lerp(100.0, 40.0, frac)
        balance_mult = lerp(0.53, 0.70, frac)
        visual_tracking_mult = lerp(0.35, 0.55, frac)
        # research §6c: acute +200-300ms; continuity from critical-end (300)
        spatial_judgment_ms_add = lerp(300.0, 100.0, frac)
        decision_quality_mult = lerp(0.38, 0.60, frac)
        healing_mult = lerp(
            PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT,
            PainConsciousnessConstants.CONCUSSION_HEALING_ACUTE_MULT,
            frac
        )
    elif elapsed < subacute_end:
        # Phase: Subacute (onset=acute_end, offset=subacute_end).
        phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_SUBACUTE
        var phase_dur: float = maxf(subacute_end - acute_end, 0.01)
        var frac: float = clampf((elapsed - acute_end) / phase_dur, 0.0, 1.0)
        perception_mult = lerp(0.60, 0.85, frac)  # continuity from acute-end value of 0.60
        reaction_time_ms_add = lerp(40.0, 15.0, frac)  # research §6c: subacute +15-40ms; continuity from acute-end (40)
        balance_mult = lerp(0.70, 0.88, frac)  # continuity from acute-end value of 0.70
        visual_tracking_mult = lerp(0.55, 0.80, frac)  # continuity from acute-end value of 0.55
        # research §6c: subacute +50-100ms; continuity from acute-end (100)
        spatial_judgment_ms_add = lerp(100.0, 30.0, frac)
        decision_quality_mult = lerp(0.60, 0.88, frac)  # continuity from acute-end value of 0.60
        healing_mult = lerp(
            PainConsciousnessConstants.CONCUSSION_HEALING_ACUTE_MULT,
            PainConsciousnessConstants.CONCUSSION_HEALING_SUBACUTE_MULT,
            frac
        )
    else:
        # Phase: Recovery (onset=subacute_end, offset=total_duration).
        phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_RECOVERY
        var phase_dur: float = maxf(total_duration - subacute_end, 0.01)
        var frac: float = clampf((elapsed - subacute_end) / phase_dur, 0.0, 1.0)
        perception_mult = lerp(0.85, 1.0, frac)  # recovers to full baseline by end of recovery
        # research §6c: recovery +5-15ms; continuity from subacute-end (15)
        reaction_time_ms_add = lerp(15.0, 0.0, frac)
        balance_mult = lerp(0.88, 1.0, frac)
        visual_tracking_mult = lerp(0.80, 1.0, frac)
        # research §6c: recovery +10-30ms; continuity from subacute-end (30)
        spatial_judgment_ms_add = lerp(30.0, 0.0, frac)
        decision_quality_mult = lerp(0.88, 1.0, frac)
        healing_mult = lerp(
            PainConsciousnessConstants.CONCUSSION_HEALING_SUBACUTE_MULT,
            PainConsciousnessConstants.CONCUSSION_HEALING_RECOVERY_MULT,
            frac
        )

    var time_in_phase: float
    match phase_id:
        PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL:
            time_in_phase = elapsed
        PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE:
            time_in_phase = maxf(elapsed - critical_end, 0.0)
        PainConsciousnessConstants.CONCUSSION_PHASE_SUBACUTE:
            time_in_phase = maxf(elapsed - acute_end, 0.0)
        PainConsciousnessConstants.CONCUSSION_PHASE_RECOVERY:
            time_in_phase = maxf(elapsed - subacute_end, 0.0)

    return {
        "phase": phase_id,
        "time_in_phase": time_in_phase,
        "perception_mult": perception_mult,
        "reaction_time_ms_add": reaction_time_ms_add,
        "balance_mult": balance_mult,
        "visual_tracking_mult": visual_tracking_mult,
        "spatial_judgment_ms_add": spatial_judgment_ms_add,
        "decision_quality_mult": decision_quality_mult,
        "healing_mult": healing_mult
    }


static func _get_current_simulation_time(_entity: Node) -> float:
    # Use CombatTiming.now_seconds() — same clock as pain shock / ambient pain shock / consciousness updates.
    # The old tree.root.get_age() fallback always returned 0.0 because no scene node implements get_age().
    return CombatTiming.now_seconds()


static func get_decision_quality_mult(entity: Node) -> float:
    """Concussion-based decision quality degradation per research §6c.
    Returns a multiplier (0-1) that reduces AI decision quality during concussion phases."""
    if not is_concussed(entity):
        return 1.0
    var info: Dictionary = get_concussion_phase_info(entity)
    return info.get("decision_quality_mult", 1.0)


static func _get_entity_overall_damage_ratio(entity: Node) -> float:
    if not ("body_max" in entity) or not ("body_cutting" in entity) or not ("body_blunt" in entity):
        return 0.0
    var body_max: Dictionary = entity.body_max
    var body_cutting: Dictionary = entity.body_cutting
    var body_blunt: Dictionary = entity.body_blunt
    var total_remaining: float = 0.0
    var total_max: float = 0.0
    for part in body_max:
        var mx: float = body_max[part]
        # body_max is the per-channel tissue max (cutting + blunt each up to mx), matching update_consciousness.
        # body_cutting/body_blunt store REMAINING health, so damage = max - remaining (healthy -> 0, destroyed -> 1).
        total_max += mx * 2.0
        total_remaining += body_cutting.get(part, 0.0) + body_blunt.get(part, 0.0)
    if total_max > 0.0:
        return clampf(1.0 - (total_remaining / total_max), 0.0, 1.0)
    return 0.0


static func _get_sis_severity_multiplier(seconds_since_onset: float, cumulative_count: int) -> float:
    """Returns severity multiplier for Second Impact Syndrome based on time since initial concussion.
    Tiers per research §6d: Critical (0-5min, ×4.5), Early (5-15min, ×2.5), Late (15min-2hr, ×1.75).
    Cumulative concussions extend the vulnerable window by 30% per prior hit."""
    var late_window_extended: float = SIS_LATE_WINDOW_S * (1.0 + cumulative_count * 0.3)
    if seconds_since_onset < SIS_CRITICAL_WINDOW_S:
        return SIS_SEVERITY_MULTIPLIER_CRITICAL  # 0-5min
    if seconds_since_onset < SIS_EARLY_WINDOW_S:
        return SIS_SEVERITY_MULTIPLIER_EARLY  # 5-15min
    if seconds_since_onset < late_window_extended:
        return SIS_SEVERITY_MULTIPLIER_LATE  # 15min - extended late window (2hr + cumulative bonus)
    return 1.0  # past vulnerable window — no SIS multiplier


static func _calculate_total_recovery_duration(severity: float, cumulative_count: int, sis_multiplier: float) -> float:
    """Calculate total recovery time in seconds based on severity, prior concussions, and SIS status.
    Returns a capped duration proportional to clinical recovery curves, scaled for gameplay pacing."""
    var base_recovery: float = lerp(CONCUSSION_MIN_TOTAL_DURATION_S, CONCUSSION_MAX_TOTAL_DURATION_S, severity)
    base_recovery = minf(base_recovery, CONCUSSION_MAX_TOTAL_DURATION_S)
    var cumulative_duration_bonus: float = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_DURATION_BONUS
    var cumulative_total: float = base_recovery * cumulative_duration_bonus
    # SIS extends recovery up to 50% beyond the cap (models prolonged neurological disruption).
    var sis_extension: float = maxf(sis_multiplier - 1.0, 0.0) * cumulative_total * 0.5
    var total_with_sis: float = cumulative_total + sis_extension
    # Apply hard cap after SIS extension to prevent runaway durations in extreme cases.
    return minf(total_with_sis, CONCUSSION_MAX_TOTAL_DURATION_S * 1.5)


static func check_and_apply_sis_catastrophic_outcome(entity: Node, sis_severity: float) -> bool:
    """Check for Second Impact Syndrome catastrophic outcome per research §6d.
    Returns true if SIS catastrophic event occurred (KO state triggered).
    SIS catastrophic outcomes: immediate KO/stun, extended recovery days, permanent stat reduction (-5% to -15%).
    SIS is most likely when severity_multiplier >= 4.0 (critical tier) and second impact delivers significant trauma."""
    if not entity.has_method("_get_vital_parts"):
        return false
    var vital_parts: Array = entity._get_vital_parts()
    if "head" not in vital_parts:
        return false
    # SIS catastrophic threshold: critical tier (>=4.0x) with meaningful second-impact severity
    if sis_severity < 4.0:
        return false
    # Apply immediate stun/disorientation — entity is effectively KO'd for a period
    var sis_ko_duration_s: float = lerp(30.0, 120.0, (sis_severity - 4.0) / 3.0)  # 30-120s based on severity
    if entity.has_method("_apply_stun"):
        entity._apply_stun(sis_ko_duration_s, "second_impact_syndrome")
    elif entity.has_method("set_meta"):
        entity.set_meta("_sis_ko_until_time", _get_current_simulation_time(entity) + sis_ko_duration_s)
    # Apply extended recovery beyond normal concussion timeline (can be days in real-world mTBI)
    var existing_until: float = 0.0
    if entity.has_meta("_concussion_until_time"):
        existing_until = float(entity.get_meta("_concussion_until_time", 0.0))
    var sis_recovery_extension: float = lerp(3600.0, 43200.0, (sis_severity - 4.0) / 3.0)  # 1hr to 12hr extension
    if existing_until > _get_current_simulation_time(entity):
        entity.set_meta("_concussion_until_time", existing_until + sis_recovery_extension)
    else:
        entity.set_meta("_concussion_until_time", _get_current_simulation_time(entity) + sis_recovery_extension)
    # Apply permanent stat reduction (-5% to -15%) — reflects lasting TBI damage
    var perm_stat_reduction: float = lerp(0.05, 0.15, (sis_severity - 4.0) / 3.0)  # 5-15% reduction
    if entity.has_method("_apply_permanent_stat_reduction"):
        entity._apply_permanent_stat_reduction(perm_stat_reduction)
    elif entity.has_method("set_meta") and entity.has_meta("_sis_perm_stat_reduced"):
        var current_reduction: float = float(entity.get_meta("_sis_perm_stat_reduced", 0.0))
        entity.set_meta("_sis_perm_stat_reduced", minf(current_reduction + perm_stat_reduction, 0.30))  # cap at 30%
    elif entity.has_method("set_meta"):
        entity.set_meta("_sis_perm_stat_reduced", perm_stat_reduction)
    # Accumulate persistent concussion fatigue spike from SIS — represents lasting brain trauma beyond normal recovery.
    var prior_fatigue_sis: float = float(entity.get_meta("_concussion_persistent_fatigue", 0.0))
    entity.set_meta("_concussion_persistent_fatigue", clampf(prior_fatigue_sis + 0.25, 0.0, 0.45))
    # Flag that SIS catastrophic event occurred (for UI display / medical treatment)
    if entity.has_method("set_meta"):
        entity.set_meta("_sis_catastrophic_flag", true)
        return true
    return false


static func get_sis_perm_stat_reduction(entity: Node) -> float:
    """Returns permanent stat reduction fraction from prior SIS catastrophic events."""
    if entity.has_meta("_sis_perm_stat_reduced"):
        return clampf(float(entity.get_meta("_sis_perm_stat_reduced", 0.0)), 0.0, 0.30)
    return 0.0


static func was_sis_catastrophic(entity: Node) -> bool:
    """Returns true if entity has suffered a SIS catastrophic outcome."""
    if entity.has_meta("_sis_catastrophic_flag"):
        return bool(entity.get_meta("_sis_catastrophic_flag", false))
    return false


static func get_persistent_concussion_fatigue(entity: Node) -> float:
    """Returns accumulated persistent concussion fatigue from repeated sub-threshold concussions (0-1 scale).
    This represents cumulative brain fatigue that lingers after individual concussions resolve,
    affecting performance until cleared by rest/recuperation between sessions."""
    if entity.has_meta("_concussion_persistent_fatigue"):
        return clampf(float(entity.get_meta("_concussion_persistent_fatigue", 0.0)), 0.0, 1.0)
    return 0.0


static func apply_attacker_windup_concussion_mult(_manager: Variant, attacker: Dictionary, wind_up_s: float) -> float:
    """Concussion-based windup extension for attackers per research — impaired motor planning increases initiation time.
    Windup penalty is inversely related to decision_quality_mult and interpolated continuously across phases."""
    var entity_node = CombatantEntityAccess.scene_node(attacker)
    if entity_node == null or not is_concussed(entity_node):
        return wind_up_s
    var info = get_concussion_phase_info(entity_node)
    var dq = info.get("decision_quality_mult", 1.0)
    # decision_quality goes 0.30(critical) -> 1.0(recovery); windup penalty goes +30% -> +5%.
    # Map: windup_mult = 1.0 + lerp(0.30, 0.05, 1.0 - dq) where dq in [0.30, 1.0]
    var normalized_dq = clampf((dq - 0.30) / 0.70, 0.0, 1.0)  # normalize to [0,1] over clinical range
    return wind_up_s * lerp(1.30, 1.05, normalized_dq)
