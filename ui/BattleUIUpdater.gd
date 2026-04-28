class_name BattleUIUpdater
extends RefCounted

const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")

## Updates a single combatant's UI row: gauge, state label, blood, consciousness, body bars.
## ctrl = id_to_controls[id], c = combatant dict from manager.get_combatants().

static func update_combatant_row(ctrl: Dictionary, c: Dictionary) -> void:
	if ctrl.name:
		var base_name: String = str(c.node.name) if c.node != null else ctrl.name.text
		if c.get("alive", true) and str(c.get("engagement_role", "")) == CombatConstants.ENGAGEMENT_ROLE_INTRUDED:
			base_name += " · intruded"
			var lo: float = absf(float(c.get("lane_offset", 0.0)))
			if lo >= 0.02:
				base_name += " (lane %.2f)" % float(c.get("lane_offset", 0.0))
		ctrl.name.text = base_name
	if ctrl.gauge:
		# Phase 1: Show stamina (0-100) instead of gauge. Gauge kept for compatibility (e.g. receiving_medical).
		var stamina: float = c.get("stamina", CombatConstants.STAMINA_MAX)
		ctrl.gauge.value = stamina
	if ctrl.get("gauge_label"):
		if not c.alive:
			ctrl.gauge_label.text = "Defeated"
		else:
			var state: String = c.get("state", "waiting")
			var state_timer: float = c.get("state_timer", 0.0)
			var state_duration: float = c.get("state_duration", 0.0)
			var remain: float = maxf(0.0, state_duration - state_timer)
			if state == "wind_up":
				ctrl.gauge_label.text = "Wind-up %.1fs" % remain
			elif state == "medical_wind_up":
				var pm = c.get("pending_medical", {})
				var mid: String = pm.get("medical_id", "")
				var tgt_cid: int = pm.get("target_combatant_id", c.id)
				var med_label: String = BattleUIConstants.MEDICAL_ACTION_LABELS_ALLY.get(mid, BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")) if tgt_cid != c.id else BattleUIConstants.MEDICAL_ACTION_LABELS.get(mid, "Medical")
				ctrl.gauge_label.text = "%s %.1fs" % [med_label, remain]
			elif state == "recovering":
				ctrl.gauge_label.text = "Recov. %.1fs" % remain
			elif state == CombatConstants.STATE_SWAP_RANK:
				ctrl.gauge_label.text = "Swap %.1fs" % remain
			elif state == CombatConstants.STATE_FALLING_BACK:
				ctrl.gauge_label.text = "Fall back %.1fs" % remain
			elif state == "receiving_medical_attention":
				ctrl.gauge_label.text = "Receiving care"
			elif c.get("status_override", "").is_empty() == false:
				# Event tracking: show closing/next-turn status so unit doesn't look frozen
				ctrl.gauge_label.text = str(c.status_override)
			else:
				# Phase 1: Event-driven ready. Gauge set to 100 when EVENT_ACTION_READY fires.
				var base: String = "Ready!" if c.gauge >= 100.0 else "Stm %d%%" % int(c.get("stamina", 100))
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
					ctrl.body_labels[part].text = _RowFormatter.format_body_part_compact(part, bc, bb, bm, bone_h, bone_m)
					ctrl.body_labels[part].visible = mx > 0
