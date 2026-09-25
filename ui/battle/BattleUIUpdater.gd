class_name BattleUIUpdater
extends RefCounted

## Updates a single combatant's UI row: gauge, state label, blood, consciousness, body bars.
## Gauge suffix order (footing): pick . attention . Step (PA) . flurry . exhaustion . Grd/Atk . Form —
## `_compose_waiting_gauge_label`. LIVE_PATHS **`#battle-ui`** . **`#wf-tier-44-pa`** (Step) .
## **`#wf-soak-audit-status`** (ii5c open for **` . Form`**).
## ctrl = id_to_controls[id], c = combatant dict from manager.get_combatants().
## Pass **`manager`** for live counter-tempo, attention salience, cooldown **`status_override`**, and
## Camp-3.3 medical-phase gauge tooltips (**`CombatUiHints.medical_phase_context_tooltip_lines`**).


static func _last_pick_suffix(c: Dictionary) -> String:
    return CombatDebug.turn_pick_kind_suffix(str(c.get("last_committed_move_id", "")))


static func _compose_waiting_gauge_label(c: Dictionary, primary: String, manager: Node = null) -> String:
    var attn_hint: String = CombatUiHints.attention_hint_text(c, manager)
    var foot_suffix: String = CombatUiHints.footwork_hint_suffix(c)
    var attn_suffix: String = (" . " + attn_hint) if not attn_hint.is_empty() else ""
    var flurry_suffix: String = CombatUiHints.flurry_bind_hint_suffix(c, manager)
    var exh_suffix: String = CombatUiHints.exhaustion_hint_suffix(c)
    var msc_suffix: String = CombatMuscleFatigue.gauge_hint_suffix(c, manager)
    var grd_suffix: String = CombatUiHints.guard_line_gauge_suffix(c)
    var form_suffix: String = CombatUiHints.weapon_form_gauge_suffix(c)
    var pick_suffix: String = _last_pick_suffix(c)
    return (
        primary
        + pick_suffix
        + attn_suffix
        + foot_suffix
        + flurry_suffix
        + exh_suffix
        + msc_suffix
        + grd_suffix
        + form_suffix
    )


static func _readiness_hint_suffix(c: Dictionary) -> String:
    var result: String = ""
    var gauge_pct: int = int(roundf(CombatantEntityAccess.gauge_float(c)))
    if gauge_pct >= 100:
        result = " . Ready"
    elif gauge_pct > 0:
        result = " . Rdy %d%%" % gauge_pct
    var mf := preload("res://combat/flow/CombatMuscleFatigue.gd")
    var msc_suffix: String = mf.gauge_hint_suffix(c)
    if not msc_suffix.is_empty():
        if not result.is_empty():
            result += msc_suffix
        else:
            result = "Ready" + msc_suffix
    return result


## Waiting row primary: stamina % of effective max; append turn-readiness when gauge is full.
static func _waiting_stamina_primary_label(c: Dictionary) -> String:
    var ratio_pct: int = int(roundf(CombatantEntityAccess.stamina_ratio(c) * 100.0))
    var label: String = "Stm %d%%" % ratio_pct
    label += _readiness_hint_suffix(c)
    return label


## Progress bar always shows absolute stamina; max scales with **`effective_stamina_max`**.
static func gauge_bar_max_for_combatant(c: Dictionary) -> float:
    return maxf(1.0, CombatExhaustion.effective_stamina_max(c))


static func gauge_bar_value_for_combatant(c: Dictionary, _manager: Node = null) -> float:
    return CombatantEntityAccess.stamina_float(c)


## Primary gauge label for a combatant snapshot row (harness + **`update_combatant_row`**).
static func gauge_label_text_for_combatant(c: Dictionary, manager: Node = null) -> String:
    # Partial snapshot rows omit `alive`; treat missing as living (matches `_sync_gauge_label` tooltips).
    if not CombatantEntityAccess.alive_bool(c, true):
        return "Defeated"
    if c.get(DataKeys.COMBATANT_COMBAT_ABSENT, false) or CombatantEntityAccess.state_str(c) == CombatConstants.STATE_FLED:
        return "Fled"
    var state: String = CombatantEntityAccess.state_str(c, "waiting")
    var state_timer: float = c.get(DataKeys.PA_STATE_TIMER, 0.0)
    var state_duration: float = c.get(DataKeys.PA_STATE_DURATION, 0.0)
    var remain: float = maxf(0.0, state_duration - state_timer)
    match state:
        "wind_up":
            var wu_prefix: String = "Counter" if c.get(DataKeys.SNAPSHOT_COUNTER_TEMPO_WIND_UP, false) else "Wind-up"
            return _compose_waiting_gauge_label(c, "%s %.1fs" % [wu_prefix, remain], manager)
        "medical_wind_up":
            return _compose_waiting_gauge_label(
                c, CombatUiHints.medical_wind_up_gauge_primary_label(c, remain), manager
            )
        "recovering":
            return _compose_waiting_gauge_label(c, "Recov. %.1fs" % remain, manager)
        CombatConstants.STATE_SWAP_RANK:
            return _compose_waiting_gauge_label(c, "Swap %.1fs . vulnerable" % remain, manager)
        CombatConstants.STATE_FALLING_BACK:
            return _compose_waiting_gauge_label(c, "Fall back %.1fs . vulnerable" % remain, manager)
        CombatConstants.STATE_COWERING:
            var cow_label: String = "Cowering"
            if CombatantEntityAccess.can_flee_or_fall_back(c):
                cow_label = "Cowering . can fall back"
            elif not CombatantEntityAccess.is_unconscious(c):
                cow_label = "Cowering . immobile"
            return _compose_waiting_gauge_label(c, cow_label, manager)
        "receiving_medical_attention":
            return _compose_waiting_gauge_label(c, "Receiving care", manager)
    var tempo_hint: String = CombatUiHints.counter_tempo_hint_key(c, manager)
    var counter_primary: String = CombatUiHints.counter_tempo_gauge_label(tempo_hint)
    var status_override: String = c.get(DataKeys.SNAPSHOT_STATUS_OVERRIDE, "").strip_edges()
    if status_override.is_empty() and manager != null:
        status_override = CombatCombatantsSnapshot.live_status_override_text(manager, c)
    if not counter_primary.is_empty():
        return _compose_waiting_gauge_label(c, counter_primary + _readiness_hint_suffix(c), manager)
    if not status_override.is_empty():
        return _compose_waiting_gauge_label(c, status_override, manager)
    var primary: String = _waiting_stamina_primary_label(c)
    if CombatConstants.COMBAT_DEBUG and c.get(DataKeys.SNAPSHOT_GUARD_ANGLE_DEG, null) is float:
        primary += " %.0ff''deg" % float(c.get(DataKeys.SNAPSHOT_GUARD_ANGLE_DEG))
    return _compose_waiting_gauge_label(c, primary, manager)


static func _sync_gauge_label(ctrl: Dictionary, c: Dictionary, text: String, manager: Node = null) -> void:
    if not ctrl.get("gauge_label"):
        return
    ctrl.gauge_label.text = text
    if not CombatantEntityAccess.alive_bool(c, true):
        ctrl.gauge_label.tooltip_text = "Defeated -- out of the fight."
        return
    if CombatantEntityAccess.has_left_battlefield(c):
        ctrl.gauge_label.tooltip_text = "Fled the field -- not in formation."
        return
    ctrl.gauge_label.tooltip_text = "\n".join(CombatUiHints.gauge_tooltip_lines(c, manager))


static func _sync_row_visuals(ctrl: Dictionary, c: Dictionary) -> void:
    var row: Control = ctrl.get("row") as Control
    if row == null or not row is CanvasItem:
        return
    if not CombatantEntityAccess.alive_bool(c, true):
        row.modulate = Color(0.65, 0.65, 0.65)
    elif CombatantEntityAccess.has_left_battlefield(c):
        row.modulate = Color(0.58, 0.6, 0.64)
    else:
        row.modulate = Color(1.0, 1.0, 1.0)


static func update_combatant_row(ctrl: Dictionary, c: Dictionary, manager: Node = null) -> void:
    _sync_row_visuals(ctrl, c)
    if ctrl.name:
        var row_node: Node = CombatantEntityAccess.scene_node(c)
        var base_name: String = str(row_node.name) if row_node != null else ctrl.name.text
        if CombatantEntityAccess.has_left_battlefield(c):
            ctrl.name.text = "%s (fled)" % base_name
        else:
            ctrl.name.text = base_name
    if ctrl.gauge:
        ctrl.gauge.max_value = gauge_bar_max_for_combatant(c)
        ctrl.gauge.value = gauge_bar_value_for_combatant(c, manager)
    if ctrl.get("gauge_label"):
        _sync_gauge_label(ctrl, c, gauge_label_text_for_combatant(c, manager), manager)
    # Blood volume and bleeding
    var s_row: Dictionary = CombatantEntityAccess.stats_dict(c)
    var bv: float = s_row.get("blood_volume", 100.0)
    if ctrl.get("blood_label"):
        ctrl.blood_label.text = PartyRowFormatter.format_blood_only(bv)
    if ctrl.get("blood_bar"):
        ctrl.blood_bar.value = clampf(bv, 0.0, 100.0)
    if ctrl.get("bleeding_label"):
        ctrl.bleeding_label.text = PartyRowFormatter.format_bleeding_only(s_row.get("total_bleeding_rate", 0.0))
    if ctrl.get("consciousness_label"):
        var pain: float = s_row.get("total_pain", 0.0)
        var consc: float = s_row.get("effective_consciousness", 100.0)
        var perf: float = s_row.get("performance_modifier", 1.0)
        ctrl.consciousness_label.text = (
            "Pain: %.1f | Consc: %d%% | Perf: %d%%" % [pain, int(clampf(consc, 0.0, 100.0)), int(roundf(perf * 100.0))]
        )
    if ctrl.get("body_diagram"):
        var body_stats: Dictionary = PartyRowFormatter.read_body_stat_dicts(s_row)
        var bc: Dictionary = body_stats["body_cutting"]
        var bb: Dictionary = body_stats["body_blunt"]
        var bm: Dictionary = body_stats["body_max"]
        var bone_h: Dictionary = body_stats["bone_health"]
        var bone_m: Dictionary = body_stats["bone_max"]
        for part in BodyPartConstants.BODY_PARTS:
            var mx = max(1, int(bm.get(part, 1)))
            var c_cur: float = bc.get(part, 0.0)
            var b_cur: float = bb.get(part, 0.0)
            # Region ratio reflects the worst of tissue and bone: a fractured bone shows damage even
            # when soft tissue is fine, and a deep cut (tissue at 0) shows immediately.
            var tissue_frac: float = clampf(minf(c_cur, b_cur) / float(mx), 0.0, 1.0)
            var bone_mx = max(1, int(bone_m.get(part, 1)))
            var bone_frac: float = clampf(bone_h.get(part, 0.0) / float(bone_mx), 0.0, 1.0)
            ctrl.body_diagram.set_part_health(part, minf(tissue_frac, bone_frac))
            if ctrl.get("body_labels") and part in ctrl.body_labels:
                ctrl.body_labels[part].text = PartyRowFormatter.format_body_part_compact(
                    part, bc, bb, bm, bone_h, bone_m
                )
                ctrl.body_labels[part].visible = mx > 0
