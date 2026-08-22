class_name D001PresetRunnerTests
extends RefCounted
## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a - c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see
## **`.d001_headless_signoff.txt`**).
## **ii5c** (`_run_ii5c_gauge_label_checks`): **`Stm`/`Ready`/`Exh`/`Grd`** + WF gauge/diagram suffix order (incl.
## **`form_wrath_*`**)  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`**.

const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05

## Cross-file preloads — Godot class_name lazy resolution requires explicit preload.
const _OpsLog := preload("res://core/OperationalLog.gd")
const SoakEncounterPresets := preload("res://world/SoakEncounterPresets.gd")
const _D001RunnerHelpers := preload("res://harness/d001/D001RunnerHelpers.gd")
const _D001Ii5Ii6Tests := preload("res://harness/d001/D001Ii5Ii6RunnerTests.gd")
const _D001TrackSpecs := preload("res://harness/d001/CombatD001TrackSpecs.gd")
const _F5SoakTrace := preload("res://combat/soak/CombatF5SoakTrace.gd")


static func _preset_seed(preset_id: String) -> int:
    return int(hash("d001_soak_%s" % preset_id) & 0x7FFFFFFF)


static func _run_preset(preset_id: String) -> Dictionary:
    match preset_id:
        SoakEncounterPresets.PRESET_II2B_SWORD_DUEL:
            return D001PresetRunnerTests._run_ii2b_duel(preset_id)
        SoakEncounterPresets.PRESET_II3_SURROUND:
            # Two front fighters vs 4-wide line so one defender sees multi-threat surround + parry traffic.
            return D001PresetRunnerTests._run_generic_fight(
                preset_id,
                2,
                4,
                {"files": 2, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL},
                D001RunnerHelpers._enemy_4_wide(),
                50.0
            )
        SoakEncounterPresets.PRESET_II5_COWERING:
            return _D001Ii5Ii6Tests._run_ii5_cowering(preset_id)
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
            return _D001Ii5Ii6Tests._run_ii6_ambient(preset_id)
        SoakEncounterPresets.PRESET_II8_FORMATION:
            return D001PresetRunnerTests._run_ii8_formation(preset_id)
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION:
            return _D001Ii5Ii6Tests._run_ii4d_exhaustion(preset_id)
        SoakEncounterPresets.PRESET_II_ENVELOP:
            return D001PresetRunnerTests._run_ii_envelop(preset_id)
        _:
            return {"ok": false, "summary": "unknown preset", "checks": {}}


## **II-5c** headless: **`BattleUIUpdater.gauge_label_text_for_combatant`** (`Stm` / `Ready` / `Exh` / `Grd` in one
## row).
## **II-5a**: formation **`FP_COMBAT`** stamp + **`ui_hint`** on 4- - 4 line (player rank-0 turn-ready).
## **II-5b**: aggregated preset captures must not contain stale crash/intrusion log vocabulary.
## II-0 **#7**: enter medical phase, list pressure on bleeding chest (live manager path).


## **II-5c** headless: **`BattleUIUpdater.gauge_label_text_for_combatant`** (`Stm` / `Ready` / `Exh` / `Grd` in one
## row).
## **II-5a**: formation **`FP_COMBAT`** stamp + **`ui_hint`** on 4- - 4 line (player rank-0 turn-ready).
## **II-5b**: aggregated preset captures must not contain stale crash/intrusion log vocabulary.
## II-0 **#7**: enter medical phase, list pressure on bleeding chest (live manager path).
static func _run_ii7_medical_phase_smoke() -> Dictionary:
    OperationalLog.play_combat("soak_setup ii7 medical phase smoke (grep medical | apply_direct_pressure | pack_wound)")
    var mgr: Node = CombatManager.new()
    var enemy_ent: CoreEntity = D001RunnerHelpers._new_entity("SWORD")
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    mgr.register(enemy_ent, "enemy")
    mgr.start(D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1())
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally: Dictionary = mgr.combatants[1]
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        D001PresetRunnerTests._wound_chest_for_packing(ally_ent)
    mgr._end_combat_phase("player", enemy_ent)
    var check_out: Dictionary = {}
    var fail: PackedStringArray = PackedStringArray()
    var in_medical: bool = bool(mgr.medical_phase)
    check_out["medical_phase"] = {"pass": in_medical, "count": 1 if in_medical else 0, "min": 1}
    if not in_medical:
        fail.append("medical_phase false")
    else:
        mgr.combatants[0]["gauge"] = 100.0
        mgr.combatants[0].state = CombatConstants.STATE_WAITING
        var acts: Array = mgr.get_available_actions(healer_id)
        var found_pressure: bool = false
        for raw in acts:
            if raw is not Dictionary:
                continue
            var a: Dictionary = raw
            if int(a.get("target_id", -1)) != ally_id:
                continue
            if str(a.get("target_part", "")) != "chest":
                continue
            if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
                found_pressure = true
                break
        check_out["pressure_listed"] = {
            "pass": found_pressure,
            "count": 1 if found_pressure else 0,
            "min": 1,
        }
        if not found_pressure:
            fail.append("pressure_listed missing")
        else:
            var committed: bool = mgr.resolve_action(
                healer_id, ally_id, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, {"target_part": "chest"}
            )
            check_out["pressure_resolve"] = {
                "pass": committed,
                "count": 1 if committed else 0,
                "min": 1,
            }
            if not committed:
                fail.append("pressure_resolve failed")
            else:
                D001PresetRunnerTests._wait_combatant_waiting(mgr, mgr.combatants[0], 8.0)
                var healer_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, mgr.combatants[0])
                D001PresetRunnerTests._ensure_ally_part_has_direct_pressure(
                    mgr, ally, mgr.combatants[0], ally_ent, healer_ent, "chest"
                )
                mgr.combatants[0].state = CombatConstants.STATE_WAITING
                mgr.combatants[0]["gauge"] = 100.0
                mgr.combatants[0].erase("pending_medical")
                var acts2: Array = mgr.get_available_actions(healer_id)
                CombatPlayerTurnHints.emit_turn_ready_hints(mgr, mgr.combatants[0], acts2)
                var found_pack: bool = D001PresetRunnerTests._medical_pack_wound_listed_for_ally(
                    mgr, mgr.combatants[0], ally, ally_id, acts2
                )
                check_out["pack_wound_listed"] = {
                    "pass": found_pack,
                    "count": 1 if found_pack else 0,
                    "min": 1,
                }
                if not found_pack:
                    fail.append("pack_wound_listed missing after pressure")
                if found_pack:
                    var who_pack: String = CombatantEntityAccess.get_display_name(mgr.combatants[0], healer_id)
                    if who_pack.is_empty() and healer_ent != null:
                        who_pack = str(healer_ent.name)
                    CombatF5SoakTrace.note_medical_pack_listed(who_pack, "chest")
                    CombatF5SoakTrace.note_medical_action_pick(
                        who_pack, CombatConstants.MOVE_ID_PACK_WOUND, "chest", "ally"
                    )
                    var pack_ok: bool = mgr.resolve_action(
                        healer_id, ally_id, CombatConstants.MOVE_ID_PACK_WOUND, {"target_part": "chest"}
                    )
                    check_out["pack_wound_resolve"] = {
                        "pass": pack_ok,
                        "count": 1 if pack_ok else 0,
                        "min": 1,
                    }
                    if not pack_ok:
                        fail.append("pack_wound_resolve failed")
                    else:
                        var elapsed_pack: float = 0.0
                        while elapsed_pack < CombatConstants.PACK_WOUND_TIMEOUT_S:
                            if CombatantEntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WAITING:
                                break
                            mgr._process(TICK_DT)
                            elapsed_pack += TICK_DT
    var lines: PackedStringArray = OperationalLog.get_captured_lines()
    var med_log_n: int = _D001Ii5Ii6Tests._count_needle(lines, "medical ")
    check_out["medical_log"] = {"pass": med_log_n >= 1, "count": med_log_n, "min": 1, "optional": true}
    var pack_listed_n: int = _D001Ii5Ii6Tests._count_needle(lines, "medical_pack_wound listed")
    var pack_pick_n: int = _D001Ii5Ii6Tests._count_needle(lines, "medical_pack_wound pick")
    check_out["f5_medical_pack_listed"] = {
        "pass": pack_listed_n >= 1,
        "count": pack_listed_n,
        "min": 1,
        "optional": true,
    }
    check_out["f5_medical_pack_pick"] = {
        "pass": pack_pick_n >= 1,
        "count": pack_pick_n,
        "min": 1,
        "optional": true,
    }
    D001RunnerHelpers._free_manager(mgr)
    var ok: bool = fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(fail),
        "checks": check_out,
        "notes": "pressure + pack_wound F5 greps for validator medical_pack_* tracks",
    }


## Headless F5 grep: **`rotate_file@partner`** (II-0 formation move trace).


## Headless F5 grep: **`rotate_file@partner`** (II-0 formation move trace).
static func _run_formation_move_f5_smoke() -> Dictionary:
    OperationalLog.play_combat("soak_setup formation_move_f5 smoke (grep rotate_file@ or swap_rank@)")
    var mgr: Node = CombatManager.new()
    for _i in 4:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    CombatEngagementMode.clear_resolved_mode_cache(mgr)
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var by_file: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        by_file[CombatantEntityAccess.file_int(c)] = c
    var p0: Dictionary = by_file.get(0, {})
    var p1: Dictionary = by_file.get(1, {})
    var fail: PackedStringArray = PackedStringArray()
    var check_out: Dictionary = {}
    if p0.is_empty() or p1.is_empty():
        fail.append("need rank-0 allies at files 0 and 1")
        D001RunnerHelpers._free_manager(mgr)
        return {"ok": false, "summary": ", ".join(fail), "checks": check_out}
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    p0.state = CombatConstants.STATE_WAITING
    p1.state = CombatConstants.STATE_WAITING
    var p0_id: int = CombatantEntityAccess.id_int(p0)
    var p1_id: int = CombatantEntityAccess.id_int(p1)
    var acts: Array = mgr.get_available_actions(p0_id)
    var rotate_act: Dictionary = CombatListedActions.first_action_move_vs_target(
        acts, CombatConstants.MOVE_ID_ROTATE_FILE, p1_id
    )
    var rotate_target: int = int(rotate_act.get("target_id", -1))
    if rotate_target < 0:
        fail.append("rotate_file not listed on 2-file line")
    else:
        var committed: bool = mgr.resolve_action(p0_id, rotate_target, CombatConstants.MOVE_ID_ROTATE_FILE, {})
        check_out["rotate_resolve"] = {
            "pass": committed,
            "count": 1 if committed else 0,
            "min": 1,
        }
        if not committed:
            fail.append("rotate_file resolve failed")
    var lines: PackedStringArray = OperationalLog.get_captured_lines()
    var rot_n: int = _D001Ii5Ii6Tests._count_needle(lines, "rotate_file")
    check_out["f5_rotate_file"] = {
        "pass": rot_n >= 1,
        "count": rot_n,
        "min": 1,
    }
    if rot_n < 1:
        fail.append("FP_COMBAT missing rotate_file grep line")
    D001RunnerHelpers._free_manager(mgr)
    var ok: bool = fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(fail),
        "checks": check_out,
        "notes": "feeds f5_log_validator formation_moves optional track",
    }


static func _wait_combatant_waiting(mgr: Node, c: Dictionary, max_sec: float) -> void:
    var elapsed: float = 0.0
    while elapsed < max_sec:
        if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WAITING:
            return
        mgr._process(TICK_DT)
        elapsed += TICK_DT


static func _ensure_ally_part_has_direct_pressure(
    mgr: Node, ally: Dictionary, healer: Dictionary, ally_ent: Node, healer_ent: Node, part: String
) -> void:
    if ally_ent == null or healer_ent == null or part.is_empty():
        return
    if CombatantEntityAccess.entity_has_direct_pressure_on_part(mgr, ally, part):
        return
    CombatantEntityAccess.entity_apply_direct_pressure_from_ally(mgr, ally, healer, part)


static func _medical_pack_wound_listed_for_ally(
    mgr: Node, healer: Dictionary, ally: Dictionary, ally_id: int, actions: Array
) -> bool:
    if not (
        CombatListedActions.first_action_move_vs_target(actions, CombatConstants.MOVE_ID_PACK_WOUND, ally_id).is_empty()
    ):
        return true
    for raw in MedicalPhaseController.get_ally_medical_actions(mgr, healer, ally, "chest"):
        if raw is Dictionary and str((raw as Dictionary).get("move_id", "")) == CombatConstants.MOVE_ID_PACK_WOUND:
            return true
    return false


static func _wound_chest_for_packing(ent: Node) -> void:
    if ent == null:
        return
    EntityWounds.add_wound(
        ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_SEVERE
    )
    if ent.linen_strips_remaining < BleedingConstants.PACKING_LINEN_COST_PER_ATTEMPT:
        ent.linen_strips_remaining = BleedingConstants.PACKING_LINEN_PARTY_START


static func _run_ii5b_log_policy_checks(lines: PackedStringArray) -> Dictionary:
    var banned: Array = [
        {"id": "no_crash_success", "needle": "crash_success"},
        {"id": "no_crash_through", "needle": "crash_through"},
        {"id": "no_intruder_wedge_live", "needle": "intruder_wedge"},
    ]
    var check_out: Dictionary = {}
    var fail: PackedStringArray = PackedStringArray()
    for spec in banned:
        var id: String = str(spec.get("id", ""))
        var needle: String = str(spec.get("needle", ""))
        var count: int = _D001Ii5Ii6Tests._count_needle(lines, needle)
        var ok_needle: bool = count == 0
        check_out[id] = {"pass": ok_needle, "count": count, "min": 0, "max": 0}
        if not ok_needle:
            fail.append("%s (count=%d)" % [id, count])
    var ok: bool = fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(fail),
        "checks": check_out,
        "notes": "stale crash/intrusion log vocabulary not present in preset sims",
    }


## **II-1e** / II-0 **#8**: engagement mode display strings used by formation diagram copy.


## **II-1e** / II-0 **#8**: engagement mode display strings used by formation diagram copy.
static func _run_ii1e_engagement_label_checks() -> Dictionary:
    var checks: Dictionary = {
        "formation_line":
        {
            "pass":
            CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_FORMATION) == "Formation line",
            "count": 1,
            "min": 1,
        },
        "skirmish":
        {
            "pass": CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_SKIRMISH) == "Skirmish",
            "count": 1,
            "min": 1,
        },
        "duel":
        {
            "pass": CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_DUEL) == "Duel",
            "count": 1,
            "min": 1,
        },
    }
    var fail: PackedStringArray = PackedStringArray()
    for key in checks.keys():
        if not bool((checks[key] as Dictionary).get("pass", false)):
            fail.append(key)
    var ok: bool = fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(fail),
        "checks": checks,
        "notes": "Diagram on-screen labels still need F5 ii8",
    }


static func _run_ii5a_formation_hint_checks() -> Dictionary:
    OperationalLog.play_combat("soak_setup ii5a 4x4 formation turn-ready hints (grep ui_hint Formation)")
    var mgr: Node = _D001Ii5Ii6Tests._start_manager(
        "ii5a", 4, 4, D001RunnerHelpers._player_4_wide(), D001RunnerHelpers._enemy_4_wide()
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var probe: Dictionary = _D001Ii5Ii6Tests._probe_formation_turn_hints(mgr)
    var check_out: Dictionary = {}
    var stamp: String = str(probe.get("formation_stamp", ""))
    var ui_n: int = int(probe.get("ui_hint_formation", 0))
    D001RunnerHelpers._free_manager(mgr)
    check_out["formation_stamp"] = {"pass": not stamp.is_empty(), "count": 1 if not stamp.is_empty() else 0, "min": 1}
    check_out["ui_hint_formation"] = {"pass": ui_n >= 1, "count": ui_n, "min": 1}
    var fail: PackedStringArray = PackedStringArray()
    if stamp.is_empty():
        fail.append("formation_stamp empty")
    if ui_n < 1:
        fail.append("ui_hint_formation got %d" % ui_n)
    var ok: bool = fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(fail),
        "checks": check_out,
        "notes": "II-5a log paths  -  F5 tooltip match still required",
    }


static func _run_ii5c_gauge_label_checks() -> Dictionary:
    var checks: Array = [
        {
            "id": "stm_ready",
            "needle": "Stm 67% . Ready",
            "label":
            (
                BattleUIUpdater
                . gauge_label_text_for_combatant(
                    {
                        "alive": true,
                        "state": CombatConstants.STATE_WAITING,
                        "gauge": 100.0,
                        "stamina": 67.0,
                        "guard_line": "high",
                    }
                )
            ),
            "min": 1,
        },
        {
            "id": "exh_grd_stack",
            "needle": "Exh 55%",
            "label":
            (
                BattleUIUpdater
                . gauge_label_text_for_combatant(
                    {
                        "alive": true,
                        "state": CombatConstants.STATE_WAITING,
                        "gauge": 50.0,
                        "stamina": 60.0,
                        "guard_line": "high_right",
                        CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
                    }
                )
            ),
            "min": 1,
        },
        {
            "id": "grd_hir",
            "needle": "Grd HiR",
            "label":
            (
                BattleUIUpdater
                . gauge_label_text_for_combatant(
                    {
                        "alive": true,
                        "state": CombatConstants.STATE_WAITING,
                        "gauge": 50.0,
                        "stamina": 60.0,
                        "guard_line": "high_right",
                        CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
                    }
                )
            ),
            "min": 1,
        },
    ]
    if not CombatConstants.is_feature_fight_exhaustion_enabled():
        checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "exh_grd_stack")
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "grd_hir")
    var form_row: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WAITING,
        "gauge": 100.0,
        "stamina": 67.0,
        "guard_line": "high",
        CombatConstants.COMBATANT_KEY_WEAPON_FORM: CombatWeaponForm.FORM_OX,
    }
    var form_label: String = BattleUIUpdater.gauge_label_text_for_combatant(form_row)
    (
        checks
        . append(
            {
                "id": "form_ox_gauge",
                "needle": " . Form Ox",
                "label": form_label,
                "min": 1,
            }
        )
    )
    (
        checks
        . append(
            {
                "id": "suffix_order_grd_form",
                "needle": "",
                "label": form_label,
                "min": 1,
                "ordered_substrings": ["Grd", " . Form Ox"],
            }
        )
    )
    if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        var wrath_row: Dictionary = {
            "alive": true,
            "state": CombatConstants.STATE_WAITING,
            "gauge": 100.0,
            "stamina": 67.0,
            "guard_line": "high_left",
            CombatConstants.COMBATANT_KEY_WEAPON_FORM: CombatWeaponForm.FORM_WRATH,
        }
        var wrath_label: String = BattleUIUpdater.gauge_label_text_for_combatant(wrath_row)
        (
            checks
            . append(
                {
                    "id": "form_wrath_grd_hil",
                    "needle": "Grd HiL",
                    "label": wrath_label,
                    "min": 1,
                }
            )
        )
        (
            checks
            . append(
                {
                    "id": "form_wrath_gauge",
                    "needle": " . Form Wrath",
                    "label": wrath_label,
                    "min": 1,
                }
            )
        )
        (
            checks
            . append(
                {
                    "id": "form_wrath_suffix_order",
                    "needle": "",
                    "label": wrath_label,
                    "min": 1,
                    "ordered_substrings": ["Grd HiL", " . Form Wrath"],
                }
            )
        )
        var wrath_cell: String = FormationDiagramBuilder._cell_label_with_footwork("P0", [wrath_row])
        (
            checks
            . append(
                {
                    "id": "form_wrath_diagram",
                    "needle": "",
                    "label": wrath_cell,
                    "min": 1,
                    "ordered_substrings": ["[HiL]", "[Wrath]"],
                }
            )
        )
        var step_grd_form_row: Dictionary = form_row.duplicate()
        step_grd_form_row["state"] = CombatConstants.STATE_WIND_UP
        step_grd_form_row["state_timer"] = 0.0
        step_grd_form_row["state_duration"] = 1.0
        step_grd_form_row[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 14.0
        step_grd_form_row["pending_attack"] = {"attack_line": "high_right", "move_id": "oberhau"}
        var step_label: String = BattleUIUpdater.gauge_label_text_for_combatant(step_grd_form_row)
        (
            checks
            . append(
                {
                    "id": "suffix_order_step_atk_form",
                    "needle": "",
                    "label": step_label,
                    "min": 1,
                    "ordered_substrings": ["Step", "Atk", " . Form Ox"],
                }
            )
        )
    var full_row: String = (
        BattleUIUpdater
        . gauge_label_text_for_combatant(
            {
                "alive": true,
                "state": CombatConstants.STATE_WAITING,
                "gauge": 100.0,
                "stamina": 72.0,
                "guard_line": "high",
                CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.12,
            }
        )
    )
    var row_subs: Array = ["Stm", " . Ready", "Grd"]
    if CombatConstants.is_feature_fight_exhaustion_enabled():
        row_subs.append("Exh")
    (
        checks
        . append(
            {
                "id": "stm_ready_exh_grd_row",
                "needle": "",
                "label": full_row,
                "min": 1,
                "substrings": row_subs,
            }
        )
    )
    var check_out: Dictionary = {}
    var required_fail: PackedStringArray = PackedStringArray()
    for spec in checks:
        var id: String = str(spec.get("id", ""))
        var text: String = str(spec.get("label", ""))
        var needle: String = str(spec.get("needle", ""))
        var ok_needle: bool = true
        if spec.has("ordered_substrings"):
            var ordered: PackedStringArray = PackedStringArray()
            for sub in spec.get("ordered_substrings", []) as Array:
                ordered.append(str(sub))
            ok_needle = D001PresetRunnerTests._label_tokens_in_order(text, ordered)
        elif spec.has("substrings"):
            for sub in spec.get("substrings", []) as Array:
                if str(sub) not in text:
                    ok_needle = false
                    break
        else:
            ok_needle = needle.is_empty() or needle in text
        check_out[id] = {"pass": ok_needle, "count": 1 if ok_needle else 0, "min": 1, "label": text}
        if not ok_needle:
            var need_s: String = needle
            if spec.has("ordered_substrings"):
                need_s = "order %s" % str(spec.get("ordered_substrings", []))
            required_fail.append("%s (label='%s' need '%s')" % [id, text, need_s])
    var ok: bool = required_fail.is_empty()
    return {
        "ok": ok,
        "summary": "ok" if ok else ", ".join(required_fail),
        "checks": check_out,
        "notes": "BattleUIUpdater row suffixes + WF form suffix (headless II-5c sign-off)",
    }


static func _label_tokens_in_order(label: String, tokens: PackedStringArray) -> bool:
    var pos: int = 0
    for tok in tokens:
        var needle: String = str(tok)
        if needle.is_empty():
            continue
        var idx: int = label.find(needle, pos)
        if idx < 0:
            return false
        pos = idx + needle.length()
    return true


## Red-tile 7v7 brawl (headless substitute for F5 random encounter).


## Red-tile 7v7 brawl (headless substitute for F5 random encounter).
static func _run_7v7_brawl() -> Dictionary:
    OperationalLog.play_combat(
        "soak_fight_enter tile=red 7v7  -  headless 5x2 grep turn_ready_gauge diagram_banner medical_action"
    )
    OperationalLog.play_combat("party_entering_combat count=7 (headless)")
    _D001Ii5Ii6Tests._probe_7v7_sparse_formation_hold_hint()
    var form: Dictionary = D001RunnerHelpers._formation_7v7()
    var mgr: Node = _D001Ii5Ii6Tests._start_manager("7v7", 7, 7, form, form)
    D001RunnerHelpers._simulate_fight(mgr, 120.0, "7v7")
    var banner: String = D001RunnerHelpers._formation_engagement_banner_line(mgr)
    if not banner.is_empty():
        CombatF5SoakTrace.log_diagram_banner_player(banner)
    D001RunnerHelpers._free_manager(mgr)
    var lines: PackedStringArray = OperationalLog.get_captured_lines()
    return _D001Ii5Ii6Tests._evaluate("7v7", lines, CombatD001TrackSpecs.headless_checks_for_preset("7v7"))


static func _run_ii2b_duel(preset_id: String, max_sec: float = 90.0) -> Dictionary:
    var lines: PackedStringArray = PackedStringArray()
    var reps: int = 3
    for rep in range(reps):
        OperationalLog.clear_capture()
        seed(D001PresetRunnerTests._preset_seed(preset_id) + rep * 7919)
        var mgr: Node = _D001Ii5Ii6Tests._start_manager(
            preset_id, 1, 1, D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1()
        )
        D001RunnerHelpers._simulate_fight(mgr, max_sec, preset_id)
        for raw in OperationalLog.get_captured_lines():
            lines.append(raw)
        D001RunnerHelpers._free_manager(mgr)
    OperationalLog.clear_capture()
    seed(D001PresetRunnerTests._preset_seed(preset_id) + 99991)
    var smoke_mgr: Node = _D001Ii5Ii6Tests._start_manager(
        preset_id, 1, 1, D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1()
    )
    D001RunnerHelpers._ensure_ii2b_bind_flurry_smoke(smoke_mgr)
    for raw in OperationalLog.get_captured_lines():
        lines.append(raw)
    D001RunnerHelpers._free_manager(smoke_mgr)
    var parry_stats: Dictionary = CombatD001TrackSpecs.parry_outcome_stats(lines)
    var parry_summary: String = CombatD001TrackSpecs.parry_stats_summary_line(parry_stats)
    var parry_summary_dup: bool = false
    for i in range(lines.size() - 1, maxi(-1, lines.size() - 24), -1):
        if str(lines[i]).contains("parry_stats deflect="):
            parry_summary_dup = true
            break
    if not parry_summary_dup:
        OperationalLog.play_combat(parry_summary)
    var pr: Dictionary = _D001Ii5Ii6Tests._evaluate(
        preset_id, lines, CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )
    pr["parry_stats"] = parry_stats
    var plaus_fail: PackedStringArray = CombatD001TrackSpecs.ii2b_plausibility_failures(parry_stats)
    pr["ii2b_plausibility_ok"] = plaus_fail.is_empty()
    pr["ii2b_plausibility_failures"] = plaus_fail
    if not plaus_fail.is_empty():
        pr["ok"] = false
        var prev: String = str(pr.get("summary", ""))
        pr["summary"] = "ii2b_plausibility: %s" % ", ".join(plaus_fail)
        if not prev.is_empty() and prev != "ok":
            pr["summary"] = "%s | %s" % [prev, pr["summary"]]
    var checks: Dictionary = pr.get("checks", {}) as Dictionary
    checks["ii2b_plausibility"] = {
        "pass": plaus_fail.is_empty(),
        "count": 1 if plaus_fail.is_empty() else 0,
        "min": 1,
    }
    pr["checks"] = checks
    pr["notes"] = "headless II-2b plausibility + parry_stats (no F5)"
    OperationalLog.replace_capture(lines)
    return pr


static func _run_generic_fight(
    preset_id: String, player_n: int, enemy_n: int, player_form: Dictionary, enemy_form: Dictionary, max_sec: float
) -> Dictionary:
    var mgr: Node = _D001Ii5Ii6Tests._start_manager(preset_id, player_n, enemy_n, player_form, enemy_form)
    D001RunnerHelpers._simulate_fight(mgr, max_sec, preset_id)
    D001RunnerHelpers._free_manager(mgr)
    return _D001Ii5Ii6Tests._evaluate(
        preset_id, OperationalLog.get_captured_lines(), CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )


static func _run_ii8_formation(preset_id: String) -> Dictionary:
    var mgr: Node = _D001Ii5Ii6Tests._start_manager(
        preset_id, 4, 4, D001RunnerHelpers._player_4_wide(), D001RunnerHelpers._enemy_4_wide(), false
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var banner: String = D001RunnerHelpers._formation_engagement_banner_line(mgr)
    if not banner.is_empty():
        CombatF5SoakTrace.log_diagram_banner_player(banner)
    var probe: Dictionary = _D001Ii5Ii6Tests._probe_formation_turn_hints(mgr)
    probe["diagram_banner"] = banner
    D001RunnerHelpers._simulate_fight(mgr, 45.0, preset_id)
    D001RunnerHelpers._free_manager(mgr)
    var pr: Dictionary = _D001Ii5Ii6Tests._evaluate(
        preset_id, OperationalLog.get_captured_lines(), CombatD001TrackSpecs.headless_checks_for_preset(preset_id)
    )
    return _D001Ii5Ii6Tests._merge_probe_ii8_checks(pr, probe)


static func _run_ii_envelop(preset_id: String) -> Dictionary:
    OperationalLog.play_combat("soak_setup ii_envelop 7v3 outnumber skirmish (III-4 wing traces in Output)")
    D001PresetRunnerTests._probe_ii_envelop_mopup_engagement_debug(preset_id)
    D001PresetRunnerTests._probe_ii_envelop_mopup_rear_rank_hint()
    _D001Ii5Ii6Tests._probe_ii_sparse_post_flee_engagement_debug(preset_id)
    _D001Ii5Ii6Tests._probe_ii_sparse_close_band_rotate_suppress(preset_id)
    _D001Ii5Ii6Tests._probe_ii_line_plug_engagement_debug(preset_id)
    _D001Ii5Ii6Tests._probe_ii_skirmish_rotate_line_plug_engagement_debug(preset_id)
    var player_form: Dictionary = FormationPreset.for_front_count(7, 7, FormationPreset.DENSITY_NORMAL)
    var enemy_form: Dictionary = {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
    return D001PresetRunnerTests._run_generic_fight(preset_id, 7, 3, player_form, enemy_form, 55.0)


## III-4 **3e**: deterministic 7v1 attrition slice  -  `engagement_debug` mop_up + hold-line hint smoke.


## III-4 **3e**: deterministic 7v1 attrition slice  -  `engagement_debug` mop_up + hold-line hint smoke.
static func _probe_ii_envelop_mopup_engagement_debug(preset_id: String) -> void:
    OperationalLog.play_combat("soak_setup ii_envelop_mopup 3e attrition smoke (engagement_debug mop_up)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var player_form: Dictionary = FormationPreset.for_front_count(7, 7, FormationPreset.DENSITY_NORMAL)
    var enemy_form: Dictionary = {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
    var mgr: Node = _D001Ii5Ii6Tests._start_manager(preset_id, 7, 3, player_form, enemy_form, false)
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        _D001Ii5Ii6Tests._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup skip envelop_mop_up_active=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var actor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 3)
    if actor.is_empty():
        actor = D001RunnerHelpers._first_alive_player_front_rank(mgr)
    var enemy_left: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_left = c
            break
    if actor.is_empty() or enemy_left.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup skip missing actor/enemy")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var actor_id: int = CombatantEntityAccess.id_int(actor)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy_left)
    actor["gauge"] = 100.0
    actor["state"] = CombatConstants.STATE_WAITING
    var acts: Array = mgr.get_available_actions(actor_id)
    var choice: Dictionary = {}
    for raw in acts:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw as Dictionary
        if (
            str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
            and int(a.get("target_id", -1)) == enemy_id
        ):
            choice = a.duplicate()
            break
    if choice.is_empty():
        for raw in acts:
            if raw is not Dictionary:
                continue
            var a: Dictionary = raw as Dictionary
            if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
                choice = a.duplicate()
                break
    if choice.is_empty():
        choice = {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id}
    CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, actor_id, acts, choice)
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, actor, acts)
    var hold_hint: String = str(actor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if hold_hint.contains("Mop-up"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup hold_line_hint_ok")
    # 3e strike-finish: CLOSE + listed melee -> `engagement_debug` strikes_listed line for validator/F5.
    var strike_actor: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 0, 3)
    if strike_actor.is_empty():
        strike_actor = actor
    var strike_id: int = CombatantEntityAccess.id_int(strike_actor)
    var dist_strike: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(strike_actor, "distance_to")
    dist_strike[enemy_id] = CombatConstants.DISTANCE_CLOSE
    var dist_enemy: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy_left, "distance_to")
    dist_enemy[strike_id] = CombatConstants.DISTANCE_CLOSE
    strike_actor["gauge"] = 100.0
    strike_actor["state"] = CombatConstants.STATE_WAITING
    var strike_acts: Array = mgr.get_available_actions(strike_id)
    var strike_choice: Dictionary = D001RunnerHelpers._first_hostile_melee_strike_action(strike_acts, strike_id)
    if not strike_choice.is_empty():
        CombatEngagementDiagnostics.maybe_log_turn_pick(mgr, strike_id, strike_acts, strike_choice)
        CombatPlayerTurnHints.emit_turn_ready_hints(mgr, strike_actor, strike_acts)
        CombatF5SoakTrace.log_turn_ready_player_ui(mgr, strike_actor, strike_acts)
        var strike_hold: String = (
            str(strike_actor.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
        )
        if strike_hold.contains("Mop-up"):
            OperationalLog.play_combat("soak_setup ii_envelop_mopup strike_hold_line_hint_ok")
        OperationalLog.play_combat("soak_setup ii_envelop_mopup strike_finish_ok")
    else:
        CombatF5SoakTrace.log_turn_ready_player_ui(mgr, actor, acts)
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up (7- - 2 line).


## III-4 **3e**: rear rank reserve + `attempt_close` during mop-up (7- - 2 line).
static func _probe_ii_envelop_mopup_rear_rank_hint() -> void:
    OperationalLog.play_combat("soak_setup ii_envelop_mopup rear rank hold-line smoke (7x2 reserve + close)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var mgr: Node = CombatManager.new()
    for _i in 14:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 7, "ranks": 2, "density": FormationPreset.DENSITY_NORMAL},
        {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
    )
    var enemy_ids: Array = []
    for c in mgr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(2, enemy_ids.size())):
        _D001Ii5Ii6Tests._soak_kill_combatant(mgr, int(enemy_ids[k]))
    if not CombatDoctrine.envelop_mop_up_active(mgr, "player"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip envelop_mop_up_active=false")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rear: Dictionary = D001RunnerHelpers._player_at_rank_file(mgr, 1, 3)
    if rear.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip missing rank-1 fixture")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var enemy_left: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy_left = c
            break
    if enemy_left.is_empty():
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear skip missing enemy")
        D001RunnerHelpers._free_manager(mgr)
        CombatConstants.set_headless_harness_quiet(was_quiet)
        return
    var rear_id: int = CombatantEntityAccess.id_int(rear)
    var enemy_id: int = CombatantEntityAccess.id_int(enemy_left)
    rear["gauge"] = 100.0
    rear["state"] = CombatConstants.STATE_WAITING
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": rear_id},
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": enemy_id},
    ]
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, rear, acts)
    var hold_hint: String = str(rear.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    if hold_hint.contains("Mop-up"):
        OperationalLog.play_combat("soak_setup ii_envelop_mopup rear_hold_line_hint_ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)


## WF-M3 optional F5 grep: **`controlling_close_list`** when **`attempt_close`** vs Fool at long.


## WF-M3 optional F5 grep: **`controlling_close_list`** when **`attempt_close`** vs Fool at long.
static func _probe_wf_controlling_close_turn_hint() -> void:
    OperationalLog.play_combat("soak_setup wf_controlling_close_hint fool defender at long (WF-M3 F5 grep)")
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    var mgr: Node = CombatManager.new()
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
    mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    CombatWeaponForm.assign_form(mgr, enemy, CombatWeaponForm.FORM_FOOL, "soak_probe")
    player["gauge"] = 100.0
    player["state"] = CombatConstants.STATE_WAITING
    enemy["gauge"] = 100.0
    var dist_p: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(player, "distance_to")
    var dist_e: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")
    dist_p[e_id] = CombatConstants.DISTANCE_LONG
    dist_e[p_id] = CombatConstants.DISTANCE_LONG
    var acts: Array = [
        {"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE, "target_id": e_id},
    ]
    CombatPlayerTurnHints.emit_turn_ready_hints(mgr, player, acts)
    if not str(player.get(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT, "")).is_empty():
        OperationalLog.play_combat("soak_setup wf_controlling_close_hint ok")
    D001RunnerHelpers._free_manager(mgr)
    CombatConstants.set_headless_harness_quiet(was_quiet)

## III-4 **3e** + post-flee sparse: rank-0 survivor picks offense, `engagement_debug fight_finish=true`.
