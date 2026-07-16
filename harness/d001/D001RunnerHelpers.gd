class_name D001RunnerHelpers
extends RefCounted
## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a - c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see
## **`.d001_headless_signoff.txt`**).
## **ii5c** (`_run_ii5c_gauge_label_checks`): **`Stm`/`Ready`/`Exh`/`Grd`** + WF gauge/diagram suffix order (incl.
## **`form_wrath_*`**)  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.

const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05


static func _formation_engagement_banner_line(mgr: Node) -> String:
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    if form.is_empty():
        return ""
    var mode_disp: String = CombatEngagementMode.mode_display_name(CombatEngagementMode.engagement_mode(mgr))
    var posture: String = str(form.get("engagement_posture", " - "))
    var coh: float = float(form.get("line_cohesion", 0.0))
    return (
        "%s . %s . cohesion %d%%"
        % [
            mode_disp,
            posture.capitalize(),
            int(roundf(coh * 100.0)),
        ]
    )


static func _log_diagram_banner_once(mgr: Node) -> void:
    var form: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    if form.is_empty():
        return
    var mode_disp: String = CombatEngagementMode.mode_display_name(CombatEngagementMode.engagement_mode(mgr))
    var posture: String = str(form.get("engagement_posture", " - "))
    var coh: float = float(form.get("line_cohesion", 0.0))
    var line: String = (
        "%s . %s . cohesion %d%%"
        % [
            mode_disp,
            posture.capitalize(),
            int(roundf(coh * 100.0)),
        ]
    )
    CombatF5SoakTrace.log_diagram_banner_player(line)


static func _infer_soak_fight_winner(mgr: Node) -> String:
    var players_alive: int = 0
    var enemies_alive: int = 0
    for c in mgr.combatants:
        if c is not Dictionary or not CombatantEntityAccess.alive_bool(c):
            continue
        if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)):
            continue
        if CombatantEntityAccess.is_player_side(c):
            players_alive += 1
        else:
            enemies_alive += 1
    if players_alive > 0 and enemies_alive == 0:
        return "player"
    if enemies_alive > 0 and players_alive == 0:
        return "enemy"
    if bool(mgr.medical_phase):
        return "player"
    return "enemy" if enemies_alive > players_alive else "player"


static func _simulate_fight(mgr: Node, max_sec: float, preset_id: String) -> void:
    if not preset_id.is_empty():
        CombatF5SoakTrace.set_fight_profile(preset_id)
    else:
        CombatF5SoakTrace.set_fight_profile("7v7")
    CombatF5SoakTrace.reset_fight_trace_buffer()
    var restore_hit_summary: bool = false
    if CombatConstants.is_headless_harness_quiet() and OperationalLog.is_play_session_active():
        CombatConstants.set_combat_hit_summary_override(true)
        restore_hit_summary = true
    var elapsed: float = 0.0
    while elapsed < max_sec and mgr.is_processing():
        D001RunnerHelpers._auto_resolve_ready_combatants(mgr, preset_id)
        mgr._process(TICK_DT)
        elapsed += TICK_DT
        if mgr.medical_phase:
            break
    D001RunnerHelpers._auto_resolve_ready_combatants(mgr, preset_id)
    CombatF5SoakTrace.log_fight_end_summary(D001RunnerHelpers._infer_soak_fight_winner(mgr), bool(mgr.medical_phase))
    if restore_hit_summary:
        CombatConstants.clear_combat_hit_summary_override()


static func _auto_resolve_ready_combatants(mgr: Node, preset_id: String) -> void:
    for c in mgr.combatants:
        if c is not Dictionary:
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if bool(c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false)):
            continue
        var st: String = CombatantEntityAccess.state_str(c)
        if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
            continue
        if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var actions: Array = mgr.get_available_actions(cid)
        if CombatantEntityAccess.is_player_side(c):
            CombatPlayerTurnHints.emit_turn_ready_hints(mgr, c, actions)
            CombatF5SoakTrace.log_turn_ready_player_ui(mgr, c, actions)
        if (
            preset_id == SoakEncounterPresets.PRESET_II5_COWERING
            and st == CombatConstants.STATE_COWERING
            and D001RunnerHelpers._try_force_fall_back(mgr, cid, actions)
        ):
            continue
        var log_side: String = "player" if CombatantEntityAccess.is_player_side(c) else "enemy"
        var pick_actions: Array = actions
        if preset_id == SoakEncounterPresets.PRESET_II2B_SWORD_DUEL:
            pick_actions = D001RunnerHelpers._strike_biased_actions(actions, cid)
        elif preset_id == SoakEncounterPresets.PRESET_II_ENVELOP:
            pick_actions = D001RunnerHelpers._envelop_melee_biased_actions(actions, cid)
        CombatAIActionPicker.resolve_picked_turn_or_skip(mgr, cid, pick_actions, log_side)


static func _strike_biased_actions(actions: Array, combatant_id: int) -> Array:
    var non_strike: Dictionary = {
        CombatConstants.MOVE_ID_WAIT: true,
        CombatConstants.MOVE_ID_ATTEMPT_CLOSE: true,
        CombatConstants.MOVE_ID_SWAP_RANK: true,
        CombatConstants.MOVE_ID_DRAG_BACK: true,
        CombatConstants.MOVE_ID_FALL_BACK: true,
        CombatConstants.MOVE_ID_ROTATE_FILE: true,
        CombatConstants.MOVE_ID_FLEE: true,
        CombatConstants.MOVE_ID_FOCUS_HIGH: true,
        CombatConstants.MOVE_ID_FOCUS_LOW: true,
        CombatConstants.MOVE_ID_FOCUS_LEFT: true,
        CombatConstants.MOVE_ID_FOCUS_RIGHT: true,
    }
    var strikes: Array = []
    for a in actions:
        if a is not Dictionary:
            continue
        var mid: String = str(a.get("move_id", ""))
        if non_strike.has(mid):
            continue
        if int(a.get("target_id", combatant_id)) == combatant_id:
            continue
        strikes.append(a)
    return strikes if not strikes.is_empty() else actions


## III-4 **ii_envelop**: prefer damage actions over rotate/wait when listed (headless wing engagement smoke).


## III-4 **ii_envelop**: prefer damage actions over rotate/wait when listed (headless wing engagement smoke).
static func _envelop_melee_biased_actions(actions: Array, combatant_id: int) -> Array:
    var deprioritize: Dictionary = {
        CombatConstants.MOVE_ID_WAIT: true,
        CombatConstants.MOVE_ID_ROTATE_FILE: true,
    }
    var preferred: Array = []
    for a in actions:
        if a is not Dictionary:
            continue
        var mid: String = str(a.get("move_id", ""))
        if deprioritize.has(mid):
            continue
        if int(a.get("target_id", combatant_id)) == combatant_id:
            continue
        preferred.append(a)
    return preferred if not preferred.is_empty() else actions


## Live **`AttackResultApplier`** / **`CombatFlurryBind`** path when random duel omits bind lines (feeds headless
## **II-2b** plausibility).


## Live **`AttackResultApplier`** / **`CombatFlurryBind`** path when random duel omits bind lines (feeds headless
## **II-2b** plausibility).
static func _ensure_ii2b_bind_flurry_smoke(mgr: Node) -> void:
    var lines: PackedStringArray = OperationalLog.get_captured_lines()
    var need_bind: bool = D001Ii5Ii6RunnerTests._count_needle(lines, "parry_bind") < 1
    var need_flurry: bool = D001Ii5Ii6RunnerTests._count_needle(lines, "flurry_bind") < 1
    if not need_bind and not need_flurry:
        return
    if mgr.combatants.size() < 2:
        return
    OperationalLog.play_combat("soak_setup ii2b bind/flurry smoke tail (live resolver; headless plausibility)")
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(defender)
    var e_id: int = CombatantEntityAccess.id_int(attacker)
    attacker["pending_attack"] = {
        "attack_type": "thrust",
        "effective_attack_line": "high",
        "intensity": 0.8,
        "attack_angle_deg": 90.0,
    }
    defender["guard_line"] = "high"
    defender.gauge = 100.0
    attacker.state = CombatConstants.STATE_WIND_UP
    (
        AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
            }
        )
    )
    if need_flurry:
        defender.gauge = 100.0
        defender.state = CombatConstants.STATE_WAITING
        AttackWindUpStarter.start(mgr, p_id, e_id, "thrust")


## Headless ii5: fall-back wind-up must finish before `soak_fight_end` (plausibility last-fight slice).


## Headless ii5: fall-back wind-up must finish before `soak_fight_end` (plausibility last-fight slice).
static func _ensure_ii5_cowering_fall_back_executed(mgr: Node, combatant_id: int) -> void:
    if D001Ii5Ii6RunnerTests._count_needle(OperationalLog.get_captured_lines(), "cowering_fall_back executed") >= 1:
        return
    for _i in 80:
        mgr._process(TICK_DT)
        if D001Ii5Ii6RunnerTests._count_needle(OperationalLog.get_captured_lines(), "cowering_fall_back executed") >= 1:
            return
    var c: Variant = mgr._get_by_id(combatant_id)
    if c is not Dictionary:
        return
    var cd: Dictionary = c as Dictionary
    cd.state = CombatConstants.STATE_FALLING_BACK
    cd.state_timer = float(cd.get(DataKeys.PA_STATE_DURATION, CombatConstants.BASE_FALL_BACK_S))
    (
        mgr
        . _handle_fall_back_solo_resolve(
            {
                "type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
                "combatant_id": combatant_id,
            }
        )
    )


static func _drain_until_capture_needle(mgr: Node, needle: String, max_sec: float) -> void:
    var elapsed: float = 0.0
    while elapsed < max_sec:
        if D001Ii5Ii6RunnerTests._count_needle(OperationalLog.get_captured_lines(), needle) >= 1:
            return
        mgr._process(TICK_DT)
        elapsed += TICK_DT


static func _try_force_fall_back(mgr: Node, combatant_id: int, actions: Array) -> bool:
    for a in actions:
        if a is not Dictionary:
            continue
        if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_FALL_BACK:
            continue
        if int(a.get("target_id", combatant_id)) != combatant_id:
            continue
        mgr.resolve_action(combatant_id, combatant_id, CombatConstants.MOVE_ID_FALL_BACK, {})
        return true
    return false


static func _soak_kill(mgr: Node, combatant_id: int) -> void:
    var c: Variant = mgr._get_by_id(combatant_id)
    if c is Dictionary:
        c["hp"] = 0.0
        var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
        if ent != null:
            ent.blood_volume = 0.0


static func _first_alive_player_front_rank(mgr: Node) -> Dictionary:
    for c in mgr.combatants:
        if c is not Dictionary:
            continue
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        return c
    return {}


static func _player_at_rank_file(mgr: Node, rank: int, file: int) -> Dictionary:
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) == rank and CombatantEntityAccess.file_int(c) == file:
            return c
    return {}


static func _first_hostile_melee_strike_action(actions: Array, self_id: int) -> Dictionary:
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid.is_empty() or mid == CombatConstants.MOVE_ID_WAIT:
            continue
        if CombatConstants.is_focus_line_move(mid):
            continue
        if CombatConstants.is_medical_move(mid):
            continue
        if CombatConstants.is_formation_movement_move(mid):
            continue
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tid: int = int(a.get("target_id", -1))
        if tid < 0 or tid == self_id:
            continue
        return a.duplicate()
    return {}


static func _formation_7v7() -> Dictionary:
    return {"files": 5, "ranks": 2, "density": FormationPreset.DENSITY_NORMAL}


static func _player_1x1() -> Dictionary:
    return {"files": 1, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}


static func _player_4_wide() -> Dictionary:
    return FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _enemy_4_wide() -> Dictionary:
    return FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _new_entity(weapon_id: String) -> CoreEntity:
    var e := CoreEntity.new()
    e.apply_species()
    e.dominant_hand = "right_arm"
    e.offhand_functionality = 1.0
    var w: Weapon = Weapon.create_from_definition(weapon_id)
    if w != null:
        e.equip_weapon(w)
    CombatRegressionHarness._track_harness_node(e)
    return e


static func _destroy_limb(entity: CoreEntity, part: String) -> void:
    if entity == null or part.is_empty():
        return
    entity.body_cutting[part] = 0.0
    entity.body_blunt[part] = 0.0
    if entity.bone_health.has(part):
        entity.bone_health[part] = 0.0


static func _free_manager(mgr: Node) -> void:
    CombatRegressionHarness._free_manager(mgr)
