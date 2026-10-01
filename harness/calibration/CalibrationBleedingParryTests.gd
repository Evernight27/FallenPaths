class_name CalibrationBleedingParryTests
extends RefCounted
## Compare shipped combat numbers to documented physics / medical anchors.
## Writes **`.calibration_audit.txt`**; optional gate via **`run_all_combat_checks.gd`**.

const HumanSpecies := preload("res://resources/species/human.tres")
const GoblinSpecies := preload("res://resources/species/goblin.tres")
const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

const REPORT_FILENAME := ".calibration_audit.txt"
const BIND_THRESHOLD := CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
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


static func _resolve_soak_log_path(explicit: String) -> String:
    if not explicit.is_empty() and FileAccess.file_exists(explicit):
        return explicit
    var root: String = ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
    var default_path: String = "%s/.f5_soak_in.txt" % root
    if FileAccess.file_exists(default_path):
        return default_path
    return ""


static func _write_report(body: String) -> void:
    var path: String = ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
    path = "%s/%s" % [path, REPORT_FILENAME]
    var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if f != null:
        f.store_string(body)
        f.close()
    print("FP_HARNESS_SUMMARY: wrote %s" % path)


static func _append_bleeding_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[bleeding_vs_ATLS]")
    var ttd: float = BleedingConstants.seconds_to_exsanguination(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, BleedingConstants.MAX_BLOOD_VOLUME, 1.0
    )
    var loss_per_s: float = BleedingConstants.blood_volume_loss_per_second(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, 1.0
    )
    lines.append(
        (
            "reference_uncontrolled_rate=%.2f HP/s loss_per_s=%.3f %%/s TTD_s=%.1f"
            % [BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, loss_per_s, ttd]
        )
    )
    lines.append(
        (
            "ATLS_death_threshold_remaining=%.0f%% (~%.0f%% lost; Class IV begins >40%% lost at <60%% remaining)"
            % [BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD, 100.0 - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD]
        )
    )
    (
        lines
        . append(
            (
                "reference_bleed_formula=critical_cut(%.2f)*head(%.2f)*arterial(%.2f)=%.2f_HP_per_s"
                % [
                    float(
                        BleedingConstants.BLEEDING_RATES[BleedingConstants.INJURY_TYPE_CUT][
                            BleedingConstants.SEVERITY_CRITICAL
                        ]
                    ),
                    float(BleedingConstants.BODY_PART_BLEEDING_MULTIPLIERS["head"]),
                    BleedingConstants.BLEEDING_TYPE_RATE_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL],
                    BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE,
                ]
            )
        )
    )
    lines.append("clinical_TTD_band_untreated_arterial=120-300s (order-of-minutes)")
    var derived_mult: float = CombatResearchAnchors.derived_blood_loss_multiplier_for_ttd(
        CombatResearchAnchors.LITERATURE_TTD_TARGET_S
    )
    (
        lines
        . append(
            (
                "blood_loss_multiplier_shipped=%.3f derived_for_48s=%.4f matches=%s"
                % [
                    BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER,
                    derived_mult,
                    str(CombatResearchAnchors.blood_loss_multiplier_matches_derived()).to_lower(),
                ]
            )
        )
    )
    var ttd_ok: bool = ttd >= 120.0 and ttd <= 300.0
    lines.append("audit_TTD_in_clinical_band=%s" % str(ttd_ok).to_lower())
    if not ttd_ok:
        failures.append("bleeding: reference TTD %.1fs outside 120-300s" % ttd)
    var pressure_ttd: float = ttd * 2.0
    lines.append("estimated_TTD_with_sustained_pressure_halve=%.0fs" % pressure_ttd)
    CalibrationBleedingParryTests._append_literal_blood_ml_section(lines)
    (
        lines
        . append(
            (
                "triage_danger_remaining=%.0f%% peril=%.0f%%"
                % [
                    BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING,
                    BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING,
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "triage_ATLS_class_IV_window=%s class_III_min=%.0f%% death=%.0f%%"
                % [
                    str(CombatResearchAnchors.medical_triage_blood_bands_in_class_iv_window()).to_lower(),
                    BleedingConstants.ATLS_CLASS_III_MIN_REMAINING,
                    BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD,
                ]
            )
        )
    )


static func _append_literal_blood_ml_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[literal_blood_ml_pilot]")
    lines.append("FEATURE_LITERAL_BLOOD_ML=%s" % str(BleedingConstants.FEATURE_LITERAL_BLOOD_ML).to_lower())
    var ref_h: float = HumanSpecies.resolved_reference_mass_kg()
    var ref_g: float = GoblinSpecies.resolved_reference_mass_kg()
    var hum_ml: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_h)
    var gob_ml: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(ref_g)
    lines.append(
        "human_blood_ml_max=%.0f ref_kg=%.1f goblin_blood_ml_max=%.0f ref_kg=%.1f" % [hum_ml, ref_h, gob_ml, ref_g]
    )
    var rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ttd_s: float = BleedingConstants.seconds_to_exsanguination(rate)
    lines.append(
        (
            "reference_uncontrolled_bleed_rate=%.2f TTD_to_death_threshold_s=%.1f (percent and mL bridge match)"
            % [rate, ttd_s]
        )
    )
    var implied_ml_s: float = CombatResearchAnchors.reference_uncontrolled_implied_ml_per_second(ref_h, 1.0)
    var implied_ml_min: float = implied_ml_s * 60.0
    lines.append("reference_implied_ml_per_s=%.2f implied_ml_per_min=%.1f" % [implied_ml_s, implied_ml_min])
    lines.append("note=HP_per_s_is_abstract_game_unit; implied_mL_is_percent_bridge_only; clinical_TTD_band=120-300s")
    lines.append("bridge=loss_ml_per_s = (rate * BLOOD_LOSS_RATE_MULTIPLIER) * ml_max / MAX_BLOOD_VOLUME")
    var bleed_deriv: Dictionary = CombatResearchAnchors.reference_bleed_rate_derivation()
    (
        lines
        . append(
            (
                "reference_bleed_product=%.2f cut_crit=%.1f head_mult=%.1f arterial_mult=%.1f matches_const=%s"
                % [
                    float(bleed_deriv.get("product_hp_per_s", 0.0)),
                    float(bleed_deriv.get("critical_cut_hp_per_s", 0.0)),
                    float(bleed_deriv.get("head_part_mult", 0.0)),
                    float(bleed_deriv.get("arterial_mult", 0.0)),
                    str(bool(bleed_deriv.get("matches_reference_const", false))).to_lower(),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "blood_loss_multiplier_shipped=%.3f derived=%.4f matches=%s clinical_ttd_s=%.1f ml_parity=%s"
                % [
                    float(bleed_deriv.get("shipped_blood_loss_multiplier", 0.0)),
                    float(bleed_deriv.get("derived_blood_loss_multiplier", 0.0)),
                    str(bool(bleed_deriv.get("multiplier_matches_derived", false))).to_lower(),
                    float(bleed_deriv.get("clinical_ttd_s", 0.0)),
                    str(bool(bleed_deriv.get("ml_ttd_parity_ok", false))).to_lower(),
                ]
            )
        )
    )
    CalibrationBleedingParryTests._append_layer_tissue_section(lines)
    CalibrationBleedingParryTests._append_penetration_pipeline_section(lines)
    CalibrationBleedingParryTests._append_wound_depth_section(lines)
    CalibrationBleedingParryTests._append_material_failure_curves_section(lines)
    CalibrationBleedingParryTests._append_layer_tissue_curves_section(lines)


static func _append_layer_tissue_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[layer_tissue_pilot]")
    lines.append("FEATURE_LAYER_TISSUE=%s" % str(BleedingConstants.FEATURE_LAYER_TISSUE).to_lower())
    var arm_stack: Array = CombatLayerTissue.soft_tissue_layer_stack_mm("right_arm")
    var arm_pen: Dictionary = CombatLayerTissue.penetration_after_soft_tissue("right_arm", 6.0, true)
    (
        lines
        . append(
            (
                "right_arm soft_tissue_stack_mm=%s budget=%.1f pen=6 absorbed=%.1f to_bone=%.1f"
                % [
                    str(arm_stack),
                    CombatLayerTissue.soft_tissue_budget_mm("right_arm"),
                    float(arm_pen.get("layer_absorbed_mm", 0.0)),
                    float(arm_pen.get("penetration_to_bone_mm", 0.0)),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "pen_depth_arterial_mult shallow=%.2f deep=%.2f"
                % [
                    BleedingConstants.penetration_depth_arterial_mult(0.8),
                    BleedingConstants.penetration_depth_arterial_mult(6.0),
                ]
            )
        )
    )
    lines.append("note=2-sheet stack (subcut+muscle); flat budget when curves off; full FEM deferred")


static func _append_penetration_pipeline_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[penetration_pipeline_s7]")
    lines.append(
        (
            "FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS=%s"
            % str(BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS).to_lower()
        )
    )
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if cuirass != null:
        var shallow: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 3.0)
        var deep: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 6.0)
        (
            lines
            . append(
                (
                    "cuirass_pen3_tissue_mm=%.2f stopped=%s pen6_tissue_mm=%.2f"
                    % [
                        float(shallow.get("penetration_to_tissue_mm", 0.0)),
                        str(shallow.get("stopped_by_armor", false)).to_lower(),
                        float(deep.get("penetration_to_tissue_mm", 0.0)),
                    ]
                )
            )
        )
    lines.append("order=armor RHA depth budget -> soft tissue (FEATURE_LAYER_TISSUE) -> MFB bone pen")
    (
        lines
        . append(
            (
                "atls_class_85=%d mod=%.2f atls_class_50=%d mod=%.2f"
                % [
                    BleedingConstants.atls_hemorrhage_class_from_remaining_pct(85.0),
                    BleedingConstants.blood_consciousness_modifier_from_remaining(
                        85.0,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
                    ),
                    BleedingConstants.atls_hemorrhage_class_from_remaining_pct(50.0),
                    BleedingConstants.blood_consciousness_modifier_from_remaining(
                        50.0,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
                        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
                    ),
                ]
            )
        )
    )


static func _append_wound_depth_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[wound_depth_s8]")
    (
        lines
        . append(
            (
                "FEATURE_PENETRATION_DEPTH_SEVERITY=%s FEATURE_BLUNT_TISSUE_KE_GATE=%s"
                % [
                    str(BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY).to_lower(),
                    str(BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE).to_lower(),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "pen_depth_mult pen=0.8mm=%.2f pen=6mm=%.2f arterial_mult_deep=%.2f arm_blunt_ke_budget_J=%.0f"
                % [
                    BleedingConstants.penetration_depth_severity_mult(0.8),
                    BleedingConstants.penetration_depth_severity_mult(6.0),
                    BleedingConstants.penetration_depth_arterial_mult(6.0),
                    float(CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get("right_arm", 22.0)),
                ]
            )
        )
    )


static func _append_material_failure_curves_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[material_failure_curves_pilot]")
    lines.append(
        "FEATURE_MATERIAL_FAILURE_CURVES=%s" % str(BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES).to_lower()
    )
    var part: String = "right_arm"
    var sub: String = "forearm"
    var pen_shallow: float = 0.8
    var pen_deep: float = 6.0
    var ke_ref: float = MaterialFailureCurves.reference_committed_arm_ke_j()
    (
        lines
        . append(
            (
                "cut_tissue_pen0.8=%.2f pen6=%.2f depth_mult_0.8=%.2f depth_mult_6=%.2f"
                % [
                    MaterialFailureCurves.cut_tissue_damage_from_pen(pen_shallow, part),
                    MaterialFailureCurves.cut_tissue_damage_from_pen(pen_deep, part),
                    MaterialFailureCurves.penetration_depth_mult(pen_shallow),
                    MaterialFailureCurves.penetration_depth_mult(pen_deep),
                ]
            )
        )
    )
    var bone_ke: float = MaterialFailureCurves.blunt_bone_damage_from_ke(ke_ref, part, sub)
    var anchor_j: float = CombatDamageMechanism.blunt_fracture_j_anchor(part, sub)
    lines.append(
        "blunt_bone_ke137_J=%.2f anchor_J=%.0f excess_J=%.1f" % [bone_ke, anchor_j, maxf(0.0, ke_ref - anchor_j)]
    )
    lines.append(
        (
            (
                "law=cut piecewise yield=%.1f ultimate=%.1f mm; blunt bone = MFB j_excess; depth mult delegates Bleedin"
                + "gConstants"
            )
            % [MaterialFailureCurves.CUT_TISSUE_YIELD_PEN_MM, MaterialFailureCurves.cut_tissue_ultimate_pen_mm()]
        )
    )


static func _append_layer_tissue_curves_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[layer_tissue_curves_m3]")
    (
        lines
        . append(
            (
                "FEATURE_LAYER_TISSUE_CURVES=%s FEATURE_LAYER_TISSUE=%s"
                % [
                    str(BleedingConstants.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
                    str(BleedingConstants.FEATURE_LAYER_TISSUE).to_lower(),
                ]
            )
        )
    )
    var state: Array = CombatLayerTissue.seed_layer_state_for_part("right_arm")
    var shallow: Dictionary = CombatLayerTissue.penetration_through_layers("right_arm", 0.5, state, true)
    var deep_state: Array = CombatLayerTissue.seed_layer_state_for_part("right_arm")
    var deep: Dictionary = CombatLayerTissue.penetration_through_layers("right_arm", 2.5, deep_state, true)
    var sh_states: Array = shallow.get("layer_states", [])
    var dp_states: Array = deep.get("layer_states", [])
    var sh_sub: String = str(sh_states[0].get("state", "?")) if not sh_states.is_empty() else "?"
    var dp_sub: String = str(dp_states[0].get("state", "?")) if not dp_states.is_empty() else "?"
    (
        lines
        . append(
            (
                "arm_pen0.5_to_bone=%.2f subcut_state=%s pen2.5_subcut=%s to_bone=%.2f"
                % [
                    float(shallow.get("penetration_to_bone_mm", 0.0)),
                    sh_sub,
                    dp_sub,
                    float(deep.get("penetration_to_bone_mm", 0.0)),
                ]
            )
        )
    )
    lines.append(
        (
            "note=tissue_layer_state reset on apply_species; ruptured subcut bleed mult=%.2f"
            % BleedingConstants.LAYER_RUPTURE_SUBCUT_BLEED_MULT
        )
    )


static func _append_material_failure_production_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[material_failure_production]")
    lines.append("M4_damage_D=cancelled (M3 layer curves sufficient; see Decision log)")
    (
        lines
        . append(
            (
                (
                    "production_flags curves=%s layer_curves=%s layer_tissue=%s damage_D=%s "
                    + "energy_pool=%s joule_armor=%s literal_blood_ml=%s"
                )
                % [
                    str(BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
                    str(BleedingConstants.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
                    str(BleedingConstants.FEATURE_LAYER_TISSUE).to_lower(),
                    str(BleedingConstants.FEATURE_TISSUE_DAMAGE_D).to_lower(),
                    str(BleedingConstants.FEATURE_TISSUE_ENERGY_POOL).to_lower(),
                    str(CombatConstants.FEATURE_JOULE_ARMOR_BUDGET).to_lower(),
                    str(BleedingConstants.FEATURE_LITERAL_BLOOD_ML).to_lower(),
                ]
            )
        )
    )
    lines.append(
        (
            "enablement_order=1 curves 2 layer_tissue 3 layer_curves 4 damage_D(cancelled) 5 energy_pool 6 joule_armor "
            + "7 literal_blood_ml"
        )
    )
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        failures.append("material_production: FEATURE_JOULE_ARMOR_BUDGET must be true (S11-A)")
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        failures.append("material_production: FEATURE_LITERAL_BLOOD_ML must be true (S11-B)")
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES and not BleedingConstants.FEATURE_LAYER_TISSUE:
        failures.append("material_production: FEATURE_LAYER_TISSUE_CURVES requires FEATURE_LAYER_TISSUE true")
    var ttd_s: float = BleedingConstants.seconds_to_exsanguination(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, BleedingConstants.MAX_BLOOD_VOLUME, 1.0
    )
    var ttd_ok: bool = ttd_s >= 120.0 and ttd_s <= 300.0
    lines.append("audit_TTD_s=%.1f in_band_120-300=%s" % [ttd_s, str(ttd_ok).to_lower()])
    if not ttd_ok:
        failures.append("material_production: TTD %.1fs outside 120-300s" % ttd_s)
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword != null:
        var ai: AttackInstance = AttackInstance.new("oberhau", 1.0)
        ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
        ai.delivery_commit_fraction = 0.78
        var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai)
        var ke_ok: bool = CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_j)
        lines.append(
            (
                "committed_oberhau_ke_J=%.0f strict_%.0f-%.0f=%s"
                % [
                    ke_j,
                    CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MIN,
                    CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MAX,
                    str(ke_ok).to_lower()
                ]
            )
        )
        if not ke_ok:
            failures.append(
                (
                    "material_production: committed oberhau KE %.0f outside %.0f-%.0f J"
                    % [
                        ke_j,
                        CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MIN,
                        CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MAX
                    ]
                )
            )
    var arm_pen6: Dictionary = CalibrationBleedingParryTests._material_failure_reference_arm_pen6()
    (
        lines
        . append(
            (
                "reference_arm_pen6_to_bone=%.2f curve_cut_pen6=%.2f"
                % [
                    float(arm_pen6.get("penetration_to_bone_mm", 0.0)),
                    MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, "right_arm"),
                ]
            )
        )
    )
    lines.append(CombatCalibrationAudit.material_failure_headless_gate_line())
    CalibrationBleedingParryTests._append_tissue_energy_pool_section(lines, failures)


static func _material_failure_reference_arm_pen6() -> Dictionary:
    var part: String = "right_arm"
    var pen: float = 6.0
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        var arm_state: Array = CombatLayerTissue.seed_layer_state_for_part(part)
        return CombatLayerTissue.penetration_through_layers(part, pen, arm_state, true)
    if BleedingConstants.FEATURE_LAYER_TISSUE:
        return CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
    return {"penetration_to_bone_mm": pen}


static func _append_tissue_energy_pool_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[tissue_energy_pool_m6]")
    lines.append("FEATURE_TISSUE_ENERGY_POOL=%s" % str(BleedingConstants.FEATURE_TISSUE_ENERGY_POOL).to_lower())
    var part: String = "right_arm"
    var body_max: int = CombatDesignAnchors.REFERENCE_HUMAN_ARM_TISSUE_DISPLAY
    var cap_j: float = TissueEnergyCapacity.capacity_j_for_part(part, body_max)
    var display_half: float = TissueEnergyCapacity.display_tissue_from_remaining_j(body_max, cap_j * 0.5, cap_j)
    lines.append(
        (
            "human_arm_anchor body_max=%d capacity_J=%.0f display_at_50pct_J=%.0f (target ~6)"
            % [body_max, cap_j, display_half]
        )
    )
    var parity: Dictionary = CombatCalibrationAudit.tissue_energy_hp_vs_j_parity_metrics()
    var tissue_j: float = float(parity.get("tissue_applied_j", 0.0))
    var tissue_hp: float = float(parity.get("tissue_applied_hp", 0.0))
    var parity_ok: bool = CalibrationBleedingParryTests._damage_within_pct_tolerance(tissue_hp, tissue_j, 0.05)
    lines.append(
        (
            "production_hit_tissue_applied_J=%.2f HP_path=%.2f within_5pct=%s"
            % [tissue_j, tissue_hp, str(parity_ok).to_lower()]
        )
    )
    lines.append(
        (
            "note=J synced from cut+blunt displays (dual-stream severance); extras.disable_tissue_energy_pool for HP ba"
            + "seline"
        )
    )
    if BleedingConstants.FEATURE_TISSUE_ENERGY_POOL and not parity_ok:
        failures.append("tissue_energy: J path tissue %.2f vs HP path %.2f outside 5%%" % [tissue_j, tissue_hp])


static func _damage_within_pct_tolerance(baseline: float, actual: float, pct: float) -> bool:
    if baseline <= 0.01:
        return actual <= 0.01
    return absf(actual - baseline) <= baseline * pct


## Compare production J debit vs classic HP pools on same hit (harness/audit).


static func _append_production_sim_flags_inventory(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[production_sim_flags]")
    (
        lines
        . append(
            (
                "material_curves=%s layer_tissue=%s layer_curves=%s tissue_energy_pool=%s tissue_damage_D=%s"
                % [
                    str(BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES).to_lower(),
                    str(BleedingConstants.FEATURE_LAYER_TISSUE).to_lower(),
                    str(BleedingConstants.FEATURE_LAYER_TISSUE_CURVES).to_lower(),
                    str(BleedingConstants.FEATURE_TISSUE_ENERGY_POOL).to_lower(),
                    str(BleedingConstants.FEATURE_TISSUE_DAMAGE_D).to_lower(),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                (
                    "pen_depth=%s blunt_tissue_ke=%s atls_stepped=%s absolute_severity=%s "
                    + "joule_armor=%s literal_blood_ml=%s"
                )
                % [
                    str(BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY).to_lower(),
                    str(BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE).to_lower(),
                    str(BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS).to_lower(),
                    str(BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS).to_lower(),
                    str(CombatConstants.FEATURE_JOULE_ARMOR_BUDGET).to_lower(),
                    str(BleedingConstants.FEATURE_LITERAL_BLOOD_ML).to_lower(),
                ]
            )
        )
    )
    (
        lines
        . append(
            (
                "species_derived_limb human=%s goblin=%s"
                % [
                    str(HumanSpecies.feature_derived_limb_capacity).to_lower(),
                    str(GoblinSpecies.feature_derived_limb_capacity).to_lower(),
                ]
            )
        )
    )
    lines.append("doc=docs/LIVE_PATHS.md#tier-5-simulation-flags-2026-05")


static func _append_research_benchmarks_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[research_benchmarks]")
    lines.append(
        "purpose=compare_shipped_constants_to_ATLS_biomechanics_anatomy_literature; harness _run_research_* gates drift"
    )
    CombatResearchAnchors.append_research_benchmark_lines(lines)
    var human_total: int = HumanSpecies.live_tissue_sum()
    var pct_head: float = 100.0 * float(HumanSpecies.head) / float(human_total)
    (
        lines
        . append(
            (
                "de_leva_head_pct=%.1f game_head_lump_pct=%.1f chest_proxy_trunk=%.1f verdict=%s"
                % [
                    DE_LEVA_REFERENCE_PCT["head"],
                    pct_head,
                    DE_LEVA_REFERENCE_PCT["chest_proxy_trunk"],
                    "note" if absf(pct_head - DE_LEVA_REFERENCE_PCT["head"]) > 4.0 else "pass",
                ]
            )
        )
    )
    lines.append("doc=docs/LIVE_PATHS.md#research-audit . core/CombatResearchAnchors.gd")


static func _audit_new_entity(weapon_id: String) -> CoreEntity:
    var ent: CoreEntity = CoreEntity.new()
    ent.apply_species()
    ent.dominant_hand = "right_arm"
    ent.offhand_functionality = 1.0
    var w: Weapon = HarnessFixtures.get_cached_weapon(weapon_id)
    if w != null:
        ent.equip_weapon(w)
    HarnessFixtures._track_harness_node(ent)
    return ent


## M5 F5 proxy: forearm graze  -  shallow pen, no bone chip (production stack).


static func _append_formation_diagram_vitals_section(lines: PackedStringArray) -> void:
    lines.append("")
    lines.append("[formation_diagram_vitals]")
    lines.append("bar_width=PartyRowFormatter.total_body_health_ratio tissue+bone remaining 0-1")
    lines.append("bar_fill=PartyRowFormatter.body_functionality_ratio green_to_red via formation_health_bar_fill_color")
    lines.append("refresh=BattleScene._tactical_diagram_signature hp fn rank file + tactical hints")
    lines.append("harness=form_health_bar body damage + form_health_tint arm function loss")
    lines.append("FORMATION_HEALTH_BAR_HEIGHT=%d px" % BattleUIConstants.FORMATION_HEALTH_BAR_HEIGHT)


static func _append_f5_scenario_headless_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[f5_scenario_headless]")
    lines.append("purpose=M5_playtest_proxies_full_entity_path; F5_feel_still_optional")
    var graze: Dictionary = CombatCalibrationAudit.f5_forearm_graze_metrics()
    var graze_ok: bool = (
        float(graze.get("final_bone", 0.0)) < 0.01
        and float(graze.get("final_cut", 0.0)) > 0.0
        and float(graze.get("penetration_to_tissue_mm", 0.0)) <= 1.0
    )
    (
        lines
        . append(
            (
                "forearm_graze pen=0.5 final_bone=%.2f final_cut=%.2f tissue_pen=%.2f verdict=%s"
                % [
                    float(graze.get("final_bone", 0.0)),
                    float(graze.get("final_cut", 0.0)),
                    float(graze.get("penetration_to_tissue_mm", 0.0)),
                    "pass" if graze_ok else "warn",
                ]
            )
        )
    )
    if not graze_ok:
        failures.append("f5_headless: forearm graze want no bone and shallow tissue pen")
    var chest: Dictionary = CombatCalibrationAudit.f5_armored_chest_metrics()
    var chest_ok: bool = (
        (
            float(chest.get("armored_tissue_pen_mm", 99.0)) < float(chest.get("bare_tissue_pen_mm", 0.0)) - 0.01
            or bool(chest.get("armor_stopped", false))
        )
        and float(chest.get("armored_damage_sum", 99.0)) < float(chest.get("bare_damage_sum", 0.0)) - 0.5
    )
    (
        lines
        . append(
            (
                (
                    "armored_chest bare_pen=%.2f armored_pen=%.2f bare_dmg=%.1f armored_dmg=%.1f "
                    + "ke_frac=%.3f ke_absorbed_J=%.0f verdict=%s"
                )
                % [
                    float(chest.get("bare_tissue_pen_mm", 0.0)),
                    float(chest.get("armored_tissue_pen_mm", 0.0)),
                    float(chest.get("bare_damage_sum", 0.0)),
                    float(chest.get("armored_damage_sum", 0.0)),
                    float(chest.get("transmitted_ke_fraction", -1.0)),
                    float(chest.get("armor_ke_absorbed_j", 0.0)),
                    "pass" if chest_ok else "warn",
                ]
            )
        )
    )
    if CombatConstants.FEATURE_JOULE_ARMOR_BUDGET and float(chest.get("transmitted_ke_fraction", -1.0)) < 0.0:
        failures.append("f5_headless: armored chest missing transmitted_ke_fraction with joule armor on")
    if not chest_ok:
        failures.append("f5_headless: cuirass should reduce chest pen or total damage")
    var mace: Dictionary = CombatCalibrationAudit.f5_mace_elbow_metrics()
    var mace_ok: bool = float(mace.get("final_bone", 0.0)) >= 0.5
    (
        lines
        . append(
            (
                "mace_elbow KE=%.0f anchor=%.0f final_bone=%.2f verdict=%s"
                % [
                    float(mace.get("strike_ke_j", 0.0)),
                    float(mace.get("j_anchor", 0.0)),
                    float(mace.get("final_bone", 0.0)),
                    "pass" if mace_ok else "warn",
                ]
            )
        )
    )
    if not mace_ok:
        failures.append("f5_headless: mace elbow want bone chip at KE above anchor")
    lines.append(
        "F5_editor_feel=optional; headless_proxies=%s" % ("pass" if graze_ok and chest_ok and mace_ok else "review")
    )


static func _append_species_pain_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[species_human_goblin]")
    lines.append("source_human=res://resources/species/human.tres source_goblin=res://resources/species/goblin.tres")
    var human: SpeciesResource = HumanSpecies
    var human_total: int = human.live_tissue_sum()
    var pct_head: float = 100.0 * float(human.get_body_part_max("head")) / float(human_total)
    var pct_chest: float = 100.0 * float(human.get_body_part_max("chest")) / float(human_total)
    var pct_arm: float = 100.0 * float(human.get_body_part_max("left_arm")) / float(human_total)
    var pct_leg: float = 100.0 * float(human.get_body_part_max("left_leg")) / float(human_total)
    lines.append(
        (
            "human_tissue_pct head=%.1f chest=%.1f arm_each=%.1f leg_each=%.1f sum=%d"
            % [pct_head, pct_chest, pct_arm, pct_leg, human_total]
        )
    )
    lines.append(
        (
            "de_leva_whole_body_pct head=%.1f trunk~%.1f (game chest=%.1f is trunk subset)"
            % [DE_LEVA_REFERENCE_PCT["head"], DE_LEVA_REFERENCE_PCT["chest_proxy_trunk"], pct_chest]
        )
    )
    var ordering_ok: bool = (
        human.get_body_part_max("chest") > human.get_body_part_max("head")
        and human.get_body_part_max("chest") > human.get_body_part_max("left_leg")
    )
    lines.append("human_chest_largest_segment=%s" % str(ordering_ok).to_lower())
    if not ordering_ok:
        failures.append("species: human chest should be largest tissue segment")
    if human.pain_reference_scale > 0.0:
        failures.append("species: human pain_reference_scale should be -1 (auto)")
    lines.append("human_pain_reference_scale=%.1f" % human.pain_reference_scale)
    var human_pain_ref: float = human.live_pain_reference()
    lines.append("human_pain_reference_auto=%.2f (divisor 32)" % human_pain_ref)
    lines.append(
        "NRS_first_effect_threshold=%.1f (PainConsciousnessConstants)" % PainConsciousnessConstants.NRS_FIRST_EFFECT
    )
    var moderate_damage: float = 6.0
    var effective_one_hit: float = moderate_damage / maxf(human_pain_ref, 0.01)
    lines.append(
        (
            "human_one_moderate_hit_effective_pain=%.2f (~%.1f hits to NRS 4)"
            % [effective_one_hit, PainConsciousnessConstants.NRS_FIRST_EFFECT / maxf(effective_one_hit, 0.01)]
        )
    )
    if not CombatResearchAnchors.human_live_tissue_sum_matches_design_anchor():
        failures.append("species: human tissue sum want 96 got %d" % human_total)
    if not is_equal_approx(human_pain_ref, 3.0):
        failures.append("species: human pain_reference want 3.0 got %.3f" % human_pain_ref)
    var goblin: SpeciesResource = GoblinSpecies
    var goblin_total: int = goblin.live_tissue_sum()
    if goblin.pain_reference_scale > 0.0:
        failures.append("species: goblin pain_reference_scale should be -1 (auto)")
    lines.append("goblin_pain_reference_scale=%.1f" % goblin.pain_reference_scale)
    var goblin_pain_ref: float = goblin.live_pain_reference()
    lines.append("goblin_tissue_sum=%d goblin_pain_reference_auto=%.2f" % [goblin_total, goblin_pain_ref])
    if not CombatResearchAnchors.goblin_live_tissue_sum_in_band():
        (
            failures
            . append(
                (
                    "species: goblin tissue sum out of band got %d want [%d-%d]"
                    % [
                        goblin_total,
                        CombatResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MIN,
                        CombatResearchAnchors.GOBLIN_LIVE_TISSUE_SUM_MAX,
                    ]
                )
            )
        )
    var want_goblin_ref: float = float(goblin_total) / 32.0
    if not is_equal_approx(goblin_pain_ref, want_goblin_ref):
        failures.append("species: goblin pain_reference want %.3f got %.3f" % [want_goblin_ref, goblin_pain_ref])
    var below_human: bool = goblin_pain_ref < human_pain_ref - 0.05
    lines.append("goblin_pain_below_human=%s" % str(below_human).to_lower())
    if not below_human:
        failures.append(
            "species: goblin pain_reference %.3f should be below human %.3f" % [goblin_pain_ref, human_pain_ref]
        )
    var human_mass: float = WeaponDamageHelper.reference_body_mass_kg_from_species(human)
    var goblin_mass: float = WeaponDamageHelper.reference_body_mass_kg_from_species(goblin)
    lines.append("human_reference_body_mass_kg=%.1f" % human_mass)
    lines.append("goblin_reference_body_mass_kg=%.1f" % goblin_mass)
    if not CombatResearchAnchors.human_reference_mass_matches_design_anchor():
        failures.append(
            "species: human body mass want %.1f got %.1f" % [CombatDesignAnchors.REFERENCE_ADULT_MASS_KG, human_mass]
        )
    if not CombatResearchAnchors.goblin_reference_mass_matches_anchor():
        failures.append(
            (
                "species: goblin body mass want %.1f got %.1f"
                % [CombatResearchAnchors.GOBLIN_REFERENCE_MASS_KG, goblin_mass]
            )
        )
    if not CombatResearchAnchors.goblin_mass_below_human():
        failures.append("species: goblin body mass %.1f should be below human %.1f" % [goblin_mass, human_mass])
    var human_blunt_chest: float = human_mass * 0.28
    var goblin_blunt_chest: float = goblin_mass * 0.28
    lines.append(
        (
            "human_blunt_chest_kg_est=%.2f goblin_blunt_chest_kg_est=%.2f (chest fraction 0.28)"
            % [human_blunt_chest, goblin_blunt_chest]
        )
    )


static func _append_parry_formula_section(lines: PackedStringArray, failures: PackedStringArray) -> void:
    lines.append("")
    lines.append("[parry_physics_nominal_sword]")
    lines.append(
        (
            "PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f"
            % [CombatConstants.PARRY_DEFLECT_THRESHOLD, CombatConstants.PARRY_BIND_CONTROL_THRESHOLD]
        )
    )
    var pa_nom: float = 8.0
    var cd_nom: float = 12.0
    var margin: float = CombatConstants.parry_deflect_margin_ratio(cd_nom, pa_nom)
    var ctrl: float = CombatConstants.parry_control_for_bind_deflect(cd_nom, pa_nom, 0.85, 1.0, false, false, "cut")
    (
        lines
        . append(
            (
                "nominal_pa=%.1f cd=%.1f margin_ratio=%.2f control=%.2f -> %s"
                % [
                    pa_nom,
                    cd_nom,
                    margin,
                    ctrl,
                    "bind" if ctrl >= BIND_THRESHOLD else "deflect",
                ]
            )
        )
    )
    var pa_marginal: float = 10.0
    var cd_marginal: float = pa_marginal * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
    var ctrl_m: float = CombatConstants.parry_control_for_bind_deflect(
        cd_marginal, pa_marginal, 0.75, 1.0, false, false, "cut"
    )
    lines.append(
        (
            "marginal_stop pa=%.1f cd=%.1f margin=%.2f control=%.2f"
            % [pa_marginal, cd_marginal, CombatConstants.parry_deflect_margin_ratio(cd_marginal, pa_marginal), ctrl_m]
        )
    )
    lines.append(CombatConstants.p4d_parry_bind_doc_sync_line())
    if ctrl >= BIND_THRESHOLD and ctrl_m < BIND_THRESHOLD:
        lines.append("formula_ordering=OK (decisive bind > marginal deflect at align 0.75)")
    elif ctrl < BIND_THRESHOLD and ctrl_m >= BIND_THRESHOLD:
        failures.append("parry_formula: nominal vs marginal control ordering inverted")
    else:
        lines.append(
            (
                (
                    "formula_note=marginal_stop can still bind when alignment high (%.2f>=%.2f); brawl partials use "
                    + "leak path"
                )
                % [ctrl_m, BIND_THRESHOLD]
            )
        )
