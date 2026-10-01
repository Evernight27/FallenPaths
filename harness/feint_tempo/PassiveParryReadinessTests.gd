class_name PassiveParryReadinessTests

extends FeintTempoDefenseFootworkTestBase

## Passive parry readiness: incoming-contact stab scales vs cut, low defender stamina scales readiness in
## choose-defense, and below the glancing floor the defender refuses parry.


static func _run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.44
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "incoming_contact_readiness: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
    var arch_ober: Dictionary = WeaponConstants.get_archetype(
        str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var move_spear: Dictionary = WeaponConstants.get_move("spear_thrust")
    var arch_spear: Dictionary = WeaponConstants.get_archetype(
        str(move_spear.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
    )
    var pa_base: Dictionary = {
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(92001)
    var pa_cut: Dictionary = pa_base.duplicate()
    pa_cut["attack_type"] = "oberhau"
    var dc_cut: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_cut, attacker, defender, parts, "oberhau", arch_ober, -1.0
    )
    var pa_stab: Dictionary = pa_base.duplicate()
    pa_stab["attack_type"] = "spear_thrust"
    seed(92001)
    var dc_stab: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_stab, attacker, defender, parts, "spear_thrust", arch_spear, -1.0
    )
    var pr_c: float = float(dc_cut.get("parry_readiness", -1.0))
    var pr_s: float = float(dc_stab.get("parry_readiness", -1.0))
    if pr_c <= 1e-6:
        _fail(failures, "incoming_contact_readiness: cut parry_readiness too small %.4f" % pr_c)
    elif not is_equal_approx(pr_s / pr_c, CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT):
        _fail(
            failures,
            (
                "incoming_contact_readiness: stab/cut readiness ratio want %.4f got %.4f (pr_cut=%.4f pr_stab=%.4f)"
                % [CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT, pr_s / pr_c, pr_c, pr_s]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: defender **`stamina`** scales **`choose_defense`** **`parry_readiness`** (feint
## read-through / guard-zone / dodge telegraph) via
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`**
## (**`DefenseChoiceResolver._defender_passive_readiness_stamina_mult`**), not the **`pr_base`** term in **`parry_c_d *=
## parry_capacity_mult * pr_base`**.


static func _run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.44
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "def_stam_readiness: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    defender["stamina"] = CombatConstants.STAMINA_MAX
    var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
    var arch_ober: Dictionary = WeaponConstants.get_archetype(
        str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(92002)
    var dc_hi: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau", arch_ober, -1.0
    )
    defender["stamina"] = 0.0
    seed(92002)
    var dc_lo: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau", arch_ober, -1.0
    )
    var pr_hi: float = float(dc_hi.get("parry_readiness", -1.0))
    var pr_lo: float = float(dc_lo.get("parry_readiness", -1.0))
    var want: float = (
        lerpf(CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(0.0))
        / lerpf(CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(1.0))
    )
    if pr_hi <= 1e-6:
        _fail(failures, "def_stam_readiness: full-stamina parry_readiness too small %.4f" % pr_hi)
    elif not is_equal_approx(pr_lo / pr_hi, want):
        _fail(
            failures,
            (
                "def_stam_readiness: low/full readiness ratio want %.4f got %.4f (pr_lo=%.4f pr_hi=%.4f)"
                % [want, pr_lo / pr_hi, pr_lo, pr_hi]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 parry decision: below the glancing alignment floor (cos60) a parry is physically ineffective, so
## **`choose_defense`** must refuse parry even when **`redirect_viable`** (desperate low-dodge) would otherwise
## fire — a recovering defender whose guard ended on the attack line (align 0) previously chose a zero-capacity
## parry via the `not is_glancing` fallthrough. LIVE_PATHS **`#wf-guard-writers`** (blade ends where action ends).


static func _run_below_glancing_floor_refuses_parry(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high_right"
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["state_duration"] = 1.0
    defender["state_timer"] = 0.25
    defender["recovery_cause"] = "attack_miss"
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "below_glancing_floor: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "head",
        "intensity": 1.0,
        "wind_up_duration": 0.40,
        "tactical_ambush_mult": 1.0,
        DataKeys.PA_GUARD_ALIGNMENT: 0.0,
    }
    seed(91003)
    var dc_below: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau", arch, -1.0
    )
    var chose_parry: bool = str(dc_below.get("defense", "")) == "parry"
    var align_out: float = float(dc_below.get(DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT, 1.0))
    var c_d_out: float = float(dc_below.get("parry_c_d", -1.0))
    var p_a_out: float = float(dc_below.get("parry_p_a", -1.0))
    if align_out >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
        _fail(
            failures,
            "below_glancing_floor: forced align should stay below floor, got %.3f" % align_out,
        )
    elif c_d_out > 0.001 or not bool(dc_below.get("can_parry_in_time", false)):
        _fail(
            failures,
            (
                "below_glancing_floor: fixture must be zero-capacity parry in time "
                + "(c_d=%.3f p_a=%.3f) to exercise the zero-alignment fallthrough" % [c_d_out, p_a_out]
            ),
        )
    elif chose_parry:
        _fail(
            failures,
            (
                "below_glancing_floor: zero-alignment recovering defender must refuse parry "
                + "(parry physically ineffective below cos60)"
            ),
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  feint listing applies
## **`passive_parry_readiness_incoming_contact_mult`** to defender readiness: stab feint (**`thrust_feint`**) vs cut
## feint (**`oberhau_feint`**) at defender **`guard`** **1.0** (**SWORD** 1v1).
