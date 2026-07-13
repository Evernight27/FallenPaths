class_name CombatRegressionHarnessSimulationPartA
extends RefCounted

## Simulation realism track (S1 - S10): `_run_sim_*`  -  docs/LIVE_PATHS.md#harness-prefixes.

const HumanSpecies := preload("res://species/human.tres")
const GoblinSpecies := preload("res://species/goblin.tres")


static func _sim_entity() -> CoreEntity:
    var ent: CoreEntity = CoreEntity.new()
    CombatRegressionHarness._track_harness_node(ent)
    return ent


static func _fail(failures: PackedStringArray, msg: String) -> void:
    CombatRegressionHarness._fail(failures, msg)


static func _oberhau_swing_instance(intensity: float, commit_frac: float) -> AttackInstance:
    var ai: AttackInstance = AttackInstance.new("oberhau", intensity)
    ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    if commit_frac >= 0.0:
        ai.delivery_commit_fraction = commit_frac
    return ai


## S1: extension commit scales KE and pre_armor_cut; intensity ordering at fixed commit.
static func _run_sim_delivery_commit_scales_ke_and_cut(failures: PackedStringArray) -> void:
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if sword == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_delivery: missing SWORD")
        return
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var commit_lo: float = 0.45
    var commit_hi: float = 0.90
    var ai_lo: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(1.0, commit_lo)
    var ai_hi: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(1.0, commit_hi)
    var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
    var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
    if ke_hi <= ke_lo + 0.5:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_delivery: commit %.2f KE %.1f should exceed commit %.2f KE %.1f" % [commit_hi, ke_hi, commit_lo, ke_lo]
        )
    var cut_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo, strength, arm_mod)
    var cut_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi, strength, arm_mod)
    if cut_hi <= cut_lo + 0.01:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_delivery: cut commit_hi=%.2f %.2f should exceed commit_lo=%.2f %.2f"
                % [commit_hi, cut_hi, commit_lo, cut_lo]
            )
        )
    var pin_commit: float = 0.78
    var ai_half: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(0.5, pin_commit)
    var ai_full: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(1.0, pin_commit)
    var ke_half: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_half)
    var ke_full: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_full)
    if ke_full <= ke_half + 0.5:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_delivery: i=1.0 KE %.1f should exceed i=0.5 KE %.1f at commit %.2f" % [ke_full, ke_half, pin_commit]
        )
    var ai_no_commit: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(1.0, -1.0)
    var ke_no: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_no_commit)
    if ke_no <= ke_full + 0.5:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_delivery: no-commit KE %.1f should exceed committed i=1.0 KE %.1f" % [ke_no, ke_full]
        )


## S1: oberhau full wind-up with move commit lands nearer design arm KE than uncommitted i=1.0.
static func _run_sim_calibration_audit_committed_ke_in_band(failures: PackedStringArray) -> void:
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if sword == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_audit_ke: missing SWORD")
        return
    var oberhau_commit: float = CombatWeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move("oberhau"))
    var ai_bare: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(1.0, -1.0)
    var ai_committed: AttackInstance = CombatRegressionHarnessSimulationPartA._oberhau_swing_instance(
        1.0, oberhau_commit
    )
    var ke_bare: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_bare)
    var ke_commit: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_committed)
    if not CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_commit):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_audit_ke: committed oberhau i=1.0 KE %.0fJ outside %s-%sj (commit=%.2f bare=%.0f)"
                % [
                    ke_commit,
                    CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MIN,
                    CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MAX,
                    oberhau_commit,
                    ke_bare
                ]
            )
        )
    var err_bare: float = absf(ke_bare - CombatDesignAnchors.DESIGN_KE_ARM_J)
    var err_commit: float = absf(ke_commit - CombatDesignAnchors.DESIGN_KE_ARM_J)
    if err_commit >= err_bare - 1.0:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_audit_ke: committed |KE-%.0f|=%.1f should beat bare %.1f (commit=%.2f bare=%.0f commit=%.0f)"
                % [CombatDesignAnchors.DESIGN_KE_ARM_J, err_commit, err_bare, oberhau_commit, ke_bare, ke_commit]
            )
        )


## S2: identical inputs yield the same sub_region (no randf on hot path).
static func _run_sim_subregion_deterministic_same_inputs(failures: PackedStringArray) -> void:
    var align: Dictionary = {"attack_angle_deg": 0.0, "guard_angle_deg": 0.0}
    var intercept_idx: int = AttackPathResolver.path_intercept_max_index("high", "high", 1.0, align)
    var a: String = CombatHitSubRegion.resolve_sub_region("right_arm", "high", "high", align, "oberhau", intercept_idx)
    var b: String = CombatHitSubRegion.resolve_sub_region("right_arm", "high", "high", align, "oberhau", intercept_idx)
    if a.is_empty() or a != b:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_subregion_det: want stable non-empty got a=%s b=%s" % [a, b]
        )


## S2: high attack vs high guard on arm path -> proximal site (upper_arm).
static func _run_sim_subregion_high_line_arm(failures: PackedStringArray) -> void:
    var align: Dictionary = {"attack_angle_deg": 0.0, "guard_angle_deg": 0.0}
    var intercept_idx: int = AttackPathResolver.path_intercept_max_index("high", "high", 1.0, align)
    var sub: String = CombatHitSubRegion.resolve_sub_region(
        "right_arm", "high", "high", align, "oberhau", intercept_idx
    )
    if sub != "upper_arm":
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_subregion_high_arm: want upper_arm got %s (intercept=%d)" % [sub, intercept_idx]
        )


## IV-10: elbow sub_region applies higher mechanical cut than upper_arm when feature on.
static func _run_iv10_subregion_combat_mult_elbow_vs_upper_arm(failures: PackedStringArray) -> void:
    var sync_line: String = CombatHitSubRegion.iv10_doc_sync_line()
    if "mechanical=severity_modifier" not in sync_line:
        CombatRegressionHarness._fail(failures, "iv10_mult: sync line missing token in %s" % sync_line)
    if not CombatConstants.is_feature_subregion_combat_mult_enabled():
        CombatRegressionHarness._fail(failures, "iv10_mult: FEATURE_SUBREGION_COMBAT_MULT must be on in production")
        return
    var cut_pre: float = 18.0
    var ent_upper: CoreEntity = CombatRegressionHarness._new_entity_unarmed()
    var ent_elbow: CoreEntity = CombatRegressionHarness._new_entity_unarmed()
    var r_upper: Dictionary = ent_upper.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "upper_arm"}
    )
    var r_elbow: Dictionary = ent_elbow.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow"}
    )
    var mech_upper: float = float(r_upper.get("mechanical_post_armor", 0.0))
    var mech_elbow: float = float(r_elbow.get("mechanical_post_armor", 0.0))
    if mech_elbow <= mech_upper + 0.05:
        CombatRegressionHarness._fail(
            failures,
            (
                "iv10_mult: elbow want higher mechanical_post_armor than upper_arm (%.2f vs %.2f)"
                % [mech_elbow, mech_upper]
            )
        )
    var mult_upper: float = CombatHitSubRegion.combat_damage_mult("right_arm", "upper_arm")
    var mult_elbow: float = CombatHitSubRegion.combat_damage_mult("right_arm", "elbow")
    if mult_elbow <= mult_upper:
        CombatRegressionHarness._fail(
            failures, "iv10_mult: elbow mult want > upper_arm (%.3f vs %.3f)" % [mult_elbow, mult_upper]
        )


## IV-10: flag off  -  identical sub_region hits apply same mechanical damage.
static func _run_iv10_subregion_combat_mult_flag_off_parity(failures: PackedStringArray) -> void:
    var cut_pre: float = 16.0
    var saved: bool = CombatConstants.is_feature_subregion_combat_mult_enabled()
    CombatConstants.set_feature_subregion_combat_mult_load(false)
    var ent_a: CoreEntity = CombatRegressionHarness._new_entity_unarmed()
    var ent_b: CoreEntity = CombatRegressionHarness._new_entity_unarmed()
    var r_a: Dictionary = ent_a.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow"}
    )
    var r_b: Dictionary = ent_b.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "forearm"}
    )
    CombatConstants.set_feature_subregion_combat_mult_load(saved)
    var mech_a: float = float(r_a.get("mechanical_post_armor", 0.0))
    var mech_b: float = float(r_b.get("mechanical_post_armor", 0.0))
    if absf(mech_a - mech_b) > 0.05:
        CombatRegressionHarness._fail(
            failures, "iv10_mult_off: flag off want parity (elbow=%.2f forearm=%.2f)" % [mech_a, mech_b]
        )


## S2: packing eligibility still works when neck sub_region is explicit (medical harness pattern).
static func _run_sim_pack_neck_requires_subregion(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 5.0, "neck", BleedingConstants.SEVERITY_MODERATE
    )
    if ent.wounds.get("head", []).size() != 1:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pack_neck: expected one neck wound")
        return
    ent.wounds["head"][0]["is_arterial"] = true
    # Compression must be held before packing when active bleed present.
    if not ent.apply_direct_pressure("head"):
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pack_neck: direct pressure setup failed")
        return
    if not ent.can_apply_packing("head"):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_pack_neck: moderate arterial neck should allow packing after pressure"
        )


static func _has_fracture_wound(ent: Node, part: String) -> bool:
    for w: Variant in ent.wounds.get(part, []):
        if w is Dictionary and str(w.get("injury_type", "")) == BleedingConstants.INJURY_TYPE_FRACTURE:
            return true
    return false


## S3: cut-dominant, low penetration -> no fracture (old pool would often chip bone).
static func _run_sim_mfb_cut_only_no_fracture(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var res: Dictionary = ent.take_damage_split(16.0, 0.0, "right_arm", 0.4, -1.0, -1.0, {"hit_sub_region": "forearm"})
    if (
        CombatRegressionHarnessSimulationPartA._has_fracture_wound(ent, "right_arm")
        or float(res.get("final_bone", 0.0)) > 0.01
    ):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_mfb_cut_low_pen: sharp-dominant low pen should not chip bone"
        )


## S3: blunt-dominant arm hit with KE above sub-region anchor -> fracture.
static func _run_sim_mfb_mace_arm_fracture(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("MACE")
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
    var strike_ke: float = j_anchor + 24.0
    var res: Dictionary = ent.take_damage_split(
        0.0, 8.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow", "strike_ke_j": strike_ke}
    )
    if (
        not CombatRegressionHarnessSimulationPartA._has_fracture_wound(ent, "right_arm")
        and float(res.get("final_bone", 0.0)) < 0.5
    ):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_mfb_mace_arm: want fracture or final_bone at KE %.1f (anchor %.1f)" % [strike_ke, j_anchor]
        )


## S3: deep cut (pen gate) allows bone; shallow pen at same cut damage does not.
static func _run_sim_mfb_deep_cut_bone_optional(failures: PackedStringArray) -> void:
    var shallow: Node = CombatRegressionHarness._new_entity("SWORD")
    var extras_mfb: Dictionary = {
        "hit_sub_region": "forearm",
        "disable_layer_tissue": true,
    }
    var res_sh: Dictionary = shallow.take_damage_split(11.0, 0.0, "right_arm", 0.5, -1.0, -1.0, extras_mfb)
    if (
        CombatRegressionHarnessSimulationPartA._has_fracture_wound(shallow, "right_arm")
        or float(res_sh.get("final_bone", 0.0)) > 0.01
    ):
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_mfb_deep_cut: shallow pen should not chip bone")
    var deep: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_dp: Dictionary = deep.take_damage_split(
        11.0, 0.0, "right_arm", CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5, -1.0, -1.0, extras_mfb
    )
    if (
        float(res_dp.get("final_bone", 0.0)) < 0.5
        and not CombatRegressionHarnessSimulationPartA._has_fracture_wound(deep, "right_arm")
    ):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_mfb_deep_cut: pen >= %.2f mm should allow cut bone chip"
                % CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM
            )
        )


static func _entity_for_species(sp: SpeciesResource) -> CoreEntity:
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._sim_entity()
    ent.species = sp
    ent.apply_species()
    return ent


## S4: same raw tissue damage -> same severity on human vs goblin arm (absolute bands on).
static func _run_sim_severity_absolute_stable(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_severity_abs: FEATURE_ABSOLUTE_SEVERITY_BANDS must be on"
        )
        return
    var dmg: float = 5.5
    var part: String = "right_arm"
    var human: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(HumanSpecies)
    var goblin: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(GoblinSpecies)
    var sev_h: String = EntityWounds.severity_from_damage(human, part, dmg, "forearm", -1.0)
    var sev_g: String = EntityWounds.severity_from_damage(goblin, part, dmg, "forearm", -1.0)
    if sev_h != sev_g:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_severity_abs: human=%s goblin=%s want same at dmg=%.1f (max hp %d vs %d)"
                % [sev_h, sev_g, dmg, int(human.body_max.get(part, 0)), int(goblin.body_max.get(part, 0))]
            )
        )
    if sev_h != BleedingConstants.SEVERITY_SEVERE:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_severity_abs: pinned dmg %.1f want severe got %s" % [dmg, sev_h]
        )
    var bone_h: String = EntityWounds.severity_from_bone_damage(human, part, 3.2)
    var bone_g: String = EntityWounds.severity_from_bone_damage(goblin, part, 3.2)
    if bone_h != bone_g or bone_h != BleedingConstants.SEVERITY_SEVERE:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_severity_abs: bone 3.2 want severe both got human=%s goblin=%s" % [bone_h, bone_g]
        )


## S4: high impact_ke_j still raises severity band vs low-KE same damage.
static func _run_sim_severity_ke_still_upgrades(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(HumanSpecies)
    var part: String = "chest"
    var dmg: float = 1.8
    var sev_low: String = EntityWounds.severity_from_damage(ent, part, dmg, "thoracic", -1.0)
    var sev_hi: String = EntityWounds.severity_from_damage(ent, part, dmg, "thoracic", 140.0)
    var order: Array = [
        BleedingConstants.SEVERITY_MINOR,
        BleedingConstants.SEVERITY_MODERATE,
        BleedingConstants.SEVERITY_SEVERE,
        BleedingConstants.SEVERITY_CRITICAL,
    ]
    if order.find(sev_hi) <= order.find(sev_low):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_severity_ke: high KE should raise band (low=%s hi=%s dmg=%.1f)" % [sev_low, sev_hi, dmg]
        )


static func _species_with_derived_flag(sp: SpeciesResource) -> SpeciesResource:
    var dup: SpeciesResource = sp.duplicate() as SpeciesResource
    dup.feature_derived_limb_capacity = true
    return dup


static func _within_pct(actual: int, expected: int, tolerance_pct: float) -> bool:
    if expected <= 0:
        return actual == expected
    var slack: int = maxi(1, int(round(float(expected) * tolerance_pct)))
    return absi(actual - expected) <= slack


## S5: human + goblin production flags on; profiled derived matches hand exports.
static func _run_sim_derived_production_species_flags(failures: PackedStringArray) -> void:
    if not HumanSpecies.feature_derived_limb_capacity:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_flag: human.tres feature_derived_limb_capacity must be true (S5 pilot)"
        )
    if not GoblinSpecies.feature_derived_limb_capacity:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_flag: goblin.tres feature_derived_limb_capacity must be true (S5 pilot)"
        )
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_tissue(HumanSpecies, part)
        var hand_b: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_bone(HumanSpecies, part)
        if HumanSpecies.get_body_part_max(part) != hand_t or HumanSpecies.get_bone_max(part) != hand_b:
            (
                CombatRegressionHarnessSimulationPartA
                . _fail(
                    failures,
                    (
                        "sim_derived_flag: human production %s tissue/bone %d/%d != hand %d/%d"
                        % [
                            part,
                            HumanSpecies.get_body_part_max(part),
                            HumanSpecies.get_bone_max(part),
                            hand_t,
                            hand_b,
                        ]
                    )
                )
            )
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t_g: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_tissue(GoblinSpecies, part)
        var hand_b_g: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_bone(GoblinSpecies, part)
        if GoblinSpecies.get_body_part_max(part) != hand_t_g or GoblinSpecies.get_bone_max(part) != hand_b_g:
            (
                CombatRegressionHarnessSimulationPartA
                . _fail(
                    failures,
                    (
                        "sim_derived_flag: goblin production %s tissue/bone %d/%d != hand %d/%d"
                        % [
                            part,
                            GoblinSpecies.get_body_part_max(part),
                            GoblinSpecies.get_bone_max(part),
                            hand_t_g,
                            hand_b_g,
                        ]
                    )
                )
            )


static func _hand_tuned_limb_tissue(sp: SpeciesResource, part: String) -> int:
    match part:
        "right_arm":
            return sp.right_arm
        "left_arm":
            return sp.left_arm
        "left_leg":
            return sp.left_leg
        "right_leg":
            return sp.right_leg
    return 0


static func _hand_tuned_limb_bone(sp: SpeciesResource, part: String) -> int:
    match part:
        "right_arm":
            return sp.right_arm_bone
        "left_arm":
            return sp.left_arm_bone
        "left_leg":
            return sp.left_leg_bone
        "right_leg":
            return sp.right_leg_bone
    return 1


## S5: derived human arm tissue/bone within +/-15% of hand-tuned 12/8 when pilot flag on.
static func _run_sim_derived_limb_capacity_human_arm_reference(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(HumanSpecies)
    var part: String = "right_arm"
    var tissue: int = sp.get_body_part_max(part)
    var bone: int = sp.get_bone_max(part)
    if not CombatRegressionHarnessSimulationPartA._within_pct(tissue, 12, 0.15):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_human_arm: tissue=%d want ~12 within 15%% (derived formula)" % tissue
        )
    if not CombatRegressionHarnessSimulationPartA._within_pct(bone, 8, 0.15):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_human_arm: bone=%d want ~8 within 15%% (derived formula)" % bone
        )
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(sp)
    if int(ent.body_max.get(part, 0)) != tissue or int(ent.bone_max.get(part, 0)) != bone:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_derived_human_arm: CoreEntity caps tissue=%d bone=%d != getters %d/%d"
                % [int(ent.body_max.get(part, 0)), int(ent.bone_max.get(part, 0)), tissue, bone]
            )
        )


## S5: derived human leg tissue/bone within +/-15% of hand-tuned 16/12 when pilot flag on.
static func _run_sim_derived_limb_capacity_human_leg_reference(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(HumanSpecies)
    var part: String = "left_leg"
    var tissue: int = sp.get_body_part_max(part)
    var bone: int = sp.get_bone_max(part)
    if not CombatRegressionHarnessSimulationPartA._within_pct(tissue, 16, 0.15):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_human_leg: tissue=%d want ~16 within 15%% (derived formula)" % tissue
        )
    if not CombatRegressionHarnessSimulationPartA._within_pct(bone, 12, 0.15):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_derived_human_leg: bone=%d want ~12 within 15%% (derived formula)" % bone
        )


## S5: lighter species gets smaller derived limb budgets than human (mass-scaled pilot).
static func _run_sim_derived_goblin_smaller_limb_than_human(failures: PackedStringArray) -> void:
    var human: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(HumanSpecies)
    var goblin: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(GoblinSpecies)
    for part in ["right_arm", "left_leg"]:
        var h_t: int = human.get_body_part_max(part)
        var g_t: int = goblin.get_body_part_max(part)
        if g_t >= h_t:
            CombatRegressionHarnessSimulationPartA._fail(
                failures, "sim_derived_goblin: %s goblin tissue=%d should be < human %d" % [part, g_t, h_t]
            )
        var h_b: int = human.get_bone_max(part)
        var g_b: int = goblin.get_bone_max(part)
        if g_b >= h_b:
            CombatRegressionHarnessSimulationPartA._fail(
                failures, "sim_derived_goblin: %s goblin bone=%d should be < human %d" % [part, g_b, h_b]
            )


## S5: profiled derived goblin limbs equal hand-tuned exports (mini mass, hand cap).
static func _run_sim_derived_goblin_limbs_match_hand_tuned(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(GoblinSpecies)
    for part in ["right_arm", "left_arm", "left_leg", "right_leg"]:
        var hand_t: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_tissue(GoblinSpecies, part)
        var hand_b: int = CombatRegressionHarnessSimulationPartA._hand_tuned_limb_bone(GoblinSpecies, part)
        if sp.get_body_part_max(part) != hand_t:
            CombatRegressionHarnessSimulationPartA._fail(
                failures,
                "sim_derived_goblin_hand: %s tissue=%d want hand-tuned %d" % [part, sp.get_body_part_max(part), hand_t]
            )
        if sp.get_bone_max(part) != hand_b:
            CombatRegressionHarnessSimulationPartA._fail(
                failures,
                "sim_derived_goblin_hand: %s bone=%d want hand-tuned %d" % [part, sp.get_bone_max(part), hand_b]
            )


## S5: pain reference uses applied entity body_max (getters), not bypassing derived caps.
static func _run_sim_derived_pain_reference_matches_entity_body_max(failures: PackedStringArray) -> void:
    var sp: SpeciesResource = CombatRegressionHarnessSimulationPartA._species_with_derived_flag(HumanSpecies)
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(sp)
    var from_entity: float = sp.get_pain_reference(ent.body_max)
    var from_getters: float = sp.live_pain_reference()
    if not is_equal_approx(from_entity, from_getters):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_derived_pain_ref: entity body_max sum pain ref %.3f != getter dict %.3f" % [from_entity, from_getters]
        )


## S6: layer KE walk conserves strike_ke_j = absorbed + remaining.
static func _run_sim_joule_armor_ke_conserved(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_joule_ke: missing CUIRASS")
        return
    var strike_ke: float = 120.0
    var pen: float = 2.0
    var r: Dictionary = ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
    var absorbed: float = float(r.get("armor_ke_absorbed_j", 0.0))
    var remaining: float = float(r.get("armor_ke_remaining_j", 0.0))
    if not is_equal_approx(absorbed + remaining, strike_ke):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_joule_ke: absorbed %.1f + remaining %.1f != strike %.1f" % [absorbed, remaining, strike_ke]
        )


## S6: plate kit bleeds less KE through than gambeson at same pen (sharp deflect path).
static func _run_sim_joule_armor_cuirass_absorbs_more_than_gambeson(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    var gambeson: ArmorPiece = ArmorPiece.create_from_definition("GAMBESON")
    if cuirass == null or gambeson == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_joule_armor: missing CUIRASS or GAMBESON")
        return
    var strike_ke: float = 100.0
    var pen: float = 2.0
    var heavy: Dictionary = ArmorJouleBudget.account_ke_through_armor(cuirass, strike_ke, pen, true)
    var light: Dictionary = ArmorJouleBudget.account_ke_through_armor(gambeson, strike_ke, pen, true)
    var rem_heavy: float = float(heavy.get("armor_ke_remaining_j", strike_ke))
    var rem_light: float = float(light.get("armor_ke_remaining_j", strike_ke))
    if rem_heavy >= rem_light - 0.5:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_joule_armor: cuirass remaining KE %.1f should be < gambeson %.1f" % [rem_heavy, rem_light]
        )


## S10: joule-authoritative path matches ke_frac - -  pre (no second scalar ArmorPiece pass).
static func _run_sim_joule_armor_authoritative_ke_frac(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    var armor: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if armor == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_joule_authoritative: missing CUIRASS")
        return
    ent.equip_armor("chest", armor)
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var extras: Dictionary = {"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
    var res: Dictionary = EntityDamage.apply_damage_split(ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0, extras)
    var frac: float = float(res.get("transmitted_ke_fraction", -1.0))
    var mech: float = float(res.get("mechanical_post_armor", 0.0))
    var want_mech: float = cut_pre * frac
    if frac < 0.0:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_joule_authoritative: missing transmitted_ke_fraction on result"
        )
    if want_mech > 0.01 and absf(mech - want_mech) > want_mech * 0.15:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_joule_authoritative: mech %.2f want cut*frac=%.2f (frac=%.3f)" % [mech, want_mech, frac]
        )
    if float(res.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_joule_authoritative: want armor_ke_absorbed_j > 1 when forced"
        )


## S10: joule path must not double-absorb below ke_frac floor (regression guard).
static func _run_sim_joule_armor_not_below_ke_frac_floor(failures: PackedStringArray) -> void:
    var armor: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if armor == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_joule_floor: missing CUIRASS")
        return
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var joule_ke: Dictionary = ArmorJouleBudget.account_ke_through_armor(armor, strike_ke, 2.0, true)
    var frac: float = float(joule_ke.get("transmitted_ke_fraction", 1.0))
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    ent.equip_armor("chest", armor)
    var res: Dictionary = EntityDamage.apply_damage_split(
        ent, cut_pre, 0.0, "chest", 2.0, -1.0, -1.0, {"strike_ke_j": strike_ke, "force_joule_armor_budget": true}
    )
    var mech: float = float(res.get("mechanical_post_armor", 0.0))
    var floor_mech: float = cut_pre * frac * 0.92
    if mech < floor_mech - 0.05:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_joule_floor: mech %.2f below ke_frac floor %.2f (double-absorb regression)" % [mech, floor_mech]
        )


static func _harness_entity_with_ml_pool(sp: SpeciesResource) -> CoreEntity:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._sim_entity()
    ent.species = sp
    ent.apply_species()
    return ent


## S6 literal blood: mL max scales with species reference mass (human 75 kg -> 5250 mL via `CombatDesignAnchors`).
static func _run_sim_blood_ml_pool_human_goblin_mass_scale(failures: PackedStringArray) -> void:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var human: CoreEntity = CombatRegressionHarnessSimulationPartA._harness_entity_with_ml_pool(HumanSpecies)
    var goblin: CoreEntity = CombatRegressionHarnessSimulationPartA._harness_entity_with_ml_pool(GoblinSpecies)
    var hum_max: float = human.blood_volume_ml_max
    var gob_max: float = goblin.blood_volume_ml_max
    if not is_equal_approx(hum_max, BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_blood_ml: human max want %.0f got %.0f" % [BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT, hum_max]
        )
    if gob_max >= hum_max - 1.0:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml: goblin max %.0f should be < human %.0f" % [gob_max, hum_max]
        )
    var want_gob: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(38.0)
    if not is_equal_approx(gob_max, want_gob):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml: goblin max want %.0f got %.0f" % [want_gob, gob_max]
        )
    BloodVolumeMl._harness_force_literal_blood_ml = false


## S6: same bleed rate -> same seconds-to-death in % mode vs mL mode (ATLS bridge).
static func _run_sim_blood_ml_ttd_matches_percent_mode(failures: PackedStringArray) -> void:
    var rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ttd_pct: float = BleedingConstants.seconds_to_exsanguination(rate, BleedingConstants.MAX_BLOOD_VOLUME, 1.0)
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent_ml: CoreEntity = CombatRegressionHarnessSimulationPartA._harness_entity_with_ml_pool(HumanSpecies)
    var max_ml: float = ent_ml.blood_volume_ml_max
    var buffer_ml: float = (
        max_ml
        * (
            (BleedingConstants.MAX_BLOOD_VOLUME - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
            / BleedingConstants.MAX_BLOOD_VOLUME
        )
    )
    var loss_ml_s: float = BloodVolumeMl.blood_ml_loss_per_second(rate, max_ml, 1.0)
    var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
    BloodVolumeMl._harness_force_literal_blood_ml = false
    if not is_equal_approx(ttd_pct, ttd_ml):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml_ttd: percent %.1fs vs ml %.1fs (rate=%.2f)" % [ttd_pct, ttd_ml, rate]
        )


## S6: one process_blood_loss tick keeps blood_volume % in sync with mL pool.
static func _run_sim_blood_ml_sync_percent_from_ml(failures: PackedStringArray) -> void:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._harness_entity_with_ml_pool(HumanSpecies)
    ent.take_damage_split(8.0, 2.0, "right_arm")
    ent.blood_volume_ml = ent.blood_volume_ml_max * 0.6
    BloodVolumeMl.sync_percent_from_ml(ent)
    if not is_equal_approx(ent.blood_volume, 60.0):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml_sync: 60%% pool want blood_volume=60 got %.2f" % ent.blood_volume
        )
    var rate: float = EntityWounds.get_total_bleeding_rate(ent)
    if rate <= 0.0:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_blood_ml_sync: need bleed rate")
        return
    var ml_before: float = ent.blood_volume_ml
    var pct_before: float = ent.blood_volume
    ent._set_combat_blood_loss_mult(1.0)
    EntityWounds.process_blood_loss(ent, 1.0)
    var want_loss_pct: float = rate * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER
    var want_loss_ml: float = BloodVolumeMl.blood_ml_loss_per_second(rate, ent.blood_volume_ml_max, 1.0)
    if not is_equal_approx(pct_before - ent.blood_volume, want_loss_pct):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml_sync: pct loss %.3f want %.3f" % [pct_before - ent.blood_volume, want_loss_pct]
        )
    if not is_equal_approx(ml_before - ent.blood_volume_ml, want_loss_ml):
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_blood_ml_sync: ml loss %.1f want %.1f" % [ml_before - ent.blood_volume_ml, want_loss_ml]
        )


## Death signal fires once per entity (map bleed / repeated process_blood_loss ticks).
static func _run_sim_notify_died_emits_once(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._sim_entity()
    var fired_box: Array = [0]
    ent.died.connect(func() -> void: fired_box[0] = int(fired_box[0]) + 1)
    ent._notify_died()
    ent._notify_died()
    if int(fired_box[0]) != 1:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "notify_died: want 1 died signal got %d" % int(fired_box[0])
        )
    var bleed_ent: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    bleed_ent.take_damage_split(6.0, 2.0, "chest")
    if EntityWounds.get_total_bleeding_rate(bleed_ent) <= 0.0:
        CombatRegressionHarnessSimulationPartA._fail(failures, "notify_died: need bleed rate on wounded entity")
        return
    bleed_ent.blood_volume = 36.0
    bleed_ent._set_combat_blood_loss_mult(1.0)
    bleed_ent._set_combat_blood_recovery_per_s(0.0)
    var bleed_fired: Array = [0]
    bleed_ent.died.connect(func() -> void: bleed_fired[0] = int(bleed_fired[0]) + 1)
    for _i in range(24):
        EntityWounds.process_blood_loss(bleed_ent, 1.0)
    if int(bleed_fired[0]) != 1:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "notify_died: blood_loss ticks want 1 died signal got %d" % int(bleed_fired[0])
        )
    bleed_ent.apply_species()
    var refire_box: Array = [0]
    bleed_ent.died.connect(func() -> void: refire_box[0] = int(refire_box[0]) + 1)
    bleed_ent._notify_died()
    if int(refire_box[0]) != 1:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "notify_died: apply_species should allow one new died signal got %d" % int(refire_box[0])
        )


## S6 layer tissue: shallow penetration absorbed by soft-tissue budget -> less bone via MFB pen gate.
static func _run_sim_layer_tissue_shallow_pen_reduces_bone(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue = true
    var part: String = "right_arm"
    var sub: String = "forearm"
    var cut: float = 14.0
    var pen_mid: float = 6.0
    var off: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen_mid, -1.0)
    var layer: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, pen_mid, true)
    var on: Dictionary = (
        CombatDamageMechanism
        . allocate_bone_and_tissue(
            cut,
            0.0,
            cut,
            part,
            sub,
            float(layer.get("penetration_to_bone_mm", pen_mid)),
            -1.0,
        )
    )
    CombatLayerTissue._harness_force_layer_tissue = false
    if float(layer.get("penetration_to_bone_mm", -1.0)) >= CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
        (
            CombatRegressionHarnessSimulationPartA
            . _fail(
                failures,
                (
                    "sim_layer_tissue_shallow: pen %.1f absorbed should leave to_bone < %.2f got %.2f"
                    % [
                        pen_mid,
                        CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM,
                        float(layer.get("penetration_to_bone_mm", 0.0)),
                    ]
                )
            )
        )
    if float(off.get("to_bone", 0.0)) <= 0.0:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_layer_tissue_shallow: need baseline bone from pen for comparison"
        )
    if float(on.get("to_bone", 0.0)) >= float(off.get("to_bone", 0.0)):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_layer_tissue_shallow: layer on bone %.2f should be < off %.2f"
                % [float(on.get("to_bone", 0.0)), float(off.get("to_bone", 0.0))]
            )
        )


## S6 layer tissue: penetration beyond budget reaches bone MFB pen threshold.
static func _run_sim_layer_tissue_deep_pen_reaches_bone(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue = true
    var part: String = "right_arm"
    var sub: String = "forearm"
    var cut: float = 14.0
    var pen_deep: float = 8.0
    var layer: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, pen_deep, true)
    var pen_bone: float = float(layer.get("penetration_to_bone_mm", 0.0))
    if pen_bone < CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_layer_tissue_deep: pen_to_bone %.2f want >= %.2f"
                % [pen_bone, CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM]
            )
        )
    var alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen_bone, -1.0)
    CombatLayerTissue._harness_force_layer_tissue = false
    if float(alloc.get("to_bone", 0.0)) < 0.5:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_layer_tissue_deep: want bone chip at pen %.1f (to_bone=%.2f)"
                % [pen_deep, float(alloc.get("to_bone", 0.0))]
            )
        )


## S7: armor layer stack consumes RHA depth  -  shallow pen stopped before tissue.
static func _run_sim_pen_trace_cuirass_stops_shallow(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pen_trace: missing CUIRASS")
        return
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 3.0)
    if not bool(trace.get("stopped_by_armor", false)):
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pen_trace: pen 3 mm should stop on cuirass plate")
    if float(trace.get("penetration_to_tissue_mm", -1.0)) > 0.01:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_pen_trace: shallow pen tissue mm want 0 got %.2f" % float(trace.get("penetration_to_tissue_mm", 0.0))
        )


## S7: pen beyond cloth+plate stack reaches tissue with remainder.
static func _run_sim_pen_trace_cuirass_deep_reaches_tissue(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pen_trace_deep: missing CUIRASS")
        return
    var pen_deep: float = 6.0
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, pen_deep)
    var to_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
    var want_remainder: float = pen_deep - 0.9 - 3.5
    if not is_equal_approx(to_tissue, want_remainder):
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            "sim_pen_trace_deep: tissue pen %.2f want ~%.2f (cloth+plate consumed)" % [to_tissue, want_remainder]
        )


## S7: post-armor tissue pen gates sharp-dominant MFB bone (cuirass vs bare pen).
static func _run_sim_pen_entity_damage_armor_reduces_bone(failures: PackedStringArray) -> void:
    var armor: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if armor == null:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pen_damage: missing CUIRASS")
        return
    var pen: float = 5.0
    var cut: float = 14.0
    var part: String = "chest"
    var sub: String = "thoracic"
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(armor, pen)
    var pen_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
    var bare_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen, -1.0)
    var arm_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
        cut, 0.0, cut, part, sub, pen_tissue, -1.0
    )
    if float(bare_alloc.get("to_bone", 0.0)) <= 0.0:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_pen_damage: bare MFB want bone at pen %.1f" % pen)
    if float(arm_alloc.get("to_bone", 0.0)) >= float(bare_alloc.get("to_bone", 0.0)) - 0.01:
        CombatRegressionHarnessSimulationPartA._fail(
            failures,
            (
                "sim_pen_damage: armored sharp bone %.2f should be < bare %.2f (tissue pen %.2f)"
                % [float(arm_alloc.get("to_bone", 0.0)), float(bare_alloc.get("to_bone", 0.0)), pen_tissue]
            )
        )


## S7: ATLS hemorrhage class boundaries (remaining blood %).
static func _run_sim_atls_consciousness_class_boundaries(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
        CombatRegressionHarnessSimulationPartA._fail(
            failures, "sim_atls: FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS must be on"
        )
        return
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(90.0) != 1:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: 90%% remaining want class I")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(75.0) != 2:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: 75%% remaining want class II")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(65.0) != 3:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: 65%% remaining want class III")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(50.0) != 4:
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: 50%% remaining want class IV")
    var mod_85: float = BleedingConstants.blood_consciousness_modifier_from_remaining(
        85.0,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )
    var mod_35: float = BleedingConstants.blood_consciousness_modifier_from_remaining(
        35.0,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )
    if not is_equal_approx(mod_85, 1.0):
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: mod at 85%% want 1.0 got %.3f" % mod_85)
    if not is_equal_approx(mod_35, 0.5):
        CombatRegressionHarnessSimulationPartA._fail(failures, "sim_atls: mod at 35%% want 0.5 got %.3f" % mod_35)


## S7: blood-loss consciousness modifier decreases monotonically with volume loss.
static func _run_sim_atls_consciousness_monotonic(failures: PackedStringArray) -> void:
    var ent: CoreEntity = CombatRegressionHarnessSimulationPartA._entity_for_species(HumanSpecies)
    var prev: float = 1.0
    for pct in [100.0, 85.0, 80.0, 70.0, 65.0, 55.0, 40.0, 35.0]:
        ent.blood_volume = pct
        var mod: float = EntityPainConsciousness.get_blood_consciousness_modifier(ent)
        if mod > prev + 0.001:
            CombatRegressionHarnessSimulationPartA._fail(
                failures, "sim_atls_mono: mod %.3f at %.0f%% > prev %.3f (non-monotonic)" % [mod, pct, prev]
            )
        prev = mod

## S8: shallow post-armor penetration -> lower cut severity than deep track at same damage.
