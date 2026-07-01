class_name TuningLogFormatter
extends RefCounted

## Formats per-strike trace from AttackResolver result dict + entity readback.
## Used by the tuning scene's log panel and CSV export.

const _ConfigData := preload("res://combat_tuning/TuningConfigData.gd")

## Formats a full strike trace string.
static func format_strike(
	move_id: String,
	result: Dictionary,
	atk_gauge: float,
	def_gauge: float
) -> String:
	var lines := PackedStringArray()
	var action: String = result.get("action", "?")
	var dmg: float = result.get("dmg", 0.0)
	var part: String = result.get("part", "")
	var dt: String = result.get("damage_type", "")

	lines.push_back("--- Strike (%s) ---" % move_id)
	lines.push_back("  action=%s  dmg=%.1f  part=%s  type=%s" % [action, dmg, part, dt])

	# Sub-damage breakdown (cutting, blunt, KE, penetration)
	var cut: float = result.get("final_cut", 0.0)
	var blunt: float = result.get("final_blunt", 0.0)
	var ke: float = result.get("ke", 0.0)
	var pen: float = result.get("penetration", 0.0)
	if cut > 0.0 or blunt > 0.0:
		lines.push_back("  cut=%.1f  blunt=%.1f  ke=%.1f  pen=%.2f" % [cut, blunt, ke, pen])

	# Outcome / deflection / parry detail
	var outcome: String = result.get("outcome", "")
	if not outcome.is_empty():
		lines.push_back("  outcome=%s" % outcome)

	# Bleeding contribution
	var bleed: Variant = result.get("bleeding", null)
	if bleed is float:
		lines.push_back("  bleeding_rate=%.2f" % bleed)
	elif bleed is Dictionary:
		var bld: Dictionary = bleed as Dictionary
		for bk in bld:
			lines.push_back("  bleed[%s]=%.2f" % [bk, bld.get(bk, 0.0)])

	# Health before/after on target
	var hb: float = result.get("health_before", 0.0)
	var ha: float = result.get("health_after", 0.0)
	if hb > 0.0 or ha > 0.0:
		lines.push_back("  target_hp: %.1f -> %.1f (delta=%.1f)" % [hb, ha, ha - hb])

	# Gauge values for awareness
	lines.push_back("  gauge: atk=%.3f  def=%.3f" % [atk_gauge, def_gauge])

	# Defensive move used (if any)
	var def_move: String = result.get("defensive_move", "")
	var def_intensity: float = result.get("defense_intensity", 0.0)
	if not def_move.is_empty():
		lines.push_back("  defense=%s  int=%.2f" % [def_move, def_intensity])

	return "\n".join(lines)


## Brief one-liner for the summary line (used in list/CSV).
static func format_strike_one_line(move_id: String, result: Dictionary) -> String:
	var action: String = result.get("action", "?")
	var dmg: float = result.get("dmg", 0.0)
	var part: String = result.get("part", "?")
	return "%s %s dmg=%.1f part=%s" % [move_id, action, dmg, part]


## Formats entity health summary across all body parts + blood + consciousness.
static func format_entity_health(entity: Node) -> String:
	if entity == null or not is_instance_valid(entity):
		return "(no entity)"
	entity.ensure_consciousness_current()

	var parts := _ConfigData.BODY_PARTS
	var lines := PackedStringArray()

	for part in parts:
		var cut: float = entity.body_cutting.get(part, 0.0)
		var blunt: float = entity.body_blunt.get(part, 0.0)
		var max_hp: float = entity.body_max.get(part, 1.0)
		var bone: float = entity.bone_health.get(part, 0.0)
		var bone_max_val: float = entity.bone_max.get(part, 1.0)
		var hp_ratio: float = (cut + blunt) / max_hp if max_hp > 0.0 else 0.0
		var bone_ratio: float = bone / bone_max_val if bone_max_val > 0.0 else 0.0
		lines.push_back("  %s: hp=%.1f/%.1f (%.0f%%) bone=%.1f/%.1f (%.0f%%)" % [
			part, cut, max_hp, hp_ratio * 100.0,
			bone, bone_max_val, bone_ratio * 100.0
		])

	lines.push_back("  blood=%.1f  consciousness=%.1f" % [
		entity.blood_volume, entity.consciousness
	])
	return "\n".join(lines)


## Formats combatant dict state (stamina, gauge, guard, form).
static func format_combatant_state(c: Dictionary) -> String:
	if c.is_empty():
		return "(no combatant)"
	var state: String = c.get("state", "?")
	var stamina: float = c.get("stamina", 0.0)
	var gauge: float = c.get("gauge", 0.0)
	var guard: String = c.get("guard_line", "?")
	var form: String = c.get("_form_str", c.get("weapon_form", "?"))
	var alive: bool = c.get("alive", false)
	return "state=%s stamina=%.2f gauge=%.3f guard=%s form=%s alive=%s" % [
		state, stamina, gauge, guard, form, str(alive)
	]


## CSV header for aggregate batch output.
static func csv_header() -> String:
	return "strike,action,dmg,part,damage_type,cut,blunt,ke,penetration,outcome,gauge_atk,gauge_def,health_before,health_after"


## CSV row for one strike.
static func csv_row(
	strike_index: int,
	_move_id: String,
	result: Dictionary,
	gauge_atk: float,
	gauge_def: float
) -> String:
	var parts := PackedStringArray()
	parts.push_back(str(strike_index))
	parts.push_back(result.get("action", "?"))
	parts.push_back("%.1f" % result.get("dmg", 0.0))
	parts.push_back(result.get("part", ""))
	parts.push_back(result.get("damage_type", ""))
	parts.push_back("%.1f" % result.get("final_cut", 0.0))
	parts.push_back("%.1f" % result.get("final_blunt", 0.0))
	parts.push_back("%.1f" % result.get("ke", 0.0))
	parts.push_back("%.3f" % result.get("penetration", 0.0))
	parts.push_back(result.get("outcome", ""))
	parts.push_back("%.3f" % gauge_atk)
	parts.push_back("%.3f" % gauge_def)
	parts.push_back("%.1f" % result.get("health_before", 0.0))
	parts.push_back("%.1f" % result.get("health_after", 0.0))
	return ",".join(parts)
