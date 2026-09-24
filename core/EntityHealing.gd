class_name EntityHealing
extends RefCounted

## Time-advance healing: game time, wound resolution, bandage/tourniquet expiry, tissue/bone/blood recovery.
## Entity must have: _game_time_seconds, wounds, bandaged_parts, packed_parts, tourniquet_applied,
## body_cutting, body_blunt, bone_health, body_max, bone_max, blood_volume; methods _get_body_part_list,
## _is_part_severed, _round_tissue, get_total_bleeding_rate; and EntityWounds.get_wound_healing_progress,
## EntityPainConsciousness.update_consciousness.

# CompanyState is world-owned; core reads it lazily to avoid circular preload.
static var _company_state: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state == null:
        _company_state = load("res://world/CompanyState.gd")
    return _company_state


# --- Main entry: advance game time and run all healing logic ---


static func _process_healing(entity: Node, seconds: float) -> void:
    if seconds <= 0.0:
        return
    # A corpse does not convalesce: a member who has died (blood-loss death, vital-destruction grace
    # elapsed, sepsis/tetanus death roll) must not heal, resolve wounds, restage sepsis, or accrue pain
    # on later advances — dead tissue heals nothing. Resolving a corpse's wounds would stash descriptors
    # that the world mint then turns into PERMANENT scars (and mood / op-log lines) on the deceased; the
    # game clock and wound bookkeeping freeze at the death snapshot instead.
    if entity.has_method("is_dead") and entity.is_dead():
        # Death must also sever the pressure coupling: nothing clears a corpse's direct-pressure latches
        # (the hemostasis auto-release in process_bleeding never fires -- that pass gates corpses out --
        # and clear_direct_pressure_scene only runs when a holder takes a new MOVE, not at battle end).
        # A dead casualty keeps direct_pressure_part / self / held-by / assist FOREVER, and -- worse --
        # the medic holding them keeps direct_pressure_on_ally pointing at a corpse: next battle that
        # medic reads "already holding" (prepare_for_medical_windup / assist eligibility / triage) and
        # can't treat a NEW casualty; a corpse that was holding on a LIVING ally leaves the living ally
        # with a dead holder. clear_direct_pressure is the canonical teardown (CoreEntity._clear_direct_pressure)
        # and handles both roles; on a corpse the rebound helper is a dict-only no-op, and a living ex-casualty
        # gets its proper release-without-dressing rebleed.
        EntityMedical.clear_direct_pressure(entity)
        return
    entity._game_time_seconds += seconds

    # Remove resolved wounds (healing progress >= threshold); pain has effectively resolved
    for part in entity.wounds.keys():
        var list: Array = entity.wounds[part]
        var i: int = list.size() - 1
        while i >= 0:
            if EntityWounds._get_wound_healing_progress(entity, list[i]) >= HealingConstants.WOUND_RESOLVED_THRESHOLD:
                var inj: Dictionary = list[i]
                # CAMP-SCAR-1: record what this wound left behind so the world layer can mint a scar.
                if entity.has_method("_stash_resolved_wound"):
                    entity._stash_resolved_wound({
                        "part": part,
                        "severity": str(inj.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE)),
                        "injury_type": str(inj.get("injury_type", "")),
                        "is_compound_fracture": bool(inj.get("is_compound_fracture", false)),
                        # Infection history rides on the wound's ever_infected latch (set once at the
                        # 0->1 flip) with the live stage/is_infected state as a floor for legacy wounds
                        # that predate the latch. A dressing clears stage/is_infected but NOT the latch,
                        # so a cured-then-resolved wound still reports was_infected (scar mint).
                        "was_infected": bool(inj.get("ever_infected", false)) or (int(inj.get("infection_stage", 0)) >= 1) or bool(inj.get("is_infected", false)),
                        "is_osteomyelitis": bool(inj.get("is_osteomyelitis", false)),
                        # Ischemia history travels on the WOUND's own latch (set by
                        # apply_tourniquet_ischemia_damage only when the TQ actually expires) -- NOT on
                        # tourniquet_applied: at resolution the clamp is still in the dict until the
                        # cleanup below (pass 17), so reading tourniquet_applied.has(part) here would
                        # false-positive on every wound that resolves pre-expiry and mint a Volkmann
                        # contracture (grip 0.78) on a limb whose clamp was released at healing (no
                        # ischemic necrosis occurred).
                        "had_ischemia": bool(inj.get("had_ischemia", false)),
                    })
                list.remove_at(i)
            i -= 1
        if list.is_empty():
            entity.wounds.erase(part)
            entity.bandaged_parts.erase(part)
            entity.packed_parts.erase(part)
            # A tourniquet must not outlive its wound: once the limb's last wound resolves, release the
            # clamp with the bandage/packing cleanup. Otherwise the stale TQ lingers until max duration
            # and silently skips the ischemia consequence (the expiring loop latches had_ischemia onto a
            # wound that no longer exists), and a stale `applied_at` from a previous battle instantly
            # "expires" against a NEW re-wound in the next fight -- an hour-long clamp turns into an
            # immediate ischemic strike. Healed limb, released clamp: consistent with the dressing cleanup.
            EntityMedical._remove_tourniquet(entity, part)
            # Held direct pressure must die with the wound too: a pressure latch that outlives the last
            # wound on the part silently marks the NEXT fresh wound as pressure-held (get_bleeding_rate
            # applies the direct-pressure flow-retention factor and the clotting sim the under-pressure
            # rate) with nobody holding anything — one free invisible hemostasis helper for the re-injury.
            # There is nothing left to press on a healed part, so drop the latch (held-by, assist, and the
            # ally's on-ally record) here; the rebound helper is a no-op on a woundless part.
            EntityMedical.release_direct_pressure_on_part(entity, part)

    # Bandage stabilization expiry: subtract time from stabilized_remaining_seconds; clear is_stabilized when expired.
    if BleedingConstants.BANDAGE_STABILIZATION_DURATION > 0.0:
        for part in entity.wounds.keys():
            for injury in entity.wounds[part]:
                if injury.get("stabilized_remaining_seconds", 0.0) > 0.0:
                    var rem: float = injury["stabilized_remaining_seconds"] - seconds
                    injury["stabilized_remaining_seconds"] = maxf(0.0, rem)
                    if rem <= 0.0:
                        injury["is_stabilized"] = false
                        injury.erase("stabilized_remaining_seconds")
    # Tourniquet expiry: if max duration > 0, release TQ after duration (limb ischemia risk). Bleeding can resume.
    # A TQ left on too long causes ischemic soft-tissue damage to the limb (necrosis / compartment injury).
    if BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS > 0.0:
        for part in entity.tourniquet_applied.keys():
            EntityMedical.ensure_tourniquet_dict_entry(entity, part)
            var data: Dictionary = entity.tourniquet_applied[part]
            var applied_at: float = data.get("applied_at", 0.0)
            if entity._game_time_seconds - applied_at >= BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS:
                EntityMedical.apply_tourniquet_ischemia_damage(entity, part)
                EntityMedical._remove_tourniquet(entity, part)
    # Wound infection: untreated wounds accumulate infection risk over days (a clean dressing or tourniquet
    # greatly reduces it). Progresses only on day-scale time advances (never during a battle), so campaign-only.
    # CAMP-INF-1 (staged): clean(0) -> localized(1) -> septic(2) + entity-level sepsis death/resolve roll.
    # When the gate is off, the legacy single-stage model (is_infected flip at 1.0) is used.
    var per_day: float = seconds / HealingConstants.SECONDS_PER_DAY
    if per_day > 0.0:
        var staging_on: bool = _get_company_state().read_stub_infection_staging_enabled()
        for part in entity.wounds.keys():
            var treated: bool = EntityWounds.part_has_definitive_hemostasis(entity, part)
            for injury in entity.wounds[part]:
                if staging_on:
                    _advance_infection_stage(entity, part, injury, treated, per_day)
                else:
                    _advance_infection_legacy(entity, injury, treated, per_day)
        # Entity-level sepsis death / recovery (staged model only). Keyed to is_septic so healing
        # a septic wound cannot silently stop the death roll (plan §11).
        if staging_on:
            _process_sepsis(entity, per_day)
            # A sepsis death latched above stops the tetanus pass for this advance: the corpse must not
            # arm spore loads, flip is_tetanus, or take a second death roll mid-call. The re-check below
            # guards the tissue/bone/blood pipeline, not this sepsis->tetanus hand-off.
            if not (entity.has_method("is_dead") and entity.is_dead()):
                _process_tetanus(entity, per_day)

    # A death roll latched DURING this advance (sepsis/tetanus above) must stop the rest of the
    # pipeline: tissue/bone regrow and blood recovery below would otherwise run on the fresh corpse
    # within the same call, regrowing limb pools and popping blood_volume back ABOVE the death clamp
    # emit_death_once just set. The entry gate only covers LATER advances — death is discovered on
    # ENTRY, but these rolls fire mid-call, so re-check here. Pressure coupling is severed the same
    # way as the entry gate (death releases the bookkeeping); consciousness refreshes so the corpse
    # reports the death snapshot rather than its last living value.
    if entity.has_method("is_dead") and entity.is_dead():
        EntityMedical.clear_direct_pressure(entity)
        EntityPainConsciousness.update_consciousness(entity)
        return

    for part in entity._get_body_part_list():
        if part not in entity.body_max or part not in entity.bone_max:
            continue
        if entity._is_part_severed(part):
            continue  # severed part is gone; no healing. Crushed/mangled (still attached) can heal (limb salvage).
        var max_tissue: int = entity.body_max.get(part, 0)
        var max_bone: int = entity.bone_max.get(part, 0)
        if max_tissue <= 0:
            continue
        # Worst wound severity on this part sets tissue heal duration (medical realism)
        var severity: String = BleedingConstants.SEVERITY_MINOR
        if entity.wounds.has(part) and entity.wounds[part].size() > 0:
            var order: Array = [
                BleedingConstants.SEVERITY_MINOR,
                BleedingConstants.SEVERITY_MODERATE,
                BleedingConstants.SEVERITY_SEVERE,
                BleedingConstants.SEVERITY_CRITICAL
            ]
            for injury in entity.wounds[part]:
                var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MINOR)
                if order.find(sev) > order.find(severity):
                    severity = sev
        var tissue_duration: float = HealingConstants.get_tissue_heal_duration_seconds(part, severity)
        if tissue_duration <= 0.0:
            tissue_duration = HealingConstants.SECONDS_PER_DAY * 4.0
        # Tissue: exponential healing (deficit *= exp(-t/tau)); rate ~ current deficit. See
        # HealingConstants.gd (exponential decay model, BMC Dermatol 9:2).
        var cur_cut: float = entity.body_cutting.get(part, 0.0)
        var cur_blunt: float = entity.body_blunt.get(part, 0.0)
        var remain_cut: float = float(max_tissue) - cur_cut
        var remain_blunt: float = float(max_tissue) - cur_blunt
        var heal_speed: float = 1.0
        if entity.has_method("_get_endurance_healing_speed_mult"):
            heal_speed = entity._get_endurance_healing_speed_mult()
        # TBI impairs recovery cascades — concussed entities heal slower (clinical evidence of delayed wound healing in TBI).
        var conc_info: Dictionary = EntityPainConsciousness.get_concussion_phase_info(entity)
        var conc_healing_mult: float = conc_info.get("healing_mult", 1.0)
        heal_speed *= conc_healing_mult
        # Malnutrition impairs wound healing: a starving member heals slower than a well-fed one.
        if entity.has_method("_get_nutrition_healing_speed_mult"):
            heal_speed *= entity._get_nutrition_healing_speed_mult()
        # Infected (stage>=1) / septic (stage==2) wounds heal slower (CAMP-INF-1).
        if entity.wounds.has(part):
            var worst_stage: int = 0
            for injury in entity.wounds[part]:
                worst_stage = max(worst_stage, _effective_infection_stage(injury))
            if worst_stage >= 2:
                heal_speed *= BleedingConstants.SEPSIS_HEAL_SPEED_MULT
            elif worst_stage == 1:
                heal_speed *= BleedingConstants.WOUND_INFECTION_HEAL_SPEED_MULT
        # CAMP-SCAR-1: a scarred part (wound-derived scar) heals slower; heal_mult < 1.0.
        if entity.has_method("_get_scar_heal_mult"):
            heal_speed *= entity._get_scar_heal_mult(part)
        # Active bleeding diverts repair resources + impairs local perfusion: the faster this part bleeds,
        # the slower its tissue/bone repair. An open, untreated arterial wound cannot close while systolic
        # pressure drives flow through it, so repair stalls until definitive hemostasis (TQ/pack/clot).
        var part_bleed: float = EntityWounds.get_bleeding_rate_for_part(entity, part)
        if part_bleed > BleedingConstants.BLEEDING_RATE_EPSILON:
            var untreated_arterial: bool = false
            if not EntityWounds.part_has_definitive_hemostasis(entity, part):
                for injury in entity.wounds[part]:
                    if (
                        injury.get("is_arterial", false)
                        and float(injury.get("current_bleeding_rate", 0.0)) > BleedingConstants.BLEEDING_RATE_EPSILON
                    ):
                        untreated_arterial = true
                        break
            heal_speed *= BleedingConstants.bleed_healing_speed_mult(part_bleed, untreated_arterial)
        var tau_tissue: float = tissue_duration / (HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR * heal_speed)
        var add_cut: float = remain_cut * (1.0 - exp(-seconds / tau_tissue))
        var add_blunt: float = remain_blunt * (1.0 - exp(-seconds / tau_tissue))
        entity.body_cutting[part] = entity._round_tissue(minf(float(max_tissue), cur_cut + add_cut))
        entity.body_blunt[part] = entity._round_tissue(minf(float(max_tissue), cur_blunt + add_blunt))
        # Sync J reservoir when display pools change (prevents J/display mismatch during healing).
        if "tissue_energy_remaining_j" in entity and "tissue_energy_capacity_j" in entity:
            var body_max_t: int = max_tissue
            var cap_j: float = float(entity.tissue_energy_capacity_j.get(part, 0.0))
            if cap_j > 0.01:
                entity.tissue_energy_remaining_j[part] = TissueEnergyCapacity.remaining_j_from_display_pools(
                    body_max_t,
                    entity.body_cutting.get(part, 0.0),
                    entity.body_blunt.get(part, 0.0),
                    cap_j,
                )
        # Bone: exponential healing toward max (6 weeks duration)
        var bone_duration: float = HealingConstants.get_bone_heal_duration_seconds(part)
        if bone_duration <= 0.0:
            bone_duration = HealingConstants.BONE_HEAL_DURATION_SECONDS
        var cur_bone: float = entity.bone_health.get(part, 0.0)
        var remain_bone: float = float(max_bone) - cur_bone
        # Osteomyelitis (plan §10.3): a chronic sequestered bone nidus halves the bone-heal rate.
        var bone_speed: float = heal_speed
        if entity.wounds.has(part):
            for injury in entity.wounds[part]:
                if bool(injury.get("is_osteomyelitis", false)):
                    bone_speed *= BleedingConstants.OSTEOMYELITIS_BONE_HEAL_MULT
                    break
        var tau_bone: float = bone_duration / (HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR * bone_speed)
        var bone_heal: float = remain_bone * (1.0 - exp(-seconds / tau_bone))
        entity.bone_health[part] = entity._round_tissue(minf(float(max_bone), cur_bone + bone_heal))

    # Blood volume recovery when not bleeding: exponential (deficit ~ current deficit). Body replenishes over ~24 h.
    if entity._get_total_bleeding_rate() <= 0.0:
        var remain_blood: float = BleedingConstants.MAX_BLOOD_VOLUME - entity.blood_volume
        if remain_blood > 0.0:
            var tau_blood: float = (
                HealingConstants.BLOOD_VOLUME_RECOVERY_DURATION_SECONDS / HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR
            )
            # A decompensated patient (ATLS Class III->IV, below DECOMPENSATION_BLOOD_THRESHOLD) does not
            # self-replenish: perfusion collapse needs resuscitation. Scale the rest-recovery down the same
            # way the other two recovery sources already do — process_blood_loss's recovery term carries
            # DECOMPENSATED_RECOVERY_SUPPRESSION and _apply_fluid_resuscitation scales its bolus — otherwise
            # a single rest day erases a near-fatal hemorrhage back to ~95% with no intervention, quietly
            # uncoupling the decompensation death-spiral the bleeding model documents.
            var rest_recovery_mult: float = 1.0
            if entity.blood_volume < BleedingConstants.DECOMPENSATION_BLOOD_THRESHOLD:
                rest_recovery_mult = BleedingConstants.DECOMPENSATED_RECOVERY_SUPPRESSION
            var add_blood: float = remain_blood * (1.0 - exp(-seconds / tau_blood)) * rest_recovery_mult
            entity.blood_volume = minf(BleedingConstants.MAX_BLOOD_VOLUME, entity.blood_volume + add_blood)
            if BloodVolumeMl.entity_uses_ml(entity):
                BloodVolumeMl.sync_ml_from_percent(entity)
    # Pain and consciousness depend on wounds, head, and blood; refresh after all healing/time advance.
    EntityPainConsciousness.update_consciousness(entity)


# --- Infection staging (CAMP-INF-1) ---


## Effective infection stage for a wound. Legacy wounds carry is_infected but no infection_stage,
## so is_infected maps to stage 1 (localized) for backward compatibility.
static func _effective_infection_stage(injury: Dictionary) -> int:
    var stage: int = int(injury.get("infection_stage", 0))
    if injury.get("is_infected", false) and stage < 1:
        stage = 1
    return stage


## Legacy single-stage progression: flip is_infected at progress >= 1.0. Uses the SAME per-day dose
## as staged mode (plan §1 source of truth) — base severity risk × contamination × susceptibility,
## capped — so flipping the staging gate cannot silently change infection severity.
static func _advance_infection_legacy(entity: Node, injury: Dictionary, treated: bool, per_day: float) -> void:
    if injury.get("is_infected", false):
        return
    # Entry-portal realism (plan §1): a closed wound (bruise / clean fracture) has no tract to seed.
    if not BleedingConstants.injury_has_open_entry(injury):
        return
    var dose: float = BleedingConstants.wound_infection_daily_dose(entity, injury, treated)
    if dose <= 0.0:
        return
    var progress: float = float(injury.get("infection_progress", 0.0)) + per_day * dose
    if progress >= 1.0:
        injury["is_infected"] = true
        injury["ever_infected"] = true
        injury["infection_progress"] = 1.0
    else:
        injury["infection_progress"] = progress


## Staged progression (CAMP-INF-1): clean(0) -> localized(1) -> septic(2).
## Stage 1 stalls while the part is treated (source control); a stage-0->1 flip extends the
## track-(a) resolution duration one-way. Stage-2 sets the entity is_septic flag.
static func _advance_infection_stage(entity: Node, part: String, injury: Dictionary, treated: bool, per_day: float) -> void:
    var stage: int = _effective_infection_stage(injury)
    # Osteomyelitis (plan §10.3): an exposed-bone (compound fracture) wound that localizes
    # (stage >= 1) sequesters a chronic bone nidus. Latch the flag once; it persists for the
    # wound's life, halving bone-heal and keeping a residual festering dose while source-controlled.
    if stage >= 1 and bool(injury.get("is_compound_fracture", false)) and not bool(injury.get("is_osteomyelitis", false)):
        injury["is_osteomyelitis"] = true
        EntityMedical.log_medical_session(
            "%s osteomyelitis(%s): exposed bone infection" % [entity.name, part]
        )
    if stage == 0:
        # Entry-portal realism (plan §1): infection needs an open tract. A closed contusion (bruise)
        # or a clean (non-compound) fracture cannot seed — zero dose, matching the closed-wound
        # boundary the scar mint uses (CAMP-SCAR-1 §2.3). The gate is entry-only: a wound already
        # infected (e.g. a legacy save that flipped before this rule) keeps its existing sepsis track.
        if not BleedingConstants.injury_has_open_entry(injury):
            return
        var dose: float = BleedingConstants.wound_infection_daily_dose(entity, injury, treated)
        # Golden-period realism (plan §1.2): infection risk is front-loaded in a wound's life. A wound
        # that has been open for days is far less likely to *newly* infect than a fresh one, so scale the
        # per-day dose down by the wound's age (1.0 fresh -> FLOOR after INFECTION_FRESH_WINDOW_DAYS).
        # Fresh wounds (age ~0) are unaffected, preserving the calibrated base rates.
        var created: float = float(injury.get("created_at_game_time", -1.0))
        var age_days: float = 0.0
        if created >= 0.0 and "_game_time_seconds" in entity:
            age_days = maxf(0.0, (float(entity._game_time_seconds) - created) / HealingConstants.SECONDS_PER_DAY)
        dose *= BleedingConstants.infection_freshness_factor(age_days)
        if dose <= 0.0:
            return
        var progress: float = float(injury.get("infection_progress", 0.0)) + per_day * dose
        if progress >= 1.0:
            injury["infection_stage"] = 1
            injury["is_infected"] = true
            injury["ever_infected"] = true
            injury["infection_progress"] = 1.0
            _extend_resolution_duration(injury, BleedingConstants.INFECTION_HEAL_DURATION_MULT)
            EntityMedical.log_medical_session(
                "%s wound_infected(%s): untreated wound became localized" % [entity.name, part]
            )
        else:
            injury["infection_progress"] = progress
    elif stage == 1:
        if not injury.get("is_infected", false):
            injury["is_infected"] = true
        if not injury.get("ever_infected", false):
            injury["ever_infected"] = true  # stage-1 wound is infected even if the live flag is stale
        var osteo: bool = bool(injury.get("is_osteomyelitis", false))
        if treated and not osteo:
            return  # source-controlled localized infection does not go systemic
        # Osteomyelitis (plan §10.3): the sequestered bone nidus is not cleared by surface control, so
        # a treated osteo wound keeps a small residual festering dose instead of fully stalling.
        var base_rate: float = BleedingConstants.SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY
        if treated and osteo:
            base_rate = BleedingConstants.OSTEOMYELITIS_RESIDUAL_DAILY_DOSE
        var mult: float = BleedingConstants.GAS_GANGRENE_PROGRESS_MULT if injury.get("is_gas_gangrene", false) else 1.0
        var sp: float = float(injury.get("sepsis_progress", 0.0)) + per_day * base_rate * mult
        if sp >= 1.0:
            # Phase A+ (gas gangrene, plan §10.1): at the localized->septic flip, arm the clostridial
            # variant on gangrene-prone wounds (crush / compound fracture / deep penetrating / low
            # perfusion). A severity-scaled roll, not a certainty. Once armed, this wound's death roll
            # uses GAS_GANGRENE_DEATH_RISK_PER_DAY (handled in _process_sepsis via _has_gangrene_focus).
            if not injury.get("is_gas_gangrene", false) and BleedingConstants.is_gangrene_candidate(entity, part, injury):
                if randf() < BleedingConstants.gangrene_candidate_roll(injury):
                    injury["is_gas_gangrene"] = true
                    EntityMedical.log_medical_session(
                        "%s gas_gangrene(%s): wound became clostridial" % [entity.name, part]
                    )
            injury["infection_stage"] = 2
            injury["sepsis_progress"] = 1.0
            _extend_resolution_duration(injury, BleedingConstants.SEPSIS_HEAL_DURATION_MULT)
            if not entity.is_septic:
                entity.is_septic = true
                EntityMedical.log_medical_session(
                    "%s sepsis(%s): infection became systemic" % [entity.name, part]
                )
        else:
            injury["sepsis_progress"] = sp


## One-way track-(a) extension: multiply the stored resolution duration (only if present/positive).
static func _extend_resolution_duration(injury: Dictionary, mult: float) -> void:
    var dur: float = float(injury.get("healing_duration_seconds", 0.0))
    if dur > 0.0:
        injury["healing_duration_seconds"] = dur * mult


## True when every septic focus (stage-2 wound) has definitive hemostasis or is a stump (source removed).
## Vacuously true when no stage-2 foci remain (e.g. the septic wound healed/amputated): the residual
## systemic infection then clears over time via sepsis_resolve_progress.
static func _all_septic_foci_source_controlled(entity: Node) -> bool:
    for part in entity.wounds.keys():
        var has_septic_focus: bool = false
        for injury in entity.wounds[part]:
            if int(injury.get("infection_stage", 0)) == 2:
                has_septic_focus = true
        if not has_septic_focus:
            continue
        if EntityWounds.part_has_definitive_hemostasis(entity, part) or EntityWounds.has_stump_wound(entity, part):
            continue
        return false
    return true


static func _has_gangrene_focus(entity: Node) -> bool:
    for part in entity.wounds.keys():
        for injury in entity.wounds[part]:
            if int(injury.get("infection_stage", 0)) == 2 and injury.get("is_gas_gangrene", false):
                return true
    return false


## Entity-level sepsis death / recovery (plan §11). Keyed to is_septic so healing a septic wound
## cannot silently stop the death roll. Death is a per-day probabilistic roll; recovery accrues
## only while source-controlled.
static func _process_sepsis(entity: Node, per_day: float) -> void:
    if not entity.is_septic:
        return
    var source_controlled: bool = _all_septic_foci_source_controlled(entity)
    var death_risk: float = BleedingConstants.SEPSIS_DEATH_RISK_SOURCE_CONTROLLED if source_controlled else BleedingConstants.SEPSIS_DEATH_RISK_PER_DAY
    if _has_gangrene_focus(entity):
        death_risk = BleedingConstants.GAS_GANGRENE_DEATH_RISK_PER_DAY
    if not entity._sepsis_dead and randf() < death_risk * per_day:
        entity._sepsis_dead = true
        entity.blood_volume = minf(entity.blood_volume, BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
        EntityWounds.emit_death_once(entity)
        EntityMedical.log_medical_session("%s died(sepsis): systemic infection" % [entity.name])
        return
    if source_controlled:
        entity.sepsis_resolve_progress = minf(1.0, entity.sepsis_resolve_progress + per_day * BleedingConstants.SEPSIS_RESOLVE_PER_DAY_TREATED)
        if entity.sepsis_resolve_progress >= 1.0:
            entity.is_septic = false
            entity.sepsis_resolve_progress = 0.0
            if "sepsis_recovered" in entity:
                entity.sepsis_recovered = true
            EntityMedical.log_medical_session("%s sepsis_recovered: systemic infection cleared" % [entity.name])


## Tetanus (plan §10.2): a delayed, spore-borne hazard distinct from local wound infection.
## Unlike infection, a surface dressing does NOT abort it once spores are seeded; the wound can
## fully heal before the member manifests. Incubation + the symptomatic window are entity-level
## so they survive the seeding wound resolving.
##   1. Arm: while a contaminated deep cut/stab (is_wound_contaminated) is present and no spore
##      load exists, draw one incubation in [TETANUS_INCUBATION_MIN..MAX_DAYS] (once per load).
##   2. Incubate: the countdown decrements every day-advance (treatment-agnostic). At <=0, roll
##      TETANUS_ONSET_RISK; on hit, latch the systemic is_tetanus state.
##   3. Symptomatic window: a per-day TETANUS_DEATH_RISK_PER_DAY death roll for
##      TETANUS_SYMPTOMATIC_DAYS; at the window's end the member survives (is_tetanus cleared).
static func _process_tetanus(entity: Node, per_day: float) -> void:
    if not ("is_tetanus" in entity) or not ("tetanus_incubation_days" in entity):
        return
    # Arm a single spore load while a contaminated wound is present (once).
    if entity.tetanus_incubation_days < 0.0 and not entity.is_tetanus:
        for part in entity.wounds.keys():
            var contaminated: bool = false
            for injury in entity.wounds[part]:
                if BleedingConstants.is_wound_contaminated(injury):
                    contaminated = true
                    break
            if contaminated:
                entity.tetanus_incubation_days = BleedingConstants.tetanus_arm_days()
                # Plan §10.2 counter-play: a wound cleanly dressed / debrided (definitive hemostasis)
                # at the moment the spores are seeded has ~half the onset risk — debridement removes
                # spores before they germinate. Latch the treatment state at arm time (the moment of
                # injury); a later dressing does not reach back to remove spores already seeded.
                entity.tetanus_cleaned_at_arm = EntityWounds.part_has_definitive_hemostasis(entity, part)
                EntityMedical.log_medical_session(
                    "%s tetanus_risk(%s): contaminated wound seeding spore load" % [entity.name, part]
                )
                break
    # Incubation countdown (treatment-agnostic; the wound may heal first).
    if entity.tetanus_incubation_days > 0.0:
        entity.tetanus_incubation_days -= per_day
        if entity.tetanus_incubation_days <= 0.0:
            entity.tetanus_incubation_days = -1.0
            # Plan §10.2 counter-play: a wound that was cleanly dressed / debrided when the spores were
            # seeded (tetanus_cleaned_at_arm) germinates less often — scale the onset roll accordingly.
            var onset_risk: float = BleedingConstants.TETANUS_ONSET_RISK
            if "tetanus_cleaned_at_arm" in entity and bool(entity.tetanus_cleaned_at_arm):
                onset_risk *= BleedingConstants.TETANUS_ONSET_RISK_TREATED_MULT
            if not entity.is_tetanus and randf() < onset_risk:
                entity.is_tetanus = true
                entity.tetanus_resolve_progress = 0.0
                EntityMedical.log_medical_session("%s tetanus_onset: systemic rigidity" % [entity.name])
    if not entity.is_tetanus:
        return
    # Symptomatic window: per-day death roll, then survival at the window's end.
    if not entity._tetanus_dead and randf() < BleedingConstants.TETANUS_DEATH_RISK_PER_DAY * per_day:
        entity._tetanus_dead = true
        entity.blood_volume = minf(entity.blood_volume, BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
        EntityWounds.emit_death_once(entity)
        EntityMedical.log_medical_session("%s died(tetanus): systemic spasm" % [entity.name])
        return
    entity.tetanus_resolve_progress = minf(1.0, entity.tetanus_resolve_progress + per_day / BleedingConstants.TETANUS_SYMPTOMATIC_DAYS)
    if entity.tetanus_resolve_progress >= 1.0:
        entity.is_tetanus = false
        entity.tetanus_resolve_progress = 0.0
        EntityMedical.log_medical_session("%s tetanus_recovered: symptomatic window ended" % [entity.name])
