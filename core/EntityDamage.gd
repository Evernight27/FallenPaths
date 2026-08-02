class_name EntityDamage
extends RefCounted

## Severance ease and full damage-split application. Entity must have: body_*, bone_*, wounds, endurance,
## _get_armor_for_part(part), _round_tissue(v), _get_vital_parts(), _is_part_severed(part),
## _get_pain_contribution_for_wound(...),
## _last_hit_impact, _try_enter_pain_shock_from_hit(pain), _update_consciousness(), EntityWounds.emit_death_once.

# Damage resistance and severance (CoreEntity-aligned).
const ENDURANCE_DAMAGE_RESISTANCE_PER_POINT: float = 0.0001
const ENDURANCE_DAMAGE_RESISTANCE_MAX: float = 0.05
const MIN_DAMAGE_TO_SEVER: int = 10
const DEFLECTION_BRUISE_THRESHOLD: int = 3
const SEVERANCE_EARLY_THRESHOLD: float = 0.40
const SEVERANCE_EARLY_MAX_CHANCE: float = 0.20
const SEVERANCE_EARLY_LIMBS_ONLY: bool = true

# Severance ease: full-health limb resists dismemberment; already wounded/bone-damaged parts give way more easily.
const SEVERANCE_EASE_MAX: float = 1.8
const SEVERANCE_EASE_TISSUE_FACTOR: float = 0.4
const SEVERANCE_EASE_BONE_FACTOR: float = 0.3
const SEVERANCE_EASE_PER_WOUND: float = 0.03
const SEVERANCE_EASE_WOUND_CAP: float = 0.12
const SEVERANCE_EASE_SEVERITY_BONUS: Dictionary = {"minor": 0.0, "moderate": 0.05, "severe": 0.12, "critical": 0.20}

# Per-channel amplification dampening to prevent multi-channel zeroing from ease factor alone.
# When base allocation already zeroes a channel (to_X >= cur_X), ease=1.0 for that channel — no bonus amplification.
# Otherwise, local ease = 1.0 + (severance_ease - 1.0) * CHANNEL_DAMP, capping the wound amplifier so
# at most one channel can be zeroed by amplified damage per hit when base allocations alone wouldn't do it.
const SEVERANCE_EASE_CHANNEL_DAMP: float = 0.75

## --- Armor energy accounting (design options, not implemented) ---
## Option A  -  Layer joule budget: each layer absorbs KE from a running total; sharp vs blunt uses split
## absorption curves. Pros: matches armor literature, one conserved quantity. Cons: needs per-material
## data, larger refactor, tuning all weapons again.
## Option B  -  Impedance chain: sequential reflection coefficients per interface. Pros: fast, stable.
## Cons: still many tuned coefficients, less intuitive than joules for designers.
## Option C  -  Hybrid: keep current scalar streams but report "estimated absorbed joules" for logs/AI
## only. Pros: incremental. Cons: not physically authoritative, can disagree with gameplay damage.
## Option D  -  Monte Carlo micro-deflect: sample yarn/ring deflections. Pros: rich variance. Cons: CPU,
## hard to balance, opaque to players.


static func _layer_state_rows_for_part(entity: Node, part: String) -> Array:
    if not ("tissue_layer_state" in entity):
        return CombatLayerTissue.seed_layer_state_for_part(part)
    var by_part: Variant = entity.tissue_layer_state
    if by_part is Dictionary:
        if not by_part.has(part):
            by_part[part] = CombatLayerTissue.seed_layer_state_for_part(part)
        var rows: Variant = by_part[part]
        if rows is Array:
            return rows
    return CombatLayerTissue.seed_layer_state_for_part(part)


static func get_severance_ease_factor(entity: Node, part: String) -> float:
    var max_tissue: int = entity.body_max.get(part, 1)
    var max_bone: int = entity.bone_max.get(part, 1)
    if max_tissue <= 0 or max_bone <= 0:
        return 1.0
    var cur_cut: float = entity.body_cutting.get(part, 0.0)
    var cur_blunt: float = entity.body_blunt.get(part, 0.0)
    var cur_bone: float = entity.bone_health.get(part, 0.0)
    var tissue_ratio: float = (cur_cut + cur_blunt) / float(maxi(1, max_tissue * 2))
    var bone_ratio: float = cur_bone / float(max_bone)
    var wound_count: int = entity.wounds.get(part, []).size()
    var wound_factor: float = minf(float(wound_count) * SEVERANCE_EASE_PER_WOUND, SEVERANCE_EASE_WOUND_CAP)
    var worst_sev: String = BleedingConstants.SEVERITY_MINOR
    for injury in entity.wounds.get(part, []):
        var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MINOR)
        var order: Array = [
            BleedingConstants.SEVERITY_MINOR,
            BleedingConstants.SEVERITY_MODERATE,
            BleedingConstants.SEVERITY_SEVERE,
            BleedingConstants.SEVERITY_CRITICAL
        ]
        if order.find(sev) > order.find(worst_sev):
            worst_sev = sev
    var severity_bonus: float = SEVERANCE_EASE_SEVERITY_BONUS.get(worst_sev, 0.0)
    var severance_ease: float = (
        1.0
        + (1.0 - tissue_ratio) * SEVERANCE_EASE_TISSUE_FACTOR
        + (1.0 - bone_ratio) * SEVERANCE_EASE_BONE_FACTOR
        + wound_factor
        + severity_bonus
    )
    return clampf(severance_ease, 1.0, SEVERANCE_EASE_MAX)


static func _effective_endurance_for_damage(entity: Node) -> float:
    return EntityStatsUtil.get_effective_stat(entity, "endurance")


## Full damage-split application: armor, bone/tissue split, wounds, early severance, stump, vital death, pain shock.
## extras: strike_ke_j, hit_sub_region, hit_sub_region_seed, force_layer_tissue, force_layer_tissue_curves,
## force_material_curves, material_curve_blend_weight, force_joule_armor_budget, force_tissue_energy_pool,
## disable_layer_tissue, disable_layer_tissue_curves, disable_tissue_energy_pool, disable_joule_armor_budget (harness
## baselines).
## Returns final_* , was_deflected, mechanical_post_armor (cut+blunt sum immediately after armor, game units).
static func apply_damage_split(
    entity: Node,
    cut_pre: float,
    blunt_pre: float,
    part: String,
    penetration_sharp: float = -1.0,
    penetration_blunt_momentum_per_area: float = -1.0,
    blunt_contact_cm: float = -1.0,
    extras: Dictionary = {}
) -> Dictionary:
    var impact_ke: float = extras.get("strike_ke_j", -1.0)
    if part not in entity.body_cutting or part not in entity.body_blunt or part not in entity.bone_health:
        return {
            "final_cut": 0.0,
            "final_blunt": 0.0,
            "final_bone": 0.0,
            "was_deflected": false,
            "mechanical_post_armor": 0.0
        }
    if entity._is_part_severed(part):
        # Detached part should no longer take weapon damage. Keep/seed one stump wound and exit.
        EntityWounds.ensure_stump_wound(entity, part)
        return {
            "final_cut": 0.0,
            "final_blunt": 0.0,
            "final_bone": 0.0,
            "was_deflected": false,
            "mechanical_post_armor": 0.0
        }
    var cut_pre_val: float = maxf(0.0, cut_pre)
    var blunt_pre_val: float = maxf(0.0, blunt_pre)
    var end_resist: float = clampf(
        _effective_endurance_for_damage(entity) * ENDURANCE_DAMAGE_RESISTANCE_PER_POINT,
        0.0,
        ENDURANCE_DAMAGE_RESISTANCE_MAX
    )
    cut_pre_val *= (1.0 - end_resist)
    blunt_pre_val *= (1.0 - end_resist)
    var armor_var: Variant = entity._get_armor_for_part(part)
    var pen_s: float = penetration_sharp if penetration_sharp >= 0.0 else ArmorConstants.DEFAULT_PENETRATION_SHARP
    var joule_ke: Dictionary = {}
    var force_joule: bool = extras.get("force_joule_armor_budget", false)
    var joule_authoritative: bool = false
    if (
        ArmorJouleBudget.is_active(force_joule)
        and not extras.get("disable_joule_armor_budget", false)
        and impact_ke > 0.0
        and armor_var != null
        and armor_var.get_script() == ArmorPiece
    ):
        joule_ke = ArmorJouleBudget.account_ke_through_armor(
            armor_var, impact_ke, pen_s, cut_pre_val > 0.0, penetration_blunt_momentum_per_area, blunt_contact_cm
        )
        var ke_frac: float = joule_ke.get("transmitted_ke_fraction", 1.0)
        cut_pre_val *= ke_frac
        blunt_pre_val *= ke_frac
        joule_authoritative = true
    var final_cut: float = 0.0
    var final_blunt: float = 0.0
    var blunt_from_deflection: float = 0.0
    var blunt_from_direct: float = 0.0
    if armor_var != null and armor_var.get_script() == ArmorPiece:
        if joule_authoritative:
            final_cut = cut_pre_val
            final_blunt = blunt_pre_val
            blunt_from_direct = blunt_pre_val
            if CombatConstants.combat_debug_active():
                (
                    CombatDebug
                    . log(
                        (
                            (
                                "[Armor] %s %s: joule-authoritative cut=%.1f blunt=%.1f ke_frac=%.3f "
                                + "(scalar ArmorPiece skipped)"
                            )
                            % [
                                entity.name,
                                part,
                                final_cut,
                                final_blunt,
                                joule_ke.get("transmitted_ke_fraction", 1.0),
                            ]
                        )
                    )
                )
        else:
            var deflected_raw: float = 0.0
            if cut_pre_val > 0.0:
                var result_cut: Dictionary = armor_var.apply_damage(
                    cut_pre_val, CombatConstants.DAMAGE_TYPE_SHARP, pen_s, -1.0, -1.0
                )
                var d: float = maxf(0.0, result_cut.get("damage", 0.0))
                var dtype: String = result_cut.get("damage_type", CombatConstants.DAMAGE_TYPE_SHARP)
                if dtype == CombatConstants.DAMAGE_TYPE_SHARP:
                    final_cut += d
                else:
                    deflected_raw = result_cut.get(
                        "transmitted_blunt_amount", result_cut.get("deflected_blunt_amount", d)
                    )
                    blunt_from_deflection = deflected_raw
            blunt_from_direct = blunt_pre_val
            if deflected_raw > 0.0 and blunt_pre_val > 0.0:
                var result_deflected: Dictionary = armor_var.apply_damage(
                    deflected_raw,
                    CombatConstants.DAMAGE_TYPE_BLUNT,
                    0.0,
                    penetration_blunt_momentum_per_area,
                    blunt_contact_cm,
                    1
                )
                var result_direct: Dictionary = armor_var.apply_damage(
                    blunt_pre_val,
                    CombatConstants.DAMAGE_TYPE_BLUNT,
                    0.0,
                    penetration_blunt_momentum_per_area,
                    blunt_contact_cm,
                    0
                )
                final_blunt = (
                    maxf(0.0, result_deflected.get("damage", 0.0)) + maxf(0.0, result_direct.get("damage", 0.0))
                )
            elif deflected_raw > 0.0:
                var result_blunt: Dictionary = armor_var.apply_damage(
                    deflected_raw,
                    CombatConstants.DAMAGE_TYPE_BLUNT,
                    0.0,
                    penetration_blunt_momentum_per_area,
                    blunt_contact_cm,
                    1
                )
                final_blunt = maxf(0.0, result_blunt.get("damage", 0.0))
            elif blunt_pre_val > 0.0:
                var result_blunt: Dictionary = armor_var.apply_damage(
                    blunt_pre_val,
                    CombatConstants.DAMAGE_TYPE_BLUNT,
                    0.0,
                    penetration_blunt_momentum_per_area,
                    blunt_contact_cm,
                    0
                )
                final_blunt = maxf(0.0, result_blunt.get("damage", 0.0))
            if CombatConstants.combat_debug_active():
                (
                    CombatDebug
                    . log(
                        (
                            (
                                "[Armor] %s %s: pre cut=%.1f blunt=%.1f | transmitted_raw=%.1f direct_blunt=%.1f | "
                                + "pen_sharp=%.2f mm RHA | blunt: => post-armor cut=%.1f blunt=%.1f"
                            )
                            % [
                                entity.name,
                                part,
                                cut_pre_val,
                                blunt_pre_val,
                                deflected_raw,
                                blunt_pre_val,
                                pen_s,
                                final_cut,
                                final_blunt,
                            ]
                        )
                    )
                )
    else:
        final_cut = cut_pre_val
        final_blunt = blunt_pre_val
        blunt_from_direct = blunt_pre_val
        if CombatConstants.combat_debug_active() and (cut_pre_val > 0.0 or blunt_pre_val > 0.0):
            CombatDebug.log(
                "[Armor] %s %s: no armor => post cut=%.1f blunt=%.1f" % [entity.name, part, final_cut, final_blunt]
            )
    var total_final: float = final_cut + final_blunt
    var mechanical_post_armor: float = total_final
    if total_final <= 0.0:
        return {
            "final_cut": 0.0,
            "final_blunt": 0.0,
            "final_bone": 0.0,
            "was_deflected": false,
            "mechanical_post_armor": 0.0
        }
    var sub_region: String = extras.get("hit_sub_region", "").strip_edges()
    if sub_region.is_empty():
        var seed_key: int = int(extras.get("hit_sub_region_seed", entity.get_instance_id()))
        sub_region = CombatHitSubRegion.fallback_sub_region(part, seed_key)
    var combat_mult: float = CombatHitSubRegion.combat_damage_mult(part, sub_region)
    if combat_mult != 1.0:
        final_cut *= combat_mult
        final_blunt *= combat_mult
        total_final = final_cut + final_blunt
        mechanical_post_armor = total_final
    var pen_to_tissue: float = 0.0
    if final_cut > 0.0:
        pen_to_tissue = pen_s
        if armor_var != null and armor_var.get_script() == ArmorPiece:
            var pen_trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(armor_var, pen_s)
            pen_to_tissue = pen_trace.get("penetration_to_tissue_mm", 0.0)
    var pen_for_mfb: float = pen_to_tissue
    var layer_meta: Dictionary = {}
    var force_layer: bool = extras.get("force_layer_tissue", false)
    var force_layer_curves: bool = extras.get("force_layer_tissue_curves", false)
    if (
        final_cut > 0.0
        and not extras.get("disable_layer_tissue", false)
        and CombatLayerTissue.is_layer_penetration_active(force_layer, force_layer_curves)
    ):
        if (
            CombatLayerTissue.is_curves_active(force_layer_curves)
            and not extras.get("disable_layer_tissue_curves", false)
        ):
            var state_rows: Array = _layer_state_rows_for_part(entity, part)
            layer_meta = CombatLayerTissue.penetration_through_layers(part, pen_to_tissue, state_rows, true)
            if layer_meta.has("layer_state") and "tissue_layer_state" in entity:
                entity.tissue_layer_state[part] = layer_meta["layer_state"]
        else:
            layer_meta = CombatLayerTissue.penetration_after_soft_tissue(part, pen_to_tissue, true)
        pen_for_mfb = float(layer_meta.get("penetration_to_bone_mm", pen_to_tissue))
    var ke_blunt_bone: float = CombatLayerTissue.blunt_ke_reaching_bone(part, impact_ke)
    var mfb_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
        final_cut, final_blunt, total_final, part, sub_region, pen_for_mfb, impact_ke, ke_blunt_bone
    )
    var alloc: Dictionary = mfb_alloc
    var force_curves: bool = extras.get("force_material_curves", false)
    var curve_alloc: Dictionary = {}
    if MaterialFailureCurves.is_active(force_curves):
        curve_alloc = MaterialFailureCurves.allocate_bone_and_tissue(
            final_cut, final_blunt, total_final, part, sub_region, pen_to_tissue, pen_for_mfb, impact_ke, ke_blunt_bone
        )
        var blend_w: float = float(
            extras.get("material_curve_blend_weight", BleedingConstants.MATERIAL_CURVE_BLEND_WEIGHT)
        )
        alloc = MaterialFailureCurves.blend_allocations(mfb_alloc, curve_alloc, blend_w)
    var wound_pen_mm: float = -1.0
    if final_cut > 0.0:
        wound_pen_mm = pen_to_tissue
    var to_tissue_total: float = float(alloc.get("to_tissue_total", total_final))
    var to_bone: float = alloc.get("to_bone", 0.0)
    var to_cut: float = alloc.get("to_cut", 0.0)
    var to_blunt: float = alloc.get("to_blunt", 0.0)
    var mechanism_raw: String = str(alloc.get("mechanism", "mixed"))
    var mfb_mechanism: String = str(mfb_alloc.get("mechanism", mechanism_raw))
    var applied_mechanism: String = mechanism_raw
    var bone_threshold: int = BodyPartConstants.get_bone_damage_threshold(part, sub_region)
    var bone_fraction: float = BodyPartConstants.get_bone_damage_fraction(part, sub_region)
    var severance_ease: float = get_severance_ease_factor(entity, part)
    var cur_cut: float = entity.body_cutting.get(part, 0.0)
    var cur_blunt: float = entity.body_blunt.get(part, 0.0)
    var cur_bone: float = entity.bone_health.get(part, 0.0)
    var allocated_bone: float = to_bone
    # Per-channel ease cap prevents amplification from zeroing multiple channels.
    # When base allocation already zeros a channel (to_X >= cur_X), use ease=1.0 for that
    # channel — the hit is lethal regardless of wound factor. Otherwise, dampen the global
    # severance_ease so moderate hits can't zero two+ channels through amplification alone:
    # local_ease = 1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP.
    var cut_ease: float = 1.0 if to_cut >= cur_cut else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
    var blunt_ease: float = 1.0 if to_blunt >= cur_blunt else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
    var bone_ease: float = 1.0 if to_bone >= cur_bone else clampf(1.0 + (severance_ease - 1.0) * SEVERANCE_EASE_CHANNEL_DAMP, 1.0, severance_ease)
    to_cut = minf(entity._round_tissue(to_cut * cut_ease), cur_cut)
    to_blunt = minf(entity._round_tissue(to_blunt * blunt_ease), cur_blunt)
    to_bone = minf(entity._round_tissue(to_bone * bone_ease), cur_bone)
    var total_damage_this_hit: float = to_cut + to_blunt + to_bone
    if (
        total_damage_this_hit < float(MIN_DAMAGE_TO_SEVER)
        and (cur_cut - to_cut) <= 0.0
        and (cur_bone - to_bone) <= 0.0
        and cur_bone > 0.0
    ):
        to_bone = maxf(0.0, cur_bone - 1.0)
    var force_energy_pool: bool = extras.get("force_tissue_energy_pool", false)
    var use_energy_pool: bool = (
        TissueEnergyCapacity.is_active(force_energy_pool) and not extras.get("disable_tissue_energy_pool", false)
    )
    if use_energy_pool:
        TissueEnergyCapacity.apply_tissue_damage_to_entity(entity, part, to_cut, to_blunt)
        entity.bone_health[part] = entity._round_tissue(maxf(0.0, entity.bone_health.get(part, 0.0) - to_bone))
    else:
        entity.body_cutting[part] = entity._round_tissue(maxf(0.0, entity.body_cutting.get(part, 0.0) - to_cut))
        entity.body_blunt[part] = entity._round_tissue(maxf(0.0, entity.body_blunt.get(part, 0.0) - to_blunt))
        entity.bone_health[part] = entity._round_tissue(maxf(0.0, entity.bone_health.get(part, 0.0) - to_bone))
    var cut_after: float = entity.body_cutting.get(part, 0.0)
    var blunt_after: float = entity.body_blunt.get(part, 0.0)
    var bone_after: float = entity.bone_health.get(part, 0.0)
    if CombatConstants.combat_debug_active():
        (
            CombatDebug
            . log(
                (
                    (
                        "[Bone/tissue] %s %s (%s): mechanism=%s%s total_post_armor=%.1f | "
                        + "threshold=%d fraction=%.2f => allocated bone=%.2f tissue=%.2f | "
                        + "severance_ease=%.2f => applied cut=%.2f blunt=%.2f bone=%.2f | "
                        + "part state: cut %.2f->%.2f blunt %.2f->%.2f bone %.2f->%.2f"
                    )
                    % [
                        entity.name,
                        part,
                        sub_region,
                        mfb_mechanism,
                        " curve=%s" % applied_mechanism if force_curves else "",
                        total_final,
                        bone_threshold,
                        bone_fraction,
                        allocated_bone,
                        to_tissue_total,
                        severance_ease,
                        to_cut,
                        to_blunt,
                        to_bone,
                        cur_cut,
                        cut_after,
                        cur_blunt,
                        blunt_after,
                        cur_bone,
                        bone_after,
                    ]
                )
            )
        )
    # Stab wounds use INJURY_TYPE_STAB (narrow deep channel; forensic: stab:cut external bleed ratio ~1:2-3).
    var contact_type: String = extras.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
    if to_cut > 0.0:
        var injury_type_for_wound: String = (
            BleedingConstants.INJURY_TYPE_STAB if contact_type == WeaponConstants.ATTACK_TYPE_STAB else BleedingConstants.INJURY_TYPE_CUT
        )
        EntityWounds.add_wound(entity, part, injury_type_for_wound, to_cut, sub_region, "", impact_ke, wound_pen_mm)
    if to_blunt > 0.0:
        var total_blunt_source: float = blunt_from_deflection + blunt_from_direct
        var to_blunt_deflected: float = 0.0
        var to_blunt_direct: float = to_blunt
        if total_blunt_source > 0.0 and blunt_from_deflection > 0.0:
            to_blunt_deflected = to_blunt * blunt_from_deflection / total_blunt_source
            to_blunt_direct = to_blunt - to_blunt_deflected
        if to_blunt_deflected > 0.0:
            var sev: String = EntityWounds.severity_from_damage(entity, part, to_blunt_deflected, sub_region, impact_ke)
            if to_blunt_deflected <= float(DEFLECTION_BRUISE_THRESHOLD) or sev == BleedingConstants.SEVERITY_MINOR:
                EntityWounds.add_wound(
                    entity, part, BleedingConstants.INJURY_TYPE_BRUISE, to_blunt_deflected, sub_region, "", impact_ke
                )
            else:
                EntityWounds.add_wound(
                    entity, part, BleedingConstants.INJURY_TYPE_CRUSH, to_blunt_deflected, sub_region, "", impact_ke
                )
        if to_blunt_direct > 0.0:
            EntityWounds.add_wound(
                entity, part, BleedingConstants.INJURY_TYPE_CRUSH, to_blunt_direct, sub_region, "", impact_ke
            )
    if to_bone > 0.0:
        var fracture_severity: String = EntityWounds.severity_from_bone_damage(entity, part, to_bone)
        EntityWounds.add_wound(
            entity, part, BleedingConstants.INJURY_TYPE_FRACTURE, to_bone, sub_region, fracture_severity, impact_ke
        )
    # Concussion from head bone damage (Issue 1).
    if to_bone > 0.0 and part == BodyPartConstants.PART_HEAD:
        EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(entity, to_bone)
    var early_severed: bool = false
    if not entity._is_part_severed(part) and total_damage_this_hit >= float(MIN_DAMAGE_TO_SEVER):
        if not SEVERANCE_EARLY_LIMBS_ONLY or part not in entity._get_vital_parts():
            var max_cut: int = entity.body_max.get(part, 1)
            var max_bone: int = entity.bone_max.get(part, 1)
            var rem_cut: float = entity.body_cutting.get(part, 0.0)
            var rem_bone: float = entity.bone_health.get(part, 0.0)
            var combined_max: float = float(max_cut + max_bone)
            if combined_max > 0.0:
                var remaining_ratio: float = (rem_cut + rem_bone) / combined_max
                if remaining_ratio < SEVERANCE_EARLY_THRESHOLD and remaining_ratio > 0.0:
                    var chance: float = (
                        (SEVERANCE_EARLY_THRESHOLD - remaining_ratio)
                        / SEVERANCE_EARLY_THRESHOLD
                        * SEVERANCE_EARLY_MAX_CHANCE
                    )
                    chance = clampf(chance, 0.0, 1.0)
                    if randf() < chance:
                        # Fold the destroyed remainder into the applied allocation so the
                        # reported final_cut/final_blunt/final_bone match what was actually
                        # lost from the part (previously the remainder vanished from logs).
                        to_cut += entity.body_cutting.get(part, 0.0)
                        to_blunt += entity.body_blunt.get(part, 0.0)
                        to_bone += entity.bone_health.get(part, 0.0)
                        entity.body_cutting[part] = 0.0
                        entity.body_blunt[part] = 0.0
                        entity.bone_health[part] = 0.0
                        early_severed = true
                        total_damage_this_hit = to_cut + to_blunt + to_bone
                        CombatDebug.log(
                            (
                                (
                                    "[Severance] %s %s: early severance triggered "
                                    + "(remaining ratio < threshold) => part destroyed "
                                    + "(applied cut=%.1f blunt=%.1f bone=%.1f)"
                                )
                                % [entity.name, part, to_cut, to_blunt, to_bone]
                            )
                        )
    if entity._is_part_severed(part):
        EntityWounds.ensure_stump_wound(entity, part, sub_region)
    var vital: Array = entity._get_vital_parts()
    if part in vital and ((entity.body_cutting.get(part, 0.0) <= 0.0 and entity.body_blunt.get(part, 0.0) <= 0.0) or (entity.bone_health.get(part, 0.0) <= 0.0 and (entity.body_cutting.get(part, 0.0) <= 0.0 or entity.body_blunt.get(part, 0.0) <= 0.0))):
        EntityWounds.emit_death_once(entity)
    var pain_from_this_hit_raw: float = 0.0
    if entity._is_part_severed(part):
        var stump_damage: float = entity.body_max.get(part, 10)
        pain_from_this_hit_raw = entity._get_pain_contribution_for_wound(
            part, stump_damage, BleedingConstants.SEVERITY_CRITICAL, BleedingConstants.INJURY_TYPE_CUT, sub_region, true
        )
    else:
        if to_cut > 0.0:
            var sev_cut: String = EntityWounds.severity_from_damage(entity, part, to_cut, sub_region, impact_ke)
            pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
                part, to_cut, sev_cut, BleedingConstants.INJURY_TYPE_CUT, sub_region, false
            )
        if to_blunt > 0.0:
            var total_blunt_source: float = blunt_from_deflection + blunt_from_direct
            var to_blunt_deflected: float = 0.0
            var to_blunt_direct: float = to_blunt
            if total_blunt_source > 0.0 and blunt_from_deflection > 0.0:
                to_blunt_deflected = to_blunt * blunt_from_deflection / total_blunt_source
                to_blunt_direct = to_blunt - to_blunt_deflected
            if to_blunt_deflected > 0.0:
                var sev_def: String = EntityWounds.severity_from_damage(
                    entity, part, to_blunt_deflected, sub_region, impact_ke
                )
                var itype_def: String = (
                    BleedingConstants.INJURY_TYPE_BRUISE
                    if (
                        to_blunt_deflected <= float(DEFLECTION_BRUISE_THRESHOLD)
                        or sev_def == BleedingConstants.SEVERITY_MINOR
                    )
                    else BleedingConstants.INJURY_TYPE_CRUSH
                )
                pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
                    part, to_blunt_deflected, sev_def, itype_def, sub_region, false
                )
            if to_blunt_direct > 0.0:
                var sev_dir: String = EntityWounds.severity_from_damage(
                    entity, part, to_blunt_direct, sub_region, impact_ke
                )
                pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
                    part, to_blunt_direct, sev_dir, BleedingConstants.INJURY_TYPE_CRUSH, sub_region, false
                )
        if to_bone > 0.0:
            var sev_bone: String = EntityWounds.severity_from_bone_damage(entity, part, to_bone)
            pain_from_this_hit_raw += entity._get_pain_contribution_for_wound(
                part, to_bone, sev_bone, BleedingConstants.INJURY_TYPE_FRACTURE, sub_region, false
            )
    entity._last_hit_impact = float(total_damage_this_hit)
    entity._try_enter_pain_shock_from_hit(pain_from_this_hit_raw)
    entity._update_consciousness()
    var result: Dictionary = {
        "final_cut": to_cut,
        "final_blunt": to_blunt,
        "final_bone": to_bone,
        "was_deflected": blunt_from_deflection > 0.0,
        "mechanical_post_armor": mechanical_post_armor,
        "early_severed": early_severed,
    }
    if not joule_ke.is_empty():
        result["armor_ke_absorbed_j"] = joule_ke.get("armor_ke_absorbed_j", 0.0)
        result["armor_ke_remaining_j"] = joule_ke.get("armor_ke_remaining_j", 0.0)
        result["transmitted_ke_fraction"] = joule_ke.get("transmitted_ke_fraction", 1.0)
    if final_cut > 0.0:
        result["penetration_to_tissue_mm"] = pen_to_tissue
    if not layer_meta.is_empty():
        result["layer_absorbed_mm"] = layer_meta.get("layer_absorbed_mm", 0.0)
        result["penetration_to_bone_mm"] = float(layer_meta.get("penetration_to_bone_mm", pen_for_mfb))
        if layer_meta.has("layer_states"):
            result["layer_states"] = layer_meta["layer_states"]
    if use_energy_pool and entity.tissue_energy_remaining_j.has(part):
        result["tissue_energy_remaining_j"] = entity.tissue_energy_remaining_j.get(part, 0.0)
        result["tissue_energy_capacity_j"] = entity.tissue_energy_capacity_j.get(part, 0.0)
    if force_curves and not curve_alloc.is_empty():
        result["mfb_cut"] = mfb_alloc.get("to_cut", 0.0)
        result["mfb_blunt"] = mfb_alloc.get("to_blunt", 0.0)
        result["mfb_bone"] = mfb_alloc.get("to_bone", 0.0)
        result["curve_cut"] = curve_alloc.get("to_cut", 0.0)
        result["curve_blunt"] = curve_alloc.get("to_blunt", 0.0)
        result["curve_bone"] = curve_alloc.get("to_bone", 0.0)
    CombatF5SoakTrace.note_research_damage_outcome(part, result, extras)
    return result
