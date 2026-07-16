class_name CombatCalibrationAudit
extends RefCounted
## Compare shipped combat numbers to documented physics / medical anchors.
## Writes **`.calibration_audit.txt`**; optional gate via **`run_all_combat_checks.gd`**.

const HumanSpecies := preload("res://resources/species/human.tres")
const GoblinSpecies := preload("res://resources/species/goblin.tres")

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


static func run_and_write_report(soak_log_path: String = "") -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    var lines: PackedStringArray = PackedStringArray()
    lines.append("--- FP_CALIBRATION_AUDIT —")
    lines.append("purpose=physics_and_medical_anchor_comparison")
    CalibrationBleedingParryTests._append_bleeding_section(lines, failures)
    CalibrationBleedingParryTests._append_species_pain_section(lines, failures)
    CalibrationImpactKeTests._append_impact_ke_section(lines, failures)
    CalibrationImpactKeTests._append_derived_limb_capacity_section(lines)
    CalibrationBleedingParryTests._append_parry_formula_section(lines, failures)
    CalibrationImpactKeTests._append_soak_parry_section(
        lines, failures, CalibrationBleedingParryTests._resolve_soak_log_path(soak_log_path)
    )
    CalibrationBleedingParryTests._append_material_failure_production_section(lines, failures)
    CalibrationBleedingParryTests._append_production_sim_flags_inventory(lines)
    CalibrationBleedingParryTests._append_research_benchmarks_section(lines)
    CalibrationBleedingParryTests._append_formation_diagram_vitals_section(lines)
    CalibrationBleedingParryTests._append_f5_scenario_headless_section(lines, failures)
    lines.append("failures=%d" % failures.size())
    for msg in failures:
        lines.append("FAIL: %s" % msg)
    lines.append("ok=%s" % str(failures.is_empty()).to_lower())
    lines.append("--- END FP_CALIBRATION_AUDIT —")
    var body: String = "\n".join(lines) + "\n"
    CalibrationBleedingParryTests._write_report(body)
    return {"ok": failures.is_empty(), "failures": failures, "lines": lines}


static func material_failure_headless_gate_line() -> String:
    if BleedingConstants.FEATURE_TISSUE_DAMAGE_D:
        return "headless_M5_gate=partial_enablement_review_flags"
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES and not BleedingConstants.FEATURE_LAYER_TISSUE:
        return "headless_M5_gate=partial_enablement_review_flags"
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        return "headless_M5_gate=all_pilot_flags_off_and_anchors_locked"
    if (
        BleedingConstants.FEATURE_LITERAL_BLOOD_ML
        and CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
        and BleedingConstants.FEATURE_TISSUE_ENERGY_POOL
        and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES
    ):
        return "headless_M5_gate=p3b_full_including_energy_pool_joule_armor_and_literal_blood_ml"
    if (
        CombatConstants.FEATURE_JOULE_ARMOR_BUDGET
        and BleedingConstants.FEATURE_TISSUE_ENERGY_POOL
        and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES
    ):
        return "headless_M5_gate=p3b_full_including_energy_pool_and_joule_armor"
    if BleedingConstants.FEATURE_TISSUE_ENERGY_POOL and BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        return "headless_M5_gate=p3b_full_including_energy_pool"
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        return "headless_M5_gate=curves_layer_tissue_and_curves_on"
    if BleedingConstants.FEATURE_LAYER_TISSUE:
        return "headless_M5_gate=curves_and_layer_tissue_on"
    return "headless_M5_gate=curves_on_layer_pilots_off_anchors_locked"


## Compare production J debit vs classic HP pools on same hit (harness/audit).
static func tissue_energy_hp_vs_j_parity_metrics() -> Dictionary:
    var part: String = "right_arm"
    var extras: Dictionary = {
        "hit_sub_region": "forearm",
        "strike_ke_j": 12.0,
        "disable_layer_tissue": true,
    }
    var ent_j: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("SWORD")
    var res_j: Dictionary = ent_j.take_damage_split(8.0, 1.0, part, 4.0, -1.0, -1.0, extras)
    var extras_hp: Dictionary = extras.duplicate()
    extras_hp["disable_tissue_energy_pool"] = true
    var ent_hp: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("SWORD")
    var res_hp: Dictionary = ent_hp.take_damage_split(8.0, 1.0, part, 4.0, -1.0, -1.0, extras_hp)
    var tissue_j: float = (
        float(res_j.get("final_cut", 0.0)) + float(res_j.get("final_blunt", 0.0)) + float(res_j.get("final_bone", 0.0))
    )
    var tissue_hp: float = (
        float(res_hp.get("final_cut", 0.0))
        + float(res_hp.get("final_blunt", 0.0))
        + float(res_hp.get("final_bone", 0.0))
    )
    CombatRegressionHarness._free_harness_node(ent_j)
    CombatRegressionHarness._free_harness_node(ent_hp)
    return {"tissue_applied_j": tissue_j, "tissue_applied_hp": tissue_hp}


## M5 F5 proxy: forearm graze  -  shallow pen, no bone chip (production stack).
static func f5_forearm_graze_metrics() -> Dictionary:
    var ent: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("SWORD")
    var extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
    var res: Dictionary = ent.take_damage_split(8.0, 0.0, "right_arm", 0.5, -1.0, -1.0, extras)
    var out: Dictionary = {
        "final_bone": float(res.get("final_bone", 0.0)),
        "final_cut": float(res.get("final_cut", 0.0)),
        "penetration_to_tissue_mm": float(res.get("penetration_to_tissue_mm", -1.0)),
        "penetration_to_bone_mm": float(res.get("penetration_to_bone_mm", -1.0)),
    }
    CombatRegressionHarness._free_harness_node(ent)
    return out


## M5 F5 proxy: cuirass chest hit  -  armor reduces tissue pen vs bare (committed-scale cut).


## M5 F5 proxy: cuirass chest hit  -  armor reduces tissue pen vs bare (committed-scale cut).
static func f5_armored_chest_metrics() -> Dictionary:
    var part: String = "chest"
    var sub: String = "thoracic"
    var pen: float = 6.0
    var cut: float = 18.0
    var extras: Dictionary = {"hit_sub_region": sub, "strike_ke_j": 120.0}
    var bare: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("SWORD")
    var res_bare: Dictionary = bare.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
    var armored: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("SWORD")
    var cuirass: ArmorPiece = ArmorPiece.create_from_definition("CUIRASS")
    if cuirass != null:
        armored.equip_armor(part, cuirass)
    var res_arm: Dictionary = armored.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
    var bare_sum: float = (
        float(res_bare.get("final_cut", 0.0))
        + float(res_bare.get("final_blunt", 0.0))
        + float(res_bare.get("final_bone", 0.0))
    )
    var arm_sum: float = (
        float(res_arm.get("final_cut", 0.0))
        + float(res_arm.get("final_blunt", 0.0))
        + float(res_arm.get("final_bone", 0.0))
    )
    var out: Dictionary = {
        "bare_tissue_pen_mm": float(res_bare.get("penetration_to_tissue_mm", 0.0)),
        "armored_tissue_pen_mm": float(res_arm.get("penetration_to_tissue_mm", 0.0)),
        "bare_damage_sum": bare_sum,
        "armored_damage_sum": arm_sum,
        "armor_stopped": float(res_arm.get("penetration_to_tissue_mm", 0.0)) < 0.01,
        "transmitted_ke_fraction": float(res_arm.get("transmitted_ke_fraction", -1.0)),
        "armor_ke_absorbed_j": float(res_arm.get("armor_ke_absorbed_j", 0.0)),
    }
    CombatRegressionHarness._free_harness_node(bare)
    CombatRegressionHarness._free_harness_node(armored)
    return out


## M5 F5 proxy: mace elbow  -  blunt KE above anchor fractures (production MFB).


## M5 F5 proxy: mace elbow  -  blunt KE above anchor fractures (production MFB).
static func f5_mace_elbow_metrics() -> Dictionary:
    var ent: CoreEntity = CalibrationBleedingParryTests._audit_new_entity("MACE")
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor("right_arm", "elbow")
    var strike_ke: float = j_anchor + 24.0
    var res: Dictionary = ent.take_damage_split(
        0.0, 8.0, "right_arm", -1.0, -1.0, -1.0, {"hit_sub_region": "elbow", "strike_ke_j": strike_ke}
    )
    var out: Dictionary = {
        "strike_ke_j": strike_ke,
        "j_anchor": j_anchor,
        "final_bone": float(res.get("final_bone", 0.0)),
        "final_blunt": float(res.get("final_blunt", 0.0)),
    }
    CombatRegressionHarness._free_harness_node(ent)
    return out
