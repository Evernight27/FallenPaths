class_name EntityHealing
extends RefCounted

## Time-advance healing: game time, wound resolution, bandage/tourniquet expiry, tissue/bone/blood recovery.
## Entity must have: _game_time_seconds, wounds, bandaged_parts, packed_parts, tourniquet_applied,
## body_cutting, body_blunt, bone_health, body_max, bone_max, blood_volume; methods _get_body_part_list,
## _is_part_severed, _round_tissue, get_total_bleeding_rate; and EntityWounds.get_wound_healing_progress,
## EntityPainConsciousness.update_consciousness.

# --- Main entry: advance game time and run all healing logic ---


static func _process_healing(entity: Node, seconds: float) -> void:
    if seconds <= 0.0:
        return
    entity._game_time_seconds += seconds

    # Remove resolved wounds (healing progress >= threshold); pain has effectively resolved
    for part in entity.wounds.keys():
        var list: Array = entity.wounds[part]
        var i: int = list.size() - 1
        while i >= 0:
            if EntityWounds._get_wound_healing_progress(entity, list[i]) >= HealingConstants.WOUND_RESOLVED_THRESHOLD:
                list.remove_at(i)
            i -= 1
        if list.is_empty():
            entity.wounds.erase(part)
            entity.bandaged_parts.erase(part)
            entity.packed_parts.erase(part)

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
                entity.tourniquet_applied.erase(part)
    # Wound infection: untreated wounds accumulate infection risk over days (a clean dressing or tourniquet
    # greatly reduces it). Progresses only on day-scale time advances (never during a battle), so campaign-only.
    var per_day: float = seconds / HealingConstants.SECONDS_PER_DAY
    if per_day > 0.0:
        for part in entity.wounds.keys():
            var treated: bool = EntityWounds.part_has_definitive_hemostasis(entity, part)
            for injury in entity.wounds[part]:
                if injury.get("is_infected", false):
                    continue
                var risk: float = BleedingConstants.wound_infection_daily_risk(injury, treated)
                if risk <= 0.0:
                    continue
                var progress: float = float(injury.get("infection_progress", 0.0)) + per_day * risk
                if progress >= 1.0:
                    injury["is_infected"] = true
                    injury["infection_progress"] = 1.0
                    EntityMedical.log_medical_session(
                        "%s wound_infected(%s): untreated wound became infected" % [entity.name, part]
                    )
                else:
                    injury["infection_progress"] = progress

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
        # Infected wounds heal slower (systemic response + tissue damage from the infection).
        if entity.wounds.has(part):
            var infected_here: bool = false
            for injury in entity.wounds[part]:
                if injury.get("is_infected", false):
                    infected_here = true
                    break
            if infected_here:
                heal_speed *= BleedingConstants.WOUND_INFECTION_HEAL_SPEED_MULT
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
        var tau_bone: float = bone_duration / (HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR * heal_speed)
        var bone_heal: float = remain_bone * (1.0 - exp(-seconds / tau_bone))
        entity.bone_health[part] = entity._round_tissue(minf(float(max_bone), cur_bone + bone_heal))

    # Blood volume recovery when not bleeding: exponential (deficit ~ current deficit). Body replenishes over ~24 h.
    if entity._get_total_bleeding_rate() <= 0.0:
        var remain_blood: float = BleedingConstants.MAX_BLOOD_VOLUME - entity.blood_volume
        if remain_blood > 0.0:
            var tau_blood: float = (
                HealingConstants.BLOOD_VOLUME_RECOVERY_DURATION_SECONDS / HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR
            )
            var add_blood: float = remain_blood * (1.0 - exp(-seconds / tau_blood))
            entity.blood_volume = minf(BleedingConstants.MAX_BLOOD_VOLUME, entity.blood_volume + add_blood)
            if BloodVolumeMl.entity_uses_ml(entity):
                BloodVolumeMl.sync_ml_from_percent(entity)
    # Pain and consciousness depend on wounds, head, and blood; refresh after all healing/time advance.
    EntityPainConsciousness.update_consciousness(entity)
