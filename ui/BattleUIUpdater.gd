class_name BattleUIUpdater
extends RefCounted

const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")

## Updates a single combatant's UI row: gauge, state label, blood, consciousness, body bars.
## ctrl = id_to_controls[id], c = combatant dict from manager.get_combatants().

static func update_combatant_row(ctrl: Dictionary, c: Dictionary) -> void:
	if ctrl.name:
		ctrl.name.text = str(c.node.name) if c.node != null else ctrl.name.text
	if ctrl.gauge:
		var state: String = c.get("state", "waiting")
		# Action bar only shows fill when waiting (charging next turn); stays empty during swing/medical/recovery
		# receiving_medical_attention: gauge full (readied), cannot act until care finishes
		if state == "wind_up" or state == "medical_wind_up" or state == "recovering":
			ctrl.gauge.value = 0.0
		else:
			ctrl.gauge.value = c.gauge
	if ctrl.get("gauge_label"):
		if not c.alive:
			ctrl.gauge_label.text = "Defeated"
		else:
			var state: String = c.get("state", "waiting")
			var state_timer: float = c.get("state_timer", 0.0)
			var state_duration: float = c.get("state_duration", 0.0)
			if state == "wind_up":
				var remain: float = maxf(0.0, state_duration - state_timer)
				ctrl.gauge_label.text = "Wind-up %.1fs" % remain
			elif state == "medical_wind_up":
				var remain: float = maxf(0.0, state_duration - state_timer)
				var pm = c.get("pending_medical", {})
				var mid: String = pm.get("medical_id", "")
				var tgt_cid: int = pm.get("target_combatant_id", c.id)
				var med_label: String = BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(mid, BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")) if tgt_cid != c.id else BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
				ctrl.gauge_label.text = "%s %.1fs" % [med_label, remain]
			elif state == "recovering":
				var remain: float = maxf(0.0, state_duration - state_timer)
				ctrl.gauge_label.text = "Recov. %.1fs" % remain
			elif state == "receiving_medical_attention":
				ctrl.gauge_label.text = "Receiving care"
			else:
				var base: String = "Ready!" if c.gauge >= 100.0 else "%d%%" % int(c.gauge)
				if CombatConstants.COMBAT_DEBUG and c.get("guard_angle_deg", null) is float:
					base += " %.0f°" % float(c.guard_angle_deg)
				ctrl.gauge_label.text = base
	# Blood volume and bleeding
	var bv: float = c.stats.get("blood_volume", 100.0)
	if ctrl.get("blood_label"):
		ctrl.blood_label.text = _RowFormatter.format_blood_only(bv)
	if ctrl.get("blood_bar"):
		ctrl.blood_bar.value = clampf(bv, 0.0, 100.0)
	if ctrl.get("bleeding_label"):
		ctrl.bleeding_label.text = _RowFormatter.format_bleeding_only(c.stats.get("total_bleeding_rate", 0.0))
	if ctrl.get("consciousness_label"):
		var pain: float = c.stats.get("total_pain", 0.0)
		var consc: float = c.stats.get("effective_consciousness", 100.0)
		var perf: float = c.stats.get("performance_modifier", 1.0)
		ctrl.consciousness_label.text = "Pain: %.1f | Consc: %d%% | Perf: %d%%" % [pain, int(clampf(consc, 0.0, 100.0)), int(roundf(perf * 100.0))]
	if "body_bars" in ctrl and ctrl.body_bars:
		var bc: Dictionary = c.stats.get("body_cutting", {})
		var bb: Dictionary = c.stats.get("body_blunt", {})
		var bm: Dictionary = c.stats.get("body_max", {})
		var bone_h: Dictionary = c.stats.get("bone_health", {})
		var bone_m: Dictionary = c.stats.get("bone_max", {})
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
				if part in ctrl.get("body_labels", {}):
					ctrl.body_labels[part].text = _RowFormatter.format_body_part(part, bc, bb, bm, bone_h, bone_m)
					ctrl.body_labels[part].visible = mx > 0
