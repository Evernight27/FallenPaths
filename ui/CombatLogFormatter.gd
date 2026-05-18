class_name CombatLogFormatter
extends RefCounted

## Formats combat action results as BBCode strings for the combat log.
## BattleScene calls format_action_line() and appends the result to RichTextLabel.
## **`parry_deflect`** / **`parry_partial`**: optional **`parry_clash_context`** on **`result`** (from **`action_resolved`** after **`AttackResultApplier`**) — extra clash suffix only when **`CombatConstants.COMBAT_DEBUG_CALIBRATION`** (partial adds **`rem=`** leak ratio).

static func _eff_pct(result: Dictionary) -> int:
	return int(roundf(result.get("effectiveness", 1.0) * 100.0))


static func _medical_procedure_label(move_id: String, on_self: bool) -> String:
	var base: String = move_id.replace("_", " ")
	if on_self:
		return base
	match move_id:
		"bandage_self":
			return "bandage (ally)"
		"pack_wound":
			return "pack wound (ally)"
		"apply_tourniquet":
			return "tourniquet (ally)"
		_:
			return "%s (ally)" % base


static func _medical_on_self(result: Dictionary, attacker_name: String, target_name: String) -> bool:
	if result.has("medical_target_is_self"):
		return bool(result.get("medical_target_is_self", true))
	return attacker_name == target_name


static func _medical_procedure_log_line(
	success: bool,
	success_clause: String,
	fail_verb: String,
	fail_note: String,
	attacker_name: String,
	attacker_side: String,
	target_name: String,
	part_label: String,
	result: Dictionary,
	procedure_verb: String = ""
) -> String:
	var who: String = "%s (%s)" % [attacker_name, attacker_side]
	var eff: int = _eff_pct(result)
	var target_part: String = "%s's %s" % [target_name, part_label]
	if success:
		if not procedure_verb.is_empty():
			return "[color=teal]%s %s %s's %s successfully (effectiveness: %d%%).[/color]" % [
				who, procedure_verb, target_name, part_label, eff
			]
		return "[color=teal]%s %s (effectiveness: %d%%).[/color]" % [
			who, success_clause % [target_name, part_label], eff
		]
	return (
		"[color=orange]%s failed to properly %s %s (effectiveness: %d%%; %s).[/color]"
		% [who, fail_verb, target_part, eff, fail_note]
	)


## True when resolved hit carried meaningful physical damage (integer **`dmg`** or fractional **`total_physical`**).
static func has_resolved_physical_damage(result: Dictionary) -> bool:
	var dmg: int = int(result.get("dmg", 0))
	var phys_chip: float = float(result.get("total_physical", -1.0))
	return dmg > 0 or (phys_chip >= 0.0 and phys_chip > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS)


## Human-readable damage from `action_resolved` hit payloads: prefers **`total_physical`** (cut+blunt+bone); falls back to **`dmg`**.
static func format_resolved_damage(result: Dictionary) -> String:
	var tp: Variant = result.get("total_physical", null)
	if tp != null:
		var t: float = float(tp)
		if t <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			return "0"
		var as_int: int = int(roundf(t))
		# Integer "dmg" can be 0 while fractional tissue/bone still chipped (display precisely).
		if as_int == 0 and t > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			return "~0 (%.2f)" % t
		if absf(t - roundf(t)) < CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
			return str(as_int)
		return "%.1f" % t
	return str(int(result.get("dmg", 0)))


## Compact one-line strip on the target row (`BattleScene` `last_hit_label`): outcome-appropriate prefix + part + damage.
static func format_last_hit_on_target_row(result: Dictionary) -> String:
	var part: String = result.get("part", "")
	if part.is_empty():
		return ""
	var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part)
	var outcome: String = result.get("outcome", "hit")
	var prefix: String = "Hit"
	match outcome:
		"negligible":
			prefix = "Graze"
		"glancing":
			prefix = "Glancing"
		"deflected":
			prefix = "Deflected"
		_:
			prefix = "Hit"
	return "%s: %s -%s" % [prefix, part_label, format_resolved_damage(result)]


static func format_action_line(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> String:
	var part: String = result.get("part", "")
	var died: bool = result.get("died", false)
	var outcome: String = result.get("outcome", "hit")
	var health_before: int = result.get("health_before", -1)
	var health_after: int = result.get("health_after", -1)
	var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part) if part else "—"
	if died and not has_resolved_physical_damage(result):
		if outcome == "bled_out":
			return "[color=red]%s (%s) — %s bled out.[/color]" % [attacker_name, attacker_side, target_name]
		elif outcome == "defeated":
			return "[color=red]%s (%s) — %s (%s) is defeated.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		else:
			return "[color=gray]%s (%s) — %s had no targetable parts.[/color]" % [attacker_name, attacker_side, target_name]
	elif outcome == "miss":
		return "[color=gray]%s (%s) → %s (%s): [b]Miss![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "dodge":
		return "[color=green]%s (%s) → %s (%s): [b]Dodge![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "skip":
		return "[color=gray]%s (%s) — no functional arm; skips attack.[/color]" % [attacker_name, attacker_side]
	elif outcome == "wait":
		return "[color=gray]%s (%s) waits.[/color]" % [attacker_name, attacker_side]
	elif outcome == "pass":
		var rank: int = int(result.get("rank", 0))
		if rank > 0:
			return "[color=gray]%s (%s) holds in reserve (no action available).[/color]" % [attacker_name, attacker_side]
		return "[color=gray]%s (%s) passes (no action available).[/color]" % [attacker_name, attacker_side]
	elif outcome == "swap_rank_complete":
		return "[color=gray]%s (%s) and %s (%s) swapped ranks.[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "drag_back_complete":
		return "[color=gray]%s (%s) and %s (%s) dragged back (formation).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "fall_back_complete":
		return "[color=gray]%s (%s) and %s (%s) fell back together.[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "fall_back_solo_complete":
		return "[color=gray]%s (%s) fell back to the second rank.[/color]" % [attacker_name, attacker_side]
	elif outcome == "rotate_file_complete":
		return "[color=gray]%s (%s) and %s (%s) rotated files (front rank).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "fled":
		return "[color=gray]%s (%s) fled the field.[/color]" % [attacker_name, attacker_side]
	elif outcome == "parry_deflect":
		var line_pd: String = "[color=cyan]%s (%s) parried %s (%s)'s attack.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if CombatConstants.COMBAT_DEBUG_CALIBRATION:
			var ctx_pd: Variant = result.get("parry_clash_context", null)
			if ctx_pd is Dictionary:
				var dpd: Dictionary = ctx_pd
				if not dpd.is_empty():
					var kdel: String = str(dpd.get("kinematic_delivery", ""))
					var sm: float = float(dpd.get("strike_measure_ratio", -1.0))
					var pc: float = float(dpd.get("parry_control", 0.0))
					line_pd += " [size=10][color=gray](%s meas=%.2f bind=%.2f)[/color][/size]" % [kdel, sm, pc]
		return line_pd
	elif outcome == "parry_partial":
		var line_pp: String = (
			"[color=cyan]%s (%s) partially parried %s (%s)'s attack (follow-through).[/color]"
			% [attacker_name, attacker_side, target_name, target_side]
		)
		if CombatConstants.COMBAT_DEBUG_CALIBRATION:
			var ctx_pp: Variant = result.get("parry_clash_context", null)
			if ctx_pp is Dictionary:
				var dpp: Dictionary = ctx_pp
				if not dpp.is_empty():
					var kdel_p: String = str(dpp.get("kinematic_delivery", ""))
					var sm_p: float = float(dpp.get("strike_measure_ratio", -1.0))
					var pc_p: float = float(dpp.get("parry_control", 0.0))
					var rem_p: float = float(dpp.get("remaining_ratio", -1.0))
					line_pp += " [size=10][color=gray](%s meas=%.2f bind=%.2f rem=%.2f)[/color][/size]" % [kdel_p, sm_p, pc_p, rem_p]
		return line_pp
	elif outcome == "direct_pressure":
		return "[color=teal]%s (%s) applied direct pressure on %s's %s.[/color]" % [attacker_name, attacker_side, target_name, part_label]
	elif outcome == "bandaged":
		var on_self_b: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_b: String = str(result.get("medical_move_id", "bandage_self"))
		var bandage_verb: String = (
			"bandaged" if on_self_b else _medical_procedure_label(med_id_b, false)
		)
		return _medical_procedure_log_line(
			true, "", "bandage",
			"partial effect; another can retry",
			attacker_name, attacker_side, target_name, part_label, result, bandage_verb
		)
	elif outcome == "bandage_failed":
		var on_self_bf: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_bf: String = str(result.get("medical_move_id", "bandage_self"))
		return _medical_procedure_log_line(
			false, "", _medical_procedure_label(med_id_bf, on_self_bf), "partial effect; another can retry",
			attacker_name, attacker_side, target_name, part_label, result
		)
	elif outcome == "packed":
		var on_self_p: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_p: String = str(result.get("medical_move_id", "pack_wound"))
		var pack_verb: String = (
			"packed with linen" if on_self_p else _medical_procedure_label(med_id_p, false)
		)
		return _medical_procedure_log_line(
			true, "", "pack",
			"partial effect; another can retry",
			attacker_name, attacker_side, target_name, part_label, result, pack_verb
		)
	elif outcome == "packing_failed":
		var on_self_pf: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_pf: String = str(result.get("medical_move_id", "pack_wound"))
		return _medical_procedure_log_line(
			false, "", _medical_procedure_label(med_id_pf, on_self_pf), "partial effect; another can retry",
			attacker_name, attacker_side, target_name, part_label, result
		)
	elif outcome == "tourniquet_applied":
		var on_self_t: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_t: String = str(result.get("medical_move_id", "apply_tourniquet"))
		var tq_verb: String = (
			"applied tourniquet to" if on_self_t else _medical_procedure_label(med_id_t, false)
		)
		return _medical_procedure_log_line(
			true, "", "apply tourniquet to",
			"not tight enough; can retry",
			attacker_name, attacker_side, target_name, part_label, result, tq_verb
		)
	elif outcome == "tourniquet_failed":
		var on_self_tf: bool = _medical_on_self(result, attacker_name, target_name)
		var med_id_tf: String = str(result.get("medical_move_id", "apply_tourniquet"))
		return _medical_procedure_log_line(
			false, "", _medical_procedure_label(med_id_tf, on_self_tf), "not tight enough; can retry",
			attacker_name, attacker_side, target_name, part_label, result
		)
	elif outcome == "close_success":
		return "[color=teal]%s (%s) closed the distance on %s (%s).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "close_failed":
		var rsn_close: String = str(result.get("reason", ""))
		if rsn_close == "not_long":
			return "[color=gray]%s (%s) could not close on %s (%s) — already in melee range.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn_close == "contest_failed":
			return "[color=gray]%s (%s) tried to close on %s (%s) — the defender held their measure.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		return "[color=gray]%s (%s) failed to close on %s (%s).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "crash_success":
		return "[color=orange]%s (%s) crashed the line against %s (%s) (tactical depth %d).[/color]" % [attacker_name, attacker_side, target_name, target_side, int(result.get("tactical_penetration_depth", 1))]
	elif outcome == "crash_failed":
		var rsn: String = str(result.get("reason", ""))
		if rsn == "intrusion_disabled":
			return "[color=gray]%s (%s) — line breach unavailable (intrusions disabled).[/color]" % [attacker_name, attacker_side]
		if rsn == "stamina":
			return "[color=gray]%s (%s) could not crash %s (%s) — too exhausted.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "max_depth":
			return "[color=gray]%s (%s) is already committed forward vs %s (%s).[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "not_viable":
			return "[color=gray]%s (%s) will not risk a line crash vs %s (%s) — too light or unready.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "repelled":
			return "[color=gray]%s (%s) pressed %s (%s) — the line held.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn.begins_with("engagement_mode_"):
			return "[color=gray]%s (%s) cannot breach the line vs %s (%s) in this engagement.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "light_armor":
			return "[color=gray]%s (%s) cannot crash %s (%s) — not heavy enough to force a breach.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "low_breach_power":
			return "[color=gray]%s (%s) cannot crash %s (%s) — formation not ready to drive through.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		if rsn == "intruder_cap":
			return "[color=gray]%s (%s) cannot crash %s (%s) — too many fighters already committed forward.[/color]" % [attacker_name, attacker_side, target_name, target_side]
		return "[color=gray]%s (%s) failed to break through %s (%s).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "deflected":
		return "%s (%s) → %s (%s) %s: [b]%s[/b] dmg [color=green](deflected — all avoided)[/color]" % [attacker_name, attacker_side, target_name, target_side, part_label, format_resolved_damage(result)]
	elif outcome == "glancing":
		var line: String = "%s (%s) → %s (%s) %s: [b]%s[/b] dmg [color=orange](glancing)[/color]" % [attacker_name, attacker_side, target_name, target_side, part_label, format_resolved_damage(result)]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		elif health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		return line
	elif outcome == "negligible":
		var line_n: String = (
			"%s (%s) → %s (%s) %s: [b]%s[/b] dmg [color=gray](negligible — contact, no counted HP)[/color]"
			% [attacker_name, attacker_side, target_name, target_side, part_label, format_resolved_damage(result)]
		)
		if result.has("final_cut") and result.has("final_blunt"):
			line_n += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		elif health_before >= 0 and health_after >= 0:
			line_n += " (%d→%d)" % [health_before, health_after]
		return line_n
	else:
		var line: String = "%s (%s) → %s (%s) %s: [b]%s[/b] dmg" % [attacker_name, attacker_side, target_name, target_side, part_label, format_resolved_damage(result)]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		if health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		if died:
			line += " [color=red](defeated)[/color]"
		return line
