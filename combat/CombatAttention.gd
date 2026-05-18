class_name CombatAttention
extends RefCounted

## Tier 4.3: salience probes, attention load, combat focus (**`focus_part`**, **`focus_intensity`**), and per-attacker yomi memory.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")


static func _counter_tempo() -> GDScript:
	return load("res://combat/CounterTempo.gd") as GDScript


static func enabled() -> bool:
	return CombatConstants.is_feature_combat_attention_enabled()


static func clear_focus_and_yomi(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	c.erase(CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY)
	c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_LOAD)
	c.erase(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER)
	c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)


static func get_focus_part(c: Dictionary) -> String:
	if c == null:
		return "head"
	var fp: String = str(c.get(CombatConstants.COMBATANT_KEY_FOCUS_PART, "")).strip_edges()
	if not fp.is_empty():
		return fp
	return str(c.get("guard_zone", "head"))


static func get_focus_intensity(c: Dictionary) -> float:
	if c == null:
		return CombatConstants.FOCUS_INTENSITY_DEFAULT
	return clampf(
		float(c.get(CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY, CombatConstants.FOCUS_INTENSITY_DEFAULT)),
		0.0,
		1.0
	)


static func set_focus(c: Dictionary, part: String, intensity: float = -1.0) -> void:
	if c == null:
		return
	var p: String = str(part).strip_edges()
	if p.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	else:
		c[CombatConstants.COMBATANT_KEY_FOCUS_PART] = p
	if intensity >= 0.0:
		c[CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY] = clampf(intensity, 0.0, 1.0)


## Wind-up telegraph: defender commits focus to the bait line at high intensity.
static func set_focus_from_incoming_telegraph(defender: Dictionary, telegraph_part: String) -> void:
	if not enabled() or defender == null:
		return
	var p: String = str(telegraph_part).strip_edges()
	if p.is_empty():
		return
	set_focus(defender, p, CombatConstants.FOCUS_INTENSITY_DEFAULT)


static func get_attention_load(c: Dictionary) -> float:
	if c == null:
		return 0.0
	return clampf(float(c.get(CombatConstants.COMBATANT_KEY_ATTENTION_LOAD, 0.0)), 0.0, 1.0)


static func focus_effective(c: Dictionary) -> float:
	var fi: float = get_focus_intensity(c)
	if not enabled():
		return fi
	var attention_load: float = get_attention_load(c)
	return clampf(fi * (1.0 - CombatConstants.ATTENTION_LOAD_FOCUS_PENALTY * attention_load), 0.0, 1.0)


static func refresh_salience(manager: Node, combatant_id: int) -> void:
	if not enabled() or manager == null or combatant_id < 0:
		return
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return
	var attention_load: float = 0.0
	if is_being_wind_up_targeted(manager, combatant_id):
		attention_load += CombatConstants.ATTENTION_LOAD_TELEGRAPH_WEIGHT
	if ally_in_immediate_peril(manager, combatant_id):
		attention_load += CombatConstants.ATTENTION_LOAD_PERIL_WEIGHT
	if has_actionable_counter_tempo(manager, c):
		attention_load += CombatConstants.ATTENTION_LOAD_COUNTER_WEIGHT
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = clampf(attention_load, 0.0, 1.0)


## Row label fragment: telegraphed line, focus part + effective %, optional load %.
static func format_attention_ui_hint(c: Dictionary) -> String:
	if not enabled() or c.is_empty():
		return ""
	var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
	var attention_load: float = get_attention_load(c)
	var stack_layer: String = str(
		c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")
	).strip_edges()
	if tele.is_empty() and attention_load < 0.05 and stack_layer.is_empty():
		return ""
	var chunks: PackedStringArray = []
	if not tele.is_empty():
		chunks.append("Tel %s" % tele)
	var fp: String = get_focus_part(c)
	var fe_pct: int = int(roundf(focus_effective(c) * 100.0))
	chunks.append("Focus %s %d%%" % [fp, fe_pct])
	if attention_load >= 0.08:
		chunks.append("Load %d%%" % int(roundf(attention_load * 100.0)))
	if not stack_layer.is_empty():
		chunks.append("Stack %s" % stack_layer)
	return " · ".join(chunks)


## UI snapshot: stamped row hint when present, else derive from live telegraph/focus/load (same frame as **`build`**).
static func snapshot_ui_hint(c: Dictionary) -> String:
	if not enabled() or c.is_empty():
		return ""
	var stamped: String = str(c.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "")).strip_edges()
	if not stamped.is_empty():
		return stamped
	return format_attention_ui_hint(c)


## Live UI: refresh salience probes, format hint (does not stamp **`COMBATANT_KEY_ATTENTION_UI_HINT`**).
static func live_ui_hint(manager: Node, c: Dictionary) -> String:
	if not enabled() or manager == null or c.is_empty():
		return ""
	var cid: int = _EntityAccess.id_int(c)
	if cid < 0:
		return ""
	refresh_salience(manager, cid)
	return format_attention_ui_hint(c)


## Waiting-tick refresh: recompute load + stamp **`COMBATANT_KEY_ATTENTION_UI_HINT`** for **`BattleUIUpdater`**.
static func refresh_for_waiting_tick(manager: Node, c: Dictionary) -> void:
	if c.is_empty() or manager == null:
		return
	var cid: int = _EntityAccess.id_int(c)
	if cid < 0:
		return
	refresh_salience(manager, cid)
	apply_yomi_focus_drift(manager, c)
	var hint: String = format_attention_ui_hint(c)
	if hint.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = hint


static func is_being_wind_up_targeted(manager: Node, defender_id: int) -> bool:
	if manager == null or defender_id < 0:
		return false
	var def: Dictionary = _EntityAccess.manager_get_combatant(manager, defender_id)
	if def.is_empty():
		return false
	if not str(def.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).is_empty():
		return true
	return _counter_tempo().call("incoming_attacker_id", manager, defender_id) >= 0


static func has_actionable_counter_tempo(manager: Node, c: Dictionary) -> bool:
	return _counter_tempo().call("can_act", manager, c)


static func ally_in_immediate_peril(manager: Node, combatant_id: int) -> bool:
	if manager == null or combatant_id < 0:
		return false
	var self_c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if self_c.is_empty():
		return false
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var o: Dictionary = other as Dictionary
		if _EntityAccess.id_int(o) == combatant_id:
			continue
		if not _EntityAccess.is_living_same_side(self_c, o):
			continue
		if manager._is_in_immediate_peril(o):
			return true
	return false


## Feint-only line commitment: wrong-line focus on telegraph hurts read-through; focus on real line helps.
static func focus_line_mult_for_feint(defender: Dictionary, pa: Dictionary) -> float:
	if not enabled() or defender == null or pa.is_empty():
		return 1.0
	var fp: String = str(pa.get("feint_part", "")).strip_edges()
	if fp.is_empty():
		return 1.0
	var tele: String = str(
		defender.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, fp)
	).strip_edges()
	var real: String = str(pa.get("target_part", "")).strip_edges()
	var focus: String = get_focus_part(defender)
	if not tele.is_empty() and focus == tele and not real.is_empty() and real != tele:
		return CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT
	if not real.is_empty() and focus == real:
		return CombatConstants.FOCUS_CORRECT_LINE_READTHROUGH_MULT
	return 1.0


static func _yomi_root(defender: Dictionary) -> Dictionary:
	var raw: Variant = defender.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, null)
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func record_attack_toward_defender(
	_manager: Node, attacker_id: int, defender: Dictionary, target_part: String
) -> void:
	if not enabled() or defender == null or attacker_id < 0:
		return
	var part: String = str(target_part).strip_edges()
	if part.is_empty():
		return
	var line: String = CombatConstants.PART_TO_LINE.get(part, "high")
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Dictionary = root.get(key, {}) as Dictionary
	if entry.is_empty():
		entry = {"line_counts": {}, "parry_deflect": 0}
	var counts: Dictionary = entry.get("line_counts", {}) as Dictionary
	counts[line] = int(counts.get(line, 0)) + 1
	entry["line_counts"] = counts
	root[key] = entry
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func record_parry_deflect_on_attacker_memory(defender: Dictionary, attacker_id: int) -> void:
	if not enabled() or defender == null or attacker_id < 0:
		return
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Dictionary = root.get(key, {}) as Dictionary
	if entry.is_empty():
		entry = {"line_counts": {}, "parry_deflect": 0}
	entry["parry_deflect"] = int(entry.get("parry_deflect", 0)) + 1
	root[key] = entry
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func clear_yomi_for_attacker(defender: Dictionary, attacker_id: int) -> void:
	if defender == null or attacker_id < 0:
		return
	var root: Dictionary = _yomi_root(defender)
	root.erase(str(attacker_id))
	if root.is_empty():
		defender.erase(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER)
	else:
		defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func dominant_attack_line_toward_defender(defender: Dictionary, attacker_id: int) -> String:
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return ""
	var counts: Dictionary = (entry as Dictionary).get("line_counts", {}) as Dictionary
	var best_line: String = ""
	var best_n: int = 0
	for line_key in counts.keys():
		var n: int = int(counts[line_key])
		if n > best_n:
			best_n = n
			best_line = str(line_key)
	return best_line


static func line_count_toward_defender(defender: Dictionary, attacker_id: int, line: String) -> int:
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary or line.is_empty():
		return 0
	var counts: Dictionary = (entry as Dictionary).get("line_counts", {}) as Dictionary
	return int(counts.get(line, 0))


## AI (non party-lead): nudge **`focus_part`** toward attacker's habitual line; mismatched feint telegraph keeps habit.
static func apply_yomi_focus_drift(
	manager: Node, c: Dictionary, forced_incoming_attacker_id: int = -1
) -> void:
	if not enabled() or c == null or bool(c.get("is_party_leader", false)):
		return
	var atk_id: int = forced_incoming_attacker_id
	if atk_id < 0 and manager != null:
		atk_id = _counter_tempo().call("incoming_attacker_id", manager, _EntityAccess.id_int(c))
	if atk_id < 0:
		return
	var dom: String = dominant_attack_line_toward_defender(c, atk_id)
	if dom.is_empty():
		return
	if line_count_toward_defender(c, atk_id, dom) < CombatConstants.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT:
		return
	var habit_part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom, "")
	if habit_part.is_empty():
		return
	var tele: String = str(
		c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")
	).strip_edges()
	var focus_part: String = habit_part
	if not tele.is_empty():
		var tele_line: String = CombatConstants.PART_TO_LINE.get(tele, "")
		if tele_line == dom:
			focus_part = tele
		elif tele_line != dom:
			focus_part = habit_part
		else:
			focus_part = tele
	var next_intensity: float = maxf(
		get_focus_intensity(c),
		CombatConstants.YOMI_FOCUS_DRIFT_INTENSITY
	)
	set_focus(c, focus_part, next_intensity)


## Feint listing: boost when feint telegraph line matches attacker's habitual target line.
static func yomi_feint_listing_mult(
	defender: Dictionary, attacker_id: int, feint_part: String
) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var fp: String = str(feint_part).strip_edges()
	if fp.is_empty():
		return 1.0
	var dom: String = dominant_attack_line_toward_defender(defender, attacker_id)
	if dom.is_empty():
		return 1.0
	var feint_line: String = CombatConstants.PART_TO_LINE.get(fp, "")
	if feint_line != dom:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Dictionary = root.get(str(attacker_id), {}) as Dictionary
	var counts: Dictionary = entry.get("line_counts", {}) as Dictionary
	var n: int = int(counts.get(dom, 0))
	if n < CombatConstants.YOMI_FEINT_LISTING_MIN_LINE_COUNT:
		return 1.0
	var boost: float = 1.0 + float(n - CombatConstants.YOMI_FEINT_LISTING_MIN_LINE_COUNT + 1) * CombatConstants.YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT
	return minf(boost, CombatConstants.YOMI_FEINT_LISTING_MULT_CAP)


## Feint listing: recent **`parry_deflect`** vs this attacker makes feints more attractive.
static func yomi_parry_deflect_feint_listing_mult(defender: Dictionary, attacker_id: int) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return 1.0
	var n: int = int((entry as Dictionary).get("parry_deflect", 0))
	if n <= 0:
		return 1.0
	var boost: float = 1.0 + float(n) * CombatConstants.YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_PER
	return minf(boost, CombatConstants.YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_CAP)


## Defender passive readiness: prior **`parry_deflect`** vs this attacker raises confidence.
static func yomi_defense_readiness_mult(defender: Dictionary, attacker_id: int) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return 1.0
	var n: int = int((entry as Dictionary).get("parry_deflect", 0))
	if n <= 0:
		return 1.0
	var boost: float = 1.0 + float(n) * CombatConstants.YOMI_DEFENSE_READINESS_MULT_PER_PARRY_DEFLECT
	return minf(boost, CombatConstants.YOMI_DEFENSE_READINESS_MULT_CAP)


## Tier 4.3.7: self-target guard-line / focus retarget while waiting (`get_available_actions`).
static func append_focus_line_listing_actions(c: Dictionary, combatant_id: int, actions: Array) -> void:
	if not enabled() or c.is_empty():
		return
	for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
		actions.append({"target_id": combatant_id, "move_id": move_id})
