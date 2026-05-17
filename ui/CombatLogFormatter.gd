class_name CombatLogFormatter
extends RefCounted

## Formats combat action results as BBCode strings for the combat log.
## BattleScene calls format_action_line() and appends the result to RichTextLabel.
## **`parry_deflect`** / **`parry_partial`**: optional **`parry_clash_context`** on **`result`** (from **`action_resolved`** after **`AttackResultApplier`**) — extra clash suffix only when **`CombatConstants.COMBAT_DEBUG_CALIBRATION`** (partial adds **`rem=`** leak ratio).

static func _eff_pct(result: Dictionary) -> int:
	return int(roundf(result.get("effectiveness", 1.0) * 100.0))


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
	var dmg: int = result.get("dmg", 0)
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
		return "[color=teal]%s (%s) bandaged %s's %s successfully (effectiveness: %d%%).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
	elif outcome == "bandage_failed":
		return "[color=orange]%s (%s) failed to properly bandage %s's %s (effectiveness: %d%%; partial effect; another can retry).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
	elif outcome == "packed":
		return "[color=teal]%s (%s) packed %s's %s with linen successfully (effectiveness: %d%%).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
	elif outcome == "packing_failed":
		return "[color=orange]%s (%s) failed to properly pack %s's %s (effectiveness: %d%%; partial effect; another can retry).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
	elif outcome == "tourniquet_applied":
		return "[color=teal]%s (%s) applied tourniquet to %s's %s successfully (effectiveness: %d%%).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
	elif outcome == "tourniquet_failed":
		return "[color=orange]%s (%s) failed to properly apply tourniquet to %s's %s (effectiveness: %d%%; not tight enough; can retry).[/color]" % [attacker_name, attacker_side, target_name, part_label, _eff_pct(result)]
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
