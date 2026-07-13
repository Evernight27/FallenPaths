class_name CombatCalibrationAuditPartB
extends RefCounted

## Compare shipped combat numbers to documented physics / medical anchors.
## Writes **`.calibration_audit.txt`**; optional gate via **`run_all_combat_checks.gd`**.

const HumanSpecies := preload("res://species/human.tres")
const GoblinSpecies := preload("res://species/goblin.tres")

const REPORT_FILENAME := ".calibration_audit.txt"
const BIND_THRESHOLD := CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
const DEFLECT_THRESHOLD := CombatConstants.PARRY_DEFLECT_THRESHOLD
## Soak lines tag `parry_deflect` for full-stop outcomes; `parry_bind` only when `parry_was_bind`  -  allow ctrl at
## threshold on deflect rows.
const BIND_CTRL_AUDIT_EPS := 0.001

# de Leva (1996) whole-body segment mass % (adult male reference; game uses abstract 6-part lumping).
const DE_LEVA_REFERENCE_PCT: Dictionary = {
    "head": 6.9,
    "chest_proxy_trunk": 43.5,
    "upper_arm_each": 2.7,
    "forearm_hand_lump": 5.0,
    "thigh_each": 14.2,
    "shank_foot_lump": 5.5,
}


static func _append_soak_parry_section(lines: PackedStringArray, failures: PackedStringArray, log_path: String) -> void:
    lines.append("")
    lines.append("[soak_log_parry_ctrl_vs_BIND_THRESHOLD=%.2f]" % BIND_THRESHOLD)
    if log_path.is_empty():
        lines.append("soak_log=missing (run CombatD001SoakRunner first)")
        return
    var text: String = FileAccess.get_file_as_string(log_path)
    var deflect_n: int = 0
    var bind_n: int = 0
    var partial_n: int = 0
    var bind_ctrl_ok: int = 0
    var deflect_ctrl_ok: int = 0
    var ctrl_mismatch: int = 0
    for raw in text.split("\n"):
        var line: String = str(raw)
        if "parry_deflect" in line and "ctrl=" in line:
            deflect_n += 1
            var ctrl: float = CombatCalibrationAuditPartB._parse_ctrl(line)
            if ctrl >= 0.0:
                if ctrl < DEFLECT_THRESHOLD + BIND_CTRL_AUDIT_EPS:
                    deflect_ctrl_ok += 1
                else:
                    ctrl_mismatch += 1
        elif "parry_bind" in line and "flurry_bind" not in line and "ctrl=" in line:
            bind_n += 1
            var ctrl_b: float = CombatCalibrationAuditPartB._parse_ctrl(line)
            if ctrl_b >= 0.0:
                if ctrl_b >= BIND_THRESHOLD - BIND_CTRL_AUDIT_EPS:
                    bind_ctrl_ok += 1
                else:
                    ctrl_mismatch += 1
        elif "parry_partial" in line:
            partial_n += 1
    var ii2b_slice: PackedStringArray = CombatD001TrackSpecs.slice_lines_for_soak_preset(
        CombatCalibrationAuditPartB._packed_lines(text), "ii2b"
    )
    var ii2b_stats: Dictionary = CombatD001TrackSpecs.parry_outcome_stats(ii2b_slice)
    lines.append("aggregate_log deflect=%d bind=%d partial=%d" % [deflect_n, bind_n, partial_n])
    (
        lines
        . append(
            (
                "ctrl_consistent_with_threshold=%d mismatch=%d"
                % [
                    deflect_ctrl_ok + bind_ctrl_ok,
                    ctrl_mismatch,
                ]
            )
        )
    )
    lines.append(CombatD001TrackSpecs.parry_stats_summary_line(ii2b_stats))
    lines.append(
        (
            "HEMA_plausibility_headless=%s"
            % ("pass" if CombatD001TrackSpecs.ii2b_plausibility_failures(ii2b_stats).is_empty() else "fail")
        )
    )
    var clean: int = deflect_n + bind_n
    var total_parry: int = clean + partial_n
    if total_parry > 0:
        var partial_pct: float = 100.0 * float(partial_n) / float(total_parry)
        var bind_pct: float = 100.0 * float(bind_n) / float(max(clean, 1))
        lines.append(
            "brawl_parry_mix partial=%.0f%% of %d events (bind %.0f%% of clean)" % [partial_pct, total_parry, bind_pct]
        )
        lines.append(
            (
                "clinical_read=high partial pct expected in multi-threat (misaligned guard); duel sample too small for "
                + "pct stats"
            )
        )
    if ctrl_mismatch > 0:
        failures.append(
            "soak_log: %d parry ctrl lines disagree with bind threshold %.2f" % [ctrl_mismatch, BIND_THRESHOLD]
        )


static func _append_impact_ke_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[impact_KE_vs_limb_severance]")
    var sp: SpeciesResource = HumanSpecies
    var arm_slot: int = sp.left_arm + sp.left_arm_bone
    var leg_slot: int = sp.left_leg + sp.left_leg_bone
    (
        lines
        . append(
            (
                "DAMAGE_KE_SCALE=%.1f human_arm_slot=%d leg_slot=%d design_KE_arm~%.0fJ leg~%.0fJ"
                % [
                    WeaponConstants.DAMAGE_KE_SCALE,
                    arm_slot,
                    leg_slot,
                    CombatDesignAnchors.DESIGN_KE_ARM_J,
                    CombatDesignAnchors.DESIGN_KE_LEG_J,
                ]
            )
        )
    )
    var sword: Weapon = Weapon.create_from_definition("SWORD")
    if sword == null:
        failures.append("impact_ke: could not create SWORD")
        return
    var ke_hi: float = -1.0
    for intensity in [0.5, 0.8, 1.0]:
        var ai: AttackInstance = AttackInstance.new("oberhau", intensity)
        ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai)
        var pre_cut: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai, 100.0, 1.0)
        var est_damage: float = WeaponConstants.DAMAGE_KE_SCALE * sqrt(maxf(0.0, ke_j))
        lines.append(
            (
                "oberhau_swing i=%.1f KE_J=%.0f pre_armor_cut=%.1f sqrt_KE_scale_damage=%.1f"
                % [intensity, ke_j, pre_cut, est_damage]
            )
        )
        if is_equal_approx(intensity, 1.0):
            ke_hi = ke_j
    var oberhau_move: Dictionary = WeaponConstants.get_move("oberhau")
    var oberhau_commit: float = float(oberhau_move.get("weapon_extension_commit_fraction", 0.78))
    var ai_commit: AttackInstance = AttackInstance.new("oberhau", 1.0)
    ai_commit.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai_commit.delivery_commit_fraction = oberhau_commit
    var ke_commit: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_commit)
    var pre_cut_commit: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_commit, 100.0, 1.0)
    var commit_ke_ratio: float = ke_commit / ke_hi if ke_hi > 0.01 else 0.0
    lines.append(
        (
            "delivery_commit_formula=effective_intensity=intensity*commit_frac (floor %.2f); KE from v(eff_i); blun"
            + "t slip uses full intensity" % [WeaponDamageHelper.DELIVERY_INTENSITY_FLOOR]
        )
    )
    lines.append(
        (
            "oberhau_i=1.0_commit=%.2f KE_J=%.0f pre_armor_cut=%.1f ke_ratio_vs_no_commit=%.3f"
            % [oberhau_commit, ke_commit, pre_cut_commit, commit_ke_ratio]
        )
    )
    var arm_strict_commit: bool = CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_commit)
    lines.append("audit_KE_at_i1.0_committed_J=%.0f strict_70-140J=%s" % [ke_commit, str(arm_strict_commit).to_lower()])
    var arm_strict: bool = CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_hi)
    var arm_loose: bool = ke_hi >= 40.0 and ke_hi <= 250.0
    var vs_design: float = ke_hi / CombatDesignAnchors.DESIGN_KE_ARM_J if ke_hi >= 0.0 else 0.0
    lines.append(
        (
            "audit_KE_at_i1.0_J=%.0f vs_design_arm=%.2fx (nominal %.0fJ)"
            % [ke_hi, vs_design, CombatDesignAnchors.DESIGN_KE_ARM_J]
        )
    )
    lines.append("audit_KE_arm_strict_70-140J=%s (full commit may exceed nominal)" % str(arm_strict).to_lower())
    lines.append("audit_KE_arm_loose_40-250J=%s" % str(arm_loose).to_lower())
    if ke_hi < 0.0:
        failures.append("impact_ke: no intensity 1.0 sample")
    elif not arm_loose:
        failures.append("impact_ke: sword oberhau i=1.0 KE %.0fJ outside 40-250J loose band" % ke_hi)
    lines.append("spear_thrust_vs_mace=see harness impact_station_order (tip > head-weighted blunt)")


static func _append_derived_limb_capacity_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[derived_limb_capacity_pilot]")
    lines.append(
        (
            "FEATURE_DERIVED_LIMB_CAPACITY production_default=%s (limbs only; head/chest hand-tuned)"
            % str(HumanSpecies.feature_derived_limb_capacity).to_lower()
        )
    )
    var ref_h: float = HumanSpecies.resolved_reference_mass_kg()
    var ref_g: float = GoblinSpecies.resolved_reference_mass_kg()
    for part in ["left_arm", "left_leg"]:
        var hand_t: int = HumanSpecies.get("left_arm" if part == "left_arm" else "left_leg")
        var hand_b: int = HumanSpecies.get("left_arm_bone" if part == "left_arm" else "left_leg_bone")
        var hand_t_h: int = hand_t
        var hand_b_h: int = hand_b
        var derived_t: int = SpeciesResource.derived_limb_body_max_profiled(part, ref_h, hand_t_h)
        var derived_b: int = SpeciesResource.derived_limb_bone_max_profiled(part, derived_t, hand_b_h)
        lines.append(
            (
                "human_%s hand_tissue=%d hand_bone=%d derived_tissue=%d derived_bone=%d ref_kg=%.1f"
                % [part, hand_t, hand_b, derived_t, derived_b, ref_h]
            )
        )
    var gob_arm_t: int = SpeciesResource.derived_limb_body_max_profiled("right_arm", ref_g, GoblinSpecies.right_arm)
    var hum_arm_t: int = SpeciesResource.derived_limb_body_max_profiled("right_arm", ref_h, HumanSpecies.right_arm)
    lines.append(
        (
            "goblin_right_arm derived_tissue=%d human_right_arm derived_tissue=%d (mass %.1f vs %.1f kg)"
            % [gob_arm_t, hum_arm_t, ref_g, ref_h]
        )
    )
    for part in ["right_arm", "left_leg"]:
        var hand_t_g: int = GoblinSpecies.right_arm if part == "right_arm" else GoblinSpecies.left_leg
        var hand_b_g: int = GoblinSpecies.right_arm_bone if part == "right_arm" else GoblinSpecies.left_leg_bone
        var derived_t_g: int = SpeciesResource.derived_limb_body_max_profiled(part, ref_g, hand_t_g)
        var derived_b_g: int = SpeciesResource.derived_limb_bone_max_profiled(part, derived_t_g, hand_b_g)
        lines.append(
            (
                "goblin_%s hand_tissue=%d hand_bone=%d profiled_derived_tissue=%d profiled_derived_bone=%d"
                % [part, hand_t_g, hand_b_g, derived_t_g, derived_b_g]
            )
        )
    lines.append("profile_formula=mini(mass_derived,hand_export) tissue; bone mini(ratio_bone,hand_bone)")
    lines.append(
        "pilot_note=human+goblin feature_derived_limb_capacity on; live caps = hand exports via profiled mini()"
    )


static func _parse_ctrl(line: String) -> float:
    var idx: int = line.find("ctrl=")
    if idx < 0:
        return -1.0
    var tail: String = line.substr(idx + 5).strip_edges()
    var space: int = tail.find(" ")
    if space >= 0:
        tail = tail.substr(0, space)
    return float(tail) if tail.is_valid_float() else -1.0


static func _packed_lines(text: String) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    for raw in text.split("\n"):
        var s: String = str(raw).strip_edges()
        if not s.is_empty():
            out.append(s)
    return out
