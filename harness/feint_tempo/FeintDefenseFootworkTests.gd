class_name FeintTempoDefenseFootworkTests

extends FeintTempoDefenseFootworkTestBase

## Feint telegraph + commitment: dodge readthrough respects guard-zone spacing, spacing long/close dampens or
## boosts dodge bite vs mid, and commitment fraction shortens effective wind-up for late parry (cut + thrust).


## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).
static func _run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "defensive"
    defender["guard"] = 0.69
    defender["state"] = CombatConstants.STATE_WAITING
    defender["stamina"] = CombatConstants.STAMINA_MAX
    var dm: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        _fail(failures, "feint_tele_dodge_gz_spacing: need left_leg in targetable")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "left_leg",
        "target_part": "chest",
        "intensity": 0.6,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
        CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
    }
    var found_seed: int = -1
    var initial_part: String = ""
    for s in range(0, 65536):
        seed(s)
        dm[atk_id] = CombatConstants.DISTANCE_LONG
        var dc_l: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        var p_l: String = str(dc_l.get("dodge_eval_part", ""))
        if p_l == "left_leg":
            continue
        seed(s)
        dm[atk_id] = CombatConstants.DISTANCE_MID
        var dc_m: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        if str(dc_m.get("dodge_eval_part", "")) == "left_leg":
            found_seed = s
            initial_part = p_l
            break
    if found_seed < 0:
        _fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: no seed in 0..65535 yields non-left_leg initial at LONG + telegraph left_"
                + "leg at MID"
            )
        )
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    seed(found_seed)
    dm[atk_id] = CombatConstants.DISTANCE_LONG
    var dc_long: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
    )
    seed(found_seed)
    dm[atk_id] = CombatConstants.DISTANCE_MID
    var dc_mid: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
    )
    if str(dc_mid.get("dodge_eval_part", "")) != "left_leg":
        _fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: mid want left_leg got %s (seed=%d)"
                % [str(dc_mid.get("dodge_eval_part", "")), found_seed]
            )
        )
    if str(dc_long.get("dodge_eval_part", "")) != initial_part or initial_part == "left_leg":
        _fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: long want initial %s got %s (seed=%d)"
                % [initial_part, str(dc_long.get("dodge_eval_part", "")), found_seed]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: LONG **`distance_to[attacker]`** scales feint dodge telegraph bias down vs MID
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG`**) so the same RNG draw can take telegraph bite at MID but not
## at LONG.


static func _run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        _fail(failures, "feint_telegraph_spacing: need left_leg in targetable")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "left_leg",
        "target_part": "chest",
        "intensity": 0.6,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
        CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
    }
    var eff_mid: float = 0.85
    var eff_long: float = 0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG
    var de_mid: String = ""
    var de_long: String = ""
    var ok_spacing: bool = false
    for s in range(0, 65536):
        seed(s)
        CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
            CombatConstants.DISTANCE_MID
        )
        var dc_mid: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        seed(s)
        CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
            CombatConstants.DISTANCE_LONG
        )
        var dc_long: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        de_mid = str(dc_mid.get("dodge_eval_part", ""))
        de_long = str(dc_long.get("dodge_eval_part", ""))
        if de_mid == "left_leg" and de_long != "left_leg":
            ok_spacing = true
            break
    if not ok_spacing:
        _fail(
            failures,
            (
                "feint_telegraph_spacing: no seed in 0..65535 with mid=left_leg long!=left_leg (eff_mid=%.4f eff_lo"
                + "ng=%.4f last mid=%s long=%s)" % [eff_mid, eff_long, de_mid, de_long]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: CLOSE **`distance_to[attacker]`** scales feint dodge telegraph bias up vs MID
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE`**) so the same RNG draw can skip telegraph bite at MID but
## take it at CLOSE.


static func _run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        _fail(failures, "feint_telegraph_spacing_close: need left_leg in targetable")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "left_leg",
        "target_part": "chest",
        "intensity": 0.6,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
        CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
    }
    var eff_mid: float = 0.85
    var eff_close: float = clampf(0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE, 0.0, 1.0)
    var de_mid: String = ""
    var de_close: String = ""
    var ok_spacing: bool = false
    for s in range(0, 65536):
        seed(s)
        CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
            CombatConstants.DISTANCE_MID
        )
        var dc_mid: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        seed(s)
        CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
            CombatConstants.DISTANCE_CLOSE
        )
        var dc_close: Dictionary = DefenseChoiceResolver.choose_defense(
            pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
        )
        de_mid = str(dc_mid.get("dodge_eval_part", ""))
        de_close = str(dc_close.get("dodge_eval_part", ""))
        if de_mid != "left_leg" and de_close == "left_leg":
            ok_spacing = true
            break
    if not ok_spacing:
        _fail(
            failures,
            (
                "feint_telegraph_spacing_close: no seed in 0..65535 with mid!=left_leg close=left_leg (eff_mid=%.4f"
                + " eff_close=%.4f last mid=%s close=%s)" % [eff_mid, eff_close, de_mid, de_close]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: non-empty **`feint_part`** -> **`CombatConstants.COMMITMENT_FRACTION_FEINT`**  -  same
## **`wind_up_duration`** and defender **`reaction_time`** can yield on-time plain parry vs late feint parry (bracket
## duration between the two **`effective_wind_up`** thresholds).


static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "feint_commitment: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_plain: Dictionary = WeaponConstants.get_move("oberhau")
    var arch_plain: Dictionary = WeaponConstants.get_archetype(
        str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var move_feint: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch_feint: Dictionary = WeaponConstants.get_archetype(
        str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var r_time: float = def_n._get_passive_parry_reaction_time()
    var cf: float = CombatConstants.COMMITMENT_FRACTION
    var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
    var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
    var eff_plain: float = w_up * (1.0 - cf)
    var eff_feint: float = w_up * (1.0 - cff)
    if eff_plain <= r_time or eff_feint >= r_time:
        _fail(
            failures,
            (
                "feint_commitment: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
                % [r_time, w_up, eff_plain, eff_feint]
            )
        )
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var pa_plain: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": w_up,
        "tactical_ambush_mult": 1.0,
    }
    var pa_feint: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "head",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": w_up,
        "tactical_ambush_mult": 1.0,
    }
    seed(44002)
    var dc_plain: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_plain, attacker, defender, parts, "oberhau", arch_plain, -1.0
    )
    seed(44002)
    var dc_feint: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_feint, attacker, defender, parts, "oberhau_feint", arch_feint, -1.0
    )
    if bool(dc_plain.get("late_parry", false)):
        _fail(
            failures,
            (
                "feint_commitment: plain oberhau want on-time parry late_parry=false got late=%s"
                % str(dc_plain.get("late_parry", false))
            )
        )
    elif not bool(dc_feint.get("late_parry", false)):
        _fail(
            failures,
            "feint_commitment: feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: same bracket as **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, for
## **`thrust`** vs **`thrust_feint`** (**stab** archetypes).


static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "feint_commitment_thrust: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_plain: Dictionary = WeaponConstants.get_move("thrust")
    var arch_plain: Dictionary = WeaponConstants.get_archetype(
        str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
    )
    var move_feint: Dictionary = WeaponConstants.get_move("thrust_feint")
    var arch_feint: Dictionary = WeaponConstants.get_archetype(
        str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
    )
    var r_time: float = def_n._get_passive_parry_reaction_time()
    var cf: float = CombatConstants.COMMITMENT_FRACTION
    var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
    var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
    var eff_plain: float = w_up * (1.0 - cf)
    var eff_feint: float = w_up * (1.0 - cff)
    if eff_plain <= r_time or eff_feint >= r_time:
        _fail(
            failures,
            (
                "feint_commitment_thrust: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
                % [r_time, w_up, eff_plain, eff_feint]
            )
        )
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var pa_plain: Dictionary = {
        "attack_type": "thrust",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": w_up,
        "tactical_ambush_mult": 1.0,
    }
    var pa_feint: Dictionary = {
        "attack_type": "thrust_feint",
        "feint_part": "head",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": w_up,
        "tactical_ambush_mult": 1.0,
    }
    seed(44002)
    var dc_plain: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_plain, attacker, defender, parts, "thrust", arch_plain, -1.0
    )
    seed(44002)
    var dc_feint: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_feint, attacker, defender, parts, "thrust_feint", arch_feint, -1.0
    )
    if bool(dc_plain.get("late_parry", false)):
        _fail(
            failures,
            (
                "feint_commitment_thrust: plain thrust want on-time parry late_parry=false got late=%s"
                % str(dc_plain.get("late_parry", false))
            )
        )
    elif not bool(dc_feint.get("late_parry", false)):
        _fail(
            failures,
            (
                "feint_commitment_thrust: thrust_feint want late_parry=true got late=%s"
                % str(dc_feint.get("late_parry", false))
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## Tier 4.2 footwork: **`DefenseChoiceResolver.choose_defense`**  -  defender **`distance_to[attacker]`** scales
## **`parry_c_d`** (CLOSE / LONG vs MID) and **`dodge_chance`** at CLOSE / LONG
## (**`CombatConstants.DEFENSE_SPACING_*`**).
