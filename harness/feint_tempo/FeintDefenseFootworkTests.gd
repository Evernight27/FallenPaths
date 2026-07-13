class_name FeintTempoDefenseFootworkTests
extends CombatRegressionHarnessCore
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func _run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "defensive"
    defender["guard"] = 0.83
    defender["state"] = CombatConstants.STATE_WAITING
    defender["stamina"] = CombatConstants.STAMINA_MAX
    var dm: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        CombatRegressionHarness._fail(failures, "feint_tele_dodge_gz_spacing: need left_leg in targetable")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: no seed in 0..65535 yields non-left_leg initial at LONG + telegraph left_"
                + "leg at MID"
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: mid want left_leg got %s (seed=%d)"
                % [str(dc_mid.get("dodge_eval_part", "")), found_seed]
            )
        )
    if str(dc_long.get("dodge_eval_part", "")) != initial_part or initial_part == "left_leg":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_tele_dodge_gz_spacing: long want initial %s got %s (seed=%d)"
                % [initial_part, str(dc_long.get("dodge_eval_part", "")), found_seed]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: LONG **`distance_to[attacker]`** scales feint dodge telegraph bias down vs MID
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG`**) so the same RNG draw can take telegraph bite at MID but not
## at LONG.
static func _run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        CombatRegressionHarness._fail(failures, "feint_telegraph_spacing: need left_leg in targetable")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_telegraph_spacing: no seed in 0..65535 with mid=left_leg long!=left_leg (eff_mid=%.4f eff_lo"
                + "ng=%.4f last mid=%s long=%s)" % [eff_mid, eff_long, de_mid, de_long]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: CLOSE **`distance_to[attacker]`** scales feint dodge telegraph bias up vs MID
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE`**) so the same RNG draw can skip telegraph bite at MID but
## take it at CLOSE.
static func _run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty() or not parts.has("left_leg"):
        CombatRegressionHarness._fail(failures, "feint_telegraph_spacing_close: need left_leg in targetable")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_telegraph_spacing_close: no seed in 0..65535 with mid!=left_leg close=left_leg (eff_mid=%.4f"
                + " eff_close=%.4f last mid=%s close=%s)" % [eff_mid, eff_close, de_mid, de_close]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: non-empty **`feint_part`** -> **`CombatConstants.COMMITMENT_FRACTION_FEINT`**  -  same
## **`wind_up_duration`** and defender **`reaction_time`** can yield on-time plain parry vs late feint parry (bracket
## duration between the two **`effective_wind_up`** thresholds).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "feint_commitment: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_commitment: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
                % [r_time, w_up, eff_plain, eff_feint]
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_commitment: plain oberhau want on-time parry late_parry=false got late=%s"
                % str(dc_plain.get("late_parry", false))
            )
        )
    elif not bool(dc_feint.get("late_parry", false)):
        CombatRegressionHarness._fail(
            failures,
            "feint_commitment: feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: same bracket as **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, for
## **`thrust`** vs **`thrust_feint`** (**stab** archetypes).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "feint_commitment_thrust: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_commitment_thrust: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
                % [r_time, w_up, eff_plain, eff_feint]
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_commitment_thrust: plain thrust want on-time parry late_parry=false got late=%s"
                % str(dc_plain.get("late_parry", false))
            )
        )
    elif not bool(dc_feint.get("late_parry", false)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_commitment_thrust: thrust_feint want late_parry=true got late=%s"
                % str(dc_feint.get("late_parry", false))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`DefenseChoiceResolver.choose_defense`**  -  defender **`distance_to[attacker]`** scales
## **`parry_c_d`** (CLOSE / LONG vs MID) and **`dodge_chance`** at CLOSE / LONG
## (**`CombatConstants.DEFENSE_SPACING_*`**).
static func _run_defense_spacing_band_modulates_parry_and_dodge(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_spacing: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91001)
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var dc_mid: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_LONG
    )
    seed(91001)
    var dc_long: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_mid: float = float(dc_mid.get("parry_c_d", 0.0))
    var cd_long: float = float(dc_long.get("parry_c_d", 0.0))
    var dodge_mid: float = float(dc_mid.get("dodge_chance", 0.0))
    var dodge_long: float = float(dc_long.get("dodge_chance", 0.0))
    if cd_mid < 1.0:
        CombatRegressionHarness._fail(failures, "defense_spacing: mid parry_c_d too small %.3f" % cd_mid)
    elif not is_equal_approx(cd_long / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_spacing: parry_c_d long/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG, cd_long / cd_mid]
            )
        )
    elif dodge_mid <= 1e-6:
        CombatRegressionHarness._fail(failures, "defense_spacing: mid dodge_chance too small")
    elif not is_equal_approx(dodge_long / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_spacing: dodge long/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, dodge_long / dodge_mid]
            )
        )
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    seed(91001)
    var dc_close: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau", arch, -1.0
    )
    var cd_close: float = float(dc_close.get("parry_c_d", 0.0))
    var dodge_close: float = float(dc_close.get("dodge_chance", 0.0))
    if not is_equal_approx(cd_close / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_spacing: parry_c_d close/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE, cd_close / cd_mid]
            )
        )
    elif not is_equal_approx(dodge_close / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_spacing: dodge close/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, dodge_close / dodge_mid]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** defender gets recovering dodge mult vs off-balance
## **`STATE_WAITING`** baseline (no settled waiting-footwork mult).
static func _run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["state"] = CombatConstants.STATE_WAITING
    defender["off_balance_until"] = CombatTiming.now_seconds() + 10.0
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_footwork_recovering: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91002)
    var dc_wait: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["state_duration"] = 1.0
    defender["state_timer"] = 0.25
    defender["recovery_cause"] = "attack_hit"
    seed(91002)
    var dc_rec: Dictionary = DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var d_wait: float = float(dc_wait.get("dodge_chance", 0.0))
    var d_rec: float = float(dc_rec.get("dodge_chance", 0.0))
    if d_wait <= 1e-6:
        CombatRegressionHarness._fail(
            failures, "defense_footwork_recovering: waiting dodge_chance too small %.6f" % d_wait
        )
    elif not is_equal_approx(
        d_rec / d_wait, CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
    ):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "defense_footwork_recovering: dodge rec/wait want ratio %.3f got %.3f"
                    % [
                        CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit"),
                        d_rec / d_wait,
                    ]
                )
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`recovery_cause`** selects
## **`CombatConstants.defense_footwork_recovering_dodge_mult_for_cause`**
## (**`DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE`**) on reported **`dodge_chance`**; **`attack_hit`** >
## **`attack_miss`** at same **`distance_to`** / seed (miss recovery is more punishing).
static func _run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["state"] = CombatConstants.STATE_WAITING
    defender["off_balance_until"] = CombatTiming.now_seconds() + 10.0
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_footwork_cause: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91003)
    var d_wait: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["state_duration"] = 1.0
    defender["state_timer"] = 0.25
    defender["recovery_cause"] = "attack_hit"
    seed(91003)
    var d_hit: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    defender["state"] = CombatConstants.STATE_WAITING
    defender["recovery_cause"] = "skip"
    defender["state_duration"] = 0.0
    defender["state_timer"] = 0.0
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["state_duration"] = 1.0
    defender["state_timer"] = 0.25
    defender["recovery_cause"] = "attack_miss"
    seed(91003)
    var d_miss: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    var m_hit: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
    var m_miss: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_miss")
    if d_wait <= 1e-6:
        CombatRegressionHarness._fail(failures, "defense_footwork_cause: waiting dodge_chance too small %.6f" % d_wait)
    elif not is_equal_approx(d_hit / d_wait, m_hit):
        CombatRegressionHarness._fail(
            failures, "defense_footwork_cause: hit rec/wait want %.4f got %.4f" % [m_hit, d_hit / d_wait]
        )
    elif not is_equal_approx(d_miss / d_wait, m_miss):
        CombatRegressionHarness._fail(
            failures, "defense_footwork_cause: miss rec/wait want %.4f got %.4f" % [m_miss, d_miss / d_wait]
        )
    elif not is_equal_approx(d_miss / d_hit, m_miss / m_hit):
        CombatRegressionHarness._fail(
            failures, "defense_footwork_cause: miss/hit ratio want %.4f got %.4f" % [m_miss / m_hit, d_miss / d_hit]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`**  -  pair **`distance_to`** spacing
## (**`DEFENSE_SPACING_DODGE_MULT_*`**) multiplies before **`defense_footwork_recovering_dodge_mult_for_cause`**;
## LONG/CLOSE vs MID ratios match WAITING spacing harness at fixed cause.
static func _run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["state_duration"] = 1.0
    defender["state_timer"] = 0.25
    defender["recovery_cause"] = "attack_hit"
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_footwork_rec_spacing: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91004)
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var d_mid: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_LONG
    )
    seed(91004)
    var d_long: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    seed(91004)
    var d_close: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    if d_mid <= 1e-6:
        CombatRegressionHarness._fail(failures, "defense_footwork_rec_spacing: mid dodge_chance too small %.6f" % d_mid)
    elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_footwork_rec_spacing: long/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
            )
        )
    elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_footwork_rec_spacing: close/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** (not off-balance) gets
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** on reported **`dodge_chance`** after spacing.
static func _run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["state"] = CombatConstants.STATE_WAITING
    defender["off_balance_until"] = -1.0
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_footwork_waiting: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91005)
    var d_settled: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    defender["off_balance_until"] = CombatTiming.now_seconds() + 10.0
    seed(91005)
    var d_off: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    if d_off <= 1e-6:
        CombatRegressionHarness._fail(
            failures, "defense_footwork_waiting: off-balance dodge_chance too small %.6f" % d_off
        )
    elif not is_equal_approx(d_settled / d_off, CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_footwork_waiting: settled/off want ratio %.4f got %.4f"
                % [CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT, d_settled / d_off]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`**  -  pair **`distance_to`** spacing multiplies before
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`**.
static func _run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.4
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["state"] = CombatConstants.STATE_WAITING
    defender["off_balance_until"] = -1.0
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        CombatRegressionHarness._fail(failures, "defense_footwork_wait_spacing: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    seed(91006)
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var d_mid: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_LONG
    )
    seed(91006)
    var d_long: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = (
        CombatConstants.DISTANCE_CLOSE
    )
    seed(91006)
    var d_close: float = float(
        DefenseChoiceResolver.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get(
            "dodge_chance", 0.0
        )
    )
    if d_mid <= 1e-6:
        CombatRegressionHarness._fail(
            failures, "defense_footwork_wait_spacing: mid dodge_chance too small %.6f" % d_mid
        )
    elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_footwork_wait_spacing: long/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
            )
        )
    elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        CombatRegressionHarness._fail(
            failures,
            (
                "defense_footwork_wait_spacing: close/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: incoming stab **`contact_type`** scales passive **`parry_readiness`** after guard
## (**`PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT`** vs cut baseline) in **`DefenseChoiceResolver.choose_defense`**.
static func _run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
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
        CombatRegressionHarness._fail(failures, "incoming_contact_readiness: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(failures, "incoming_contact_readiness: cut parry_readiness too small %.4f" % pr_c)
    elif not is_equal_approx(pr_s / pr_c, CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "incoming_contact_readiness: stab/cut readiness ratio want %.4f got %.4f (pr_cut=%.4f pr_stab=%.4f)"
                % [CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT, pr_s / pr_c, pr_c, pr_s]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: defender **`stamina`** scales **`choose_defense`** **`parry_readiness`** (feint
## read-through / guard-zone / dodge telegraph) via
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`**
## (**`DefenseChoiceResolver._defender_passive_readiness_stamina_mult`**), not the **`pr_base`** term in **`parry_c_d *=
## parry_capacity_mult * pr_base`**.
static func _run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
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
        CombatRegressionHarness._fail(failures, "def_stam_readiness: targetable parts empty")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
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
        CombatRegressionHarness._fail(
            failures, "def_stam_readiness: full-stamina parry_readiness too small %.4f" % pr_hi
        )
    elif not is_equal_approx(pr_lo / pr_hi, want):
        CombatRegressionHarness._fail(
            failures,
            (
                "def_stam_readiness: low/full readiness ratio want %.4f got %.4f (pr_lo=%.4f pr_hi=%.4f)"
                % [want, pr_lo / pr_hi, pr_lo, pr_hi]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)

## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  feint listing applies
## **`passive_parry_readiness_incoming_contact_mult`** to defender readiness: stab feint (**`thrust_feint`**) vs cut
## feint (**`oberhau_feint`**) at defender **`guard`** **1.0** (**SWORD** 1v1).
