class_name SimulationMaterialTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Simulation realism track (S1 - S10): `_run_sim_*`  -  docs/LIVE_PATHS.md#harness-prefixes.

const HumanSpecies := preload("res://resources/species/human.tres")
const GoblinSpecies := preload("res://resources/species/goblin.tres")


static func _run_sim_depth_shallow_pen_lowers_severity(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY:
        SimulationCombatTests._fail(failures, "sim_depth_severity: FEATURE_PENETRATION_DEPTH_SEVERITY must be on")
        return
    var ent: CoreEntity = SimulationCombatTests._entity_for_species(HumanSpecies)
    var part: String = "right_arm"
    var sub: String = "forearm"
    var dmg: float = 5.5
    var sev_shallow: String = EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 0.8)
    var sev_deep: String = EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 6.0)
    var order: Array = EntityWounds._severity_order()
    if order.find(sev_deep) < order.find(sev_shallow):
        SimulationCombatTests._fail(
            failures, "sim_depth_severity: deep=%s should be >= shallow=%s at same damage" % [sev_deep, sev_shallow]
        )


## S8: deep penetration reaches severe+ band where shallow stays moderate at tuned damage.
static func _run_sim_depth_deep_pen_raises_severity(failures: PackedStringArray) -> void:
    var ent: CoreEntity = SimulationCombatTests._entity_for_species(HumanSpecies)
    var part: String = "right_arm"
    var sub: String = "forearm"
    var dmg: float = 5.5
    var sev_shallow: String = EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 0.5)
    var sev_deep: String = EntityWounds.severity_from_damage(ent, part, dmg, sub, -1.0, 6.0)
    if sev_shallow == BleedingConstants.SEVERITY_SEVERE or sev_shallow == BleedingConstants.SEVERITY_CRITICAL:
        SimulationCombatTests._fail(
            failures, "sim_depth_deep: shallow pen should not already be severe+ (got %s)" % sev_shallow
        )
    if sev_deep != BleedingConstants.SEVERITY_SEVERE and sev_deep != BleedingConstants.SEVERITY_CRITICAL:
        SimulationCombatTests._fail(
            failures, "sim_depth_deep: deep pen want severe+ got %s (shallow=%s)" % [sev_deep, sev_shallow]
        )


## S8: blunt KE budget in soft tissue suppresses low-energy arm fracture.
static func _run_sim_blunt_tissue_ke_reduces_fracture(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE:
        SimulationCombatTests._fail(failures, "sim_blunt_tissue_ke: FEATURE_BLUNT_TISSUE_KE_GATE must be on")
        return
    var part: String = "right_arm"
    var sub: String = "elbow"
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(part, sub)
    var budget: float = float(CombatLayerTissue.BLUNT_TISSUE_KE_BUDGET_J_BY_PART.get(part, 22.0))
    var ke_hi: float = j_anchor + budget + 18.0
    var ke_lo: float = j_anchor + budget - 4.0
    var blunt_stream: float = 2.0
    var hi: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
        0.0, blunt_stream, blunt_stream, part, sub, -1.0, ke_hi, CombatLayerTissue.blunt_ke_reaching_bone(part, ke_hi)
    )
    var lo: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
        0.0, blunt_stream, blunt_stream, part, sub, -1.0, ke_lo, CombatLayerTissue.blunt_ke_reaching_bone(part, ke_lo)
    )
    if float(hi.get("to_bone", 0.0)) < 0.5:
        SimulationCombatTests._fail(
            failures, "sim_blunt_tissue_ke: high KE %.1f want bone (anchor %.1f)" % [ke_hi, j_anchor]
        )
    if float(lo.get("to_bone", 0.0)) > 0.01:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_blunt_tissue_ke: low KE %.1f should not fracture (to_bone=%.2f)"
                % [ke_lo, float(lo.get("to_bone", 0.0))]
            )
        )


## S9: deep tissue penetration raises arterial chance vs shallow slash (same severity/part).
static func _run_sim_depth_deep_pen_raises_arterial_chance(failures: PackedStringArray) -> void:
    var sev: String = BleedingConstants.SEVERITY_SEVERE
    var ch_shallow: float = BleedingConstants.get_arterial_chance(
        sev, BleedingConstants.INJURY_TYPE_CUT, "right_arm", "forearm", 0.8
    )
    var ch_deep: float = BleedingConstants.get_arterial_chance(
        sev, BleedingConstants.INJURY_TYPE_CUT, "right_arm", "forearm", 6.0
    )
    if ch_deep <= ch_shallow + 0.001:
        SimulationCombatTests._fail(
            failures, "sim_depth_arterial: deep chance %.4f should exceed shallow %.4f" % [ch_deep, ch_shallow]
        )


## S9: subcutaneous + muscle stack (2 mm + 3 mm arm) absorbs before bone.
static func _run_sim_layer_stack_two_sheets_absorb_pen(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue = true
    var part: String = "right_arm"
    var mid: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, 4.0, true)
    var deep: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, 6.5, true)
    CombatLayerTissue._harness_force_layer_tissue = false
    var layers_mid: Array = mid.get("layers_absorbed_mm", [])
    if layers_mid.size() < 2:
        SimulationCombatTests._fail(failures, "sim_layer_stack: want 2 soft-tissue sheets in layers_absorbed_mm")
    if float(mid.get("penetration_to_bone_mm", -1.0)) > 0.01:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_layer_stack: pen 4 mm should not reach bone (to_bone=%.2f)"
                % float(mid.get("penetration_to_bone_mm", 0.0))
            )
        )
    var to_bone: float = float(deep.get("penetration_to_bone_mm", 0.0))
    if not is_equal_approx(to_bone, 1.5):
        SimulationCombatTests._fail(
            failures, "sim_layer_stack: pen 6.5 mm want 1.5 to bone (2+3 consumed) got %.2f" % to_bone
        )


## S10: full EntityDamage path  -  layer tissue reduces bone vs same hit without layer stack.
static func _run_sim_layer_tissue_entity_path_reduces_bone(failures: PackedStringArray) -> void:
    var off_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var on_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var pen: float = CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 2.0
    # Below forearm J anchor so bone comes from penetration gate, not KE excess alone.
    var extras: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
    var extras_off: Dictionary = extras.duplicate()
    if BleedingConstants.FEATURE_LAYER_TISSUE:
        extras_off["disable_layer_tissue"] = true
    var res_off: Dictionary = off_ent.take_damage_split(12.0, 0.0, "right_arm", pen, -1.0, -1.0, extras_off)
    var extras_on: Dictionary = extras.duplicate()
    if not BleedingConstants.FEATURE_LAYER_TISSUE:
        extras_on["force_layer_tissue"] = true
    var res_on: Dictionary = on_ent.take_damage_split(12.0, 0.0, "right_arm", pen, -1.0, -1.0, extras_on)
    var bone_off: float = float(res_off.get("final_bone", 0.0))
    var bone_on: float = float(res_on.get("final_bone", 0.0))
    if bone_off <= 0.0:
        SimulationCombatTests._fail(failures, "sim_layer_entity: off-path want bone chip at pen %.1f" % pen)
    if bone_on >= bone_off - 0.01:
        SimulationCombatTests._fail(
            failures, "sim_layer_entity: layer on bone %.2f should be < off %.2f" % [bone_on, bone_off]
        )
    if float(res_on.get("penetration_to_bone_mm", 99.0)) >= pen - 0.5:
        SimulationCombatTests._fail(failures, "sim_layer_entity: want reduced penetration_to_bone_mm in result")


## M1: pen and KE curves monotonic; no EntityDamage mutation.
static func _run_mat_curve_monotonic_pen_and_ke(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var sub: String = "forearm"
    var cut_sh: float = MaterialFailureCurves.cut_tissue_damage_from_pen(0.8, part)
    var cut_mid: float = MaterialFailureCurves.cut_tissue_damage_from_pen(3.0, part)
    var cut_deep: float = MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, part)
    if cut_mid <= cut_sh + 0.01 or cut_deep <= cut_mid + 0.01:
        SimulationCombatTests._fail(
            failures,
            "mat_curve_monotonic: cut pen 0.8=%.2f 3=%.2f 6=%.2f want strict increase" % [cut_sh, cut_mid, cut_deep]
        )
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(part, sub)
    var bone_lo: float = MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor + 8.0, part, sub)
    var bone_hi: float = MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor + 40.0, part, sub)
    if bone_hi <= bone_lo + 0.01:
        SimulationCombatTests._fail(
            failures, "mat_curve_monotonic: blunt bone KE+8=%.2f KE+40=%.2f want increase" % [bone_lo, bone_hi]
        )
    if MaterialFailureCurves.blunt_bone_damage_from_ke(j_anchor - 1.0, part, sub) > 0.01:
        SimulationCombatTests._fail(failures, "mat_curve_monotonic: blunt bone below anchor should be 0")


## M1: blunt bone curve matches MFB `j_excess_to_bone_damage` at harness anchor.
static func _run_mat_curve_matches_mfb_baseline_at_anchor(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var sub: String = "forearm"
    var excess_j: float = 24.0
    var j_anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(part, sub)
    var ke_hit: float = j_anchor + excess_j
    var curve_bone: float = MaterialFailureCurves.blunt_bone_damage_from_ke(ke_hit, part, sub)
    var mfb_bone: float = CombatDamageMechanism.j_excess_to_bone_damage(excess_j)
    if absf(curve_bone - mfb_bone) > 0.02:
        SimulationCombatTests._fail(
            failures,
            "mat_curve_mfb_anchor: blunt curve %.2f vs MFB %.2f (excess_J=%.0f)" % [curve_bone, mfb_bone, excess_j]
        )
    var ke_ref: float = MaterialFailureCurves.reference_committed_arm_ke_j()
    var ref_bone: float = MaterialFailureCurves.blunt_bone_damage_from_ke(ke_ref, part, sub)
    var expected_ref: float = CombatDamageMechanism.j_excess_to_bone_damage(maxf(0.0, ke_ref - j_anchor))
    if absf(ref_bone - expected_ref) > 0.02:
        SimulationCombatTests._fail(
            failures, "mat_curve_mfb_anchor: KE %.0f bone %.2f vs expected %.2f" % [ke_ref, ref_bone, expected_ref]
        )
    if MaterialFailureCurves.cut_bone_damage_from_pen(1.0, part, sub) > 0.01:
        SimulationCombatTests._fail(failures, "mat_curve_mfb_anchor: cut bone below MFB pen floor should be 0")
    var cut_deep: float = MaterialFailureCurves.cut_tissue_damage_from_pen(6.0, part)
    var cut_shallow: float = MaterialFailureCurves.cut_tissue_damage_from_pen(0.8, part)
    if cut_deep <= cut_shallow * 1.5:
        SimulationCombatTests._fail(
            failures, "mat_curve_mfb_anchor: cut deep %.2f should exceed shallow %.2f" % [cut_deep, cut_shallow]
        )


## M1: depth mult is BleedingConstants delegate (no fork).
static func _run_mat_curve_depth_mult_delegates_bleeding(failures: PackedStringArray) -> void:
    for pen in [0.8, 3.0, 6.0]:
        var curve_mult: float = MaterialFailureCurves.penetration_depth_mult(pen)
        var bleed_mult: float = BleedingConstants.penetration_depth_severity_mult(pen)
        if absf(curve_mult - bleed_mult) > 0.0001:
            SimulationCombatTests._fail(
                failures, "mat_curve_depth: pen=%.1f curve=%.3f bleeding=%.3f" % [pen, curve_mult, bleed_mult]
            )


static func _mat_within_pct_tolerance(baseline: float, actual: float, pct: float) -> bool:
    if baseline <= 0.01:
        return actual <= 0.01
    return absf(actual - baseline) <= baseline * pct


## M2: unarmored forearm  -  curve path within +/-15% of MFB entity path (blend weight 1.0).
static func _run_mat_entity_curve_matches_hp_baseline_unarmored(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var sub: String = "forearm"
    var pen: float = CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5
    var cut: float = 12.0
    var strike_ke: float = 12.0
    var extras_base: Dictionary = {
        "hit_sub_region": sub,
        "strike_ke_j": strike_ke,
        "material_curve_blend_weight": 0.0,
    }
    var ent_mfb: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_mfb: Dictionary = ent_mfb.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras_base)
    var extras_curve: Dictionary = extras_base.duplicate()
    extras_curve["force_material_curves"] = true
    extras_curve["material_curve_blend_weight"] = 1.0
    var ent_curve: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_curve: Dictionary = ent_curve.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras_curve)
    var tol: float = 0.15
    for key: String in ["final_cut", "final_blunt", "final_bone"]:
        var base_v: float = float(res_mfb.get(key, 0.0))
        var curve_v: float = float(res_curve.get(key, 0.0))
        if not SimulationMaterialTests._mat_within_pct_tolerance(base_v, curve_v, tol):
            SimulationCombatTests._fail(
                failures,
                "mat_entity_baseline: %s MFB %.2f vs curve %.2f (>%.0f%%)" % [key, base_v, curve_v, tol * 100.0]
            )


## M2: production off -> MFB path; production on -> matches explicit `force_material_curves`.
static func _run_mat_entity_flag_off_matches_mfb_path(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var pen: float = CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 1.5
    var cut: float = 12.0
    var strike_ke: float = 12.0
    var extras: Dictionary = {
        "hit_sub_region": "forearm",
        "strike_ke_j": strike_ke,
        "material_curve_blend_weight": 0.0,
    }
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        var ent_a: Node = CombatRegressionHarness._new_entity("SWORD")
        var ent_b: Node = CombatRegressionHarness._new_entity("SWORD")
        var res_a: Dictionary = ent_a.take_damage_split(10.0, 2.0, part, 3.5, -1.0, -1.0, extras)
        var res_b: Dictionary = ent_b.take_damage_split(10.0, 2.0, part, 3.5, -1.0, -1.0, extras.duplicate())
        for key: String in ["final_cut", "final_blunt", "final_bone"]:
            if absf(float(res_a.get(key, 0.0)) - float(res_b.get(key, 0.0))) > 0.01:
                SimulationCombatTests._fail(
                    failures,
                    (
                        "mat_entity_flag_off: %s diverged %.2f vs %.2f"
                        % [key, float(res_a.get(key, 0.0)), float(res_b.get(key, 0.0))]
                    )
                )
        if ent_a.body_cutting.get(part, 99.0) != ent_b.body_cutting.get(part, 99.0):
            SimulationCombatTests._fail(failures, "mat_entity_flag_off: body_cutting pool mismatch")
        return
    var ent_prod: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_prod: Dictionary = ent_prod.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
    var extras_force: Dictionary = extras.duplicate()
    extras_force["force_material_curves"] = true
    extras_force["material_curve_blend_weight"] = 1.0
    var ent_force: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_force: Dictionary = ent_force.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras_force)
    var tol: float = 0.15
    for key: String in ["final_cut", "final_blunt", "final_bone"]:
        var prod_v: float = float(res_prod.get(key, 0.0))
        var force_v: float = float(res_force.get(key, 0.0))
        if not SimulationMaterialTests._mat_within_pct_tolerance(prod_v, force_v, tol):
            SimulationCombatTests._fail(
                failures,
                "mat_entity_prod_curves: %s prod %.2f vs force %.2f (>%.0f%%)" % [key, prod_v, force_v, tol * 100.0]
            )


## M2: cuirass reduces post-armor pen -> curve damage <= bare at pen 5.
static func _run_mat_armored_pen_reduces_curve_damage(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if cuirass == null:
        SimulationCombatTests._fail(failures, "mat_armored_pen: missing CUIRASS")
        return
    var part: String = "chest"
    var sub: String = "thoracic"
    var pen: float = 5.0
    var cut: float = 14.0
    var extras: Dictionary = {
        "hit_sub_region": sub,
        "force_material_curves": true,
        "material_curve_blend_weight": 1.0,
    }
    var bare: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_bare: Dictionary = bare.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
    var armored: Node = CombatRegressionHarness._new_entity("SWORD")
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
    if bare_sum <= 0.5:
        SimulationCombatTests._fail(failures, "mat_armored_pen: bare path want damage at pen %.1f" % pen)
    if arm_sum > bare_sum + 0.01:
        SimulationCombatTests._fail(
            failures, "mat_armored_pen: armored total %.2f should be <= bare %.2f" % [arm_sum, bare_sum]
        )
    if float(res_arm.get("final_bone", 0.0)) > float(res_bare.get("final_bone", 0.0)) + 0.01:
        SimulationCombatTests._fail(
            failures,
            (
                "mat_armored_pen: armored bone %.2f should be <= bare %.2f"
                % [float(res_arm.get("final_bone", 0.0)), float(res_bare.get("final_bone", 0.0))]
            )
        )


## M3: shallow pen  -  yield stack leaves no bone penetration.
static func _run_mat_layer_yield_stops_shallow_pen(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue_curves = true
    var part: String = "right_arm"
    var state: Array = CombatLayerTissue.seed_layer_state_for_part(part)
    var layer: Dictionary = CombatLayerTissue.penetration_through_layers(part, 0.5, state, true)
    CombatLayerTissue._harness_force_layer_tissue_curves = false
    if float(layer.get("penetration_to_bone_mm", 99.0)) > 0.01:
        SimulationCombatTests._fail(
            failures,
            "mat_layer_yield: pen 0.5 want to_bone=0 got %.2f" % float(layer.get("penetration_to_bone_mm", 0.0))
        )
    var states: Array = layer.get("layer_states", [])
    if states.is_empty() or str(states[0].get("state", "")) != "intact":
        SimulationCombatTests._fail(failures, "mat_layer_yield: subcut should stay intact at 0.5 mm")


## M3: deep pen ruptures subcut; wound depth uses full tissue pen.
static func _run_mat_layer_rupture_deepens_wound_depth(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue_curves = true
    var part: String = "right_arm"
    var state: Array = CombatLayerTissue.seed_layer_state_for_part(part)
    var layer: Dictionary = CombatLayerTissue.penetration_through_layers(part, 2.5, state, true)
    CombatLayerTissue._harness_force_layer_tissue_curves = false
    var states: Array = layer.get("layer_states", [])
    if states.is_empty() or str(states[0].get("state", "")) != "ruptured":
        SimulationCombatTests._fail(failures, "mat_layer_rupture: subcut should rupture at 2.5 mm pen")
    if float(layer.get("penetration_to_bone_mm", 0.0)) > 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "mat_layer_rupture: shallow rupture should not reach bone (to_bone=%.2f)"
                % float(layer.get("penetration_to_bone_mm", 0.0))
            )
        )


## M3: entity path  -  curves + layer tissue reduces bone vs flat MFB at same pen.
static func _run_mat_layer_entity_path_reduces_bone(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    # Through 5 mm arm stack + bone gate (2.5 mm); 6 mm only reaches 1 mm to bone when flat layer on.
    var pen: float = 8.0 if BleedingConstants.FEATURE_LAYER_TISSUE else 6.0
    var cut: float = 12.0
    var extras: Dictionary = {
        "hit_sub_region": "forearm",
        "strike_ke_j": 12.0,
        "force_material_curves": true,
        "force_layer_tissue_curves": true,
    }
    var extras_flat: Dictionary = extras.duplicate()
    extras_flat.erase("force_layer_tissue_curves")
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        extras_flat["disable_layer_tissue_curves"] = true
    var flat: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_flat: Dictionary = flat.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras_flat)
    var curve: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_curve: Dictionary = curve.take_damage_split(cut, 0.0, part, pen, -1.0, -1.0, extras)
    var bone_flat: float = float(res_flat.get("final_bone", 0.0))
    var bone_curve: float = float(res_curve.get("final_bone", 0.0))
    if bone_flat <= 0.0 and bone_curve <= 0.0:
        SimulationCombatTests._fail(failures, "mat_layer_entity: need bone chip at pen %.1f for comparison" % pen)
    if bone_curve > bone_flat + 0.01:
        SimulationCombatTests._fail(
            failures, "mat_layer_entity: curve+layer bone %.2f should be <= flat path %.2f" % [bone_curve, bone_flat]
        )
    var pen_tissue: float = float(res_curve.get("penetration_to_tissue_mm", -1.0))
    if pen_tissue < pen - 0.5:
        SimulationCombatTests._fail(
            failures, "mat_layer_entity: want wound depth ~= strike pen %.1f got %.2f" % [pen, pen_tissue]
        )


## M3: flat layer budget (5 mm arm stack) when yield/rupture curves inactive.
static func _run_mat_layer_flat_budget_unchanged_when_curves_off(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var pen: float = 6.0
    var flat: Dictionary
    if BleedingConstants.FEATURE_LAYER_TISSUE and not BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        flat = CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
    else:
        CombatLayerTissue._harness_force_layer_tissue = true
        CombatLayerTissue._harness_force_layer_tissue_curves = false
        flat = CombatLayerTissue.penetration_after_soft_tissue(part, pen, true)
        CombatLayerTissue._harness_force_layer_tissue = false
    if absf(float(flat.get("penetration_to_bone_mm", -1.0)) - 1.0) > 0.05:
        SimulationCombatTests._fail(
            failures, "mat_layer_flat: pen 6 want to_bone 1.0 got %.2f" % float(flat.get("penetration_to_bone_mm", 0.0))
        )


## M5 enablement PR #1: material curves production on.
static func _run_mat_production_curves_flag_enabled(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        SimulationCombatTests._fail(
            failures, "mat_production: FEATURE_MATERIAL_FAILURE_CURVES must be true (enablement PR #1)"
        )


## M5 enablement PR #2: flat layer tissue production on.
static func _run_mat_production_layer_tissue_flag_enabled(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LAYER_TISSUE:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_LAYER_TISSUE must be true (enablement PR #2)")


## M5 enablement PR #3: layer yield/rupture production on.
static func _run_mat_production_layer_curves_flag_enabled(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        SimulationCombatTests._fail(
            failures, "mat_production: FEATURE_LAYER_TISSUE_CURVES must be true (enablement PR #3)"
        )
    if not BleedingConstants.FEATURE_LAYER_TISSUE:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_LAYER_TISSUE required before layer curves")


## PR #3: production yield/rupture path matches explicit `force_layer_tissue_curves`.
static func _run_mat_production_layer_curves_entity_matches_forced(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        return
    var part: String = "right_arm"
    var pen: float = 8.0 if BleedingConstants.FEATURE_LAYER_TISSUE else 6.0
    var extras_prod: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
    var extras_force: Dictionary = extras_prod.duplicate()
    extras_force["force_layer_tissue_curves"] = true
    var ent_prod: Node = CombatRegressionHarness._new_entity("SWORD")
    var ent_force: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_prod: Dictionary = ent_prod.take_damage_split(12.0, 0.0, part, pen, -1.0, -1.0, extras_prod)
    var res_force: Dictionary = ent_force.take_damage_split(12.0, 0.0, part, pen, -1.0, -1.0, extras_force)
    for key: String in ["final_cut", "final_blunt", "final_bone", "penetration_to_bone_mm"]:
        if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
            SimulationCombatTests._fail(
                failures,
                (
                    "mat_layer_curves_prod: %s prod %.2f vs force %.2f"
                    % [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
                )
            )


## PR #2: production flat layer path matches `force_layer_tissue` (disable yield stack when curves on).
static func _run_mat_production_layer_entity_matches_forced(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LAYER_TISSUE:
        return
    var part: String = "right_arm"
    var pen: float = CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM + 2.0
    var extras_prod: Dictionary = {"hit_sub_region": "forearm", "strike_ke_j": 12.0}
    if BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        extras_prod["disable_layer_tissue_curves"] = true
    var extras_force: Dictionary = extras_prod.duplicate()
    extras_force["force_layer_tissue"] = true
    var ent_prod: Node = CombatRegressionHarness._new_entity("SWORD")
    var ent_force: Node = CombatRegressionHarness._new_entity("SWORD")
    var res_prod: Dictionary = ent_prod.take_damage_split(12.0, 0.0, part, pen, -1.0, -1.0, extras_prod)
    var res_force: Dictionary = ent_force.take_damage_split(12.0, 0.0, part, pen, -1.0, -1.0, extras_force)
    for key: String in ["final_cut", "final_blunt", "final_bone", "penetration_to_bone_mm"]:
        if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
            SimulationCombatTests._fail(
                failures,
                (
                    "mat_layer_prod: %s prod %.2f vs force %.2f"
                    % [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
                )
            )


## S11-A: joule armor production flag on (`CombatConstants`).
static func _run_mat_production_joule_armor_flag_enabled(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        SimulationCombatTests._fail(
            failures, "mat_production: FEATURE_JOULE_ARMOR_BUDGET must be true (S11-A enablement)"
        )


## S11-A: production joule path matches explicit `force_joule_armor_budget` on armored chest hit.
static func _run_mat_production_joule_authoritative_matches_forced(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        return
    var saved_sub: bool = CombatConstants.is_feature_subregion_combat_mult_enabled()
    CombatConstants.set_feature_subregion_combat_mult_load(false)
    if HarnessFixtures.get_cached_armor("CUIRASS") == null:
        SimulationCombatTests._fail(failures, "mat_joule_prod: missing CUIRASS")
        CombatConstants.set_feature_subregion_combat_mult_load(saved_sub)
        return
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var part: String = "chest"
    var extras_prod: Dictionary = {
        "strike_ke_j": strike_ke,
        "hit_sub_region": "thoracic",
        "hit_sub_region_seed": 42,
    }
    var extras_force: Dictionary = extras_prod.duplicate()
    extras_force["force_joule_armor_budget"] = true
    var ent_prod: CoreEntity = SimulationCombatTests._sim_entity()
    ent_prod.species = HumanSpecies
    ent_prod.apply_species()
    ent_prod.equip_armor(part, HarnessFixtures.get_cached_armor("CUIRASS"))
    var ent_force: CoreEntity = SimulationCombatTests._sim_entity()
    ent_force.species = HumanSpecies
    ent_force.apply_species()
    ent_force.equip_armor(part, HarnessFixtures.get_cached_armor("CUIRASS"))
    var res_prod: Dictionary = EntityDamage.apply_damage_split(
        ent_prod, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_prod
    )
    var res_force: Dictionary = EntityDamage.apply_damage_split(
        ent_force, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_force
    )
    for key: String in [
        "mechanical_post_armor",
        "transmitted_ke_fraction",
        "armor_ke_absorbed_j",
        "final_cut",
        "final_blunt",
    ]:
        if absf(float(res_prod.get(key, 0.0)) - float(res_force.get(key, 0.0))) > 0.02:
            CombatConstants.set_feature_subregion_combat_mult_load(saved_sub)
            SimulationCombatTests._fail(
                failures,
                (
                    "mat_joule_prod: %s prod %.3f vs force %.3f"
                    % [key, float(res_prod.get(key, 0.0)), float(res_force.get(key, 0.0))]
                )
            )
    CombatConstants.set_feature_subregion_combat_mult_load(saved_sub)


## S11-A: `disable_joule_armor_budget` restores scalar ArmorPiece path when production flag on.
static func _run_mat_production_joule_disable_restores_scalar_armor(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        return
    var armor: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if armor == null:
        SimulationCombatTests._fail(failures, "mat_joule_disable: missing CUIRASS")
        return
    var strike_ke: float = 90.0
    var cut_pre: float = 14.0
    var part: String = "chest"
    var extras_joule: Dictionary = {"strike_ke_j": strike_ke}
    var extras_scalar: Dictionary = extras_joule.duplicate()
    extras_scalar["disable_joule_armor_budget"] = true
    var ent_j: CoreEntity = SimulationCombatTests._sim_entity()
    ent_j.species = HumanSpecies
    ent_j.apply_species()
    ent_j.equip_armor(part, armor)
    var ent_s: CoreEntity = SimulationCombatTests._sim_entity()
    ent_s.species = HumanSpecies
    ent_s.apply_species()
    ent_s.equip_armor(part, armor)
    var res_j: Dictionary = EntityDamage.apply_damage_split(ent_j, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_joule)
    var res_s: Dictionary = EntityDamage.apply_damage_split(ent_s, cut_pre, 0.0, part, 2.0, -1.0, -1.0, extras_scalar)
    var mech_j: float = float(res_j.get("mechanical_post_armor", 0.0))
    var mech_s: float = float(res_s.get("mechanical_post_armor", 0.0))
    if absf(mech_j - mech_s) < 0.25:
        SimulationCombatTests._fail(
            failures, "mat_joule_disable: joule mech %.2f should differ from scalar %.2f on cuirass" % [mech_j, mech_s]
        )
    if float(res_j.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
        SimulationCombatTests._fail(failures, "mat_joule_disable: joule path should report armor_ke_absorbed_j > 1")
    if float(res_s.get("armor_ke_absorbed_j", 0.0)) > 0.01:
        SimulationCombatTests._fail(failures, "mat_joule_disable: scalar path should not populate armor_ke_absorbed_j")


## S11-B: literal blood mL production flag on.
static func _run_mat_production_literal_blood_ml_flag_enabled(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        SimulationCombatTests._fail(
            failures, "mat_production: FEATURE_LITERAL_BLOOD_ML must be true (S11-B enablement)"
        )


## S11-B: apply_species seeds mL pool when production flag on (no harness force).
static func _run_mat_production_blood_ml_pools_seeded(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        return
    BloodVolumeMl._harness_force_literal_blood_ml = false
    var human: CoreEntity = SimulationCombatTests._sim_entity()
    human.species = HumanSpecies
    human.apply_species()
    var goblin: CoreEntity = SimulationCombatTests._sim_entity()
    goblin.species = GoblinSpecies
    goblin.apply_species()
    if not BloodVolumeMl.entity_uses_ml(human):
        SimulationCombatTests._fail(failures, "mat_blood_prod: human should use mL pool when flag on")
    if not is_equal_approx(human.blood_volume_ml_max, BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT):
        SimulationCombatTests._fail(
            failures,
            (
                "mat_blood_prod: human max want %.0f got %.0f"
                % [BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT, human.blood_volume_ml_max]
            )
        )
    if not is_equal_approx(human.blood_volume_ml, human.blood_volume_ml_max):
        SimulationCombatTests._fail(failures, "mat_blood_prod: human should spawn at full mL pool")
    if goblin.blood_volume_ml_max >= human.blood_volume_ml_max - 1.0:
        SimulationCombatTests._fail(
            failures,
            (
                "mat_blood_prod: goblin max %.0f should be < human %.0f"
                % [goblin.blood_volume_ml_max, human.blood_volume_ml_max]
            )
        )


## S11-B: mL TTD matches percent-mode anchor (production bridge, no harness force).
static func _run_mat_production_blood_ttd_matches_percent(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        return
    var rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ttd_pct: float = BleedingConstants.seconds_to_exsanguination(rate, BleedingConstants.MAX_BLOOD_VOLUME, 1.0)
    BloodVolumeMl._harness_force_literal_blood_ml = false
    var ent: CoreEntity = SimulationCombatTests._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    var max_ml: float = ent.blood_volume_ml_max
    if max_ml < 1.0:
        SimulationCombatTests._fail(failures, "mat_blood_ttd: missing blood_volume_ml_max on production entity")
        return
    var buffer_ml: float = (
        max_ml
        * (
            (BleedingConstants.MAX_BLOOD_VOLUME - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
            / BleedingConstants.MAX_BLOOD_VOLUME
        )
    )
    var loss_ml_s: float = BloodVolumeMl.blood_ml_loss_per_second(rate, max_ml, 1.0)
    var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
    if not is_equal_approx(ttd_pct, ttd_ml):
        SimulationCombatTests._fail(
            failures, "mat_blood_ttd: percent %.1fs vs ml %.1fs (rate=%.2f)" % [ttd_pct, ttd_ml, rate]
        )


## S11-B: one blood-loss tick keeps blood_volume % in sync with mL pool (production path).
static func _run_mat_production_blood_sync_tick(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        return
    BloodVolumeMl._harness_force_literal_blood_ml = false
    var ent: CoreEntity = SimulationCombatTests._sim_entity()
    ent.species = HumanSpecies
    ent.apply_species()
    ent.take_damage_split(8.0, 2.0, "right_arm")
    ent.blood_volume_ml = ent.blood_volume_ml_max * 0.6
    BloodVolumeMl.sync_percent_from_ml(ent)
    if not is_equal_approx(ent.blood_volume, 60.0):
        SimulationCombatTests._fail(
            failures, "mat_blood_sync: 60%% pool want blood_volume=60 got %.2f" % ent.blood_volume
        )
    var rate: float = EntityWounds.get_total_bleeding_rate(ent)
    if rate <= 0.0:
        SimulationCombatTests._fail(failures, "mat_blood_sync: need bleed rate")
        return
    var ml_before: float = ent.blood_volume_ml
    var pct_before: float = ent.blood_volume
    ent._set_combat_blood_loss_mult(1.0)
    EntityWounds.process_blood_loss(ent, 1.0)
    var want_loss_pct: float = rate * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER
    var want_loss_ml: float = BloodVolumeMl.blood_ml_loss_per_second(rate, ent.blood_volume_ml_max, 1.0)
    if not is_equal_approx(pct_before - ent.blood_volume, want_loss_pct):
        SimulationCombatTests._fail(
            failures, "mat_blood_sync: pct loss %.3f want %.3f" % [pct_before - ent.blood_volume, want_loss_pct]
        )
    if not is_equal_approx(ml_before - ent.blood_volume_ml, want_loss_ml):
        SimulationCombatTests._fail(
            failures, "mat_blood_sync: ml loss %.1f want %.1f" % [ml_before - ent.blood_volume_ml, want_loss_ml]
        )
    if not is_equal_approx(ent.blood_volume, 100.0 * ent.blood_volume_ml / ent.blood_volume_ml_max):
        SimulationCombatTests._fail(
            failures,
            (
                "mat_blood_sync: blood_volume %.2f != 100*ml/max %.2f"
                % [ent.blood_volume, 100.0 * ent.blood_volume_ml / ent.blood_volume_ml_max]
            )
        )


## M5: production simulation + material flags snapshot (P3b + S11).
static func _run_mat_production_sim_flags_snapshot(failures: PackedStringArray) -> void:
    var checks: Array = [
        ["FEATURE_MATERIAL_FAILURE_CURVES", BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES],
        ["FEATURE_LAYER_TISSUE", BleedingConstants.FEATURE_LAYER_TISSUE],
        ["FEATURE_LAYER_TISSUE_CURVES", BleedingConstants.FEATURE_LAYER_TISSUE_CURVES],
        ["FEATURE_TISSUE_ENERGY_POOL", BleedingConstants.FEATURE_TISSUE_ENERGY_POOL],
        ["FEATURE_JOULE_ARMOR_BUDGET", CombatConstants.FEATURE_JOULE_ARMOR_BUDGET],
        ["FEATURE_LITERAL_BLOOD_ML", BleedingConstants.FEATURE_LITERAL_BLOOD_ML],
        ["FEATURE_PENETRATION_DEPTH_SEVERITY", BleedingConstants.FEATURE_PENETRATION_DEPTH_SEVERITY],
        ["FEATURE_BLUNT_TISSUE_KE_GATE", BleedingConstants.FEATURE_BLUNT_TISSUE_KE_GATE],
        ["FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS", BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS],
        ["FEATURE_ABSOLUTE_SEVERITY_BANDS", BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS],
    ]
    for row: Array in checks:
        if not bool(row[1]):
            SimulationCombatTests._fail(failures, "mat_flags_snapshot: %s must be true in production" % String(row[0]))
    if BleedingConstants.FEATURE_TISSUE_DAMAGE_D:
        SimulationCombatTests._fail(
            failures, "mat_flags_snapshot: FEATURE_TISSUE_DAMAGE_D must stay false (M4 cancelled)"
        )


## M5: F5 playtest proxies green on full production stack (audit helpers).
static func _run_mat_production_f5_headless_proxies(failures: PackedStringArray) -> void:
    var graze: Dictionary = CombatCalibrationAudit.f5_forearm_graze_metrics()
    if float(graze.get("final_bone", 0.0)) >= 0.01:
        SimulationCombatTests._fail(failures, "mat_f5: forearm graze want no bone chip")
    var chest: Dictionary = CombatCalibrationAudit.f5_armored_chest_metrics()
    var chest_ok: bool = (
        (
            float(chest.get("armored_tissue_pen_mm", 99.0)) < float(chest.get("bare_tissue_pen_mm", 0.0)) - 0.01
            or bool(chest.get("armor_stopped", false))
        )
        and float(chest.get("armored_damage_sum", 99.0)) < float(chest.get("bare_damage_sum", 0.0)) - 0.5
    )
    if not chest_ok:
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "mat_f5: cuirass pen/damage armored=%.2f/%.1f bare=%.2f/%.1f"
                    % [
                        float(chest.get("armored_tissue_pen_mm", 0.0)),
                        float(chest.get("armored_damage_sum", 0.0)),
                        float(chest.get("bare_tissue_pen_mm", 0.0)),
                        float(chest.get("bare_damage_sum", 0.0)),
                    ]
                )
            )
        )
    if CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        if float(chest.get("transmitted_ke_fraction", -1.0)) < 0.0:
            SimulationCombatTests._fail(failures, "mat_f5: armored chest missing joule transmitted_ke_fraction")
        if float(chest.get("armor_ke_absorbed_j", 0.0)) <= 1.0:
            SimulationCombatTests._fail(failures, "mat_f5: armored chest want armor_ke_absorbed_j > 1 with joule on")
    var mace: Dictionary = CombatCalibrationAudit.f5_mace_elbow_metrics()
    if float(mace.get("final_bone", 0.0)) < 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "mat_f5: mace elbow bone %.2f want >=0.5 at KE %.0f"
                % [float(mace.get("final_bone", 0.0)), float(mace.get("strike_ke_j", 0.0))]
            )
        )


## M6 enablement PR #5: tissue energy pool production on.
static func _run_mat_production_energy_pool_flag_enabled(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        SimulationCombatTests._fail(
            failures, "mat_production: FEATURE_TISSUE_ENERGY_POOL must be true (enablement PR #5)"
        )


## M6: apply_species seeds J pools when production flag on.
static func _run_mat_production_energy_pools_seeded(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    var part: String = "right_arm"
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var cap_j: float = float(ent.tissue_energy_capacity_j.get(part, 0.0))
    var rem_j: float = float(ent.tissue_energy_remaining_j.get(part, 0.0))
    if cap_j < 95.0 or cap_j > 105.0:
        SimulationCombatTests._fail(failures, "mat_energy_prod: capacity_J %.0f want ~100" % cap_j)
    if rem_j < cap_j - 0.5:
        SimulationCombatTests._fail(
            failures, "mat_energy_prod: remaining_J %.0f should equal capacity %.0f at spawn" % [rem_j, cap_j]
        )


## M6: cut-only hit depletes cutting pool more than blunt (independent streams).
static func _run_mat_production_energy_severance_streams_independent(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    var part: String = "right_arm"
    var extras: Dictionary = {
        "hit_sub_region": "forearm",
        "strike_ke_j": 12.0,
        "disable_layer_tissue": true,
    }
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var cut_before: float = float(ent.body_cutting.get(part, 0.0))
    var blunt_before: float = float(ent.body_blunt.get(part, 0.0))
    ent.take_damage_split(7.0, 0.5, part, 3.0, -1.0, -1.0, extras)
    var cut_drop: float = cut_before - float(ent.body_cutting.get(part, 0.0))
    var blunt_drop: float = blunt_before - float(ent.body_blunt.get(part, 0.0))
    if cut_drop <= blunt_drop + 0.5:
        SimulationCombatTests._fail(
            failures,
            "mat_energy_streams: cut drop %.1f should exceed blunt drop %.1f on cut-heavy hit" % [cut_drop, blunt_drop]
        )


## M6: production J path tissue+bone applied within 5% of HP pool path (same hit).
static func _run_mat_production_energy_damage_within_five_pct(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        return
    var m: Dictionary = CombatCalibrationAudit.tissue_energy_hp_vs_j_parity_metrics()
    var tissue_hp: float = float(m.get("tissue_applied_hp", 0.0))
    var tissue_j: float = float(m.get("tissue_applied_j", 0.0))
    if not SimulationMaterialTests._mat_within_pct_tolerance(tissue_hp, tissue_j, 0.05):
        SimulationCombatTests._fail(failures, "mat_energy_parity: J %.2f vs HP %.2f (>5%%)" % [tissue_j, tissue_hp])


## M5: only M4 damage_D remains off (cancelled).
static func _run_mat_production_deferred_flags_off(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_MATERIAL_FAILURE_CURVES:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_MATERIAL_FAILURE_CURVES must be true")
    if not BleedingConstants.FEATURE_LAYER_TISSUE or not BleedingConstants.FEATURE_LAYER_TISSUE_CURVES:
        SimulationCombatTests._fail(failures, "mat_production: layer tissue + layer curves must be true")
    if not BleedingConstants.FEATURE_TISSUE_ENERGY_POOL:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_TISSUE_ENERGY_POOL must be true after PR #5")
    if BleedingConstants.FEATURE_TISSUE_DAMAGE_D:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_TISSUE_DAMAGE_D must be false (M4 cancelled)")
    if not CombatConstants.FEATURE_JOULE_ARMOR_BUDGET:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_JOULE_ARMOR_BUDGET must be true after S11-A")
    if not BleedingConstants.FEATURE_LITERAL_BLOOD_ML:
        SimulationCombatTests._fail(failures, "mat_production: FEATURE_LITERAL_BLOOD_ML must be true after S11-B")


## M5: calibration audit material sections + anchor gate (runs audit inline, not stale file).
static func _run_mat_production_calibration_anchors_locked(failures: PackedStringArray) -> void:
    var result: Dictionary = CombatCalibrationAudit.run_and_write_report()
    if not bool(result.get("ok", false)):
        for msg: String in result.get("failures", PackedStringArray()):
            SimulationCombatTests._fail(failures, "mat_production audit: %s" % msg)
    var body: String = "\n".join(result.get("lines", PackedStringArray()))
    for section: String in [
        "[material_failure_curves_pilot]",
        "[layer_tissue_curves_m3]",
        "[material_failure_production]",
        "[tissue_energy_pool_m6]",
        "[production_sim_flags]",
        "[research_benchmarks]",
        "[f5_scenario_headless]",
    ]:
        if section not in body:
            SimulationCombatTests._fail(failures, "mat_production: audit missing section %s" % section)
    var gate_line: String = CombatCalibrationAudit.material_failure_headless_gate_line()
    if gate_line not in body:
        SimulationCombatTests._fail(failures, "mat_production: audit missing gate line %s" % gate_line)


## M5: TTD band and committed oberhau KE unchanged (delivery anchors).
static func _run_mat_production_ttd_and_oberhau_unchanged(failures: PackedStringArray) -> void:
    var ttd_s: float = BleedingConstants.seconds_to_exsanguination(
        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE, BleedingConstants.MAX_BLOOD_VOLUME, 1.0
    )
    if ttd_s < 30.0 or ttd_s > 120.0:
        SimulationCombatTests._fail(failures, "mat_production: TTD %.1fs outside 30-120s" % ttd_s)
    var sword: Weapon = HarnessFixtures.get_cached_weapon("SWORD")
    if sword == null:
        SimulationCombatTests._fail(failures, "mat_production: missing SWORD for KE anchor")
        return
    var ai: AttackInstance = AttackInstance.new("oberhau", 1.0)
    ai.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ai.delivery_commit_fraction = 0.78
    var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai)
    if not CombatDesignAnchors.committed_strike_ke_in_strict_band(ke_j):
        SimulationCombatTests._fail(
            failures,
            (
                "mat_production: committed oberhau KE %.0f outside %s-%sj"
                % [ke_j, CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MIN, CombatDesignAnchors.COMMITTED_STRIKE_KE_J_MAX]
            )
        )

## M6: human arm 12 display <-> ~100 J capacity anchor.
