class_name ArmWoundDegradationTests
extends CombatRegressionHarnessCore


## Doc-10 Issue 2 (`plan_balance_tuning.md`): localized arm wounds (sub-region + severity) degrade weapon function
## (grip). `BodyPartQuery.get_arm_wound_function_mult` maps sub-region/severity -> grip mult; the mult folds into
## `EntityEquipment.get_attack_damage_modifier` (attack) and `DefenseChoiceResolver.arm_wound_parry_capacity_mult`
## (parry, 10/15 penalty ratio per line 91 so parry is gentler than attack at the same wound). Feature-gated.
static func _run_arm_wound_grip_sub_region_and_severity_ordering(failures: PackedStringArray) -> void:
    var clean := _new_entity("SWORD")
    if not is_equal_approx(BodyPartQuery.get_arm_wound_function_mult(clean, BodyPartConstants.PART_RIGHT_ARM), 1.0):
        _fail(failures, "arm_grip: clean arm grip mult want 1.0")
    if not is_equal_approx(
        BodyPartQuery.get_arm_wound_function_mult(clean, BodyPartConstants.PART_CHEST), 1.0
    ):
        _fail(failures, "arm_grip: non-arm part grip mult want 1.0")
    var mod_hand := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_MODERATE)
    var mod_forearm := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "forearm", BleedingConstants.SEVERITY_MODERATE)
    var mod_elbow := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "elbow", BleedingConstants.SEVERITY_MODERATE)
    var mod_upper := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "upper_arm", BleedingConstants.SEVERITY_MODERATE)
    if not is_equal_approx(mod_hand, 1.0 - 1.0 * 0.55 * 0.45):
        _fail(failures, "arm_grip: moderate hand want ~0.7525 got %f" % mod_hand)
    if not is_equal_approx(mod_forearm, 1.0 - 0.85 * 0.55 * 0.45):
        _fail(failures, "arm_grip: moderate forearm want ~0.7896 got %f" % mod_forearm)
    if not is_equal_approx(mod_elbow, 1.0 - 1.15 * 0.55 * 0.45):
        _fail(failures, "arm_grip: moderate elbow want ~0.7154 got %f" % mod_elbow)
    if not is_equal_approx(mod_upper, 1.0 - 0.6 * 0.55 * 0.45):
        _fail(failures, "arm_grip: moderate upper_arm want ~0.8515 got %f" % mod_upper)
    if not (mod_elbow < mod_hand and mod_hand < mod_forearm and mod_forearm < mod_upper):
        _fail(
            failures,
            "arm_grip: sub-region ordering want elbow<hand<forearm<upper_arm got %f<%f<%f<%f"
            % [mod_elbow, mod_hand, mod_forearm, mod_upper]
        )
    var sev_minor := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_MINOR)
    var sev_mod := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_MODERATE)
    var sev_severe := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_SEVERE)
    var sev_critical := _arm_grip_mult(BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_CRITICAL)
    if not is_equal_approx(sev_severe, 0.55):
        _fail(failures, "arm_grip: severe hand want ~0.55 got %f" % sev_severe)
    if not (sev_critical < sev_severe and sev_severe < sev_mod and sev_mod < sev_minor):
        _fail(
            failures,
            "arm_grip: severity ordering want critical<severe<moderate<minor got %f<%f<%f<%f"
            % [sev_critical, sev_severe, sev_mod, sev_minor]
        )
    var stacked := _new_entity("SWORD")
    _inject_arm_wound(stacked, BodyPartConstants.PART_RIGHT_ARM, "hand", BleedingConstants.SEVERITY_MODERATE)
    _inject_arm_wound(stacked, BodyPartConstants.PART_RIGHT_ARM, "forearm", BleedingConstants.SEVERITY_MODERATE)
    var mod_stacked := BodyPartQuery.get_arm_wound_function_mult(
        stacked, BodyPartConstants.PART_RIGHT_ARM
    )
    if not is_equal_approx(mod_stacked, 1.0 - (1.0 + 0.85) * 0.55 * 0.45):
        _fail(failures, "arm_grip: stacked hand+forearm want ~0.5421 got %f" % mod_stacked)
    var legacy := _new_entity("SWORD")
    legacy.wounds[BodyPartConstants.PART_RIGHT_ARM] = [{"severity": BleedingConstants.SEVERITY_SEVERE}]
    var mod_legacy := BodyPartQuery.get_arm_wound_function_mult(
        legacy, BodyPartConstants.PART_RIGHT_ARM
    )
    if not is_equal_approx(mod_legacy, 1.0):
        _fail(failures, "arm_grip: legacy no-sub_region wound must not stack grip mult got %f" % mod_legacy)


## Doc-10 Issue 2 integration: `get_attack_damage_modifier` folds the grip mult; parry applies the 10/15 penalty
## ratio (line 91) so a wound hits attack harder than parry capacity. Feature-off must bypass both.
static func _run_arm_wound_attack_modifier_and_parry_ease(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_arm_wound_degradation_enabled()
    var mgr: Node = _harness_start_1v1("SWORD")
    var p: Dictionary = mgr.combatants[0]
    var node: CoreEntity = EntityAccess.scene_node(p)
    var arm: String = EntityEquipment.get_attacking_arm(node)
    var mod_clean: float = EntityAccess.get_attack_damage_modifier(p)
    _inject_arm_wound(node, arm, "hand", BleedingConstants.SEVERITY_MODERATE)
    var grip: float = BodyPartQuery.get_arm_wound_function_mult(node, arm)
    var mod_wound: float = EntityAccess.get_attack_damage_modifier(p)
    var attack_ratio: float = mod_wound / mod_clean
    if not is_equal_approx(attack_ratio, grip):
        _fail(
            failures,
            "arm_grip_attack: attack mod ratio want ~%f (grip) got %f (wounded=%.4f clean=%.4f)"
            % [grip, attack_ratio, mod_wound, mod_clean]
        )
    var parry_ease: float = DefenseChoiceResolver.arm_wound_parry_capacity_mult(grip)
    var want_parry: float = 1.0 - (1.0 - grip) * CombatConstants.ARM_WOUND_GRIP_PARRY_PENALTY_RATIO
    if not is_equal_approx(parry_ease, want_parry):
        _fail(failures, "arm_grip_parry: parry ease want ~%f (10/15 ratio) got %f" % [want_parry, parry_ease])
    if not (parry_ease > attack_ratio):
        _fail(
            failures,
            "arm_grip_parry: parry ease (%f) must exceed attack ratio (%f)"
            % [parry_ease, attack_ratio]
        )
    _free_manager(mgr)
    CombatConstants.set_feature_arm_wound_degradation_load(false)
    var mgr2: Node = _harness_start_1v1("SWORD")
    var p2: Dictionary = mgr2.combatants[0]
    var node2: CoreEntity = EntityAccess.scene_node(p2)
    var arm2: String = EntityEquipment.get_attacking_arm(node2)
    var clean2: float = EntityAccess.get_attack_damage_modifier(p2)
    _inject_arm_wound(node2, arm2, "hand", BleedingConstants.SEVERITY_MODERATE)
    var wound2: float = EntityAccess.get_attack_damage_modifier(p2)
    if not is_equal_approx(wound2, clean2):
        _fail(
            failures,
            "arm_grip_flag_off: attack mod must not change with feature off got clean=%.4f wounded=%.4f"
            % [clean2, wound2]
        )
    var grip_off: float = BodyPartQuery.get_arm_wound_function_mult(node2, arm2)
    if not is_equal_approx(grip_off, 1.0):
        _fail(failures, "arm_grip_flag_off: grip mult want 1.0 got %f" % grip_off)
    if not is_equal_approx(
        DefenseChoiceResolver.arm_wound_parry_capacity_mult(0.7525), 0.7525
    ):
        _fail(failures, "arm_grip_flag_off: parry ease must pass through unchanged when feature off")
    CombatConstants.set_feature_arm_wound_degradation_load(saved)
    _free_manager(mgr2)


## Fresh entity, one crafted localized wound (damage 0 -> no pain/blood noise; only sub_region + severity feed grip).
static func _arm_grip_mult(arm: String, sub_region: String, severity: String) -> float:
    var e := _new_entity("SWORD")
    _inject_arm_wound(e, arm, sub_region, severity)
    return BodyPartQuery.get_arm_wound_function_mult(e, arm)


static func _inject_arm_wound(e: Node, arm: String, sub_region: String, severity: String) -> void:
    if not e.wounds.has(arm):
        e.wounds[arm] = []
    e.wounds[arm].append(
        {
            "damage": 0.0,
            "severity": severity,
            "sub_region": sub_region,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        }
    )
