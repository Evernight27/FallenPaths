class_name CombatLogFormatter
extends RefCounted

## Formats combat action results as BBCode strings for the combat log.
## BattleScene calls format_action_line() and appends the result to RichTextLabel.

static func _eff_pct(result: Dictionary) -> int:
	return int(roundf(result.get("effectiveness", 1.0) * 100.0))

static func format_action_line(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> String:
	var part: String = result.get("part", "")
	var dmg: int = result.get("dmg", 0)
	var died: bool = result.get("died", false)
	var outcome: String = result.get("outcome", "hit")
	var health_before: int = result.get("health_before", -1)
	var health_after: int = result.get("health_after", -1)
	var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part) if part else "—"
	if died and dmg == 0:
		if outcome == "bled_out":
			return "[color=red]%s (%s) — %s bled out.[/color]" % [attacker_name, attacker_side, target_name]
		else:
			return "[color=gray]%s (%s) — %s had no targetable parts.[/color]" % [attacker_name, attacker_side, target_name]
	elif outcome == "miss":
		return "[color=gray]%s (%s) → %s (%s): [b]Miss![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "dodge":
		return "[color=green]%s (%s) → %s (%s): [b]Dodge![/b][/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "skip":
		return "[color=gray]%s (%s) — no functional arm; skips attack.[/color]" % [attacker_name, attacker_side]
	elif outcome == "parry_deflect":
		return "[color=cyan]%s (%s) parried %s (%s)'s attack.[/color]" % [attacker_name, attacker_side, target_name, target_side]
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
		return "[color=gray]%s (%s) failed to close on %s (%s).[/color]" % [attacker_name, attacker_side, target_name, target_side]
	elif outcome == "deflected":
		return "%s (%s) → %s (%s) %s: [b]%d[/b] dmg [color=green](deflected — all avoided)[/color]" % [attacker_name, attacker_side, target_name, target_side, part_label, dmg]
	elif outcome == "glancing":
		var line: String = "%s (%s) → %s (%s) %s: [b]%d[/b] dmg [color=orange](glancing)[/color]" % [attacker_name, attacker_side, target_name, target_side, part_label, dmg]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		elif health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		return line
	else:
		var line: String = "%s (%s) → %s (%s) %s: [b]%d[/b] dmg" % [attacker_name, attacker_side, target_name, target_side, part_label, dmg]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		if health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		if died:
			line += " [color=red](defeated)[/color]"
		return line
