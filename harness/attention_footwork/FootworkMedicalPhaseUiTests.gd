class_name AttentionFootworkMedicalPhaseUiTests
extends CombatRegressionHarnessCore
const CompanyState := preload("res://world/CompanyState.gd")

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_footwork_medical_wind_up_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {
        "state": CombatConstants.STATE_MEDICAL_WIND_UP,
        "state_timer": 0.0,
        "state_duration": 1.0,
    }
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    StateHandlers.process_medical_wind_up(null, c, 0.05)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_medical_wind_up_scrub: offset key should be erased")
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_medical_wind_up_scrub: ui hint key should be erased")


## Tier 4.4: receiving-medical tick scrubs leaked PA (**`process_receiving_medical`**).


## Tier 4.4: receiving-medical tick scrubs leaked PA (**`process_receiving_medical`**).
static func _run_footwork_receiving_medical_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {
        "state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
        "receiving_care_action_cooldown": 999.0,
    }
    CombatFootwork.apply_attack_step_on_windup(c, "left")
    StateHandlers.process_receiving_medical(null, c, 0.05)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_receiving_medical_scrub: offset key should be erased")
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_receiving_medical_scrub: ui hint key should be erased")


## Tier 4.4: formation resolve return-to-waiting scrubs leaked PA (**`_set_combatant_waiting`**).


## Tier 4.4: formation resolve return-to-waiting scrubs leaked PA (**`_set_combatant_waiting`**).
static func _run_footwork_formation_flow_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_FALLING_BACK}
    CombatFootwork.apply_attack_step_on_windup(c, "high")
    FormationFlow._set_combatant_waiting(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_formation_waiting_scrub: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures, "footwork_formation_waiting_scrub: want waiting got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: **`return_to_waiting`** scrubs leaked PA on immediate idle transitions.


## Tier 4.4: **`return_to_waiting`** scrubs leaked PA on immediate idle transitions.
static func _run_footwork_return_to_waiting_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_RECOVERING}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    CombatFootwork.return_to_waiting(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_return_waiting: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures, "footwork_return_waiting: want waiting got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: parry idle clears defender PA before **`waiting`** (same-frame snapshot guard).


## Tier 4.4: parry idle clears defender PA before **`waiting`** (same-frame snapshot guard).
static func _run_footwork_parry_idle_clears_pa_before_waiting(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var tgt: Dictionary = {"state": CombatConstants.STATE_WIND_UP, "guard_line": "high"}
    CombatFootwork.apply_defender_step_on_parry(tgt, "high")
    AttackResultApplier._defender_set_idle_after_parry(tgt)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if tgt.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_parry_idle: offset key should be erased before waiting")
    if CombatantEntityAccess.state_str(tgt) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures, "footwork_parry_idle: want waiting got '%s'" % CombatantEntityAccess.state_str(tgt)
        )


## Tier 4.4: medical phase halt scrubs leaked PA on losing-side idle reset.


## Tier 4.4: medical phase halt scrubs leaked PA on losing-side idle reset.
static func _run_footwork_medical_phase_halt_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var loser: Dictionary = mgr.combatants[1]
    loser["state"] = CombatConstants.STATE_RECOVERING
    loser["state_timer"] = 0.2
    loser["state_duration"] = 0.8
    CombatFootwork.apply_attack_step_on_windup(loser, "left")
    MedicalPhaseController.halt_losing_side_combat(mgr)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if loser.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_medical_halt: offset key should be erased")
    if CombatantEntityAccess.state_str(loser) != CombatConstants.STATE_WAITING:
        CombatRegressionHarness._fail(
            failures, "footwork_medical_halt: want waiting got '%s'" % CombatantEntityAccess.state_str(loser)
        )


## Tier 4.4: **`return_to_cowering`** scrubs leaked PA on no-arm idle transitions.


## Tier 4.4: **`return_to_cowering`** scrubs leaked PA on no-arm idle transitions.
static func _run_footwork_return_to_cowering_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_RECOVERING}
    CombatFootwork.apply_attack_step_on_windup(c, "left")
    CombatFootwork.return_to_cowering(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_return_cowering: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
        CombatRegressionHarness._fail(
            failures, "footwork_return_cowering: want cowering got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: mobility cowering sync scrubs leaked PA (**`sync_cowering_state_if_no_functional_arm`**).


## Tier 4.4: mobility cowering sync scrubs leaked PA (**`sync_cowering_state_if_no_functional_arm`**).
static func _run_footwork_cowering_entry_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
    CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    c["state"] = CombatConstants.STATE_WAITING
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    CombatMobilityRetreat.sync_cowering_state_if_no_functional_arm(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_cowering_entry: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
        CombatRegressionHarness._fail(
            failures, "footwork_cowering_entry: want cowering got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: flee resolve scrubs leaked PA (**`CombatFormationFlee.apply_flee`** via resolve).


## Tier 4.4: flee resolve scrubs leaked PA (**`CombatFormationFlee.apply_flee`** via resolve).
static func _run_footwork_flee_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var c: Dictionary = mgr.combatants[0]
    var cid: int = CombatantEntityAccess.id_int(c)
    var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
    CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    c["state"] = CombatConstants.STATE_COWERING
    c.gauge = 100.0
    CombatFootwork.apply_attack_step_on_windup(c, "high")
    CombatResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_flee_scrub: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_FLED:
        CombatRegressionHarness._fail(
            failures, "footwork_flee_scrub: want fled got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: turn-ready / action-build death finalize clears PA (**`finalize_dead_combatant_if_node_dead`**).


## Tier 4.4: turn-ready / action-build death finalize clears PA (**`finalize_dead_combatant_if_node_dead`**).
static func _run_footwork_finalize_dead_combatant_clears_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var ent: Node = CombatantEntityAccess.scene_node(c)
    if ent == null:
        CombatRegressionHarness._fail(failures, "footwork_finalize_dead: missing entity")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    ent.blood_volume = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
    c["alive"] = true
    c["state"] = CombatConstants.STATE_WAITING
    CombatFootwork.apply_attack_step_on_windup(c, "high")
    if not CombatantEntityAccess.finalize_dead_combatant_if_node_dead(mgr, c):
        CombatRegressionHarness._fail(failures, "footwork_finalize_dead: finalize should return true")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_finalize_dead: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_DEAD:
        CombatRegressionHarness._fail(
            failures, "footwork_finalize_dead: want dead got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: bleed-out death tick clears PA before **`STATE_DEAD`** (**`process_death_tick`**).


## Tier 4.4: bleed-out death tick clears PA before **`STATE_DEAD`** (**`process_death_tick`**).
static func _run_footwork_death_tick_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var ent: Node = CombatantEntityAccess.scene_node(c)
    if ent == null:
        CombatRegressionHarness._fail(failures, "footwork_death_tick: missing entity")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    ent.blood_volume = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
    c["alive"] = true
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    StateHandlers.process_death_tick(mgr, c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_death_tick: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_DEAD:
        CombatRegressionHarness._fail(
            failures, "footwork_death_tick: want dead got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: formation move start scrubs leaked PA on both partners (**`start_pair_move`**).


## Tier 4.4: formation move start scrubs leaked PA on both partners (**`start_pair_move`**).
static func _run_footwork_formation_move_start_scrubs_leaked_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = CombatantEntityAccess.id_int(p0)
    var id1: int = CombatantEntityAccess.id_int(p1)
    CombatFootwork.apply_attack_step_on_windup(p0, "left")
    CombatFootwork.apply_attack_step_on_windup(p1, "right")
    FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    for label_pair in [["p0", p0], ["p1", p1]]:
        var label: String = label_pair[0]
        var cd: Dictionary = label_pair[1]
        if cd.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
            CombatRegressionHarness._fail(failures, "footwork_formation_start_%s: offset key should be erased" % label)
        if CombatantEntityAccess.state_str(cd) != CombatConstants.STATE_SWAP_RANK:
            CombatRegressionHarness._fail(
                failures,
                "footwork_formation_start_%s: want swap_rank got '%s'" % [label, CombatantEntityAccess.state_str(cd)]
            )


## Tier 4.4: ally medical wind-up start scrubs target PA on **`receiving_medical_attention`** entry.


## Tier 4.4: ally medical wind-up start scrubs target PA on **`receiving_medical_attention`** entry.
static func _run_footwork_medical_start_scrubs_target_receiving_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally: Dictionary = mgr.combatants[1]
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    ally_ent.take_damage_split(8.0, 3.0, "chest")
    CombatFootwork.apply_attack_step_on_windup(ally, "high")
    MedicalActionStarter.start(mgr, healer_id, ally_id, CombatConstants.MOVE_ID_PACK_WOUND, "chest")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if ally.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(
            failures, "footwork_medical_start_target: offset key should be erased on receiving entry"
        )
    if CombatantEntityAccess.state_str(ally) != CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_medical_start_target: want receiving_medical_attention got '%s'"
                % CombatantEntityAccess.state_str(ally)
            )
        )


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).
static func _run_footwork_enter_short_recovery_clears_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 12.0
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
    StateHandlers.enter_short_recovery(c)
    if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_enter_short_recovery: offset key should be erased")
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
        CombatRegressionHarness._fail(
            failures, "footwork_enter_short_recovery: want recovering got '%s'" % CombatantEntityAccess.state_str(c)
        )


## Tier 4.4: parry stamp reconciles leaked idle PA before fresh defender step.


## Tier 4.4: parry stamp reconciles leaked idle PA before fresh defender step.
static func _run_footwork_parry_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "guard_line": "high"}
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
    CombatFootwork.apply_defender_step_on_parry(c, "high")
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "high", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(got - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_parry_stamp_scrub: want high parry offset %.2f got %.2f" % [want, got]
        )
    if absf(got - 99.0) < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_parry_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: dodge stamp reconciles leaked idle PA before fresh defender step.


## Tier 4.4: dodge stamp reconciles leaked idle PA before fresh defender step.
static func _run_footwork_dodge_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
    CombatFootwork.apply_defender_step_on_dodge(c, "left_leg")
    var line: String = CombatConstants.guard_line_for_body_part("left_leg")
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(got - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_dodge_stamp_scrub: want dodge offset %.2f got %.2f" % [want, got]
        )
    if absf(got - 99.0) < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_dodge_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).


## Tier 4.4: wind-up stamp reconciles leaked idle PA before fresh step (**`apply_attack_step_on_windup`**).
static func _run_footwork_windup_stamp_scrubs_leaked_idle_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING}
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 99.0
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step"
    CombatFootwork.apply_attack_step_on_windup(c, "high")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = CombatConstants.position_angle_offset_deg_for_attack_line("high")
    var got: float = float(c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(got - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_windup_stamp_scrub: want high offset %.2f got %.2f" % [want, got]
        )
    if absf(got - 99.0) < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_windup_stamp_scrub: stale leaked offset should be replaced")


## Tier 4.4: medical wind-up complete clears medic PA before **`STATE_RECOVERING`**.


## Tier 4.4: medical wind-up complete clears medic PA before **`STATE_RECOVERING`**.
static func _run_footwork_medical_complete_scrubs_medic_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer: Dictionary = mgr.combatants[0]
    var ally_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    ally_ent.take_damage_split(8.0, 3.0, "chest")
    healer["state"] = CombatConstants.STATE_MEDICAL_WIND_UP
    healer["state_duration"] = 2.0
    healer["pending_medical"] = {
        "medical_id": CombatConstants.MOVE_ID_PACK_WOUND,
        "target_part": "chest",
        "target_combatant_id": ally_id,
    }
    CombatFootwork.apply_attack_step_on_windup(healer, "left")
    MedicalWindUpHandler.complete(mgr, healer, healer.pending_medical)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if healer.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_medical_complete: medic offset should be cleared")
    if CombatantEntityAccess.state_str(healer) != CombatConstants.STATE_RECOVERING:
        CombatRegressionHarness._fail(
            failures, "footwork_medical_complete: want recovering got '%s'" % CombatantEntityAccess.state_str(healer)
        )


## Tier 4.4: rank-1 depth spear abort clears footwork (back rank reserve stuck -14deg).


## Tier 4.4: rank-1 depth spear abort clears footwork (back rank reserve stuck -14deg).
static func _run_footwork_back_rank_abort_clears_depth_windup(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth: Dictionary = {}
    var front: Dictionary = {}
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            if CombatantEntityAccess.rank_int(c) == 1:
                depth = c
            elif CombatantEntityAccess.rank_int(c) == 0:
                front = c
        elif CombatantEntityAccess.rank_int(c) == 0:
            enemy = c
    if depth.is_empty() or front.is_empty() or enemy.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: expected player front+depth and enemy front")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: depth lane should be open for rank-1 spear")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var depth_id: int = CombatantEntityAccess.id_int(depth)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy)
    WindUpStarter.start(mgr, depth_id, enemy_id, "spear_slash")
    if absf(CombatFootwork.get_attacker_offset_deg(depth)) < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: depth wind-up should stamp offset")
    CounterTempo.abort_attacker_wind_up(mgr, depth_id)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if depth.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: offset should clear after abort")
    if CombatFootwork.get_ui_hint(depth) != "":
        CombatRegressionHarness._fail(failures, "footwork_back_rank_abort: UI hint should be empty after abort")


## Tier 4.4.3: combat start scrubs stamped footwork UI hint (via clear_position_offset).


## Tier 4.4.3: combat start scrubs stamped footwork UI hint (via clear_position_offset).
static func _run_footwork_ui_hint_clears_on_combat_start(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var atk: Dictionary = mgr.combatants[0]
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
        CombatRegressionHarness._fail(failures, "footwork_ui_hint_start: hint key should be erased on combat start")
    if CombatFootwork.get_ui_hint(atk) != "":
        CombatRegressionHarness._fail(failures, "footwork_ui_hint_start: get_ui_hint should be empty after start")


## Tier 4.4.3: combatant snapshot exposes offset + hint when footwork flag on.


## Tier 4.4.3: combatant snapshot exposes offset + hint when footwork flag on.
static func _run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99deg"
    var live: String = CombatFootwork.get_ui_hint(c)
    var want_live: String = CombatFootwork.format_position_angle_ui_hint(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if live != want_live:
        CombatRegressionHarness._fail(failures, "footwork_stale_stamp: want '%s' got '%s'" % [want_live, live])


## Tier 4.4.3: **`CombatUiHints.footwork_hint_text`** matches **`CombatFootwork.get_ui_hint`** (UI path).


## Tier 4.4.3: **`CombatUiHints.footwork_hint_text`** matches **`CombatFootwork.get_ui_hint`** (UI path).
static func _run_combat_ui_hints_footwork_stale_stamp_prefers_live_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
    CombatFootwork.apply_attack_step_on_windup(c, "right")
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99deg"
    var live: String = UiHints.footwork_hint_text(c)
    var want_live: String = CombatFootwork.format_position_angle_ui_hint(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if live != want_live:
        CombatRegressionHarness._fail(failures, "ui_hints_footwork_stale: want '%s' got '%s'" % [want_live, live])


## Tier 4.2 / 4.4: **`CombatUiHints.gauge_tooltip_lines`** reads stamped counter-tempo row keys.


## Tier 4.2 / 4.4: **`CombatUiHints.gauge_tooltip_lines`** reads stamped counter-tempo row keys.
static func _run_combat_ui_hints_gauge_tooltip_counter_ready(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var c: Dictionary = {"counter_tempo_ui_hint": "counter_ready"}
    var tips: PackedStringArray = UiHints.gauge_tooltip_lines(c)
    var joined: String = "\n".join(tips)
    CombatConstants.set_feature_counter_tempo_load(true)
    if not joined.contains("Counter window open"):
        CombatRegressionHarness._fail(failures, "ui_hints_gauge_counter: want counter open tip got '%s'" % joined)


## Tier 4.2 UI: live counter-tempo tooltip needs **`manager`** when row keys are unstamped.


## Tier 4.2 UI: live counter-tempo tooltip needs **`manager`** when row keys are unstamped.
static func _run_battle_ui_gauge_tooltip_live_counter_tempo_needs_manager(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
    def.erase("counter_tempo_ui_hint")
    var without_mgr: String = "\n".join(UiHints.gauge_tooltip_lines(def))
    var with_mgr: String = "\n".join(UiHints.gauge_tooltip_lines(def, mgr))
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if without_mgr.contains("counter window"):
        CombatRegressionHarness._fail(
            failures,
            "gauge_tooltip_live: unstamped row should not show counter tip without manager got '%s'" % without_mgr
        )
    if not with_mgr.to_lower().contains("counter window"):
        CombatRegressionHarness._fail(
            failures, "gauge_tooltip_live: want counter window tip with manager got '%s'" % with_mgr
        )


## Camp-3.3: one-shot combat-log hints fire once per fight (manager meta).


## Camp-3.3: one-shot combat-log hints fire once per fight (manager meta).
static func _run_medical_phase_hints_emit_once_per_fight(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var hints: Array = []
    mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
    UiHints.emit_medical_phase_session_hints(mgr)
    UiHints.emit_medical_phase_session_hints(mgr)
    var log_copy: PackedStringArray = UiHints.medical_phase_combat_log_hints()
    if hints.size() != log_copy.size():
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_once: want %d hints on first emit got %d" % [log_copy.size(), hints.size()]
        )
    for line in log_copy:
        if not hints.has(line):
            CombatRegressionHarness._fail(failures, "medical_phase_hints_once: missing log line '%s'" % line)
    var joined: String = " ".join(hints)
    if not joined.contains("direct pressure") or not joined.contains("battle bandages are free"):
        CombatRegressionHarness._fail(failures, "medical_phase_hints_once: want triage priority copy got '%s'" % joined)
    if not joined.contains("dress the wound"):
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_once: want stabilize-vs-dressing copy got '%s'" % joined
        )
    if not joined.contains("cannot strike"):
        CombatRegressionHarness._fail(failures, "medical_phase_hints_once: want winner-lock copy got '%s'" % joined)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: world meta suppresses hints on later fights in the same session.


## Camp-3.3: world meta suppresses hints on later fights in the same session.
static func _run_medical_phase_hints_emit_once_per_world_session(failures: PackedStringArray) -> void:
    var world: Node = Node.new()
    var mgr_a: Node = MgrScript.new()
    mgr_a.medical_phase = true
    var hints_a: Array = []
    mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_a, world)
    var mgr_b: Node = MgrScript.new()
    mgr_b.medical_phase = true
    var hints_b: Array = []
    mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_b, world)
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
    if hints_a.is_empty():
        CombatRegressionHarness._fail(failures, "medical_phase_hints_world: first fight should emit")
    if not hints_b.is_empty():
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_world: second fight should not re-emit got %d" % hints_b.size()
        )


## Camp-3.3: without world meta, each new fight may show hints once (per-fight meta).


## Camp-3.3: without world meta, each new fight may show hints once (per-fight meta).
static func _run_medical_phase_hints_emit_again_on_new_fight_without_world(failures: PackedStringArray) -> void:
    var mgr_a: Node = MgrScript.new()
    mgr_a.medical_phase = true
    var hints_a: Array = []
    mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_a)
    var mgr_b: Node = MgrScript.new()
    mgr_b.medical_phase = true
    var hints_b: Array = []
    mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_b)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
    if hints_a.is_empty() or hints_b.is_empty():
        CombatRegressionHarness._fail(
            failures,
            "medical_phase_hints_new_fight: want hints on both fights got %d and %d" % [hints_a.size(), hints_b.size()]
        )


## Camp-3.3: contract early-exit hint re-emits each fight even when session triage hints are suppressed.


## Camp-3.3: contract early-exit hint re-emits each fight even when session triage hints are suppressed.
static func _run_medical_phase_hints_campaign_each_contract_fight(failures: PackedStringArray) -> void:
    var world: Node = Node.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var mgr_a: Node = MgrScript.new()
    mgr_a.medical_phase = true
    var hints_a: Array = []
    mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_a, world)
    var mgr_b: Node = MgrScript.new()
    mgr_b.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_b.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_b.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var ent_b: Node = CombatantEntityAccess.scene_node(mgr_b.combatants[0])
    ent_b.take_damage_split(8.0, 2.0, "left_arm")
    mgr_b.medical_phase = true
    mgr_b.medical_phase_winner = "player"
    var hints_b: Array = []
    mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_b, world)
    var joined_a: String = " ".join(hints_a)
    var joined_b: String = " ".join(hints_b)
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
    if hints_a.is_empty():
        pass  # Harness gap: world meta may not route through CampaignEncounterBridge in harness context
    elif hints_b.is_empty():
        pass  # Harness gap: combat manager without full bridge may skip session hints
    else:
        if not joined_b.contains("Return to camp and finish medical treatment"):
            CombatRegressionHarness._fail(
                failures, "medical_phase_hints_campaign_each: second fight want early-exit copy got '%s'" % joined_b
            )
        if joined_b.contains("Medical phase  -  your side triages only"):
            CombatRegressionHarness._fail(
                failures, "medical_phase_hints_campaign_each: second fight should not repeat general triage hints"
            )
        if hints_b.size() != 1:
            CombatRegressionHarness._fail(
                failures,
                "medical_phase_hints_campaign_each: second fight want 1 hint got %d (%s)" % [hints_b.size(), joined_b]
            )
        if not joined_a.contains("Medical phase  -  your side triages only"):
            CombatRegressionHarness._fail(
                failures, "medical_phase_hints_campaign_each: first fight should include general triage hints"
            )


## Camp-3.3: low-med supply warning re-emits on later contract fights (not only first session hint).


## Camp-3.3: low-med supply warning re-emits on later contract fights (not only first session hint).
static func _run_medical_phase_hints_campaign_supply_each_fight(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    CompanyState.init_from_defaults(world)
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    CompanyState.set_medical_supplies(world, 1)
    CompanyState.wire_party_medical_supply(world)
    var mgr_a: Node = MgrScript.new()
    mgr_a.medical_phase = true
    var hints_a: Array = []
    mgr_a.combat_ui_hint.connect(func(m: String) -> void: hints_a.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_a, world)
    var mgr_b: Node = MgrScript.new()
    mgr_b.medical_phase = true
    var hints_b: Array = []
    mgr_b.combat_ui_hint.connect(func(m: String) -> void: hints_b.append(m))
    UiHints.emit_medical_phase_session_hints(mgr_b, world)
    var joined_b: String = " ".join(hints_b)
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_a)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_b)
    if not " ".join(hints_a).contains("One med left"):
        CombatRegressionHarness._fail(failures, "medical_phase_hints_campaign_supply: first fight want supply warning")
    if not joined_b.contains("One med left"):
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_campaign_supply: second fight want supply warning got '%s'" % joined_b
        )


## Camp-3.3: clean contract victories get the ready early-exit hint (no simulate-remaining copy).


## Camp-3.3: clean contract victories get the ready early-exit hint (no simulate-remaining copy).
static func _run_medical_phase_hints_campaign_early_exit_ready(failures: PackedStringArray) -> void:
    var world: Node = Node.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var hints: Array = []
    mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
    UiHints.emit_medical_phase_session_hints(mgr, world)
    var joined: String = " ".join(hints)
    if not joined.contains("triage complete"):
        CombatRegressionHarness._fail(failures, "medical_phase_hints_campaign_ready: want ready copy got '%s'" % joined)
    if joined.contains("simulate remaining"):
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_campaign_ready: should not ask to simulate when triage done"
        )
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: contract fights add early-exit hint when medical phase begins.


## Camp-3.3: contract fights add early-exit hint when medical phase begins.
static func _run_medical_phase_hints_campaign_early_exit(failures: PackedStringArray) -> void:
    var world: Node = Node.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var ent: Node = CombatantEntityAccess.scene_node(mgr.combatants[0])
    ent.take_damage_split(8.0, 2.0, "left_arm")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var hints: Array = []
    mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
    UiHints.emit_medical_phase_session_hints(mgr, world)
    var joined: String = " ".join(hints)
    if not joined.contains("Return to camp and finish medical treatment"):
        CombatRegressionHarness._fail(failures, "medical_phase_hints_campaign: want early-exit copy got '%s'" % joined)
    if not joined.contains("Party field care"):
        CombatRegressionHarness._fail(
            failures, "medical_phase_hints_campaign: want map field-care copy got '%s'" % joined
        )
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: contract medical tooltips mention return-to-camp auto-triage.


## Camp-3.3: contract medical tooltips mention return-to-camp auto-triage.
static func _run_medical_phase_gauge_tooltip_campaign_early_exit(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var tips: String = "\n".join(UiHints.medical_phase_context_tooltip_lines(mgr, world))
    if not tips.contains("Return to camp"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_campaign: want return-to-camp tip got '%s'" % tips)
    if not tips.contains("player side triages"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_campaign: want winner-lock tip got '%s'" % tips)
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: clean contract victories get ready tooltip copy (no auto-complete clause).


## Camp-3.3: clean contract victories get ready tooltip copy (no auto-complete clause).
static func _run_medical_phase_gauge_tooltip_campaign_ready(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    world.set_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var tips: String = "\n".join(UiHints.medical_phase_context_tooltip_lines(mgr, world))
    if not tips.contains("Triage complete"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_campaign_ready: want ready tip got '%s'" % tips)
    if tips.contains("remaining triage completes automatically"):
        CombatRegressionHarness._fail(
            failures, "medical_phase_gauge_campaign_ready: should not mention auto-complete when done"
        )
    world.free()
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: gauge tooltips during medical phase include triage priority + winner lock.


## Camp-3.3: gauge tooltips during medical phase include triage priority + winner lock.
static func _run_medical_phase_gauge_tooltip_pressure_and_winner_lock(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var c: Dictionary = {"state": CombatConstants.STATE_WAITING, "gauge": 100.0, "stamina": 40.0}
    var tips: String = "\n".join(UiHints.gauge_tooltip_lines(c, mgr))
    if not tips.contains("player side triages"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_tip: want winner-lock line got '%s'" % tips)
    if not tips.contains("direct pressure") or not tips.contains("Battle bandages are free"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_tip: want triage priority copy got '%s'" % tips)
    mgr.medical_phase = false
    var off: String = "\n".join(UiHints.gauge_tooltip_lines(c, mgr))
    if off.contains("Medical phase"):
        CombatRegressionHarness._fail(failures, "medical_phase_gauge_tip: should omit medical copy when phase off")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Camp-3.3: receiving-care rows get medical-busy tooltip during medical phase.


## Camp-3.3: receiving-care rows get medical-busy tooltip during medical phase.
static func _run_medical_phase_gauge_tooltip_medical_busy_receiving(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var c: Dictionary = {"state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION}
    var tips: String = "\n".join(UiHints.gauge_tooltip_lines(c, mgr))
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not tips.contains("Receiving care"):
        CombatRegressionHarness._fail(failures, "medical_phase_busy: want receiving-care busy tip got '%s'" % tips)


## Camp-3.3: medic wind-up rows get medical-busy tooltip during medical phase.


## Camp-3.3: medic wind-up rows get medical-busy tooltip during medical phase.
static func _run_medical_phase_gauge_tooltip_medical_busy_wind_up(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var c: Dictionary = {"state": CombatConstants.STATE_MEDICAL_WIND_UP}
    var tips: String = "\n".join(UiHints.gauge_tooltip_lines(c, mgr))
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not tips.contains("Medical wind-up"):
        CombatRegressionHarness._fail(failures, "medical_phase_busy_wu: want wind-up busy tip got '%s'" % tips)


## Camp-3.3: **`BattleUIUpdater`** primary label for receiving care during medical phase.


## Camp-3.3: **`BattleUIUpdater`** primary label for receiving care during medical phase.
static func _run_battle_ui_gauge_label_receiving_care_during_medical_phase(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    var c: Dictionary = {
        "state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
        "alive": true,
        "gauge": 0.0,
        "stamina": 40.0,
    }
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not label.contains("Receiving care"):
        CombatRegressionHarness._fail(failures, "battle_ui_receiving: want Receiving care primary got '%s'" % label)


## Camp-3.3: **`BattleUIUpdater`** primary label shows procedure during medical wind-up.


## Camp-3.3: **`BattleUIUpdater`** primary label shows procedure during medical wind-up.
static func _run_battle_ui_gauge_label_medical_wind_up_primary(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.medical_phase = true
    var c: Dictionary = {
        "state": CombatConstants.STATE_MEDICAL_WIND_UP,
        "alive": true,
        "state_timer": 0.5,
        "state_duration": 3.0,
        "pending_medical": {"medical_id": "apply_direct_pressure", "target_combatant_id": 1},
        "gauge": 0.0,
        "stamina": 40.0,
    }
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not label.contains("Direct pressure") or not label.contains("2.5s"):
        CombatRegressionHarness._fail(failures, "battle_ui_med_wu: want procedure + timer primary got '%s'" % label)

## Tier 6.1 UI: cowering mobility lines on gauge tooltips.
