class_name CombatUiHints
extends RefCounted

## Shared UI hint resolution for snapshot rows and live combatant dicts.
## Gauge suffix order (footing): Step (PA) ->''--''''' ' Grd/Atk (guard line) ->''--''''' ' Form '
## **`BattleUIUpdater._compose_waiting_gauge_label`**. LIVE_PATHS **`#battle-ui`** '. **`#wf-1c--ui-surfacing`** '.
## **`#wf-tier-44-pa`** (Step) '. soak **`#wf-soak-audit-status`**.
## **`active_line_for_ui`**: wind-up ->''--''''' ' **`pending_attack`** line; else **`guard_line`** ' does **not** read
## **`weapon_form`** or PA offset.
## Diagram: guard **`[short]`** then form **`[Ox]`** ' **`FormationDiagramBuilder._cell_label_with_footwork`**.
## LIVE_PATHS **`#wf-footing-guards-stances`** '. **`#wf-guard-writers`** (L3 drift).
## **Camp-3.3:** one-shot medical-phase combat-log hints ' **once per play session** when
## `world` meta is set (campaign fights); **once per fight** on `manager` when no world node.

const WORLD_META_MEDICAL_PHASE_HINTS_SHOWN := "fp_medical_phase_hints_shown"
const _META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT := "_fp_medical_phase_hints_shown_fight"
const _META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT := "_fp_campaign_medical_exit_hint_shown_fight"

# Runtime preload ' circular dependency (CompanyState |' CampaignEncounterBridge |' CombatUiHints).
static var _company_state: Variant = null


static func _get_company_state() -> GDScript:
    if CombatUiHints._company_state == null:
        CombatUiHints._company_state = load("res://world/CompanyState.gd")
    return CombatUiHints._company_state


static func medical_phase_active(manager: Node) -> bool:
    return manager != null and manager.medical_phase


static func medical_phase_hints_already_shown(manager: Node, world: Node = null) -> bool:
    if world != null and world.has_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN):
        return world.get_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN) == true
    if manager != null and manager.has_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT):
        return manager.get_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT) == true
    return false


static func mark_medical_phase_hints_shown(manager: Node, world: Node = null) -> void:
    if world != null:
        world.set_meta(WORLD_META_MEDICAL_PHASE_HINTS_SHOWN, true)
    elif manager != null:
        manager.set_meta(_META_MEDICAL_PHASE_HINTS_SHOWN_FIGHT, true)


## One-shot combat-log copy when medical phase begins (Camp-3.3).
static func medical_phase_combat_log_hints() -> PackedStringArray:
    return PackedStringArray(
        [
            "Medical phase  -  your side triages only; defeated opponents cannot strike or act.",
            (
                "Triage priority: hold direct pressure on active bleeds (especially arterial), "
                + "then bandage or pack "
                + "(battle bandages are free; pack/stabilize cost -1 company med each)."
            ),
            (
                "Allies choose medical actions automatically  -  gauge may show Stack medical or "
                + "self_medical when triage is urgent."
            ),
            (
                "Stabilize (1 med) slows bleeding but does not dress the wound  -  bandage, pack, or "
                + "tourniquet still required before camp rest or marching."
            ),
        ]
    )


static func _campaign_medical_exit_hint_shown_this_fight(manager: Node) -> bool:
    return (
        manager != null
        and manager.has_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT)
        and bool(manager.get_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT))
    )


static func _mark_campaign_medical_exit_hint_shown(manager: Node) -> void:
    if manager != null:
        manager.set_meta(_META_CAMPAIGN_MEDICAL_EXIT_HINT_SHOWN_FIGHT, true)


## Emit session/fight one-shot hints via **`manager.notify_combat_ui_hint`** (BattleScene hook).
static func emit_medical_phase_session_hints(manager: Node, world: Node = null) -> void:
    if not medical_phase_active(manager) or not manager.has_method("notify_combat_ui_hint"):
        return
    var emit_general: bool = not medical_phase_hints_already_shown(manager, world)
    if emit_general:
        mark_medical_phase_hints_shown(manager, world)
        for line in medical_phase_combat_log_hints():
            # Combat log only ' FP uses `note_medical_phase_intro` + `medical_action pick`.
            manager.notify_combat_ui_hint(line, false)
    if world != null:
        var supply_hint: String = _get_company_state().format_battle_medical_supply_hint(world)
        if (
            not supply_hint.is_empty()
            and (emit_general or _get_company_state().is_campaign_contract_battle_world(world))
        ):
            manager.notify_combat_ui_hint(supply_hint, false)
    if (
        world != null
        and _get_company_state().is_campaign_contract_battle_world(world)
        and not _campaign_medical_exit_hint_shown_this_fight(manager)
    ):
        _mark_campaign_medical_exit_hint_shown(manager)
        var triage_ready: bool = manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase()
        var exit_hint: String = (
            BattleUIConstants.CAMPAIGN_MEDICAL_EARLY_EXIT_HINT_READY
            if triage_ready
            else BattleUIConstants.CAMPAIGN_MEDICAL_EARLY_EXIT_HINT
        )
        manager.notify_combat_ui_hint(exit_hint, false)


static func medical_phase_context_tooltip_lines(manager: Node, world: Node = null) -> PackedStringArray:
    if not medical_phase_active(manager):
        return PackedStringArray()
    var winner: String = str(manager.medical_phase_winner).strip_edges()
    var lines: PackedStringArray = []
    var resolved_world: Node = world if world != null else _get_company_state().resolve_world_from_battle(manager)
    var campaign_contract: bool = _get_company_state().is_campaign_contract_battle_world(resolved_world)
    if winner.is_empty():
        lines.append(
            (
                "Medical phase ' triage wounded allies before returning to camp."
                if campaign_contract
                else "Medical phase ' triage wounded allies before ending the battle."
            )
        )
    else:
        lines.append("Medical phase ' %s side triages only; opponents cannot strike." % winner)
    lines.append("Priority: direct pressure, then bandage/pack/TQ. Battle bandages are free; stabilize costs 1 med.")
    if campaign_contract:
        var triage_ready: bool = manager.has_method("can_end_medical_phase") and manager.can_end_medical_phase()
        lines.append(
            (
                BattleUIConstants.CAMPAIGN_MEDICAL_TOOLTIP_EXIT_READY
                if triage_ready
                else BattleUIConstants.CAMPAIGN_MEDICAL_TOOLTIP_EXIT_PENDING
            )
        )
    return lines


static func medical_wind_up_gauge_primary_label(c: Dictionary, remain: float) -> String:
    var pm: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_medical")
    var mid: String = pm.get(DataKeys.MEDICAL_ID, "").strip_edges()
    var self_id: int = CombatantEntityAccess.id_int(c)
    var tgt_cid: int = int(pm.get(DataKeys.MEDICAL_TARGET_COMBATANT_ID, self_id))
    var med_label: String = (
        BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(
            mid, BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
        )
        if tgt_cid != self_id
        else BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
    )
    return "%s %.1fs" % [med_label, remain]


static func medical_busy_row_tooltip_line(c: Dictionary) -> String:
    var st: String = CombatantEntityAccess.state_str(c)
    if st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
        return "Receiving care ' another combatant is treating this wound."
    if st == CombatConstants.STATE_MEDICAL_WIND_UP:
        return "Medical wind-up ' hold until the procedure completes."
    return ""


static func _first_exported_hint(c: Dictionary, keys: Array) -> String:
    for key in keys:
        var s: String = str(c.get(key, "")).strip_edges()
        if not s.is_empty():
            return s
    return ""


## Tier 4.4 PA gauge text ' from live offset when flag on; exported row key when off. LIVE_PATHS **`#wf-tier-44-pa`**
## (UI phase) '. **`#battle-ui`**.
static func footwork_hint_text(c: Dictionary) -> String:
    if not CombatFootwork.enabled():
        return c.get(DataKeys.POSITION_ANGLE_UI_HINT, "").strip_edges()
    return CombatFootwork.get_ui_hint(c)


## Formation diagram cell suffix (empty ' offset is not shown on the diagram); gauge via **`footwork_hint_text`**.
static func footwork_diagram_suffix(c: Dictionary) -> String:
    if c == null:
        return ""
    var exported: String = c.get(DataKeys.POSITION_ANGLE_UI_HINT, "").strip_edges()
    if not CombatFootwork.enabled():
        if exported.is_empty():
            return ""
        return (" . " + exported) if not exported.begins_with(" . ") else exported
    return CombatFootwork.get_diagram_label_suffix(c)


## Gauge **` . Step`** suffix from Tier 4.4 PA · **`#battle-ui`** · **`#wf-tier-44-pa`** (display only).
static func footwork_hint_suffix(c: Dictionary) -> String:
    var hint: String = footwork_hint_text(c)
    return (" . " + hint) if not hint.is_empty() else ""


static func attention_hint_text(c: Dictionary, manager: Node = null) -> String:
    if c.is_empty():
        return ""
    if not CombatAttention.enabled():
        return _first_exported_hint(c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT])
    if manager != null:
        return CombatAttention.live_ui_hint(manager, c)
    var exported: String = _first_exported_hint(
        c, ["attention_ui_hint", CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT]
    )
    if not exported.is_empty():
        return exported
    return CombatAttention.snapshot_ui_hint(c)


## Snapshot row keys + live derive when **`manager`** set (see **`CounterTempo.snapshot_ui_hint`**).
static func counter_tempo_hint_key(c: Dictionary, manager: Node = null) -> String:
    if c == null or c.is_empty():
        return ""
    var row: String = _first_exported_hint(
        c, ["counter_tempo_ui_hint", CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT]
    )
    if not CounterTempo.enabled():
        return row
    if manager != null:
        var live: String = CounterTempo.snapshot_ui_hint(manager, c)
        return live if not live.is_empty() else row
    return row


## Empty unless **`STATE_COWERING`** (Tier **6.1** mobility).
static func cowering_mobility_tooltip_line(c: Dictionary) -> String:
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_COWERING:
        return ""
    if CombatantEntityAccess.can_flee_or_fall_back(c):
        return "No arms ' may fall back when rear rank in your file is clear."
    if not CombatantEntityAccess.is_unconscious(c):
        return "No arms ' holding position (fall back blocked)."
    return ""


## C3: Form-switch transition tooltip ' vulnerable during guard repositioning.
static func form_switch_tooltip_line(c: Dictionary) -> String:
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_FORM_SWITCH:
        return ""
    var old_form: String = str(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_OLD_FORM, "")).strip_edges()
    var target_form: String = str(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_TARGET_FORM, "")).strip_edges()
    var remaining: float = maxf(0.0, c.get(DataKeys.PA_STATE_DURATION, 0.0) - c.get(DataKeys.PA_STATE_TIMER, 0.0))
    if old_form.is_empty() or target_form.is_empty():
        return "Repositioning blade (%.1fs)" % remaining
    return "Repositioning %s → %s (%.1fs)" % [old_form, target_form, remaining]


static func flurry_bind_gauge_label(c: Dictionary, manager: Node = null) -> String:
    if not CombatFlurryBind.enabled() or manager == null or c.is_empty():
        return ""
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    if not CombatFlurryBind.is_active(c, clk):
        return ""
    return "Bind exchange"


static func flurry_bind_hint_suffix(c: Dictionary, manager: Node = null) -> String:
    var label: String = flurry_bind_gauge_label(c, manager)
    return (" . " + label) if not label.is_empty() else ""


static func exhaustion_hint_suffix(c: Dictionary) -> String:
    return CombatExhaustion.gauge_hint_suffix(c)


static func _guard_line_ui_states() -> Array:
    return [
        CombatConstants.STATE_WAITING,
        CombatConstants.STATE_WIND_UP,
        CombatConstants.STATE_RECOVERING,
        CombatConstants.STATE_COWERING,
    ]


## L3 moment line for gauge/diagram ' wind-up ->''--''''' ' **`pending_attack`** line; else **`guard_line`**. Does
## **not** read **`weapon_form`** or PA offset. LIVE_PATHS **`#wf-guard-writers`** '. **`#battle-ui`**.
static func active_line_for_ui(c: Dictionary) -> String:
    if not CombatConstants.is_feature_hema_eight_guard_lines_enabled() or c.is_empty():
        return ""
    var st: String = CombatantEntityAccess.state_str(c)
    if st not in _guard_line_ui_states():
        return ""
    if st == CombatConstants.STATE_WIND_UP:
        var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
        var attack_line: String = pa.get(DataKeys.PA_ATTACK_LINE, "").strip_edges()
        if not attack_line.is_empty():
            return attack_line
        var move_id: String = pa.get(DataKeys.ATTACK_ATTACK_TYPE, pa.get(DataKeys.ACTION_MOVE_ID, "")).strip_edges()
        if not move_id.is_empty():
            var move_def: Dictionary = WeaponConstants.get_move(move_id)
            return move_def.get(DataKeys.PA_ATTACK_LINE, "").strip_edges()
        return ""
    return str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()


## Gauge **` . Grd`** / **` . Atk`** suffix from **`active_line_for_ui`**. LIVE_PATHS **`#battle-ui`** · soak content
## asserts open **`#wf-soak-audit-status`**.
static func guard_line_gauge_suffix(c: Dictionary) -> String:
    var line: String = active_line_for_ui(c)
    if line.is_empty():
        return ""
    var short: String = CombatGuardLines.display_short_for_line(line)
    if short.is_empty():
        return ""
    var prefix: String = "Atk" if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP else "Grd"
    return " . %s %s" % [prefix, short]


static func guard_line_diagram_suffix(c: Dictionary) -> String:
    var line: String = active_line_for_ui(c)
    if line.is_empty():
        return ""
    var short: String = CombatGuardLines.display_short_for_line(line)
    if short.is_empty():
        return ""
    return " [%s]" % short


static func guard_line_tooltip_line(c: Dictionary) -> String:
    var line: String = active_line_for_ui(c)
    if line.is_empty():
        return ""
    var long_label: String = CombatGuardLines.display_long_for_line(line)
    if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
        return "Attack line: %s" % long_label
    return "Guard: %s" % long_label


## Gauge **` . Form {name}`** from **`form_str`** · independent of **`guard_line`** drift. LIVE_PATHS **`#battle-ui`** ·
## **`#wf-1c--ui-surfacing`** · soak **`#wf-soak-audit-status`** (ii5c open).
static func weapon_form_gauge_suffix(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    var name: String = CombatWeaponForm.display_name(CombatantEntityAccess.form_str(c))
    if name.is_empty():
        return ""
    return " . Form %s" % name


## Diagram **`[Ox]`** suffix from **`form_str`** ' after guard short in **`FormationDiagramBuilder`**. LIVE_PATHS
## **`#battle-ui`**.
static func weapon_form_diagram_suffix(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    var name: String = CombatWeaponForm.display_name(CombatantEntityAccess.form_str(c))
    if name.is_empty():
        return ""
    return " [%s]" % name


## IV-11 slice 4: diagram **`[Ldr]`** for player party leader ' **`FormationDiagramBuilder`**. LIVE_PATHS
## **`#battle-ui`**.
static func party_leader_diagram_suffix(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    if CombatantEntityAccess.side_str(c) != "player":
        return ""
    if c.get(DataKeys.COMBATANT_IS_PARTY_LEADER, false) != true:
        return ""
    return " [Ldr]"


## IV-11 slice 6: diagram **`[Cmd]`** for enemy commander ' **`FormationDiagramBuilder`**.
static func enemy_leader_diagram_suffix(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    if CombatantEntityAccess.side_str(c) != "enemy":
        return ""
    if c.get(DataKeys.COMBATANT_IS_ENEMY_LEADER, false) != true:
        return ""
    return " [Cmd]"


static func party_leader_tooltip_line(c: Dictionary) -> String:
    if party_leader_diagram_suffix(c).is_empty():
        return ""
    return "Party leader"


static func enemy_leader_tooltip_line(c: Dictionary) -> String:
    if enemy_leader_diagram_suffix(c).is_empty():
        return ""
    return "Enemy commander"


static func weapon_form_tooltip_line(c: Dictionary) -> String:
    if c.is_empty():
        return ""
    var form: String = CombatantEntityAccess.form_str(c)
    var name: String = CombatWeaponForm.display_name(form)
    if name.is_empty():
        return ""
    var pressure: String = CombatWeaponForm.pressure_class_label_for_ui(c)
    if not pressure.is_empty():
        return "Form: %s (%s)" % [name, pressure]
    return "Form: %s" % name


## Short label fragment for listed **`attempt_close`** vs a controlling defender.
static func close_attempt_list_hint_for_defender(defender: Dictionary) -> String:
    if defender.is_empty():
        return ""
    if not CombatWeaponForm.controlling_pressure_active(defender):
        return ""
    var form: String = CombatantEntityAccess.form_str(defender)
    var fname: String = CombatWeaponForm.display_name(form)
    if fname.is_empty():
        return "controlling defender"
    return "%s (controlling)" % fname


## Player turn hint when **`attempt_close`** is listed vs a controlling defender (Fool / space-holding form).
static func controlling_defender_close_hint_line(manager: Node, c: Dictionary, actions: Array) -> String:
    if manager == null or c.is_empty() or actions.is_empty():
        return ""
    if not CombatantEntityAccess.is_player_side(c):
        return ""
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(DataKeys.ACTION_MOVE_ID, "") != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tid: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tid < 0:
            continue
        var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid)
        if tgt.is_empty():
            continue
        var tag: String = close_attempt_list_hint_for_defender(tgt)
        if tag.is_empty():
            continue
        return "Close is harder vs %s ' strike from range or commit with strength." % tag.replace(" (controlling)", "")
    return ""


static func surround_arc_occupancy_tooltip_line(c: Dictionary, manager: Node = null) -> String:
    if manager == null or c.is_empty():
        return ""
    if not CombatConstants.is_feature_surround_arc_occupancy_enabled():
        return ""
    var blocked: int = TacticalCombat.arc_occupancy_blocked_for_defender(manager, c)
    if blocked <= 0:
        return ""
    return "Arc overlap: %d threat(s) share your front sector (reduced surround weight)." % blocked


static func counter_tempo_gauge_label(tempo_hint: String) -> String:
    if tempo_hint.is_empty():
        return ""
    if tempo_hint == "counter_ready":
        return "Counter!"
    if tempo_hint == "counter_winding":
        return "Seize tempo'f''s'|"
    return ""


## Export stamped hint fields on a **`CombatCombatantsSnapshot`** row from live **`c`**.
static func stamp_snapshot_hint_fields(item: Dictionary, c: Dictionary, manager: Node) -> void:
    if CombatFootwork.enabled() and CombatFootwork.offset_visible_for_ui_state(c):
        var off_deg: float = CombatFootwork.get_defender_offset_deg(c)
        if absf(off_deg) >= 0.01:
            item[DataKeys.PA_POSITION_ANGLE_OFFSET_DEG] = off_deg
        var fw_hint: String = footwork_hint_text(c)
        if not fw_hint.is_empty():
            item[DataKeys.POSITION_ANGLE_UI_HINT] = fw_hint
    if CombatAttention.enabled():
        var attn_hint: String = _first_exported_hint(
            c, [CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "attention_ui_hint"]
        )
        if attn_hint.is_empty():
            attn_hint = attention_hint_text(c, manager)
        if not attn_hint.is_empty():
            item[DataKeys.ATTENTION_UI_HINT] = attn_hint
    if CounterTempo.enabled() and manager != null:
        var tempo_hint: String = counter_tempo_hint_key(c, manager)
        if not tempo_hint.is_empty():
            item[DataKeys.COUNTER_TEMPO_UI_HINT] = tempo_hint


## Waiting tick: salience + yomi + attention UI stamp (see **`CombatAttention.refresh_for_waiting_tick`**).
static func refresh_waiting_tick_stamps(manager: Node, c: Dictionary) -> void:
    if manager == null or c == null or not CombatAttention.enabled():
        return
    CombatAttention.refresh_for_waiting_tick(manager, c)


static func gauge_tooltip_lines(c: Dictionary, manager: Node = null) -> PackedStringArray:
    var tips: PackedStringArray = []
    var st0: String = CombatantEntityAccess.state_str(c)
    if st0 in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
        var ratio_pct: int = int(roundf(CombatantEntityAccess.stamina_ratio(c) * 100.0))
        var cap_pct: int = int(roundf(CombatExhaustion.effective_stamina_max(c)))
        tips.append(
            "Stamina %d%% of %d burst max ' progress bar (label shows Stm when waiting)." % [ratio_pct, cap_pct]
        )
        var gauge_pct: int = int(roundf(CombatantEntityAccess.gauge_float(c)))
        if gauge_pct >= 100:
            tips.append("Turn ready ' action selection allowed for this combatant.")
        elif gauge_pct > 0:
            tips.append("Readiness %d%% ' turn / counter-tempo gauge (label only)." % gauge_pct)
    var fw: String = footwork_hint_text(c)
    if not fw.is_empty():
        tips.append("Arc footwork (position-angle step): %s" % fw)
    var attn: String = attention_hint_text(c, manager)
    if not attn.is_empty():
        tips.append("Attention: %s" % attn)
    var tempo: String = counter_tempo_hint_key(c, manager)
    if tempo == "counter_ready":
        tips.append("Counter window open ' seize tempo.")
    elif tempo == "counter_winding":
        tips.append("Incoming wind-up ' counter window building.")
    if c.get(DataKeys.SNAPSHOT_COUNTER_TEMPO_WIND_UP, false):
        tips.append("Counter-tempo riposte ' shortened wind-up.")
    if (
        CombatFlurryBind.enabled()
        and manager != null
        and CombatFlurryBind.is_active(c, CombatantEntityAccess.combat_clock_float(manager))
    ):
        var left: int = c.get(CombatFlurryBind.KEY_EXCHANGES, 0)
        tips.append("Bind exchange ' faster blows vs bound opponent (%d exchange(s) left)." % maxi(0, left))
    var cow: String = cowering_mobility_tooltip_line(c)
    if not cow.is_empty():
        tips.append(cow)
    var fsw: String = form_switch_tooltip_line(c)
    if not fsw.is_empty():
        tips.append(fsw)
    if manager != null:
        var rout: String = CombatFormationRout.rout_pressure_tooltip_line(manager, c)
        if not rout.is_empty():
            tips.append(rout)
    var fm: String = CombatFormationMoveDuration.formation_preview_tooltip_line(manager, c)
    if not fm.is_empty():
        tips.append(fm)
    var cap_tip: String = CombatExhaustion.stamina_cap_tooltip_line(c)
    if not cap_tip.is_empty() and st0 not in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
        tips.append(cap_tip)
    var exh: String = CombatExhaustion.gauge_tooltip_line(c)
    if not exh.is_empty():
        tips.append(exh)
    var msc: String = CombatMuscleFatigue.gauge_tooltip_line(c, manager)
    if not msc.is_empty():
        tips.append(msc)
    var arc_sur: String = surround_arc_occupancy_tooltip_line(c, manager)
    if not arc_sur.is_empty():
        tips.append(arc_sur)
    var grd: String = guard_line_tooltip_line(c)
    if not grd.is_empty():
        tips.append(grd)
    var wf: String = weapon_form_tooltip_line(c)
    if not wf.is_empty():
        tips.append(wf)
    var st: String = CombatantEntityAccess.state_str(c)
    if manager != null and medical_phase_active(manager):
        for mp_line in medical_phase_context_tooltip_lines(manager):
            tips.append(mp_line)
        var busy_line: String = medical_busy_row_tooltip_line(c)
        if not busy_line.is_empty():
            tips.append(busy_line)
    if st in [CombatConstants.STATE_WAITING, CombatConstants.STATE_COWERING]:
        var listed_fm: String = str(c.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
        if not listed_fm.is_empty():
            tips.append(listed_fm)
        var hold_line: String = str(c.get(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
        if not hold_line.is_empty():
            tips.append(hold_line)
        var close_ctrl: String = str(c.get(CombatConstants.COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT, "")).strip_edges()
        if not close_ctrl.is_empty():
            tips.append(close_ctrl)
    if st in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]:
        tips.append(
            (
                (
                    "Formation move ' heavy hits (intensity ->''--'''''degf''s'' %.0f) may cancel; lighter hits extend "
                    + "duration."
                )
                % CombatConstants.FORMATION_HIT_CANCEL_INTENSITY
            )
        )
    return tips


static func formation_cell_tooltip_lines(
    c: Dictionary, display_name: String, manager: Node = null
) -> PackedStringArray:
    var lines: PackedStringArray = []
    var fw: String = footwork_hint_text(c)
    if not fw.is_empty():
        lines.append("%s  -  footwork: %s" % [display_name, fw])
    var attn: String = attention_hint_text(c, manager)
    if not attn.is_empty():
        lines.append("%s  -  attention: %s" % [display_name, attn])
    var tempo: String = counter_tempo_hint_key(c, manager)
    if tempo == "counter_ready":
        lines.append("%s  -  counter window open" % display_name)
    elif tempo == "counter_winding":
        lines.append("%s  -  counter window building" % display_name)
    var cow: String = cowering_mobility_tooltip_line(c)
    if not cow.is_empty():
        lines.append("%s  -  %s" % [display_name, cow])
    var fsw: String = form_switch_tooltip_line(c)
    if not fsw.is_empty():
        lines.append("%s  -  %s" % [display_name, fsw])
    var fm: String = CombatFormationMoveDuration.formation_preview_tooltip_line(manager, c)
    if not fm.is_empty():
        lines.append("%s  -  %s" % [display_name, fm])
    var grd: String = guard_line_tooltip_line(c)
    if not grd.is_empty():
        lines.append("%s  -  %s" % [display_name, grd])
    var wf: String = weapon_form_tooltip_line(c)
    if not wf.is_empty():
        lines.append("%s  -  %s" % [display_name, wf])
    var ldr: String = party_leader_tooltip_line(c)
    if not ldr.is_empty():
        lines.append("%s  -  %s" % [display_name, ldr])
    var cmd: String = enemy_leader_tooltip_line(c)
    if not cmd.is_empty():
        lines.append("%s  -  %s" % [display_name, cmd])
    return lines


