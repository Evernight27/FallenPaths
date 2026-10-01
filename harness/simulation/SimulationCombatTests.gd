class_name SimulationCombatTests

extends SimulationCombatBase

## S1 strike-delivery realism: committed KE / cut composition, subregion
## determinism, IV10 combat multipliers, pack-neck subregion gate, MFB
## fracture rules, and severity stability under KE upgrades.


static func _run_sim_delivery_commit_scales_ke_and_cut(failures: PackedStringArray) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        SimulationCombatTests._fail(failures, "sim_delivery: missing SWORD")
        return
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var commit_lo: float = 0.45
    var commit_hi: float = 0.90
    var ai_lo: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, commit_lo)
    var ai_hi: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, commit_hi)
    var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
    var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
    if ke_hi <= ke_lo + TOLERANCE_KE_J:
        SimulationCombatTests._fail(
            failures,
            "sim_delivery: commit %.2f KE %.1f should exceed commit %.2f KE %.1f" % [commit_hi, ke_hi, commit_lo, ke_lo]
        )
    var cut_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo, strength, arm_mod)
    var cut_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi, strength, arm_mod)
    if cut_hi <= cut_lo + TOLERANCE_SHARP:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_delivery: cut commit_hi=%.2f %.2f should exceed commit_lo=%.2f %.2f"
                % [commit_hi, cut_hi, commit_lo, cut_lo]
            )
        )
    var pin_commit: float = 0.78
    var ai_half: AttackInstance = SimulationCombatBase._oberhau_swing_instance(0.5, pin_commit)
    var ai_full: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, pin_commit)
    var ke_half: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_half)
    var ke_full: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_full)
    if ke_full <= ke_half + TOLERANCE_KE_J:
        SimulationCombatTests._fail(
            failures,
            "sim_delivery: i=1.0 KE %.1f should exceed i=0.5 KE %.1f at commit %.2f" % [ke_full, ke_half, pin_commit]
        )
    var ai_no_commit: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, -1.0)
    var ke_no: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_no_commit)
    if ke_no <= ke_full + TOLERANCE_KE_J:
        SimulationCombatTests._fail(
            failures, "sim_delivery: no-commit KE %.1f should exceed committed i=1.0 KE %.1f" % [ke_no, ke_full]
        )


## S1: oberhau full wind-up with move commit lands nearer design arm KE than uncommitted i=1.0.


static func _run_sim_calibration_audit_committed_ke_in_band(failures: PackedStringArray) -> void:
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        SimulationCombatTests._fail(failures, "sim_audit_ke: missing SWORD")
        return
    var oberhau_commit: float = CombatWeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move("oberhau"))
    var ai_bare: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, -1.0)
    var ai_committed: AttackInstance = SimulationCombatBase._oberhau_swing_instance(1.0, oberhau_commit)
    var ke_bare: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_bare)
    var ke_commit: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_committed)
    if not CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_commit):
        SimulationCombatTests._fail(
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
    if err_commit > err_bare + 3.0:
        SimulationCombatTests._fail(
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
        SimulationCombatTests._fail(failures, "sim_subregion_det: want stable non-empty got a=%s b=%s" % [a, b])


## S2: high attack vs high guard on arm path -> proximal site (upper_arm).


static func _run_sim_subregion_high_line_arm(failures: PackedStringArray) -> void:
    var align: Dictionary = {"attack_angle_deg": 0.0, "guard_angle_deg": 0.0}
    var intercept_idx: int = AttackPathResolver.path_intercept_max_index("high", "high", 1.0, align)
    var sub: String = CombatHitSubRegion.resolve_sub_region(
        "right_arm", "high", "high", align, "oberhau", intercept_idx
    )
    if sub != "upper_arm":
        SimulationCombatTests._fail(
            failures, "sim_subregion_high_arm: want upper_arm got %s (intercept=%d)" % [sub, intercept_idx]
        )


## IV-10: elbow sub_region applies higher mechanical cut than upper_arm when feature on.


static func _run_iv10_subregion_combat_mult_elbow_vs_upper_arm(failures: PackedStringArray) -> void:
    var sync_line: String = CombatHitSubRegion.iv10_doc_sync_line()
    if "mechanical=severity_modifier" not in sync_line:
        _fail(failures, "iv10_mult: sync line missing token in %s" % sync_line)
    if not CombatConstants.is_feature_subregion_combat_mult_enabled():
        _fail(failures, "iv10_mult: FEATURE_SUBREGION_COMBAT_MULT must be on in production")
        return
    var cut_pre: float = 18.0
    var ent_upper: CoreEntity = HarnessFixtures._new_entity_unarmed()
    var ent_elbow: CoreEntity = HarnessFixtures._new_entity_unarmed()
    var r_upper: Dictionary = ent_upper.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "upper_arm"}
    )
    var r_elbow: Dictionary = ent_elbow.take_damage_split(
        cut_pre, 0.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow"}
    )
    var mech_upper: float = float(r_upper.get("mechanical_post_armor", 0.0))
    var mech_elbow: float = float(r_elbow.get("mechanical_post_armor", 0.0))
    if mech_elbow <= mech_upper + 0.05:
        _fail(
            failures,
            (
                "iv10_mult: elbow want higher mechanical_post_armor than upper_arm (%.2f vs %.2f)"
                % [mech_elbow, mech_upper]
            )
        )
    var mult_upper: float = CombatHitSubRegion.combat_damage_mult("right_arm", "upper_arm")
    var mult_elbow: float = CombatHitSubRegion.combat_damage_mult("right_arm", "elbow")
    if mult_elbow <= mult_upper:
        _fail(failures, "iv10_mult: elbow mult want > upper_arm (%.3f vs %.3f)" % [mult_elbow, mult_upper])


## IV-10: flag off  -  identical sub_region hits apply same mechanical damage.


static func _run_iv10_subregion_combat_mult_flag_off_parity(failures: PackedStringArray) -> void:
    var cut_pre: float = 16.0
    var saved: bool = CombatConstants.is_feature_subregion_combat_mult_enabled()
    CombatConstants.set_feature_subregion_combat_mult_load(false)
    var ent_a: CoreEntity = HarnessFixtures._new_entity_unarmed()
    var ent_b: CoreEntity = HarnessFixtures._new_entity_unarmed()
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
        _fail(failures, "iv10_mult_off: flag off want parity (elbow=%.2f forearm=%.2f)" % [mech_a, mech_b])


## S2: packing eligibility still works when neck sub_region is explicit (medical harness pattern).


static func _run_sim_pack_neck_requires_subregion(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 5.0, "neck", BleedingConstants.SEVERITY_MODERATE
    )
    if ent.wounds.get("head", []).size() != 1:
        SimulationCombatTests._fail(failures, "sim_pack_neck: expected one neck wound")
        return
    ent.wounds["head"][0]["is_arterial"] = true
    # Compression must be held before packing when active bleed present.
    if not ent.apply_direct_pressure("head"):
        SimulationCombatTests._fail(failures, "sim_pack_neck: direct pressure setup failed")
        return
    if not ent.can_apply_packing("head"):
        SimulationCombatTests._fail(
            failures, "sim_pack_neck: moderate arterial neck should allow packing after pressure"
        )


static func _run_sim_mfb_cut_only_no_fracture(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var res: Dictionary = ent.take_damage_split(16.0, 0.0, "right_arm", 0.4, -1.0, -1.0, {"hit_sub_region": "forearm"})
    if SimulationCombatBase._has_fracture_wound(ent, "right_arm") or float(res.get("final_bone", 0.0)) > 0.01:
        SimulationCombatTests._fail(failures, "sim_mfb_cut_low_pen: sharp-dominant low pen should not chip bone")


## S3: blunt-dominant arm hit with KE above sub-region anchor -> fracture.


static func _run_sim_mfb_mace_arm_fracture(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("MACE")
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
    var strike_ke: float = j_anchor + 24.0
    var res: Dictionary = ent.take_damage_split(
        0.0, 8.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow", "strike_ke_j": strike_ke}
    )
    if not SimulationCombatBase._has_fracture_wound(ent, "right_arm") and float(res.get("final_bone", 0.0)) < 0.5:
        SimulationCombatTests._fail(
            failures, "sim_mfb_mace_arm: want fracture or final_bone at KE %.1f (anchor %.1f)" % [strike_ke, j_anchor]
        )


## S3: deep cut (pen gate) allows bone; shallow pen at same cut damage does not.


static func _run_sim_mfb_deep_cut_bone_optional(failures: PackedStringArray) -> void:
    var shallow: Node = _new_entity("SWORD")
    var extras_mfb: Dictionary = {
        "hit_sub_region": "forearm",
        "disable_layer_tissue": true,
    }
    var res_sh: Dictionary = shallow.take_damage_split(11.0, 0.0, "right_arm", 0.5, -1.0, -1.0, extras_mfb)
    if SimulationCombatBase._has_fracture_wound(shallow, "right_arm") or float(res_sh.get("final_bone", 0.0)) > 0.01:
        SimulationCombatTests._fail(failures, "sim_mfb_deep_cut: shallow pen should not chip bone")
    var deep: Node = _new_entity("SWORD")
    var res_dp: Dictionary = deep.take_damage_split(
        11.0, 0.0, "right_arm", CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5, -1.0, -1.0, extras_mfb
    )
    if float(res_dp.get("final_bone", 0.0)) < 0.5 and not SimulationCombatBase._has_fracture_wound(deep, "right_arm"):
        SimulationCombatTests._fail(
            failures,
            (
                "sim_mfb_deep_cut: pen >= %.2f mm should allow cut bone chip"
                % CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM
            )
        )


static func _run_sim_severity_absolute_stable(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS:
        SimulationCombatTests._fail(failures, "sim_severity_abs: FEATURE_ABSOLUTE_SEVERITY_BANDS must be on")
        return
    var dmg: float = 5.5
    var part: String = "right_arm"
    var human: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var goblin: CoreEntity = SimulationCombatBase._entity_for_species(GoblinSpecies)
    var sev_h: String = EntityWounds.severity_from_damage(human, part, dmg, "forearm", -1.0)
    var sev_g: String = EntityWounds.severity_from_damage(goblin, part, dmg, "forearm", -1.0)
    if sev_h != sev_g:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_severity_abs: human=%s goblin=%s want same at dmg=%.1f (max hp %d vs %d)"
                % [sev_h, sev_g, dmg, int(human.body_max.get(part, 0)), int(goblin.body_max.get(part, 0))]
            )
        )
    if sev_h != BleedingConstants.SEVERITY_SEVERE:
        SimulationCombatTests._fail(failures, "sim_severity_abs: pinned dmg %.1f want severe got %s" % [dmg, sev_h])
    var bone_h: String = EntityWounds.severity_from_bone_damage(human, part, 3.2)
    var bone_g: String = EntityWounds.severity_from_bone_damage(goblin, part, 3.2)
    if bone_h != bone_g or bone_h != BleedingConstants.SEVERITY_SEVERE:
        SimulationCombatTests._fail(
            failures, "sim_severity_abs: bone 3.2 want severe both got human=%s goblin=%s" % [bone_h, bone_g]
        )


## S4: high impact_ke_j still raises severity band vs low-KE same damage.


static func _run_sim_severity_ke_still_upgrades(failures: PackedStringArray) -> void:
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
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
        SimulationCombatTests._fail(
            failures, "sim_severity_ke: high KE should raise band (low=%s hi=%s dmg=%.1f)" % [sev_low, sev_hi, dmg]
        )
