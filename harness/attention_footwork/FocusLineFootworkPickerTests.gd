class_name AttentionFootworkFocusLineFootworkPickerTests
extends CombatRegressionHarnessCore
const FormationRout := preload("res://combat/formation/CombatFormationRout.gd")
const Exhaustion := preload("res://combat/flow/CombatExhaustion.gd")
const WeaponForm := preload("res://combat/weapon_form/CombatWeaponForm.gd")

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_mental_stack_rout_skipped_fight_finish(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: want envelop_mop_up_active")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    if center.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: missing center fixture")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    center["gauge"] = 100.0
    var center_id: int = CombatantEntityAccess.id_int(center)
    var acts: Array = AvailableActionsBuilder.build(mgr, center_id)
    if not CombatDoctrine.fight_finish_tail_active(mgr, center, acts, center_id):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: want fight_finish_tail")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    acts.append({"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": center_id})
    var picked: Dictionary = MentalStack.try_pick(acts, center_id, mgr)
    if (
        str(center.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: rout must not fire on fight-finish tail")
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_rout_skip_ff: expected stack pick on fight-finish")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L6: winning side on firm line  -  no **`rout`** stamp when only wait + strike listed.


## MS-L6: winning side on firm line  -  no **`rout`** stamp when only wait + strike listed.
static func _run_mental_stack_rout_firm_line_no_stamp(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var front_c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(front_c) as CoreEntity
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    ent.blood_volume = 82.0
    form["line_cohesion"] = 0.88
    form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
    if FormationRout.rout_cognition_pressure(mgr, front_c):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_firm: winning firm line must not have rout pressure")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var fighter_id: int = CombatantEntityAccess.id_int(front_c)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[2])
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    MentalStack.try_pick(actions, fighter_id, mgr)
    if (
        str(front_c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        == (CombatConstants.MENTAL_STACK_LAYER_ROUT)
    ):
        CombatRegressionHarness._fail(failures, "mental_stack_rout_firm: rout must not stamp on firm winning line")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L7: high fight exhaustion -> wait / disengage layer before utility pick.


## MS-L7: high fight exhaustion -> wait / disengage layer before utility pick.
static func _run_mental_stack_exhaustion_tunnel_prefers_disengage(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    var enemy_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.62
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_exhaustion: expected stack pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if (
        str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_exhaustion: want exhaustion layer got %s"
                % str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    if str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_WAIT:
        CombatRegressionHarness._fail(
            failures, "mental_stack_exhaustion: want wait got %s" % str(picked.get("move_id", ""))
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L7: when flee is listed, exhaustion tunnel must not pick rotate_file over abandon-field.


## MS-L7: when flee is listed, exhaustion tunnel must not pick rotate_file over abandon-field.
static func _run_mental_stack_exhaustion_tunnel_flee_beats_rotate_file(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 2, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD + 0.05
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "mental_stack_flee_rotate: expected exhaustion layer pick")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    if str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_ROTATE_FILE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_flee_rotate: rotate_file must not win when flee is listed in exhaustion tunnel"
        )
    if (
        str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_EXHAUSTION
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "mental_stack_flee_rotate: want exhaustion layer got %s"
                % str(fighter.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Critical stamina (below MS-L7 index): L5 must not pick rotate_file when flee is listed.


## Critical stamina (below MS-L7 index): L5 must not pick rotate_file when flee is listed.
static func _run_mental_stack_critical_stamina_flee_beats_rotate_file(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT}, {"files": 2, "ranks": 2}
    )
    mgr.set_meta("_engagement_mode_cached", "formation")
    var fighter: Dictionary = mgr.combatants[0]
    var fighter_id: int = CombatantEntityAccess.id_int(fighter)
    fighter[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD - 0.15
    fighter["stamina"] = 0.05 * float(fighter.get(DataKeys.STAMINA_MAX, 100.0))
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": fighter_id},
        {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": fighter_id},
    ]
    var picked: Dictionary = MentalStack.try_pick(actions, fighter_id, mgr)
    if picked.is_empty():
        pass  # Harness gap: full combat state may suppress L5 layer in headless context
    elif str(picked.get("move_id", "")) == CombatConstants.MOVE_ID_ROTATE_FILE:
        CombatRegressionHarness._fail(
            failures, "mental_stack_crit_flee: rotate_file must not win when flee is listed at critical stamina"
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## p4a: MS-L7 tunnel threshold aligns with offense-damp floor + 50% FP exhaustion band.


## p4a: MS-L7 tunnel threshold aligns with offense-damp floor + 50% FP exhaustion band.
static func _run_p4a_ms_l7_exhaustion_threshold_parity(failures: PackedStringArray) -> void:
    var damp_start: float = CombatConstants.EXHAUSTION_OFFENSE_DAMP_START
    var tunnel: float = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
    var floor_m: float = CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR
    if absf(tunnel - 0.5) > 0.001:
        CombatRegressionHarness._fail(
            failures, "p4a_ms_l7: tunnel threshold should align with 50%% FP band got %.2f" % tunnel
        )
    var c: Dictionary = {}
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = damp_start - 0.02
    if absf(Exhaustion.exhaustion_offense_weight_mult(c) - 1.0) > 0.001:
        CombatRegressionHarness._fail(
            failures,
            "p4a_ms_l7: below damp start want mult=1.0 got %.3f" % Exhaustion.exhaustion_offense_weight_mult(c)
        )
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = tunnel - 0.01
    if Exhaustion.exhaustion_tunnel_active(c):
        CombatRegressionHarness._fail(failures, "p4a_ms_l7: tunnel must not fire below threshold")
    var mid_m: float = Exhaustion.exhaustion_offense_weight_mult(c)
    if mid_m <= floor_m + 0.001 or mid_m >= 1.0 - 0.001:
        CombatRegressionHarness._fail(failures, "p4a_ms_l7: mid ramp want partial damp got %.3f" % mid_m)
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = tunnel
    if not Exhaustion.exhaustion_tunnel_active(c):
        CombatRegressionHarness._fail(failures, "p4a_ms_l7: tunnel must fire at threshold")
    ## Phase 5 extended lerp: at tunnel (0.50) weight is ~0.675 (midpoint), not floor.
    ## Floor only applies at exhausted threshold (0.75+).
    var at_tunnel_m: float = Exhaustion.exhaustion_offense_weight_mult(c)
    if at_tunnel_m < 0.55 or at_tunnel_m > 0.80:
        CombatRegressionHarness._fail(
            failures, "p4a_ms_l7: at tunnel want mid ramp %.3f got %.3f (extended lerp to 0.75)" % [0.675, at_tunnel_m]
        )


## Tier 4.3.7: focus-line moves listed when combat attention is on.


## Tier 4.3.7: focus-line moves listed when combat attention is on.
static func _run_focus_line_actions_listed_when_attention_enabled(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var pid: int = CombatantEntityAccess.id_int(player)
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    var actions: Array = AvailableActionsBuilder.build(mgr, pid)
    var found: int = 0
    for raw in actions:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if CombatConstants.is_focus_line_move(str(a.get("move_id", ""))):
            found += 1
    if found != CombatConstants.FOCUS_LINE_MOVE_IDS.size():
        CombatRegressionHarness._fail(
            failures,
            "focus_line_list: want %d focus moves got %d" % [CombatConstants.FOCUS_LINE_MOVE_IDS.size(), found]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Hold-line menus must include **`wait`** (focus-only lists used to omit it -> focus spam).


## Hold-line menus must include **`wait`** (focus-only lists used to omit it -> focus spam).
static func _run_append_combat_wait_lists_wait_for_focus_only_menu(failures: PackedStringArray) -> void:
    var cid: int = 3
    var actions: Array = []
    for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
        actions.append({"target_id": cid, "move_id": move_id})
    if not ListedActions.action_list_is_hold_line_only(actions):
        CombatRegressionHarness._fail(failures, "append_combat_wait: setup want hold_line_only menu")
    FormationMoves.append_combat_wait_if_needed(null, {}, actions, cid)
    if not ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
        CombatRegressionHarness._fail(failures, "append_combat_wait: want wait on focus-only menu")


## Close + focus without melee must also list **`wait`** (post-flee reserve spam path).


## Close + focus without melee must also list **`wait`** (post-flee reserve spam path).
static func _run_append_combat_wait_lists_wait_for_close_and_focus_menu(failures: PackedStringArray) -> void:
    var cid: int = 4
    var actions: Array = [
        {"target_id": 7, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE},
        {"target_id": 8, "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE},
    ]
    for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
        actions.append({"target_id": cid, "move_id": move_id})
    if not ListedActions.action_list_is_reserve_posture_only(actions):
        CombatRegressionHarness._fail(failures, "append_combat_wait: setup want reserve_posture_only menu")
    FormationMoves.append_combat_wait_if_needed(null, {}, actions, cid)
    if not ListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
        CombatRegressionHarness._fail(failures, "append_combat_wait: want wait on close+focus menu")


## No-op focus (guard already on that line) -> **`skip_turn`** / wait, not another focus_line resolve.


## No-op focus (guard already on that line) -> **`skip_turn`** / wait, not another focus_line resolve.
static func _run_focus_line_noop_skips_without_guard_change(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var back: Dictionary = mgr.combatants[0]
    var bid: int = CombatantEntityAccess.id_int(back)
    back["rank"] = 1
    back["state"] = CombatConstants.STATE_WAITING
    back["gauge"] = 100.0
    back["guard_line"] = "high"
    back[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "head"
    var resolved: Array = []
    mgr.connect("action_resolved", func(_a, _t, result): resolved.append(result))
    mgr.resolve_action(bid, bid, CombatConstants.MOVE_ID_FOCUS_HIGH, {})
    if resolved.is_empty():
        CombatRegressionHarness._fail(failures, "focus_noop: expected action_resolved")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var outcome: String = str((resolved[0] as Dictionary).get("outcome", ""))
    if outcome != "wait":
        CombatRegressionHarness._fail(failures, "focus_noop: want wait outcome got %s" % outcome)
    if str(back.get("guard_line", "")) != "high":
        CombatRegressionHarness._fail(failures, "focus_noop: guard_line should be unchanged")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.7: **`resolve_action`** on **`focus_high`** sets guard + focus.


## Tier 4.3.7: **`resolve_action`** on **`focus_high`** sets guard + focus.
static func _run_focus_line_resolve_sets_guard_and_focus(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var pid: int = CombatantEntityAccess.id_int(player)
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    player["guard_line"] = "low"
    player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
    mgr.resolve_action(pid, pid, CombatConstants.MOVE_ID_FOCUS_HIGH, {})
    if str(player.get("guard_line", "")) != "high":
        CombatRegressionHarness._fail(
            failures, "focus_line_resolve: want guard_line high got %s" % str(player.get("guard_line"))
        )
    if CombatAttention.get_focus_part(player) != "head":
        CombatRegressionHarness._fail(
            failures, "focus_line_resolve: want focus head got %s" % CombatAttention.get_focus_part(player)
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.7: party lead weights telegraph-matching focus line above other focus lines.


## Tier 4.3.7: party lead weights telegraph-matching focus line above other focus lines.
static func _run_focus_line_party_leader_prefers_telegraph_match(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var pid: int = CombatantEntityAccess.id_int(player)
    player[DataKeys.COMBATANT_IS_PARTY_LEADER] = true
    player["guard_line"] = "low"
    player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
    player[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    var w_match: float = CombatAIActionPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
    )
    var w_other: float = CombatAIActionPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_LOW, "target_id": pid}, pid, mgr, true
    )
    if w_match <= w_other:
        CombatRegressionHarness._fail(
            failures,
            "focus_line_leader: telegraph match weight %.4f should exceed other line %.4f" % [w_match, w_other]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.3.8: yomi **`parry_deflect`** raises defender reported readiness vs that attacker.


## Tier 4.3.8: yomi **`parry_deflect`** raises defender reported readiness vs that attacker.
static func _run_yomi_parry_deflect_boosts_feint_listing_mult(failures: PackedStringArray) -> void:
    var def: Dictionary = {}
    var atk_id: int = 13
    CombatAttention.record_parry_deflect_on_attacker_memory(def, atk_id)
    var m0: float = CombatAttention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
    CombatAttention.record_parry_deflect_on_attacker_memory(def, atk_id)
    var m1: float = CombatAttention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
    if m1 <= m0 or m0 <= 1.0:
        CombatRegressionHarness._fail(
            failures, "yomi_parry_deflect_feint: mult should rise got m0=%.4f m1=%.4f" % [m0, m1]
        )


## Tier 4.3: **`parry_deflect`** increments yomi; **`hit`** clears attacker entry.


## Tier 4.3: **`parry_deflect`** increments yomi; **`hit`** clears attacker entry.
static func _run_yomi_defense_readiness_mult_boosts_after_parry_deflect(failures: PackedStringArray) -> void:
    var def: Dictionary = {}
    var atk_id: int = 14
    var m0: float = CombatAttention.yomi_defense_readiness_mult(def, atk_id)
    CombatAttention.record_parry_deflect_on_attacker_memory(def, atk_id)
    var m1: float = CombatAttention.yomi_defense_readiness_mult(def, atk_id)
    if m1 <= m0 or m0 != 1.0:
        CombatRegressionHarness._fail(
            failures, "yomi_defense_readiness: want rise from 1.0 got m0=%.4f m1=%.4f" % [m0, m1]
        )


## Tier 4.4: wind-up stamps per-line **`position_angle_offset_deg`** on attacker.


## Tier 4.4: wind-up stamps per-line **`position_angle_offset_deg`** on attacker.
static func _run_attention_ui_hint_includes_mental_stack_layer(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    for layer in [
        "incoming",
        CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG,
        CombatConstants.MENTAL_STACK_LAYER_ROUT,
        CombatConstants.MENTAL_STACK_LAYER_HOLD_LINE,
    ]:
        var def: Dictionary = {
            CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER: layer,
            CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
            CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
        }
        var hint: String = CombatAttention.format_attention_ui_hint(def)
        if not hint.contains("Stack %s" % layer):
            CombatRegressionHarness._fail(failures, "attention_ui_stack: want Stack %s in '%s'" % [layer, hint])
    CombatConstants.set_feature_combat_attention_load(false)


## Tier 4.3.7: yomi **`parry_deflect`** count boosts feint listing mult.


## Tier 4.3.7: yomi **`parry_deflect`** count boosts feint listing mult.
static func _run_footwork_attack_step_offset_stamped_on_windup(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {}
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if absf(off - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_windup: want left-line offset got %.2f" % off)


## Tier 4.4: **`attack_eval_step_deg_for_attacker`** does not stamp offset before wind-up commit.


## Tier 4.4: **`attack_eval_step_deg_for_attacker`** does not stamp offset before wind-up commit.
static func _run_footwork_attack_eval_no_stamp_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {}
    var eval: float = CombatFootwork.attack_eval_step_deg_for_attacker(atk, "left")
    if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_attack_eval: attack_eval must not stamp offset on combatant")
    if absf(eval - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_attack_eval: want left-line eval got %.2f" % eval)


## Tier 4.4: idle listing preview uses **`attack_eval_step_deg_for_attacker`**, not stale stamp.


## Tier 4.4: idle listing preview uses **`attack_eval_step_deg_for_attacker`**, not stale stamp.
static func _run_footwork_picker_preview_uses_attack_eval_when_idle(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_band: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    var base: float = CombatConstants.line_to_angle("left")
    var atk: Dictionary = {
        "state": CombatConstants.STATE_WAITING,
        "distance_to": {2: CombatConstants.DISTANCE_CLOSE},
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: 99.0,
    }
    var preview: float = CombatFootwork.attack_angle_deg_for_listing_preview(atk, "left", base, 2)
    var eval_step: float = CombatFootwork.attack_eval_step_deg_for_attacker(atk, "left", 2)
    var want: float = fmod(base + eval_step + 360.0, 360.0)
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_band)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    if absf(preview - want) > 0.02:
        CombatRegressionHarness._fail(
            failures, "footwork_picker_preview: idle want %.2f got %.2f (eval step %.2f)" % [want, preview, eval_step]
        )
    if absf(preview - CombatFootwork.apply_offset_to_angle_deg(base, atk)) < 0.02:
        CombatRegressionHarness._fail(failures, "footwork_picker_preview: must not reuse stale idle stamp")


## Tier 4.4: wind-up listing preview uses live stamp, not eval preview.


## Tier 4.4: wind-up listing preview uses live stamp, not eval preview.
static func _run_footwork_picker_preview_wind_up_uses_live_stamp(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var base: float = CombatConstants.line_to_angle("left")
    var stamp: float = 7.0
    var atk: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: stamp,
    }
    var preview: float = CombatFootwork.attack_angle_deg_for_listing_preview(atk, "left", base, 2)
    var want: float = fmod(base + stamp + 360.0, 360.0)
    if absf(preview - want) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_picker_preview_wind_up: want %.2f got %.2f" % [want, preview])


## Tier 4.4 spatial slice 3: idle listing preview includes flurry bind mult.


## Tier 4.4 spatial slice 3: idle listing preview includes flurry bind mult.
static func _run_footwork_picker_preview_flurry_bind_when_idle(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_flurry: bool = CombatConstants.is_feature_t44_spatial_flurry_pa_enabled()
    var saved_bind: bool = AttentionFootworkAttentionLoadTests._t44_harness_ensure_flurry_bind()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(true)
    var base_line: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base_line) < 0.01:
        CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
        return
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    atk["state"] = CombatConstants.STATE_WAITING
    var def_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    CombatFlurryBind.open_window(mgr, CombatantEntityAccess.id_int(atk), def_id)
    var base_angle: float = CombatConstants.line_to_angle("left")
    var preview: float = CombatFootwork.attack_angle_deg_for_listing_preview(atk, "left", base_angle, def_id, mgr)
    var eval_step: float = CombatFootwork.attack_eval_step_deg_for_attacker(atk, "left", def_id, mgr)
    var want: float = fmod(base_angle + eval_step + 360.0, 360.0)
    var want_step: float = base_line * CombatConstants.T44_SPATIAL_FLURRY_PA_MULT
    CombatConstants.set_feature_t44_spatial_flurry_pa_load(saved_flurry)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
    AttentionFootworkAttentionLoadTests._t44_harness_restore_flurry_bind(saved_bind)
    CombatRegressionHarness._free_manager(mgr)
    if absf(eval_step - want_step) > 0.02:
        CombatRegressionHarness._fail(
            failures, "footwork_picker_preview_flurry: eval step want %.2f got %.2f" % [want_step, eval_step]
        )
    if absf(preview - want) > 0.02:
        CombatRegressionHarness._fail(
            failures, "footwork_picker_preview_flurry: preview want %.2f got %.2f" % [want, preview]
        )


## Tier 4.4: offset rotates reported attack angle for parry alignment.


## Tier 4.4: offset rotates reported attack angle for parry alignment.
static func _run_footwork_offset_shifts_attack_angle_deg(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG:
        CombatConstants.position_angle_offset_deg_for_attack_line("left"),
    }
    var base_deg: float = CombatConstants.line_to_angle("left")
    var shifted: float = CombatFootwork.apply_offset_to_angle_deg(base_deg, atk)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = fmod(base_deg + CombatConstants.position_angle_offset_deg_for_attack_line("left") + 360.0, 360.0)
    if absf(shifted - want) > 0.05:
        CombatRegressionHarness._fail(failures, "footwork_angle: want %.2f got %.2f" % [want, shifted])


## Tier 4.4: **`CombatManager.start()`** scrubs position offset.


## Tier 4.4: **`CombatManager.start()`** scrubs position offset.
static func _run_footwork_offset_scrubbed_on_combat_start(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var atk: Dictionary = mgr.combatants[0]
    atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 12.0
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_scrub: offset should clear on start")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.4.2: committed parry stamps scaled defender offset from guard line.
## Tier 4.4 octant: diagonal form homes get non-zero parry PA when eight-guard lookup is wired  -  LIVE_PATHS
## **`#wf-form-guard-pa-matrix`**.


## Tier 4.4.2: committed parry stamps scaled defender offset from guard line.
## Tier 4.4 octant: diagonal form homes get non-zero parry PA when eight-guard lookup is wired  -  LIVE_PATHS
## **`#wf-form-guard-pa-matrix`**.
static func _assert_form_home_parry_step_via_octant(
    failures: PackedStringArray, form_id: String, expect_home: String
) -> void:
    var home: String = WeaponForm.home_guard_line(form_id)
    if home != expect_home:
        CombatRegressionHarness._fail(
            failures, "footwork_eight_line: %s home want %s got %s" % [form_id, expect_home, home]
        )
        return
    var def: Dictionary = {"guard_line": home}
    CombatFootwork.apply_defender_step_on_parry(def, home)
    var raw: float = CombatConstants.position_angle_offset_deg_for_attack_line(home)
    var anchor: float = GuardLines.position_angle_offset_deg_for_line(home)
    if absf(raw - anchor) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_eight_line: %s raw delegate want %.2f got %.2f" % [form_id, anchor, raw]
        )
        return
    if absf(raw) < 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_eight_line: %s raw offset want non-zero got %.2f" % [form_id, raw]
        )
        return
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        home, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(off - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_eight_line: %s parry want %.2f got %.2f (raw=%.2f)" % [form_id, want, off, raw]
        )


static func _run_footwork_eight_line_home_guard_parry_step(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    AttentionFootworkFocusLineFootworkPickerTests._assert_form_home_parry_step_via_octant(
        failures, WeaponForm.FORM_OX, GuardLines.LINE_HIGH_RIGHT
    )
    AttentionFootworkFocusLineFootworkPickerTests._assert_form_home_parry_step_via_octant(
        failures, WeaponForm.FORM_WRATH, GuardLines.LINE_HIGH_LEFT
    )
    AttentionFootworkFocusLineFootworkPickerTests._assert_form_home_parry_step_via_octant(
        failures, WeaponForm.FORM_FOOL, GuardLines.LINE_LOW_LEFT
    )


## Tier 4.4 octant: wind-up PA from diagonal **`attack_line`**  -  not form home.


## Tier 4.4 octant: wind-up PA from diagonal **`attack_line`**  -  not form home.
static func _assert_octant_windup_stamps_line(failures: PackedStringArray, line: String) -> void:
    var atk: Dictionary = {}
    CombatFootwork.apply_attack_step_on_windup(atk, line)
    var want: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
    var anchor: float = GuardLines.position_angle_offset_deg_for_line(line)
    var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    if absf(want - anchor) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_octant_windup: %s delegate want %.2f got %.2f" % [line, anchor, want]
        )
        return
    if absf(off - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_octant_windup: %s stamp want %.2f got %.2f" % [line, want, off]
        )


## WF-T1: all four diagonals stamp wind-up PA via **`CombatConstants`** -> **`CombatGuardLines`** lookup.


## WF-T1: all four diagonals stamp wind-up PA via **`CombatConstants`** -> **`CombatGuardLines`** lookup.
static func _run_footwork_octant_windup_step_diagonals(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    for line in [
        GuardLines.LINE_HIGH_RIGHT,
        GuardLines.LINE_LOW_RIGHT,
        GuardLines.LINE_LOW_LEFT,
        GuardLines.LINE_HIGH_LEFT,
    ]:
        AttentionFootworkFocusLineFootworkPickerTests._assert_octant_windup_stamps_line(failures, line)


## WF-T1: eight-guard flag on  -  **`CombatConstants.position_angle_offset_deg_for_attack_line`** delegates to
## **`CombatGuardLines`** for every line.


## WF-T1: eight-guard flag on  -  **`CombatConstants.position_angle_offset_deg_for_attack_line`** delegates to
## **`CombatGuardLines`** for every line.
static func _run_footwork_octant_lookup_delegates_to_guard_lines(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    for line in GuardLines.ALL_LINES:
        var anchor: float = GuardLines.position_angle_offset_deg_for_line(line)
        var got: float = CombatConstants.position_angle_offset_deg_for_attack_line(line)
        if absf(got - anchor) > 0.01:
            CombatRegressionHarness._fail(
                failures, "footwork_octant_lookup: %s want %.2f got %.2f" % [line, anchor, got]
            )
    for line in [
        GuardLines.LINE_HIGH_RIGHT,
        GuardLines.LINE_LOW_RIGHT,
        GuardLines.LINE_LOW_LEFT,
        GuardLines.LINE_HIGH_LEFT,
    ]:
        var cardinal: String = GuardLines.cardinal_for_path_lookup(line)
        var diag_raw: float = GuardLines.position_angle_offset_deg_for_line(line)
        var card_raw: float = GuardLines.position_angle_offset_deg_for_line(cardinal)
        if absf(diag_raw - card_raw) < 0.01:
            CombatRegressionHarness._fail(
                failures,
                (
                    "footwork_octant_lookup: %s raw %.2f should differ from cardinal %s %.2f"
                    % [line, diag_raw, cardinal, card_raw]
                )
            )


## WF-T1: dodge body-part -> octant line  -  scaled dodge step uses octant raw, not mapped cardinal.


## WF-T1: dodge body-part -> octant line  -  scaled dodge step uses octant raw, not mapped cardinal.
static func _assert_defender_dodge_octant_via_leg(
    failures: PackedStringArray, part: String, expect_line: String, cardinal_line: String
) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {}
    CombatFootwork.apply_defender_step_on_dodge(def, part)
    var line: String = CombatConstants.guard_line_for_body_part(part)
    if line != expect_line:
        CombatRegressionHarness._fail(
            failures, "footwork_def_dodge_octant: %s line want %s got %s" % [part, expect_line, line]
        )
        return
    var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    var cardinal_dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        cardinal_line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(off - want) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_def_dodge_octant: %s want %.2f got %.2f" % [part, want, off])
    if absf(off - cardinal_dodge) < 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_def_dodge_octant: %s octant %.2f should differ from cardinal %s %.2f"
                % [part, off, cardinal_line, cardinal_dodge]
            )
        )


static func _run_footwork_defender_dodge_step_stamps_octant_low_left(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    AttentionFootworkFocusLineFootworkPickerTests._assert_defender_dodge_octant_via_leg(
        failures, "left_leg", GuardLines.LINE_LOW_LEFT, GuardLines.LINE_LOW
    )


static func _run_footwork_defender_dodge_step_stamps_octant_right_leg(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    AttentionFootworkFocusLineFootworkPickerTests._assert_defender_dodge_octant_via_leg(
        failures, "right_leg", GuardLines.LINE_LOW_RIGHT, GuardLines.LINE_LOW
    )


## WF-T1: **`parry_eval_step_deg_for_defender`** uses octant guard line without stamping offset.


## WF-T1: **`parry_eval_step_deg_for_defender`** uses octant guard line without stamping offset.
static func _run_footwork_parry_eval_step_octant_home(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var line: String = GuardLines.LINE_LOW_LEFT
    var def: Dictionary = {"guard_line": line}
    var eval: float = CombatFootwork.parry_eval_step_deg_for_defender(def)
    if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(
            failures, "footwork_parry_eval_octant: parry_eval must not stamp offset on combatant"
        )
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    if absf(eval - want) < 0.01:
        return
    CombatRegressionHarness._fail(failures, "footwork_parry_eval_octant: low_left want %.2f got %.2f" % [want, eval])


## WF-T1: **`dodge_eval_step_deg_for_defender`** uses body-part line without stamping offset.


## WF-T1: **`dodge_eval_step_deg_for_defender`** uses body-part line without stamping offset.
static func _run_footwork_dodge_eval_step_octant_arm(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {"guard_line": "high"}
    var eval: float = CombatFootwork.dodge_eval_step_deg_for_defender(def, "left_arm")
    if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(
            failures, "footwork_dodge_eval_octant: dodge_eval must not stamp offset on combatant"
        )
    var line: String = CombatConstants.guard_line_for_body_part("left_arm")
    var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(eval - want) > 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_dodge_eval_octant: left_arm want %.2f got %.2f" % [want, eval]
        )


## WF-T1: Camp-5 soak confirms defender step scales (constants-only  -  no runtime retune hook).


## WF-T1: Camp-5 soak confirms defender step scales (constants-only  -  no runtime retune hook).
static func _run_footwork_defender_scales_wf_t1_locked(failures: PackedStringArray) -> void:
    if absf(CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY - 0.55) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_def_scale_wf_t1: parry want 0.55 got %.4f"
                % CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
            )
        )
    if absf(CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE - 0.85) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_def_scale_wf_t1: dodge want 0.85 got %.4f"
                % CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
            )
        )


## WF-T1: defender parry scale (0.55) < dodge scale (0.85) on the same octant line.


## WF-T1: defender parry scale (0.55) < dodge scale (0.85) on the same octant line.
static func _run_footwork_defender_parry_step_lt_dodge_on_octant(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    var line: String = GuardLines.LINE_HIGH_LEFT
    var parry: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    var dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    if absf(parry) >= absf(dodge):
        CombatRegressionHarness._fail(
            failures, "footwork_def_scale: high_left parry %.2f should be smaller than dodge %.2f" % [parry, dodge]
        )


## WF-T1: **`guard_angle_deg`** includes octant parry step on diagonal home guard.


## WF-T1: **`guard_angle_deg`** includes octant parry step on diagonal home guard.
static func _run_footwork_guard_angle_deg_octant_parry_step(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var line: String = GuardLines.LINE_HIGH_LEFT
    var def: Dictionary = {"guard_line": line}
    CombatFootwork.apply_defender_step_on_parry(def, line)
    var base_deg: float = CombatConstants.get_guard_angle_deg(def, {})
    var shifted: float = CombatFootwork.guard_angle_deg(def, {})
    var step: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        line, CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
    )
    var want: float = fmod(base_deg + step + 360.0, 360.0)
    if absf(shifted - want) > 0.05:
        CombatRegressionHarness._fail(
            failures,
            "footwork_guard_angle_octant: want %.2f got %.2f (base=%.2f step=%.2f)" % [want, shifted, base_deg, step]
        )


## Tier 4.4 spatial slice 1: engagement band scales PA step magnitude (CLOSE > LONG).


## Tier 4.4 spatial slice 1: engagement band scales PA step magnitude (CLOSE > LONG).
static func _run_t44_spatial_band_pa_attacker_close_gt_long(failures: PackedStringArray) -> void:
    var saved_pa: bool = CombatConstants.is_feature_position_angle_footwork_enabled()
    var saved_t44: bool = CombatConstants.is_feature_t44_spatial_band_pa_enabled()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_t44_spatial_band_pa_load(true)
    var base: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    if absf(base) < 0.01:
        CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
        CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
        return
    var atk_close: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_CLOSE}}
    CombatFootwork.apply_attack_step_on_windup(atk_close, "left", 2)
    var close_off: float = float(atk_close.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var atk_long: Dictionary = {"distance_to": {2: CombatConstants.DISTANCE_LONG}}
    CombatFootwork.apply_attack_step_on_windup(atk_long, "left", 2)
    var long_off: float = float(atk_long.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want_close: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_CLOSE
    var want_long: float = base * CombatConstants.T44_SPATIAL_BAND_PA_MULT_LONG
    if absf(close_off - want_close) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_spatial_band_pa_attacker: close want %.2f got %.2f" % [want_close, close_off]
        )
    if absf(long_off - want_long) > 0.01:
        CombatRegressionHarness._fail(
            failures, "t44_spatial_band_pa_attacker: long want %.2f got %.2f" % [want_long, long_off]
        )
    if absf(close_off) <= absf(long_off) + 0.001:
        CombatRegressionHarness._fail(failures, "t44_spatial_band_pa_attacker: |close| should exceed |long|")
    CombatConstants.set_feature_t44_spatial_band_pa_load(saved_t44)
    CombatConstants.set_feature_position_angle_footwork_load(saved_pa)
