class_name EntityPainConsciousness
extends RefCounted

## Pain aggregation, consciousness, pain shock, and performance modifiers.
## Entity must have: wounds, body_max, species, consciousness, effective_consciousness,
## _consciousness_dirty, _pain_shock_until_time, _last_hit_impact, _ambient_pain_shock_accum, blood_volume,
## body_cutting,
## body_blunt, endurance, perception, agility; signals health_changed, creature_incapacitated.

const PASSIVE_PARRY_BASE_REACTION_S: float = 0.24

## Armor encumbrance on dodge speed — ~4% per kg above the baseline.
## Models historical HEMA reports of heavily armored fighters having reduced
## mobility: full plate adds ~17-18 kg in-sim, imposing a large step-time penalty.
## The baseline is set just above the mass of a full light (cloth/leather) kit
## (~3-4 kg) so that light armor is free to wear, mail is a modest cost, and
## plate is a real mobility tax. XCamp-4j: lowered from 25.0 (which no kit ever
## reached, so the mechanic was dormant) to 6.0 to match the intended behavior,
## and the mass-read guard in `_get_armor_encumbrance_modifier` was fixed from
## `has_method("armor_slots")` (always false — it is a property) to
## `"armor_slots" in entity`, so the mass loop actually runs.
const ENCUMBRANCE_BASELINE_MASS_KG: float = 6.0
const ENCUMBRANCE_PER_KG_STEP_MULT: float = 0.04  # 4% slower per extra kg of armor load

const CONCUSSION_LOC_CONSCIOUSNESS_FLOOR: float = 2.0  # below INCAPACITATION_CONSCIOUSNESS_THRESHOLD (5.0) => down

# Pain-concussion synergistic amplification (Gosselin et al., J Neurotrauma 2012).
## When both pain shock AND concussion are active, they amplify each other synergistically.
## Full formula: combined_reduction = concussive + pain_shock + (concussive * pain_shock * SYNERGY_FACTOR)
## E.g., 50% pain shock × 65% perception reduction → combined = 0.50 + 0.65 + (0.50*0.65*0.30) = 1.145 → capped at 1.0
## Result: only ~0-2% remaining function vs 15% without synergy — dramatic clinical effect.
const PAIN_CONCUSSION_SYNERGY_FACTOR: float = 0.30  # 30% additional impairment when both present (Gosselin et al.)
# --- Adrenaline-dump subdomain extracted to EntityAdrenaline (pure code-motion split). ---
# Thin delegates keep the original entry points (staying pain/consciousness code + CoreEntity tick).


static func _get_adrenaline_phase_info(entity: Node) -> Dictionary:
    return EntityAdrenaline._get_adrenaline_phase_info(entity)


static func try_enter_adrenaline_dump(entity: Node, severity_factor: float = 1.0) -> void:
    EntityAdrenaline.try_enter_adrenaline_dump(entity, severity_factor)


static func tick_adrenaline_dump(entity: Node) -> void:
    EntityAdrenaline.tick_adrenaline_dump(entity)


# --- Pain contribution (single wound; used for pain-shock from hit) ---


static func get_pain_contribution_for_wound(
    _entity: Node,
    part: String,
    damage: float,
    severity: String,
    injury_type: String,
    sub_region: String,
    is_stump: bool = false,
    penetration_to_tissue_mm: float = -1.0
) -> float:
    if damage <= 0.0:
        return 0.0
    var part_mult: float = PainConsciousnessConstants.get_body_part_pain_multiplier(part)
    var sev_mult: float = PainConsciousnessConstants.SEVERITY_PAIN_MULTIPLIERS.get(severity, 1.0)
    var itype_mult: float = PainConsciousnessConstants.get_injury_type_pain_multiplier(injury_type)
    var sub_mult: float = PainConsciousnessConstants.get_sub_region_pain_multiplier(part, sub_region)
    var stump_mult: float = PainConsciousnessConstants.get_stump_pain_multiplier(is_stump)
    var depth_mult: float = PainConsciousnessConstants.get_wound_depth_pain_multiplier(penetration_to_tissue_mm)
    return damage * sev_mult * part_mult * itype_mult * sub_mult * stump_mult * depth_mult


# --- Pain per part and total ---


static func get_pain_for_part(entity: Node, part: String) -> float:
    if not entity.wounds.has(part):
        return 0.0
    var total: float = 0.0
    var part_mult: float = PainConsciousnessConstants.get_body_part_pain_multiplier(part)
    for injury in entity.wounds[part]:
        var d: float = injury.get("cumulative_damage", injury.get("damage", 0.0))
        var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE)
        var sev_mult: float = PainConsciousnessConstants.SEVERITY_PAIN_MULTIPLIERS.get(sev, 1.0)
        var itype: String = injury.get("injury_type", "crush")
        var itype_mult: float = PainConsciousnessConstants.get_injury_type_pain_multiplier(itype)
        var sub: String = injury.get("sub_region", "")
        var sub_mult: float = PainConsciousnessConstants.get_sub_region_pain_multiplier(part, sub)
        var stump_mult: float = PainConsciousnessConstants.get_stump_pain_multiplier(injury.get("is_stump", false))
        var depth_mult: float = PainConsciousnessConstants.get_wound_depth_pain_multiplier(
            float(injury.get("penetration_to_tissue_mm", -1.0))
        )
        var progress: float = EntityWounds._get_wound_healing_progress(entity, injury)
        total += d * sev_mult * part_mult * itype_mult * sub_mult * stump_mult * depth_mult * (1.0 - progress)
    # Localized (stage 1) infection is painful (cellulitis: warmth, swelling, pain) — CAMP-INF-1.
    # Applied once per part if any wound on it is in the localized stage.
    var localized_infection: bool = false
    for injury in entity.wounds[part]:
        var st: int = int(injury.get("infection_stage", 0))
        if st < 1 and injury.get("is_infected", false):
            st = 1
        if st == 1:
            localized_infection = true
            break
    if localized_infection:
        total *= BleedingConstants.INFECTION_LOCALIZED_PAIN_MULT
    if entity.has_method("_get_campaign_pain_mult"):
        total *= float(entity._get_campaign_pain_mult())
    return total


static func get_total_pain(entity: Node) -> float:
    if entity == null:
        return 0.0
    var total: float = 0.0
    for part in entity.wounds:
        total += get_pain_for_part(entity, part)
    return total


static func get_pain_reference(entity: Node) -> float:
    if entity == null or entity.species == null:
        return 6.0
    if entity.species.has_method("get_pain_reference"):
        var r: float = entity.species.get_pain_reference(entity.body_max)
        if r > 0.0:
            return r
    return 6.0


static func get_effective_pain_for_thresholds(entity: Node) -> float:
    var raw: float = get_total_pain(entity)
    if not PainConsciousnessConstants.USE_NORMALIZED_PAIN:
        return raw
    var ref: float = 6.0
    if entity.species != null and entity.species.has_method("get_pain_reference"):
        ref = entity.species.get_pain_reference(entity.body_max)
    if ref <= 0.0:
        ref = 6.0
    return raw / ref


static func _get_effective_pain_for_region(entity: Node, region: String) -> float:
    var raw: float = 0.0
    match region:
        "arms":
            raw = (
                get_pain_for_part(entity, BodyPartConstants.PART_RIGHT_ARM)
                + get_pain_for_part(entity, BodyPartConstants.PART_LEFT_ARM)
            )
        "legs":
            raw = (
                get_pain_for_part(entity, BodyPartConstants.PART_LEFT_LEG)
                + get_pain_for_part(entity, BodyPartConstants.PART_RIGHT_LEG)
            )
        BodyPartConstants.PART_CHEST:
            raw = get_pain_for_part(entity, BodyPartConstants.PART_CHEST)
        BodyPartConstants.PART_HEAD:
            raw = get_pain_for_part(entity, BodyPartConstants.PART_HEAD)
        _:
            return 0.0
    if not PainConsciousnessConstants.USE_NORMALIZED_PAIN:
        return raw
    return raw / get_pain_reference(entity)


# --- Blood -> consciousness modifier ---


static func get_blood_consciousness_modifier(entity: Node) -> float:
    var raw_bv: float = 100.0
    if "blood_volume" in entity:
        raw_bv = float(entity.blood_volume)
    var effective_remaining: float = clampf(raw_bv, 0.0, 100.0)
    if BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
        var rate_pct_per_s: float = BleedingConstants.blood_volume_loss_per_second(
            EntityWounds.get_total_bleeding_rate(entity)
        )
        effective_remaining = BleedingConstants.adjusted_remaining_for_consciousness(
            effective_remaining, rate_pct_per_s, _effective_endurance(entity)
        )
    return BleedingConstants.blood_consciousness_modifier_from_remaining(
        effective_remaining,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )


# --- Consciousness update and pain shock ---


static func mark_consciousness_dirty(entity: Node) -> void:
    entity._consciousness_dirty = true


static func try_enter_pain_shock_from_hit(entity: Node, pain_from_this_hit_raw: float) -> void:
    if entity._last_hit_impact <= 0.0 or pain_from_this_hit_raw <= 0.0:
        return
    var ref: float = get_pain_reference(entity)
    if ref <= 0.0:
        ref = 6.0
    var pain_value: float = pain_from_this_hit_raw / ref
    var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    shock_thresh += (
        (_effective_endurance(entity) - 100.0) * PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
    )
    if pain_value <= shock_thresh:
        return
    var risk: float = minf(
        1.0, (pain_value - shock_thresh) * PainConsciousnessConstants.get_pain_shock_risk_per_point()
    )
    var suscept: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(
        get_effective_pain_for_thresholds(entity)
    )
    risk = minf(1.0, risk * suscept)
    if randf() >= risk:
        return
    var now: float = CombatTiming.now_seconds()
    var duration: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(
        pain_value, entity._last_hit_impact
    )
    # Limb destruction trauma bonus: strikes to destroyed/damaged limbs cause amplified shock.
    ## Clinical basis: limb ischemia (crush syndrome), nerve avulsion, and bone splintering produce
    ## disproportionate pain relative to visible damage — damaged nerves fire continuously until severed.
    var limb_shock_mult: float = _limb_destruction_pain_multiplier(entity)
    duration *= limb_shock_mult
    entity._pain_shock_until_time = now + duration
    entity._last_hit_impact = 0.0
    # In tuning/batch mode, lock effective_consciousness at current value once pain shock is entered.
    ## This prevents CON from recovering mid-cycle when the shock timer expires between strikes,
    ## ensuring consciousness is non-monotonic within a single weapon-sweep cycle.
    if entity.has_meta("_tuning_pain_shock_locked"):
        entity.set_meta("_tuning_pain_shock_locked_value", entity.effective_consciousness)
    elif entity._pain_shock_until_time >= 0.0:
        # First pain shock in this tuning session — set the lock flag and capture value.
        entity.set_meta("_tuning_pain_shock_locked", true)
        entity.set_meta("_tuning_pain_shock_locked_value", entity.effective_consciousness)
    # Pain shock triggers adrenaline dump — acute trauma → catecholamine surge.
    var severity_factor: float = clampf(pain_value / 5.0, 0.3, 2.0)
    try_enter_adrenaline_dump(entity, severity_factor)


## Sustained high pain during combat (no new hit). Returns true when shock was entered this tick.
static func try_ambient_pain_shock_tick(entity: Node, delta: float) -> bool:
    if not CombatConstants.is_feature_ambient_pain_shock():
        return false
    if entity == null or delta <= 0.0:
        return false
    var now: float = CombatTiming.now_seconds()
    if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
        entity._ambient_pain_shock_accum = 0.0
        return false
    # Ambient cooldown: prevent repeated ambient shock re-entry within cooldown window.
    var last_ambient_shock: float = -1.0
    if entity.has_method("_get_last_ambient_pain_shock_time"):
        last_ambient_shock = float(entity.call("_get_last_ambient_pain_shock_time"))
    if (
        last_ambient_shock >= 0.0
        and (now - last_ambient_shock) < PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_COOLDOWN_S
    ):
        entity._ambient_pain_shock_accum = 0.0
        return false
    var pain_value: float = get_effective_pain_for_thresholds(entity)
    var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    shock_thresh += (
        (_effective_endurance(entity) - 100.0) * PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
    )
    if pain_value <= shock_thresh:
        entity._ambient_pain_shock_accum = 0.0
        return false
    entity._ambient_pain_shock_accum += delta
    if entity._ambient_pain_shock_accum < PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S:
        return false
    entity._ambient_pain_shock_accum = 0.0
    var risk: float = PainConsciousnessConstants.PAIN_SHOCK_RISK_PER_POINT_NORMALIZED * (pain_value - shock_thresh)
    var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
    if BloodVolumeMl.entity_uses_ml(entity):
        risk *= PainConsciousnessConstants.PAIN_SHOCK_SUSCEPTIBILITY_MULT_HIGH if blood_pct < 85.0 else 1.0
    else:
        risk *= PainConsciousnessConstants.get_pain_shock_susceptibility_mult(blood_pct) if blood_pct < 85.0 else 1.0
    risk = minf(1.0, risk)
    if randf() >= risk:
        return false
    var duration: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain_value, 0.0)
    entity._pain_shock_until_time = now + duration
    if entity.has_method("_set_last_ambient_pain_shock_time"):
        entity.call("_set_last_ambient_pain_shock_time", now)
    # Sustained pain also triggers adrenaline dump (lower severity than acute hit).
    var ambient_severity: float = clampf(pain_value / 8.0, 0.2, 1.5)
    try_enter_adrenaline_dump(entity, ambient_severity)
    entity._last_ambient_pain_shock_time = now
    entity._consciousness_dirty = true
    var who: String = _session_entity_label(entity)
    if OperationalLog.play_session_is_editor_f5():
        CombatF5SoakTrace.note_ambient_pain_shock(who, pain_value, duration)
    else:
        CombatDebug.combat_session(
            "ambient_pain_shock %s effective_pain=%.1f duration=%.1fs" % [who, pain_value, duration]
        )
    return true


## Character node name when **`CombatBody`** is nested (F5 **ii6** grep `Companion`).
static func _session_entity_label(entity: Node) -> String:
    if entity == null:
        return "?"
    var parent: Node = entity.get_parent()
    if parent != null:
        var pn: String = str(parent.name).strip_edges()
        if not pn.is_empty():
            return pn
    return str(entity.name)


static func update_consciousness(entity: Node) -> void:
    # A dead creature is unconscious regardless of which vital part failed. Head destruction already
    # zeroes consciousness via the head-fraction term, but chest destruction leaves the head intact,
    # which previously left a corpse at consc~1 (critical-damage cap 15 x blood mod). Force 0 on death
    # so every KILL reports a fully unconscious victim.
    if entity.has_method("is_dead") and entity.is_dead():
        var dead_old: float = entity.consciousness
        entity.consciousness = 0.0
        entity.effective_consciousness = 0.0
        entity._consciousness_dirty = false
        if dead_old != 0.0:
            if entity.has_method("_notify_health_changed"):
                entity._notify_health_changed()
            elif entity.has_signal("health_changed"):
                entity.health_changed.emit()
        return
    var head_cut: float = entity.body_cutting.get(BodyPartConstants.PART_HEAD, 0.0)
    var head_blunt: float = entity.body_blunt.get(BodyPartConstants.PART_HEAD, 0.0)
    var head_max: int = entity.body_max.get(BodyPartConstants.PART_HEAD, 1)
    var head_total: float = float(head_cut + head_blunt)
    var head_max_total: float = float(head_max * 2)
    var base_consciousness: float = 100.0
    if head_max_total > 0.0:
        base_consciousness = 100.0 * (head_total / head_max_total)
    # Vital-part consciousness cap — two tiers:
    #   Destroyed (tissue=0): cap at 4.0 (below incapacitation floor of 5.0). The fighter collapses
    #   immediately; death follows after VITAL_DESTRUCTION_GRACE_PERIOD_S via is_dead().
    #   Critically damaged (tissue<30%): cap at 12.0. Severely impaired but still conscious — the
    #   fighter struggles to act (12% base performance) rather than instantly dropping. Matches
    #   clinical data where penetrating chest/abdominal trauma causes rapid deterioration but not
    #   instantaneous LOC unless brain perfusion is directly compromised.
    if entity.has_method("is_vital_part_destroyed") and entity.is_vital_part_destroyed():
        base_consciousness = minf(base_consciousness, 4.0)
    elif entity.has_method("is_vital_part_critically_damaged") and entity.is_vital_part_critically_damaged():
        base_consciousness = minf(base_consciousness, 12.0)
    var blood_mod: float = get_blood_consciousness_modifier(entity)
    var true_consciousness: float = base_consciousness * blood_mod
    # Pain-shock consciousness daze — acute pain crisis reduces effective consciousness by up to
    # PAIN_SHOCK_CONSCIOUSNESS_REDUCTION (−50%). Without adrenaline the full daze applies; during a
    # catecholamine surge the adrenaline's pain_suppression_mult dampens it (adrenaline masks pain).
    # At Class III+ hemorrhage, receptor desensitization progressively negates the adrenaline masking.
    var now_check: float = CombatTiming.now_seconds()
    # Transient concussion LOC: a strong head impact (rolled in _maybe_apply_concussion_loc) drops the
    # fighter to a consciousness floor below the incapacitation threshold for a brief window, so
    # is_unconscious() returns true and the fighter is down; value reverts to base×blood when it expires.
    if is_concussed(entity):
        var loc_until: float = float(entity.get_meta("_concussion_loc_until_time", 0.0))
        if now_check < loc_until:
            true_consciousness = minf(true_consciousness, CONCUSSION_LOC_CONSCIOUSNESS_FLOOR)
    var adrenaline_info: Dictionary = _get_adrenaline_phase_info(entity)
    var ad_pain_suppression: float = 1.0
    if entity._pain_shock_until_time >= 0.0 and now_check < entity._pain_shock_until_time:
        if adrenaline_info.get("phase", "none") != "none":
            ad_pain_suppression = adrenaline_info.get(
                "pain_suppression_mult", EntityAdrenaline.ADRENALINE_PAIN_SUPPRESSION
            )
    var old_consciousness: float = entity.consciousness
    var old_effective: float = entity.effective_consciousness
    entity.consciousness = true_consciousness
    if entity._pain_shock_until_time >= 0.0 and now_check < entity._pain_shock_until_time:
        entity.effective_consciousness = (
            true_consciousness
            * (1.0 - PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0 * ad_pain_suppression)
        )
    elif entity.has_meta("_tuning_pain_shock_locked"):
        ## Tuning/batch mode: once pain shock is entered during a cycle, it remains locked at the
        ## lowest effective_consciousness reached. Prevents CON from recovering mid-cycle when shock
        ## expires between strikes (which would make CON non-monotonic within a single weapon-sweep cycle).
        var locked_val: float = entity.get_meta("_tuning_pain_shock_locked_value", -1.0)
        if locked_val < 0.0:
            entity.effective_consciousness = true_consciousness
            entity.remove_meta("_tuning_pain_shock_locked")
        else:
            entity.effective_consciousness = locked_val
    else:
        entity._pain_shock_until_time = -1.0
        entity.effective_consciousness = true_consciousness
    entity._consciousness_dirty = false
    if old_consciousness != entity.consciousness or old_effective != entity.effective_consciousness:
        if entity.has_method("_notify_health_changed"):
            entity._notify_health_changed()
        elif entity.has_signal("health_changed"):
            entity.health_changed.emit()
    if true_consciousness < PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
        if entity.has_method("_notify_creature_incapacitated"):
            entity._notify_creature_incapacitated()
        elif entity.has_signal("creature_incapacitated"):
            entity.creature_incapacitated.emit()


# --- Performance modifiers ---


static func get_performance_modifier(entity: Node) -> float:
    var pain: float = get_effective_pain_for_thresholds(entity)
    var cons: float = get_effective_consciousness(entity)
    var base_mod: float = PainConsciousnessConstants.get_combined_performance_modifier(pain, cons)
    if "blood_volume" in entity:
        var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
        if blood_pct < 85.0:
            # Progressive hypovolemic impairment — models the continuum from early compensatory
            # vasoconstriction through decompensation (ATLS Class I-IV). Pre-Class-I (70-85%)
            # applies a smooth performance ramp, while Class II+ uses stepped penalties.
            ## Clinical basis: even at Class I (<15% blood loss), sympathetic activation causes
            ## anxiety, tachycardia, and ~5-12% reduction in fine motor control (ATLS 10th ed.).
            var blood_penalty: float
            match BleedingConstants.atls_hemorrhage_class_from_remaining_pct(blood_pct):
                1:  # Class I (85-100% range, but capped at 85 below) — smooth ramp from 1.0 to Class II floor
                    blood_penalty = lerpf(1.0, 0.92, (85.0 - blood_pct) / 15.0)
                2:  # Class II (70-85% remaining): anxious but functional; fine motor degrades
                    blood_penalty = lerpf(0.92, 0.85, (85.0 - blood_pct) / 15.0)
                3:  # Class III (60-70%): confused/lethargic, significant motor degradation
                    blood_penalty = lerpf(0.85, 0.62, (70.0 - blood_pct) / 10.0)
                4:  # Class IV (<60%): near-coma, barely coherent; gross motor only
                    blood_penalty = lerpf(0.62, 0.25, clampf((60.0 - blood_pct) / 20.0, 0.0, 1.0))
                _:
                    blood_penalty = 1.0
            base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, blood_penalty)
    # Progressive hypovolemic cognitive impairment — cerebral hypoperfusion degrades attention,
    ## decision-making, and working memory before gross motor symptoms appear. At Class I (85-70%),
    ## sympathetic surge causes anxiety-driven tunnel vision (-3-6% cognition); at Class II+ this
    ## compounds with reduced CBF (~12-18%/sec per 10% blood loss). Separate from performance mod
    ## because cognitive effects dominate early hemorrhage while motor function is preserved.
    var hypovolemic_cognitive_mod: float = 1.0
    if "blood_volume" in entity:
        var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
        if blood_pct < 85.0:
            var hypovolemia_severity: float = (85.0 - blood_pct) / 85.0  # 0 at 85%, 1 at 0%
            # Cognitive degradation ramps faster than performance early on — clinical data shows
            ## attentional deficits appear before motor impairment in hypovolemic patients (ATLS).
            hypovolemic_cognitive_mod = lerpf(1.0, 0.82, clampf(hypovolemia_severity * 1.5, 0.0, 1.0))
    base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, hypovolemic_cognitive_mod)
    # Phase-based concussion effects (perception, balance, visual tracking) with pain-concussion synergy.
    var conc_info: Dictionary = get_concussion_phase_info(entity)
    var conc_perception_mult: float = conc_info.get("perception_mult", 1.0)
    var conc_balance_mult: float = conc_info.get("balance_mult", 1.0)
    var conc_visual_mult: float = conc_info.get("visual_tracking_mult", 1.0)
    var spatial_ms_add: float = conc_info.get("spatial_judgment_ms_add", 0.0)
    var conc_reduction: float = 1.0 - conc_perception_mult
    var pain_shock_reduction: float = 0.0
    var now_check: float = CombatTiming.now_seconds()
    if entity._pain_shock_until_time >= 0.0 and now_check < entity._pain_shock_until_time:
        if PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION > 0.0:
            pain_shock_reduction = PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0
    # Apply perception modifier from concussion phase.
    base_mod *= conc_perception_mult
    # Sepsis confusion (CAMP-INF-1): a septic member thinks slower (CNS/altered mental status).
    # Gated on the entity-level is_septic state; a playable, recoverable combat tell.
    if entity.has_method("_get_sepsis_stamina_mult") or "is_septic" in entity:
        if bool(entity.get("is_septic")):
            base_mod *= BleedingConstants.SEPSIS_COMBAT_PERCEPTION_MULT
    # Tetanus (plan §10.2): tetanospasmin rigidity impairs aim/handling. Gated on the entity-level
    # is_tetanus state; a playable, recoverable combat tell.
    if "is_tetanus" in entity:
        if bool(entity.get("is_tetanus")):
            base_mod *= BleedingConstants.TETANUS_PERCEPTION_MULT
    # Scarred head (CAMP-SCAR-1 §9.5): chronic perception penalty from a healed head scar
    # (the residue of an acute head injury). Gated on the per-part scar penalty.
    if entity.has_method("_get_scar_part_penalty"):
        base_mod *= float(entity._get_scar_part_penalty(BodyPartConstants.PART_HEAD).get("perception", 1.0))
    # Pain-concussion synergistic amplification (Gosselin et al., J Neurotrauma 2012).
    ## When both pain shock AND concussion are active, they amplify each other synergistically.
    ## Interaction term = pain_shock_reduction * concussive_reduction * SYNERGY_FACTOR
    ## Applied as additional multiplicative penalty on top of individual effects.
    var synergy_mult: float = 1.0
    if pain_shock_reduction > 0.0 and conc_reduction > 0.0:
        var interaction: float = pain_shock_reduction * conc_reduction * PAIN_CONCUSSION_SYNERGY_FACTOR
        synergy_mult = maxf(1.0 - interaction, 0.0)
    base_mod *= synergy_mult
    # NOTE: the pain-shock performance cost is applied ONCE, through the effective_consciousness
    # daze in _update_consciousness (which flows into get_combined_performance_modifier via `cons`).
    # A second multiplicative `(1 - pain_shock_reduction)` here would double-count the same acute
    # impairment. The synergy cross-term above is a DISTINCT pain+TBI interaction (Gosselin 2012),
    # not a second copy of the pain-shock effect, so it is retained.
    # Apply balance impairment (affects movement/dodge).
    base_mod *= conc_balance_mult
    # Apply visual tracking impairment (affects hit chance/parry timing).
    base_mod *= conc_visual_mult
    # SIS catastrophic KO/stun — entity is incapacitated for 30-120s during disorientation period.
    var sis_ko_until: float = 0.0
    if entity.has_meta("_sis_ko_until_time"):
        sis_ko_until = float(entity.get_meta("_sis_ko_until_time", 0.0))
    if sis_ko_until > CombatTiming.now_seconds():
        return PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER
    # Apply spatial judgment impairment — misjudged distance/timing degrades combat accuracy.
    # Baseline parry window ~240ms; onset 500ms spatial error ≈ 68% penalty at critical phase.
    if is_concussed(entity):
        var base_reaction_ms: float = PASSIVE_PARRY_BASE_REACTION_S * 1000.0  # ~240ms baseline parry window
        var spatial_penalty: float = 1.0 - clampf(spatial_ms_add / (spatial_ms_add + base_reaction_ms), 0.0, 0.85)
        base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, spatial_penalty)
    # Apply persistent concussion fatigue — cumulative brain impairment from repeated sub-threshold concussions.
    var persistent_fatigue: float = get_persistent_concussion_fatigue(entity)
    if persistent_fatigue > 0.0:
        base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, 1.0 - persistent_fatigue * 0.5)
    # Adrenaline dump phase modulation — single sustained state with fine motor penalty and pain suppression.
    var adrenaline_info: Dictionary = _get_adrenaline_phase_info(entity)
    if adrenaline_info.get("phase", "none") != "none":
        var ad_mult: float = adrenaline_info.get("performance_mult", 1.0)
        base_mod *= ad_mult
        # Fine motor degradation during surge — large-motor sympathetic activation impairs precision
        # tasks (aiming, parry timing). At Class III+ hemorrhage, receptor desensitization negates this
        # effect too (blood-aware constant from phase info).
        var fine_motor_penalty: float = adrenaline_info.get(
            "fine_motor_mult", EntityAdrenaline.ADRENALINE_FINE_MOTOR_PENALTY
        )
        base_mod *= fine_motor_penalty
    return base_mod


static func get_action_bar_performance_modifier(entity: Node) -> float:
    var base: float = get_performance_modifier(entity)
    # Chest pain already factored into total pain via get_performance_modifier; do not double-count.
    return base


static func get_hit_chance_performance_modifier(entity: Node) -> float:
    var base: float = get_performance_modifier(entity)
    # Head pain already factored into total pain via get_performance_modifier; do not double-count.
    return base


static func get_parry_capacity_modifier(entity: Node) -> float:
    var perf: float = get_performance_modifier(entity)
    # Arms carry the weapon into parry position — arm pain directly degrades parry capacity.
    var right_arm_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        _get_effective_pain_for_region(entity, BodyPartConstants.PART_RIGHT_ARM)
    )
    var left_arm_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        _get_effective_pain_for_region(entity, BodyPartConstants.PART_LEFT_ARM)
    )
    var arm_pain_blend: float = (right_arm_pain_mod + left_arm_pain_mod) * 0.5
    # Concussion balance impairment affects parry timing — vestibular disruption makes precise blade
    # movement unreliable.
    var conc_info: Dictionary = get_concussion_phase_info(entity)
    var conc_balance_mult: float = conc_info.get("balance_mult", 1.0)
    # Concussion spatial judgment adds reaction delay proportional to parry capacity loss.
    var spatial_ms_add: float = conc_info.get("spatial_judgment_ms_add", 0.0)
    var spatial_penalty: float = 1.0
    if is_concussed(entity):
        var base_reaction_ms: float = PASSIVE_PARRY_BASE_REACTION_S * 1000.0
        spatial_penalty = maxf(
            PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER,
            1.0 - clampf(spatial_ms_add / (spatial_ms_add + base_reaction_ms), 0.0, 0.85)
        )
    return maxf(
        PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, perf * arm_pain_blend * conc_balance_mult * spatial_penalty
    )


static func get_dodge_speed_modifier(entity: Node) -> float:
    var perf: float = get_performance_modifier(entity)
    # Leg pain directly degrades dodge speed and reaction.
    var leg_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
        _get_effective_pain_for_region(entity, "legs")
    )
    # Concussion balance impairment severely affects dodge — vestibular disruption makes movement unreliable.
    var conc_info: Dictionary = get_concussion_phase_info(entity)
    var conc_balance_mult: float = conc_info.get("balance_mult", 1.0)
    # Armor encumbrance reduces movement speed — heavier armor slows step time and lateral displacement.
    var encumbrance_mult: float = _get_armor_encumbrance_modifier(entity)
    return maxf(
        PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, perf * leg_pain_mod * conc_balance_mult * encumbrance_mult
    )


static func _get_armor_encumbrance_modifier(entity: Node) -> float:
    var total_armor_kg: float = 0.0
    if "armor_slots" in entity and entity.armor_slots is Dictionary:
        for slot_value in entity.armor_slots.values():
            if slot_value != null and slot_value.has_method("get_total_mass_kg"):
                total_armor_kg += slot_value.get_total_mass_kg()
    var excess_kg: float = maxf(0.0, total_armor_kg - ENCUMBRANCE_BASELINE_MASS_KG)
    # 4% step time increase per kg above baseline → dodge speed scales inversely.
    return clampf(1.0 - (excess_kg * ENCUMBRANCE_PER_KG_STEP_MULT), 0.2, 1.0)


static func get_cumulative_pain_degradation(entity: Node) -> float:
    var total_pain: float = 0.0
    var part_count: int = 0
    for part in BodyPartConstants.BODY_PARTS:
        if entity.has_method("_get_effective_pain_for_region"):
            var region_pain: float = _get_effective_pain_for_region(entity, part)
            total_pain += region_pain
            part_count += 1
        elif "body_cutting" in entity and "body_max" in entity:
            total_pain += clampf(float(entity.body_cutting.get(part, 0.0)), 0.0, float(entity.body_max.get(part, 10)))
            part_count += 1
    var avg_pain: float = total_pain / maxf(part_count, 1)
    # Cumulative pain degradation — sustained multi-region pain causes progressive cognitive decline.
    # At 50% average pain across all body parts, ~15% performance degradation beyond individual pain effects.
    return clampf(avg_pain / 100.0, 0.0, 1.0)


static func get_limb_crippling_modifier(entity: Node, limb_part: String) -> float:
    if not BodyPartQuery.is_limb(limb_part):
        return 1.0
    var operability: float = BodyPartQuery.get_part_operability(entity, limb_part)
    if operability >= BodyPartQuery.PART_OPERABILITY_THRESHOLD:
        # Not yet crippled — fully functional.
        return 1.0
    # Partial damage below operability threshold but above destroyed: crippling penalty scales from 0 to full.
    var tissue_factor: float = (
        BodyPartQuery.get_arm_tissue_factor(entity, limb_part)
        if BodyPartQuery.is_arm(limb_part)
        else BodyPartQuery.get_bone_functionality_factor(entity, limb_part)
    )
    var bone_factor: float = BodyPartQuery.get_bone_functionality_factor(entity, limb_part)
    return clampf(tissue_factor * bone_factor, 0.0, 1.0)


static func get_cumulative_limb_penalty(entity: Node) -> float:
    # Blend all limb penalties — losing one arm is worse than two minor leg injuries due to weapon handling priority.
    var right_arm_mod: float = 1.0
    var left_arm_mod: float = 1.0
    if entity.has_method("_get_vital_parts"):
        right_arm_mod = get_limb_crippling_modifier(entity, BodyPartConstants.PART_RIGHT_ARM)
        left_arm_mod = get_limb_crippling_modifier(entity, BodyPartConstants.PART_LEFT_ARM)
    var arm_penalty: float = (1.0 - right_arm_mod + 1.0 - left_arm_mod) * 0.6  # Arms weighted higher for combat
    var leg_penalty: float = 0.0
    for leg in [BodyPartConstants.PART_RIGHT_LEG, BodyPartConstants.PART_LEFT_LEG]:
        leg_penalty += 1.0 - get_limb_crippling_modifier(entity, leg)
    leg_penalty *= 0.25  # Legs affect movement/dodge but less than arms for combat
    return clampf(arm_penalty + leg_penalty, 0.0, 1.0)


## Graduated limb impairment: returns {parry_mult, dodge_mult} based on per-limb damage severity.
## Arm wounds degrade parry/weapon handling; leg wounds degrade dodge/movement. Applies before pain/consciousness.
static func get_limb_impairment_multiplier(entity: Node) -> Dictionary:
    var right_arm_mod: float = 1.0
    var left_arm_mod: float = 1.0
    if entity.has_method("_get_vital_parts"):
        right_arm_mod = get_limb_crippling_modifier(entity, BodyPartConstants.PART_RIGHT_ARM)
        left_arm_mod = get_limb_crippling_modifier(entity, BodyPartConstants.PART_LEFT_ARM)
    var arm_penalty: float = (1.0 - right_arm_mod + 1.0 - left_arm_mod) * 0.6
    var parry_mult: float = maxf(0.5, 1.0 - arm_penalty * 0.5)
    var leg_penalty: float = 0.0
    for leg in [BodyPartConstants.PART_RIGHT_LEG, BodyPartConstants.PART_LEFT_LEG]:
        leg_penalty += 1.0 - get_limb_crippling_modifier(entity, leg)
    leg_penalty *= 0.25
    var dodge_mult: float = maxf(0.5, 1.0 - leg_penalty * 0.5)
    return {"parry_mult": parry_mult, "dodge_mult": dodge_mult}


# get_effective_consciousness: ensure current then return (used by get_performance_modifier and callers)
static func get_effective_consciousness(entity: Node) -> float:
    if entity._consciousness_dirty:
        update_consciousness(entity)
    return entity.effective_consciousness


static func _effective_perception(entity: Node) -> float:
    return EntityStatsUtil.get_effective_stat(entity, "perception")


static func _effective_agility(entity: Node) -> float:
    return EntityStatsUtil.get_effective_stat(entity, "agility")


static func _effective_endurance(entity: Node) -> float:
    return EntityStatsUtil.get_effective_stat(entity, "endurance")


## Concussion / SIS methods now live in **EntityConcussion** (pure code-motion split).
## The thin delegates below keep every existing call site (internal + external) unchanged.


static func try_enter_concussion_from_head_bone_damage(entity: Node, bone_damage_ratio: float) -> void:
    EntityConcussion.try_enter_concussion_from_head_bone_damage(entity, bone_damage_ratio)


static func _maybe_apply_concussion_loc(
    entity: Node, current_time: float, transmitted_ratio: float, severity: float
) -> void:
    EntityConcussion._maybe_apply_concussion_loc(entity, current_time, transmitted_ratio, severity)


static func head_rotational_accel_rad_s2(
    ke_head_transmitted_j: float,
    i_head_kg_m2: float = EntityConcussion.HEAD_MOMENT_OF_INERTIA_KG_M2,
    impact_duration_s: float = EntityConcussion.HEAD_IMPACT_DURATION_S
) -> float:
    return EntityConcussion.head_rotational_accel_rad_s2(ke_head_transmitted_j, i_head_kg_m2, impact_duration_s)


static func rotational_alpha_thresholds_for_fracture_anchor(fracture_anchor_j: float) -> Array:
    return EntityConcussion.rotational_alpha_thresholds_for_fracture_anchor(fracture_anchor_j)


static func try_enter_concussion_from_rotation(
    entity: Node,
    rotational_accel_rad_s2: float,
    mild_alpha: float = EntityConcussion.CONCUSSION_ROTATIONAL_ACC_THRESHOLD_RAD_S2,
    severe_alpha: float = EntityConcussion.CONCUSSION_ROTATIONAL_ACC_SEVERE_RAD_S2
) -> void:
    EntityConcussion.try_enter_concussion_from_rotation(entity, rotational_accel_rad_s2, mild_alpha, severe_alpha)


static func is_concussed(entity: Node) -> bool:
    return EntityConcussion.is_concussed(entity)


static func get_concussion_phase_info(entity: Node) -> Dictionary:
    return EntityConcussion.get_concussion_phase_info(entity)


static func get_decision_quality_mult(entity: Node) -> float:
    return EntityConcussion.get_decision_quality_mult(entity)


static func _get_entity_overall_damage_ratio(entity: Node) -> float:
    return EntityConcussion._get_entity_overall_damage_ratio(entity)


static func _get_sis_severity_multiplier(seconds_since_onset: float, cumulative_count: int) -> float:
    return EntityConcussion._get_sis_severity_multiplier(seconds_since_onset, cumulative_count)


static func _calculate_total_recovery_duration(severity: float, cumulative_count: int, sis_multiplier: float) -> float:
    return EntityConcussion._calculate_total_recovery_duration(severity, cumulative_count, sis_multiplier)


static func check_and_apply_sis_catastrophic_outcome(entity: Node, sis_severity: float) -> bool:
    return EntityConcussion.check_and_apply_sis_catastrophic_outcome(entity, sis_severity)


static func get_sis_perm_stat_reduction(entity: Node) -> float:
    return EntityConcussion.get_sis_perm_stat_reduction(entity)


static func was_sis_catastrophic(entity: Node) -> bool:
    return EntityConcussion.was_sis_catastrophic(entity)


static func get_persistent_concussion_fatigue(entity: Node) -> float:
    return EntityConcussion.get_persistent_concussion_fatigue(entity)


static func apply_attacker_windup_concussion_mult(_manager: Variant, attacker: Dictionary, wind_up_s: float) -> float:
    return EntityConcussion.apply_attacker_windup_concussion_mult(_manager, attacker, wind_up_s)


## Compute a pain shock duration multiplier based on limb destruction state of the entity.
## Destroyed limbs produce disproportionate trauma — damaged nerves fire continuously (phantom limb pain,
## ischemic agony), and bone fragments cause additional internal damage. Clinical basis: Mangled Extremity
## Severity Score (MESS) shows that limb-threatening injuries produce shock responses 2-3x higher than
## equivalent soft-tissue wounds to trunk regions.
static func _limb_destruction_pain_multiplier(entity: Node) -> float:
    if not entity.has_method("_get_leg_functionality") or not entity.has_method("get_total_bleeding_rate"):
        return 1.0
    var limb_loss_factor: float = 0.0

    # Check arm functionality — destroyed arms cause grip trauma + nerve pain
    if entity.has_method("_get_bone_functionality_factor"):
        for arm_part in [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM]:
            var func_val: float = entity._get_bone_functionality_factor(arm_part)
            var tissue_factor: float = 1.0
            if entity.has_method("_round_tissue"):
                tissue_factor = BodyPartQuery.get_arm_tissue_factor(entity, arm_part)
            # Fully destroyed limb (tissue < threshold or not operable): major trauma bonus
            if not BodyPartQuery.is_part_physically_operable(entity, arm_part) or tissue_factor < 0.15:
                limb_loss_factor += 0.4
            elif func_val < 0.5:
                # Severely damaged but not destroyed: moderate trauma bonus
                limb_loss_factor += 0.2

    # Check leg functionality — destroyed legs cause balance trauma + ischemic pain
    var leg_func: float = entity._get_leg_functionality() if entity.has_method("_get_leg_functionality") else 1.0
    if leg_func < 0.5:
        limb_loss_factor += 0.3

    return 1.0 + limb_loss_factor
