class_name BattleUIUpdater
extends RefCounted

const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")

## Updates a single combatant's UI row: gauge, state label, blood, consciousness, body bars.
## ctrl = id_to_controls[id], c = combatant dict from manager.get_combatants().
## Pass **`manager`** so counter-tempo tooltips can derive live window state (stamped row keys alone are insufficient).

static func _compose_waiting_gauge_label(c: Dictionary, primary: String) -> String:
	var attn_hint: String = _UiHints.attention_hint_text(c)
	var foot_suffix: String = _UiHints.footwork_hint_suffix(c)
	var attn_suffix: String = (" · " + attn_hint) if not attn_hint.is_empty() else ""
	return primary + attn_suffix + foot_suffix


## Progress bar fill: readiness **`gauge`** during counter-tempo window, else stamina (Phase 1).
static func gauge_bar_value_for_combatant(c: Dictionary) -> float:
	if not _UiHints.counter_tempo_gauge_label(_UiHints.counter_tempo_hint_key(c)).is_empty():
		return _EntityAccess.gauge_float(c)
	return _EntityAccess.stamina_float(c)


## Primary gauge label for a combatant snapshot row (harness + **`update_combatant_row`**).
static func gauge_label_text_for_combatant(c: Dictionary) -> String:
	if not _EntityAccess.alive_bool(c):
		return "Defeated"
	var state: String = _EntityAccess.state_str(c, "waiting")
	var state_timer: float = float(c.get("state_timer", 0.0))
	var state_duration: float = float(c.get("state_duration", 0.0))
	var remain: float = maxf(0.0, state_duration - state_timer)
	if state == "wind_up":
		var wu_prefix: String = "Counter" if bool(c.get("is_counter_tempo_wind_up", false)) else "Wind-up"
		return _compose_waiting_gauge_label(c, "%s %.1fs" % [wu_prefix, remain])
	if state == "medical_wind_up":
		var pm: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_medical")
		var mid: String = pm.get("medical_id", "")
		var self_id: int = _EntityAccess.id_int(c)
		var tgt_cid: int = int(pm.get("target_combatant_id", self_id))
		var med_label: String = (
			BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(mid, BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical"))
			if tgt_cid != self_id
			else BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
		)
		return _compose_waiting_gauge_label(c, "%s %.1fs" % [med_label, remain])
	if state == "recovering":
		return _compose_waiting_gauge_label(c, "Recov. %.1fs" % remain)
	if state == CombatConstants.STATE_SWAP_RANK:
		return _compose_waiting_gauge_label(c, "Swap %.1fs" % remain)
	if state == CombatConstants.STATE_FALLING_BACK:
		return _compose_waiting_gauge_label(c, "Fall back %.1fs" % remain)
	if state == CombatConstants.STATE_COWERING:
		var cow_label: String = "Cowering"
		if _EntityAccess.can_flee_or_fall_back(c):
			cow_label = "Cowering · can fall back"
		elif not _EntityAccess.is_unconscious(c):
			cow_label = "Cowering · immobile"
		return _compose_waiting_gauge_label(c, cow_label)
	if state == "receiving_medical_attention":
		return "Receiving care"
	var tempo_hint: String = _UiHints.counter_tempo_hint_key(c)
	var counter_primary: String = _UiHints.counter_tempo_gauge_label(tempo_hint)
	var status_override: String = str(c.get("status_override", "")).strip_edges()
	if not counter_primary.is_empty():
		return _compose_waiting_gauge_label(c, counter_primary)
	if not status_override.is_empty():
		return _compose_waiting_gauge_label(c, status_override)
	var attn_hint: String = _UiHints.attention_hint_text(c)
	var foot_suffix: String = _UiHints.footwork_hint_suffix(c)
	if not attn_hint.is_empty():
		return attn_hint + foot_suffix
	if not foot_suffix.is_empty():
		var base_fw: String = (
			"Ready!" if _EntityAccess.gauge_float(c) >= 100.0
			else "Stm %d%%" % int(_EntityAccess.stamina_float(c))
		)
		return base_fw + foot_suffix
	var base: String = (
		"Ready!" if _EntityAccess.gauge_float(c) >= 100.0
		else "Stm %d%%" % int(_EntityAccess.stamina_float(c))
	)
	if CombatConstants.COMBAT_DEBUG and c.get("guard_angle_deg", null) is float:
		base += " %.0f°" % float(c.get("guard_angle_deg"))
	return base


static func _sync_gauge_label(ctrl: Dictionary, c: Dictionary, text: String, manager: Node = null) -> void:
	if not ctrl.get("gauge_label"):
		return
	ctrl.gauge_label.text = text
	if not _EntityAccess.alive_bool(c, true):
		ctrl.gauge_label.tooltip_text = "Defeated — out of the fight."
		return
	ctrl.gauge_label.tooltip_text = "\n".join(_UiHints.gauge_tooltip_lines(c, manager))


static func update_combatant_row(ctrl: Dictionary, c: Dictionary, manager: Node = null) -> void:
	if ctrl.name:
		var row_node: Node = _EntityAccess.scene_node(c)
		var base_name: String = str(row_node.name) if row_node != null else ctrl.name.text
		if _EntityAccess.alive_bool(c, true) and _ZoneOfControl.is_intruded(c):
			base_name += " · intruded"
			var lo: float = absf(float(c.get("lane_offset", 0.0)))
			if lo >= 0.02:
				base_name += " (lane %.2f)" % float(c.get("lane_offset", 0.0))
		ctrl.name.text = base_name
	if ctrl.gauge:
		ctrl.gauge.value = gauge_bar_value_for_combatant(c)
	if ctrl.get("gauge_label"):
		_sync_gauge_label(ctrl, c, gauge_label_text_for_combatant(c), manager)
	# Blood volume and bleeding
	var s_row: Dictionary = _EntityAccess.stats_dict(c)
	var bv: float = s_row.get("blood_volume", 100.0)
	if ctrl.get("blood_label"):
		ctrl.blood_label.text = _RowFormatter.format_blood_only(bv)
	if ctrl.get("blood_bar"):
		ctrl.blood_bar.value = clampf(bv, 0.0, 100.0)
	if ctrl.get("bleeding_label"):
		ctrl.bleeding_label.text = _RowFormatter.format_bleeding_only(s_row.get("total_bleeding_rate", 0.0))
	if ctrl.get("consciousness_label"):
		var pain: float = s_row.get("total_pain", 0.0)
		var consc: float = s_row.get("effective_consciousness", 100.0)
		var perf: float = s_row.get("performance_modifier", 1.0)
		ctrl.consciousness_label.text = "Pain: %.1f | Consc: %d%% | Perf: %d%%" % [pain, int(clampf(consc, 0.0, 100.0)), int(roundf(perf * 100.0))]
	if "body_bars" in ctrl and ctrl.body_bars:
		var bc: Dictionary = _EntityAccess.nested_dictionary_read(s_row, "body_cutting")
		var bb: Dictionary = _EntityAccess.nested_dictionary_read(s_row, "body_blunt")
		var bm: Dictionary = _EntityAccess.nested_dictionary_read(s_row, "body_max")
		var bone_h: Dictionary = _EntityAccess.nested_dictionary_read(s_row, "bone_health")
		var bone_m: Dictionary = _EntityAccess.nested_dictionary_read(s_row, "bone_max")
		for part in BodyPartConstants.BODY_PARTS:
			if part in ctrl.body_bars:
				var bar: ProgressBar = ctrl.body_bars[part]
				var c_cur: float = bc.get(part, 0.0)
				var b_cur: float = bb.get(part, 0.0)
				var mx = max(1, bm.get(part, 1))
				var worst: float = minf(c_cur, b_cur)
				bar.max_value = float(mx)
				bar.value = worst
				bar.visible = mx > 0
				if part in _EntityAccess.nested_dictionary_read(ctrl, "body_labels"):
					ctrl.body_labels[part].text = _RowFormatter.format_body_part_compact(part, bc, bb, bm, bone_h, bone_m)
					ctrl.body_labels[part].visible = mx > 0
