class_name DefenseSpacingFootworkTests

extends FeintTempoDefenseFootworkTestBase

## Defense spacing + footwork: spacing band modulates parry/dodge, recovering footwork boosts dodge vs
## waiting, recovery-cause ordering, recovering/waiting dodge stacks with spacing long and close.


static func _run_defense_spacing_band_modulates_parry_and_dodge(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_spacing: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_spacing: mid parry_c_d too small %.3f" % cd_mid)
    elif not is_equal_approx(cd_long / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG):
        _fail(
            failures,
            (
                "defense_spacing: parry_c_d long/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG, cd_long / cd_mid]
            )
        )
    elif dodge_mid <= 1e-6:
        _fail(failures, "defense_spacing: mid dodge_chance too small")
    elif not is_equal_approx(dodge_long / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        _fail(
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
        _fail(
            failures,
            (
                "defense_spacing: parry_c_d close/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE, cd_close / cd_mid]
            )
        )
    elif not is_equal_approx(dodge_close / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        _fail(
            failures,
            (
                "defense_spacing: dodge close/mid want ratio %.3f got %.3f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, dodge_close / dodge_mid]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** defender gets recovering dodge mult vs off-balance
## **`STATE_WAITING`** baseline (no settled waiting-footwork mult).


static func _run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_footwork_recovering: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_footwork_recovering: waiting dodge_chance too small %.6f" % d_wait)
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
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`recovery_cause`** selects
## **`CombatConstants.defense_footwork_recovering_dodge_mult_for_cause`**
## (**`DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE`**) on reported **`dodge_chance`**; **`attack_hit`** >
## **`attack_miss`** at same **`distance_to`** / seed (miss recovery is more punishing).


static func _run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_footwork_cause: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_footwork_cause: waiting dodge_chance too small %.6f" % d_wait)
    elif not is_equal_approx(d_hit / d_wait, m_hit):
        _fail(failures, "defense_footwork_cause: hit rec/wait want %.4f got %.4f" % [m_hit, d_hit / d_wait])
    elif not is_equal_approx(d_miss / d_wait, m_miss):
        _fail(failures, "defense_footwork_cause: miss rec/wait want %.4f got %.4f" % [m_miss, d_miss / d_wait])
    elif not is_equal_approx(d_miss / d_hit, m_miss / m_hit):
        _fail(failures, "defense_footwork_cause: miss/hit ratio want %.4f got %.4f" % [m_miss / m_hit, d_miss / d_hit])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`**  -  pair **`distance_to`** spacing
## (**`DEFENSE_SPACING_DODGE_MULT_*`**) multiplies before **`defense_footwork_recovering_dodge_mult_for_cause`**;
## LONG/CLOSE vs MID ratios match WAITING spacing harness at fixed cause.


static func _run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_footwork_rec_spacing: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_footwork_rec_spacing: mid dodge_chance too small %.6f" % d_mid)
    elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        _fail(
            failures,
            (
                "defense_footwork_rec_spacing: long/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
            )
        )
    elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        _fail(
            failures,
            (
                "defense_footwork_rec_spacing: close/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** (not off-balance) gets
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** on reported **`dodge_chance`** after spacing.


static func _run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_footwork_waiting: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_footwork_waiting: off-balance dodge_chance too small %.6f" % d_off)
    else:
        # Settled waiting defender: gets DEFENSE_FOOTWORK_WAITING_DODGE_MULT.
        # Off-balance waiting defender: loses that bonus AND gets OFF_BALANCE_DODGE_CHANCE_MULT
        # (stepping is impaired). Combined settled/off ratio is the two factors divided.
        var expected_ratio: float = (
            CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT / CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT
        )
        if not is_equal_approx(d_settled / d_off, expected_ratio):
            _fail(
                failures,
                "defense_footwork_waiting: settled/off want ratio %.4f got %.4f" % [expected_ratio, d_settled / d_off]
            )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`**  -  pair **`distance_to`** spacing multiplies before
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`**.


static func _run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
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
        _fail(failures, "defense_footwork_wait_spacing: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
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
        _fail(failures, "defense_footwork_wait_spacing: mid dodge_chance too small %.6f" % d_mid)
    elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
        _fail(
            failures,
            (
                "defense_footwork_wait_spacing: long/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
            )
        )
    elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
        _fail(
            failures,
            (
                "defense_footwork_wait_spacing: close/mid want %.4f got %.4f"
                % [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## Tier 4.2 footwork / tempo: incoming stab **`contact_type`** scales passive **`parry_readiness`** after guard
## (**`PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT`** vs cut baseline) in **`DefenseChoiceResolver.choose_defense`**.
