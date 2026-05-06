class_name CombatLogFormatter
extends RefCounted

## Formats combat action results as BBCode strings for the combat log.
## BattleScene calls format_action_line() and appends the result to RichTextLabel.

static func _eff_pct(result: Dictionary) -> int:
	return int(roundf(result.get("effectiveness", 1.0) * 100.0))


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


static func format_action_line(attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary) -> String:
	var part: String = result.get("part", "")
	var dmg: int = result.get("dmg", 0)
	var died: bool = result.get("died", false)
	var outcome: String = result.get("outcome", "hit")
	var health_before: int = result.get("health_before", -1)
	var health_after: int = result.get("health_after", -1)
	var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part) if part else "—"
	var phys_chip: float = float(result.get("total_physical", -1.0))
	var has_resolve_phys: bool = dmg > 0 or (phys_chip >= 0.0 and phys_chip > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS)
	if died and not has_resolve_phys:
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
	else:
		var line: String = "%s (%s) → %s (%s) %s: [b]%s[/b] dmg" % [attacker_name, attacker_side, target_name, target_side, part_label, format_resolved_damage(result)]
		if result.has("final_cut") and result.has("final_blunt"):
			line += " (cut %.2f blunt %.2f)" % [result.final_cut, result.final_blunt]
		if health_before >= 0 and health_after >= 0:
			line += " (%d→%d)" % [health_before, health_after]
		if died:
			line += " [color=red](defeated)[/color]"
		return line
