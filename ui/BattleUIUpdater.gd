class_name BattleUIUpdater
extends RefCounted

const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

## Updates a single combatant's UI row: gauge, state label, blood, consciousness, body bars.
## ctrl = id_to_controls[id], c = combatant dict from manager.get_combatants().

static func _footwork_hint_suffix(c: Dictionary) -> String:
	var hint: String = _Footwork.get_ui_hint(c)
	return (" · " + hint) if not hint.is_empty() else ""


static func _append_footwork_hint(base: String, c: Dictionary) -> String:
	return base + _footwork_hint_suffix(c)


static func update_combatant_row(ctrl: Dictionary, c: Dictionary) -> void:
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
		# Phase 1: Show stamina (0-100) instead of gauge. Gauge kept for compatibility (e.g. receiving_medical).
		var stamina: float = _EntityAccess.stamina_float(c)
		ctrl.gauge.value = stamina
	if ctrl.get("gauge_label"):
		if not _EntityAccess.alive_bool(c):
			ctrl.gauge_label.text = "Defeated"
		else:
			var state: String = _EntityAccess.state_str(c, "waiting")
			var state_timer: float = c.get("state_timer", 0.0)
			var state_duration: float = c.get("state_duration", 0.0)
			var remain: float = maxf(0.0, state_duration - state_timer)
			if state == "wind_up":
				ctrl.gauge_label.text = _append_footwork_hint("Wind-up %.1fs" % remain, c)
			elif state == "medical_wind_up":
				var pm: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_medical")
				var mid: String = pm.get("medical_id", "")
				var self_id: int = _EntityAccess.id_int(c)
				var tgt_cid: int = pm.get("target_combatant_id", self_id)
				var med_label: String = BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(mid, BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")) if tgt_cid != self_id else BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
				ctrl.gauge_label.text = "%s %.1fs" % [med_label, remain]
			elif state == "recovering":
				ctrl.gauge_label.text = _append_footwork_hint("Recov. %.1fs" % remain, c)
			elif state == CombatConstants.STATE_SWAP_RANK:
				ctrl.gauge_label.text = "Swap %.1fs" % remain
			elif state == CombatConstants.STATE_FALLING_BACK:
				ctrl.gauge_label.text = "Fall back %.1fs" % remain
			elif state == "receiving_medical_attention":
				ctrl.gauge_label.text = "Receiving care"
			elif not str(c.get("status_override", "")).is_empty():
				# Event tracking: show closing/next-turn status so unit doesn't look frozen
				ctrl.gauge_label.text = _append_footwork_hint(str(c.get("status_override", "")), c)
			else:
				var tempo_hint: String = str(c.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
				var attn_hint: String = ""
				if _Attention.enabled():
					attn_hint = str(c.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "")).strip_edges()
				var foot_suffix: String = _footwork_hint_suffix(c)
				var attn_suffix: String = (" · " + attn_hint) if not attn_hint.is_empty() else ""
				if tempo_hint == "counter_ready" and _CounterTempo.enabled():
					ctrl.gauge_label.text = "Counter!" + attn_suffix + foot_suffix
				elif tempo_hint == "counter_winding" and _CounterTempo.enabled():
					ctrl.gauge_label.text = "Seize tempo…" + attn_suffix + foot_suffix
				elif not attn_hint.is_empty():
					ctrl.gauge_label.text = attn_hint + foot_suffix
				elif not foot_suffix.is_empty():
					var base_fw: String = (
						"Ready!" if _EntityAccess.gauge_float(c) >= 100.0
						else "Stm %d%%" % int(_EntityAccess.stamina_float(c))
					)
					ctrl.gauge_label.text = base_fw + foot_suffix
				else:
					# Phase 1: Event-driven ready. Gauge set to 100 when EVENT_ACTION_READY fires.
					var base: String = "Ready!" if _EntityAccess.gauge_float(c) >= 100.0 else "Stm %d%%" % int(_EntityAccess.stamina_float(c))
					if CombatConstants.COMBAT_DEBUG and c.get("guard_angle_deg", null) is float:
						base += " %.0f°" % float(c.get("guard_angle_deg"))
					ctrl.gauge_label.text = base
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
