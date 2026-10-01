class_name BleedingMath
extends RefCounted

## Bleeding / infection / hemorrhage **computation** functions, extracted from **`BleedingConstants`**.
## Pure math over `injury: Dictionary` / `entity: Node` / scalars. All tuning values stay in
## `BleedingConstants` and are referenced here by `class_name` (mutual refs, no `preload`).


static func infection_freshness_factor(age_days: float) -> float:
    return lerpf(
        1.0,
        BleedingConstants.WOUND_INFECTION_FRESHNESS_FLOOR,
        clampf(age_days / BleedingConstants.INFECTION_FRESH_WINDOW_DAYS, 0.0, 1.0)
    )


## Gas gangrene (Phase A+; gated on is_gas_gangrene wound flag, armed at the stage-1->2 flip).


## Draw a fresh tetanus incubation period (days) in [MIN, MAX] using the global RNG (the same
## source as the rest of the day-scale code). Called once per seeded spore load.
static func tetanus_arm_days() -> float:
    return lerp(BleedingConstants.TETANUS_INCUBATION_MIN_DAYS, BleedingConstants.TETANUS_INCUBATION_MAX_DAYS, randf())


## Osteomyelitis (Phase A+): chronic bone infection from an infected compound fracture.
## While the flag is present the part's bone-heal rate is multiplied by this (halves closure).


## True when a wound is auto-contaminated by depth (cut/stab penetrating to the "full" band).
## A traumatic amputation stump is a raw, devitalized, open wound (unknown depth) and is always
## treated as contaminated: it seeds the tetanus spore load (plan §10.2) and takes the full
## BleedingConstants.WOUND_INFECTION_CONTAMINATED_MULT infection-dose boost — the historical stump-infection risk.
static func is_wound_contaminated(injury: Dictionary) -> bool:
    if bool(injury.get("is_stump", false)):
        return true
    # Debridement (plan §10.2 counter-play): a wound cleaned of devitalized tissue + debris by a
    # successful dressing is no longer contaminated — the depth-qualified contamination is removed,
    # so the BleedingConstants.WOUND_INFECTION_CONTAMINATED_MULT dose boost stops. A stump is excluded above (a raw
    # amputation surface stays the historical infection/tetanus risk even once cleaned).
    if bool(injury.get("debrided", false)):
        return false
    var itype: String = str(injury.get("injury_type", ""))
    if itype != BleedingConstants.INJURY_TYPE_CUT and itype != BleedingConstants.INJURY_TYPE_STAB:
        return false
    var pen: float = float(injury.get("penetration_to_tissue_mm", -1.0))
    return pen >= BleedingConstants.CONTAMINATION_PENETRATION_MM


## True when a wound has an open entry portal that can seed infection. Sepsis needs a tract: a closed
## contusion (bruise) and a clean (non-compound) fracture have no portal for colonization — the tissue
## is intact or the damage is internally contained — so their per-day infection dose must be zero.
## compound_fracture is open (exposed bone); cut/stab/crush breach tissue; internal_bleed keeps the
## pass-4 boundary. This mirrors the open-wound gate the scar mint uses (CAMP-SCAR-1 §2.3): a closed
## injury neither gets infected nor remodels into scar tissue. Legacy descriptors ("" — pre-stash-era
## saves) keep the old dose rule.


static func injury_has_open_entry(injury: Dictionary) -> bool:
    if bool(injury.get("is_stump", false)):
        return true
    if bool(injury.get("is_compound_fracture", false)):
        return true
    var itype: String = str(injury.get("injury_type", ""))
    return (
        itype.is_empty()
        or (itype != BleedingConstants.INJURY_TYPE_BRUISE and itype != BleedingConstants.INJURY_TYPE_FRACTURE)
    )


## Combined susceptibility multiplier (starvation × fatigue × concussion).
## entity must have: nutrition_level, campaign_fatigue; concussion via EntityPainConsciousness.


static func infection_susceptibility_mult(entity: Node) -> float:
    var mult: float = 1.0
    # Starvation: lerp 1.5 (starving) -> 1.0 (well-fed). nutrition_level is a CoreEntity property (default 1.0).
    var nutrition: float = 1.0
    if "nutrition_level" in entity:
        nutrition = clampf(float(entity.get("nutrition_level")), 0.0, 1.0)
    mult *= lerp(BleedingConstants.INFECTION_RISK_STARVATION_MULT, 1.0, nutrition)
    # Fatigue: lerp 1.0 -> 1.25. campaign_fatigue is a CoreEntity property (default 0.0).
    var fatigue: float = 0.0
    if "campaign_fatigue" in entity:
        fatigue = clampf(float(entity.get("campaign_fatigue")), 0.0, 1.0)
    mult *= lerp(1.0, BleedingConstants.INFECTION_RISK_FATIGUE_MAX_MULT, fatigue)
    # Concussion: acute phase (critical or acute)
    var conc_info: Dictionary = EntityPainConsciousness.get_concussion_phase_info(entity)
    var phase: int = int(conc_info.get("phase", 0))
    if (
        phase == PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL
        or phase == PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE
    ):
        mult *= BleedingConstants.INFECTION_RISK_CONCUSSION_MULT
    return mult


## Full per-day infection dose for one wound (base × contamination × susceptibility), capped.
## Replaces the direct `per_day * risk` pattern in EntityHealing when staging is enabled.


static func wound_infection_daily_dose(entity: Node, injury: Dictionary, treated: bool) -> float:
    var base: float = wound_infection_daily_risk(injury, treated)
    if is_wound_contaminated(injury):
        base *= BleedingConstants.WOUND_INFECTION_CONTAMINATED_MULT
    base *= infection_susceptibility_mult(entity)
    return minf(base, BleedingConstants.INFECTION_DAILY_DOSE_CAP)


## True when a stage-1 (localized) wound is a gas-gangrene candidate (clostridial myonecrosis: anaerobic,
## deep / devitalized / low-perfusion tissue). Crush and compound-fracture wounds are prime substrates
## (devitalized muscle / exposed bone); a raw amputation stump qualifies outright (devitalized + open,
## the historical leading cause of amputation mortality); deep penetrating cut/stab wounds qualify by
## depth; a part currently under a tourniquet (low perfusion) also qualifies. (plan §10.1)


static func is_gangrene_candidate(entity: Node, part: String, injury: Dictionary) -> bool:
    var itype: String = str(injury.get("injury_type", ""))
    if itype == BleedingConstants.INJURY_TYPE_CRUSH or itype == BleedingConstants.INJURY_TYPE_COMPOUND_FRACTURE:
        return true
    # A raw amputation stump is devitalized, crushed, open tissue — a prime clostridial substrate even
    # though its depth is unknown. Historically the leading cause of amputation mortality (plan §10.1).
    if bool(injury.get("is_stump", false)):
        return true
    if itype == BleedingConstants.INJURY_TYPE_CUT or itype == BleedingConstants.INJURY_TYPE_STAB:
        var pen: float = float(injury.get("penetration_to_tissue_mm", -1.0))
        if pen >= BleedingConstants.GAS_GANGRENE_DEEP_PENETRATION_MM:
            return true
    if entity != null and entity.tourniquet_applied.has(part):
        return true
    return false


## Per-stage-2 gas-gangrene arming roll: base risk scaled up by severity (worse wounds gangrene more).
## Never a certainty — returns a probability in (0, 1]. (plan §10.1: "a roll scaled by severity, not a certainty")


static func gangrene_candidate_roll(injury: Dictionary) -> float:
    var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE))
    var scale: float
    match sev:
        BleedingConstants.SEVERITY_MINOR:
            scale = 0.5
        BleedingConstants.SEVERITY_MODERATE:
            scale = 0.75
        BleedingConstants.SEVERITY_SEVERE:
            scale = 1.0
        BleedingConstants.SEVERITY_CRITICAL:
            scale = 1.25
        _:
            scale = 0.75
    return clampf(BleedingConstants.GAS_GANGRENE_CANDIDATE_BASE_RISK * scale, 0.0, 1.0)


# --- Active bleeding slows tissue/bone repair ---
## Hemorrhage diverts repair resources and impairs local perfusion (hypovolemia): the faster a part bleeds,
## the slower its tissue/bone repair. 1.0 at no bleed -> BleedingConstants.BLEED_HEAL_SLOW_FLOOR at/above the
## reference rate. Reference = BleedingConstants.TOURNIQUET_BLEEDING_RATE_THRESHOLD (a severe bleed) so the
## factor is a no-op for trivial oozing.


## Per-part healing-speed factor from active bleeding. 1.0 when the part is not bleeding; a hard stall
## (0.0) for an open untreated arterial wound; otherwise lerp 1.0 -> BleedingConstants.BLEED_HEAL_SLOW_FLOOR
## as the bleed rate rises to BleedingConstants.BLEED_HEAL_SLOW_REF_RATE.
static func bleed_healing_speed_mult(part_bleed_rate: float, untreated_arterial: bool) -> float:
    if part_bleed_rate <= BleedingConstants.BLEEDING_RATE_EPSILON:
        return 1.0
    if untreated_arterial:
        return BleedingConstants.ARTERIAL_UNTREATED_HEAL_STALL_MULT
    var t: float = clampf(part_bleed_rate / BleedingConstants.BLEED_HEAL_SLOW_REF_RATE, 0.0, 1.0)
    return lerpf(1.0, BleedingConstants.BLEED_HEAL_SLOW_FLOOR, t)


## Per-day infection risk dose for one wound. Treated parts (definitive hemostasis) get a greatly reduced
## risk; compound fractures and arterial wounds are more infection-prone.


static func wound_infection_daily_risk(injury: Dictionary, treated: bool) -> float:
    var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE))
    var risk: float = float(
        BleedingConstants.WOUND_INFECTION_SEVERITY_RISK.get(
            sev, BleedingConstants.WOUND_INFECTION_SEVERITY_RISK[BleedingConstants.SEVERITY_MODERATE]
        )
    )
    if injury.get("is_compound_fracture", false):
        risk *= BleedingConstants.WOUND_INFECTION_COMPOUND_FRACTURE_MULT
    if injury.get("is_arterial", false):
        risk *= BleedingConstants.WOUND_INFECTION_ARTERIAL_MULT
    if treated:
        risk *= BleedingConstants.WOUND_INFECTION_TREATED_MULT
    return risk


# --- Severity thresholds (damage as fraction of part max) ---


## Shallow vs deep laceration: vessel involvement scales with penetration depth (ATLS penetrating trauma).
static func penetration_depth_severity_mult(penetration_to_tissue_mm: float) -> float:
    if not BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY or penetration_to_tissue_mm < 0.0:
        return 1.0
    if penetration_to_tissue_mm <= BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return BleedingConstants.PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT
    if penetration_to_tissue_mm >= BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM:
        return 1.0
    var span: float = (
        BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM
    )
    var t: float = (penetration_to_tissue_mm - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return lerpf(BleedingConstants.PENETRATION_DEPTH_SEVERITY_SHALLOW_MULT, 1.0, clampf(t, 0.0, 1.0))


## Arterial involvement scales with wound track depth (cuts only; uses same depth bands as severity).


static func penetration_depth_arterial_mult(penetration_to_tissue_mm: float) -> float:
    if not BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY or penetration_to_tissue_mm < 0.0:
        return 1.0
    if penetration_to_tissue_mm <= BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return BleedingConstants.PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT
    if penetration_to_tissue_mm >= BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM:
        return BleedingConstants.PENETRATION_DEPTH_ARTERIAL_DEEP_MULT
    var span: float = (
        BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM
    )
    var t: float = (penetration_to_tissue_mm - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return lerpf(
        BleedingConstants.PENETRATION_DEPTH_ARTERIAL_SHALLOW_MULT,
        BleedingConstants.PENETRATION_DEPTH_ARTERIAL_DEEP_MULT,
        clampf(t, 0.0, 1.0)
    )


## Internal-organ bleed chance for a torso thrust, scaled by penetration depth (game mm).
## A shallow thrust (pen < MIN) can't reach the organ plane; a deep thrust (pen >= FULL) reaches it at
## full chance. Reuses the same depth bands as the severity/arterial models so all three agree on what
## "deep enough to matter" means. Returns 0.0 when penetration is unknown (< 0) or too shallow.


static func internal_bleed_chance_torso_thrust(penetration_to_tissue_mm: float) -> float:
    if penetration_to_tissue_mm < BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return 0.0
    if penetration_to_tissue_mm >= BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM:
        return BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST
    var span: float = (
        BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM
    )
    var t: float = (penetration_to_tissue_mm - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return BleedingConstants.INTERNAL_BLEED_CHANCE_TORSO_THRUST * clampf(t, 0.0, 1.0)


## Severity of an internal-organ bleed, scaled by penetration depth (game mm). A shallow thrust that just
## reaches the organ plane nicks it lightly (moderate); a deep thrust that pierces through nicks it hard
## (severe). Mirrors internal_bleed_chance_torso_thrust's depth bands. Capped at SEVERE — a nicked organ
## oozes, it is not a severed artery, so it never reaches the CRITICAL arterial decomp band.


static func internal_bleed_severity_for_penetration(penetration_to_tissue_mm: float) -> String:
    if penetration_to_tissue_mm < BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM:
        return BleedingConstants.SEVERITY_MODERATE
    var span: float = (
        BleedingConstants.PENETRATION_DEPTH_SEVERITY_FULL_MM - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM
    )
    var t: float = (penetration_to_tissue_mm - BleedingConstants.PENETRATION_DEPTH_SEVERITY_MIN_MM) / span
    return BleedingConstants.SEVERITY_SEVERE if t >= 0.5 else BleedingConstants.SEVERITY_MODERATE


## Chance of intracranial hemorrhage given skull damage (to_bone) from a head strike.
## Scales linearly with skull damage: a minor chip (to_bone 1) bleeds at ~13% of max chance;
## a full fracture (to_bone >= FULL_DMG) bleeds at max. No breach (to_bone <= 0) -> no bleed.


static func internal_bleed_chance_head_skull_damage(skull_damage: float) -> float:
    if skull_damage <= 0.0:
        return 0.0
    var t: float = clampf(skull_damage / BleedingConstants.HEAD_INTRACRANIAL_BLEED_FULL_DMG, 0.0, 1.0)
    return BleedingConstants.HEAD_INTRACRANIAL_BLEED_MAX_CHANCE * t


## Severity of an intracranial bleed from a head skull breach. A sharp wound that penetrates past
## the skull (deep) or a heavy skull fracture -> SEVERE (subdural hematoma); a light breach ->
## MODERATE (oozing meningeal vessels). Capped at SEVERE — intracranial bleeding is slow/progressive,
## not a CRITICAL arterial exsanguination.


static func internal_bleed_severity_head_skull_damage(
    skull_damage: float, penetration_to_tissue_mm: float = -1.0
) -> String:
    if penetration_to_tissue_mm >= BleedingConstants.HEAD_SKULL_BREACH_PEN_MM:
        return BleedingConstants.SEVERITY_SEVERE
    return (
        BleedingConstants.SEVERITY_SEVERE
        if skull_damage >= BleedingConstants.HEAD_INTRACRANIAL_BLEED_FULL_DMG
        else BleedingConstants.SEVERITY_MODERATE
    )


## ATLS hemorrhage class 1 - 4 from remaining blood volume % (ATLS 10th ed. loss bands).


static func atls_hemorrhage_class_from_remaining_pct(remaining_pct: float) -> int:
    var r: float = clampf(remaining_pct, 0.0, BleedingConstants.MAX_BLOOD_VOLUME)
    if r >= BleedingConstants.ATLS_CLASS_I_MIN_REMAINING:
        return 1
    if r >= BleedingConstants.ATLS_CLASS_II_MIN_REMAINING:
        return 2
    if r >= BleedingConstants.ATLS_CLASS_III_MIN_REMAINING:
        return 3
    return 4


## Consciousness modifier from blood loss (S7 stepped ATLS when flag on; else linear legacy).


static func blood_consciousness_modifier_from_remaining(
    remaining_pct: float,
    linear_start: float,
    linear_floor: float,
    linear_reduction_max: float,
    use_stepped: bool = BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS
) -> float:
    if remaining_pct >= linear_start:
        return 1.0
    if remaining_pct <= linear_floor:
        return maxf(0.0, 1.0 - linear_reduction_max)
    if not use_stepped:
        var reduction: float = (linear_start - remaining_pct) / (linear_start - linear_floor) * linear_reduction_max
        return maxf(0.0, 1.0 - reduction)
    # Piecewise within ATLS classes (mild Class II -> marked Class IV toward death threshold).
    # Class IV (60%->floor) drops steeply to the floor so deep blood loss alone produces unconsciousness.
    if remaining_pct >= BleedingConstants.ATLS_CLASS_II_MIN_REMAINING:
        return lerpf(
            BleedingConstants.ATLS_CONSC_CLASS_II_FLOOR,
            BleedingConstants.ATLS_CONSC_CLASS_I_TOP,
            (
                (remaining_pct - BleedingConstants.ATLS_CLASS_II_MIN_REMAINING)
                / (BleedingConstants.ATLS_CLASS_I_MIN_REMAINING - BleedingConstants.ATLS_CLASS_II_MIN_REMAINING)
            )
        )
    if remaining_pct >= BleedingConstants.ATLS_CLASS_III_MIN_REMAINING:
        return lerpf(
            BleedingConstants.ATLS_CONSC_CLASS_III_FLOOR,
            BleedingConstants.ATLS_CONSC_CLASS_II_FLOOR,
            (
                (remaining_pct - BleedingConstants.ATLS_CLASS_III_MIN_REMAINING)
                / (BleedingConstants.ATLS_CLASS_II_MIN_REMAINING - BleedingConstants.ATLS_CLASS_III_MIN_REMAINING)
            )
        )
    return lerpf(
        maxf(0.0, 1.0 - linear_reduction_max),
        BleedingConstants.ATLS_CONSC_CLASS_III_FLOOR,
        (remaining_pct - linear_floor) / (BleedingConstants.ATLS_CLASS_III_MIN_REMAINING - linear_floor)
    )


## Shift effective remaining % by bleeding rate (downward) and endurance (upward), before
## feeding into the ATLS stepped consciousness curve. Reference conditions (rate=0, endurance=100)
## return the input unchanged. Rate is in %/s (use blood_volume_loss_per_second).


static func adjusted_remaining_for_consciousness(
    remaining_pct: float, bleeding_rate_pct_per_s: float, endurance: float
) -> float:
    var rate_shift: float = minf(
        (
            (bleeding_rate_pct_per_s / BleedingConstants.BLOOD_CONSC_RATE_REF_PCT_PER_S)
            * BleedingConstants.BLOOD_CONSC_RATE_SHIFT_MAX
        ),
        BleedingConstants.BLOOD_CONSC_RATE_SHIFT_MAX
    )
    var end_shift: float = clampf(
        (endurance - BleedingConstants.BLOOD_CONSC_END_REF) * BleedingConstants.BLOOD_CONSC_END_SHIFT_PER_POINT,
        -BleedingConstants.BLOOD_CONSC_END_SHIFT_MAX,
        BleedingConstants.BLOOD_CONSC_END_SHIFT_MAX
    )
    return clampf(remaining_pct - rate_shift + end_shift, 0.0, 100.0)


## Blood volume % lost per second from summed wound bleed rates (game units).


static func blood_volume_loss_per_second(total_bleeding_rate: float, loss_mult: float = 1.0) -> float:
    return total_bleeding_rate * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER * maxf(loss_mult, 0.0)


## Seconds until `blood_volume` reaches a given death threshold at constant bleed (no clotting, no treatment).


static func seconds_to_exsanguination_at_death_threshold(
    total_bleeding_rate: float, blood_volume: float, death_threshold: float, loss_mult: float = 1.0
) -> float:
    var loss_per_s: float = blood_volume_loss_per_second(total_bleeding_rate, loss_mult)
    if loss_per_s <= 0.0:
        return INF
    var buffer: float = blood_volume - death_threshold
    if buffer <= 0.0:
        return 0.0
    return buffer / loss_per_s


## Seconds until `blood_volume` reaches default **`BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD`**.


static func seconds_to_exsanguination(
    total_bleeding_rate: float, blood_volume: float = BleedingConstants.MAX_BLOOD_VOLUME, loss_mult: float = 1.0
) -> float:
    return seconds_to_exsanguination_at_death_threshold(
        total_bleeding_rate, blood_volume, BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD, loss_mult
    )


static func get_bleeding_rate(injury_type: String, severity: String, part: String, sub_region: String = "") -> float:
    var type_rates: Dictionary = BleedingConstants.BLEEDING_RATES.get(injury_type, {})
    var base_rate: float = type_rates.get(severity, 0.0)
    # Critical wounds bleed disproportionately faster due to vessel damage and wound cavity formation
    if severity == BleedingConstants.SEVERITY_CRITICAL:
        base_rate *= 1.4
    elif severity == BleedingConstants.SEVERITY_SEVERE:
        base_rate *= 1.15
    var mult: float = BleedingConstants.BODY_PART_BLEEDING_MULTIPLIERS.get(part, 1.0)
    if not sub_region.is_empty():
        mult *= BleedingConstants.SUB_REGION_BLEEDING_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    # Cap combined body part × sub-region multiplier to prevent extreme stacking (e.g., head+neck=2.4x vs clinical
    # ~1.5-2.0x).
    mult = clampf(mult, 0.0, BleedingConstants.MAX_BODY_PART_SUBREGION_BLEED_MULT)
    return base_rate * mult


# Stump (amputation site) bleeding: part + sub_region (level) accurate. Sub_region = where the cut occurred (proximal vs
# distal).
# If sub_region empty, uses 1.0 for level multiplier. Caller should pass get_random_sub_region(part) when level unknown.


static func get_stump_bleeding_rate(part: String, sub_region: String = "") -> float:
    var base: float = get_bleeding_rate(
        BleedingConstants.INJURY_TYPE_CUT, BleedingConstants.SEVERITY_CRITICAL, part, sub_region
    )
    var level_mult: float = 1.0
    if not sub_region.is_empty():
        level_mult = BleedingConstants.STUMP_LEVEL_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    return base * level_mult


## Fraction of wound bleed rate still lost while direct pressure is held (per injury).


static func direct_pressure_held_flow_retained(is_arterial: bool) -> float:
    if is_arterial:
        return BleedingConstants.DIRECT_PRESSURE_HELD_FLOW_RETAINED_ARTERIAL
    return BleedingConstants.DIRECT_PRESSURE_HELD_FLOW_RETAINED_VENOUS


# Pick a random sub-region given the body part was hit. Uses
# BleedingConstants.SUB_REGION_WEIGHTS[part] so probabilities are relative to that part only. Returns empty
# string if part has no sub-regions.


static func get_random_sub_region(part: String) -> String:
    var subs: Array = BleedingConstants.SUB_REGIONS.get(part, [])
    var weights: Dictionary = BleedingConstants.SUB_REGION_WEIGHTS.get(part, {})
    if subs.is_empty() or weights.is_empty():
        return ""
    for sub in subs:
        if not weights.has(sub):
            weights[sub] = 1.0
    return WeightedSample.pick_random(weights)


# Effective damage multiplier for severity mapping (thin tissue / exposed bone = higher effective depth).


static func get_severity_modifier(part: String, sub_region: String) -> float:
    if sub_region.is_empty():
        return 1.0
    return BleedingConstants.SUB_REGION_SEVERITY_MODIFIERS.get(part, {}).get(sub_region, 1.0)


# Per-severity clotting rate (k per second). Use when not stabilized; arterial applies
# BleedingConstants.BLEEDING_TYPE_CLOTTING_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL] on
# top.


static func get_clotting_rate(severity: String) -> float:
    return BleedingConstants.CLOTTING_RATE_BY_SEVERITY.get(severity, 0.02)  # 0.02 = moderate default


# Multiplier on clotting rate by severity (minor faster, severe/critical slower). Apply in process_bleeding: clotting *=
# get_clotting_multiplier(sev).


static func get_clotting_multiplier(severity: String) -> float:
    return BleedingConstants.CLOTTING_SEVERITY_MULTIPLIERS.get(severity, 1.0)


## True when a wound type cannot be clotted by external means (pressure/bandage). Internal-organ bleeds
## sit inside the body, so the clotting path holds their rate constant instead of decaying it.


static func is_unclottable(injury_type: String) -> bool:
    return injury_type == BleedingConstants.INJURY_TYPE_INTERNAL_BLEED


# Chance (0.0-1.0) that a wound is arterial based on severity, injury type (cut vs crush), body part, and sub-region.
# Research-based. Crush uses BleedingConstants.ARTERIAL_CRUSH_MULTIPLIER ×
# SUB_REGION_BLUNT_ARTERIAL_MODIFIER for region-specific cut vs blunt differentiation.


static func get_arterial_chance(
    severity: String, injury_type: String, part: String, sub_region: String = "", penetration_to_tissue_mm: float = -1.0
) -> float:
    # Internal-organ bleeds are a slow constant ooze, not an arterial event — no arterial chance/multiplier.
    if injury_type == BleedingConstants.INJURY_TYPE_INTERNAL_BLEED:
        return 0.0
    var base_chance: float = BleedingConstants.ARTERIAL_CHANCE_BY_SEVERITY.get(severity, 0.06)
    if injury_type == BleedingConstants.INJURY_TYPE_CRUSH:
        base_chance *= BleedingConstants.ARTERIAL_CRUSH_MULTIPLIER
        if not sub_region.is_empty():
            base_chance *= BleedingConstants.SUB_REGION_BLUNT_ARTERIAL_MODIFIERS.get(part, {}).get(sub_region, 1.0)
    elif injury_type == BleedingConstants.INJURY_TYPE_CUT and penetration_to_tissue_mm >= 0.0:
        base_chance *= penetration_depth_arterial_mult(penetration_to_tissue_mm)
    var part_mult: float = BleedingConstants.ARTERIAL_BODY_PART_MULTIPLIERS.get(part, 1.0)
    if not sub_region.is_empty():
        var sr_mult: float = BleedingConstants.SUB_REGION_ARTERIAL_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
        # Use max of part/sub-region rather than multiply to avoid over-counting vascular chance (e.g., neck critical at
        # ~55% vs lit ~25%).
        part_mult = maxf(part_mult, sr_mult)
    return clampf(base_chance * part_mult, 0.0, 1.0)


## Vital zone damage multiplier - strikes to critical anatomical targets (vital organs, major vessels, brain) deal
## amplified mechanical damage beyond what tissue depth alone captures. Models clinical reality where a throat cut or
## sternum strike is disproportionately lethal vs equivalent damage to forearm/thigh. Returns 1.0 for non-vital zones.


static func get_vital_damage_multiplier(part: String, sub_region: String = "", attack_line: String = "") -> float:
    var base_mult: float = BleedingConstants.VITAL_DAMAGE_MULTIPLIERS.get(part, {}).get(sub_region, 1.0)
    ## Groin targeting: when a low-line strike hits the upper thigh (femoral artery proximity), apply additional
    ## multiplier.
    if part == BodyPartConstants.PART_RIGHT_LEG or part == BodyPartConstants.PART_LEFT_LEG:
        var is_low_line: bool = attack_line.to_lower().begins_with("low")
        if sub_region == "thigh" and is_low_line:
            base_mult *= BleedingConstants.VITAL_GROIN_MULTIPLIER
    return base_mult
