class_name CombatRegressionHarnessAttentionFootworkTailPartF
extends RefCounted

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_combat_ui_hints_cowering_gauge_tooltip(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
    CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    c["state"] = CombatConstants.STATE_COWERING
    var mobile_tip: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
    if not mobile_tip.contains("fall back"):
        CombatRegressionHarness._fail(failures, "ui_hints_cowering: mobile want fall back tip got '%s'" % mobile_tip)
    CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
    CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
    var immobile_tip: String = "\n".join(_UiHints.gauge_tooltip_lines(c, mgr))
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not immobile_tip.contains("holding position"):
        CombatRegressionHarness._fail(failures, "ui_hints_cowering: immobile want holding tip got '%s'" % immobile_tip)


## Tier 6.1 UI: formation diagram cell tooltips include cowering mobility.


## Tier 6.1 UI: formation diagram cell tooltips include cowering mobility.
static func _run_combat_ui_hints_formation_cowering_tooltip(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = CombatantEntityAccess.scene_node(c) as CoreEntity
    CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
    CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
    c["state"] = CombatConstants.STATE_COWERING
    var nm: String = CombatantEntityAccess.get_display_name(c, CombatantEntityAccess.id_int(c))
    var lines: PackedStringArray = _UiHints.formation_cell_tooltip_lines(c, nm, mgr)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    var joined: String = "\n".join(lines)
    if not joined.contains("fall back"):
        CombatRegressionHarness._fail(failures, "ui_hints_formation_cow: want fall back got '%s'" % joined)


static func _run_battle_ui_gauge_label_live_counter_tempo_needs_manager(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 55.0
    _WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
    def.erase("counter_tempo_ui_hint")
    var without_mgr: String = BattleUIUpdater.gauge_label_text_for_combatant(def)
    var with_mgr: String = BattleUIUpdater.gauge_label_text_for_combatant(def, mgr)
    var bar_no_mgr: float = BattleUIUpdater.gauge_bar_value_for_combatant(def)
    var bar_with_mgr: float = BattleUIUpdater.gauge_bar_value_for_combatant(def, mgr)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if without_mgr.begins_with("Seize tempo"):
        CombatRegressionHarness._fail(
            failures,
            "gauge_label_live: unstamped row should not show counter label without manager got '%s'" % without_mgr
        )
    if not with_mgr.begins_with("Seize tempo"):
        CombatRegressionHarness._fail(
            failures, "gauge_label_live: want Seize tempo prefix with manager got '%s'" % with_mgr
        )
    if not is_equal_approx(bar_no_mgr, 100.0):
        CombatRegressionHarness._fail(
            failures, "gauge_bar_live: without manager bar should show stamina (100) got %.2f" % bar_no_mgr
        )
    if not is_equal_approx(bar_with_mgr, 100.0):
        CombatRegressionHarness._fail(
            failures, "gauge_bar_live: with manager bar should still show stamina (100) got %.2f" % bar_with_mgr
        )


## Tier 4.2 UI: formation tooltips derive counter window from **`manager`** when unstamped.


## Tier 4.2 UI: formation tooltips derive counter window from **`manager`** when unstamped.
static func _run_combat_ui_hints_formation_counter_tempo_needs_manager(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    _WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
    def.erase("counter_tempo_ui_hint")
    var nm: String = CombatantEntityAccess.get_display_name(def, def_id)
    var without_mgr: String = "\n".join(_UiHints.formation_cell_tooltip_lines(def, nm))
    var with_mgr: String = "\n".join(_UiHints.formation_cell_tooltip_lines(def, nm, mgr))
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if without_mgr.contains("counter window"):
        CombatRegressionHarness._fail(failures, "formation_counter_live: without manager got '%s'" % without_mgr)
    if not with_mgr.contains("counter window building"):
        CombatRegressionHarness._fail(
            failures, "formation_counter_live: with manager want building tip got '%s'" % with_mgr
        )


## Tier 4.3 UI: with **`manager`**, stale **`attention_ui_hint`** stamp ignored when telegraph absent.


## Tier 4.3 UI: with **`manager`**, stale **`attention_ui_hint`** stamp ignored when telegraph absent.
static func _run_combat_ui_hints_attention_stale_stamp_prefers_live(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    var c: Dictionary = {"guard_zone": "head", CombatConstants.COMBATANT_KEY_FOCUS_PART: "head"}
    c[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = "Tel head . Focus head 99%"
    var mgr: Node = _MgrScript.new()
    var stamped_path: String = _UiHints.attention_hint_text(c)
    var live_path: String = _UiHints.attention_hint_text(c, mgr)
    CombatConstants.set_feature_combat_attention_load(false)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not stamped_path.contains("Tel head"):
        CombatRegressionHarness._fail(failures, "attention_stale: snapshot path want Tel got '%s'" % stamped_path)
    if live_path.contains("Tel head"):
        CombatRegressionHarness._fail(failures, "attention_stale: live path should drop Tel got '%s'" % live_path)


## Tier 4.3 UI: **`attention_hint_text(..., manager)`** refreshes load during incoming wind-up.


## Tier 4.3 UI: **`attention_hint_text(..., manager)`** refreshes load during incoming wind-up.
static func _run_combat_ui_hints_attention_live_refresh_load_during_windup(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    _WindUpStarter.start(
        mgr,
        CombatantEntityAccess.id_int(atk),
        CombatantEntityAccess.id_int(def),
        "oberhau_feint",
        {"target_part": "chest", "feint_part": "head"}
    )
    def.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
    def.erase("attention_ui_hint")
    def[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 0.0
    var without_mgr: String = _UiHints.attention_hint_text(def)
    var with_mgr: String = _UiHints.attention_hint_text(def, mgr)
    CombatConstants.set_feature_combat_attention_load(false)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if without_mgr.contains("Load 45") or without_mgr.contains("Load 40"):
        CombatRegressionHarness._fail(
            failures, "attention_live_load: without manager should not refresh load got '%s'" % without_mgr
        )
    if with_mgr.find("Load ") < 0:
        CombatRegressionHarness._fail(
            failures, "attention_live_load: with manager want Load segment got '%s'" % with_mgr
        )


static func _run_strike_stamping_weapon_eff_dist_sanity(failures: PackedStringArray) -> void:
    var w: Weapon = _Weapon.create_from_definition("SWORD")
    if w == null:
        CombatRegressionHarness._fail(failures, "strike_stamp: missing SWORD")
        return
    var eff: float = 1.25
    var ratio: float = _StrikeStamping.strike_measure_ratio_for_weapon_eff_dist(w, eff)
    if not is_finite(ratio) or ratio < 0.0:
        CombatRegressionHarness._fail(failures, "strike_stamp: want finite non-negative ratio got %.4f" % ratio)


## Tier 4.4 UI: stamped hint without offset is ignored (row/diagram stay blank).


## Tier 4.4 UI: stamped hint without offset is ignored (row/diagram stay blank).
static func _run_footwork_ui_hint_ignores_orphan_stamp_without_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {}
    c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99deg"
    var live: String = CombatFootwork.get_ui_hint(c)
    var sfx: String = CombatFootwork.get_diagram_label_suffix(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if not live.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_orphan_stamp: get_ui_hint should be empty got '%s'" % live)
    if not sfx.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_orphan_stamp: diagram suffix should be empty got '%s'" % sfx)


## Tier 4.4.3: clearing offset clears stamped UI hint key.


## Tier 4.4.3: clearing offset clears stamped UI hint key.
static func _run_footwork_diagram_label_suffix_compact(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {"state": CombatConstants.STATE_WIND_UP}
    CombatFootwork.apply_attack_step_on_windup(c, "left")
    var sfx: String = CombatFootwork.get_diagram_label_suffix(c)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if not sfx.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_diagram_suffix: want empty got '%s'" % sfx)


## Tier 4.4.3: stale stamped hint yields live offset when they disagree.


## Tier 4.4.3: stale stamped hint yields live offset when they disagree.
static func _run_footwork_snapshot_includes_position_hint_when_enabled(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    _WindUpStarter.start(mgr, CombatantEntityAccess.id_int(atk), CombatantEntityAccess.id_int(def), "slash")
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_snapshot: expected one row")
        return
    var row: Dictionary = rows[0]
    if not row.has("position_angle_offset_deg"):
        CombatRegressionHarness._fail(failures, "footwork_snapshot: missing position_angle_offset_deg")
    var want_hint: String = CombatFootwork.get_ui_hint(atk)
    if str(row.get("position_angle_ui_hint", "")) != want_hint:
        CombatRegressionHarness._fail(
            failures,
            (
                "footwork_snapshot: ui hint mismatch row='%s' want='%s'"
                % [row.get("position_angle_ui_hint", ""), want_hint]
            )
        )


## Tier 4.4.3: snapshot derives UI hint from offset when stamp key missing.


## Tier 4.4.3: snapshot derives UI hint from offset when stamp key missing.
static func _run_footwork_snapshot_ui_hint_from_unstamped_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var atk: Dictionary = mgr.combatants[0]
    var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
    atk["state"] = CombatConstants.STATE_WIND_UP
    atk.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    var want_hint: String = CombatFootwork.get_ui_hint(atk)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_snapshot_unstamped: expected one row")
        return
    var row: Dictionary = rows[0]
    if str(row.get("position_angle_ui_hint", "")) != want_hint:
        CombatRegressionHarness._fail(
            failures,
            "footwork_snapshot_unstamped: want '%s' got '%s'" % [want_hint, row.get("position_angle_ui_hint", "")]
        )
    if absf(float(row.get("position_angle_offset_deg", 0.0)) - off) > 0.01:
        CombatRegressionHarness._fail(failures, "footwork_snapshot_unstamped: offset deg missing or wrong")


## Tier 4.4 UI soak: snapshot copies stamped attention hint for gauge/diagram consumers.


## Tier 4.4 UI soak: snapshot copies stamped attention hint for gauge/diagram consumers.
static func _run_footwork_snapshot_omits_position_when_disabled(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var atk: Dictionary = mgr.combatants[0]
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    CombatConstants.set_feature_position_angle_footwork_load(false)
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "footwork_snapshot_disabled: expected one row")
        return
    var row: Dictionary = rows[0]
    if row.has("position_angle_offset_deg") or row.has("position_angle_ui_hint"):
        CombatRegressionHarness._fail(
            failures, "footwork_snapshot_disabled: should omit position_angle keys when flag off"
        )


## Tier 4.4: body-part -> guard line for dodge step direction.


## Tier 4.4: body-part -> guard line for dodge step direction.
static func _run_combat_snapshot_exports_attention_ui_hint_when_stamped(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    var stamped: String = "Tel head . Focus head 80%"
    def[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = stamped
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_combat_attention_load(false)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_attention: expected one row")
        return
    if str(rows[0].get("attention_ui_hint", "")) != stamped:
        CombatRegressionHarness._fail(
            failures, "snapshot_attention: row='%s' want='%s'" % [rows[0].get("attention_ui_hint", ""), stamped]
        )


## Tier 4.4 UI soak: snapshot copies stamped counter-tempo hint for gauge consumers.


## Tier 4.4 UI soak: snapshot copies stamped counter-tempo hint for gauge consumers.
static func _run_combat_snapshot_exports_counter_tempo_ui_hint_when_stamped(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    var stamped: String = "counter_ready"
    def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = stamped
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_counter_tempo: expected one row")
        return
    if str(rows[0].get("counter_tempo_ui_hint", "")) != stamped:
        CombatRegressionHarness._fail(
            failures, "snapshot_counter_tempo: row='%s' want='%s'" % [rows[0].get("counter_tempo_ui_hint", ""), stamped]
        )


## Tier 4.2 UI soak: counter-tempo row hint wins over scheduled-next **`status_override`**.


## Tier 4.2 UI soak: counter-tempo row hint wins over scheduled-next **`status_override`**.
static func _run_combat_snapshot_suppresses_next_override_during_counter_tempo(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(def)
    def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_ready"
    (
        mgr
        . event_queue
        . append(
            {
                "type": CombatConstants.EVENT_ACTION_READY,
                "combatant_id": def_id,
                "resolve_at": float(mgr.combat_clock) + 0.5,
            }
        )
    )
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_counter_next: expected one row")
        return
    var row: Dictionary = rows[0]
    if str(row.get("counter_tempo_ui_hint", "")) != "counter_ready":
        CombatRegressionHarness._fail(
            failures, "snapshot_counter_next: counter hint missing row=%s" % row.get("counter_tempo_ui_hint", "")
        )
    if row.has("status_override"):
        CombatRegressionHarness._fail(
            failures,
            "snapshot_counter_next: status_override should be suppressed got '%s'" % row.get("status_override", "")
        )


## Tier 4.3 UI soak: snapshot derives attention row hint from telegraph when stamp missing.


## Tier 4.3 UI soak: snapshot derives attention row hint from telegraph when stamp missing.
static func _run_combat_snapshot_derives_attention_ui_hint_from_telegraph(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    def[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    def.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
    var want: String = _UiHints.attention_hint_text(def, mgr)
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_combat_attention_load(false)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if want.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_attention_derive: expected non-empty derived hint")
        return
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_attention_derive: expected one row")
        return
    if str(rows[0].get("attention_ui_hint", "")) != want:
        CombatRegressionHarness._fail(
            failures, "snapshot_attention_derive: row='%s' want='%s'" % [rows[0].get("attention_ui_hint", ""), want]
        )


## Tier 4.2 UI soak: snapshot derives counter-tempo hint from open window when stamp missing.


## Tier 4.2 UI soak: snapshot derives counter-tempo hint from open window when stamp missing.
static func _run_combat_snapshot_derives_counter_tempo_ui_hint_from_open_window(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 60.0
    _WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    def.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    var want: String = CounterTempo.snapshot_ui_hint(mgr, def)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_counter_derive: expected two rows")
        return
    var row: Dictionary = rows[1]
    if want != "counter_winding":
        CombatRegressionHarness._fail(failures, "snapshot_counter_derive: want counter_winding got '%s'" % want)
    if str(row.get("counter_tempo_ui_hint", "")) != want:
        CombatRegressionHarness._fail(
            failures, "snapshot_counter_derive: row='%s' want='%s'" % [row.get("counter_tempo_ui_hint", ""), want]
        )


## Tier 4.2 UI: gauge label prefers counter hint over **`status_override`**.


## Tier 4.2 UI: gauge label prefers counter hint over **`status_override`**.
static func _run_battle_ui_gauge_label_counter_beats_status_override(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var row: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WAITING,
        "status_override": "Next: 0.1s",
        "counter_tempo_ui_hint": "counter_ready",
        "gauge": 100.0,
        "stamina": 100.0,
    }
    var text: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    CombatConstants.set_feature_counter_tempo_load(true)
    if not text.begins_with("Counter!"):
        CombatRegressionHarness._fail(failures, "battle_ui_counter_label: want Counter! prefix got '%s'" % text)
    if text.find("Next:") >= 0:
        CombatRegressionHarness._fail(failures, "battle_ui_counter_label: should not show Next override in '%s'" % text)


## Tier 4.3 UI: **`status_override`** row still shows attention fragment.


## Tier 4.3 UI: **`status_override`** row still shows attention fragment.
static func _run_battle_ui_gauge_label_status_override_includes_attention(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_combat_attention_load(true)
    var attn: String = "Tel head . Focus head 80%"
    var row: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WAITING,
        "status_override": "Closing 1.2s",
        "attention_ui_hint": attn,
        "gauge": 40.0,
        "stamina": 40.0,
    }
    var text: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    CombatConstants.set_feature_combat_attention_load(false)
    if text.find("Closing") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_status_attn: missing Closing in '%s'" % text)
    if text.find("Tel head") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_status_attn: missing attention in '%s'" % text)


## Tier 4.2 UI: counter-tempo wind-up uses **Counter** prefix on gauge row.


## Tier 4.2 UI: counter-tempo wind-up uses **Counter** prefix on gauge row.
static func _run_battle_ui_gauge_label_counter_wind_up_prefix(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var row: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": 0.1,
        "state_duration": 0.5,
        "is_counter_tempo_wind_up": true,
    }
    var text: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    CombatConstants.set_feature_counter_tempo_load(true)
    if not text.begins_with("Counter "):
        CombatRegressionHarness._fail(failures, "battle_ui_counter_windup: want Counter prefix got '%s'" % text)


## Tier 4.2 UI soak: snapshot skips Closing/Crash/Next overrides while counter window UI active.


## Tier 4.2 UI soak: snapshot skips Closing/Crash/Next overrides while counter window UI active.
static func _run_combat_snapshot_omits_closing_override_during_counter_tempo(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_ready"
    def["action_cooldown_until"] = float(mgr.combat_clock) + 2.0
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "snapshot_counter_closing: expected one row")
        return
    if rows[0].has("status_override"):
        CombatRegressionHarness._fail(
            failures,
            (
                "snapshot_counter_closing: status_override should be suppressed got '%s'"
                % rows[0].get("status_override", "")
            )
        )


## Tier 4.4 UI soak: **`gauge_label_text_for_combatant`** matches **`CombatCombatantsSnapshot.build`** row.
## WF-1c + Tier 4.4: gauge suffix order **Step -> Atk -> Form** during wind-up  -  LIVE_PATHS
## **`#wf-soak-audit-status`**.


## Tier 4.4 UI soak: **`gauge_label_text_for_combatant`** matches **`CombatCombatantsSnapshot.build`** row.
## WF-1c + Tier 4.4: gauge suffix order **Step -> Atk -> Form** during wind-up  -  LIVE_PATHS
## **`#wf-soak-audit-status`**.
static func _run_battle_ui_gauge_suffix_step_atk_form_order(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        return
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var c: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": 0.0,
        "state_duration": 1.0,
        "gauge": 100.0,
        "stamina": 67.0,
        "guard_line": "high",
        CombatConstants.COMBATANT_KEY_WEAPON_FORM: _WeaponForm.FORM_OX,
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: 14.0,
        "pending_attack": {"attack_line": "high_right", "move_id": "oberhau"},
    }
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c)
    for needle in ["Step", "Atk", " . Form Ox"]:
        if needle not in label:
            CombatRegressionHarness._fail(
                failures, "gauge_suffix_step_atk_form: missing '%s' in '%s'" % [needle, label]
            )
            return
    var step_i: int = label.find("Step")
    var atk_i: int = label.find("Atk")
    var form_i: int = label.find(" . Form Ox")
    if step_i < 0 or atk_i < 0 or form_i < 0 or not (step_i < atk_i and atk_i < form_i):
        CombatRegressionHarness._fail(failures, "gauge_suffix_step_atk_form: want Step<Atk<Form order got '%s'" % label)


static func _run_battle_ui_gauge_label_matches_snapshot_row(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_combat_attention_load(true)
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var def: Dictionary = mgr.combatants[0]
    def[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = "counter_winding"
    def["gauge"] = 80.0
    def["stamina"] = 80.0
    var rows: Array = CombatCombatantsSnapshot.build(mgr)
    if rows.is_empty():
        CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: expected one row")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var row: Dictionary = rows[0]
    var want: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatConstants.set_feature_combat_attention_load(false)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if not want.begins_with("Seize tempo"):
        CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: want Seize tempo prefix got '%s'" % want)
    if want.find("Tel head") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_snapshot_row: missing attention fragment in '%s'" % want)


## Tier 4.4 UI soak: exported row hints still render when feature flags are toggled off.


## Tier 4.4 UI soak: exported row hints still render when feature flags are toggled off.
static func _run_battle_ui_gauge_label_renders_exported_hints_when_features_off(failures: PackedStringArray) -> void:
    var row: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_WAITING,
        "attention_ui_hint": "Tel head . Focus head 80%",
        "counter_tempo_ui_hint": "counter_ready",
        "position_angle_ui_hint": "Step +14deg",
        "gauge": 100.0,
        "stamina": 100.0,
    }
    CombatConstants.set_feature_combat_attention_load(false)
    CombatConstants.set_feature_counter_tempo_load(false)
    CombatConstants.set_feature_position_angle_footwork_load(false)
    var text: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    CombatConstants.set_feature_combat_attention_load(true)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if not text.begins_with("Counter!"):
        CombatRegressionHarness._fail(failures, "battle_ui_exported_off: want Counter! prefix got '%s'" % text)
    if text.find("Tel head") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_exported_off: missing attention in '%s'" % text)
    if text.find("Step +14") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_exported_off: missing footwork in '%s'" % text)


## Tier 4.3 UI: recovering row keeps exported attention fragment.


## Tier 4.3 UI: recovering row keeps exported attention fragment.
static func _run_battle_ui_gauge_label_recovering_includes_exported_attention(failures: PackedStringArray) -> void:
    var row: Dictionary = {
        "alive": true,
        "state": "recovering",
        "state_timer": 0.2,
        "state_duration": 1.0,
        "attention_ui_hint": "Tel head . Focus head 80%",
    }
    var text: String = BattleUIUpdater.gauge_label_text_for_combatant(row)
    if not text.begins_with("Recov."):
        CombatRegressionHarness._fail(failures, "battle_ui_recov_attn: want Recov prefix got '%s'" % text)
    if text.find("Tel head") < 0:
        CombatRegressionHarness._fail(failures, "battle_ui_recov_attn: missing attention in '%s'" % text)


## Tier 4.2 UI: player turn-ready combat log hint when counter-tempo melee is listed.


## Tier 4.2 UI: player turn-ready combat log hint when counter-tempo melee is listed.
static func _run_player_counter_tempo_turn_ready_hint_when_window_open(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_counter_tempo_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var ply: Dictionary = mgr.combatants[0]
    var en: Dictionary = mgr.combatants[1]
    var ply_id: int = CombatantEntityAccess.id_int(ply)
    var en_id: int = CombatantEntityAccess.id_int(en)
    ply["gauge"] = 80.0
    _WindUpStarter.start(mgr, en_id, ply_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, en_id, 0.6)
    CounterTempo.process_waiting(mgr, ply)
    var actions: Array = mgr.get_available_actions(ply_id)
    var hint: String = _PlayerTurnHints.counter_tempo_hint_if_applicable(mgr, ply, actions)
    CombatConstants.set_feature_counter_tempo_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if hint.is_empty():
        CombatRegressionHarness._fail(failures, "player_counter_hint: expected non-empty hint")
        return
    if hint.find("seize tempo") < 0:
        CombatRegressionHarness._fail(failures, "player_counter_hint: want seize tempo in '%s'" % hint)


## Tier 4.2 UI: progress bar always maps to stamina (counter-tempo readiness on label only).


## Tier 4.2 UI: progress bar always maps to stamina (counter-tempo readiness on label only).
static func _run_battle_ui_gauge_bar_always_stamina_even_during_counter_tempo(failures: PackedStringArray) -> void:
    var row_counter: Dictionary = {
        "alive": true,
        "counter_tempo_ui_hint": "counter_ready",
        "gauge": 72.0,
        "stamina": 40.0,
    }
    if absf(BattleUIUpdater.gauge_bar_value_for_combatant(row_counter) - 40.0) > 0.01:
        CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: counter row should use stamina=40")
    if absf(BattleUIUpdater.gauge_bar_max_for_combatant(row_counter) - CombatConstants.STAMINA_MAX) > 0.01:
        CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: fresh counter row max should be STAMINA_MAX")
    var row_plain: Dictionary = {
        "alive": true,
        "gauge": 72.0,
        "stamina": 40.0,
    }
    if absf(BattleUIUpdater.gauge_bar_value_for_combatant(row_plain) - 40.0) > 0.01:
        CombatRegressionHarness._fail(failures, "battle_ui_gauge_bar: plain row should use stamina=40")


## Tier 4.4.3: snapshot omits position-angle fields when footwork flag off.


## Tier 4.4.3: snapshot omits position-angle fields when footwork flag off.
static func _run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures: PackedStringArray) -> void:
    var want_leg: String = (
        _GuardLines.LINE_LOW_RIGHT if CombatConstants.is_feature_hema_eight_guard_lines_enabled() else "low"
    )
    var want_chest: String = (
        _GuardLines.LINE_HIGH if CombatConstants.is_feature_hema_eight_guard_lines_enabled() else "high"
    )
    if CombatConstants.guard_line_for_body_part("right_leg") != want_leg:
        CombatRegressionHarness._fail(failures, "footwork_part_line: right_leg want %s" % want_leg)
    if CombatConstants.guard_line_for_body_part("chest") != want_chest:
        CombatRegressionHarness._fail(failures, "footwork_part_line: chest want %s" % want_chest)


## Tier 4.4: parry-eval helpers do not stamp offset; dodge commit replaces parry stamp.


## Tier 4.4: parry-eval helpers do not stamp offset; dodge commit replaces parry stamp.
static func _run_footwork_choose_defense_dodge_does_not_keep_parry_offset(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var def: Dictionary = {"guard_line": "left"}
    var prov: float = CombatFootwork.parry_eval_step_deg_for_defender(def)
    if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_provisional: parry_eval must not stamp offset on combatant")
    if prov < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_provisional: want non-zero eval step for left guard")
    var dodge_prov: float = CombatFootwork.dodge_eval_step_deg_for_defender(def, "left_arm")
    if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_provisional: dodge_eval must not stamp offset on combatant")
    if dodge_prov < 0.01:
        CombatRegressionHarness._fail(failures, "footwork_provisional: want non-zero dodge eval for left_arm")
    CombatFootwork.apply_defender_step_on_parry(def, "left")
    var parry_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    CombatFootwork.clear_position_offset(def)
    CombatFootwork.apply_defender_step_on_dodge(def, "left_arm")
    var dodge_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
    var want_dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
        "left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
    )
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if absf(parry_off - dodge_off) < 0.01:
        CombatRegressionHarness._fail(
            failures, "footwork_commit_dodge: dodge offset should differ from parry stamp got %.2f" % dodge_off
        )
    if absf(dodge_off - want_dodge) > 0.05:
        CombatRegressionHarness._fail(
            failures, "footwork_commit_dodge: want dodge offset %.2f got %.2f" % [want_dodge, dodge_off]
        )


## Tier 4.4: **`arc_end_deg_for_contact_geometry`** must not treat offset-bearing **`attack_angle_deg`** as arc end.


## Tier 4.4: **`arc_end_deg_for_contact_geometry`** must not treat offset-bearing **`attack_angle_deg`** as arc end.
static func _run_footwork_arc_contact_applies_offset_once(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG:
        CombatConstants.position_angle_offset_deg_for_attack_line("left"),
    }
    var arc_start: float = 0.0
    var arc_end_base: float = 90.0
    var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end_base, 1.0)
    at_contact = CombatFootwork.apply_offset_to_angle_deg(at_contact, atk)
    var doubled: float = CombatFootwork.apply_offset_to_angle_deg(
        CombatConstants.get_arc_angle_at_progress(
            arc_start, arc_end_base + atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0), 1.0
        ),
        atk
    )
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var want: float = fmod(
        arc_end_base + float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0)) + 360.0, 360.0
    )
    if absf(at_contact - want) > 0.05:
        CombatRegressionHarness._fail(failures, "footwork_arc_once: want %.2f got %.2f" % [want, at_contact])
    if absf(doubled - at_contact) < 0.05:
        CombatRegressionHarness._fail(
            failures, "footwork_arc_once: double-apply would match got %.2f (want distinct)" % at_contact
        )


## Tier 4.4: flag off  -  step-on-windup does not stamp offset (restore production default after).


## Tier 4.4: flag off  -  step-on-windup does not stamp offset (restore production default after).
static func _run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
    var pa: Dictionary = {
        "arc_intended_deg": 90.0,
        "attack_angle_deg": fmod(90.0 + off + 360.0, 360.0),
    }
    var end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if absf(end - 90.0) > 0.05:
        CombatRegressionHarness._fail(failures, "footwork_arc_end_fb: want intended 90 got %.2f" % end)
    var arc_start: float = float(pa.get("arc_start_deg", 0.0))
    var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
    var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, 1.0)
    var atk: Dictionary = {CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: off}
    at_contact = CombatFootwork.apply_offset_to_angle_deg(at_contact, atk)
    var doubled: float = CombatFootwork.apply_offset_to_angle_deg(90.0 + off, atk)
    if absf(at_contact - doubled) < 0.05:
        CombatRegressionHarness._fail(
            failures, "footwork_arc_end_fb: progress-1 should apply offset once got %.2f" % at_contact
        )


## Tier 4.4: **`parry_partial`** follow-through must not re-roll resolve angle geometry.


## Tier 4.4: **`parry_partial`** follow-through must not re-roll resolve angle geometry.
static func _run_footwork_windup_arc_intended_includes_attacker_step(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var mgr: Node = _MgrScript.new()
    var p_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    var e_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(p_ent, "player")
    mgr.register(e_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    seed(42)
    _WindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "chest"})
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var atk: Dictionary = mgr._get_by_id(p_id)
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
    var intended: float = float(pa.get("arc_intended_deg", -999.0))
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var atk_line: String = str(move_def.get("attack_line", "high"))
    var off: float = CombatConstants.position_angle_offset_deg_for_attack_line(atk_line)
    var want: float = fmod(CombatConstants.line_to_angle(atk_line) + off + 360.0, 360.0)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    if intended < -900.0:
        CombatRegressionHarness._fail(failures, "footwork_windup_intended: missing arc_intended_deg")
        return
    if absf(intended - want) > 0.05:
        CombatRegressionHarness._fail(failures, "footwork_windup_intended: want %.2f got %.2f" % [want, intended])


## Tier 4.4: **`arc_end_deg`** stays pre-offset; parry contact applies footwork once (not twice at progress 1).


## Tier 4.4: **`arc_end_deg`** stays pre-offset; parry contact applies footwork once (not twice at progress 1).
static func _run_footwork_partial_follow_through_freezes_resolve_angles(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(true)
    var atk: Dictionary = {
        CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG:
        CombatConstants.position_angle_offset_deg_for_attack_line("high"),
    }
    var pa: Dictionary = {
        "passive_parry_attempted": true,
        "attack_angle_deg": 201.0,
        "arc_end_deg": 187.0,
        "arc_span_deg": 42.0,
        "effective_attack_line": "left",
        "arc_start_deg": 0.0,
    }
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    AttackResolver.stamp_resolve_angle_geometry_on_pa(pa, atk, "high", move_def, 0.0)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if absf(float(pa.get("attack_angle_deg", -1.0)) - 201.0) > 0.05:
        CombatRegressionHarness._fail(
            failures,
            "footwork_partial_freeze: attack_angle_deg changed to %.2f" % float(pa.get("attack_angle_deg", -1.0))
        )
    if absf(float(pa.get("arc_end_deg", -1.0)) - 187.0) > 0.05:
        CombatRegressionHarness._fail(
            failures, "footwork_partial_freeze: arc_end_deg changed to %.2f" % float(pa.get("arc_end_deg", -1.0))
        )
    if absf(float(pa.get("arc_span_deg", -1.0)) - 42.0) > 0.05:
        CombatRegressionHarness._fail(
            failures, "footwork_partial_freeze: arc_span_deg changed to %.2f" % float(pa.get("arc_span_deg", -1.0))
        )
    if str(pa.get("effective_attack_line", "")) != "left":
        CombatRegressionHarness._fail(
            failures,
            "footwork_partial_freeze: effective_attack_line changed to %s" % str(pa.get("effective_attack_line", ""))
        )


## Tier 4.4: wind-up **`arc_intended_deg`** includes attacker step (guard transition + arc query).


## Tier 4.4: wind-up **`arc_intended_deg`** includes attacker step (guard transition + arc query).
static func _run_footwork_disabled_skips_windup_stamp(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_position_angle_footwork_load(false)
    var atk: Dictionary = {}
    CombatFootwork.apply_attack_step_on_windup(atk, "left")
    CombatConstants.set_feature_position_angle_footwork_load(true)
    if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
        CombatRegressionHarness._fail(failures, "footwork_disabled: offset must not stamp when flag off")

## AI target pick: weapon/form limb bias + perception/intelligence scale off-focus exploitation.
